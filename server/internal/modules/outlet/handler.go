package outlet

import (
	"github.com/gofiber/fiber/v3"

	"jesi-laundry-app-server/internal/platform/httpx"
	"jesi-laundry-app-server/internal/platform/middleware"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) List(c fiber.Ctx) error {
	p, err := middleware.PrincipalFrom(c)
	if err != nil {
		return err
	}
	outlets, err := h.svc.List(c.Context(), p)
	if err != nil {
		return err
	}
	return httpx.OK(c, newOutletResponses(outlets))
}

func (h *Handler) Create(c fiber.Ctx) error {
	var req CreateOutletRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	o, err := h.svc.Create(c.Context(), req)
	if err != nil {
		return err
	}
	return httpx.Created(c, newOutletResponse(o))
}

func (h *Handler) Update(c fiber.Ctx) error {
	id, err := httpx.ParamUUID(c, "id")
	if err != nil {
		return err
	}
	var req UpdateOutletRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	o, err := h.svc.Update(c.Context(), id, req)
	if err != nil {
		return err
	}
	return httpx.OK(c, newOutletResponse(o))
}
