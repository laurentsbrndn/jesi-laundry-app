package model

import (
	"time"

	"github.com/google/uuid"
)

type User struct {
	Base
	Name         string     `gorm:"type:varchar(100);not null" json:"name"`
	Email        string     `gorm:"type:varchar(255);not null;uniqueIndex:uq_users_email" json:"email"`
	PasswordHash string     `gorm:"type:varchar(255);not null" json:"-"`
	Role         Role       `gorm:"type:varchar(10);not null;check:chk_users_role,role IN ('owner','staff');uniqueIndex:uq_users_single_owner,where:role = 'owner'" json:"role"`
	OutletID     *uuid.UUID `gorm:"type:uuid;check:chk_users_role_outlet,(role = 'owner' AND outlet_id IS NULL) OR (role = 'staff' AND outlet_id IS NOT NULL)" json:"outlet_id"`
	IsActive     bool       `gorm:"not null" json:"is_active"` // callers set this explicitly
	LastLoginAt  *time.Time `json:"last_login_at"`

	Outlet *Outlet `gorm:"foreignKey:OutletID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT" json:"-"`
}
