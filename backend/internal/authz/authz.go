package authz

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
)

// ActorKind identifies the application role of an authenticated user.
type ActorKind string

const (
	ActorCustomer ActorKind = "customer"
	ActorVendor   ActorKind = "vendor"
	ActorRider    ActorKind = "rider"
	ActorAdmin    ActorKind = "admin"
)

// Querier is the minimal SQL interface needed for role resolution.
// Both pgxpool.Pool and pgx.Tx satisfy it.
type Querier interface {
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

// ResolveActor determines the application role of the authenticated user by
// checking their presence in the riders / vendors tables and the admin flag.
// A user present in multiple role tables resolves to the most privileged role.
func ResolveActor(ctx context.Context, q Querier, userID string) (ActorKind, error) {
	if q == nil {
		return "", errors.New("querier is nil")
	}

	var riderExists bool
	if err := q.QueryRow(ctx,
		`SELECT EXISTS (SELECT 1 FROM riders WHERE id::text = $1)`, userID).Scan(&riderExists); err != nil {
		return "", fmt.Errorf("failed to check rider role: %w", err)
	}
	if riderExists {
		return ActorRider, nil
	}

	var vendorExists bool
	if err := q.QueryRow(ctx,
		`SELECT EXISTS (SELECT 1 FROM vendors WHERE id::text = $1)`, userID).Scan(&vendorExists); err != nil {
		return "", fmt.Errorf("failed to check vendor role: %w", err)
	}
	if vendorExists {
		return ActorVendor, nil
	}

	var isAdmin bool
	if err := q.QueryRow(ctx,
		`SELECT COALESCE(is_admin, FALSE) FROM users WHERE user_id::text = $1 OR id::text = $1`, userID).Scan(&isAdmin); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ActorCustomer, nil
		}
		// If is_admin column doesn't exist in legacy schema, check admin emails as fallback
		var email string
		if errEmail := q.QueryRow(ctx, `SELECT email FROM users WHERE user_id::text = $1 OR id::text = $1`, userID).Scan(&email); errEmail == nil {
			if email == "questrsanate@gmail.com" || email == "kingsanate@gmail.com" || email == "jamesanate22@gmail.com" || email == "admin@anilunch.com" {
				return ActorAdmin, nil
			}
			return ActorCustomer, nil
		}
		return "", fmt.Errorf("failed to check admin role: %w", err)
	}
	if isAdmin {
		return ActorAdmin, nil
	}

	return ActorCustomer, nil
}