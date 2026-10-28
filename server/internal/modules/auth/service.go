package auth

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"jesi-laundry-app-server/internal/model"
	"jesi-laundry-app-server/internal/platform/config"
	"jesi-laundry-app-server/internal/platform/database"
	"jesi-laundry-app-server/internal/platform/httpx"
	"jesi-laundry-app-server/internal/platform/mailer"
	"jesi-laundry-app-server/internal/platform/security"
)

const (
	refreshRetention  = 30 * 24 * time.Hour // keep revoked refresh tokens this long (reuse detection)
	otpRetention      = 24 * time.Hour
	otpResendCooldown = 60 * time.Second
	otpMaxPerHour     = 5
	otpMaxAttempts    = 5
	mailSendTimeout   = 10 * time.Second
)

// OutletCreator and DefaultServiceCreator are the slices of the outlet and catalog modules that auth needs.
type OutletCreator interface {
	Create(ctx context.Context, o *model.Outlet) error
}

type DefaultServiceCreator interface {
	CreateDefaults(ctx context.Context, outletID uuid.UUID) error
}

// Session is the result of any operation that signs a user in.
type Session struct {
	AccessToken           string
	AccessTokenExpiresAt  time.Time
	RefreshToken          string
	RefreshTokenExpiresAt time.Time
	User                  *model.User
}

type Service struct {
	db        *gorm.DB
	repo      *Repository
	cfg       *config.Config
	mailer    mailer.Mailer
	outletTx  func(tx *gorm.DB) OutletCreator
	catalogTx func(tx *gorm.DB) DefaultServiceCreator
}

func NewService(
	db *gorm.DB,
	repo *Repository,
	cfg *config.Config,
	m mailer.Mailer,
	outletTx func(tx *gorm.DB) OutletCreator,
	catalogTx func(tx *gorm.DB) DefaultServiceCreator,
) *Service {
	return &Service{db: db, repo: repo, cfg: cfg, mailer: m, outletTx: outletTx, catalogTx: catalogTx}
}

// ---- setup & registration ----

func (s *Service) SetupStatus(ctx context.Context) (bool, error) {
	exists, err := s.repo.OwnerExists(ctx)
	if err != nil {
		return false, fmt.Errorf("check owner exists: %w", err)
	}
	return exists, nil
}

// RegisterOwner creates the owner, the first outlet and its default catalog in one transaction.
func (s *Service) RegisterOwner(ctx context.Context, req RegisterOwnerRequest) (*Session, error) {
	name := strings.TrimSpace(req.Name)
	outletName := strings.TrimSpace(req.OutletName)
	if name == "" {
		return nil, invalid("name", "required")
	}
	if outletName == "" {
		return nil, invalid("outlet_name", "required")
	}
	if err := checkPassword("password", req.Password); err != nil {
		return nil, err
	}

	exists, err := s.repo.OwnerExists(ctx)
	if err != nil {
		return nil, fmt.Errorf("check owner exists: %w", err)
	}
	if exists {
		return nil, httpx.New(httpx.CodeOwnerAlreadyExists, "owner already registered")
	}

	hash, err := security.HashPassword(req.Password)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}

	var session *Session
	err = database.WithTx(ctx, s.db, func(tx *gorm.DB) error {
		o := &model.Outlet{
			Code:     strings.ToUpper(strings.TrimSpace(req.OutletCode)),
			Name:     outletName,
			Address:  nilIfEmpty(req.OutletAddress),
			Phone:    nilIfEmpty(req.OutletPhone),
			IsActive: true,
		}
		if err := s.outletTx(tx).Create(ctx, o); err != nil {
			return err
		}
		if err := s.catalogTx(tx).CreateDefaults(ctx, o.ID); err != nil {
			return err
		}

		user := &model.User{
			Name:         name,
			Email:        normalizeEmail(req.Email),
			PasswordHash: hash,
			Role:         model.RoleOwner,
			IsActive:     true,
		}
		repo := s.repo.WithTx(tx)
		if err := repo.CreateUser(ctx, user); err != nil {
			return err
		}

		sess, _, err := s.issueSession(ctx, repo, user, time.Now().UTC())
		if err != nil {
			return err
		}
		session = sess
		return nil
	})
	if err != nil {
		if appErr := mapUniqueViolation(err); appErr != nil {
			return nil, appErr
		}
		return nil, fmt.Errorf("register owner: %w", err)
	}
	return session, nil
}

