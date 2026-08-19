package database

import (
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
)

// TestReader_FallbackToPrimary verifies that without a read replica the
// reader routes to the primary pool (single-node behaviour).
func TestReader_FallbackToPrimary(t *testing.T) {
	// No real pools needed: routing is a nil-check on the struct fields.
	db := &Postgres{Pool: &pgxpool.Pool{}}
	if got := db.Reader(); got != db.Pool {
		t.Errorf("Reader() = %v, want primary pool", got)
	}
}

// TestReader_UsesReplica verifies that a configured read pool wins.
func TestReader_UsesReplica(t *testing.T) {
	db := &Postgres{Pool: &pgxpool.Pool{}, ReadPool: &pgxpool.Pool{}}
	if got := db.Reader(); got != db.ReadPool {
		t.Errorf("Reader() = %v, want read pool", got)
	}
}

// TestReader_NilSafe verifies nil receiver and nil pools do not panic.
func TestReader_NilSafe(t *testing.T) {
	var db *Postgres
	if got := db.Reader(); got != nil {
		t.Errorf("Reader() on nil receiver = %v, want nil", got)
	}

	db = &Postgres{}
	if got := db.Reader(); got != nil {
		t.Errorf("Reader() with nil pools = %v, want nil", got)
	}
}

// TestPing_NilPool verifies Ping returns an error for a nil pool.
func TestPing_NilPool(t *testing.T) {
	db := &Postgres{}
	if err := db.Ping(t.Context()); err == nil {
		t.Errorf("Ping() with nil pool: expected error, got nil")
	}
}

// TestReadPing_NilPool verifies ReadPing returns an error without pools.
func TestReadPing_NilPool(t *testing.T) {
	db := &Postgres{}
	if err := db.ReadPing(t.Context()); err == nil {
		t.Errorf("ReadPing() with nil pools: expected error, got nil")
	}
}

// TestClose_NilSafe verifies Close tolerates missing pools.
func TestClose_NilSafe(t *testing.T) {
	db := &Postgres{}
	db.Close() // must not panic
}

// TestStartReplicaLagMonitor_NoopWithoutReplica verifies the monitor is a
// no-op when no read replica is configured (no goroutine, no panic).
func TestStartReplicaLagMonitor_NoopWithoutReplica(t *testing.T) {
	db := &Postgres{}
	db.StartReplicaLagMonitor(t.Context(), 0)
}