package middleware

import (
	"errors"
	"strings"

	"github.com/gofiber/fiber/v3"
	"github.com/google/uuid"

	"jesi-laundry-app-server/internal/model"
	"jesi-laundry-app-server/internal/platform/httpx"
	"jesi-laundry-app-server/internal/platform/security"
)

const bearerPrefix = "bearer "

// RequireAuth verifies the Bearer access token and stores the Principal in the request context.
func RequireAuth(accessSecret string) fiber.Handler {
	return func(c fiber.Ctx) error {
		header := c.Get(fiber.HeaderAuthorization)
		if len(header) <= len(bearerPrefix) || !strings.EqualFold(header[:len(bearerPrefix)], bearerPrefix) {
			return httpx.Unauthorized("missing or malformed authorization header")
		}

		claims, err := security.ParseAccessToken(accessSecret, strings.TrimSpace(header[len(bearerPrefix):]))
		if err != nil {
			if errors.Is(err, security.ErrTokenExpired) {
				return httpx.New(httpx.CodeTokenExpired, "access token expired")
			}
			return httpx.Unauthorized("invalid access token")
		}

		p, ok := principalFromClaims(claims)
		if !ok {
			return httpx.Unauthorized("invalid access token")
		}
		c.Locals(principalKey{}, p)
		return c.Next()
	}
}

func principalFromClaims(claims *security.AccessClaims) (Principal, bool) {
	userID, err := uuid.Parse(claims.Subject)
	if err != nil {
		return Principal{}, false
	}
	role := model.Role(claims.Role)
	if !role.IsValid() {
		return Principal{}, false
	}

	p := Principal{UserID: userID, Role: role}
	if claims.OutletID != "" {
		oid, err := uuid.Parse(claims.OutletID)
		if err != nil {
			return Principal{}, false
		}
		p.OutletID = &oid
	}
	if role == model.RoleStaff && p.OutletID == nil {
		return Principal{}, false
	}
	return p, true
}
