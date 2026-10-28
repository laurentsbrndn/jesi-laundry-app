package order

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
	"jesi-laundry-app-server/internal/platform/middleware"
	"jesi-laundry-app-server/internal/platform/timeutil"
)

const (
	defaultLimit = 20
	maxLimit     = 100
)

// CustomerResolver is the part of the customer module used while creating an order (bound to a transaction).
type CustomerResolver interface {
	Resolve(ctx context.Context, id *uuid.UUID, name, phone string) (*model.Customer, error)
	TouchLastOrder(ctx context.Context, id uuid.UUID, at time.Time) error
}

// ServiceReader is the part of the catalog module used to load the services of an order.
type ServiceReader interface {
	FindByIDs(ctx context.Context, ids []uuid.UUID) ([]model.LaundryService, error)
}

// OutletReader is the part of the outlet module used to load the order's outlet.
type OutletReader interface {
	FindByID(ctx context.Context, id uuid.UUID) (*model.Outlet, error)
}

type Service struct {
	db          *gorm.DB
	repo        *Repository
	customersTx func(tx *gorm.DB) CustomerResolver
	servicesTx  func(tx *gorm.DB) ServiceReader
	outlets     OutletReader
}

func NewService(
	db *gorm.DB,
	repo *Repository,
	customersTx func(tx *gorm.DB) CustomerResolver,
	servicesTx func(tx *gorm.DB) ServiceReader,
	outlets OutletReader,
) *Service {
	return &Service{db: db, repo: repo, customersTx: customersTx, servicesTx: servicesTx, outlets: outlets}
}

// Create validates the request, computes prices on the server and stores the order, its items,
// the customer and the order number in one transaction.
func (s *Service) Create(ctx context.Context, p middleware.Principal, req CreateOrderRequest) (*model.Order, error) {
	outletID, err := s.resolveOutletID(p, req.OutletID)
	if err != nil {
		return nil, err
	}
	outlet, err := s.outlets.FindByID(ctx, outletID)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, httpx.NotFound("outlet not found")
	}
	if err != nil {
		return nil, fmt.Errorf("find outlet: %w", err)
	}
	if !outlet.IsActive {
		return nil, httpx.New(httpx.CodeOutletInactive, "outlet is inactive")
	}

	customerID, err := checkCustomerInput(req.Customer)
	if err != nil {
		return nil, err
	}

	speed := model.ServiceSpeed(req.Speed)
	payment := model.PaymentUnpaid
	if req.PaymentStatus != "" {
		payment = model.PaymentStatus(req.PaymentStatus)
	}

	services, results, err := s.priceItems(ctx, s.servicesTx(s.db), outletID, speed, req.Items)
	if err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	order := &model.Order{
		OutletID:        outletID,
		Speed:           speed,
		Status:          model.StatusReceived,
		PaymentStatus:   payment,
		TotalAmount:     TotalAmount(results),
		EstimatedDoneAt: EstimatedDoneAt(now, results),
		Notes:           nilIfEmpty(req.Notes),
		CreatedByID:     p.UserID,
		CreatedAt:       now,
		Items:           newOrderItems(services, results),
	}
	if payment == model.PaymentPaid {
		order.PaidAt = &now
	}

	err = database.WithTx(ctx, s.db, func(tx *gorm.DB) error {
		customers := s.customersTx(tx)
		repo := s.repo.WithTx(tx)

		cust, err := customers.Resolve(ctx, customerID, req.Customer.Name, req.Customer.Phone)
		if err != nil {
			return err
		}
		order.CustomerID = cust.ID
		order.CustomerName = cust.Name
		order.CustomerPhone = cust.Phone

		number, err := nextOrderNumber(ctx, repo, outletID, outlet.Code, now)
		if err != nil {
			return err
		}
		order.OrderNumber = number

		if err := repo.Create(ctx, order); err != nil {
			return err
		}
		return customers.TouchLastOrder(ctx, cust.ID, now)
	})
	if err != nil {
		return nil, txError("create order", err)
	}

	return s.Get(ctx, p, order.ID)
}

