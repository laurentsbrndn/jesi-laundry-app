package httpx

import (
	"github.com/gofiber/fiber/v3"
	"github.com/google/uuid"
)

// ParamUUID parses a UUID route parameter. A malformed id cannot match any resource, so it yields NOT_FOUND.
func ParamUUID(c fiber.Ctx, name string) (uuid.UUID, error) {
	id, err := uuid.Parse(c.Params(name))
	if err != nil {
		return uuid.Nil, NotFound("resource not found")
	}
	return id, nil
}

// OptionalUUID parses an optional UUID string (already validated with the `uuid` rule); empty yields nil.
func OptionalUUID(s string) *uuid.UUID {
	if s == "" {
		return nil
	}
	id, err := uuid.Parse(s)
	if err != nil {
		return nil
	}
	return &id
}
