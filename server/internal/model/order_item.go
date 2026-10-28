package model

import (
	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

type OrderItem struct {
	Base
	OrderID        uuid.UUID           `gorm:"type:uuid;not null;index" json:"order_id"`
	ServiceID      uuid.UUID           `gorm:"type:uuid;not null;index" json:"service_id"`
	ServiceName    string              `gorm:"type:varchar(100);not null" json:"service_name"`
	Category       ServiceCategory     `gorm:"type:varchar(20);not null" json:"category"`
	PricingUnit    PricingUnit         `gorm:"type:varchar(10);not null" json:"pricing_unit"`
	Quantity       decimal.Decimal     `gorm:"type:numeric(10,2);not null" json:"quantity"`
	LengthM        decimal.NullDecimal `gorm:"type:numeric(10,2)" json:"length_m"`
	WidthM         decimal.NullDecimal `gorm:"type:numeric(10,2)" json:"width_m"`
	BilledQuantity decimal.Decimal     `gorm:"type:numeric(10,2);not null" json:"billed_quantity"`
	UnitPrice      int64               `gorm:"not null" json:"unit_price"`
	Subtotal       int64               `gorm:"not null" json:"subtotal"`
	DurationDays   int16               `gorm:"type:smallint;not null" json:"duration_days"`

	Service *LaundryService `gorm:"foreignKey:ServiceID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT" json:"-"`
}
