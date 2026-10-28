package model

type Outlet struct {
	Base
	Code     string  `gorm:"type:varchar(5);not null;uniqueIndex:uq_outlets_code;check:chk_outlets_code,code ~ '^[A-Z0-9]+$' AND char_length(code) >= 2" json:"code"`
	Name     string  `gorm:"type:varchar(100);not null" json:"name"`
	Address  *string `gorm:"type:varchar(255)" json:"address"`
	Phone    *string `gorm:"type:varchar(20)" json:"phone"`
	IsActive bool    `gorm:"not null" json:"is_active"` // callers set this explicitly; a Go zero value would otherwise trigger a GORM column default
}
