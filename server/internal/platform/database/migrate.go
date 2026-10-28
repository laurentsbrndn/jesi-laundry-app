package database

import (
	"context"

	"gorm.io/gorm"

	"jesi-laundry-app-server/internal/model"
)

// Migrate is the single migration entrypoint. AutoMigrate only adds tables, columns,
// indexes and constraints; destructive changes are done manually.
func Migrate(ctx context.Context, db *gorm.DB) error {
	return db.WithContext(ctx).AutoMigrate(
		&model.Outlet{},
		&model.User{},
		&model.RefreshToken{},
		&model.PasswordResetOTP{},
		&model.LaundryService{},
		&model.Customer{},
		&model.Order{},
		&model.OrderItem{},
		&model.OrderCounter{},
	)
}