// Get returns an order the caller may see; orders of other outlets yield NOT_FOUND for staff.
func (s *Service) Get(ctx context.Context, p middleware.Principal, id uuid.UUID) (*model.Order, error) {
	o, err := s.repo.FindByID(ctx, id, middleware.ScopedOutletID(p, nil))
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, httpx.NotFound("order not found")
	}
	if err != nil {
		return nil, fmt.Errorf("find order: %w", err)
	}
	return o, nil
}

func (s *Service) List(ctx context.Context, p middleware.Principal, q ListOrdersQuery) ([]ListItem, httpx.Meta, error) {
	page := httpx.Page{Page: q.Page, Limit: q.Limit}.Normalize(defaultLimit, maxLimit)

	filter := ListFilter{
		OutletID: middleware.ScopedOutletID(p, httpx.OptionalUUID(q.OutletID)),
		Search:   strings.TrimSpace(q.Search),
		Offset:   page.Offset(),
		Limit:    page.Limit,
	}

	for _, raw := range strings.Split(q.Status, ",") {
		raw = strings.TrimSpace(raw)
		if raw == "" {
			continue
		}
		status := model.OrderStatus(raw)
		if !status.IsValid() {
			return nil, httpx.Meta{}, httpx.FieldViolation("status", "oneof")
		}
		filter.Statuses = append(filter.Statuses, status)
	}
	if q.PaymentStatus != "" {
		ps := model.PaymentStatus(q.PaymentStatus)
		filter.PaymentStatus = &ps
	}
	if q.DateFrom != "" {
		from, err := timeutil.ParseDate(q.DateFrom)
		if err != nil {
			return nil, httpx.Meta{}, httpx.FieldViolation("date_from", "datetime")
		}
		filter.From = &from
	}
	if q.DateTo != "" {
		to, err := timeutil.ParseDate(q.DateTo)
		if err != nil {
			return nil, httpx.Meta{}, httpx.FieldViolation("date_to", "datetime")
		}
		until := to.AddDate(0, 0, 1) // inclusive end date → exclusive next midnight
		filter.Until = &until
	}

	items, total, err := s.repo.List(ctx, filter)
	if err != nil {
		return nil, httpx.Meta{}, fmt.Errorf("list orders: %w", err)
	}
	return items, page.Meta(total), nil
}

// priceItems loads (through reader, which must be bound to the caller's transaction when there is one) and validates the services of all items, then computes every item.
// The returned services slice is index-aligned with the results.
func (s *Service) priceItems(ctx context.Context, reader ServiceReader, outletID uuid.UUID, speed model.ServiceSpeed, reqItems []ItemRequest) ([]model.LaundryService, []ItemResult, error) {
	if ferr := CheckItemCount(len(reqItems)); ferr != nil {
		return nil, nil, httpx.Validation([]httpx.FieldError{*ferr})
	}

	ids := make([]uuid.UUID, len(reqItems))
	for i, it := range reqItems {
		id, err := uuid.Parse(it.ServiceID)
		if err != nil {
			return nil, nil, httpx.FieldViolation(itemField(i, "service_id"), "uuid")
		}
		ids[i] = id
	}
	loaded, err := reader.FindByIDs(ctx, ids)
	if err != nil {
		return nil, nil, fmt.Errorf("load services: %w", err)
	}
	byID := make(map[uuid.UUID]*model.LaundryService, len(loaded))
	for i := range loaded {
		byID[loaded[i].ID] = &loaded[i]
	}

	services := make([]model.LaundryService, len(reqItems))
	results := make([]ItemResult, len(reqItems))
	seenKilo := make(map[uuid.UUID]bool)

	for i, it := range reqItems {
		svc, ok := byID[ids[i]]
		if !ok || !svc.IsActive || svc.OutletID != outletID {
			return nil, nil, serviceInactive(i)
		}
		if svc.Category.IsKilo() {
			if seenKilo[svc.ID] {
				e := httpx.New(httpx.CodeDuplicateKiloService, "kilo service appears more than once")
				e.Details = []httpx.FieldError{{Field: itemField(i, "service_id"), Rule: "duplicate"}}
				return nil, nil, e
			}
			seenKilo[svc.ID] = true
		}

		res, ferr := CalculateItem(svc, speed, ItemInput{Quantity: it.Quantity, LengthM: it.LengthM, WidthM: it.WidthM})
		if ferr != nil {
			return nil, nil, httpx.FieldViolation(itemField(i, ferr.Field), ferr.Rule)
		}
		services[i] = *svc
		results[i] = res
	}
	return services, results, nil
}