// ---- login / refresh / logout ----

func (s *Service) Login(ctx context.Context, req LoginRequest) (*Session, error) {
	user, err := s.repo.FindUserByEmail(ctx, normalizeEmail(req.Email))
	if errors.Is(err, gorm.ErrRecordNotFound) {
		security.CompareDummy(req.Password)
		return nil, errInvalidCredentials()
	}
	if err != nil {
		return nil, fmt.Errorf("find user: %w", err)
	}
	if !security.ComparePassword(user.PasswordHash, req.Password) {
		return nil, errInvalidCredentials()
	}
	if !user.IsActive {
		return nil, httpx.New(httpx.CodeAccountInactive, "account is inactive")
	}

	var session *Session
	err = database.WithTx(ctx, s.db, func(tx *gorm.DB) error {
		repo := s.repo.WithTx(tx)
		now := time.Now().UTC()
		if err := repo.UpdateUser(ctx, user.ID, map[string]any{"last_login_at": now}); err != nil {
			return err
		}
		user.LastLoginAt = &now

		sess, _, err := s.issueSession(ctx, repo, user, now)
		if err != nil {
			return err
		}
		session = sess
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("login: %w", err)
	}

	// Housekeeping without a background worker: failures are logged and never fail the login.
	now := time.Now().UTC()
	if err := s.repo.DeleteStaleRefreshTokens(ctx, user.ID, now, now.Add(-refreshRetention)); err != nil {
		slog.Warn("cleanup stale refresh tokens failed", "user_id", user.ID, "error", err)
	}
	return session, nil
}

// Refresh rotates a refresh token. Reusing an already-rotated token revokes every session of that user.
func (s *Service) Refresh(ctx context.Context, rawToken string) (*Session, error) {
	hash := security.SHA256Hex(rawToken)

	var session *Session
	var failure error // business error returned after the transaction commits (so revocations persist)

	err := database.WithTx(ctx, s.db, func(tx *gorm.DB) error {
		repo := s.repo.WithTx(tx)

		old, err := repo.FindRefreshTokenByHash(ctx, hash)
		if errors.Is(err, gorm.ErrRecordNotFound) {
			failure = errInvalidRefreshToken()
			return nil
		}
		if err != nil {
			return err
		}

		now := time.Now().UTC()
		if !old.ExpiresAt.After(now) {
			failure = errInvalidRefreshToken()
			return nil
		}
		if old.RevokedAt != nil {
			failure = errInvalidRefreshToken()
			return repo.RevokeAllRefreshTokens(ctx, old.UserID, now)
		}

		user, err := repo.FindUserByID(ctx, old.UserID)
		if err != nil {
			return err
		}
		if !user.IsActive {
			failure = httpx.New(httpx.CodeAccountInactive, "account is inactive")
			return repo.RevokeAllRefreshTokens(ctx, user.ID, now)
		}

		sess, next, err := s.issueSession(ctx, repo, user, now)
		if err != nil {
			return err
		}
		if err := repo.RevokeRefreshToken(ctx, old.ID, now, &next.ID); err != nil {
			return err
		}
		session = sess
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("refresh session: %w", err)
	}
	if failure != nil {
		return nil, failure
	}
	return session, nil
}

// Logout revokes the given refresh token. Unknown or empty tokens are ignored (idempotent).
func (s *Service) Logout(ctx context.Context, rawToken string) error {
	if rawToken == "" {
		return nil
	}
	if err := s.repo.RevokeRefreshTokenByHash(ctx, security.SHA256Hex(rawToken), time.Now().UTC()); err != nil {
		return fmt.Errorf("revoke refresh token: %w", err)
	}
	return nil
}

// ---- password reset ----

// ForgotPassword never reveals whether the email exists; all skip conditions return nil silently.
func (s *Service) ForgotPassword(ctx context.Context, req ForgotPasswordRequest, lang string) error {
	user, err := s.repo.FindUserByEmail(ctx, normalizeEmail(req.Email))
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil
	}
	if err != nil {
		return fmt.Errorf("find user: %w", err)
	}
	if !user.IsActive {
		return nil
	}

	now := time.Now().UTC()
	latest, err := s.repo.LatestOTP(ctx, user.ID)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return fmt.Errorf("find latest otp: %w", err)
	}
	if latest != nil && now.Sub(latest.CreatedAt) < otpResendCooldown {
		return nil
	}
	recent, err := s.repo.CountOTPsSince(ctx, user.ID, now.Add(-time.Hour))
	if err != nil {
		return fmt.Errorf("count otps: %w", err)
	}
	if recent >= otpMaxPerHour {
		return nil
	}

	code, err := security.GenerateOTP()
	if err != nil {
		return fmt.Errorf("generate otp: %w", err)
	}
	err = database.WithTx(ctx, s.db, func(tx *gorm.DB) error {
		repo := s.repo.WithTx(tx)
		if err := repo.MarkActiveOTPsUsed(ctx, user.ID, now); err != nil {
			return err
		}
		return repo.CreateOTP(ctx, &model.PasswordResetOTP{
			UserID:    user.ID,
			CodeHash:  security.HashOTP(s.cfg.OTPSecret, user.ID, code),
			ExpiresAt: now.Add(s.cfg.OTPTTL),
		})
	})
	if err != nil {
		return fmt.Errorf("store otp: %w", err)
	}

	// Housekeeping without a background worker: failures are logged and never fail the request.
	if err := s.repo.DeleteStaleOTPs(ctx, user.ID, now.Add(-otpRetention)); err != nil {
		slog.Warn("cleanup stale otps failed", "user_id", user.ID, "error", err)
	}

	mailCtx, cancel := context.WithTimeout(ctx, mailSendTimeout)
	defer cancel()
	if err := s.mailer.SendPasswordResetOTP(mailCtx, user.Email, user.Name, code, lang); err != nil {
		slog.Error("send password reset otp failed", "user_id", user.ID, "error", err)
	}
	return nil
}

