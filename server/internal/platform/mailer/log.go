package mailer

import (
	"context"
	"log/slog"
)

// LogMailer prints the OTP to the log. Development only; never used in production.
type LogMailer struct{}

func (LogMailer) SendPasswordResetOTP(_ context.Context, to, _, code, lang string) error {
	slog.Info("password reset OTP (development only)", "to", to, "code", code, "lang", lang)
	return nil
}
