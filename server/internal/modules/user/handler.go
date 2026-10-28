package user

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
	var q ListStaffQuery
	if err := httpx.BindQuery(c, &q); err != nil {
		return err
	}
	users, meta, err := h.svc.List(c.Context(), httpx.OptionalUUID(q.OutletID), q.Search, httpx.Page{Page: q.Page, Limit: q.Limit})
	if err != nil {
		return err
	}
	return httpx.Paginated(c, newStaffResponses(users), meta)
}

func (h *Handler) Create(c fiber.Ctx) error {
	var req CreateStaffRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	u, err := h.svc.Create(c.Context(), req)
	if err != nil {
		return err
	}
	return httpx.Created(c, newStaffResponse(u))
}

func (h *Handler) Get(c fiber.Ctx) error {
	id, err := httpx.ParamUUID(c, "id")
	if err != nil {
		return err
	}
	u, err := h.svc.Get(c.Context(), id)
	if err != nil {
		return err
	}
	return httpx.OK(c, newStaffResponse(u))
}

func (h *Handler) Update(c fiber.Ctx) error {
	id, err := httpx.ParamUUID(c, "id")
	if err != nil {
		return err
	}
	var req UpdateStaffRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	u, err := h.svc.Update(c.Context(), id, req)
	if err != nil {
		return err
	}
	return httpx.OK(c, newStaffResponse(u))
}

func (h *Handler) ResetPassword(c fiber.Ctx) error {
	id, err := httpx.ParamUUID(c, "id")
	if err != nil {
		return err
	}
	var req ResetPasswordRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	if err := h.svc.ResetPassword(c.Context(), id, req); err != nil {
		return err
	}
	return httpx.NoContent(c)
}
