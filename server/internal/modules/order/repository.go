package order

import (
	"context"
	"strings"
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

type ListFilter struct {
	OutletID      *uuid.UUID
	Statuses      []model.OrderStatus
	PaymentStatus *model.PaymentStatus
	Search        string
	From          *time.Time // inclusive
	Until         *time.Time // exclusive
	Offset        int
	Limit         int
}

// ListItem is one row of the order list with its aggregated item count.
type ListItem struct {
	Order      model.Order
	ItemsCount int
}

// NextSequence upserts the per-outlet, per-day counter and returns the new last_number.
func (r *Repository) NextSequence(ctx context.Context, outletID uuid.UUID, localDate, now time.Time) (int, error) {
	counter := model.OrderCounter{OutletID: outletID, LocalDate: localDate, LastNumber: 1, UpdatedAt: now}
	err := r.db.WithContext(ctx).Clauses(
		clause.OnConflict{
			Columns: []clause.Column{{Name: "outlet_id"}, {Name: "local_date"}},
			DoUpdates: clause.Assignments(map[string]any{
				"last_number": gorm.Expr("order_counters.last_number + ?", 1),
				"updated_at":  now,
			}),
		},
		clause.Returning{Columns: []clause.Column{{Name: "last_number"}}},
	).Create(&counter).Error
	if err != nil {
		return 0, err
	}
	return counter.LastNumber, nil
}

// Create inserts the order together with its items.
func (r *Repository) Create(ctx context.Context, o *model.Order) error {
	return r.db.WithContext(ctx).Create(o).Error
}

// FindByID loads a non-deleted order with outlet, creator and items. When outletID is non-nil the order
// must belong to that outlet, otherwise gorm.ErrRecordNotFound is returned.
func (r *Repository) FindByID(ctx context.Context, id uuid.UUID, outletID *uuid.UUID) (*model.Order, error) {
	q := r.db.WithContext(ctx).
		Preload("Outlet").
		Preload("CreatedBy").
		Preload("Items", func(db *gorm.DB) *gorm.DB { return db.Order("order_items.id ASC") }).
		Where("id = ?", id)
	if outletID != nil {
		q = q.Where("outlet_id = ?", *outletID)
	}
	var o model.Order
	if err := q.First(&o).Error; err != nil {
		return nil, err
	}
	return &o, nil
}

// FindForUpdate loads a non-deleted order and locks its row until the surrounding transaction ends.
// Like FindByID, a non-nil outletID restricts the match to that outlet.
func (r *Repository) FindForUpdate(ctx context.Context, id uuid.UUID, outletID *uuid.UUID) (*model.Order, error) {
	q := r.db.WithContext(ctx).Clauses(clause.Locking{Strength: "UPDATE"}).Where("id = ?", id)
	if outletID != nil {
		q = q.Where("outlet_id = ?", *outletID)
	}
	var o model.Order
	if err := q.First(&o).Error; err != nil {
		return nil, err
	}
	return &o, nil
}

// UpdateFields writes only the given columns (map, so NULL and zero values are applied).
func (r *Repository) UpdateFields(ctx context.Context, id uuid.UUID, fields map[string]any) error {
	return r.db.WithContext(ctx).Model(&model.Order{}).Where("id = ?", id).Updates(fields).Error
}

// ReplaceItems deletes all items of the order and inserts the given ones.
func (r *Repository) ReplaceItems(ctx context.Context, orderID uuid.UUID, items []model.OrderItem) error {
	if err := r.db.WithContext(ctx).Where("order_id = ?", orderID).Delete(&model.OrderItem{}).Error; err != nil {
		return err
	}
	return r.db.WithContext(ctx).Create(&items).Error
}

// SoftDelete records who deleted the order, then sets deleted_at.
func (r *Repository) SoftDelete(ctx context.Context, id, deletedBy uuid.UUID) error {
	fields := map[string]any{"deleted_by_id": deletedBy, "updated_by_id": deletedBy}
	if err := r.UpdateFields(ctx, id, fields); err != nil {
		return err
	}
	return r.db.WithContext(ctx).Delete(&model.Order{}, "id = ?", id).Error
}

// List returns one page of non-deleted orders (newest first), the total match count, and item counts
// loaded with a single grouped query.
func (r *Repository) List(ctx context.Context, f ListFilter) ([]ListItem, int64, error) {
	base := r.db.WithContext(ctx).Model(&model.Order{})
	if f.OutletID != nil {
		base = base.Where("outlet_id = ?", *f.OutletID)
	}
	if len(f.Statuses) > 0 {
		base = base.Where("status IN ?", f.Statuses)
	}
	if f.PaymentStatus != nil {
		base = base.Where("payment_status = ?", *f.PaymentStatus)
	}
	if f.Search != "" {
		like := "%" + escapeLike(f.Search) + "%"
		base = base.Where("(order_number ILIKE ? OR customer_name ILIKE ?)", like, like)
	}
	if f.From != nil {
		base = base.Where("created_at >= ?", *f.From)
	}
	if f.Until != nil {
		base = base.Where("created_at < ?", *f.Until)
	}

	var total int64
	if err := base.Session(&gorm.Session{}).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var orders []model.Order
	err := base.Session(&gorm.Session{}).Preload("Outlet").
		Order("created_at DESC, id DESC").Offset(f.Offset).Limit(f.Limit).Find(&orders).Error
	if err != nil {
		return nil, 0, err
	}
	if len(orders) == 0 {
		return []ListItem{}, total, nil
	}

	ids := make([]uuid.UUID, len(orders))
	for i := range orders {
		ids[i] = orders[i].ID
	}
	counts, err := r.countItems(ctx, ids)
	if err != nil {
		return nil, 0, err
	}

	items := make([]ListItem, len(orders))
	for i := range orders {
		items[i] = ListItem{Order: orders[i], ItemsCount: counts[orders[i].ID]}
	}
	return items, total, nil
}

func (r *Repository) countItems(ctx context.Context, orderIDs []uuid.UUID) (map[uuid.UUID]int, error) {
	var rows []struct {
		OrderID uuid.UUID
		Count   int
	}
	err := r.db.WithContext(ctx).Model(&model.OrderItem{}).
		Select("order_id, COUNT(*) AS count").
		Where("order_id IN ?", orderIDs).
		Group("order_id").
		Scan(&rows).Error
	if err != nil {
		return nil, err
	}
	counts := make(map[uuid.UUID]int, len(rows))
	for _, row := range rows {
		counts[row.OrderID] = row.Count
	}
	return counts, nil
}

func escapeLike(s string) string {
	return strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(s)
}