// resolveOutletID: staff are pinned to their own outlet (body value ignored); owners must name one.
func (s *Service) resolveOutletID(p middleware.Principal, requested string) (uuid.UUID, error) {
	if !p.IsOwner() {
		if p.OutletID == nil {
			return uuid.Nil, httpx.Forbidden("staff has no outlet")
		}
		return *p.OutletID, nil
	}
	if requested == "" {
		return uuid.Nil, httpx.FieldViolation("outlet_id", "required")
	}
	id, err := uuid.Parse(requested)
	if err != nil {
		return uuid.Nil, httpx.FieldViolation("outlet_id", "uuid")
	}
	return id, nil
}

// checkCustomerInput requires either an existing customer id or a name, and returns the parsed id.
func checkCustomerInput(c CustomerInput) (*uuid.UUID, error) {
	id, err := parseOptionalCustomerID(c.ID)
	if err != nil {
		return nil, err
	}
	if id == nil && strings.TrimSpace(c.Name) == "" {
		return nil, httpx.FieldViolation("customer.name", "required")
	}
	return id, nil
}

// newOrderItems snapshots the services and computed results into order items (index-aligned inputs).
func newOrderItems(services []model.LaundryService, results []ItemResult) []model.OrderItem {
	items := make([]model.OrderItem, len(results))
	for i, res := range results {
		svc := services[i]
		items[i] = model.OrderItem{
			ServiceID:      svc.ID,
			ServiceName:    svc.Name,
			Category:       svc.Category,
			PricingUnit:    svc.PricingUnit,
			Quantity:       res.Quantity,
			LengthM:        res.LengthM,
			WidthM:         res.WidthM,
			BilledQuantity: res.BilledQuantity,
			UnitPrice:      res.UnitPrice,
			Subtotal:       res.Subtotal,
			DurationDays:   res.DurationDays,
		}
	}
	return items
}

// txError keeps business errors (*httpx.AppError) intact and wraps everything else for logging.
func txError(action string, err error) error {
	var appErr *httpx.AppError
	if errors.As(err, &appErr) {
		return appErr
	}
	return fmt.Errorf("%s: %w", action, err)
}

func parseOptionalCustomerID(raw string) (*uuid.UUID, error) {
	if raw == "" {
		return nil, nil
	}
	id, err := uuid.Parse(raw)
	if err != nil {
		return nil, httpx.FieldViolation("customer.id", "uuid")
	}
	return &id, nil
}

func serviceInactive(index int) *httpx.AppError {
	e := httpx.New(httpx.CodeServiceInactive, "service is inactive, deleted, or not in this outlet")
	e.Details = []httpx.FieldError{{Field: itemField(index, "service_id"), Rule: "inactive"}}
	return e
}

func itemField(index int, field string) string {
	return fmt.Sprintf("items[%d].%s", index, field)
}

func nilIfEmpty(s string) *string {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil
	}
	return &s
}

// ---- mutations (B4b) ----
//
// Every mutation locks the order row first (SELECT ... FOR UPDATE) inside a transaction, so concurrent
// requests on the same order are serialized and see each other's result. Check order:
// NOT_FOUND (missing, deleted or outside the caller's outlet) → FORBIDDEN (role) → business rules.

