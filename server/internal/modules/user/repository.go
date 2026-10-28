package user

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

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

type ListFilter struct {
	OutletID *uuid.UUID
	Search   string
	Offset   int
	Limit    int
}

// ListStaff returns one page of staff (role = staff) and the total match count.
func (r *Repository) ListStaff(ctx context.Context, f ListFilter) ([]model.User, int64, error) {
	q := r.db.WithContext(ctx).Model(&model.User{}).Where("role = ?", model.RoleStaff)
	if f.OutletID != nil {
		q = q.Where("outlet_id = ?", *f.OutletID)
	}
	if f.Search != "" {
		like := "%" + escapeLike(f.Search) + "%"
		q = q.Where("(name ILIKE ? OR email ILIKE ?)", like, like)
	}

	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var users []model.User
	err := q.Preload("Outlet").Order("name ASC, created_at ASC").Offset(f.Offset).Limit(f.Limit).Find(&users).Error
	if err != nil {
		return nil, 0, err
	}
	return users, total, nil
}

// FindStaffByID only matches staff; owners are never visible through this module.
func (r *Repository) FindStaffByID(ctx context.Context, id uuid.UUID) (*model.User, error) {
	var u model.User
	err := r.db.WithContext(ctx).Preload("Outlet").First(&u, "id = ? AND role = ?", id, model.RoleStaff).Error
	if err != nil {
		return nil, err
	}
	return &u, nil
}

// Create inserts a user. Callers must set IsActive explicitly.
func (r *Repository) Create(ctx context.Context, u *model.User) error {
	return r.db.WithContext(ctx).Create(u).Error
}

// Update writes only the given columns (map, so false/NULL values are applied).
func (r *Repository) Update(ctx context.Context, id uuid.UUID, fields map[string]any) error {
	return r.db.WithContext(ctx).Model(&model.User{}).Where("id = ?", id).Updates(fields).Error
}

func (r *Repository) RevokeAllRefreshTokens(ctx context.Context, userID uuid.UUID, at time.Time) error {
	return r.db.WithContext(ctx).Model(&model.RefreshToken{}).
		Where("user_id = ? AND revoked_at IS NULL", userID).
		Update("revoked_at", at).Error
}

func escapeLike(s string) string {
	return strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(s)
}
