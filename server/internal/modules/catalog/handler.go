package catalog

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
	var q ListServicesQuery
	if err := httpx.BindQuery(c, &q); err != nil {
		return err
	}
	services, err := h.svc.List(c.Context(), p, httpx.OptionalUUID(q.OutletID), q.IncludeInactive)
	if err != nil {
		return err
	}
	return httpx.OK(c, newServiceResponses(services))
}

func (h *Handler) Create(c fiber.Ctx) error {
	var req CreateServiceRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	svc, err := h.svc.Create(c.Context(), req)
	if err != nil {
		return err
	}
	return httpx.Created(c, newServiceResponse(svc))
}

func (h *Handler) Update(c fiber.Ctx) error {
	id, err := httpx.ParamUUID(c, "id")
	if err != nil {
		return err
	}
	var req UpdateServiceRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	svc, err := h.svc.Update(c.Context(), id, req)
	if err != nil {
		return err
	}
	return httpx.OK(c, newServiceResponse(svc))
}

func (h *Handler) Delete(c fiber.Ctx) error {
	id, err := httpx.ParamUUID(c, "id")
	if err != nil {
		return err
	}
	if err := h.svc.Delete(c.Context(), id); err != nil {
		return err
	}
	return httpx.NoContent(c)
}
