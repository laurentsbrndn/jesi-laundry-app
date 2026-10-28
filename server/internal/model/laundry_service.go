package model

import (
	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"gorm.io/gorm"
)

type LaundryService struct {
	Base
	OutletID            uuid.UUID       `gorm:"type:uuid;not null;index:idx_laundry_services_outlet_category,priority:1" json:"outlet_id"`
	Category            ServiceCategory `gorm:"type:varchar(20);not null;index:idx_laundry_services_outlet_category,priority:2;check:chk_laundry_services_category,category IN ('wash_iron','iron_only','wash_fold','unit')" json:"category"`
	Name                string          `gorm:"type:varchar(100);not null" json:"name"`
	PricingUnit         PricingUnit     `gorm:"type:varchar(10);not null;check:chk_laundry_services_pricing_unit,pricing_unit IN ('kg','piece','sqm')" json:"pricing_unit"` // immutable after creation (enforced in service)
	RegularPrice        int64           `gorm:"not null;check:chk_laundry_services_regular_price,regular_price >= 0" json:"regular_price"`
	ExpressPrice        int64           `gorm:"not null;check:chk_laundry_services_express_price,express_price >= 0" json:"express_price"`
	RegularDurationDays int16           `gorm:"type:smallint;not null;check:chk_laundry_services_regular_days,regular_duration_days BETWEEN 1 AND 30" json:"regular_duration_days"`
	ExpressDurationDays int16           `gorm:"type:smallint;not null;check:chk_laundry_services_express_days,express_duration_days BETWEEN 1 AND 30" json:"express_duration_days"`
	MinQuantity         decimal.Decimal `gorm:"type:numeric(10,2);not null;default:0;check:chk_laundry_services_min_quantity,min_quantity >= 0" json:"min_quantity"`
	IsSystem            bool            `gorm:"not null;default:false" json:"is_system"`
	IsActive            bool            `gorm:"not null" json:"is_active"` // callers set this explicitly
	SortOrder           int             `gorm:"not null;default:0" json:"sort_order"`
	DeletedAt           gorm.DeletedAt  `gorm:"index" json:"-"`

	Outlet *Outlet `gorm:"foreignKey:OutletID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT" json:"-"`
}
