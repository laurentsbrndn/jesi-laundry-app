package catalog

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

// CreateDefaults inserts the default service catalog for a newly created outlet.
func (r *Repository) CreateDefaults(ctx context.Context, outletID uuid.UUID) error {
	services := defaultServices(outletID)
	return r.db.WithContext(ctx).Create(&services).Error
}

// Create inserts a service. Callers must set IsActive explicitly.
func (r *Repository) Create(ctx context.Context, s *model.LaundryService) error {
	return r.db.WithContext(ctx).Create(s).Error
}

// List returns the outlet's non-deleted services ordered by sort_order, name.
func (r *Repository) List(ctx context.Context, outletID uuid.UUID, includeInactive bool) ([]model.LaundryService, error) {
	q := r.db.WithContext(ctx).Where("outlet_id = ?", outletID).Order("sort_order ASC, name ASC")
	if !includeInactive {
		q = q.Where("is_active = ?", true)
	}
	var services []model.LaundryService
	if err := q.Find(&services).Error; err != nil {
		return nil, err
	}
	return services, nil
}

// FindByID ignores soft-deleted services.
func (r *Repository) FindByID(ctx context.Context, id uuid.UUID) (*model.LaundryService, error) {
	var s model.LaundryService
	if err := r.db.WithContext(ctx).First(&s, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &s, nil
}

// FindByIDs returns the non-deleted services among ids (missing or deleted ids are simply absent).
func (r *Repository) FindByIDs(ctx context.Context, ids []uuid.UUID) ([]model.LaundryService, error) {
	var services []model.LaundryService
	if err := r.db.WithContext(ctx).Where("id IN ?", ids).Find(&services).Error; err != nil {
		return nil, err
	}
	return services, nil
}

// Update writes only the given columns (map, so false/0 values are applied).
func (r *Repository) Update(ctx context.Context, id uuid.UUID, fields map[string]any) error {
	return r.db.WithContext(ctx).Model(&model.LaundryService{}).Where("id = ?", id).Updates(fields).Error
}

func (r *Repository) SoftDelete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&model.LaundryService{}, "id = ?", id).Error
}

// NameExists checks case-insensitively among non-deleted services of the outlet, optionally excluding one id.
func (r *Repository) NameExists(ctx context.Context, outletID uuid.UUID, name string, excludeID *uuid.UUID) (bool, error) {
	q := r.db.WithContext(ctx).Model(&model.LaundryService{}).
		Where("outlet_id = ? AND lower(name) = lower(?)", outletID, name)
	if excludeID != nil {
		q = q.Where("id <> ?", *excludeID)
	}
	var n int64
	if err := q.Count(&n).Error; err != nil {
		return false, err
	}
	return n > 0, nil
}

// MaxSortOrder returns the highest sort_order among non-deleted services of the outlet (0 when none).
func (r *Repository) MaxSortOrder(ctx context.Context, outletID uuid.UUID) (int, error) {
	var top []model.LaundryService
	err := r.db.WithContext(ctx).Where("outlet_id = ?", outletID).
		Order("sort_order DESC").Limit(1).Find(&top).Error
	if err != nil || len(top) == 0 {
		return 0, err
	}
	return top[0].SortOrder, nil
}
