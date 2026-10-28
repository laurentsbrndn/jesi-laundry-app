package model

import "time"

type Customer struct {
	Base
	Name        string     `gorm:"type:varchar(100);not null;index:idx_customers_name_lower,expression:lower(name)" json:"name"`
	Phone       *string    `gorm:"type:varchar(20);index" json:"phone"`
	LastOrderAt *time.Time `json:"last_order_at"`
}
