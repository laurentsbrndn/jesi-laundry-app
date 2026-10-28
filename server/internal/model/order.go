package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Order struct {
	Base
	OutletID        uuid.UUID      `gorm:"type:uuid;not null;index:idx_orders_outlet_created,priority:1" json:"outlet_id"`
	OrderNumber     string         `gorm:"type:varchar(30);not null;uniqueIndex:uq_orders_order_number" json:"order_number"`
	CustomerID      uuid.UUID      `gorm:"type:uuid;not null;index" json:"customer_id"`
	CustomerName    string         `gorm:"type:varchar(100);not null" json:"customer_name"`
	CustomerPhone   *string        `gorm:"type:varchar(20)" json:"customer_phone"`
	Speed           ServiceSpeed   `gorm:"type:varchar(10);not null;check:chk_orders_speed,speed IN ('regular','express')" json:"speed"`
	Status          OrderStatus    `gorm:"type:varchar(15);not null;default:received;index;check:chk_orders_status,status IN ('received','processing','done','picked_up')" json:"status"`
	PaymentStatus   PaymentStatus  `gorm:"type:varchar(10);not null;default:unpaid;index;check:chk_orders_payment_status,payment_status IN ('unpaid','paid')" json:"payment_status"`
	TotalAmount     int64          `gorm:"not null;check:chk_orders_total_amount,total_amount >= 0" json:"total_amount"`
	EstimatedDoneAt time.Time      `gorm:"not null" json:"estimated_done_at"`
	ProcessingAt    *time.Time     `json:"processing_at"`
	DoneAt          *time.Time     `json:"done_at"`
	PickedUpAt      *time.Time     `json:"picked_up_at"`
	PaidAt          *time.Time     `json:"paid_at"`
	Notes           *string        `gorm:"type:varchar(500)" json:"notes"`
	CreatedByID     uuid.UUID      `gorm:"type:uuid;not null" json:"created_by_id"`
	UpdatedByID     *uuid.UUID     `gorm:"type:uuid" json:"updated_by_id"`
	DeletedByID     *uuid.UUID     `gorm:"type:uuid" json:"deleted_by_id"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"-"`

	// Shadows Base.CreatedAt (GORM prefers the shallower field) so it can join the composite index.
	CreatedAt time.Time `gorm:"not null;index:idx_orders_outlet_created,priority:2" json:"created_at"`

	Outlet    *Outlet     `gorm:"foreignKey:OutletID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT" json:"-"`
	Customer  *Customer   `gorm:"foreignKey:CustomerID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT" json:"-"`
	CreatedBy *User       `gorm:"foreignKey:CreatedByID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT" json:"-"`
	UpdatedBy *User       `gorm:"foreignKey:UpdatedByID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL" json:"-"`
	DeletedBy *User       `gorm:"foreignKey:DeletedByID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL" json:"-"`
	Items     []OrderItem `gorm:"foreignKey:OrderID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE" json:"-"`
}
