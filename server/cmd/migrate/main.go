package main

import (
	"context"
	"log/slog"
	"os"
	"time"
	_ "time/tzdata"

	"jesi-laundry-app-server/internal/platform/config"
	"jesi-laundry-app-server/internal/platform/database"
)

func main() {
	if err := run(); err != nil {
		slog.Error("migration failed", "error", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.LoadDatabase()
	if err != nil {
		return err
	}

	db, err := database.Open(cfg.MigrationURL(), database.Options{
		MaxOpenConns: 2,
		MaxIdleConns: 1,
		Production:   cfg.IsProduction(),
	})
	if err != nil {
		return err
	}
	defer func() { _ = database.Close(db) }()

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	if err := database.Migrate(ctx, db); err != nil {
		return err
	}
	slog.Info("migration complete")
	return nil
}
