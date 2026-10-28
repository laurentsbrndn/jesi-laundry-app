package httpx

import (
	"errors"
	"log/slog"
	"net/http"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/requestid"
)

type errorEnvelope struct {
	Error errorBody `json:"error"`
}

type errorBody struct {
	Code    string       `json:"code"`
	Message string       `json:"message"`
	Details []FieldError `json:"details,omitempty"`
}

// ErrorHandler converts every error into the standard error envelope.
// Unexpected errors are logged with the request id and returned as INTERNAL_ERROR.
func ErrorHandler(c fiber.Ctx, err error) error {
	var appErr *AppError
	var fiberErr *fiber.Error

	switch {
	case errors.As(err, &appErr):
	case errors.As(err, &fiberErr):
		appErr = fromFiberError(fiberErr)
	default:
		appErr = nil
	}

	if appErr == nil || appErr.Status >= http.StatusInternalServerError {
		slog.Error("request failed",
			"request_id", requestid.FromContext(c),
			"method", c.Method(),
			"path", c.Path(),
			"error", err,
		)
		appErr = New(CodeInternal, "internal server error")
	}

	return c.Status(appErr.Status).JSON(errorEnvelope{Error: errorBody{
		Code:    appErr.Code,
		Message: appErr.Message,
		Details: appErr.Details,
	}})
}

func fromFiberError(e *fiber.Error) *AppError {
	switch {
	case e.Code == http.StatusNotFound:
		return New(CodeNotFound, "route not found")
	case e.Code == http.StatusTooManyRequests:
		return New(CodeRateLimited, "too many requests")
	case e.Code >= 400 && e.Code < 500:
		return &AppError{Status: e.Code, Code: CodeBadRequest, Message: e.Message}
	default:
		return nil
	}
}
