package customer

import (
	"time"

	"github.com/google/uuid"

	"jesi-laundry-app-server/internal/model"
)

type ListCustomersQuery struct {
	Search string `query:"search" validate:"omitempty,max=100"`
	Page   int    `query:"page" validate:"omitempty,gte=1"`
	Limit  int    `query:"limit" validate:"omitempty,gte=1"`
}

// UpdateCustomerRequest uses pointers so "not sent" differs from "empty". An empty phone clears it.
type UpdateCustomerRequest struct {
	Name  *string `json:"name" validate:"omitempty,max=100"`
	Phone *string `json:"phone" validate:"omitempty,max=30"`
}

type CustomerResponse struct {
	ID          uuid.UUID  `json:"id"`
	Name        string     `json:"name"`
	Phone       *string    `json:"phone"`
	LastOrderAt *time.Time `json:"last_order_at"`
}

func newCustomerResponse(c *model.Customer) CustomerResponse {
	resp := CustomerResponse{ID: c.ID, Name: c.Name, Phone: c.Phone}
	if c.LastOrderAt != nil {
		t := c.LastOrderAt.UTC()
		resp.LastOrderAt = &t
	}
	return resp
}

func newCustomerResponses(customers []model.Customer) []CustomerResponse {
	out := make([]CustomerResponse, 0, len(customers))
	for i := range customers {
		out = append(out, newCustomerResponse(&customers[i]))
	}
	return out
}
