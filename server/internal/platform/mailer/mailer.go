package mailer

import (
	"context"
	"strings"
)

type Mailer interface {
	SendPasswordResetOTP(ctx context.Context, to, name, code, lang string) error
}

// NormalizeLang maps an Accept-Language header to "en" or "id" (default "id").
func NormalizeLang(acceptLanguage string) string {
	if strings.HasPrefix(strings.ToLower(strings.TrimSpace(acceptLanguage)), "en") {
		return "en"
	}
	return "id"
}
