package user

import (
	"time"

	"github.com/google/uuid"

	"jesi-laundry-app-server/internal/model"
)

type ListStaffQuery struct {
	OutletID string `query:"outlet_id" validate:"omitempty,uuid"`
	Search   string `query:"search" validate:"omitempty,max=100"`
	Page     int    `query:"page" validate:"omitempty,gte=1"`
	Limit    int    `query:"limit" validate:"omitempty,gte=1"`
}

type CreateStaffRequest struct {
	Name     string `json:"name" validate:"required,max=100"`
	Email    string `json:"email" validate:"required,email,max=255"`
	Password string `json:"password" validate:"required"`
	OutletID string `json:"outlet_id" validate:"required,uuid"`
}

// UpdateStaffRequest uses pointers so "not sent" differs from "false/empty".
type UpdateStaffRequest struct {
	Name     *string `json:"name" validate:"omitempty,max=100"`
	OutletID *string `json:"outlet_id" validate:"omitempty,uuid"`
	IsActive *bool   `json:"is_active"`
}

type ResetPasswordRequest struct {
	NewPassword string `json:"new_password" validate:"required"`
}

type OutletRefResponse struct {
	ID   uuid.UUID `json:"id"`
	Code string    `json:"code"`
	Name string    `json:"name"`
}

type StaffResponse struct {
	ID          uuid.UUID          `json:"id"`
	Name        string             `json:"name"`
	Email       string             `json:"email"`
	Role        model.Role         `json:"role"`
	IsActive    bool               `json:"is_active"`
	Outlet      *OutletRefResponse `json:"outlet"`
	LastLoginAt *time.Time         `json:"last_login_at"`
	CreatedAt   time.Time          `json:"created_at"`
}

func newStaffResponse(u *model.User) StaffResponse {
	resp := StaffResponse{
		ID:        u.ID,
		Name:      u.Name,
		Email:     u.Email,
		Role:      u.Role,
		IsActive:  u.IsActive,
		CreatedAt: u.CreatedAt.UTC(),
	}
	if u.LastLoginAt != nil {
		t := u.LastLoginAt.UTC()
		resp.LastLoginAt = &t
	}
	if u.Outlet != nil {
		resp.Outlet = &OutletRefResponse{ID: u.Outlet.ID, Code: u.Outlet.Code, Name: u.Outlet.Name}
	}
	return resp
}

func newStaffResponses(users []model.User) []StaffResponse {
	out := make([]StaffResponse, 0, len(users))
	for i := range users {
		out = append(out, newStaffResponse(&users[i]))
	}
	return out
}
