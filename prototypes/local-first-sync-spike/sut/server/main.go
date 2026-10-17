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
// Rule 2 widened (founder, 2026-10-17): one summary per period in which the device lacked the current price list,
// offline or simply not yet pulled. A sale is judged only by its cfg_version against the list in force on the
// server at upload, never by device time. The period is keyed by the old version the device was on: it runs from
// the server's publication of the next version to the device's first pull of a newer one (server time); offline
// periods inside it are context for the owner message. MUTANT=offline_only keeps the first rule (summaries per
// offline period only, nothing for an online lag).
//
// SC-25b (N5 offline lease, founder rule 2026-10-17): every contact (a batch reply, a config pull) issues a lease
// {server_time, grace_s, warn_s} (LEASE_G_S, LEASE_WARN_S; spike defaults 7 days and 24 h). The owner warning and the
// expiry are computed from the server's own clock and the last lease issued, so the owner is warned even while the
// device is offline. The server never refuses a backlog because the lease ran out. POST /test/clock?advance=
// moves the server clock (spike test hook). MUTANT=reject_after_expiry refuses batches from an expired device.
//
// SC-28 (dashboard edit of an open bill, founder rule 2026-10-17, sync note OQ9 (2)): POST /edit is the owner's
// edit (add n cafe items to an open session), idempotent on edit_id. It is refused, and nothing is stored, when the
// device is not connected (no contact within PRESENCE_S seconds of server time). It is rejected visibly at once when
// the server already holds the closed bill. Otherwise it is stored "pending" with a deadline (EDIT_TTL_S). Every
// batch reply carries the device's pending edits and the server time, and records the first delivery. The device
// decides; its edit_result command (an ordinary command in its sequence) ends the edit "applied" or "rejected".
// An edit never delivered by its deadline is rejected ("device_unreachable") by the server; it will never be sent.
// An edit delivered once can only be ended by the device (the reply may have arrived): it stays "pending, sent at
// X" until the device's next contact. POST /correction records a correction of a closed bill as a new record; the
// original sale is never rewritten (OQ9 (3), OQ6). MUTANT=queue_when_offline stores edits for an offline device;
// MUTANT=expire_delivered rejects delivered edits at the deadline too; MUTANT=correction_rewrites changes the
// original sale row.
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
	"sync/atomic"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

