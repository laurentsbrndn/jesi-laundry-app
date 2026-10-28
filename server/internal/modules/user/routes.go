package user

import "github.com/gofiber/fiber/v3"

// RegisterRoutes mounts /users (staff management). Every route is owner only.
func RegisterRoutes(r fiber.Router, h *Handler, requireAuth, requireOwner fiber.Handler) {
	r.Get("/users", requireAuth, requireOwner, h.List)
	r.Post("/users", requireAuth, requireOwner, h.Create)
	r.Get("/users/:id", requireAuth, requireOwner, h.Get)
	r.Patch("/users/:id", requireAuth, requireOwner, h.Update)
	r.Post("/users/:id/reset-password", requireAuth, requireOwner, h.ResetPassword)
}
