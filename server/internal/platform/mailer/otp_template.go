package mailer

import (
	"fmt"
	"html"
)

type message struct {
	Subject string
	HTML    string
	Text    string
}

// passwordResetOTPMessage renders the reset email in "en" or "id".
func passwordResetOTPMessage(lang, name, code string, ttlMinutes int) message {
	if lang == "en" {
		return message{
			Subject: "Your Jesi Laundry password reset code",
			Text: fmt.Sprintf("Hi %s,\n\nYour password reset code is %s.\nIt is valid for %d minutes. Do not share it with anyone.\n\nIf you did not request this, you can ignore this email.",
				name, code, ttlMinutes),
			HTML: fmt.Sprintf(`<p>Hi %s,</p><p>Your password reset code is:</p><p style="font-size:28px;font-weight:bold;letter-spacing:6px">%s</p><p>It is valid for %d minutes. Do not share it with anyone.</p><p>If you did not request this, you can ignore this email.</p>`,
				html.EscapeString(name), code, ttlMinutes),
		}
	}
	return message{
		Subject: "Kode reset password Jesi Laundry",
		Text: fmt.Sprintf("Halo %s,\n\nKode reset password Anda adalah %s.\nBerlaku selama %d menit. Jangan bagikan kode ini kepada siapa pun.\n\nJika Anda tidak merasa memintanya, abaikan email ini.",
			name, code, ttlMinutes),
		HTML: fmt.Sprintf(`<p>Halo %s,</p><p>Kode reset password Anda adalah:</p><p style="font-size:28px;font-weight:bold;letter-spacing:6px">%s</p><p>Berlaku selama %d menit. Jangan bagikan kode ini kepada siapa pun.</p><p>Jika Anda tidak merasa memintanya, abaikan email ini.</p>`,
			html.EscapeString(name), code, ttlMinutes),
	}
}
