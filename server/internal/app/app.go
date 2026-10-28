package app

import (
	"time"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/logger"
	recovermw "github.com/gofiber/fiber/v3/middleware/recover"
	"github.com/gofiber/fiber/v3/middleware/requestid"
	"gorm.io/gorm"

	"jesi-laundry-app-server/internal/platform/config"
	"jesi-laundry-app-server/internal/platform/httpx"
)

type Deps struct {
	Config *config.Config
	DB     *gorm.DB
}

// New builds the Fiber app with global middleware and all routes.
func New(deps Deps) *fiber.App {
	fiberCfg := fiber.Config{
		AppName:      "jesi-laundry-api",
		BodyLimit:    1 * 1024 * 1024,
		ErrorHandler: httpx.ErrorHandler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
	}
	// Behind a platform proxy the TCP peer is the proxy, not the client. When CLIENT_IP_HEADER is set,
	// c.IP() reads that header, but only if the peer is a loopback/private/link-local address.
	// With the header unset nothing is trusted and c.IP() is the TCP peer (local development).
	if header := deps.Config.ClientIPHeader; header != "" {
		fiberCfg.ProxyHeader = header
		fiberCfg.TrustProxy = true
		fiberCfg.TrustProxyConfig = fiber.TrustProxyConfig{Loopback: true, Private: true, LinkLocal: true}
	}
	app := fiber.New(fiberCfg)

	app.Use(recovermw.New())
	app.Use(requestid.New())
	app.Use(logger.New(logger.Config{
		Format: `{"request_id":"${respHeader:X-Request-ID}","method":"${method}","path":"${path}","status":${status},"latency":"${latency}"}` + "\n",
	}))

	registerRoutes(app, deps)
	return app
}
