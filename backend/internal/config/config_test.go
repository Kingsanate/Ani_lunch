package config

import (
	"os"
	"testing"
)

func TestConfig_LoadDefaults(t *testing.T) {
	// Clear relevant env vars
	_ = os.Unsetenv("APP_ENV")
	_ = os.Unsetenv("PORT")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() returned error: %v", err)
	}

	if cfg.Port != "8080" {
		t.Errorf("expected default Port '8080', got '%s'", cfg.Port)
	}

	if cfg.Environment != "development" {
		t.Errorf("expected default Environment 'development', got '%s'", cfg.Environment)
	}

	if cfg.ReadDatabaseURL != "" {
		t.Errorf("expected default ReadDatabaseURL '', got '%s'", cfg.ReadDatabaseURL)
	}
}

func TestConfig_LoadCustom(t *testing.T) {
	_ = os.Setenv("PORT", "9090")
	_ = os.Setenv("APP_ENV", "production")
	_ = os.Setenv("READ_DATABASE_URL", "postgres://replica:pass@localhost:6432/animeat?sslmode=disable")
	defer func() {
		_ = os.Unsetenv("PORT")
		_ = os.Unsetenv("APP_ENV")
		_ = os.Unsetenv("READ_DATABASE_URL")
	}()

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() returned error: %v", err)
	}

	if cfg.Port != "9090" {
		t.Errorf("expected custom Port '9090', got '%s'", cfg.Port)
	}

	if cfg.Environment != "production" {
		t.Errorf("expected custom Environment 'production', got '%s'", cfg.Environment)
	}

	wantRead := "postgres://replica:pass@localhost:6432/animeat?sslmode=disable"
	if cfg.ReadDatabaseURL != wantRead {
		t.Errorf("expected ReadDatabaseURL %q, got %q", wantRead, cfg.ReadDatabaseURL)
	}
}
