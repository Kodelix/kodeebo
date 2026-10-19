package spike

// S20: ADR-0002 helper (Job and Support-like kinds) on pgx v5.11.0 against postgres:18.6.
// Checks: SECURITY DEFINER calls, transaction_timeout, streaming COPY TO STDOUT under RLS, outbox claim
// (FOR UPDATE SKIP LOCKED) one tenant per transaction, idempotent consumer, atomic write + enqueue.
// Throwaway spike code written for research note backend-track.part-2; not production code.

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"os"
	"regexp"
	"runtime"
	"runtime/debug"
	"sort"
	"sync"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	tA = "11111111-1111-4111-8111-111111111111"
	tB = "22222222-2222-4222-8222-222222222222"
	tC = "33333333-3333-4333-8333-333333333333"
)

var (
	ErrScopeAlreadySet = errors.New("scope already set")
	ErrInvalidScope    = errors.New("invalid scope")
	uuidRe             = regexp.MustCompile(`^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`)
	addr               = os.Getenv("PG_ADDR")
)

// Scope: only the fields the spike needs (Job = tenant only; TxTimeout models the Support kind).
type Scope struct {
	Tenant    string
	TxTimeout string
}

type ScopedTx struct {
	tx  pgx.Tx
	set bool
}

func (s *ScopedTx) setScope(ctx context.Context, sc Scope) error {
	if s.set {
		return ErrScopeAlreadySet
	}
	if !uuidRe.MatchString(sc.Tenant) {
		return ErrInvalidScope
	}
	s.set = true
	if sc.TxTimeout != "" {
		_, err := s.tx.Exec(ctx, "select set_config('app.tenant_id', $1, true), set_config('transaction_timeout', $2, true)", sc.Tenant, sc.TxTimeout)
		return err
	}
	_, err := s.tx.Exec(ctx, "select set_config('app.tenant_id', $1, true)", sc.Tenant)
	return err
}

func WithScope[T any](ctx context.Context, pool *pgxpool.Pool, sc Scope, fn func(*ScopedTx) (T, error)) (T, error) {
	var out T
	err := pgx.BeginTxFunc(ctx, pool, pgx.TxOptions{}, func(tx pgx.Tx) error {
		st := &ScopedTx{tx: tx}
		if err := st.setScope(ctx, sc); err != nil {
			return err
		}
		v, err := fn(st)
		out = v
		return err
	})
	return out, err
}

// Edited 2026-10-19 after the run, for the commit secret check: the throwaway role password
// moved from the URL literal to BT2_PG_PASSWORD (set by run.sh). No behaviour change;
// output.txt is from the run before this edit.
func mkPool(t testing.TB, role string) *pgxpool.Pool {
	t.Helper()
	cfg, err := pgxpool.ParseConfig(fmt.Sprintf("postgres://%s@%s/postgres?pool_max_conns=4", role, addr))
	if err != nil {
		t.Fatal(err)
	}
	cfg.ConnConfig.Password = os.Getenv("BT2_PG_PASSWORD")
	p, err := pgxpool.NewWithConfig(context.Background(), cfg)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	return p
}

func code(err error) string {
	if err == nil {
		return "<nil>"
	}
	var pe *pgconn.PgError
	if errors.As(err, &pe) {
		return pe.Code + " " + pe.Message + " (severity " + pe.Severity + ")"
	}
	return fmt.Sprint(err)
}

func count(ctx context.Context, st *ScopedTx, sql string, args ...any) (int, error) {
	var n int
	err := st.tx.QueryRow(ctx, sql, args...).Scan(&n)
	return n, err
}

func TestT0Versions(t *testing.T) {
	p := mkPool(t, "app_rt")
	var v string
	if err := p.QueryRow(context.Background(), "select version()").Scan(&v); err != nil {
		t.Fatal(err)
	}
	t.Logf("server: %s", v)
	t.Logf("go: %s", runtime.Version())
	if bi, ok := debug.ReadBuildInfo(); ok {
		for _, d := range bi.Deps {
			if d.Path == "github.com/jackc/pgx/v5" {
				t.Logf("pgx: %s %s", d.Path, d.Version)
			}
		}
	}
}

