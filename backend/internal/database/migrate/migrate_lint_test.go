package migrate

import (
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"testing"
)

// repoRoot walks up from the package dir until it finds supabase/migrations.
func repoRoot(t *testing.T) string {
	t.Helper()
	dir, err := os.Getwd()
	if err != nil {
		t.Fatalf("getwd: %v", err)
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, "supabase", "migrations")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			t.Fatalf("could not locate supabase/migrations from %s", dir)
		}
		dir = parent
	}
}

func migrationFiles(t *testing.T) map[string]string {
	t.Helper()
	dir := filepath.Join(repoRoot(t), "supabase", "migrations")
	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatalf("read migrations dir: %v", err)
	}
	files := map[string]string{}
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".sql") {
			continue
		}
		b, err := os.ReadFile(filepath.Join(dir, e.Name()))
		if err != nil {
			t.Fatalf("read %s: %v", e.Name(), err)
		}
		files[e.Name()] = string(b)
	}
	if len(files) == 0 {
		t.Fatal("no migration files found")
	}
	return files
}

var versionPrefix = regexp.MustCompile(`^(\d+)`)

// TestDuplicateMigrationVersions flags two files claiming the same version —
// ordering between them is ambiguous for any migration runner.
func TestDuplicateMigrationVersions(t *testing.T) {
	files := migrationFiles(t)
	seen := map[string]string{}
	for name := range files {
		m := versionPrefix.FindString(name)
		if m == "" {
			t.Errorf("%s: no numeric version prefix", name)
			continue
		}
		if prev, ok := seen[m]; ok {
			t.Errorf("duplicate migration version %q: %s and %s (ambiguous apply order)", m, prev, name)
		}
		seen[m] = name
	}
}

// TestNoForeignKeyToNonUniqueColumn catches FKs whose target column has no
// unique index — Postgres refuses to create these, so the migration fails.
func TestNoForeignKeyToNonUniqueColumn(t *testing.T) {
	files := migrationFiles(t)
	for name, sql := range files {
		for range regexp.MustCompile(`REFERENCES\s+public\.orders\s*\(\s*uuid_id\s*\)`).FindAllStringIndex(sql, -1) {
			// A UNIQUE index on uuid_id must exist somewhere in the chain before the FK.
			if !regexp.MustCompile(`CREATE UNIQUE INDEX[^;]*uuid_id`).MatchString(allMigrationsBefore(files, name)) {
				t.Errorf("%s: FK REFERENCES orders(uuid_id) but no UNIQUE index on uuid_id exists earlier in the chain", name)
			}
		}
	}
}

// TestNoReferencesToUndefinedColumns statically flags references to columns
// that no migration ever defines (orders.discount_type) or that are only
// created via CREATE TABLE IF NOT EXISTS (no-op on an existing table, so not
// guaranteed to exist).
func TestNoReferencesToUndefinedColumns(t *testing.T) {
	files := migrationFiles(t)
	all := allMigrations(files)

	knownColumns := map[string]bool{
		"users.role":          allSeemsToDefineColumn(all, "users", "role"),
		"daily_deals.valid_from":  allSeemsToDefineColumn(all, "daily_deals", "valid_from"),
		"daily_deals.valid_until": allSeemsToDefineColumn(all, "daily_deals", "valid_until"),
	}
	// orders.discount_type is referenced by 016 but defined nowhere.
	if strings.Contains(all, "discount_type") {
		knownColumns["orders.discount_type"] = false
	}

	for col, defined := range knownColumns {
		if defined {
			continue
		}
		for name, sql := range files {
			if strings.Contains(sql, col) {
				t.Errorf("%s: references %s which is never guaranteed to exist (CREATE TABLE IF NOT EXISTS is a no-op on existing tables)", name, col)
			}
		}
	}
}

// TestNoMoneyValuesInRupeeColumns flags seed/insert values that look like
// paise accidentally written into rupee NUMERIC columns (e.g. item_price 18000).
func TestNoMoneyValuesInRupeeColumns(t *testing.T) {
	files := migrationFiles(t)
	seed, ok := files["013_seed_catalog_data.sql"]
	if !ok {
		t.Skip("013_seed_catalog_data.sql not present")
	}
	// In the seed, money-bearing tables (items, daily_deals, coupons) get bare
	// integer literals >= 10000. Those columns are NUMERIC(10,2) RUPEES, so a
	// value of 18000 means ₹18,000 — i.e. paise written into a rupee column.
	re := regexp.MustCompile(`\b([0-9]{5,})\b`)
	for _, m := range re.FindAllStringSubmatch(seed, -1) {
		t.Errorf("013_seed_catalog_data.sql: bare integer %s in a rupee NUMERIC column — paise-in-rupees (100x inflation)", m[1])
	}
}

// TestItemsIdTypeConflict flags the TEXT (000) vs UUID (010) redefinition.
func TestItemsIdTypeConflict(t *testing.T) {
	files := migrationFiles(t)
	text := files["000_base_schema.sql"]
	uuidDef := files["010_menus_items_deals_schema.sql"]
	if !strings.Contains(text, "id TEXT PRIMARY KEY") {
		t.Log("000_base_schema.sql: items.id not TEXT — check schema drift")
	}
	if strings.Contains(uuidDef, "CREATE TABLE IF NOT EXISTS public.items") &&
		strings.Contains(uuidDef, "id UUID PRIMARY KEY") {
		t.Log("010 redefines items.id as UUID via IF NOT EXISTS — no-op on an existing table; type mismatch with 000 is a migration-chain contradiction")
		t.Error("migration chain contradiction: items.id TEXT (000) vs UUID (010); menus.id/daily_deals.id/coupons.id have the same conflict (BIGINT vs UUID)")
	}
}

// --- helpers ---

func allMigrations(files map[string]string) string {
	names := make([]string, 0, len(files))
	for n := range files {
		names = append(names, n)
	}
	sort.Strings(names)
	var sb strings.Builder
	for _, n := range names {
		sb.WriteString(files[n])
	}
	return sb.String()
}

func allMigrationsBefore(files map[string]string, name string) string {
	names := make([]string, 0, len(files))
	for n := range files {
		names = append(names, n)
	}
	sort.Strings(names)
	var sb strings.Builder
	for _, n := range names {
		if n >= name {
			break
		}
		sb.WriteString(files[n])
	}
	return sb.String()
}

// allSeemsToDefineColumn reports whether the column is created with ALTER
// TABLE ADD COLUMN (guaranteed) rather than only inside CREATE TABLE IF NOT
// EXISTS (which no-ops when the table already exists).
func allSeemsToDefineColumn(all string, table, column string) bool {
	if regexp.MustCompile(`(?i)ALTER\s+TABLE\s+public\.`+table+`\s+ADD\s+(?:COLUMN\s+)?IF\s+NOT\s+EXISTS\s+`+column).MatchString(all) {
		return true
	}
	return false
}
