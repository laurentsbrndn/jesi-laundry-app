package outlet

import (
	"context"

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

// Create inserts an outlet. Callers must set IsActive explicitly.
func (r *Repository) Create(ctx context.Context, o *model.Outlet) error {
	return r.db.WithContext(ctx).Create(o).Error
}

func (r *Repository) FindByID(ctx context.Context, id uuid.UUID) (*model.Outlet, error) {
	var o model.Outlet
	if err := r.db.WithContext(ctx).First(&o, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &o, nil
}

// List returns all outlets, or only onlyID when it is non-nil.
func (r *Repository) List(ctx context.Context, onlyID *uuid.UUID) ([]model.Outlet, error) {
	q := r.db.WithContext(ctx).Order("created_at ASC")
	if onlyID != nil {
		q = q.Where("id = ?", *onlyID)
	}
	var outlets []model.Outlet
	if err := q.Find(&outlets).Error; err != nil {
		return nil, err
	}
	return outlets, nil
}

// Update writes only the given columns (map, so false/NULL values are applied).
func (r *Repository) Update(ctx context.Context, id uuid.UUID, fields map[string]any) error {
	return r.db.WithContext(ctx).Model(&model.Outlet{}).Where("id = ?", id).Updates(fields).Error
}