func (s *Service) ChangeStatus(ctx context.Context, p middleware.Principal, id uuid.UUID, req ChangeStatusRequest) (*model.Order, error) {
	err := s.mutate(ctx, p, id, func(repo *Repository, o *model.Order, now time.Time) error {
		fields, aerr := PlanStatusChange(o, model.OrderStatus(req.Status), p.IsOwner(), now)
		if aerr != nil {
			return aerr
		}
		fields["updated_by_id"] = p.UserID
		return repo.UpdateFields(ctx, id, fields)
	})
	if err != nil {
		return nil, txError("change order status", err)
	}
	return s.Get(ctx, p, id)
}

func (s *Service) ChangePayment(ctx context.Context, p middleware.Principal, id uuid.UUID, req ChangePaymentRequest) (*model.Order, error) {
	err := s.mutate(ctx, p, id, func(repo *Repository, o *model.Order, now time.Time) error {
		fields, aerr := PlanPaymentChange(o, model.PaymentStatus(req.PaymentStatus), p.IsOwner(), now)
		if aerr != nil {
			return aerr
		}
		fields["updated_by_id"] = p.UserID
		return repo.UpdateFields(ctx, id, fields)
	})
	if err != nil {
		return nil, txError("change order payment", err)
	}
	return s.Get(ctx, p, id)
}

// Update replaces the content of an unpaid, not-yet-picked-up order, repricing with the current catalog.
// The outlet, status and customers.last_order_at are left alone; created_at stays the base of the estimate.
func (s *Service) Update(ctx context.Context, p middleware.Principal, id uuid.UUID, req UpdateOrderRequest) (*model.Order, error) {
	customerID, err := checkCustomerInput(req.Customer)
	if err != nil {
		return nil, err
	}
	speed := model.ServiceSpeed(req.Speed)

	err = s.mutate(ctx, p, id, func(repo *Repository, o *model.Order, now time.Time) error {
		if !CanEdit(o) {
			return httpx.New(httpx.CodeOrderNotEditable, "order can no longer be edited")
		}

		services, results, err := s.priceItems(ctx, s.servicesTx(repo.db), o.OutletID, speed, req.Items)
		if err != nil {
			return err
		}
		cust, err := s.customersTx(repo.db).Resolve(ctx, customerID, req.Customer.Name, req.Customer.Phone)
		if err != nil {
			return err
		}

		items := newOrderItems(services, results)
		for i := range items {
			items[i].OrderID = o.ID
		}
		if err := repo.ReplaceItems(ctx, o.ID, items); err != nil {
			return err
		}
		return repo.UpdateFields(ctx, o.ID, map[string]any{
			"customer_id":       cust.ID,
			"customer_name":     cust.Name,
			"customer_phone":    cust.Phone,
			"speed":             string(speed),
			"notes":             nilIfEmpty(req.Notes),
			"total_amount":      TotalAmount(results),
			"estimated_done_at": EstimatedDoneAt(o.CreatedAt, results),
			"updated_by_id":     p.UserID,
		})
	})
	if err != nil {
		return nil, txError("update order", err)
	}
	return s.Get(ctx, p, id)
}

// Delete soft-deletes the order, recording who did it. Order numbers are never reused.
func (s *Service) Delete(ctx context.Context, p middleware.Principal, id uuid.UUID) error {
	err := s.mutate(ctx, p, id, func(repo *Repository, o *model.Order, now time.Time) error {
		return repo.SoftDelete(ctx, o.ID, p.UserID)
	})
	if err != nil {
		return txError("delete order", err)
	}
	return nil
}

// mutate runs fn in a transaction holding a row lock on the order. A missing, deleted or out-of-scope
// order yields NOT_FOUND before fn runs.
func (s *Service) mutate(ctx context.Context, p middleware.Principal, id uuid.UUID, fn func(repo *Repository, o *model.Order, now time.Time) error) error {
	return database.WithTx(ctx, s.db, func(tx *gorm.DB) error {
		repo := s.repo.WithTx(tx)
		o, err := repo.FindForUpdate(ctx, id, middleware.ScopedOutletID(p, nil))
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return httpx.NotFound("order not found")
		}
		if err != nil {
			return err
		}
		return fn(repo, o, time.Now().UTC())
	})
}
