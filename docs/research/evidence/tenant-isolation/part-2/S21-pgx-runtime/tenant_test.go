package s21

// Evidence for tenant-isolation part 2 (Go track). Runs against postgres:18.6 as role app_rt
// (LOGIN, NOSUPERUSER, NOBYPASSRLS, not the table owner) with ENABLE + FORCE RLS.
// Direct tests use a pool of size 1 so the "next request" always gets the same backend.
// Pooler tests go through PgBouncer in transaction mode with default_pool_size=1.

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	tenantA = "11111111-1111-4111-8111-111111111111"
	tenantB = "22222222-2222-4222-8222-222222222222"
)

func dsn(t *testing.T, env string) string {
	v := os.Getenv(env)
	if v == "" {
		t.Skipf("%s not set", env)
	}
	return fmt.Sprintf("postgres://app_rt:%s@%s/postgres?sslmode=disable", os.Getenv("APP_RT_PASSWORD"), v) // password removed from the file after the run (2026-10-17); set APP_RT_PASSWORD to the value in setup.sql
}

func newPool(t *testing.T, env string, mutate func(*pgxpool.Config)) *pgxpool.Pool {
	cfg, err := pgxpool.ParseConfig(dsn(t, env))
	if err != nil {
		t.Fatal(err)
	}
	cfg.MaxConns = 1
	if mutate != nil {
		mutate(cfg)
	}
	p, err := pgxpool.NewWithConfig(context.Background(), cfg)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	return p
}

// WithTenant is the only entry point a use case may use: one transaction, context set first, local to the tx.
func WithTenant(ctx context.Context, p *pgxpool.Pool, tenant string, fn func(pgx.Tx) error) error {
	return pgx.BeginTxFunc(ctx, p, pgx.TxOptions{}, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true)", tenant); err != nil {
			return err
		}
		return fn(tx)
	})
}

