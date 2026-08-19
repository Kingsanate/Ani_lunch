package database

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"animeat/backend/internal/config"
	"animeat/backend/internal/observability"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Postgres wraps the write pool (primary) and, when configured, a read pool
// (replica). All money/state mutations go through Pool; stale-tolerant reads
// may use Reader(). When no read replica is configured Reader() falls back
// to the primary pool, preserving single-node behaviour.
type Postgres struct {
	Pool     *pgxpool.Pool
	ReadPool *pgxpool.Pool
}

// NewPostgres initializes and validates the primary pool, and — when
// READ_DATABASE_URL is set — the read-replica pool.
func NewPostgres(ctx context.Context, cfg *config.Config) (*Postgres, error) {
	poolCfg, err := pgxpool.ParseConfig(cfg.DatabaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to parse database URL: %w", err)
	}

	poolCfg.MaxConns = cfg.DBMaxConns
	poolCfg.MinConns = cfg.DBMinConns
	poolCfg.MaxConnLifetime = cfg.DBMaxConnLifetime
	poolCfg.MaxConnIdleTime = cfg.DBMaxConnIdleTime

	pool, err := pgxpool.NewWithConfig(ctx, poolCfg)
	if err != nil {
		return nil, fmt.Errorf("failed to create connection pool: %w", err)
	}

	// Ping database with timeout
	pingCtx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()

	if err := pool.Ping(pingCtx); err != nil {
		slog.Warn("database ping failed on startup (will retry in background)", "error", err)
	} else {
		slog.Info("database connection pool initialized successfully",
			"max_conns", cfg.DBMaxConns,
			"min_conns", cfg.DBMinConns,
		)
	}

	db := &Postgres{Pool: pool}

	// Optional read-replica pool (Phase 12). When unset, Reader() returns the
	// primary pool so deployment stays single-node by default.
	if cfg.ReadDatabaseURL != "" {
		readCfg, err := pgxpool.ParseConfig(cfg.ReadDatabaseURL)
		if err != nil {
			pool.Close()
			return nil, fmt.Errorf("failed to parse read database URL: %w", err)
		}
		readCfg.MaxConns = cfg.DBMaxConns
		readCfg.MinConns = cfg.DBMinConns
		readCfg.MaxConnLifetime = cfg.DBMaxConnLifetime
		readCfg.MaxConnIdleTime = cfg.DBMaxConnIdleTime

		readPool, err := pgxpool.NewWithConfig(ctx, readCfg)
		if err != nil {
			pool.Close()
			return nil, fmt.Errorf("failed to create read connection pool: %w", err)
		}
		readPingCtx, readCancel := context.WithTimeout(ctx, 3*time.Second)
		defer readCancel()
		if err := readPool.Ping(readPingCtx); err != nil {
			slog.Warn("read replica ping failed on startup (will retry in background)", "error", err)
		} else {
			slog.Info("read replica connection pool initialized successfully")
		}
		db.ReadPool = readPool
	}

	return db, nil
}

// Reader returns the read-replica pool, or the primary pool when no replica
// is configured (or the replica pool failed to build).
func (p *Postgres) Reader() *pgxpool.Pool {
	if p == nil {
		return nil
	}
	if p.ReadPool != nil {
		return p.ReadPool
	}
	return p.Pool
}

// Ping verifies primary connectivity.
func (p *Postgres) Ping(ctx context.Context) error {
	if p.Pool == nil {
		return fmt.Errorf("connection pool is nil")
	}
	return p.Pool.Ping(ctx)
}

// ReadPing verifies read-replica connectivity (falls back to the primary).
func (p *Postgres) ReadPing(ctx context.Context) error {
	if p.Reader() == nil {
		return fmt.Errorf("read pool is nil")
	}
	return p.Reader().Ping(ctx)
}

// Close gracefully closes all connection pools.
func (p *Postgres) Close() {
	if p.Pool != nil {
		p.Pool.Close()
	}
	if p.ReadPool != nil {
		p.ReadPool.Close()
	}
}

// StartReplicaLagMonitor periodically measures streaming-replication lag on
// the read replica and exposes it as the animeat_replica_lag_seconds gauge.
// No-op when no read replica is configured.
func (p *Postgres) StartReplicaLagMonitor(ctx context.Context, interval time.Duration) {
	if p.ReadPool == nil {
		return
	}

	go func() {
		ticker := time.NewTicker(interval)
		defer ticker.Stop()

		p.measureLag(ctx)
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				p.measureLag(ctx)
			}
		}
	}()
}

func (p *Postgres) measureLag(ctx context.Context) {
	queryCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	var lagSeconds float64
	// pg_last_xact_replay_timestamp() is NULL until the standby applies the
	// first WAL record; treat NULL as unknown (0) to avoid false alarms.
	err := p.ReadPool.QueryRow(queryCtx, `
		SELECT COALESCE(EXTRACT(EPOCH FROM (NOW() - pg_last_xact_replay_timestamp())), 0)
	`).Scan(&lagSeconds)
	if err != nil {
		slog.Warn("failed to measure replication lag", "error", err)
		observability.SetReplicaLagSeconds(-1) // unknown
		return
	}

	observability.SetReplicaLagSeconds(lagSeconds)
	if lagSeconds > 10 {
		slog.Warn("replication lag above threshold", "lag_seconds", lagSeconds)
	}
}