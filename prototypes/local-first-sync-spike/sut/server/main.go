// PROTOTYPE - NOT FOR PRODUCTION
// Question: Does local-first sync ever lose or double-count money or session time under faults? (phase 0 server stub)
// Date: 2026-10-16
//
// Server stub: inbox keyed (tenant, device, command_id) with a payload hash,
// compare-and-set cursor per device, one database transaction per batch.
// Env: PG_DSN, ADDR (127.0.0.1 only), RESET=1 (recreate schema), MUTANT, FP=name:hit,
//
//	GAP_MS (contact gap that counts as offline, TS-09), BUSINESS_HOURS (1 = alert on gaps, 0 = record only),
//	SLOW_COMMIT_MS (sleep before COMMIT, so a backup can be taken inside a batch: SC-19).
//
// SC-19 (server restored from backup): every restore sets a new meta.epoch (restore runbook step). A device's
// batch carries acked_seq (its highest acknowledged sequence H) and low_seq (its lowest retained sequence L).
// When the cursor N < H the server asks for "resend from N+1"; when L > N+1 the range N+1..L-1 can no longer be
// recovered: it is recorded as lost, the owner is alerted and the cursor skips it (an explicit, recorded skip).
// The first contact of each device in a new epoch is always recorded (reconcile_events). A device in a new epoch
// that does not report acked_seq is refused ("reconcile_required"). MUTANT=no_reconcile skips the comparison.
//
// SC-23 (owner changes prices while the device is offline; founder rules 2026-10-16): the config feed carries a
// price list (per-tier station rates and the cafe item price). A sale carries cfg_version, the newest price-list
// version it used. The server records the amount the device sent and never re-prices it. Sales billed under an
// older version than the server's current one are counted into ONE owner summary per offline period (the period
// the device just came back from, from the TS-09 contact-gap record); no per-sale flag. MUTANT=reprice_on_server
// recomputes the amount with current prices; MUTANT=per_sale_flag flags every such sale for review.
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
	"sync"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const schema = `
DROP TABLE IF EXISTS inbox, cursor_, ledger, minutes, flags, offline_periods, meta, device_epoch, archive_mark,
  reconcile_events, config, device_events, price_summaries;
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
CREATE TABLE offline_periods (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, device_id text NOT NULL,
  from_ts timestamptz NOT NULL, to_ts timestamptz NOT NULL, owner_alert boolean NOT NULL);
INSERT INTO cursor_ VALUES (1, 'dev-1', 0);
CREATE TABLE meta (id int PRIMARY KEY CHECK (id = 1), epoch text NOT NULL);
INSERT INTO meta VALUES (1, 'e0');
CREATE TABLE device_epoch (device_id text PRIMARY KEY, epoch text NOT NULL);
CREATE TABLE archive_mark (device_id text PRIMARY KEY, archived_seq bigint NOT NULL);
CREATE TABLE reconcile_events (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, device_id text NOT NULL,
  epoch text NOT NULL, server_cursor bigint NOT NULL, device_acked bigint NOT NULL, device_low bigint NOT NULL,
  outcome text NOT NULL, lost_from bigint, lost_to bigint, owner_alert boolean NOT NULL,
  UNIQUE (device_id, epoch, server_cursor, outcome));
CREATE TABLE config (id int PRIMARY KEY CHECK (id = 1), version int NOT NULL, price int NOT NULL,
  prices jsonb NOT NULL);
INSERT INTO config VALUES (1, 1, 6000, '{"std": 6000, "vip": 9000, "cafe": 1500}');
CREATE TABLE price_summaries (device_id text NOT NULL, period_key bigint NOT NULL, n_sales int NOT NULL,
  owner_alert boolean NOT NULL DEFAULT true, PRIMARY KEY (device_id, period_key));
CREATE TABLE device_events (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, device_id text NOT NULL,
  kind text NOT NULL, detail jsonb NOT NULL, owner_alert boolean NOT NULL);
`

type payload struct {
	ActionID        string    `json:"action_id"`
	SessionID       string    `json:"session_id"`
	Minutes         []int     `json:"minutes"`
	SalePiasters    int64     `json:"sale_piasters"`
	PaymentPiasters int64     `json:"payment_piasters"`
	CfgVersion      int       `json:"cfg_version"` // SC-23: newest price-list version the bill used (0 = not priced from the feed)
	Segments        []segment `json:"segments"`
	Cafe            *cafe     `json:"cafe"`
}