type q interface {
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

func state(ctx context.Context, c q) (pid int, n int, guc string, err error) {
	err = c.QueryRow(ctx, `select pg_backend_pid(), (select count(*) from app.orders), coalesce(current_setting('app.tenant_id', true),'<NULL>')`).Scan(&pid, &n, &guc)
	return
}

func pgCode(err error) string {
	var pe *pgconn.PgError
	if errors.As(err, &pe) {
		return pe.Code + " " + pe.Message
	}
	return fmt.Sprint(err)
}

func TestGo_ForgottenContextFailsClosed(t *testing.T) {
	ctx := context.Background()
	p := newPool(t, "PG_DIRECT", nil)
	// use case forgets WithTenant: plain pool query, and a tx without set_config
	pid, n, guc, err := state(ctx, p)
	t.Logf("no tx, no context: pid=%d rows_visible=%d guc=%q err=%v", pid, n, guc, err)
	if err != nil || n != 0 {
		t.Fatalf("want 0 rows, got n=%d err=%v", n, err)
	}
	err = pgx.BeginTxFunc(ctx, p, pgx.TxOptions{}, func(tx pgx.Tx) error {
		_, n, guc, err := state(ctx, tx)
		t.Logf("tx without set_config: rows_visible=%d guc=%q", n, guc)
		if n != 0 {
			t.Fatalf("want 0 got %d", n)
		}
		_, err = tx.Exec(ctx, `insert into app.orders(tenant_id, note) values ($1,'forgot')`, tenantA)
		t.Logf("INSERT without context -> %s", pgCode(err))
		return err // the tx aborts; BeginTxFunc rolls back
	})
	if err == nil || !strings.Contains(pgCode(err), "42501") {
		t.Fatalf("insert without context must be rejected with 42501, got %v", err)
	}
}

func TestGo_LocalContextDoesNotSurviveCommitOrRollback(t *testing.T) {
	ctx := context.Background()
	p := newPool(t, "PG_DIRECT", nil)
	var pidIn int
	err := WithTenant(ctx, p, tenantA, func(tx pgx.Tx) error {
		pid, n, guc, err := state(ctx, tx)
		pidIn = pid
		t.Logf("inside tx A: pid=%d rows=%d guc=%q", pid, n, guc)
		if n != 3 {
			t.Fatalf("tenant A should see 3 rows, got %d", n)
		}
		return err
	})
	if err != nil {
		t.Fatal(err)
	}
	pid, n, guc, _ := state(ctx, p)
	t.Logf("after commit, next borrower: pid=%d (same backend: %v) rows=%d guc=%q", pid, pid == pidIn, n, guc)
	if pid != pidIn || n != 0 || guc != "" {
		t.Fatalf("expected same backend, 0 rows, empty guc; got %d %d %q", pid, n, guc)
	}
	// rollback via returned error
	sentinel := errors.New("boom")
	err = WithTenant(ctx, p, tenantB, func(tx pgx.Tx) error { return sentinel })
	pid, n, guc, _ = state(ctx, p)
	t.Logf("after fn error (%v): pid=%d rows=%d guc=%q", err, pid, n, guc)
	if !errors.Is(err, sentinel) || pid != pidIn || n != 0 || guc != "" {
		t.Fatalf("unexpected after error path")
	}
	// rollback via panic
	func() {
		defer func() { t.Logf("recovered panic: %v", recover()) }()
		_ = WithTenant(ctx, p, tenantB, func(tx pgx.Tx) error { panic("use case panicked") })
	}()
	pid, n, guc, _ = state(ctx, p)
	t.Logf("after panic: pid=%d rows=%d guc=%q stat idle=%d total=%d", pid, n, guc, p.Stat().IdleConns(), p.Stat().TotalConns())
	if pid != pidIn || n != 0 || guc != "" {
		t.Fatalf("unexpected after panic path")
	}
}

func TestGo_CancelledContextAtRollbackDestroysConn(t *testing.T) {
	// B21: a rollback that fails (ctx already cancelled) kills the connection instead of returning it.
	p := newPool(t, "PG_DIRECT", nil)
	ctx, cancel := context.WithCancel(context.Background())
	var pidIn int
	err := WithTenant(ctx, p, tenantA, func(tx pgx.Tx) error {
		pidIn, _, _, _ = state(ctx, tx)
		cancel() // request cancelled while the tx is open
		return errors.New("work failed")
	})
	t.Logf("WithTenant returned: %v", err)
	pid, n, guc, e := state(context.Background(), p)
	t.Logf("next borrower: pid=%d (same as before: %v) rows=%d guc=%q err=%v", pid, pid == pidIn, n, guc, e)
	if pid == pidIn || n != 0 || (guc != "" && guc != "<NULL>") {
		t.Fatalf("expected a destroyed connection (new pid) and no tenant context")
	}
}

func TestGo_LeakedOpenTxIsDestroyedOnRelease(t *testing.T) {
	ctx := context.Background()
	p := newPool(t, "PG_DIRECT", nil)
	c, err := p.Acquire(ctx)
	if err != nil {
		t.Fatal(err)
	}
	pidIn := c.Conn().PgConn().PID()
	if _, err = c.Exec(ctx, "begin"); err != nil {
		t.Fatal(err)
	}
	if _, err = c.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true)", tenantA); err != nil {
		t.Fatal(err)
	}
	c.Release() // a bug: returned with an open transaction
	pid, n, guc, e := state(ctx, p)
	t.Logf("leaked-tx conn pid=%d; next borrower pid=%d (different: %v) rows=%d guc=%q err=%v", pidIn, int(pid), int(pid) != int(pidIn), n, guc, e)
	if int(pid) == int(pidIn) || n != 0 || (guc != "" && guc != "<NULL>") {
		t.Fatalf("a connection returned inside a transaction must be destroyed, not reused")
	}
}

func TestGo_SessionLevelSetConfigLeaks_NegativeControl(t *testing.T) {
	ctx := context.Background()
	p := newPool(t, "PG_DIRECT", nil)
	if _, err := p.Exec(ctx, "SELECT set_config('app.tenant_id', $1, false)", tenantA); err != nil { // is_local = false: the anti-pattern
		t.Fatal(err)
	}
	pid, n, guc, _ := state(ctx, p)
	t.Logf("NEGATIVE CONTROL (is_local=false): next borrower pid=%d rows=%d guc=%q -> tenant A rows are visible to whoever borrows next", pid, n, guc)
	if n != 3 {
		t.Fatalf("expected the leak (3 rows) in the negative control, got %d", n)
	}
}

