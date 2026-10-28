package mailer

import (
	"context"
	"fmt"
	"time"

	"github.com/resend/resend-go/v3"
)

type ResendMailer struct {
	client *resend.Client
	from   string
	otpTTL time.Duration
}

func NewResend(apiKey, from string, otpTTL time.Duration) *ResendMailer {
	return &ResendMailer{client: resend.NewClient(apiKey), from: from, otpTTL: otpTTL}
}

func (m *ResendMailer) SendPasswordResetOTP(ctx context.Context, to, name, code, lang string) error {
	msg := passwordResetOTPMessage(lang, name, code, int(m.otpTTL.Minutes()))
	_, err := m.client.Emails.SendWithContext(ctx, &resend.SendEmailRequest{
		From:    m.from,
		To:      []string{to},
		Subject: msg.Subject,
		Html:    msg.HTML,
		Text:    msg.Text,
	})
	if err != nil {
		return fmt.Errorf("send reset email via resend: %w", err)
	}
	return nil
}
