package app

import (
	"context"
	"net/http"
	"time"

	"github.com/gofiber/fiber/v3"
	"gorm.io/gorm"

	"jesi-laundry-app-server/internal/modules/auth"
	"jesi-laundry-app-server/internal/modules/catalog"
	"jesi-laundry-app-server/internal/modules/customer"
	"jesi-laundry-app-server/internal/modules/dashboard"
	"jesi-laundry-app-server/internal/modules/order"
	"jesi-laundry-app-server/internal/modules/outlet"
	"jesi-laundry-app-server/internal/modules/user"
	"jesi-laundry-app-server/internal/platform/mailer"
	"jesi-laundry-app-server/internal/platform/middleware"
)

// registerRoutes wires modules and registers routes under /api/v1.
func registerRoutes(app *fiber.App, deps Deps) {
	app.Get("/health", healthHandler(deps))

	outletRepo := outlet.NewRepository(deps.DB)
	catalogRepo := catalog.NewRepository(deps.DB)

	authSvc := auth.NewService(
		deps.DB,
		auth.NewRepository(deps.DB),
		deps.Config,
		newMailer(deps),
		func(tx *gorm.DB) auth.OutletCreator { return outletRepo.WithTx(tx) },
		func(tx *gorm.DB) auth.DefaultServiceCreator { return catalogRepo.WithTx(tx) },
	)

	outletSvc := outlet.NewService(
		deps.DB,
		outletRepo,
		func(tx *gorm.DB) outlet.DefaultServiceCreator { return catalogRepo.WithTx(tx) },
	)
	catalogSvc := catalog.NewService(catalogRepo, outletRepo)
	userSvc := user.NewService(deps.DB, user.NewRepository(deps.DB), outletRepo)

	customerRepo := customer.NewRepository(deps.DB)
	customerSvc := customer.NewService(customerRepo)
	orderSvc := order.NewService(
		deps.DB,
		order.NewRepository(deps.DB),
		func(tx *gorm.DB) order.CustomerResolver { return customerSvc.WithTx(tx) },
		func(tx *gorm.DB) order.ServiceReader { return catalogRepo.WithTx(tx) },
		outletRepo,
	)

	dashboardSvc := dashboard.NewService(dashboard.NewRepository(deps.DB), outletRepo)

	api := app.Group("/api/v1")
	requireAuth := middleware.RequireAuth(deps.Config.JWTAccessSecret)
	requireOwner := middleware.RequireOwner()

	auth.RegisterRoutes(api, auth.NewHandler(authSvc), requireAuth)
	outlet.RegisterRoutes(api, outlet.NewHandler(outletSvc), requireAuth, requireOwner)
	catalog.RegisterRoutes(api, catalog.NewHandler(catalogSvc), requireAuth, requireOwner)
	customer.RegisterRoutes(api, customer.NewHandler(customerSvc), requireAuth, requireOwner)
	order.RegisterRoutes(api, order.NewHandler(orderSvc), requireAuth, requireOwner)
	dashboard.RegisterRoutes(api, dashboard.NewHandler(dashboardSvc), requireAuth)
	user.RegisterRoutes(api, user.NewHandler(userSvc), requireAuth, requireOwner)
}

// newMailer uses Resend whenever a key is configured and always in production (config requires the key
// there); only development without a key falls back to logging OTPs.
func newMailer(deps Deps) mailer.Mailer {
	cfg := deps.Config
	if cfg.ResendAPIKey != "" || cfg.IsProduction() {
		return mailer.NewResend(cfg.ResendAPIKey, cfg.MailFrom, cfg.OTPTTL)
	}
	return mailer.LogMailer{}
}

func healthHandler(deps Deps) fiber.Handler {
	return func(c fiber.Ctx) error {
		ctx, cancel := context.WithTimeout(c.Context(), 2*time.Second)
		defer cancel()

		sqlDB, err := deps.DB.DB()
		if err == nil {
			err = sqlDB.PingContext(ctx)
		}
		if err != nil {
			return c.Status(http.StatusServiceUnavailable).JSON(fiber.Map{"status": "degraded", "database": "error"})
		}
		return c.JSON(fiber.Map{"status": "ok", "database": "ok"})
	}
}