func TestGo_PrepareConnGuardCatchesLeakedSessionValue(t *testing.T) {
	ctx := context.Background()
	destroyed := 0
	p := newPool(t, "PG_DIRECT", func(c *pgxpool.Config) {
		c.PrepareConn = func(ctx context.Context, conn *pgx.Conn) (bool, error) {
			var guc string
			if err := conn.QueryRow(ctx, `select coalesce(current_setting('app.tenant_id', true),'')`).Scan(&guc); err != nil {
				return false, nil
			}
			if guc != "" || conn.PgConn().TxStatus() != 'I' {
				destroyed++
				return false, nil
			}
			return true, nil
		}
	})
	_, _ = p.Exec(ctx, "SELECT set_config('app.tenant_id', $1, false)", tenantA) // someone leaks a session-level value
	pid, n, guc, e := state(ctx, p)
	t.Logf("with PrepareConn guard: connections destroyed=%d next borrower pid=%d rows=%d guc=%q err=%v", destroyed, pid, n, guc, e)
	if destroyed != 1 || n != 0 {
		t.Fatalf("guard should destroy the dirty connection once; destroyed=%d rows=%d", destroyed, n)
	}
}

func TestGo_SecondSetConfigSwitchesTenant(t *testing.T) {
	ctx := context.Background()
	p := newPool(t, "PG_DIRECT", nil)
	_ = WithTenant(ctx, p, tenantA, func(tx pgx.Tx) error {
		_, n1, _, _ := state(ctx, tx)
		_, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true)", tenantB)
		_, n2, _, _ := state(ctx, tx)
		t.Logf("same tx: first context A rows=%d; after second set_config(B) err=%v rows=%d", n1, err, n2)
		if n1 != 3 || n2 != 5 {
			t.Fatalf("unexpected %d %d", n1, n2)
		}
		return nil
	})
}

func TestGo_MalformedTenantRaises22P02(t *testing.T) {
	ctx := context.Background()
	p := newPool(t, "PG_DIRECT", nil)
	err := WithTenant(ctx, p, "not-a-uuid", func(tx pgx.Tx) error {
		_, n, _, err := state(ctx, tx)
		t.Logf("malformed context: rows=%d err=%s", n, pgCode(err))
		return err
	})
	if err == nil || !strings.Contains(pgCode(err), "22P02") {
		t.Fatalf("expected 22P02, got %v", err)
	}
}

func TestGo_StatementCacheStaysPerConnection(t *testing.T) {
	// the default cache_statement mode on a direct connection: many alternating tenants through one conn
	ctx := context.Background()
	p := newPool(t, "PG_DIRECT", nil)
	for i := 0; i < 50; i++ {
		tn, want := tenantA, 3
		if i%2 == 1 {
			tn, want = tenantB, 5
		}
		err := WithTenant(ctx, p, tn, func(tx pgx.Tx) error {
			_, n, _, err := state(ctx, tx)
			if n != want {
				t.Fatalf("iter %d want %d got %d", i, want, n)
			}
			return err
		})
		if err != nil {
			t.Fatal(err)
		}
	}
	t.Log("50 alternating tenant transactions OK on a direct connection, default exec mode")
}

// ---------- external transaction-mode pooler (PgBouncer) ----------

// two independent pgx pools = two PgBouncer clients that share one server connection (default_pool_size=1)
func twoClients(t *testing.T, env string, mode pgx.QueryExecMode) (*pgxpool.Pool, *pgxpool.Pool) {
	mut := func(c *pgxpool.Config) {
		c.MaxConns = 1
		if mode != 0 {
			c.ConnConfig.DefaultQueryExecMode = mode
		}
	}
	return newPool(t, env, mut), newPool(t, env, mut)
}

func TestPooler_LocalContextNoLeakAcrossClients(t *testing.T) {
	ctx := context.Background()
	c1, c2 := twoClients(t, "PG_BOUNCER200", 0)
	var pid1 int
	err := WithTenant(ctx, c1, tenantA, func(tx pgx.Tx) error {
		pid, n, _, err := state(ctx, tx)
		pid1 = pid
		t.Logf("client1 tx tenant A through PgBouncer: server pid=%d rows=%d", pid, n)
		return err
	})
	if err != nil {
		t.Fatalf("default exec mode (cache_statement) with max_prepared_statements=200: %v", err)
	}
	pid2, n, guc, err := state(ctx, c2)
	t.Logf("client2 (no tx context) next: server pid=%d (same server conn: %v) rows=%d guc=%q err=%v", pid2, pid2 == pid1, n, guc, err)
	if pid2 != pid1 || n != 0 || guc != "" {
		t.Fatalf("want same server conn, 0 rows, empty guc")
	}
}

