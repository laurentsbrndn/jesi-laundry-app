package dashboard

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"gorm.io/gorm"

	"jesi-laundry-app-server/internal/model"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// Filter selects the orders a dashboard covers. IncludeRevenue is false for staff, whose queries never
// read money columns.
type Filter struct {
	OutletID       *uuid.UUID
	From, To       time.Time
	Timezone       string
	Bucket         string
	IncludeRevenue bool
}

type orderBucketRow struct {
	Bucket        time.Time
	Status        model.OrderStatus
	Speed         model.ServiceSpeed
	PaymentStatus model.PaymentStatus
	Orders        int64
	Revenue       int64
}

type itemBucketRow struct {
	Bucket      time.Time
	PricingUnit model.PricingUnit
	Quantity    decimal.Decimal
}

type categoryRow struct {
	Category model.ServiceCategory
	Orders   int64
	Quantity decimal.Decimal
	Revenue  int64
}

type unitServiceRow struct {
	ServiceID   uuid.UUID
	ServiceName string
	PricingUnit model.PricingUnit
	Orders      int64
	Quantity    decimal.Decimal
	Revenue     int64
}

type operationalRow struct {
	Status        model.OrderStatus
	PaymentStatus model.PaymentStatus
	Orders        int64
	Amount        int64
}

// bucketExpr is the only raw SQL in the application: PostgreSQL time bucketing on the business-local
// wall clock. The unit comes from a fixed whitelist; the time zone is a bound parameter (one `?`).
func bucketExpr(bucket string) (string, error) {
	switch bucket {
	case bucketFiveMin:
		return "date_bin('5 minutes', orders.created_at AT TIME ZONE ?, TIMESTAMP '2000-01-01')", nil
	case bucketHour:
		return "date_trunc('hour', orders.created_at AT TIME ZONE ?)", nil
	case bucketDay:
		return "date_trunc('day', orders.created_at AT TIME ZONE ?)", nil
	case bucketMonth:
		return "date_trunc('month', orders.created_at AT TIME ZONE ?)", nil
	case bucketYear:
		return "date_trunc('year', orders.created_at AT TIME ZONE ?)", nil
	}
	return "", fmt.Errorf("unknown bucket %q", bucket)
}

// orders scopes Model(Order) to the filter. GORM adds `deleted_at IS NULL` for the model.
func (r *Repository) orders(ctx context.Context, f Filter) *gorm.DB {
	q := r.db.WithContext(ctx).Model(&model.Order{}).
		Where("orders.created_at >= ? AND orders.created_at <= ?", f.From, f.To)
	if f.OutletID != nil {
		q = q.Where("orders.outlet_id = ?", *f.OutletID)
	}
	return q
}

// items scopes order_items joined to orders. The join bypasses GORM's soft-delete scope, so
// `orders.deleted_at IS NULL` is explicit.
func (r *Repository) items(ctx context.Context, f Filter) *gorm.DB {
	q := r.db.WithContext(ctx).Model(&model.OrderItem{}).
		Joins("JOIN orders ON orders.id = order_items.order_id").
		Where("orders.deleted_at IS NULL AND orders.created_at >= ? AND orders.created_at <= ?", f.From, f.To)
	if f.OutletID != nil {
		q = q.Where("orders.outlet_id = ?", *f.OutletID)
	}
	return q
}

// OrdersByBucket counts orders (and sums revenue) per bucket, status, speed and payment status.
// Totals, by_speed, by_status and the series are all derived from these rows.
func (r *Repository) OrdersByBucket(ctx context.Context, f Filter) ([]orderBucketRow, error) {
	expr, err := bucketExpr(f.Bucket)
	if err != nil {
		return nil, err
	}
	sel := expr + " AS bucket, orders.status AS status, orders.speed AS speed, " +
		"orders.payment_status AS payment_status, COUNT(*) AS orders"
	if f.IncludeRevenue {
		sel += ", COALESCE(SUM(orders.total_amount), 0) AS revenue"
	}

	var rows []orderBucketRow
	err = r.orders(ctx, f).Select(sel, f.Timezone).
		Group("bucket, orders.status, orders.speed, orders.payment_status").
		Scan(&rows).Error
	return rows, err
}

// ItemQuantityByBucket sums actual quantity per bucket and pricing unit.
func (r *Repository) ItemQuantityByBucket(ctx context.Context, f Filter) ([]itemBucketRow, error) {
	expr, err := bucketExpr(f.Bucket)
	if err != nil {
		return nil, err
	}
	sel := expr + " AS bucket, order_items.pricing_unit AS pricing_unit, COALESCE(SUM(order_items.quantity), 0) AS quantity"

	var rows []itemBucketRow
	err = r.items(ctx, f).Select(sel, f.Timezone).
		Group("bucket, order_items.pricing_unit").
		Scan(&rows).Error
	return rows, err
}

// ByCategory aggregates items per service category (distinct orders, quantity, revenue).
func (r *Repository) ByCategory(ctx context.Context, f Filter) ([]categoryRow, error) {
	sel := "order_items.category AS category, COUNT(DISTINCT order_items.order_id) AS orders, " +
		"COALESCE(SUM(order_items.quantity), 0) AS quantity"
	if f.IncludeRevenue {
		sel += ", COALESCE(SUM(order_items.subtotal), 0) AS revenue"
	}

	var rows []categoryRow
	err := r.items(ctx, f).Select(sel).Group("order_items.category").Scan(&rows).Error
	return rows, err
}

// ByUnitService aggregates unit-category items per service. The latest snapshot name is used so
// deleted services still show up.
func (r *Repository) ByUnitService(ctx context.Context, f Filter) ([]unitServiceRow, error) {
	sel := "order_items.service_id AS service_id, MAX(order_items.service_name) AS service_name, " +
		"order_items.pricing_unit AS pricing_unit, COUNT(DISTINCT order_items.order_id) AS orders, " +
		"COALESCE(SUM(order_items.quantity), 0) AS quantity"
	if f.IncludeRevenue {
		sel += ", COALESCE(SUM(order_items.subtotal), 0) AS revenue"
	}

	var rows []unitServiceRow
	err := r.items(ctx, f).Where("order_items.category = ?", model.CategoryUnit).
		Select(sel).Group("order_items.service_id, order_items.pricing_unit").
		Scan(&rows).Error
	return rows, err
}

// Operational counts the current state of non-deleted orders, not limited by any time range.
func (r *Repository) Operational(ctx context.Context, outletID *uuid.UUID, includeRevenue bool) ([]operationalRow, error) {
	q := r.db.WithContext(ctx).Model(&model.Order{})
	if outletID != nil {
		q = q.Where("orders.outlet_id = ?", *outletID)
	}
	sel := "orders.status AS status, orders.payment_status AS payment_status, COUNT(*) AS orders"
	if includeRevenue {
		sel += ", COALESCE(SUM(orders.total_amount), 0) AS amount"
	}

	var rows []operationalRow
	err := q.Select(sel).Group("orders.status, orders.payment_status").Scan(&rows).Error
	return rows, err
}

// FirstOrderAt returns the creation time of the oldest non-deleted order in scope, or nil when there is none.
func (r *Repository) FirstOrderAt(ctx context.Context, outletID *uuid.UUID) (*time.Time, error) {
	q := r.db.WithContext(ctx).Model(&model.Order{})
	if outletID != nil {
		q = q.Where("orders.outlet_id = ?", *outletID)
	}
	var row struct{ FirstAt *time.Time }
	if err := q.Select("MIN(orders.created_at) AS first_at").Scan(&row).Error; err != nil {
		return nil, err
	}
	return row.FirstAt, nil
}
