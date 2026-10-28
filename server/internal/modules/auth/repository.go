package auth

import (
	"context"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"jesi-laundry-app-server/internal/model"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) WithTx(tx *gorm.DB) *Repository {
	return &Repository{db: tx}
}

// ---- users ----

func (r *Repository) OwnerExists(ctx context.Context) (bool, error) {
	var n int64
	err := r.db.WithContext(ctx).Model(&model.User{}).Where("role = ?", model.RoleOwner).Count(&n).Error
	return n > 0, err
}

func (r *Repository) CreateUser(ctx context.Context, u *model.User) error {
	return r.db.WithContext(ctx).Create(u).Error
}

func (r *Repository) FindUserByEmail(ctx context.Context, email string) (*model.User, error) {
	var u model.User
	if err := r.db.WithContext(ctx).Preload("Outlet").First(&u, "email = ?", email).Error; err != nil {
		return nil, err
	}
	return &u, nil
}

func (r *Repository) FindUserByID(ctx context.Context, id uuid.UUID) (*model.User, error) {
	var u model.User
	if err := r.db.WithContext(ctx).Preload("Outlet").First(&u, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &u, nil
}

// UpdateUser applies only the given columns (map, so zero values are written).
func (r *Repository) UpdateUser(ctx context.Context, id uuid.UUID, fields map[string]any) error {
	return r.db.WithContext(ctx).Model(&model.User{}).Where("id = ?", id).Updates(fields).Error
}

// ---- refresh tokens ----

func (r *Repository) CreateRefreshToken(ctx context.Context, t *model.RefreshToken) error {
	return r.db.WithContext(ctx).Create(t).Error
}

// FindRefreshTokenByHash locks the row (FOR UPDATE) so concurrent rotations of one token serialize.
func (r *Repository) FindRefreshTokenByHash(ctx context.Context, hash string) (*model.RefreshToken, error) {
	var t model.RefreshToken
	err := r.db.WithContext(ctx).Clauses(clause.Locking{Strength: "UPDATE"}).First(&t, "token_hash = ?", hash).Error
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (r *Repository) RevokeRefreshToken(ctx context.Context, id uuid.UUID, at time.Time, replacedBy *uuid.UUID) error {
	fields := map[string]any{"revoked_at": at, "replaced_by_id": replacedBy}
	return r.db.WithContext(ctx).Model(&model.RefreshToken{}).Where("id = ?", id).Updates(fields).Error
}

func (r *Repository) RevokeRefreshTokenByHash(ctx context.Context, hash string, at time.Time) error {
	return r.db.WithContext(ctx).Model(&model.RefreshToken{}).
		Where("token_hash = ? AND revoked_at IS NULL", hash).
		Update("revoked_at", at).Error
}

func (r *Repository) RevokeAllRefreshTokens(ctx context.Context, userID uuid.UUID, at time.Time) error {
	return r.db.WithContext(ctx).Model(&model.RefreshToken{}).
		Where("user_id = ? AND revoked_at IS NULL", userID).
		Update("revoked_at", at).Error
}

// ---- password reset OTPs ----

func (r *Repository) CreateOTP(ctx context.Context, o *model.PasswordResetOTP) error {
	return r.db.WithContext(ctx).Create(o).Error
}

// LatestOTP returns the user's most recent OTP (used or not); gorm.ErrRecordNotFound when none.
func (r *Repository) LatestOTP(ctx context.Context, userID uuid.UUID) (*model.PasswordResetOTP, error) {
	var o model.PasswordResetOTP
	err := r.db.WithContext(ctx).Where("user_id = ?", userID).Order("created_at DESC").First(&o).Error
	if err != nil {
		return nil, err
	}
	return &o, nil
}

// LatestUnusedOTPForUpdate returns and locks the user's newest unused OTP.
func (r *Repository) LatestUnusedOTPForUpdate(ctx context.Context, userID uuid.UUID) (*model.PasswordResetOTP, error) {
	var o model.PasswordResetOTP
	err := r.db.WithContext(ctx).Clauses(clause.Locking{Strength: "UPDATE"}).
		Where("user_id = ? AND used_at IS NULL", userID).
		Order("created_at DESC").First(&o).Error
	if err != nil {
		return nil, err
	}
	return &o, nil
}

func (r *Repository) CountOTPsSince(ctx context.Context, userID uuid.UUID, since time.Time) (int64, error) {
	var n int64
	err := r.db.WithContext(ctx).Model(&model.PasswordResetOTP{}).
		Where("user_id = ? AND created_at > ?", userID, since).Count(&n).Error
	return n, err
}

func (r *Repository) MarkActiveOTPsUsed(ctx context.Context, userID uuid.UUID, at time.Time) error {
	return r.db.WithContext(ctx).Model(&model.PasswordResetOTP{}).
		Where("user_id = ? AND used_at IS NULL", userID).
		Update("used_at", at).Error
}

// IncrementOTPAttempts bumps the counter atomically in the database.
func (r *Repository) IncrementOTPAttempts(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Model(&model.PasswordResetOTP{}).
		Where("id = ?", id).
		Update("attempts", gorm.Expr("attempts + ?", 1)).Error
}

func (r *Repository) MarkOTPUsed(ctx context.Context, id uuid.UUID, at time.Time) error {
	return r.db.WithContext(ctx).Model(&model.PasswordResetOTP{}).Where("id = ?", id).Update("used_at", at).Error
}

// DeleteStaleRefreshTokens removes the user's tokens that have expired, or were revoked before revokedBefore.
// Recently revoked tokens are kept so reuse of a rotated token is still detected.
func (r *Repository) DeleteStaleRefreshTokens(ctx context.Context, userID uuid.UUID, now, revokedBefore time.Time) error {
	return r.db.WithContext(ctx).
		Where("user_id = ? AND (expires_at < ? OR revoked_at < ?)", userID, now, revokedBefore).
		Delete(&model.RefreshToken{}).Error
}

// DeleteStaleOTPs removes the user's OTPs that expired or were used before the cutoff.
func (r *Repository) DeleteStaleOTPs(ctx context.Context, userID uuid.UUID, before time.Time) error {
	return r.db.WithContext(ctx).
		Where("user_id = ? AND (expires_at < ? OR used_at < ?)", userID, before, before).
		Delete(&model.PasswordResetOTP{}).Error
}