// T1: SECURITY DEFINER PL functions called through the pool and inside the scope helper.
func TestT1SecurityDefiner(t *testing.T) {
	ctx := context.Background()
	app, job := mkPool(t, "app_rt"), mkPool(t, "job_rt")

	var tid string
	err := app.QueryRow(ctx, "select tenant_id::text from auth.session_lookup($1)", "tok-a1").Scan(&tid)
	t.Logf("T1a lookup with no tenant context: tenant=%s err=%s (want %s)", tid, code(err), tA)

	var n int
	_ = app.QueryRow(ctx, "select count(*) from app.sessions").Scan(&n)
	t.Logf("T1b direct select on PL table, no context, as app_rt: %d rows (want 0)", n)

	c, err := WithScope(ctx, app, Scope{Tenant: tB}, func(st *ScopedTx) (int, error) { return count(ctx, st, "select count(*) from app.sessions") })
	t.Logf("T1c direct select on PL table inside scope B as app_rt: %d rows err=%s (want 1)", c, code(err))

	got, err := WithScope(ctx, app, Scope{Tenant: tA}, func(st *ScopedTx) (string, error) {
		var s string
		e := st.tx.QueryRow(ctx, "select tenant_id::text from auth.session_lookup($1)", "tok-b1").Scan(&s)
		return s, e
	})
	t.Logf("T1d lookup of another tenant's token inside scope A: %s err=%s (functions take a key, not the context; by design)", got, code(err))

	_, err = WithScope(ctx, job, Scope{Tenant: tA}, func(st *ScopedTx) (int, error) { return count(ctx, st, "select count(*) from app.sessions") })
	t.Logf("T1e job_rt direct select on PL table inside scope A: %s (want 42501 permission denied)", code(err))

	_, err = WithScope(ctx, app, Scope{Tenant: tA}, func(st *ScopedTx) (int, error) { return count(ctx, st, "select auth.closure_end_sessions()") })
	t.Logf("T1f app_rt calling the job-only function: %s (want 42501)", code(err))

	_, err = job.Exec(ctx, "select auth.closure_end_sessions()")
	t.Logf("T1g job_rt calling it with no tenant context: %s (want 42501 no tenant context)", code(err))

	del, err := WithScope(ctx, job, Scope{Tenant: tA}, func(st *ScopedTx) (int, error) { return count(ctx, st, "select auth.closure_end_sessions()") })
	t.Logf("T1h job_rt calling it inside scope A: deleted=%d err=%s (want 2; the function reads the caller's local setting)", del, code(err))

	left, err := WithScope(ctx, app, Scope{Tenant: tB}, func(st *ScopedTx) (int, error) { return count(ctx, st, "select count(*) from app.sessions") })
	t.Logf("T1i tenant B sessions after A's closure call: %d err=%s (want 1)", left, code(err))
}

// T2: the helper refuses a second scope and an unparseable tenant before any query.
func TestT2HelperRules(t *testing.T) {
	ctx := context.Background()
	job := mkPool(t, "job_rt")
	_, err := WithScope(ctx, job, Scope{Tenant: tA}, func(st *ScopedTx) (int, error) { return 0, st.setScope(ctx, Scope{Tenant: tB}) })
	t.Logf("T2a second scope in one transaction: %v (want ErrScopeAlreadySet: %v)", err, errors.Is(err, ErrScopeAlreadySet))
	_, err = WithScope(ctx, job, Scope{Tenant: "x' or '1'='1"}, func(st *ScopedTx) (int, error) { t.Error("fn must not run"); return 0, nil })
	t.Logf("T2b unparseable tenant: %v (want ErrInvalidScope: %v)", err, errors.Is(err, ErrInvalidScope))
	var s string
	_ = job.QueryRow(ctx, "select coalesce(current_setting('app.tenant_id', true), '<null>')").Scan(&s)
	t.Logf("T2c next borrower reads app.tenant_id = %q", s)
}

