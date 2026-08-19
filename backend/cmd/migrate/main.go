package main

import (
	"flag"
	"fmt"
	"log/slog"
	"os"

	"animeat/backend/internal/config"
	"animeat/backend/internal/database/migrate"
)

func main() {
	var (
		up       = flag.Bool("up", false, "Run all pending migrations")
		down     = flag.Bool("down", false, "Rollback last migration")
		version  = flag.Bool("version", false, "Show current migration version")
		help     = flag.Bool("help", false, "Show help")
	)

	flag.Parse()

	if *help || (!*up && !*down && !*version) {
		printUsage()
		os.Exit(0)
	}

	// Load config
	cfg, err := config.Load()
	if err != nil {
		slog.Error("failed to load config", "error", err)
		os.Exit(1)
	}

	switch {
	case *up:
		if err := migrate.RunMigrations(cfg); err != nil {
			slog.Error("migration failed", "error", err)
			os.Exit(1)
		}
	case *down:
		if err := migrate.RollbackLast(cfg); err != nil {
			slog.Error("rollback failed", "error", err)
			os.Exit(1)
		}
	case *version:
		v, dirty, err := migrate.MigrationVersion(cfg)
		if err != nil {
			slog.Error("failed to get version", "error", err)
			os.Exit(1)
		}
		fmt.Printf("Migration version: %d, dirty: %v\n", v, dirty)
	}
}

func printUsage() {
	fmt.Println("Usage: migrate [options]")
	fmt.Println()
	fmt.Println("Options:")
	fmt.Println("  -up        Run all pending migrations")
	fmt.Println("  -down      Rollback last migration")
	fmt.Println("  -version   Show current migration version")
	fmt.Println("  -help      Show this help")
	fmt.Println()
	fmt.Println("Environment variables (or .env file):")
	fmt.Println("  DATABASE_URL    PostgreSQL connection string")
	fmt.Println("  APP_ENV         Environment (development/production)")
	fmt.Println("  PORT            Server port (default: 8080)")
}