type segment struct {
	Tier string `json:"tier"`
	Mins int64  `json:"mins"`
	Rate int64  `json:"rate"`
	V    int    `json:"v"`
}

type cafe struct {
	N     int64 `json:"n"`
	Price int64 `json:"price"`
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
	AckedSeq *int64    `json:"acked_seq"` // SC-19: highest sequence the device holds an ack for
	LowSeq   *int64    `json:"low_seq"`   // SC-19: lowest sequence the device still retains (H+1 if none)
}

type result struct {
	CommandID string `json:"command_id"`
	Seq       int64  `json:"seq"`
	Result    string `json:"result"`
}

// TS-09: the server records every gap in device contact longer than GAP_MS; server time is the fact.
var (
	contactMu   sync.Mutex
	lastContact = map[string]time.Time{}
)

// contact records device contact; it returns the id of the offline period it just closed, or 0.
func contact(ctx context.Context, dev string) int64 {
	gapMs, _ := strconv.Atoi(os.Getenv("GAP_MS"))
	if gapMs <= 0 {
		return 0
	}
	now := time.Now()
	contactMu.Lock()
	prev, seen := lastContact[dev]
	lastContact[dev] = now
	contactMu.Unlock()
	if seen && now.Sub(prev) > time.Duration(gapMs)*time.Millisecond {
		alert := os.Getenv("BUSINESS_HOURS") == "1"
		var id int64
		pool.QueryRow(ctx, `INSERT INTO offline_periods (device_id, from_ts, to_ts, owner_alert) VALUES ($1,$2,$3,$4) RETURNING id`,
			dev, prev, now, alert).Scan(&id)
		return id
	}
	return 0
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
	if mutant == "reprice_on_server" && len(p.Segments) > 0 { // planted defect: re-prices with today's list
		var prices map[string]int64
		if err := tx.QueryRow(ctx, `SELECT prices FROM config WHERE id = 1`).Scan(&prices); err != nil {
			return err
		}
		var amount int64
		for _, sg := range p.Segments {
			amount += (sg.Mins*prices[sg.Tier] + 30) / 60
		}
		if p.Cafe != nil {
			amount += p.Cafe.N * prices["cafe"]
		}
		p.SalePiasters, p.PaymentPiasters = amount, amount
	}
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

var errReconcileRequired = errors.New("reconcile required")

// reconcile compares the device's acknowledged high-water mark with the server cursor (SC-19). It returns the
// sequence the device must resend from (0 = nothing to resend).
func reconcile(ctx context.Context, tx pgx.Tx, b batch) (int64, error) {
	var epoch string
	if err := tx.QueryRow(ctx, `SELECT epoch FROM meta WHERE id=1`).Scan(&epoch); err != nil {
		return 0, err
	}
	var devEpoch string
	err := tx.QueryRow(ctx, `SELECT epoch FROM device_epoch WHERE device_id=$1`, b.DeviceID).Scan(&devEpoch)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return 0, err
	}
	newEpoch := devEpoch != epoch
	if b.AckedSeq == nil {
		if newEpoch && epoch != "e0" {
			return 0, errReconcileRequired
		}
		return 0, nil // phases 0-2 clients do not report; nothing to compare
	}
	var cur int64
	if err := tx.QueryRow(ctx, `SELECT last_seq FROM cursor_ WHERE tenant_id=1 AND device_id=$1 FOR UPDATE`, b.DeviceID).Scan(&cur); err != nil {
		return 0, err
	}
	h, low := *b.AckedSeq, h1(b)
	outcome, resendFrom := "in_sync", int64(0)
	var lostFrom, lostTo *int64
	if mutant != "no_reconcile" && cur < h {
		if low <= cur+1 {
			outcome, resendFrom = "resend", cur+1
		} else {
			// The device pruned part of what the server lost: record the exact range, alert, skip it explicitly.
			f, t := cur+1, low-1
			lostFrom, lostTo = &f, &t
			outcome, resendFrom = "lost_range", low
			if _, err := tx.Exec(ctx, `UPDATE cursor_ SET last_seq=$2 WHERE tenant_id=1 AND device_id=$1`, b.DeviceID, low-1); err != nil {
				return 0, err
			}
		}
	}
	if newEpoch || outcome != "in_sync" {
		if _, err := tx.Exec(ctx, `INSERT INTO reconcile_events (device_id, epoch, server_cursor, device_acked, device_low,
			outcome, lost_from, lost_to, owner_alert) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT DO NOTHING`,
			b.DeviceID, epoch, cur, h, low, outcome, lostFrom, lostTo, outcome != "in_sync"); err != nil {
			return 0, err
		}
	}
	if newEpoch {
		if _, err := tx.Exec(ctx, `INSERT INTO device_epoch VALUES ($1,$2) ON CONFLICT (device_id) DO UPDATE SET epoch=$2`,
			b.DeviceID, epoch); err != nil {
			return 0, err
		}
	}
	if resendFrom > h {
		resendFrom = 0
	}
	return resendFrom, nil
}

