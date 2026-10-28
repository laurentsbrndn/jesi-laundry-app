package customer

import "strings"

const (
	minPhoneDigits = 9
	maxPhoneDigits = 15
)

// NormalizePhone keeps digits only, turns a leading 0 into 62 and requires 9–15 digits.
// An empty input yields (nil, true); an input that cannot be a phone number yields (nil, false).
func NormalizePhone(raw string) (*string, bool) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, true
	}
	digits := digitsOnly(raw)
	if digits == "" {
		return nil, false
	}
	if strings.HasPrefix(digits, "0") {
		digits = "62" + digits[1:]
	}
	if len(digits) < minPhoneDigits || len(digits) > maxPhoneDigits {
		return nil, false
	}
	return &digits, true
}

// searchDigits normalizes a free-text search into phone digits for a LIKE match (no length rule).
func searchDigits(raw string) string {
	digits := digitsOnly(raw)
	if strings.HasPrefix(digits, "0") {
		digits = "62" + digits[1:]
	}
	return digits
}

func digitsOnly(s string) string {
	var b strings.Builder
	for _, r := range s {
		if r >= '0' && r <= '9' {
			b.WriteRune(r)
		}
	}
	return b.String()
}
