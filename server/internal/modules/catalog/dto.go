package catalog

import (
	"github.com/google/uuid"
	"github.com/shopspring/decimal"

	"jesi-laundry-app-server/internal/model"
)

type ListServicesQuery struct {
	OutletID        string `query:"outlet_id" validate:"omitempty,uuid"`
	IncludeInactive bool   `query:"include_inactive"`
}

// CreateServiceRequest creates a unit (satuan) service; kilo services are created by the system only.
type CreateServiceRequest struct {
	OutletID            string           `json:"outlet_id" validate:"required,uuid"`
	Name                string           `json:"name" validate:"required,max=100"`
	PricingUnit         string           `json:"pricing_unit" validate:"required,oneof=piece sqm"`
	RegularPrice        *int64           `json:"regular_price" validate:"required,gte=0,lte=1000000000"`
	ExpressPrice        *int64           `json:"express_price" validate:"required,gte=0,lte=1000000000"`
	RegularDurationDays int16            `json:"regular_duration_days" validate:"gte=1,lte=30"`
	ExpressDurationDays int16            `json:"express_duration_days" validate:"gte=1,lte=30"`
	MinQuantity         *decimal.Decimal `json:"min_quantity"`
	SortOrder           *int             `json:"sort_order" validate:"omitempty,gte=0"`
}

// UpdateServiceRequest uses pointers so "not sent" differs from 0/false.
// Category and PricingUnit are accepted only to reject attempts to change them.
type UpdateServiceRequest struct {
	Name                *string          `json:"name" validate:"omitempty,max=100"`
	Category            *string          `json:"category"`
	PricingUnit         *string          `json:"pricing_unit"`
	RegularPrice        *int64           `json:"regular_price" validate:"omitempty,gte=0,lte=1000000000"`
	ExpressPrice        *int64           `json:"express_price" validate:"omitempty,gte=0,lte=1000000000"`
	RegularDurationDays *int16           `json:"regular_duration_days" validate:"omitempty,gte=1,lte=30"`
	ExpressDurationDays *int16           `json:"express_duration_days" validate:"omitempty,gte=1,lte=30"`
	MinQuantity         *decimal.Decimal `json:"min_quantity"`
	IsActive            *bool            `json:"is_active"`
	SortOrder           *int             `json:"sort_order" validate:"omitempty,gte=0"`
}

type ServiceResponse struct {
	ID                  uuid.UUID             `json:"id"`
	OutletID            uuid.UUID             `json:"outlet_id"`
	Category            model.ServiceCategory `json:"category"`
	Name                string                `json:"name"`
	PricingUnit         model.PricingUnit     `json:"pricing_unit"`
	RegularPrice        int64                 `json:"regular_price"`
	ExpressPrice        int64                 `json:"express_price"`
	RegularDurationDays int16                 `json:"regular_duration_days"`
	ExpressDurationDays int16                 `json:"express_duration_days"`
	MinQuantity         decimal.Decimal       `json:"min_quantity"`
	IsSystem            bool                  `json:"is_system"`
	IsActive            bool                  `json:"is_active"`
	SortOrder           int                   `json:"sort_order"`
}

func newServiceResponse(s *model.LaundryService) ServiceResponse {
	return ServiceResponse{
		ID:                  s.ID,
		OutletID:            s.OutletID,
		Category:            s.Category,
		Name:                s.Name,
		PricingUnit:         s.PricingUnit,
		RegularPrice:        s.RegularPrice,
		ExpressPrice:        s.ExpressPrice,
		RegularDurationDays: s.RegularDurationDays,
		ExpressDurationDays: s.ExpressDurationDays,
		MinQuantity:         s.MinQuantity,
		IsSystem:            s.IsSystem,
		IsActive:            s.IsActive,
		SortOrder:           s.SortOrder,
	}
}

func newServiceResponses(services []model.LaundryService) []ServiceResponse {
	out := make([]ServiceResponse, 0, len(services))
	for i := range services {
		out = append(out, newServiceResponse(&services[i]))
	}
	return out
}
