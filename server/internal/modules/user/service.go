package user

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"jesi-laundry-app-server/internal/model"
	"jesi-laundry-app-server/internal/platform/database"
	"jesi-laundry-app-server/internal/platform/httpx"
	"jesi-laundry-app-server/internal/platform/security"
)

const (
	defaultLimit = 20
	maxLimit     = 100
)

// OutletFinder is the part of the outlet module the user module needs.
type OutletFinder interface {
	FindByID(ctx context.Context, id uuid.UUID) (*model.Outlet, error)
}

// Service manages staff accounts only. Owners are not reachable through it, which also means
// an owner can never deactivate themselves here.
type Service struct {
	db      *gorm.DB
	repo    *Repository
	outlets OutletFinder
}

func NewService(db *gorm.DB, repo *Repository, outlets OutletFinder) *Service {
	return &Service{db: db, repo: repo, outlets: outlets}
}

func (s *Service) List(ctx context.Context, outletID *uuid.UUID, search string, page httpx.Page) ([]model.User, httpx.Meta, error) {
	page = page.Normalize(defaultLimit, maxLimit)
	users, total, err := s.repo.ListStaff(ctx, ListFilter{
		OutletID: outletID,
		Search:   strings.TrimSpace(search),
		Offset:   page.Offset(),
		Limit:    page.Limit,
	})
	if err != nil {
		return nil, httpx.Meta{}, fmt.Errorf("list staff: %w", err)
	}
	return users, page.Meta(total), nil
}

func (s *Service) Get(ctx context.Context, id uuid.UUID) (*model.User, error) {
	u, err := s.repo.FindStaffByID(ctx, id)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, httpx.NotFound("staff not found")
	}
	if err != nil {
		return nil, fmt.Errorf("find staff: %w", err)
	}
	return u, nil
}

func (s *Service) Create(ctx context.Context, req CreateStaffRequest) (*model.User, error) {
	name := strings.TrimSpace(req.Name)
	if name == "" {
		return nil, httpx.FieldViolation("name", "required")
	}
	if !security.ValidPassword(req.Password) {
		return nil, httpx.FieldViolation("password", "password_strength")
	}
	outletID, err := uuid.Parse(req.OutletID)
	if err != nil {
		return nil, httpx.FieldViolation("outlet_id", "uuid")
	}
	if err := s.requireActiveOutlet(ctx, outletID); err != nil {
		return nil, err
	}

	hash, err := security.HashPassword(req.Password)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}

	u := &model.User{
		Name:         name,
		Email:        strings.ToLower(strings.TrimSpace(req.Email)),
		PasswordHash: hash,
		Role:         model.RoleStaff,
		OutletID:     &outletID,
		IsActive:     true,
	}
	if err := s.repo.Create(ctx, u); err != nil {
		if constraint, ok := database.UniqueViolation(err); ok && constraint == "uq_users_email" {
			return nil, httpx.New(httpx.CodeEmailTaken, "email already in use")
		}
		return nil, fmt.Errorf("create staff: %w", err)
	}
	return s.Get(ctx, u.ID)
}

// Update changes name, outlet and active flag. Deactivating or moving staff revokes all their sessions.
func (s *Service) Update(ctx context.Context, id uuid.UUID, req UpdateStaffRequest) (*model.User, error) {
	u, err := s.Get(ctx, id)
	if err != nil {
		return nil, err
	}

	fields := map[string]any{}
	revoke := false

	if req.Name != nil {
		name := strings.TrimSpace(*req.Name)
		if name == "" {
			return nil, httpx.FieldViolation("name", "required")
		}
		fields["name"] = name
	}
	if req.OutletID != nil {
		outletID, err := uuid.Parse(*req.OutletID)
		if err != nil {
			return nil, httpx.FieldViolation("outlet_id", "uuid")
		}
		if u.OutletID == nil || *u.OutletID != outletID {
			if err := s.requireActiveOutlet(ctx, outletID); err != nil {
				return nil, err
			}
			fields["outlet_id"] = outletID
			revoke = true
		}
	}
	if req.IsActive != nil {
		fields["is_active"] = *req.IsActive
		if !*req.IsActive {
			revoke = true
		}
	}

	if len(fields) > 0 {
		err := database.WithTx(ctx, s.db, func(tx *gorm.DB) error {
			repo := s.repo.WithTx(tx)
			if err := repo.Update(ctx, id, fields); err != nil {
				return err
			}
			if revoke {
				return repo.RevokeAllRefreshTokens(ctx, id, time.Now().UTC())
			}
			return nil
		})
		if err != nil {
			return nil, fmt.Errorf("update staff: %w", err)
		}
	}
	return s.Get(ctx, id)
}

// ResetPassword sets a new password and revokes all of the staff member's sessions.
func (s *Service) ResetPassword(ctx context.Context, id uuid.UUID, req ResetPasswordRequest) error {
	if _, err := s.Get(ctx, id); err != nil {
		return err
	}
	if !security.ValidPassword(req.NewPassword) {
		return httpx.FieldViolation("new_password", "password_strength")
	}
	hash, err := security.HashPassword(req.NewPassword)
	if err != nil {
		return fmt.Errorf("hash password: %w", err)
	}

	err = database.WithTx(ctx, s.db, func(tx *gorm.DB) error {
		repo := s.repo.WithTx(tx)
		if err := repo.Update(ctx, id, map[string]any{"password_hash": hash}); err != nil {
			return err
		}
		return repo.RevokeAllRefreshTokens(ctx, id, time.Now().UTC())
	})
	if err != nil {
		return fmt.Errorf("reset staff password: %w", err)
	}
	return nil
}

func (s *Service) requireActiveOutlet(ctx context.Context, id uuid.UUID) error {
	o, err := s.outlets.FindByID(ctx, id)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return httpx.NotFound("outlet not found")
	}
	if err != nil {
		return fmt.Errorf("find outlet: %w", err)
	}
	if !o.IsActive {
		return httpx.New(httpx.CodeOutletInactive, "outlet is inactive")
	}
	return nil
}