// T3: transaction_timeout set with set_config(..., true) by the helper (Support kind).
func TestT3TransactionTimeout(t *testing.T) {
	ctx := context.Background()
	job := mkPool(t, "job_rt")
	start := time.Now()
	_, err := WithScope(ctx, job, Scope{Tenant: tA, TxTimeout: "300ms"}, func(st *ScopedTx) (int, error) {
		_, e := st.tx.Exec(ctx, "select pg_sleep(2)")
		return 0, e
	})
	t.Logf("T3a transaction_timeout=300ms set first, then pg_sleep(2): elapsed=%v err=%s", time.Since(start).Round(time.Millisecond), code(err))

	start = time.Now()
	_, err = WithScope(ctx, job, Scope{Tenant: tA}, func(st *ScopedTx) (int, error) {
		if _, e := st.tx.Exec(ctx, "select pg_sleep(0.5)"); e != nil {
			return 0, e
		}
		// EXPERIMENT (bypasses the helper on purpose): set the timeout 0.5 s into a running transaction.
		if _, e := st.tx.Exec(ctx, "select set_config('transaction_timeout', '300ms', true)"); e != nil {
			return 0, e
		}
		_, e := st.tx.Exec(ctx, "select pg_sleep(0.1)")
		return 0, e
	})
	t.Logf("T3b timeout 300ms set 0.5 s into the transaction, then a 0.1 s statement: elapsed=%v err=%s", time.Since(start).Round(time.Millisecond), code(err))

	var s string
	err = job.QueryRow(ctx, "select current_setting('transaction_timeout')").Scan(&s)
	t.Logf("T3c next borrower reads transaction_timeout = %q err=%s", s, code(err))
}

// ---- T4: streaming COPY TO STDOUT under RLS ----

type sink struct {
	n, lines int64
	first    []byte
}

func (s *sink) Write(p []byte) (int, error) {
	s.n += int64(len(p))
	s.lines += int64(bytes.Count(p, []byte{'\n'}))
	if len(s.first) < 80 {
		k := 80 - len(s.first)
		if k > len(p) {
			k = len(p)
		}
		s.first = append(s.first, p[:k]...)
	}
	return len(p), nil
}

type limitSink struct {
	sink
	limit  int64
	cancel context.CancelFunc // nil: return an error instead
}

func (l *limitSink) Write(p []byte) (int, error) {
	l.sink.Write(p)
	if l.n >= l.limit {
		if l.cancel != nil {
			l.cancel()
			return len(p), nil
		}
		return 0, errors.New("client went away")
	}
	return len(p), nil
}

func peakHeap(stop <-chan struct{}, out *uint64, wg *sync.WaitGroup) {
	defer wg.Done()
	var ms runtime.MemStats
	tk := time.NewTicker(5 * time.Millisecond)
	defer tk.Stop()
	for {
		select {
		case <-stop:
			return
		case <-tk.C:
			runtime.ReadMemStats(&ms)
			if ms.HeapAlloc > *out {
				*out = ms.HeapAlloc
			}
		}
	}
}

const exportSQL = "COPY (SELECT id, note FROM app.orders ORDER BY id) TO STDOUT WITH (FORMAT csv, HEADER true)"

func TestT4CopyExport(t *testing.T) {
	ctx := context.Background()
	job := mkPool(t, "job_rt")

	runtime.GC()
	var base runtime.MemStats
	runtime.ReadMemStats(&base)
	stop := make(chan struct{})
	var peak uint64
	var wg sync.WaitGroup
	wg.Add(1)
	go peakHeap(stop, &peak, &wg)
	sk := &sink{}
	start := time.Now()
	tag, err := WithScope(ctx, job, Scope{Tenant: tA}, func(st *ScopedTx) (pgconn.CommandTag, error) {
		return st.tx.Conn().PgConn().CopyTo(ctx, sk, exportSQL)
	})
	el := time.Since(start)
	close(stop)
	wg.Wait()
	t.Logf("T4a scope A, no WHERE clause: tag=%q err=%s lines=%d (want 1000001 = header + A's 1,000,000 rows, not B's 1,000) bytes=%d elapsed=%v", tag.String(), code(err), sk.lines, sk.n, el.Round(time.Millisecond))
	t.Logf("T4a first bytes: %q", string(sk.first))
	t.Logf("T4a heap before=%d B, peak during export=%d B (output was %d B)", base.HeapAlloc, peak, sk.n)

	c, err := job.Acquire(ctx)
	if err != nil {
		t.Fatal(err)
	}
	sk2 := &sink{}
	tag2, err := c.Conn().PgConn().CopyTo(ctx, sk2, exportSQL)
	c.Release()
	t.Logf("T4b same COPY with no scope set (forgotten context): tag=%q err=%s lines=%d (want 1 = header only)", tag2.String(), code(err), sk2.lines)

	// cancel mid-stream via context
	cctx, cancel := context.WithCancel(ctx)
	ls := &limitSink{limit: 5 << 20, cancel: cancel}
	start = time.Now()
	_, err = WithScope(cctx, job, Scope{Tenant: tA}, func(st *ScopedTx) (pgconn.CommandTag, error) {
		return st.tx.Conn().PgConn().CopyTo(cctx, ls, exportSQL)
	})
	t.Logf("T4c context cancelled after ~5 MiB: elapsed=%v bytes=%d err=%s", time.Since(start).Round(time.Millisecond), ls.n, code(err))
	var one int
	err2 := job.QueryRow(ctx, "select 1").Scan(&one)
	t.Logf("T4c next query on the pool: %d err=%s", one, code(err2))

	// writer returns an error mid-stream (HTTP client disconnected)
	ws := &limitSink{limit: 1 << 20}
	start = time.Now()
	_, err = WithScope(ctx, job, Scope{Tenant: tA}, func(st *ScopedTx) (pgconn.CommandTag, error) {
		return st.tx.Conn().PgConn().CopyTo(ctx, ws, exportSQL)
	})
	t.Logf("T4d writer errors after ~1 MiB: elapsed=%v bytes seen by writer=%d err=%s", time.Since(start).Round(time.Millisecond), ws.n, code(err))
	err2 = job.QueryRow(ctx, "select 1").Scan(&one)
	t.Logf("T4d next query on the pool: %d err=%s", one, code(err2))
}

