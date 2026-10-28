package order

import "github.com/gofiber/fiber/v3"

// RegisterRoutes mounts /orders. Reading, creating and moving status/payment forward are open to any
// signed-in user (role limits on reverting are enforced in the service); edit and delete are owner only.
func RegisterRoutes(r fiber.Router, h *Handler, requireAuth, requireOwner fiber.Handler) {
	r.Get("/orders", requireAuth, h.List)
	r.Post("/orders", requireAuth, h.Create)
	r.Get("/orders/:id", requireAuth, h.Get)
	r.Put("/orders/:id", requireAuth, requireOwner, h.Update)
	r.Patch("/orders/:id/status", requireAuth, h.ChangeStatus)
	r.Patch("/orders/:id/payment", requireAuth, h.ChangePayment)
	r.Delete("/orders/:id", requireAuth, requireOwner, h.Delete)
}
