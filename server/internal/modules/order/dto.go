package order

import (
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"

	"jesi-laundry-app-server/internal/model"
)

// ---- requests ----

type CustomerInput struct {
	ID    string `json:"id" validate:"omitempty,uuid"`
	Name  string `json:"name" validate:"omitempty,max=100"`
	Phone string `json:"phone" validate:"omitempty,max=30"`
}

type ItemRequest struct {
	ServiceID string           `json:"service_id" validate:"required,uuid"`
	Quantity  *decimal.Decimal `json:"quantity"`
	LengthM   *decimal.Decimal `json:"length_m"`
	WidthM    *decimal.Decimal `json:"width_m"`
}

type CreateOrderRequest struct {
	OutletID      string        `json:"outlet_id" validate:"omitempty,uuid"`
	Customer      CustomerInput `json:"customer"`
	Speed         string        `json:"speed" validate:"required,oneof=regular express"`
	PaymentStatus string        `json:"payment_status" validate:"omitempty,oneof=unpaid paid"`
	Notes         string        `json:"notes" validate:"omitempty,max=500"`
	Items         []ItemRequest `json:"items" validate:"required,dive"`
}

// UpdateOrderRequest is CreateOrderRequest without the outlet (immutable) and payment status (own endpoint).
type UpdateOrderRequest struct {
	Customer CustomerInput `json:"customer"`
	Speed    string        `json:"speed" validate:"required,oneof=regular express"`
	Notes    string        `json:"notes" validate:"omitempty,max=500"`
	Items    []ItemRequest `json:"items" validate:"required,dive"`
}

type ChangeStatusRequest struct {
	Status string `json:"status" validate:"required,oneof=received processing done picked_up"`
}

type ChangePaymentRequest struct {
	PaymentStatus string `json:"payment_status" validate:"required,oneof=unpaid paid"`
}

type ListOrdersQuery struct {
	Status        string `query:"status" validate:"omitempty,max=100"`
	PaymentStatus string `query:"payment_status" validate:"omitempty,oneof=unpaid paid"`
	Search        string `query:"search" validate:"omitempty,max=100"`
	DateFrom      string `query:"date_from" validate:"omitempty,datetime=2006-01-02"`
	DateTo        string `query:"date_to" validate:"omitempty,datetime=2006-01-02"`
	OutletID      string `query:"outlet_id" validate:"omitempty,uuid"`
	Page          int    `query:"page" validate:"omitempty,gte=1"`
	Limit         int    `query:"limit" validate:"omitempty,gte=1"`
}

// ---- responses ----

type OutletRefResponse struct {
	ID   uuid.UUID `json:"id"`
	Code string    `json:"code"`
	Name string    `json:"name"`
}

type UserRefResponse struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
}

type CustomerRefResponse struct {
	ID    uuid.UUID `json:"id"`
	Name  string    `json:"name"`
	Phone *string   `json:"phone"`
}

type OrderListItemResponse struct {
	ID              uuid.UUID           `json:"id"`
	OrderNumber     string              `json:"order_number"`
	Outlet          OutletRefResponse   `json:"outlet"`
	CustomerName    string              `json:"customer_name"`
	CustomerPhone   *string             `json:"customer_phone"`
	Speed           model.ServiceSpeed  `json:"speed"`
	Status          model.OrderStatus   `json:"status"`
	PaymentStatus   model.PaymentStatus `json:"payment_status"`
	TotalAmount     int64               `json:"total_amount"`
	ItemsCount      int                 `json:"items_count"`
	EstimatedDoneAt time.Time           `json:"estimated_done_at"`
	CreatedAt       time.Time           `json:"created_at"`
}

type OrderItemResponse struct {
	ID             uuid.UUID             `json:"id"`
	ServiceID      uuid.UUID             `json:"service_id"`
	ServiceName    string                `json:"service_name"`
	Category       model.ServiceCategory `json:"category"`
	PricingUnit    model.PricingUnit     `json:"pricing_unit"`
	Quantity       decimal.Decimal       `json:"quantity"`
	LengthM        decimal.NullDecimal   `json:"length_m"`
	WidthM         decimal.NullDecimal   `json:"width_m"`
	BilledQuantity decimal.Decimal       `json:"billed_quantity"`
	UnitPrice      int64                 `json:"unit_price"`
	Subtotal       int64                 `json:"subtotal"`
	DurationDays   int16                 `json:"duration_days"`
}

