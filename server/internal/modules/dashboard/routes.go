package dashboard

import "github.com/gofiber/fiber/v3"

// RegisterRoutes mounts GET /dashboard for any signed-in user; revenue is stripped for staff in the service.
func RegisterRoutes(r fiber.Router, h *Handler, requireAuth fiber.Handler) {
	r.Get("/dashboard", requireAuth, h.Get)
}
