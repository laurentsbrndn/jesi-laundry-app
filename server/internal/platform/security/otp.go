package security

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"math/big"

	"github.com/google/uuid"
)

// GenerateOTP returns a uniformly random 6-digit code, zero-padded (000000–999999).
func GenerateOTP() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1_000_000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

// HashOTP returns HMAC-SHA256(secret, userID + ":" + code) as hex.
func HashOTP(secret string, userID uuid.UUID, code string) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(userID.String() + ":" + code))
	return hex.EncodeToString(mac.Sum(nil))
}

// EqualHash compares two hex hashes in constant time.
func EqualHash(a, b string) bool {
	return hmac.Equal([]byte(a), []byte(b))
}
