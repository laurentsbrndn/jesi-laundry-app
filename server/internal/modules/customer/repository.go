package customer

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
	Search      string // raw text, matched against the name
	PhoneDigits string // normalized digits, matched against the phone; empty = no phone match
	Offset      int
	Limit       int
}

// List returns one page of customers, most recently active first, and the total match count.
func (r *Repository) List(ctx context.Context, f ListFilter) ([]model.Customer, int64, error) {
	q := r.db.WithContext(ctx).Model(&model.Customer{})
	if f.Search != "" {
		nameLike := "%" + escapeLike(f.Search) + "%"
		if f.PhoneDigits != "" {
			q = q.Where("(name ILIKE ? OR phone LIKE ?)", nameLike, "%"+f.PhoneDigits+"%")
		} else {
			q = q.Where("name ILIKE ?", nameLike)
		}
	}

	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var customers []model.Customer
	err := q.Order("last_order_at DESC NULLS LAST, name ASC").Offset(f.Offset).Limit(f.Limit).Find(&customers).Error
	if err != nil {
		return nil, 0, err
	}
	return customers, total, nil
}

func (r *Repository) FindByID(ctx context.Context, id uuid.UUID) (*model.Customer, error) {
	var c model.Customer
	if err := r.db.WithContext(ctx).First(&c, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &c, nil
}

// FindByNameAndPhone matches lower(name) and the exact phone; a nil phone matches customers without one.
func (r *Repository) FindByNameAndPhone(ctx context.Context, name string, phone *string) (*model.Customer, error) {
	q := r.db.WithContext(ctx).Where("lower(name) = lower(?)", name)
	if phone == nil {
		q = q.Where("phone IS NULL")
	} else {
		q = q.Where("phone = ?", *phone)
	}
	var c model.Customer
	if err := q.First(&c).Error; err != nil {
		return nil, err
	}
	return &c, nil
}

func (r *Repository) Create(ctx context.Context, c *model.Customer) error {
	return r.db.WithContext(ctx).Create(c).Error
}

// Update writes only the given columns (map, so NULL values are applied).
func (r *Repository) Update(ctx context.Context, id uuid.UUID, fields map[string]any) error {
	return r.db.WithContext(ctx).Model(&model.Customer{}).Where("id = ?", id).Updates(fields).Error
}

func (r *Repository) TouchLastOrder(ctx context.Context, id uuid.UUID, at time.Time) error {
	return r.Update(ctx, id, map[string]any{"last_order_at": at})
}

func escapeLike(s string) string {
	return strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(s)
}
