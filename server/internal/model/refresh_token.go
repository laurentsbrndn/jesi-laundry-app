package model

import (
	"time"

	"github.com/google/uuid"
)

type RefreshToken struct {
	Base
	UserID       uuid.UUID  `gorm:"type:uuid;not null;index" json:"user_id"`
	TokenHash    string     `gorm:"type:char(64);not null;uniqueIndex:uq_refresh_tokens_token_hash" json:"-"`
	ExpiresAt    time.Time  `gorm:"not null" json:"expires_at"`
	RevokedAt    *time.Time `json:"revoked_at"`
	ReplacedByID *uuid.UUID `gorm:"type:uuid" json:"replaced_by_id"`

	User *User `gorm:"foreignKey:UserID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE" json:"-"`
}
