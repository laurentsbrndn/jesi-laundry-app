package auth

import (
	"time"

	"github.com/google/uuid"

	"jesi-laundry-app-server/internal/model"
)

// ---- requests ----

type RegisterOwnerRequest struct {
	Name          string `json:"name" validate:"required,max=100"`
	Email         string `json:"email" validate:"required,email,max=255"`
	Password      string `json:"password" validate:"required"`
	OutletName    string `json:"outlet_name" validate:"required,max=100"`
	OutletCode    string `json:"outlet_code" validate:"required,min=2,max=5,alphanum"`
	OutletAddress string `json:"outlet_address" validate:"omitempty,max=255"`
	OutletPhone   string `json:"outlet_phone" validate:"omitempty,max=20"`
}

type LoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

// LogoutRequest is lenient: logout is idempotent and always answers 204.
type LogoutRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type ForgotPasswordRequest struct {
	Email string `json:"email" validate:"required,email"`
}

type ResetPasswordRequest struct {
	Email       string `json:"email" validate:"required,email"`
	OTP         string `json:"otp" validate:"required,len=6,numeric"`
	NewPassword string `json:"new_password" validate:"required"`
}

type UpdateMeRequest struct {
	Name *string `json:"name" validate:"required,max=100"`
}

type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password" validate:"required"`
	NewPassword     string `json:"new_password" validate:"required"`
}

// ---- responses ----

type SetupStatusResponse struct {
	OwnerExists bool `json:"owner_exists"`
}

type RetryAfterResponse struct {
	RetryAfterSeconds int `json:"retry_after_seconds"`
}

type OutletRefResponse struct {
	ID   uuid.UUID `json:"id"`
	Code string    `json:"code"`
	Name string    `json:"name"`
}

type UserResponse struct {
	ID          uuid.UUID          `json:"id"`
	Name        string             `json:"name"`
	Email       string             `json:"email"`
	Role        model.Role         `json:"role"`
	IsActive    bool               `json:"is_active"`
	Outlet      *OutletRefResponse `json:"outlet"`
	LastLoginAt *time.Time         `json:"last_login_at"`
	CreatedAt   time.Time          `json:"created_at"`
}

type SessionResponse struct {
	AccessToken           string       `json:"access_token"`
	AccessTokenExpiresAt  time.Time    `json:"access_token_expires_at"`
	RefreshToken          string       `json:"refresh_token"`
	RefreshTokenExpiresAt time.Time    `json:"refresh_token_expires_at"`
	User                  UserResponse `json:"user"`
}

func newUserResponse(u *model.User) UserResponse {
	resp := UserResponse{
		ID:          u.ID,
		Name:        u.Name,
		Email:       u.Email,
		Role:        u.Role,
		IsActive:    u.IsActive,
		LastLoginAt: utcPtr(u.LastLoginAt),
		CreatedAt:   u.CreatedAt.UTC(),
	}
	if u.Outlet != nil {
		resp.Outlet = &OutletRefResponse{ID: u.Outlet.ID, Code: u.Outlet.Code, Name: u.Outlet.Name}
	}
	return resp
}

func newSessionResponse(s *Session) SessionResponse {
	return SessionResponse{
		AccessToken:           s.AccessToken,
		AccessTokenExpiresAt:  s.AccessTokenExpiresAt.UTC(),
		RefreshToken:          s.RefreshToken,
		RefreshTokenExpiresAt: s.RefreshTokenExpiresAt.UTC(),
		User:                  newUserResponse(s.User),
	}
}

func utcPtr(t *time.Time) *time.Time {
	if t == nil {
		return nil
	}
	u := t.UTC()
	return &u
}
