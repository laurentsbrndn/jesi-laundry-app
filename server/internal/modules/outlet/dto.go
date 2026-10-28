package outlet

import (
	"time"

	"github.com/google/uuid"

	"jesi-laundry-app-server/internal/model"
)

type CreateOutletRequest struct {
	Code    string `json:"code" validate:"required,min=2,max=5,alphanum"`
	Name    string `json:"name" validate:"required,max=100"`
	Address string `json:"address" validate:"omitempty,max=255"`
	Phone   string `json:"phone" validate:"omitempty,max=20"`
}

// UpdateOutletRequest uses pointers so "not sent" differs from "empty/false". The code is immutable.
type UpdateOutletRequest struct {
	Name     *string `json:"name" validate:"omitempty,max=100"`
	Address  *string `json:"address" validate:"omitempty,max=255"`
	Phone    *string `json:"phone" validate:"omitempty,max=20"`
	IsActive *bool   `json:"is_active"`
}

type OutletResponse struct {
	ID        uuid.UUID `json:"id"`
	Code      string    `json:"code"`
	Name      string    `json:"name"`
	Address   *string   `json:"address"`
	Phone     *string   `json:"phone"`
	IsActive  bool      `json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
}

func newOutletResponse(o *model.Outlet) OutletResponse {
	return OutletResponse{
		ID:        o.ID,
		Code:      o.Code,
		Name:      o.Name,
		Address:   o.Address,
		Phone:     o.Phone,
		IsActive:  o.IsActive,
		CreatedAt: o.CreatedAt.UTC(),
	}
}

func newOutletResponses(outlets []model.Outlet) []OutletResponse {
	out := make([]OutletResponse, 0, len(outlets))
	for i := range outlets {
		out = append(out, newOutletResponse(&outlets[i]))
	}
	return out
}
