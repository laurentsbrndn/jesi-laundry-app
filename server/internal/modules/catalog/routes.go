package catalog

import "github.com/gofiber/fiber/v3"

// RegisterRoutes mounts /services. Reads are open to any signed-in user; writes are owner only.
func RegisterRoutes(r fiber.Router, h *Handler, requireAuth, requireOwner fiber.Handler) {
	r.Get("/services", requireAuth, h.List)
	r.Post("/services", requireAuth, requireOwner, h.Create)
	r.Patch("/services/:id", requireAuth, requireOwner, h.Update)
	r.Delete("/services/:id", requireAuth, requireOwner, h.Delete)
}
