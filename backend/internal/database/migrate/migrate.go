package migrate

import (
	"fmt"
	"log/slog"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"animeat/backend/internal/config"
)

// RunMigrations runs all pending migrations against the database.
func RunMigrations(cfg *config.Config) error {
	migrationsPath := "file://../../supabase/migrations"
	
	// Use the database URL from config but ensure it points to the actual postgres port
	// In production, this would go through PgBouncer; for migrations we can go direct
	dbURL := cfg.DatabaseURL
	
	slog.Info("running database migrations", "path", migrationsPath, "db", maskPassword(dbURL))
	
	m, err := migrate.New(migrationsPath, dbURL)
	if err != nil {
		return fmt.Errorf("failed to create migrate instance: %w", err)
	}
	
	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("failed to run migrations: %w", err)
	}
	
	srcErr, dbErr := m.Close()
	if srcErr != nil {
		slog.Warn("migration source close error", "error", srcErr)
	}
	if dbErr != nil {
		slog.Warn("migration database close error", "error", dbErr)
	}
	
	slog.Info("database migrations completed successfully")
	return nil
}

// RollbackLast rolls back the last migration.
func RollbackLast(cfg *config.Config) error {
	migrationsPath := "file://../../supabase/migrations"
	dbURL := cfg.DatabaseURL
	
	slog.Info("rolling back last migration", "path", migrationsPath)
	
	m, err := migrate.New(migrationsPath, dbURL)
	if err != nil {
		return fmt.Errorf("failed to create migrate instance: %w", err)
	}
	
	if err := m.Steps(-1); err != nil {
		return fmt.Errorf("failed to rollback migration: %w", err)
	}
	
	srcErr, dbErr := m.Close()
	if srcErr != nil {
		slog.Warn("migration source close error", "error", srcErr)
	}
	if dbErr != nil {
		slog.Warn("migration database close error", "error", dbErr)
	}
	
	slog.Info("migration rollback completed")
	return nil
}

// MigrationVersion returns the current migration version.
func MigrationVersion(cfg *config.Config) (uint, bool, error) {
	migrationsPath := "file://../../supabase/migrations"
	dbURL := cfg.DatabaseURL
	
	m, err := migrate.New(migrationsPath, dbURL)
	if err != nil {
		return 0, false, fmt.Errorf("failed to create migrate instance: %w", err)
	}
	defer m.Close()
	
	version, dirty, err := m.Version()
	if err != nil && err != migrate.ErrNilVersion {
		return 0, false, fmt.Errorf("failed to get migration version: %w", err)
	}
	
	return version, dirty, nil
}

func maskPassword(url string) string {
	// Simple masking for logging
	if len(url) > 20 {
		return url[:20] + "***"
	}
	return "***"
}
