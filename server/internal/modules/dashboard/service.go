package dashboard

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"gorm.io/gorm"

	"jesi-laundry-app-server/internal/model"
	"jesi-laundry-app-server/internal/platform/httpx"
	"jesi-laundry-app-server/internal/platform/middleware"
	"jesi-laundry-app-server/internal/platform/timeutil"
)

// Fixed output orders, so arrays always have the same shape.
var (
	categoryOrder = []model.ServiceCategory{model.CategoryWashIron, model.CategoryIronOnly, model.CategoryWashFold, model.CategoryUnit}
	speedOrder    = []model.ServiceSpeed{model.SpeedRegular, model.SpeedExpress}
	statusOrder   = []model.OrderStatus{model.StatusReceived, model.StatusProcessing, model.StatusDone, model.StatusPickedUp}
)

// OutletFinder is the part of the outlet module used to validate an owner's outlet filter.
type OutletFinder interface {
	FindByID(ctx context.Context, id uuid.UUID) (*model.Outlet, error)
}

type Service struct {
	repo    *Repository
	outlets OutletFinder
}

func NewService(repo *Repository, outlets OutletFinder) *Service {
	return &Service{repo: repo, outlets: outlets}
}

// Get builds the dashboard. Staff are pinned to their own outlet and never receive revenue fields
// (those queries are not even run with money columns).
func (s *Service) Get(ctx context.Context, p middleware.Principal, rangeName string, requested *uuid.UUID) (*Response, error) {
	spec, ok := ParseRange(rangeName)
	if !ok {
		return nil, httpx.Validation([]httpx.FieldError{{Field: "range", Rule: "oneof", Param: "1h 24h 7d 30d 1y all"}})
	}

	outletID := middleware.ScopedOutletID(p, requested)
	if p.IsOwner() && outletID != nil {
		if _, err := s.outlets.FindByID(ctx, *outletID); errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, httpx.NotFound("outlet not found")
		} else if err != nil {
			return nil, fmt.Errorf("find outlet: %w", err)
		}
	}

	loc := timeutil.Location()
	now := time.Now()
	from, to := spec.Window(now, loc)
	if spec.Name == "all" {
		var err error
		if from, to, spec.Bucket, err = s.allWindow(ctx, outletID, now, loc); err != nil {
			return nil, err
		}
	}
	f := Filter{
		OutletID:       outletID,
		From:           from,
		To:             to,
		Timezone:       loc.String(),
		Bucket:         spec.Bucket,
		IncludeRevenue: p.IsOwner(),
	}

	orderRows, err := s.repo.OrdersByBucket(ctx, f)
	if err != nil {
		return nil, fmt.Errorf("dashboard orders: %w", err)
	}
	itemRows, err := s.repo.ItemQuantityByBucket(ctx, f)
	if err != nil {
		return nil, fmt.Errorf("dashboard item quantities: %w", err)
	}
	categoryRows, err := s.repo.ByCategory(ctx, f)
	if err != nil {
		return nil, fmt.Errorf("dashboard categories: %w", err)
	}
	serviceRows, err := s.repo.ByUnitService(ctx, f)
	if err != nil {
		return nil, fmt.Errorf("dashboard unit services: %w", err)
	}
	opRows, err := s.repo.Operational(ctx, outletID, f.IncludeRevenue)
	if err != nil {
		return nil, fmt.Errorf("dashboard operational: %w", err)
	}

	resp := &Response{
		Range:         spec.Name,
		Bucket:        spec.Bucket,
		From:          from,
		To:            to,
		Timezone:      loc.String(),
		OutletID:      outletID,
		ByCategory:    buildCategories(categoryRows),
		ByUnitService: buildUnitServices(serviceRows),
		Operational:   buildOperational(opRows),
	}
	s.fillOrders(resp, orderRows, itemRows, spec, loc)

	if !f.IncludeRevenue {
		stripRevenue(resp)
	}
	return resp, nil
}