type OrderDetailResponse struct {
	ID              uuid.UUID           `json:"id"`
	OrderNumber     string              `json:"order_number"`
	Outlet          OutletRefResponse   `json:"outlet"`
	Customer        CustomerRefResponse `json:"customer"`
	Speed           model.ServiceSpeed  `json:"speed"`
	Status          model.OrderStatus   `json:"status"`
	PaymentStatus   model.PaymentStatus `json:"payment_status"`
	TotalAmount     int64               `json:"total_amount"`
	EstimatedDoneAt time.Time           `json:"estimated_done_at"`
	ProcessingAt    *time.Time          `json:"processing_at"`
	DoneAt          *time.Time          `json:"done_at"`
	PickedUpAt      *time.Time          `json:"picked_up_at"`
	PaidAt          *time.Time          `json:"paid_at"`
	Notes           *string             `json:"notes"`
	Items           []OrderItemResponse `json:"items"`
	CreatedBy       UserRefResponse     `json:"created_by"`
	CreatedAt       time.Time           `json:"created_at"`
	UpdatedAt       time.Time           `json:"updated_at"`
}

func outletRef(o *model.Outlet) OutletRefResponse {
	if o == nil {
		return OutletRefResponse{}
	}
	return OutletRefResponse{ID: o.ID, Code: o.Code, Name: o.Name}
}

func newOrderListItemResponses(items []ListItem) []OrderListItemResponse {
	out := make([]OrderListItemResponse, 0, len(items))
	for i := range items {
		o := &items[i].Order
		out = append(out, OrderListItemResponse{
			ID:              o.ID,
			OrderNumber:     o.OrderNumber,
			Outlet:          outletRef(o.Outlet),
			CustomerName:    o.CustomerName,
			CustomerPhone:   o.CustomerPhone,
			Speed:           o.Speed,
			Status:          o.Status,
			PaymentStatus:   o.PaymentStatus,
			TotalAmount:     o.TotalAmount,
			ItemsCount:      items[i].ItemsCount,
			EstimatedDoneAt: o.EstimatedDoneAt.UTC(),
			CreatedAt:       o.CreatedAt.UTC(),
		})
	}
	return out
}

func newOrderDetailResponse(o *model.Order) OrderDetailResponse {
	items := make([]OrderItemResponse, 0, len(o.Items))
	for i := range o.Items {
		it := &o.Items[i]
		items = append(items, OrderItemResponse{
			ID:             it.ID,
			ServiceID:      it.ServiceID,
			ServiceName:    it.ServiceName,
			Category:       it.Category,
			PricingUnit:    it.PricingUnit,
			Quantity:       it.Quantity,
			LengthM:        it.LengthM,
			WidthM:         it.WidthM,
			BilledQuantity: it.BilledQuantity,
			UnitPrice:      it.UnitPrice,
			Subtotal:       it.Subtotal,
			DurationDays:   it.DurationDays,
		})
	}

	resp := OrderDetailResponse{
		ID:              o.ID,
		OrderNumber:     o.OrderNumber,
		Outlet:          outletRef(o.Outlet),
		Customer:        CustomerRefResponse{ID: o.CustomerID, Name: o.CustomerName, Phone: o.CustomerPhone},
		Speed:           o.Speed,
		Status:          o.Status,
		PaymentStatus:   o.PaymentStatus,
		TotalAmount:     o.TotalAmount,
		EstimatedDoneAt: o.EstimatedDoneAt.UTC(),
		ProcessingAt:    utcPtr(o.ProcessingAt),
		DoneAt:          utcPtr(o.DoneAt),
		PickedUpAt:      utcPtr(o.PickedUpAt),
		PaidAt:          utcPtr(o.PaidAt),
		Notes:           o.Notes,
		Items:           items,
		CreatedBy:       UserRefResponse{ID: o.CreatedByID},
		CreatedAt:       o.CreatedAt.UTC(),
		UpdatedAt:       o.UpdatedAt.UTC(),
	}
	if o.CreatedBy != nil {
		resp.CreatedBy.Name = o.CreatedBy.Name
	}
	return resp
}

func utcPtr(t *time.Time) *time.Time {
	if t == nil {
		return nil
	}
	u := t.UTC()
	return &u
}
