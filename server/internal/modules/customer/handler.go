package customer

import (
	"github.com/gofiber/fiber/v3"

	"jesi-laundry-app-server/internal/platform/httpx"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) List(c fiber.Ctx) error {
	var q ListCustomersQuery
	if err := httpx.BindQuery(c, &q); err != nil {
		return err
	}
	customers, meta, err := h.svc.List(c.Context(), q.Search, httpx.Page{Page: q.Page, Limit: q.Limit})
	if err != nil {
		return err
	}
	return httpx.Paginated(c, newCustomerResponses(customers), meta)
}

func (h *Handler) Get(c fiber.Ctx) error {
	id, err := httpx.ParamUUID(c, "id")
	if err != nil {
		return err
	}
	cust, err := h.svc.Get(c.Context(), id)
	if err != nil {
		return err
	}
	return httpx.OK(c, newCustomerResponse(cust))
}

func (h *Handler) Update(c fiber.Ctx) error {
	id, err := httpx.ParamUUID(c, "id")
	if err != nil {
		return err
	}
	var req UpdateCustomerRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	cust, err := h.svc.Update(c.Context(), id, req)
	if err != nil {
		return err
	}
	return httpx.OK(c, newCustomerResponse(cust))
}
