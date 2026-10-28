package outlet

import "github.com/gofiber/fiber/v3"

// RegisterRoutes mounts /outlets. Reads are open to any signed-in user; writes are owner only.
func RegisterRoutes(r fiber.Router, h *Handler, requireAuth, requireOwner fiber.Handler) {
	r.Get("/outlets", requireAuth, h.List)
	r.Post("/outlets", requireAuth, requireOwner, h.Create)
	r.Patch("/outlets/:id", requireAuth, requireOwner, h.Update)
}
