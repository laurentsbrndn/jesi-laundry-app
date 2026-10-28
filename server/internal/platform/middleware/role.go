package middleware

import (
	"github.com/gofiber/fiber/v3"

	"jesi-laundry-app-server/internal/platform/httpx"
)

// RequireOwner must run after RequireAuth.
func RequireOwner() fiber.Handler {
	return func(c fiber.Ctx) error {
		p, err := PrincipalFrom(c)
		if err != nil {
			return err
		}
		if !p.IsOwner() {
			return httpx.Forbidden("owner access required")
		}
		return c.Next()
	}
}
