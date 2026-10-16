// PROTOTYPE - NOT FOR PRODUCTION
// Question: Does local-first sync ever lose or double-count money or session time under faults? (phase 0 server stub)
// Date: 2026-10-16
//
// Server stub: inbox keyed (tenant, device, command_id) with a payload hash,
// compare-and-set cursor per device, one database transaction per batch.
// Env: PG_DSN, ADDR (127.0.0.1 only), RESET=1 (recreate schema), MUTANT, FP=name:hit.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"syscall"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const schema = `
DROP TABLE IF EXISTS inbox, cursor_, ledger, minutes, flags;
CREATE TABLE inbox (
  tenant_id int NOT NULL, device_id text NOT NULL, command_id text NOT NULL,
  seq bigint NOT NULL, payload_hash text NOT NULL, outcome text NOT NULL,
  PRIMARY KEY (tenant_id, device_id, command_id),
  UNIQUE (tenant_id, device_id, seq));
CREATE TABLE cursor_ (tenant_id int NOT NULL, device_id text NOT NULL, last_seq bigint NOT NULL,
  PRIMARY KEY (tenant_id, device_id));
CREATE TABLE ledger (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, tenant_id int NOT NULL,
  device_id text NOT NULL, command_id text NOT NULL, seq bigint NOT NULL, action_id text NOT NULL,
  kind text NOT NULL, amount_piasters bigint NOT NULL);
CREATE TABLE minutes (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, tenant_id int NOT NULL,
  action_id text NOT NULL, session_id text NOT NULL, minute_idx int NOT NULL);
CREATE TABLE flags (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, kind text NOT NULL,
  device_id text NOT NULL, command_id text NOT NULL, seq bigint NOT NULL);