// ---- T5: outbox claim, one tenant per transaction ----

func claim(ctx context.Context, st *ScopedTx, n int) ([]int64, error) {
	rows, err := st.tx.Query(ctx, "select id from app.outbox where processed_at is null order by id limit $1 for update skip locked", n)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var ids []int64
	for rows.Next() {
		var id int64
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}

func markDone(ctx context.Context, st *ScopedTx, ids []int64) error {
	_, err := st.tx.Exec(ctx, "update app.outbox set processed_at = now(), attempts = attempts + 1 where id = any($1)", ids)
	return err
}

func TestT5aGlobalClaim(t *testing.T) {
	ctx := context.Background()
	job := mkPool(t, "job_rt")
	var n int
	err := pgx.BeginTxFunc(ctx, job, pgx.TxOptions{}, func(tx pgx.Tx) error {
		rows, e := tx.Query(ctx, "select id from app.outbox where processed_at is null for update skip locked limit 5")
		if e != nil {
			return e
		}
		for rows.Next() {
			n++
		}
		rows.Close()
		return rows.Err()
	})
	t.Logf("T5a job_rt claim with NO tenant context: %d rows err=%s (want 0: a global poll sees nothing)", n, code(err))
}

func TestT5bConcurrentClaim(t *testing.T) {
	ctx := context.Background()
	job := mkPool(t, "job_rt")
	claimed := make(chan []int64, 1)
	release := make(chan struct{})
	var wg sync.WaitGroup
	var ids1, ids2 []int64
	wg.Add(1)
	go func() {
		defer wg.Done()
		_, err := WithScope(ctx, job, Scope{Tenant: tC}, func(st *ScopedTx) (int, error) {
			ids, e := claim(ctx, st, 6)
			if e != nil {
				return 0, e
			}
			ids1 = ids
			claimed <- ids
			<-release
			return 0, markDone(ctx, st, ids)
		})
		if err != nil {
			t.Errorf("worker 1: %v", err)
		}
	}()
	<-claimed
	_, err := WithScope(ctx, job, Scope{Tenant: tC}, func(st *ScopedTx) (int, error) {
		ids, e := claim(ctx, st, 6)
		if e != nil {
			return 0, e
		}
		ids2 = ids
		return 0, markDone(ctx, st, ids)
	})
	close(release)
	wg.Wait()
	seen := map[int64]bool{}
	overlap := 0
	for _, id := range ids1 {
		seen[id] = true
	}
	for _, id := range ids2 {
		if seen[id] {
			overlap++
		}
	}
	t.Logf("T5b two workers on tenant C (10 rows, worker 1 holds its 6 locks): worker1=%d worker2=%d overlap=%d err=%s (want 6, 4, 0)", len(ids1), len(ids2), overlap, code(err))
}

func TestT5cTenantSweep(t *testing.T) {
	ctx := context.Background()
	job, plat := mkPool(t, "job_rt"), mkPool(t, "platform_rt")
	rows, err := plat.Query(ctx, "select tenant_id::text from app.tenant_status order by 1")
	if err != nil {
		t.Fatal(err)
	}
	var tenants []string
	for rows.Next() {
		var s string
		_ = rows.Scan(&s)
		tenants = append(tenants, s)
	}
	rows.Close()
	t.Logf("T5c platform_rt lists %d tenants (ids only)", len(tenants))
	for sweepNo := 1; sweepNo <= 4; sweepNo++ {
		var durs []time.Duration
		processed := 0
		sweepStart := time.Now()
		for _, tn := range tenants {
			s := time.Now()
			n, err := WithScope(ctx, job, Scope{Tenant: tn}, func(st *ScopedTx) (int, error) {
				ids, e := claim(ctx, st, 5)
				if e != nil || len(ids) == 0 {
					return 0, e
				}
				return len(ids), markDone(ctx, st, ids)
			})
			if err != nil {
				t.Fatalf("sweep %d tenant %s: %v", sweepNo, tn, err)
			}
			processed += n
			durs = append(durs, time.Since(s))
		}
		total := time.Since(sweepStart)
		sort.Slice(durs, func(i, j int) bool { return durs[i] < durs[j] })
		t.Logf("T5c sweep %d: processed=%d total=%v per-tenant tx p50=%v p95=%v max=%v", sweepNo, processed, total.Round(time.Millisecond),
			durs[len(durs)/2].Round(10*time.Microsecond), durs[len(durs)*95/100].Round(10*time.Microsecond), durs[len(durs)-1].Round(10*time.Microsecond))
	}
}

func TestT5dIdempotentConsumer(t *testing.T) {
	ctx := context.Background()
	job := mkPool(t, "job_rt")
	ins := func(st *ScopedTx, id string) (int64, error) {
		tag, e := st.tx.Exec(ctx, "insert into app.inbox_dedup (tenant_id, message_id) values (nullif(current_setting('app.tenant_id', true), '')::uuid, $1) on conflict do nothing", id)
		return tag.RowsAffected(), e
	}
	boom := errors.New("handler failed after the effect")
	_, err := WithScope(ctx, job, Scope{Tenant: tA}, func(st *ScopedTx) (int64, error) {
		n, e := ins(st, "msg-1")
		if e != nil {
			return 0, e
		}
		t.Logf("T5d attempt 1 inserted %d row, then fails", n)
		return n, boom
	})
	t.Logf("T5d attempt 1 error: %v", err)
	for i := 2; i <= 3; i++ {
		n, err := WithScope(ctx, job, Scope{Tenant: tA}, func(st *ScopedTx) (int64, error) { return ins(st, "msg-1") })
		t.Logf("T5d attempt %d: effect rows=%d err=%s (want 1 then 0: the dedup row rolled back with the failed attempt, then blocks the replay)", i, n, code(err))
	}
}

func TestT5eAtomicWriteAndEnqueue(t *testing.T) {
	ctx := context.Background()
	app := mkPool(t, "app_rt")
	write := func(st *ScopedTx, note string) error {
		if _, e := st.tx.Exec(ctx, "insert into app.orders (tenant_id, note) values (nullif(current_setting('app.tenant_id', true), '')::uuid, $1)", note); e != nil {
			return e
		}
		_, e := st.tx.Exec(ctx, "insert into app.outbox (tenant_id, kind, ref) values (nullif(current_setting('app.tenant_id', true), '')::uuid, 'order.created', gen_random_uuid())")
		return e
	}
	_, err := WithScope(ctx, app, Scope{Tenant: tA}, func(st *ScopedTx) (int, error) { return 0, errors.Join(write(st, "atomic-rolled-back"), errors.New("force rollback")) })
	_, err2 := WithScope(ctx, app, Scope{Tenant: tA}, func(st *ScopedTx) (int, error) { return 0, write(st, "atomic-committed") })
	var o1, o2, ob int
	_, _ = WithScope(ctx, app, Scope{Tenant: tA}, func(st *ScopedTx) (int, error) {
		o1, _ = count(ctx, st, "select count(*) from app.orders where note = 'atomic-rolled-back'")
		o2, _ = count(ctx, st, "select count(*) from app.orders where note = 'atomic-committed'")
		ob, _ = count(ctx, st, "select count(*) from app.outbox where kind = 'order.created'")
		return 0, nil
	})
	t.Logf("T5e rolled-back tx err=%v; committed tx err=%v; orders rolled-back=%d committed=%d; outbox rows kind order.created=%d (want 0, 1, 1)", err != nil, err2, o1, o2, ob)
}
