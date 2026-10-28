package security

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

const jwtIssuer = "jesi-laundry"

var (
	ErrTokenExpired = errors.New("access token expired")
	ErrTokenInvalid = errors.New("access token invalid")
)

type AccessClaims struct {
	Role     string `json:"role"`
	OutletID string `json:"oid"`
	jwt.RegisteredClaims
}

// IssueAccessToken signs an HS256 access token and returns it with its expiry.
func IssueAccessToken(secret string, ttl time.Duration, userID uuid.UUID, role string, outletID *uuid.UUID, now time.Time) (string, time.Time, error) {
	expiresAt := now.Add(ttl)
	claims := AccessClaims{
		Role: role,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			Issuer:    jwtIssuer,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(expiresAt),
		},
	}
	if outletID != nil {
		claims.OutletID = outletID.String()
	}

	signed, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(secret))
	if err != nil {
		return "", time.Time{}, err
	}
	return signed, expiresAt, nil
}

// ParseAccessToken verifies signature, issuer and expiry. It returns ErrTokenExpired or ErrTokenInvalid.
func ParseAccessToken(secret, token string) (*AccessClaims, error) {
	claims := &AccessClaims{}
	_, err := jwt.ParseWithClaims(token, claims,
		func(*jwt.Token) (any, error) { return []byte(secret), nil },
		jwt.WithValidMethods([]string{jwt.SigningMethodHS256.Alg()}),
		jwt.WithIssuer(jwtIssuer),
		jwt.WithExpirationRequired(),
	)
	if err != nil {
		if errors.Is(err, jwt.ErrTokenExpired) {
			return nil, ErrTokenExpired
		}
		return nil, ErrTokenInvalid
	}
	return claims, nil
}
