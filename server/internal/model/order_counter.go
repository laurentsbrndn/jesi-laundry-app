package model

import (
	"time"

	"github.com/google/uuid"
)

// OrderCounter holds the last order sequence per outlet per local day. It has no Base (no id).
type OrderCounter struct {
	OutletID   uuid.UUID `gorm:"type:uuid;primaryKey" json:"outlet_id"`
	LocalDate  time.Time `gorm:"type:date;primaryKey" json:"local_date"`
	LastNumber int       `gorm:"not null" json:"last_number"`
	UpdatedAt  time.Time `gorm:"not null" json:"updated_at"`

	Outlet *Outlet `gorm:"foreignKey:OutletID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT" json:"-"`
}