func h1(b batch) int64 {
	if b.LowSeq == nil {
		return *b.AckedSeq + 1
	}
	return *b.LowSeq
}

func handleBatch(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	var b batch
	if err := json.NewDecoder(r.Body).Decode(&b); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	period := contact(ctx, b.DeviceID)
	tx, err := pool.Begin(ctx)
	if err != nil {
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
		return
	}
	defer tx.Rollback(context.Background())
	resendFrom, err := reconcile(ctx, tx, b)
	if errors.Is(err, errReconcileRequired) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"results":[],"reconcile_required":true}`))
		return
	}
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	var curVersion int
	if err := tx.QueryRow(ctx, `SELECT version FROM config WHERE id = 1`).Scan(&curVersion); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	var results []result
	stale := 0
	for _, c := range b.Commands {
		out, err := applyOne(ctx, tx, b.DeviceID, c)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		results = append(results, result{c.CommandID, c.Seq, out})
		if out == "applied" && c.Payload.CfgVersion > 0 && c.Payload.CfgVersion < curVersion {
			stale++ // billed at a previous price: a valid fact (SC-23 rule 2)
			if mutant == "per_sale_flag" {
				if err := flag(ctx, tx, "needs_review_price", b.DeviceID, c); err != nil {
					http.Error(w, err.Error(), http.StatusInternalServerError)
					return
				}
			}
		}
		if out == "gap" {
			break
		}
	}
	if stale > 0 {
		// One summary per offline period: the period this contact closed, or the one a continuation batch follows.
		key := period
		if key == 0 {
			tx.QueryRow(ctx, `SELECT coalesce(max(id), 0) FROM offline_periods WHERE device_id = $1
				AND to_ts > now() - interval '30 seconds'`, b.DeviceID).Scan(&key)
		}
		if _, err := tx.Exec(ctx, `INSERT INTO price_summaries (device_id, period_key, n_sales) VALUES ($1,$2,$3)
			ON CONFLICT (device_id, period_key) DO UPDATE SET n_sales = price_summaries.n_sales + EXCLUDED.n_sales`,
			b.DeviceID, key, stale); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	}
	var cur int64
	if err := tx.QueryRow(ctx, `SELECT last_seq FROM cursor_ WHERE tenant_id=1 AND device_id=$1`, b.DeviceID).Scan(&cur); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if resendFrom > 0 && cur >= resendFrom {
		resendFrom = cur + 1 // this batch closed part of the gap: ask for the rest only
		if resendFrom > *b.AckedSeq {
			resendFrom = 0
		}
	}
	var archived int64
	if err := tx.QueryRow(ctx, `SELECT coalesce(max(archived_seq), 0) FROM archive_mark WHERE device_id=$1`, b.DeviceID).Scan(&archived); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	failpoint("server:before_commit")
	if ms, _ := strconv.Atoi(os.Getenv("SLOW_COMMIT_MS")); ms > 0 {
		time.Sleep(time.Duration(ms) * time.Millisecond)
	}
	resp, _ := json.Marshal(map[string]any{"results": results, "cursor": cur, "resend_from": resendFrom,
		"archived_seq": archived})
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

// handleArchive records that a verified backup holds the device's commands up to seq (the backup tool's
// confirmation; the device may prune retained records at or below it, SC-19).
func handleArchive(w http.ResponseWriter, r *http.Request) {
	seq, err := strconv.ParseInt(r.URL.Query().Get("seq"), 10, 64)
	if err != nil {
		http.Error(w, "seq", http.StatusBadRequest)
		return
	}
	if _, err := pool.Exec(r.Context(), `INSERT INTO archive_mark VALUES ($1,$2)
		ON CONFLICT (device_id) DO UPDATE SET archived_seq = greatest(archive_mark.archived_seq, $2)`,
		r.URL.Query().Get("device"), seq); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	fmt.Fprint(w, `{"ok":true}`)
}

// handleDeviceEvent records device-side events (SC-20: disk_full, marker_behind) and raises an owner alert for
// each; the detail carries error classes only, never business data.
func handleDeviceEvent(w http.ResponseWriter, r *http.Request) {
	var b struct {
		DeviceID string           `json:"device_id"`
		Events   []map[string]any `json:"events"`
	}
	if err := json.NewDecoder(r.Body).Decode(&b); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	for _, e := range b.Events {
		kind, _ := e["event"].(string)
		detail, _ := json.Marshal(e)
		if _, err := pool.Exec(r.Context(), `INSERT INTO device_events (device_id, kind, detail, owner_alert) VALUES ($1,$2,$3,true)`,
			b.DeviceID, kind, detail); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	}
	fmt.Fprint(w, `{"ok":true}`)
}

// handleConfig: GET returns the current config with the restore epoch; POST ?price= is an owner edit (version+1).
func handleConfig(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	if r.Method == http.MethodPost {
		var err error
		if q := r.URL.Query().Get("price"); q != "" { // SC-19: one owner edit of the standard rate
			price, perr := strconv.Atoi(q)
			if perr != nil {
				http.Error(w, "price", http.StatusBadRequest)
				return
			}
			_, err = pool.Exec(ctx, `UPDATE config SET version = version + 1, price = $1,
				prices = jsonb_set(prices, '{std}', to_jsonb($1::int)) WHERE id = 1`, price)
		} else { // SC-23: the owner edits the price list
			var body struct {
				Prices map[string]int64 `json:"prices"`
			}
			if derr := json.NewDecoder(r.Body).Decode(&body); derr != nil || len(body.Prices) == 0 {
				http.Error(w, "prices", http.StatusBadRequest)
				return
			}
			pj, _ := json.Marshal(body.Prices)
			_, err = pool.Exec(ctx, `UPDATE config SET version = version + 1, price = coalesce(($1::jsonb->>'std')::int, price),
				prices = $1::jsonb WHERE id = 1`, string(pj))
		}
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	} else if dev := r.URL.Query().Get("device"); dev != "" {
		contact(ctx, dev) // a device pulling its config is in contact
	}
	var epoch string
	var version, price int
	var prices map[string]int64
	if err := pool.QueryRow(ctx, `SELECT m.epoch, c.version, c.price, c.prices FROM meta m, config c`).Scan(&epoch, &version, &price, &prices); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{"epoch": epoch, "version": version, "price": price, "prices": prices})
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
		"ledger":        "SELECT id, device_id, command_id, seq, action_id, kind, amount_piasters FROM ledger ORDER BY id",
		"minutes":       "SELECT id, action_id, session_id, minute_idx FROM minutes ORDER BY id",
		"inbox":         "SELECT device_id, command_id, seq, payload_hash, outcome FROM inbox ORDER BY seq",
		"flags":         "SELECT id, kind, device_id, command_id, seq FROM flags ORDER BY id",
		"cursor":        "SELECT device_id, last_seq FROM cursor_",
		"offline":       "SELECT device_id, extract(epoch FROM from_ts)::float8 AS from_s, extract(epoch FROM to_ts)::float8 AS to_s, owner_alert FROM offline_periods ORDER BY id",
		"reconcile":     "SELECT device_id, epoch, server_cursor, device_acked, device_low, outcome, lost_from, lost_to, owner_alert FROM reconcile_events ORDER BY id",
		"meta":          "SELECT epoch FROM meta",
		"config":        "SELECT version, price FROM config",
		"device_events": "SELECT device_id, kind, detail, owner_alert FROM device_events ORDER BY id",
		"price_summaries": `SELECT s.device_id, s.period_key, s.n_sales, s.owner_alert,
			extract(epoch FROM o.from_ts)::float8 AS from_s, extract(epoch FROM o.to_ts)::float8 AS to_s
			FROM price_summaries s LEFT JOIN offline_periods o ON o.id = s.period_key ORDER BY s.period_key`,
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
	mux.HandleFunc("POST /archive", handleArchive)
	mux.HandleFunc("POST /device_event", handleDeviceEvent)
	mux.HandleFunc("GET /config", handleConfig)
	mux.HandleFunc("POST /config", handleConfig)
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) { fmt.Fprint(w, "ok") })
	mux.HandleFunc("GET /ping", func(w http.ResponseWriter, r *http.Request) {
		contact(r.Context(), r.URL.Query().Get("device"))
		fmt.Fprint(w, `{"ok":true}`)
	})
	log.Printf("server on %s mutant=%q fp=%q:%d", addr, mutant, fpName, fpAt)
	log.Fatal(http.ListenAndServe(addr, mux))
}
