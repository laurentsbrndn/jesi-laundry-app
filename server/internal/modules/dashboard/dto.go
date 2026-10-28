package dashboard

import (
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"

	"jesi-laundry-app-server/internal/model"
)

type DashboardQuery struct {
	Range    string `query:"range" validate:"omitempty,oneof=1h 24h 7d 30d 1y all"`
	OutletID string `query:"outlet_id" validate:"omitempty,uuid"`
}

// Revenue fields are pointers with omitempty: the service leaves them nil for staff, so the keys are
// absent from the JSON. A real zero (owner, no sales) is a non-nil pointer and is still sent.

type Totals struct {
	Orders        int64           `json:"orders"`
	WeightKg      decimal.Decimal `json:"weight_kg"`
	UnitPieces    decimal.Decimal `json:"unit_pieces"`
	AreaSqm       decimal.Decimal `json:"area_sqm"`
	Revenue       *int64          `json:"revenue,omitempty"`
	RevenuePaid   *int64          `json:"revenue_paid,omitempty"`
	RevenueUnpaid *int64          `json:"revenue_unpaid,omitempty"`
}

type CategoryStat struct {
	Category model.ServiceCategory `json:"category"`
	Orders   int64                 `json:"orders"`
	Quantity decimal.Decimal       `json:"quantity"`
	Revenue  *int64                `json:"revenue,omitempty"`
}

type UnitServiceStat struct {
	ServiceID   uuid.UUID         `json:"service_id"`
	ServiceName string            `json:"service_name"`
	PricingUnit model.PricingUnit `json:"pricing_unit"`
	Orders      int64             `json:"orders"`
	Quantity    decimal.Decimal   `json:"quantity"`
	Revenue     *int64            `json:"revenue,omitempty"`
}

type SpeedStat struct {
	Speed   model.ServiceSpeed `json:"speed"`
	Orders  int64              `json:"orders"`
	Revenue *int64             `json:"revenue,omitempty"`
}

type StatusStat struct {
	Status model.OrderStatus `json:"status"`
	Orders int64             `json:"orders"`
}

type SeriesPoint struct {
	BucketStart string          `json:"bucket_start"` // RFC 3339 with the business zone offset
	Orders      int64           `json:"orders"`
	WeightKg    decimal.Decimal `json:"weight_kg"`
	Revenue     *int64          `json:"revenue,omitempty"`
}

type Operational struct {
	InProgress     int64  `json:"in_progress"`
	ReadyForPickup int64  `json:"ready_for_pickup"`
	UnpaidOrders   int64  `json:"unpaid_orders"`
	UnpaidAmount   *int64 `json:"unpaid_amount,omitempty"`
}

type Response struct {
	Range         string            `json:"range"`
	Bucket        string            `json:"bucket"`
	From          time.Time         `json:"from"`
	To            time.Time         `json:"to"`
	Timezone      string            `json:"timezone"`
	OutletID      *uuid.UUID        `json:"outlet_id"`
	Totals        Totals            `json:"totals"`
	ByCategory    []CategoryStat    `json:"by_category"`
	ByUnitService []UnitServiceStat `json:"by_unit_service"`
	BySpeed       []SpeedStat       `json:"by_speed"`
	ByStatus      []StatusStat      `json:"by_status"`
	Series        []SeriesPoint     `json:"series"`
	Operational   Operational       `json:"operational"`
}
