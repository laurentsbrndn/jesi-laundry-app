package model

import (
	"time"

	"github.com/google/uuid"
)

type PasswordResetOTP struct {
	Base
	UserID    uuid.UUID  `gorm:"type:uuid;not null;index:idx_password_reset_otps_user_created,priority:1" json:"user_id"`
	CodeHash  string     `gorm:"type:char(64);not null" json:"-"`
	ExpiresAt time.Time  `gorm:"not null" json:"expires_at"`
	Attempts  int16      `gorm:"type:smallint;not null" json:"attempts"`
	UsedAt    *time.Time `json:"used_at"`

	// Shadows Base.CreatedAt (GORM prefers the shallower field) so it can join the composite index.
	CreatedAt time.Time `gorm:"not null;index:idx_password_reset_otps_user_created,priority:2" json:"created_at"`

	User *User `gorm:"foreignKey:UserID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE" json:"-"`
}

// TableName is explicit because GORM's naming strategy does not treat "OTP" as an initialism.
func (PasswordResetOTP) TableName() string { return "password_reset_otps" }
