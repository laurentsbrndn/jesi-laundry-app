package dashboard

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

func (h *Handler) Get(c fiber.Ctx) error {
	p, err := middleware.PrincipalFrom(c)
	if err != nil {
		return err
	}
	var q DashboardQuery
	if err := httpx.BindQuery(c, &q); err != nil {
		return err
	}
	resp, err := h.svc.Get(c.Context(), p, q.Range, httpx.OptionalUUID(q.OutletID))
	if err != nil {
		return err
	}
	return httpx.OK(c, resp)
}
