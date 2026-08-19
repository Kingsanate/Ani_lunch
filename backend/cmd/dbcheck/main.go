// Command dbcheck runs supabase/integrity-check.sql against a PostgreSQL
// database in STRICT read-only mode (session default_transaction_read_only=on,
// so no statement can write — even a malformed one). It parses the `\echo`
// section markers out of the SQL file, executes each block, and prints results.
//
// Usage:
//
//	DATABASE_URL="postgresql://user:pass@host:5432/db" go run ./cmd/dbcheck
package main

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/jackc/pgx/v5"
)

var echoRe = regexp.MustCompile(`^\s*\\echo\s+(?:'([^']*)'|"([^"]*)"|(.+))\s*$`)

type section struct {
	title string
	sql   strings.Builder
}

func main() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		fmt.Fprintln(os.Stderr, "DATABASE_URL is required")
		os.Exit(1)
	}

	sqlPath, err := filepath.Abs(filepath.Join("..", "..", "supabase", "integrity-check.sql"))
	if err != nil {
		fmt.Fprintln(os.Stderr, "resolve path:", err)
		os.Exit(1)
	}
	// Allow override via DBSQL for running from anywhere.
	if v := os.Getenv("DBSQL"); v != "" {
		sqlPath = v
	}

	sections, err := parseSections(sqlPath)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	ctx := context.Background()
	// default_transaction_read_only=on is a session-level hard guarantee that
	// no statement (even malformed) can write to the database.
	cfg, err := pgx.ParseConfig(dsn)
	if err != nil {
		fmt.Fprintln(os.Stderr, "parse dsn:", err)
		os.Exit(1)
	}
	cfg.RuntimeParams["default_transaction_read_only"] = "on"
	conn, err := pgx.ConnectConfig(ctx, cfg)
	if err != nil {
		fmt.Fprintln(os.Stderr, "connect:", err)
		os.Exit(1)
	}
	defer conn.Close(ctx)

	if _, err := conn.Exec(ctx, "SET TRANSACTION READ ONLY"); err != nil {
		fmt.Fprintln(os.Stderr, "set read only:", err)
		os.Exit(1)
	}

	for _, s := range sections {
		stmt := strings.TrimSpace(s.sql.String())
		if stmt == "" {
			continue
		}
		fmt.Printf("\n%s\n%s\n", s.title, strings.Repeat("-", len(s.title)))
		rows, err := conn.Query(ctx, stmt)
		if err != nil {
			fmt.Printf("ERROR: %v\n", err)
			continue
		}
		printRows(rows)
		rows.Close()
	}
}

func parseSections(path string) ([]section, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var sections []section
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		line := sc.Text()
		if strings.HasPrefix(line, "--") || strings.TrimSpace(line) == "" {
			continue
		}
		if m := echoRe.FindStringSubmatch(line); m != nil {
			title := m[1]
			if title == "" {
				title = m[2]
			}
			if title == "" {
				title = m[3]
			}
			sections = append(sections, section{title: title})
			continue
		}
		if len(sections) == 0 {
			sections = append(sections, section{title: "prelude"})
		}
		s := &sections[len(sections)-1]
		s.sql.WriteString(line)
		s.sql.WriteString("\n")
	}
	return sections, sc.Err()
}

func printRows(rows pgx.Rows) {
	cols := rows.FieldDescriptions()
	names := make([]string, len(cols))
	for i, c := range cols {
		names[i] = string(c.Name)
	}
	fmt.Println(strings.Join(names, "\t"))
	for rows.Next() {
		vals, err := rows.Values()
		if err != nil {
			fmt.Printf("ERROR reading row: %v\n", err)
			return
		}
		out := make([]string, len(vals))
		for i, v := range vals {
			switch t := v.(type) {
			case nil:
				out[i] = "NULL"
			case []byte:
				out[i] = string(t)
			default:
				out[i] = fmt.Sprintf("%v", v)
			}
		}
		fmt.Println(strings.Join(out, "\t"))
	}
}