func TestPooler_SessionLevelSetConfigLeaksAcrossClients_NegativeControl(t *testing.T) {
	ctx := context.Background()
	c1, c2 := twoClients(t, "PG_BOUNCER200", 0)
	if _, err := c1.Exec(ctx, "SELECT set_config('app.tenant_id', $1, false)", tenantA); err != nil {
		t.Fatal(err)
	}
	pid2, n, guc, _ := state(ctx, c2)
	t.Logf("NEGATIVE CONTROL: client2 sees server pid=%d rows=%d guc=%q (client1 never shared a session with client2 from its own point of view)", pid2, n, guc)
	if n != 3 {
		t.Fatalf("expected leak in negative control, rows=%d", n)
	}
	// clean the shared server connection so later tests start clean
	_, _ = c2.Exec(ctx, "RESET app.tenant_id")
}

func TestPooler_DefaultExecModeWithoutPreparedStatementSupport(t *testing.T) {
	ctx := context.Background()
	c1, c2 := twoClients(t, "PG_BOUNCER0", 0) // pgx default = cache_statement; max_prepared_statements = 0
	var firstErr error
	for i := 0; i < 20 && firstErr == nil; i++ {
		for _, c := range []*pgxpool.Pool{c1, c2} {
			firstErr = WithTenant(ctx, c, tenantA, func(tx pgx.Tx) error { _, _, _, err := state(ctx, tx); return err })
			if firstErr != nil {
				break
			}
		}
	}
	t.Logf("default mode, PgBouncer max_prepared_statements=0, alternating clients: first error = %v", firstErr)
	if firstErr == nil {
		t.Log("NO ERROR in 20 rounds (not a failure of the test; recorded as observed)")
	}
}

func TestPooler_ExecModeExecWorksWithoutPreparedStatementSupport(t *testing.T) {
	ctx := context.Background()
	c1, c2 := twoClients(t, "PG_BOUNCER0", pgx.QueryExecModeExec)
	for i := 0; i < 20; i++ {
		for _, c := range []*pgxpool.Pool{c1, c2} {
			tn, want := tenantA, 3
			if i%2 == 1 {
				tn, want = tenantB, 5
			}
			err := WithTenant(ctx, c, tn, func(tx pgx.Tx) error {
				_, n, _, err := state(ctx, tx)
				if err == nil && n != want {
					t.Fatalf("want %d got %d", want, n)
				}
				return err
			})
			if err != nil {
				t.Fatalf("QueryExecModeExec through PgBouncer (max_prepared_statements=0): %v", err)
			}
		}
	}
	t.Log("QueryExecModeExec: 40 alternating-tenant transactions across two clients OK with max_prepared_statements=0")
}

func TestPooler_DescribeExecIsUnsafe(t *testing.T) {
	// pgx doc.go says not to use QueryExecModeDescribeExec with transaction pooling; record what happens here (one server conn).
	ctx := context.Background()
	c1, c2 := twoClients(t, "PG_BOUNCER200", pgx.QueryExecModeDescribeExec)
	var errs int
	for i := 0; i < 30; i++ {
		for _, c := range []*pgxpool.Pool{c1, c2} {
			if err := WithTenant(ctx, c, tenantA, func(tx pgx.Tx) error { _, _, _, err := state(ctx, tx); return err }); err != nil {
				errs++
			}
		}
	}
	t.Logf("DescribeExec through PgBouncer, 60 tx: errors=%d (doc says unsafe; zero errors here does not prove safety)", errs)
}

func TestAcquireTimeout_StarvationFailsFast(t *testing.T) {
	// a leaked (never-ended) tx holds the only connection; the next request fails by timeout, it does not borrow it.
	p := newPool(t, "PG_DIRECT", nil)
	tx, err := p.Begin(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	_, _ = tx.Exec(context.Background(), "SELECT set_config('app.tenant_id', $1, true)", tenantA)
	ctx, cancel := context.WithTimeout(context.Background(), 300*time.Millisecond)
	defer cancel()
	_, _, _, err = state(ctx, p)
	t.Logf("while a request holds the only conn open: next request err=%v", err)
	if err == nil {
		t.Fatal("expected acquire timeout")
	}
	_ = tx.Rollback(context.Background())
}
