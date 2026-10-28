package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"
	"time"
	_ "time/tzdata"

	"github.com/gofiber/fiber/v3"
	"github.com/shopspring/decimal"

	"jesi-laundry-app-server/internal/app"
	"jesi-laundry-app-server/internal/platform/config"
	"jesi-laundry-app-server/internal/platform/database"
	"jesi-laundry-app-server/internal/platform/timeutil"
)

func main() {
	if err := run(); err != nil {
		slog.Error("server stopped", "error", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}

	if cfg.IsProduction() {
		slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, nil)))
	}
	timeutil.Init(cfg.Timezone)
	decimal.MarshalJSONWithoutQuotes = true

	db, err := database.Open(cfg.DatabaseURL, database.Options{
		MaxOpenConns: cfg.DBMaxOpenConns,
		MaxIdleConns: cfg.DBMaxIdleConns,
		Production:   cfg.IsProduction(),
	})
	if err != nil {
		return err
	}
	defer func() {
		if err := database.Close(db); err != nil {
			slog.Error("close database", "error", err)
		}
	}()

	server := app.New(app.Deps{Config: cfg, DB: db})

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	listenErr := make(chan error, 1)
	go func() {
		listenErr <- server.Listen(":"+cfg.Port, fiber.ListenConfig{DisableStartupMessage: true})
	}()
	slog.Info("server started", "port", cfg.Port, "env", cfg.AppEnv)

	select {
	case err := <-listenErr:
		return fmt.Errorf("listen: %w", err)
	case <-ctx.Done():
	}

	slog.Info("shutting down")
	if err := server.ShutdownWithTimeout(25 * time.Second); err != nil {
		return fmt.Errorf("shutdown: %w", err)
	}
	<-listenErr
	return nil
}
