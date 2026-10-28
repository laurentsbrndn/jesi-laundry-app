package config

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	AppEnv   string
	Port     string
	Timezone *time.Location

	DatabaseURL         string
	DatabaseURLUnpooled string
	DBMaxOpenConns      int
	DBMaxIdleConns      int

	JWTAccessSecret string
	JWTAccessTTL    time.Duration
	RefreshTokenTTL time.Duration
	OTPSecret       string
	OTPTTL          time.Duration

	ResendAPIKey string
	MailFrom     string

	// ClientIPHeader names the request header that carries the real client IP behind a trusted proxy
	// (e.g. X-Real-IP on Vercel). Empty = trust no header and use the TCP peer address.
	ClientIPHeader string
}

func (c *Config) IsProduction() bool { return c.AppEnv == "production" }

// MigrationURL returns the connection string for migrations (direct/unpooled when available).
func (c *Config) MigrationURL() string {
	if c.DatabaseURLUnpooled != "" {
		return c.DatabaseURLUnpooled
	}
	return c.DatabaseURL
}

// LoadDatabase loads only what migrations need: DATABASE_URL, DATABASE_URL_UNPOOLED, APP_TIMEZONE, APP_ENV.
func LoadDatabase() (*Config, error) {
	cfg, errs, err := loadCommon()
	if err != nil {
		return nil, err
	}
	return finish(cfg, errs)
}

// Load reads .env (if present), then the environment, and validates the full configuration.
func Load() (*Config, error) {
	cfg, errs, err := loadCommon()
	if err != nil {
		return nil, err
	}

	cfg.Port = getEnv("PORT", "8080")
	cfg.JWTAccessSecret = os.Getenv("JWT_ACCESS_SECRET")
	cfg.OTPSecret = os.Getenv("OTP_SECRET")
	cfg.ResendAPIKey = os.Getenv("RESEND_API_KEY")
	cfg.MailFrom = os.Getenv("MAIL_FROM")
	cfg.ClientIPHeader = strings.TrimSpace(os.Getenv("CLIENT_IP_HEADER"))

	var perr error
	if cfg.DBMaxOpenConns, perr = getInt("DB_MAX_OPEN_CONNS", 10); perr != nil {
		errs = append(errs, perr)
	}
	if cfg.DBMaxIdleConns, perr = getInt("DB_MAX_IDLE_CONNS", 5); perr != nil {
		errs = append(errs, perr)
	}
	if cfg.JWTAccessTTL, perr = getDuration("JWT_ACCESS_TTL", 15*time.Minute); perr != nil {
		errs = append(errs, perr)
	}
	if cfg.RefreshTokenTTL, perr = getDuration("REFRESH_TOKEN_TTL", 720*time.Hour); perr != nil {
		errs = append(errs, perr)
	}
	if cfg.OTPTTL, perr = getDuration("OTP_TTL", 10*time.Minute); perr != nil {
		errs = append(errs, perr)
	}

	if len(cfg.JWTAccessSecret) < 32 {
		errs = append(errs, errors.New("JWT_ACCESS_SECRET must be at least 32 characters"))
	}
	if len(cfg.OTPSecret) < 32 {
		errs = append(errs, errors.New("OTP_SECRET must be at least 32 characters"))
	}
	if cfg.IsProduction() {
		if isExampleSecret(cfg.JWTAccessSecret) {
			errs = append(errs, errors.New("JWT_ACCESS_SECRET still has the .env.example placeholder value"))
		}
		if isExampleSecret(cfg.OTPSecret) {
			errs = append(errs, errors.New("OTP_SECRET still has the .env.example placeholder value"))
		}
		if cfg.ResendAPIKey == "" {
			errs = append(errs, errors.New("RESEND_API_KEY is required in production"))
		}
		if cfg.MailFrom == "" {
			errs = append(errs, errors.New("MAIL_FROM is required in production"))
		}
	}
	return finish(cfg, errs)
}

// loadCommon reads .env and the settings shared by Load and LoadDatabase.
func loadCommon() (*Config, []error, error) {
	if err := godotenv.Load(); err != nil && !errors.Is(err, fs.ErrNotExist) {
		return nil, nil, fmt.Errorf("load .env: %w", err)
	}

	var errs []error
	cfg := &Config{
		AppEnv:              getEnv("APP_ENV", "development"),
		DatabaseURL:         os.Getenv("DATABASE_URL"),
		DatabaseURLUnpooled: os.Getenv("DATABASE_URL_UNPOOLED"),
	}

	tzName := getEnv("APP_TIMEZONE", "Asia/Jakarta")
	loc, err := time.LoadLocation(tzName)
	if err != nil {
		errs = append(errs, fmt.Errorf("APP_TIMEZONE %q: %w", tzName, err))
	}
	cfg.Timezone = loc

	if cfg.AppEnv != "development" && cfg.AppEnv != "production" {
		errs = append(errs, fmt.Errorf("APP_ENV must be development or production, got %q", cfg.AppEnv))
	}
	if cfg.DatabaseURL == "" {
		errs = append(errs, errors.New("DATABASE_URL is required"))
	}
	return cfg, errs, nil
}

func finish(cfg *Config, errs []error) (*Config, error) {
	if len(errs) > 0 {
		return nil, fmt.Errorf("invalid configuration: %w", errors.Join(errs...))
	}
	return cfg, nil
}

// exampleSecretPrefix is the start of every placeholder secret shipped in .env.example.
const exampleSecretPrefix = "change-me"

func isExampleSecret(v string) bool {
	return strings.HasPrefix(strings.ToLower(v), exampleSecretPrefix)
}

func getEnv(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}

func getInt(key string, fallback int) (int, error) {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return fallback, nil
	}
	n, err := strconv.Atoi(v)
	if err != nil || n < 1 {
		return 0, fmt.Errorf("%s must be a positive integer, got %q", key, v)
	}
	return n, nil
}

func getDuration(key string, fallback time.Duration) (time.Duration, error) {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return fallback, nil
	}
	d, err := time.ParseDuration(v)
	if err != nil || d <= 0 {
		return 0, fmt.Errorf("%s must be a positive duration, got %q", key, v)
	}
	return d, nil
}
