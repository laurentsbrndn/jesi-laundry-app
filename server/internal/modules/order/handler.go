package order

import (
	"github.com/gofiber/fiber/v3"
	"github.com/google/uuid"

	"jesi-laundry-app-server/internal/platform/httpx"
	"jesi-laundry-app-server/internal/platform/middleware"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) Create(c fiber.Ctx) error {
	p, err := middleware.PrincipalFrom(c)
	if err != nil {
		return err
	}
	var req CreateOrderRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	o, err := h.svc.Create(c.Context(), p, req)
	if err != nil {
		return err
	}
	return httpx.Created(c, newOrderDetailResponse(o))
}

func (h *Handler) List(c fiber.Ctx) error {
	p, err := middleware.PrincipalFrom(c)
	if err != nil {
		return err
	}
	var q ListOrdersQuery
	if err := httpx.BindQuery(c, &q); err != nil {
		return err
	}
	items, meta, err := h.svc.List(c.Context(), p, q)
	if err != nil {
		return err
	}
	return httpx.Paginated(c, newOrderListItemResponses(items), meta)
}

func (h *Handler) Get(c fiber.Ctx) error {
	p, err := middleware.PrincipalFrom(c)
	if err != nil {
		return err
	}
	id, err := httpx.ParamUUID(c, "id")
	if err != nil {
		return err
	}
	o, err := h.svc.Get(c.Context(), p, id)
	if err != nil {
		return err
	}
	return httpx.OK(c, newOrderDetailResponse(o))
}

func (h *Handler) Update(c fiber.Ctx) error {
	p, id, err := h.principalAndID(c)
	if err != nil {
		return err
	}
	var req UpdateOrderRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	o, err := h.svc.Update(c.Context(), p, id, req)
	if err != nil {
		return err
	}
	return httpx.OK(c, newOrderDetailResponse(o))
}

func (h *Handler) ChangeStatus(c fiber.Ctx) error {
	p, id, err := h.principalAndID(c)
	if err != nil {
		return err
	}
	var req ChangeStatusRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	o, err := h.svc.ChangeStatus(c.Context(), p, id, req)
	if err != nil {
		return err
	}
	return httpx.OK(c, newOrderDetailResponse(o))
}

func (h *Handler) ChangePayment(c fiber.Ctx) error {
	p, id, err := h.principalAndID(c)
	if err != nil {
		return err
	}
	var req ChangePaymentRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	o, err := h.svc.ChangePayment(c.Context(), p, id, req)
	if err != nil {
		return err
	}
	return httpx.OK(c, newOrderDetailResponse(o))
}

func (h *Handler) Delete(c fiber.Ctx) error {
	p, id, err := h.principalAndID(c)
	if err != nil {
		return err
	}
	if err := h.svc.Delete(c.Context(), p, id); err != nil {
		return err
	}
	return httpx.NoContent(c)
}

func (h *Handler) principalAndID(c fiber.Ctx) (middleware.Principal, uuid.UUID, error) {
	p, err := middleware.PrincipalFrom(c)
	if err != nil {
		return middleware.Principal{}, uuid.Nil, err
	}
	id, err := httpx.ParamUUID(c, "id")
	if err != nil {
		return middleware.Principal{}, uuid.Nil, err
	}
	return p, id, nil
}
