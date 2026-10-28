package middleware

import (
	"github.com/gofiber/fiber/v3"
	"github.com/google/uuid"

	"jesi-laundry-app-server/internal/model"
	"jesi-laundry-app-server/internal/platform/httpx"
)

// Principal is the authenticated caller, built from the access token claims.
type Principal struct {
	UserID   uuid.UUID
	Role     model.Role
	OutletID *uuid.UUID
}

func (p Principal) IsOwner() bool { return p.Role == model.RoleOwner }

type principalKey struct{}

// PrincipalFrom returns the caller set by RequireAuth, or UNAUTHORIZED when absent.
func PrincipalFrom(c fiber.Ctx) (Principal, error) {
	p, ok := c.Locals(principalKey{}).(Principal)
	if !ok {
		return Principal{}, httpx.Unauthorized("missing credentials")
	}
	return p, nil
}

// ScopedOutletID applies the outlet scoping rule: staff are always pinned to their own outlet,
// owners get the requested outlet (nil = all outlets).
func ScopedOutletID(p Principal, requested *uuid.UUID) *uuid.UUID {
	if p.Role == model.RoleStaff {
		return p.OutletID
	}
	return requested
}
