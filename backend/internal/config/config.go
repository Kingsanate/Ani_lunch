package config

import (
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
)

// Config encapsulates runtime configuration loaded from environment variables.
type Config struct {
	Environment       string
	Port              string
	DatabaseURL       string
	ReadDatabaseURL   string
	RedisURL          string
	NatsURL           string
	JWTSecret         string
	SupabaseJWTSecret string
	RazorpayKeyID     string
	RazorpayKeySecret string
	WebhookSecret     string
	R2AccountID       string
	R2AccessKeyID     string
	R2SecretAccessKey string
	R2Bucket          string
	R2PublicBase      string

	// Push Notifications (FCM)
	FCMServerKey      string
	FCMProjectID      string
	FCMServiceAccount string

	// Pool tuning
	DBMaxConns        int32
	DBMinConns        int32
	DBMaxConnLifetime time.Duration
	DBMaxConnIdleTime time.Duration
}

// Load loads configuration from .env (if present) and process environment variables.
func Load() (*Config, error) {
	// Attempt loading .env if available, ignoring error if missing
	_ = godotenv.Load()

	cfg := &Config{
		Environment:       getEnv("APP_ENV", "development"),
		Port:              getEnv("PORT", "8080"),
		DatabaseURL:       getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/animeat?sslmode=disable"),
		ReadDatabaseURL:   getEnv("READ_DATABASE_URL", ""),
		RedisURL:          getEnv("REDIS_URL", "redis://localhost:6379"),
		NatsURL:           getEnv("NATS_URL", "nats://localhost:4222"),
		JWTSecret:         getEnv("SUPABASE_JWT_SECRET", "super-secret-jwt-key-for-local-dev-must-change"),
		SupabaseJWTSecret: getEnv("SUPABASE_JWT_SECRET", "super-secret-jwt-key-for-local-dev-must-change"),
		RazorpayKeyID:     getEnv("RAZORPAY_KEY_ID", "rzp_test_key"),
		RazorpayKeySecret: getEnv("RAZORPAY_KEY_SECRET", "rzp_test_secret"),
		WebhookSecret:     getEnv("PAYMENT_WEBHOOK_SECRET", "webhook_secret_key"),
		R2AccountID:       getEnv("R2_ACCOUNT_ID", ""),
		R2AccessKeyID:     getEnv("R2_ACCESS_KEY_ID", ""),
		R2SecretAccessKey: getEnv("R2_SECRET_ACCESS_KEY", ""),
		R2Bucket:          getEnv("R2_BUCKET", "animeat-media"),
		R2PublicBase:      getEnv("R2_PUBLIC_BASE", "https://cdn.animeat.app"),

		FCMServerKey:      getEnv("FCM_SERVER_KEY", ""),
		FCMProjectID:      getEnv("FCM_PROJECT_ID", ""),
		FCMServiceAccount: getEnv("FCM_SERVICE_ACCOUNT_JSON", ""),

		DBMaxConns:        int32(getEnvInt("DB_MAX_CONNS", 25)),
		DBMinConns:        int32(getEnvInt("DB_MIN_CONNS", 5)),
		DBMaxConnLifetime: time.Duration(getEnvInt("DB_MAX_CONN_LIFETIME_MINS", 30)) * time.Minute,
		DBMaxConnIdleTime: time.Duration(getEnvInt("DB_MAX_CONN_IDLE_MINS", 5)) * time.Minute,
	}

	return cfg, nil
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}

func getEnvInt(key string, defaultVal int) int {
	if val := os.Getenv(key); val != "" {
		if i, err := strconv.Atoi(val); err == nil {
			return i
		}
	}
	return defaultVal
}
