package httpx

import (
	"errors"
	"strings"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v3"

	"jesi-laundry-app-server/internal/platform/validation"
)

// BindBody parses the JSON body into dst and validates it.
func BindBody(c fiber.Ctx, dst any) error {
	if err := c.Bind().Body(dst); err != nil {
		return BadRequest("invalid request body")
	}
	return validate(dst)
}

// BindQuery parses the query string into dst and validates it.
func BindQuery(c fiber.Ctx, dst any) error {
	if err := c.Bind().Query(dst); err != nil {
		return BadRequest("invalid query parameters")
	}
	return validate(dst)
}

func validate(dst any) error {
	err := validation.Validator().Struct(dst)
	if err == nil {
		return nil
	}

	var verrs validator.ValidationErrors
	if !errors.As(err, &verrs) {
		return err
	}
	details := make([]FieldError, 0, len(verrs))
	for _, fe := range verrs {
		details = append(details, FieldError{Field: fieldPath(fe.Namespace()), Rule: fe.Tag(), Param: fe.Param()})
	}
	return Validation(details)
}

// fieldPath drops the leading struct name from a validator namespace ("Req.items[0].quantity" → "items[0].quantity").
func fieldPath(namespace string) string {
	if _, rest, ok := strings.Cut(namespace, "."); ok {
		return rest
	}
	return namespace
}
