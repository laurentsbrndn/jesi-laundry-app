package security

import (
	"unicode"

	"golang.org/x/crypto/bcrypt"
)

const (
	bcryptCost       = 12
	minPasswordBytes = 8
	maxPasswordBytes = 72 // bcrypt input limit
)

// dummyHash is compared against when a login email is unknown, so response time stays similar.
var dummyHash = func() []byte {
	h, err := bcrypt.GenerateFromPassword([]byte("dummy-password-for-timing"), bcryptCost)
	if err != nil {
		panic(err)
	}
	return h
}()

func HashPassword(password string) (string, error) {
	h, err := bcrypt.GenerateFromPassword([]byte(password), bcryptCost)
	if err != nil {
		return "", err
	}
	return string(h), nil
}

func ComparePassword(hash, password string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) == nil
}

// CompareDummy burns the same CPU time as a real password check.
func CompareDummy(password string) {
	_ = bcrypt.CompareHashAndPassword(dummyHash, []byte(password))
}

// ValidPassword enforces 8–72 bytes with at least one letter and one digit.
func ValidPassword(password string) bool {
	if len(password) < minPasswordBytes || len(password) > maxPasswordBytes {
		return false
	}
	var letter, digit bool
	for _, r := range password {
		switch {
		case unicode.IsLetter(r):
			letter = true
		case unicode.IsDigit(r):
			digit = true
		}
	}
	return letter && digit
}
