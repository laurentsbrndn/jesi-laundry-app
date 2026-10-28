package httpx

import "net/http"

// Stable error codes shared with the mobile client (ARCHITECTURE.md §8.1).
const (
	CodeBadRequest                = "BAD_REQUEST"
	CodeValidationError           = "VALIDATION_ERROR"
	CodeUnauthorized              = "UNAUTHORIZED"
	CodeTokenExpired              = "TOKEN_EXPIRED"
	CodeInvalidRefreshToken       = "INVALID_REFRESH_TOKEN"
	CodeInvalidCredentials        = "INVALID_CREDENTIALS"
	CodeAccountInactive           = "ACCOUNT_INACTIVE"
	CodeForbidden                 = "FORBIDDEN"
	CodeNotFound                  = "NOT_FOUND"
	CodeEmailTaken                = "EMAIL_TAKEN"
	CodeOwnerAlreadyExists        = "OWNER_ALREADY_EXISTS"
	CodeOutletCodeTaken           = "OUTLET_CODE_TAKEN"
	CodeServiceNameTaken          = "SERVICE_NAME_TAKEN"
	CodeOutletInactive            = "OUTLET_INACTIVE"
	CodeServiceInactive           = "SERVICE_INACTIVE"
	CodeDuplicateKiloService      = "DUPLICATE_KILO_SERVICE"
	CodeInvalidStatusTransition   = "INVALID_STATUS_TRANSITION"
	CodePaymentRequired           = "PAYMENT_REQUIRED"
	CodeOrderNotEditable          = "ORDER_NOT_EDITABLE"
	CodeSystemServiceNotDeletable = "SYSTEM_SERVICE_NOT_DELETABLE"
	CodeOTPInvalid                = "OTP_INVALID"
	CodeOTPExpired                = "OTP_EXPIRED"
	CodeOTPTooManyAttempts        = "OTP_TOO_MANY_ATTEMPTS"
	CodeRateLimited               = "RATE_LIMITED"
	CodeInternal                  = "INTERNAL_ERROR"
)

var statusByCode = map[string]int{
	CodeBadRequest:                http.StatusBadRequest,
	CodeValidationError:           http.StatusUnprocessableEntity,
	CodeUnauthorized:              http.StatusUnauthorized,
	CodeTokenExpired:              http.StatusUnauthorized,
	CodeInvalidRefreshToken:       http.StatusUnauthorized,
	CodeInvalidCredentials:        http.StatusUnauthorized,
	CodeAccountInactive:           http.StatusForbidden,
	CodeForbidden:                 http.StatusForbidden,
	CodeNotFound:                  http.StatusNotFound,
	CodeEmailTaken:                http.StatusConflict,
	CodeOwnerAlreadyExists:        http.StatusConflict,
	CodeOutletCodeTaken:           http.StatusConflict,
	CodeServiceNameTaken:          http.StatusConflict,
	CodeOutletInactive:            http.StatusUnprocessableEntity,
	CodeServiceInactive:           http.StatusUnprocessableEntity,
	CodeDuplicateKiloService:      http.StatusUnprocessableEntity,
	CodeInvalidStatusTransition:   http.StatusUnprocessableEntity,
	CodePaymentRequired:           http.StatusUnprocessableEntity,
	CodeOrderNotEditable:          http.StatusUnprocessableEntity,
	CodeSystemServiceNotDeletable: http.StatusUnprocessableEntity,
	CodeOTPInvalid:                http.StatusBadRequest,
	CodeOTPExpired:                http.StatusBadRequest,
	CodeOTPTooManyAttempts:        http.StatusTooManyRequests,
	CodeRateLimited:               http.StatusTooManyRequests,
	CodeInternal:                  http.StatusInternalServerError,
}

// FieldError describes one failed validation rule.
type FieldError struct {
	Field string `json:"field"`
	Rule  string `json:"rule"`
	Param string `json:"param,omitempty"` // rule parameter, e.g. the allowed values of oneof
}

// AppError is a business/transport error that maps directly to the API error envelope.
type AppError struct {
	Status  int
	Code    string
	Message string
	Details []FieldError
}

func (e *AppError) Error() string { return e.Code + ": " + e.Message }

// New builds an AppError; the HTTP status is derived from the code.
func New(code, message string) *AppError {
	status, ok := statusByCode[code]
	if !ok {
		status = http.StatusInternalServerError
	}
	return &AppError{Status: status, Code: code, Message: message}
}

func BadRequest(message string) *AppError { return New(CodeBadRequest, message) }

func Validation(details []FieldError) *AppError {
	e := New(CodeValidationError, "validation failed")
	e.Details = details
	return e
}

// FieldViolation is a VALIDATION_ERROR for a single field, for rules that depend on data or state.
func FieldViolation(field, rule string) *AppError {
	return Validation([]FieldError{{Field: field, Rule: rule}})
}

func Unauthorized(message string) *AppError { return New(CodeUnauthorized, message) }
func Forbidden(message string) *AppError    { return New(CodeForbidden, message) }
func NotFound(message string) *AppError     { return New(CodeNotFound, message) }