// fillOrders derives totals, by_speed, by_status and the gap-filled series from the grouped rows.
func (s *Service) fillOrders(resp *Response, orderRows []orderBucketRow, itemRows []itemBucketRow, spec RangeSpec, loc *time.Location) {
	type point struct {
		orders  int64
		weight  decimal.Decimal
		revenue int64
	}
	points := make(map[int64]*point)
	order := buckets(spec.Bucket, resp.From, resp.To, loc)
	for _, b := range order {
		points[b.Unix()] = &point{}
	}

	var totalOrders, revenue, revenuePaid, revenueUnpaid int64
	speedOrders := map[model.ServiceSpeed]int64{}
	speedRevenue := map[model.ServiceSpeed]int64{}
	statusOrders := map[model.OrderStatus]int64{}

	for _, r := range orderRows {
		totalOrders += r.Orders
		revenue += r.Revenue
		if r.PaymentStatus == model.PaymentPaid {
			revenuePaid += r.Revenue
		} else {
			revenueUnpaid += r.Revenue
		}
		speedOrders[r.Speed] += r.Orders
		speedRevenue[r.Speed] += r.Revenue
		statusOrders[r.Status] += r.Orders

		if pt, ok := points[wallToLocal(r.Bucket, loc).Unix()]; ok {
			pt.orders += r.Orders
			pt.revenue += r.Revenue
		}
	}

	var weightKg, unitPieces, areaSqm decimal.Decimal
	for _, r := range itemRows {
		switch r.PricingUnit {
		case model.PricingUnitKg:
			weightKg = weightKg.Add(r.Quantity)
			if pt, ok := points[wallToLocal(r.Bucket, loc).Unix()]; ok {
				pt.weight = pt.weight.Add(r.Quantity)
			}
		case model.PricingUnitPiece:
			unitPieces = unitPieces.Add(r.Quantity)
		case model.PricingUnitSqm:
			areaSqm = areaSqm.Add(r.Quantity)
		}
	}

	resp.Totals = Totals{
		Orders:        totalOrders,
		WeightKg:      weightKg,
		UnitPieces:    unitPieces,
		AreaSqm:       areaSqm,
		Revenue:       &revenue,
		RevenuePaid:   &revenuePaid,
		RevenueUnpaid: &revenueUnpaid,
	}

	resp.BySpeed = make([]SpeedStat, 0, len(speedOrder))
	for _, sp := range speedOrder {
		rev := speedRevenue[sp]
		resp.BySpeed = append(resp.BySpeed, SpeedStat{Speed: sp, Orders: speedOrders[sp], Revenue: &rev})
	}
	resp.ByStatus = make([]StatusStat, 0, len(statusOrder))
	for _, st := range statusOrder {
		resp.ByStatus = append(resp.ByStatus, StatusStat{Status: st, Orders: statusOrders[st]})
	}

	resp.Series = make([]SeriesPoint, 0, len(order))
	for _, b := range order {
		pt := points[b.Unix()]
		rev := pt.revenue
		resp.Series = append(resp.Series, SeriesPoint{
			BucketStart: b.Format(time.RFC3339),
			Orders:      pt.orders,
			WeightKg:    pt.weight,
			Revenue:     &rev,
		})
	}
}

func buildCategories(rows []categoryRow) []CategoryStat {
	byCat := make(map[model.ServiceCategory]categoryRow, len(rows))
	for _, r := range rows {
		byCat[r.Category] = r
	}
	out := make([]CategoryStat, 0, len(categoryOrder))
	for _, c := range categoryOrder {
		r := byCat[c]
		rev := r.Revenue
		out = append(out, CategoryStat{Category: c, Orders: r.Orders, Quantity: r.Quantity, Revenue: &rev})
	}
	return out
}

func buildUnitServices(rows []unitServiceRow) []UnitServiceStat {
	out := make([]UnitServiceStat, 0, len(rows))
	for _, r := range rows {
		rev := r.Revenue
		out = append(out, UnitServiceStat{
			ServiceID:   r.ServiceID,
			ServiceName: r.ServiceName,
			PricingUnit: r.PricingUnit,
			Orders:      r.Orders,
			Quantity:    r.Quantity,
			Revenue:     &rev,
		})
	}
	sort.SliceStable(out, func(i, j int) bool {
		if out[i].Orders != out[j].Orders {
			return out[i].Orders > out[j].Orders
		}
		return out[i].ServiceName < out[j].ServiceName
	})
	return out
}

func buildOperational(rows []operationalRow) Operational {
	var op Operational
	var unpaidAmount int64
	for _, r := range rows {
		switch r.Status {
		case model.StatusReceived, model.StatusProcessing:
			op.InProgress += r.Orders
		case model.StatusDone:
			op.ReadyForPickup += r.Orders
		}
		if r.PaymentStatus == model.PaymentUnpaid && r.Status != model.StatusPickedUp {
			op.UnpaidOrders += r.Orders
			unpaidAmount += r.Amount
		}
	}
	op.UnpaidAmount = &unpaidAmount
	return op
}

// stripRevenue removes every money field so it is absent from the JSON, not merely hidden by the client.
func stripRevenue(r *Response) {
	r.Totals.Revenue, r.Totals.RevenuePaid, r.Totals.RevenueUnpaid = nil, nil, nil
	for i := range r.ByCategory {
		r.ByCategory[i].Revenue = nil
	}
	for i := range r.ByUnitService {
		r.ByUnitService[i].Revenue = nil
	}
	for i := range r.BySpeed {
		r.BySpeed[i].Revenue = nil
	}
	for i := range r.Series {
		r.Series[i].Revenue = nil
	}
	r.Operational.UnpaidAmount = nil
}

// allWindow starts at the oldest order in scope (one extra query). With no orders the window is
// [now, now] in month buckets, giving a single zero-valued current-month bucket.
func (s *Service) allWindow(ctx context.Context, outletID *uuid.UUID, now time.Time, loc *time.Location) (from, to time.Time, bucket string, err error) {
	first, err := s.repo.FirstOrderAt(ctx, outletID)
	if err != nil {
		return time.Time{}, time.Time{}, "", fmt.Errorf("dashboard first order: %w", err)
	}
	to = now.UTC()
	if first == nil {
		return to, to, bucketMonth, nil
	}
	from = first.UTC()
	return from, to, AllBucket(from, to, loc), nil
}
