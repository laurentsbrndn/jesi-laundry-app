package customer

import "github.com/gofiber/fiber/v3"

// RegisterRoutes mounts /customers. Reads are open to any signed-in user; edits are owner only.
func RegisterRoutes(r fiber.Router, h *Handler, requireAuth, requireOwner fiber.Handler) {
	r.Get("/customers", requireAuth, h.List)
	r.Get("/customers/:id", requireAuth, h.Get)
	r.Patch("/customers/:id", requireAuth, requireOwner, h.Update)
}
