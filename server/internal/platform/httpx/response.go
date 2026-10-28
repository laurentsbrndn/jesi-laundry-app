package httpx

import (
	"net/http"

	"github.com/gofiber/fiber/v3"
)

type dataEnvelope struct {
	Data any `json:"data"`
}

type pagedEnvelope struct {
	Data any  `json:"data"`
	Meta Meta `json:"meta"`
}

// Meta is the pagination block of a list response.
type Meta struct {
	Page  int   `json:"page"`
	Limit int   `json:"limit"`
	Total int64 `json:"total"`
}

func OK(c fiber.Ctx, data any) error {
	return c.Status(http.StatusOK).JSON(dataEnvelope{Data: data})
}

func Created(c fiber.Ctx, data any) error {
	return c.Status(http.StatusCreated).JSON(dataEnvelope{Data: data})
}

func Paginated(c fiber.Ctx, data any, meta Meta) error {
	return c.Status(http.StatusOK).JSON(pagedEnvelope{Data: data, Meta: meta})
}

func NoContent(c fiber.Ctx) error {
	return c.SendStatus(http.StatusNoContent)
}