const schema = `
DROP TABLE IF EXISTS inbox, cursor_, ledger, minutes, flags, offline_periods, meta, device_epoch, archive_mark,
  reconcile_events, config, device_events, price_summaries, config_history, device_pulls, device_leases, edits,
  corrections;
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
CREATE TABLE config_history (version int PRIMARY KEY, prices jsonb NOT NULL, created_at timestamptz NOT NULL DEFAULT now());
INSERT INTO config_history (version, prices) SELECT version, prices FROM config;
CREATE TABLE device_pulls (device_id text NOT NULL, version int NOT NULL, at timestamptz NOT NULL DEFAULT now());
CREATE TABLE device_leases (device_id text PRIMARY KEY, issued_at double precision NOT NULL, grace_s bigint NOT NULL,
  warn_s bigint NOT NULL);
CREATE TABLE price_summaries (device_id text NOT NULL, kind text NOT NULL, period_key bigint NOT NULL,
  n_sales int NOT NULL, owner_alert boolean NOT NULL DEFAULT true, PRIMARY KEY (device_id, kind, period_key));
CREATE TABLE device_events (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, device_id text NOT NULL,
  kind text NOT NULL, detail jsonb NOT NULL, owner_alert boolean NOT NULL);
CREATE TABLE edits (edit_id text PRIMARY KEY, device_id text NOT NULL, session_id text NOT NULL, n int NOT NULL,
  state text NOT NULL, reason text, created_at double precision NOT NULL, deadline double precision NOT NULL,
  delivered_at double precision, deliveries int NOT NULL DEFAULT 0, resolved_at double precision, resolved_by text);
CREATE TABLE corrections (correction_id text PRIMARY KEY, action_id text NOT NULL, delta_piasters bigint NOT NULL,
  original_piasters bigint NOT NULL);
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
	Kind            string    `json:"kind"` // SC-28: "" = a bill, "edit_result" = the device's decision on an edit
	EditID          string    `json:"edit_id"`
	Result          string    `json:"result"`
	Reason          *string   `json:"reason"`
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

var clockOffset atomic.Int64 // SC-25b: test hook, nanoseconds added to the server clock for leases

// SC-28: last contact per device on the server clock (presence for dashboard edits).
var (
	seenMu   sync.Mutex
	lastSeen = map[string]float64{}
)

func nowS() float64 { return float64(serverNow().UnixNano()) / 1e9 }

func seen(dev string) {
	if dev == "" {
		return
	}
	seenMu.Lock()
	lastSeen[dev] = nowS()
	seenMu.Unlock()
}

func connected(dev string) bool {
	seenMu.Lock()
	t, ok := lastSeen[dev]
	seenMu.Unlock()
	return ok && nowS()-t <= float64(envSeconds("PRESENCE_S", 15))
}

type execer interface {
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
}

// expireEdits rejects every pending edit whose deadline has passed and that was never delivered (SC-28).
func expireEdits(ctx context.Context, db execer) error {
	cond := "delivered_at IS NULL"
	if mutant == "expire_delivered" { // planted defect: a delivered edit may already be applied on the device
		cond = "true"
	}
	_, err := db.Exec(ctx, `UPDATE edits SET state = 'rejected', reason = 'device_unreachable', resolved_at = $1,
		resolved_by = 'server' WHERE state = 'pending' AND deadline <= $1 AND `+cond, nowS())
	return err
}

func serverNow() time.Time { return time.Now().Add(time.Duration(clockOffset.Load())) }

func envSeconds(name string, def int64) int64 {
	if v, err := strconv.ParseInt(os.Getenv(name), 10, 64); err == nil && v > 0 {
		return v
	}
	return def
}

// issueLease records and returns a fresh lease for the device (SC-25b).
func issueLease(ctx context.Context, dev string) map[string]any {
	now := float64(serverNow().UnixNano()) / 1e9
	g, w := envSeconds("LEASE_G_S", 7*24*3600), envSeconds("LEASE_WARN_S", 24*3600)
	pool.Exec(ctx, `INSERT INTO device_leases VALUES ($1,$2,$3,$4) ON CONFLICT (device_id)
		DO UPDATE SET issued_at = $2, grace_s = $3, warn_s = $4`, dev, now, g, w)
	return map[string]any{"server_time": now, "grace_s": g, "warn_s": w}
}

// leaseExpired reports whether the device's last lease has run out on the server's clock.
func leaseExpired(ctx context.Context, dev string) bool {
	var issued float64
	var g int64
	if err := pool.QueryRow(ctx, `SELECT issued_at, grace_s FROM device_leases WHERE device_id = $1`, dev).Scan(&issued, &g); err != nil {
		return false
	}
	return float64(serverNow().UnixNano())/1e9 >= issued+float64(g)
}

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
	if p.Kind == "edit_result" { // SC-28: the device decided; the edit ends here
		tag, err := tx.Exec(ctx, `UPDATE edits SET state = $2, reason = $3, resolved_at = $4, resolved_by = 'device'
			WHERE edit_id = $1 AND device_id = $5 AND state = 'pending'`, p.EditID, p.Result, p.Reason, nowS(), dev)
		if err != nil || tag.RowsAffected() == 1 {
			return err
		}
		var state string
		if err := tx.QueryRow(ctx, `SELECT state FROM edits WHERE edit_id = $1`, p.EditID).Scan(&state); err != nil || state != p.Result {
			return flag(ctx, tx, "edit_conflict", dev, c) // the server ended it otherwise, or never sent it
		}
		return nil
	}
	if mutant == "reprice_on_server" && len(p.Segments) > 0 { // planted defect: re-prices with today's list
		var prices map[string]int64
		if err := tx.QueryRow(ctx, `SELECT prices FROM config WHERE id = 1`).Scan(&prices); err != nil {
			return err
		}
		var units int64
		for _, sg := range p.Segments {
			units += sg.Mins * prices[sg.Tier]
		}
		amount := (units + 30) / 60
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
	seen(b.DeviceID)
	if mutant == "reject_after_expiry" && leaseExpired(ctx, b.DeviceID) { // planted defect: the backlog is refused
		http.Error(w, `{"error":"lease_expired"}`, http.StatusForbidden)
		return
	}
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
	results := []result{} // always a list, also for an empty batch (an SC-25b lease heartbeat): never JSON null
	stale := 0
	lagged := map[int]int{} // old version -> sales (rule 2 widened: online, the device had not pulled the new list)
	for _, c := range b.Commands {
		out, err := applyOne(ctx, tx, b.DeviceID, c)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		results = append(results, result{c.CommandID, c.Seq, out})
		if out == "applied" && c.Payload.CfgVersion > 0 && c.Payload.CfgVersion < curVersion {
			stale++ // billed at a previous price: a valid fact (SC-23 rule 2)
			lagged[c.Payload.CfgVersion]++
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
		rows := map[int64]int{}
		kind := "lacking"
		for v, n := range lagged { // one summary per old version the device was still on
			rows[int64(v)] = n
		}
		if mutant == "offline_only" { // the first rule: per offline period, nothing for an online lag
			kind, rows = "offline", map[int64]int{}
			key := period
			if key == 0 {
				tx.QueryRow(ctx, `SELECT coalesce(max(id), 0) FROM offline_periods WHERE device_id = $1
					AND to_ts > now() - interval '30 seconds'`, b.DeviceID).Scan(&key)
			}
			if key > 0 {
				rows[key] = stale
			}
		}
		for k, n := range rows {
			if _, err := tx.Exec(ctx, `INSERT INTO price_summaries (device_id, kind, period_key, n_sales) VALUES ($1,$2,$3,$4)
				ON CONFLICT (device_id, kind, period_key) DO UPDATE SET n_sales = price_summaries.n_sales + EXCLUDED.n_sales`,
				b.DeviceID, kind, k, n); err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
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
	// SC-28: after this batch's edit results are applied, offer the device every edit still pending for it: those
	// not yet past their deadline, and those already delivered once (only the device can end them).
	if err := expireEdits(ctx, tx); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	now := nowS()
	edits, err := tx.Query(ctx, `UPDATE edits SET delivered_at = coalesce(delivered_at, $2), deliveries = deliveries + 1
		WHERE device_id = $1 AND state = 'pending' AND (delivered_at IS NOT NULL OR deadline > $2)
		RETURNING edit_id, session_id, n, deadline`, b.DeviceID, now)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	offered, err := pgx.CollectRows(edits, pgx.RowToMap)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	failpoint("server:before_commit")
	if ms, _ := strconv.Atoi(os.Getenv("SLOW_COMMIT_MS")); ms > 0 {
		time.Sleep(time.Duration(ms) * time.Millisecond)
	}
	resp, _ := json.Marshal(map[string]any{"results": results, "cursor": cur, "resend_from": resendFrom,
		"archived_seq": archived, "lease": issueLease(ctx, b.DeviceID), "edits": offered, "server_time": now})
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
		if err == nil {
			_, err = pool.Exec(ctx, `INSERT INTO config_history (version, prices) SELECT version, prices FROM config
				ON CONFLICT (version) DO NOTHING`)
		}
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	} else if dev := r.URL.Query().Get("device"); dev != "" {
		contact(ctx, dev) // a device pulling its config is in contact
		seen(dev)
		defer pool.Exec(context.Background(), `INSERT INTO device_pulls (device_id, version) SELECT $1, version FROM config`, dev)
	}
	var epoch string
	var version, price int
	var prices map[string]int64
	if err := pool.QueryRow(ctx, `SELECT m.epoch, c.version, c.price, c.prices FROM meta m, config c`).Scan(&epoch, &version, &price, &prices); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	out := map[string]any{"epoch": epoch, "version": version, "price": price, "prices": prices}
	if dev := r.URL.Query().Get("device"); dev != "" && r.Method == http.MethodGet {
		out["lease"] = issueLease(ctx, dev)
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(out)
}

// handleEdit: POST is the owner's dashboard edit of an open bill (SC-28), GET ?id= its state as the dashboard shows it.
func handleEdit(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	w.Header().Set("Content-Type", "application/json")
	if err := expireEdits(ctx, pool); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	id := r.URL.Query().Get("id")
	if r.Method == http.MethodPost {
		var e struct {
			EditID    string `json:"edit_id"`
			DeviceID  string `json:"device_id"`
			SessionID string `json:"session_id"`
			N         int    `json:"n"`
		}
		if err := json.NewDecoder(r.Body).Decode(&e); err != nil || e.EditID == "" || e.N <= 0 {
			http.Error(w, "edit", http.StatusBadRequest)
			return
		}
		id = e.EditID
		var known bool
		pool.QueryRow(ctx, `SELECT true FROM edits WHERE edit_id = $1`, id).Scan(&known)
		if !known { // a repeated POST of the same edit id only reads its state
			var closed bool
			// The session's billed minutes arrive with its closing bill (spike: single tenant, sessions of >= 1 minute).
			pool.QueryRow(ctx, `SELECT true FROM minutes WHERE session_id = $1 LIMIT 1`, e.SessionID).Scan(&closed)
			now := nowS()
			switch {
			case closed: // the server already holds the closed bill: rejected visibly, at once
				_, err := pool.Exec(ctx, `INSERT INTO edits (edit_id, device_id, session_id, n, state, reason, created_at,
					deadline, resolved_at, resolved_by) VALUES ($1,$2,$3,$4,'rejected','bill_closed',$5,$5,$5,'server')
					ON CONFLICT DO NOTHING`, id, e.DeviceID, e.SessionID, e.N, now)
				if err != nil {
					http.Error(w, err.Error(), http.StatusInternalServerError)
					return
				}
			case !connected(e.DeviceID) && mutant != "queue_when_offline": // refused; nothing is queued
				w.WriteHeader(http.StatusConflict)
				fmt.Fprintf(w, `{"edit_id":%q,"state":"refused","reason":"device_offline"}`, id)
				return
			default:
				_, err := pool.Exec(ctx, `INSERT INTO edits (edit_id, device_id, session_id, n, state, created_at, deadline)
					VALUES ($1,$2,$3,$4,'pending',$5,$6) ON CONFLICT DO NOTHING`,
					id, e.DeviceID, e.SessionID, e.N, now, now+float64(envSeconds("EDIT_TTL_S", 120)))
				if err != nil {
					http.Error(w, err.Error(), http.StatusInternalServerError)
					return
				}
			}
		}
	}
	rows, err := dumpRows(ctx, fmt.Sprintf(`SELECT edit_id, session_id, n, state, reason, created_at, deadline,
		delivered_at, deliveries, resolved_at, resolved_by FROM edits WHERE edit_id = '%s'`, strings.ReplaceAll(id, "'", "''")))
	if err != nil || len(rows) == 0 {
		w.WriteHeader(http.StatusNotFound)
		fmt.Fprintf(w, `{"edit_id":%q,"state":"unknown"}`, id)
		return
	}
	json.NewEncoder(w).Encode(rows[0])
}

// handleCorrection records a correction of a closed bill as a new record, idempotent on correction_id (SC-28, OQ9 (3)).
func handleCorrection(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	var c struct {
		CorrectionID string `json:"correction_id"`
		ActionID     string `json:"action_id"`
		Delta        int64  `json:"delta_piasters"`
	}
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil || c.CorrectionID == "" {
		http.Error(w, "correction", http.StatusBadRequest)
		return
	}
	var original int64
	if err := pool.QueryRow(ctx, `SELECT amount_piasters FROM ledger WHERE action_id = $1 AND kind = 'sale' ORDER BY id LIMIT 1`,
		c.ActionID).Scan(&original); err != nil {
		http.Error(w, `{"error":"no closed bill"}`, http.StatusNotFound)
		return
	}
	tag, err := pool.Exec(ctx, `INSERT INTO corrections VALUES ($1,$2,$3,$4) ON CONFLICT DO NOTHING`,
		c.CorrectionID, c.ActionID, c.Delta, original)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if mutant == "correction_rewrites" && tag.RowsAffected() == 1 { // planted defect: the original is changed
		pool.Exec(ctx, `UPDATE ledger SET amount_piasters = amount_piasters + $2 WHERE action_id = $1`, c.ActionID, c.Delta)
	}
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, `{"ok":true,"recorded":%t}`, tag.RowsAffected() == 1)
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
		"edits":         "SELECT edit_id, session_id, n, state, reason, created_at, deadline, delivered_at, deliveries, resolved_at, resolved_by FROM edits ORDER BY created_at",
		"corrections":   "SELECT correction_id, action_id, delta_piasters, original_piasters FROM corrections ORDER BY correction_id",
		"price_summaries": `WITH b AS (SELECT s.*,
			  (SELECT h.created_at FROM config_history h WHERE h.version = s.period_key + 1) AS from_ts,
			  (SELECT min(p.at) FROM device_pulls p WHERE p.device_id = s.device_id AND p.version > s.period_key) AS to_ts
			  FROM price_summaries s)
			SELECT b.device_id, b.kind, b.period_key, b.n_sales, b.owner_alert,
			  extract(epoch FROM b.from_ts)::float8 AS from_s, extract(epoch FROM b.to_ts)::float8 AS to_s,
			  (SELECT count(*) FROM offline_periods o WHERE o.device_id = b.device_id
			     AND o.to_ts > b.from_ts AND o.from_ts < coalesce(b.to_ts, now())) AS offline_periods
			FROM b ORDER BY b.kind, b.period_key`,
	} {
		rows, err := dumpRows(ctx, q)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		out[name] = rows
	}
	// SC-25b: the owner's view of each device's lease, on the server's own clock.
	now := float64(serverNow().UnixNano()) / 1e9
	leases, err := dumpRows(ctx, `SELECT device_id, issued_at, grace_s, warn_s FROM device_leases ORDER BY device_id`)
	if err == nil {
		for _, l := range leases {
			issued, g, wn := l["issued_at"].(float64), float64(l["grace_s"].(int64)), float64(l["warn_s"].(int64))
			l["server_now"], l["owner_warning"], l["expired"] = now, now >= issued+g-wn, now >= issued+g
		}
		out["lease_status"] = leases
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
	mux.HandleFunc("POST /test/clock", func(w http.ResponseWriter, r *http.Request) { // SC-25b spike test hook
		sec, err := strconv.ParseFloat(r.URL.Query().Get("advance"), 64)
		if err != nil {
			http.Error(w, "advance", http.StatusBadRequest)
			return
		}
		clockOffset.Add(int64(sec * 1e9))
		fmt.Fprintf(w, `{"server_now":%f}`, float64(serverNow().UnixNano())/1e9)
	})
	mux.HandleFunc("POST /edit", handleEdit)
	mux.HandleFunc("GET /edit", handleEdit)
	mux.HandleFunc("POST /correction", handleCorrection)
	mux.HandleFunc("GET /config", handleConfig)
	mux.HandleFunc("POST /config", handleConfig)
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) { fmt.Fprint(w, "ok") })
	mux.HandleFunc("GET /ping", func(w http.ResponseWriter, r *http.Request) {
		contact(r.Context(), r.URL.Query().Get("device"))
		seen(r.URL.Query().Get("device"))
		fmt.Fprint(w, `{"ok":true}`)
	})
	log.Printf("server on %s mutant=%q fp=%q:%d", addr, mutant, fpName, fpAt)
	log.Fatal(http.ListenAndServe(addr, mux))
}
