package auth

import (
	"github.com/gofiber/fiber/v3"

	"jesi-laundry-app-server/internal/platform/middleware"
)

// RegisterRoutes mounts /auth/* (public, rate limited where required) and /me (authenticated).
func RegisterRoutes(r fiber.Router, h *Handler, requireAuth fiber.Handler) {
	a := r.Group("/auth")
	a.Get("/setup-status", h.SetupStatus)
	a.Post("/register-owner", middleware.RateLimitPerMinute(5), h.RegisterOwner)
	a.Post("/login", middleware.RateLimitPerMinute(10), h.Login)
	a.Post("/refresh", h.Refresh)
	a.Post("/logout", h.Logout)
	a.Post("/forgot-password", middleware.RateLimitPerMinute(5), h.ForgotPassword)
	a.Post("/reset-password", middleware.RateLimitPerMinute(10), h.ResetPassword)

	r.Get("/me", requireAuth, h.GetMe)
	r.Patch("/me", requireAuth, h.UpdateMe)
	r.Post("/me/change-password", requireAuth, h.ChangePassword)
}