func (s *Service) ResetPassword(ctx context.Context, req ResetPasswordRequest) error {
	if err := checkPassword("new_password", req.NewPassword); err != nil {
		return err
	}

	user, err := s.repo.FindUserByEmail(ctx, normalizeEmail(req.Email))
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return httpx.New(httpx.CodeOTPExpired, "otp expired")
	}
	if err != nil {
		return fmt.Errorf("find user: %w", err)
	}
	if !user.IsActive {
		return httpx.New(httpx.CodeOTPExpired, "otp expired")
	}

	hash, err := security.HashPassword(req.NewPassword)
	if err != nil {
		return fmt.Errorf("hash password: %w", err)
	}

	var failure error // returned after commit so a wrong-attempt increment is persisted
	err = database.WithTx(ctx, s.db, func(tx *gorm.DB) error {
		repo := s.repo.WithTx(tx)

		otp, err := repo.LatestUnusedOTPForUpdate(ctx, user.ID)
		if errors.Is(err, gorm.ErrRecordNotFound) {
			failure = httpx.New(httpx.CodeOTPExpired, "otp expired")
			return nil
		}
		if err != nil {
			return err
		}

		now := time.Now().UTC()
		if !otp.ExpiresAt.After(now) {
			failure = httpx.New(httpx.CodeOTPExpired, "otp expired")
			return nil
		}
		if otp.Attempts >= otpMaxAttempts {
			failure = httpx.New(httpx.CodeOTPTooManyAttempts, "too many otp attempts")
			return nil
		}
		if !security.EqualHash(otp.CodeHash, security.HashOTP(s.cfg.OTPSecret, user.ID, req.OTP)) {
			failure = httpx.New(httpx.CodeOTPInvalid, "otp invalid")
			return repo.IncrementOTPAttempts(ctx, otp.ID)
		}

		if err := repo.UpdateUser(ctx, user.ID, map[string]any{"password_hash": hash}); err != nil {
			return err
		}
		if err := repo.MarkOTPUsed(ctx, otp.ID, now); err != nil {
			return err
		}
		return repo.RevokeAllRefreshTokens(ctx, user.ID, now)
	})
	if err != nil {
		return fmt.Errorf("reset password: %w", err)
	}
	return failure
}

// ---- /me ----

func (s *Service) GetMe(ctx context.Context, userID uuid.UUID) (*model.User, error) {
	user, err := s.repo.FindUserByID(ctx, userID)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, httpx.Unauthorized("user no longer exists")
	}
	if err != nil {
		return nil, fmt.Errorf("find user: %w", err)
	}
	if !user.IsActive {
		return nil, httpx.New(httpx.CodeAccountInactive, "account is inactive")
	}
	return user, nil
}

