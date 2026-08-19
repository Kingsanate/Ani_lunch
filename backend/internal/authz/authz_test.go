package authz

import (
	"context"
	"errors"
	"testing"

	"github.com/jackc/pgx/v5"
)

// fakeRow implements pgx.Row with a fixed scan result.
type fakeRow struct {
	value any
	err   error
}

func (f fakeRow) Scan(dest ...any) error {
	if f.err != nil {
		return f.err
	}
	if len(dest) > 0 {
		switch d := dest[0].(type) {
		case *bool:
			if v, ok := f.value.(bool); ok {
				*d = v
			}
		}
	}
	return nil
}

// fakeQuerier implements Querier, returning queued results per query call.
type fakeQuerier struct {
	results []fakeRow
	call    int
}

func (f *fakeQuerier) QueryRow(ctx context.Context, sql string, args ...any) pgx.Row {
	if f.call >= len(f.results) {
		return fakeRow{err: errors.New("unexpected query")}
	}
	r := f.results[f.call]
	f.call++
	return r
}

func TestResolveActor(t *testing.T) {
	tests := []struct {
		name      string
		results   []fakeRow
		wantActor ActorKind
		wantErr   bool
	}{
		{
			name: "rider takes precedence over everything",
			results: []fakeRow{
				{value: true},
			},
			wantActor: ActorRider,
		},
		{
			name: "vendor when not a rider",
			results: []fakeRow{
				{value: false},
				{value: true},
			},
			wantActor: ActorVendor,
		},
		{
			name: "admin via is_admin flag",
			results: []fakeRow{
				{value: false},
				{value: false},
				{value: true},
			},
			wantActor: ActorAdmin,
		},
		{
			name: "customer when no role tables match",
			results: []fakeRow{
				{value: false},
				{value: false},
				{err: pgx.ErrNoRows},
			},
			wantActor: ActorCustomer,
		},
		{
			name: "error propagates",
			results: []fakeRow{
				{err: errors.New("db down")},
			},
			wantActor: ActorCustomer,
			wantErr:   true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			q := &fakeQuerier{results: tt.results}
			actor, err := ResolveActor(context.Background(), q, "user-1")
			if tt.wantErr {
				if err == nil {
					t.Fatalf("expected error, got nil")
				}
				return
			}
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if actor != tt.wantActor {
				t.Fatalf("expected actor %q, got %q", tt.wantActor, actor)
			}
		})
	}
}

func TestResolveActorNilQuerier(t *testing.T) {
	if _, err := ResolveActor(context.Background(), nil, "user-1"); err == nil {
		t.Fatal("expected error for nil querier")
	}
}