package middleware

import (
	"time"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/limiter"

	"jesi-laundry-app-server/internal/platform/httpx"
)

// RateLimitPerMinute limits requests per client IP using in-memory storage (per instance).
// Each call returns an independent counter, so apply one per endpoint.
func RateLimitPerMinute(max int) fiber.Handler {
	return limiter.New(limiter.Config{
		Max:        max,
		Expiration: time.Minute,
		KeyGenerator: func(c fiber.Ctx) string {
			return c.IP()
		},
		LimitReached: func(fiber.Ctx) error {
			return httpx.New(httpx.CodeRateLimited, "too many requests")
		},
	})
}