func (s *Service) UpdateMe(ctx context.Context, userID uuid.UUID, req UpdateMeRequest) (*model.User, error) {
	fields := map[string]any{}
	if req.Name != nil {
		name := strings.TrimSpace(*req.Name)
		if name == "" {
			return nil, invalid("name", "required")
		}
		fields["name"] = name
	}
	if len(fields) > 0 {
		if err := s.repo.UpdateUser(ctx, userID, fields); err != nil {
			return nil, fmt.Errorf("update user: %w", err)
		}
	}
	return s.GetMe(ctx, userID)
}

// ChangePassword updates the password, revokes every session and returns a fresh one for the caller.
func (s *Service) ChangePassword(ctx context.Context, userID uuid.UUID, req ChangePasswordRequest) (*Session, error) {
	user, err := s.GetMe(ctx, userID)
	if err != nil {
		return nil, err
	}
	if !security.ComparePassword(user.PasswordHash, req.CurrentPassword) {
		return nil, errInvalidCredentials()
	}
	if err := checkPassword("new_password", req.NewPassword); err != nil {
		return nil, err
	}
	hash, err := security.HashPassword(req.NewPassword)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}

	var session *Session
	err = database.WithTx(ctx, s.db, func(tx *gorm.DB) error {
		repo := s.repo.WithTx(tx)
		now := time.Now().UTC()
		if err := repo.UpdateUser(ctx, user.ID, map[string]any{"password_hash": hash}); err != nil {
			return err
		}
		if err := repo.RevokeAllRefreshTokens(ctx, user.ID, now); err != nil {
			return err
		}
		sess, _, err := s.issueSession(ctx, repo, user, now)
		if err != nil {
			return err
		}
		session = sess
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("change password: %w", err)
	}
	return session, nil
}

// ---- helpers ----

// issueSession creates an access token and a stored refresh token for user. It returns the new refresh token row.
func (s *Service) issueSession(ctx context.Context, repo *Repository, user *model.User, now time.Time) (*Session, *model.RefreshToken, error) {
	access, accessExp, err := security.IssueAccessToken(s.cfg.JWTAccessSecret, s.cfg.JWTAccessTTL, user.ID, string(user.Role), user.OutletID, now)
	if err != nil {
		return nil, nil, fmt.Errorf("issue access token: %w", err)
	}
	raw, err := security.RandomToken()
	if err != nil {
		return nil, nil, fmt.Errorf("generate refresh token: %w", err)
	}
	rt := &model.RefreshToken{
		UserID:    user.ID,
		TokenHash: security.SHA256Hex(raw),
		ExpiresAt: now.Add(s.cfg.RefreshTokenTTL),
	}
	if err := repo.CreateRefreshToken(ctx, rt); err != nil {
		return nil, nil, err
	}
	return &Session{
		AccessToken:           access,
		AccessTokenExpiresAt:  accessExp,
		RefreshToken:          raw,
		RefreshTokenExpiresAt: rt.ExpiresAt,
		User:                  user,
	}, rt, nil
}

func normalizeEmail(s string) string { return strings.ToLower(strings.TrimSpace(s)) }

func nilIfEmpty(s string) *string {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil
	}
	return &s
}

func invalid(field, rule string) *httpx.AppError {
	return httpx.Validation([]httpx.FieldError{{Field: field, Rule: rule}})
}

func checkPassword(field, password string) error {
	if !security.ValidPassword(password) {
		return invalid(field, "password_strength")
	}
	return nil
}

func errInvalidCredentials() *httpx.AppError {
	return httpx.New(httpx.CodeInvalidCredentials, "invalid email or password")
}

func errInvalidRefreshToken() *httpx.AppError {
	return httpx.New(httpx.CodeInvalidRefreshToken, "invalid refresh token")
}

// mapUniqueViolation translates known unique-constraint failures; it returns nil for anything else.
func mapUniqueViolation(err error) *httpx.AppError {
	constraint, ok := database.UniqueViolation(err)
	if !ok {
		return nil
	}
	switch constraint {
	case "uq_users_single_owner":
		return httpx.New(httpx.CodeOwnerAlreadyExists, "owner already registered")
	case "uq_users_email":
		return httpx.New(httpx.CodeEmailTaken, "email already in use")
	case "uq_outlets_code":
		return httpx.New(httpx.CodeOutletCodeTaken, "outlet code already in use")
	}
	return nil
}