INSERT INTO cursor_ VALUES (1, 'dev-1', 0);
`

type payload struct {
	ActionID        string `json:"action_id"`
	SessionID       string `json:"session_id"`
	Minutes         []int  `json:"minutes"`
	SalePiasters    int64  `json:"sale_piasters"`
	PaymentPiasters int64  `json:"payment_piasters"`
}

type command struct {
	CommandID   string  `json:"command_id"`
	Seq         int64   `json:"seq"`
	PayloadHash string  `json:"payload_hash"`
	Payload     payload `json:"payload"`
}

type batch struct {
	DeviceID string    `json:"device_id"`
	Commands []command `json:"commands"`
}

type result struct {
	CommandID string `json:"command_id"`
	Seq       int64  `json:"seq"`
	Result    string `json:"result"`
}

var (
	pool    *pgxpool.Pool
	mutant  = os.Getenv("MUTANT")
	fpName  string
	fpAt    int
	fpCount int
)

// failpoint kills this process with SIGKILL when the configured point is hit the configured time.
func failpoint(name string) {
	if name != fpName {
		return
	}
	fpCount++
	if fpCount == fpAt {
		log.Printf("FAILPOINT %s hit %d: SIGKILL", name, fpCount)
		syscall.Kill(os.Getpid(), syscall.SIGKILL)
		select {}
	}
}

func insertEffects(ctx context.Context, tx pgx.Tx, dev string, c command) error {
	p := c.Payload
	if _, err := tx.Exec(ctx, `INSERT INTO ledger (tenant_id, device_id, command_id, seq, action_id, kind, amount_piasters)
		VALUES (1,$1,$2,$3,$4,'sale',$5), (1,$1,$2,$3,$4,'payment',$6)`,
		dev, c.CommandID, c.Seq, p.ActionID, p.SalePiasters, p.PaymentPiasters); err != nil {
		return err
	}
	for _, m := range p.Minutes {
		if _, err := tx.Exec(ctx, `INSERT INTO minutes (tenant_id, action_id, session_id, minute_idx) VALUES (1,$1,$2,$3)`,
			p.ActionID, p.SessionID, m); err != nil {
			return err
		}
	}
	return nil
}

func flag(ctx context.Context, tx pgx.Tx, kind, dev string, c command) error {
	_, err := tx.Exec(ctx, `INSERT INTO flags (kind, device_id, command_id, seq) VALUES ($1,$2,$3,$4)`, kind, dev, c.CommandID, c.Seq)
	return err
}

// applyOne applies one command inside the batch transaction and returns its outcome.
// Correct mode: inbox insert (dedupe), compare-and-set cursor (order, gap), effects.
func applyOne(ctx context.Context, tx pgx.Tx, dev string, c command) (string, error) {
	if mutant == "no_dedupe" {
		return "applied", insertEffects(ctx, tx, dev, c)
	}
	if _, err := tx.Exec(ctx, "SAVEPOINT cmd"); err != nil {
		return "", err
	}
	tag, err := tx.Exec(ctx, `INSERT INTO inbox (tenant_id, device_id, command_id, seq, payload_hash, outcome)
		VALUES (1,$1,$2,$3,$4,'applied') ON CONFLICT DO NOTHING`, dev, c.CommandID, c.Seq, c.PayloadHash)
	if err != nil {
		return "", err
	}
	if tag.RowsAffected() == 0 {
		var h string
		err := tx.QueryRow(ctx, `SELECT payload_hash FROM inbox WHERE tenant_id=1 AND device_id=$1 AND command_id=$2`,
			dev, c.CommandID).Scan(&h)
		switch {
		case errors.Is(err, pgx.ErrNoRows):
			return "seq_conflict", flag(ctx, tx, "seq_conflict", dev, c)
		case err != nil:
			return "", err
		case h == c.PayloadHash:
			return "duplicate", nil
		default:
			return "payload_mismatch", flag(ctx, tx, "payload_mismatch", dev, c)
		}
	}
	tag, err = tx.Exec(ctx, `UPDATE cursor_ SET last_seq=$2 WHERE tenant_id=1 AND device_id=$1 AND last_seq=$2-1`, dev, c.Seq)
	if err != nil {
		return "", err
	}
	if tag.RowsAffected() == 0 {
		if _, err := tx.Exec(ctx, "ROLLBACK TO SAVEPOINT cmd"); err != nil {
			return "", err
		}
		return "gap", nil
	}
	return "applied", insertEffects(ctx, tx, dev, c)
}

func handleBatch(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	var b batch
	if err := json.NewDecoder(r.Body).Decode(&b); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	tx, err := pool.Begin(ctx)
	if err != nil {
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
		return
	}
	defer tx.Rollback(context.Background())
	var results []result
	for _, c := range b.Commands {
		out, err := applyOne(ctx, tx, b.DeviceID, c)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		results = append(results, result{c.CommandID, c.Seq, out})
		if out == "gap" {
			break
		}
	}
	var cur int64
	if err := tx.QueryRow(ctx, `SELECT last_seq FROM cursor_ WHERE tenant_id=1 AND device_id=$1`, b.DeviceID).Scan(&cur); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	failpoint("server:before_commit")
	resp, _ := json.Marshal(map[string]any{"results": results, "cursor": cur})
	w.Header().Set("Content-Type", "application/json")
	if mutant == "ack_before_commit" {
		// Planted defect: the client is told "applied" before the commit is durable.
		// Content-Length makes the response complete on the wire before the kill; without it Go
		// streams chunked and the kill truncates the reply, which hid this mutant in the first
		// self-test (finding P0-F1 in README).
		w.Header().Set("Content-Length", strconv.Itoa(len(resp)))
		w.Write(resp)
		w.(http.Flusher).Flush()
		failpoint("server:after_response_before_commit")
		tx.Commit(ctx)
		return
	}
	if err := tx.Commit(ctx); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	failpoint("server:after_commit_before_response")
	w.Write(resp)
}

func dumpRows(ctx context.Context, q string) ([]map[string]any, error) {
	rows, err := pool.Query(ctx, q)
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, pgx.RowToMap)
}

func handleDump(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	out := map[string]any{}
	for name, q := range map[string]string{
		"ledger":  "SELECT id, device_id, command_id, seq, action_id, kind, amount_piasters FROM ledger ORDER BY id",
		"minutes": "SELECT id, action_id, session_id, minute_idx FROM minutes ORDER BY id",
		"inbox":   "SELECT device_id, command_id, seq, payload_hash, outcome FROM inbox ORDER BY seq",
		"flags":   "SELECT id, kind, device_id, command_id, seq FROM flags ORDER BY id",
		"cursor":  "SELECT device_id, last_seq FROM cursor_",
	} {
		rows, err := dumpRows(ctx, q)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		out[name] = rows
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(out)
}

func main() {
	if fp := os.Getenv("FP"); fp != "" {
		i := strings.LastIndex(fp, ":")
		fpName = fp[:i]
		fpAt, _ = strconv.Atoi(fp[i+1:])
	}
	addr := os.Getenv("ADDR")
	if !strings.HasPrefix(addr, "127.0.0.1:") {
		log.Fatal("ADDR must bind 127.0.0.1")
	}
	ctx := context.Background()
	var err error
	pool, err = pgxpool.New(ctx, os.Getenv("PG_DSN"))
	if err != nil {
		log.Fatal(err)
	}
	if os.Getenv("RESET") == "1" {
		if _, err := pool.Exec(ctx, schema); err != nil {
			log.Fatal(err)
		}
	}
	mux := http.NewServeMux()
	mux.HandleFunc("POST /batch", handleBatch)
	mux.HandleFunc("GET /dump", handleDump)
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) { fmt.Fprint(w, "ok") })
	log.Printf("server on %s mutant=%q fp=%q:%d", addr, mutant, fpName, fpAt)
	log.Fatal(http.ListenAndServe(addr, mux))
}
