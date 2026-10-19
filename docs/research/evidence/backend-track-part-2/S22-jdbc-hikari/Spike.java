// S22: JDBC layer of the Ktor track (HikariCP 7.1.0 + pgjdbc 42.7.14) against postgres:18.6.
// Same checks as S20 (Go) at the JDBC level: scope helper, SECURITY DEFINER calls, transaction_timeout,
// streaming CopyManager.copyOut under RLS, outbox claim per tenant. NOT Exposed: the Exposed -> JDBC unwrap is PENDING - S23.
// Throwaway spike code written for research note backend-track.part-2; not production code.
// Run: java -Xmx32m -cp <jars> Spike.java <host:port>

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.postgresql.PGConnection;
import org.postgresql.copy.CopyManager;

import javax.sql.DataSource;
import java.io.IOException;
import java.io.OutputStream;
import java.sql.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.regex.Pattern;

public class Spike {
    static final String A = "11111111-1111-4111-8111-111111111111";
    static final String B = "22222222-2222-4222-8222-222222222222";
    static final String C = "33333333-3333-4333-8333-333333333333";
    static final Pattern UUID_RE = Pattern.compile("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$");
    static String addr;

    static void log(String s) { System.out.println(s); }

    static HikariDataSource pool(String role) {
        HikariConfig c = new HikariConfig();
        c.setJdbcUrl("jdbc:postgresql://" + addr + "/postgres");
        c.setUsername(role);
        c.setPassword("bt2_throwaway");
        c.setMaximumPoolSize(4);
        c.setPoolName("bt2-" + role);
        return new HikariDataSource(c);
    }

    interface Work<T> { T run(Connection c) throws Exception; }

    /** The ADR-0002 helper at JDBC level: one transaction, scope set once and first with is_local = true. */
    static <T> T withScope(DataSource ds, String tenant, String txTimeout, Work<T> w) throws Exception {
        if (!UUID_RE.matcher(tenant).matches()) throw new IllegalArgumentException("invalid scope");
        try (Connection c = ds.getConnection()) {
            c.setAutoCommit(false);
            try {
                String sql = txTimeout == null
                        ? "select set_config('app.tenant_id', ?, true)"
                        : "select set_config('app.tenant_id', ?, true), set_config('transaction_timeout', ?, true)";
                try (PreparedStatement ps = c.prepareStatement(sql)) {
                    ps.setString(1, tenant);
                    if (txTimeout != null) ps.setString(2, txTimeout);
                    ps.execute();
                }
                T r = w.run(c);
                c.commit();
                return r;
            } catch (Throwable e) {
                try { c.rollback(); } catch (Exception ignore) { }
                throw e;
            }
        }
    }

    static String err(Throwable e) {
        String st = e instanceof SQLException s ? " state=" + s.getSQLState() : "";
        return e.getClass().getSimpleName() + st + " msg=" + e.getMessage();
    }

    static long scalarLong(Connection c, String sql, Object... args) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < args.length; i++) ps.setObject(i + 1, args[i]);
            try (ResultSet rs = ps.executeQuery()) { rs.next(); return rs.getLong(1); }
        }
    }

    static String scalarStr(Connection c, String sql, Object... args) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < args.length; i++) ps.setObject(i + 1, args[i]);
            try (ResultSet rs = ps.executeQuery()) { rs.next(); return rs.getString(1); }
        }
    }

    static class Sink extends OutputStream {
        long n, lines, limit = Long.MAX_VALUE;
        @Override public void write(int b) throws IOException { write(new byte[]{(byte) b}, 0, 1); }
        @Override public void write(byte[] b, int off, int len) throws IOException {
            n += len;
            for (int i = off; i < off + len; i++) if (b[i] == '\n') lines++;
            if (n >= limit) throw new IOException("client went away");
        }
    }

    static List<Long> claim(Connection c, int n) throws SQLException {
        List<Long> ids = new ArrayList<>();
        try (PreparedStatement ps = c.prepareStatement("select id from app.outbox where processed_at is null order by id limit ? for update skip locked")) {
            ps.setInt(1, n);
            try (ResultSet rs = ps.executeQuery()) { while (rs.next()) ids.add(rs.getLong(1)); }
        }
        return ids;
    }

    static void markDone(Connection c, List<Long> ids) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("update app.outbox set processed_at = now(), attempts = attempts + 1 where id = any(?)")) {
            ps.setArray(1, c.createArrayOf("bigint", ids.toArray()));
            ps.executeUpdate();
        }
    }

    public static void main(String[] args) throws Exception {
        addr = args[0];
        log("### java " + System.getProperty("java.version") + " maxMemory=" + Runtime.getRuntime().maxMemory() / (1 << 20) + " MiB");
        HikariDataSource app = pool("app_rt"), job = pool("job_rt"), plat = pool("platform_rt");
        try (Connection c = job.getConnection()) {
            log("J0 server: " + scalarStr(c, "select version()"));
            log("J0 driver: " + c.getMetaData().getDriverName() + " " + c.getMetaData().getDriverVersion());
        }

        // J1: SECURITY DEFINER lookups
        try (Connection c = app.getConnection()) {
            log("J1a lookup with no tenant context (autocommit): tenant=" + scalarStr(c, "select tenant_id::text from auth.session_lookup(?)", "tok-a1") + " (want " + A + ")");
            log("J1b direct select on PL table, no context: " + scalarLong(c, "select count(*) from app.sessions") + " rows (want 0)");
        }
        log("J1c job_rt calls closure function with no context: " + tryRun(() -> { try (Connection c = job.getConnection()) { return scalarStr(c, "select auth.closure_end_sessions()::text"); } }));
        log("J1d app_rt calls the job-only function in scope A: " + tryRun(() -> withScope(app, A, null, c -> scalarStr(c, "select auth.closure_end_sessions()::text"))));
        log("J1e job_rt calls it in scope A: deleted=" + tryRun(() -> withScope(job, A, null, c -> scalarStr(c, "select auth.closure_end_sessions()::text"))) + " (want 2)");
        log("J1f tenant B sessions after: " + tryRun(() -> withScope(app, B, null, c -> scalarStr(c, "select count(*)::text from app.sessions"))) + " (want 1)");

        // J2: helper rules
        log("J2a unparseable tenant: " + tryRun(() -> withScope(job, "x' or '1'='1", null, c -> "fn ran")));

        // J3: transaction_timeout
        long t0 = System.nanoTime();
        String r = tryRun(() -> withScope(job, A, "300ms", c -> { try (Statement s = c.createStatement()) { s.execute("select pg_sleep(2)"); } return "no error"; }));
        log("J3a transaction_timeout=300ms set first, then pg_sleep(2): elapsed=" + (System.nanoTime() - t0) / 1_000_000 + " ms result: " + r);
        for (int i = 1; i <= 3; i++) {
            final int k = i;
            log("J3b next borrower #" + k + " transaction_timeout: " + tryRun(() -> { try (Connection c = job.getConnection()) { return scalarStr(c, "select current_setting('transaction_timeout')"); } }));
        }
        t0 = System.nanoTime();
        r = tryRun(() -> withScope(job, A, null, c -> {
            try (Statement s = c.createStatement()) {
                s.execute("select pg_sleep(0.5)");
                s.execute("select set_config('transaction_timeout', '300ms', true)");
                s.execute("select pg_sleep(0.1)");
            }
            return "no error";
        }));
        log("J3c timeout 300ms set 0.5 s into a running transaction, then a 0.1 s statement: elapsed=" + (System.nanoTime() - t0) / 1_000_000 + " ms result: " + r);

        // J4: streaming COPY via CopyManager obtained by unwrapping the pooled connection
        final String sql = "COPY (SELECT id, note FROM app.orders ORDER BY id) TO STDOUT WITH (FORMAT csv, HEADER true)";
        System.gc();
        final long base = Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory();
        final long[] peak = {0};
        Thread sampler = new Thread(() -> {
            while (!Thread.currentThread().isInterrupted()) {
                long used = Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory();
                if (used > peak[0]) peak[0] = used;
                try { Thread.sleep(5); } catch (InterruptedException e) { return; }
            }
        });
        sampler.setDaemon(true);
        sampler.start();
        Sink sk = new Sink();
        t0 = System.nanoTime();
        r = tryRun(() -> withScope(job, A, null, c -> {
            CopyManager cm = c.unwrap(PGConnection.class).getCopyAPI();
            return "rows=" + cm.copyOut(sql, sk);
        }));
        long el = (System.nanoTime() - t0) / 1_000_000;
        sampler.interrupt();
        log("J4a scope A, no WHERE clause (unwrap PGConnection.getCopyAPI on the Hikari proxy): " + r + " lines=" + sk.lines + " (want 1000001) bytes=" + sk.n + " elapsed=" + el + " ms");
        log("J4a heap used before=" + base + " B, peak while exporting=" + peak[0] + " B (JVM -Xmx is small; GC noise included)");
        Sink sk2 = new Sink();
        r = tryRun(() -> { try (Connection c = job.getConnection()) { return "rows=" + c.unwrap(PGConnection.class).getCopyAPI().copyOut(sql, sk2); } });
        log("J4b same COPY with no scope: " + r + " lines=" + sk2.lines + " (want 1 = header only)");
        Sink sk3 = new Sink();
        sk3.limit = 1 << 20;
        t0 = System.nanoTime();
        r = tryRun(() -> withScope(job, A, null, c -> "rows=" + c.unwrap(PGConnection.class).getCopyAPI().copyOut(sql, sk3)));
        log("J4c writer throws after ~1 MiB: elapsed=" + (System.nanoTime() - t0) / 1_000_000 + " ms bytes seen=" + sk3.n + " result: " + r);
        log("J4c next query on the pool: " + tryRun(() -> { try (Connection c = job.getConnection()) { return scalarStr(c, "select 1"); } }));

        // J5: outbox
        log("J5a job_rt claim with no tenant context: " + tryRun(() -> { try (Connection c = job.getConnection()) { c.setAutoCommit(false); try { return String.valueOf(claim(c, 5).size()); } finally { c.rollback(); } } }) + " rows (want 0)");
        CompletableFuture<List<Long>> claimed = new CompletableFuture<>();
        CountDownLatch release = new CountDownLatch(1);
        ExecutorService ex = Executors.newSingleThreadExecutor();
        Future<?> w1 = ex.submit(() -> withScope(job, C, null, c -> { List<Long> ids = claim(c, 6); claimed.complete(ids); release.await(); markDone(c, ids); return ids; }));
        List<Long> ids1 = claimed.get(10, TimeUnit.SECONDS);
        List<Long> ids2 = withScope(job, C, null, c -> { List<Long> ids = claim(c, 6); markDone(c, ids); return ids; });
        release.countDown();
        w1.get(10, TimeUnit.SECONDS);
        ex.shutdown();
        Set<Long> ov = new HashSet<>(ids1);
        ov.retainAll(ids2);
        log("J5b two workers on tenant C: worker1=" + ids1.size() + " worker2=" + ids2.size() + " overlap=" + ov.size() + " (want 6, 4, 0)");
        List<String> tenants = new ArrayList<>();
        try (Connection c = plat.getConnection(); Statement s = c.createStatement(); ResultSet rs = s.executeQuery("select tenant_id::text from app.tenant_status order by 1")) {
            while (rs.next()) tenants.add(rs.getString(1));
        }
        log("J5c platform_rt lists " + tenants.size() + " tenants");
        for (int sweep = 1; sweep <= 4; sweep++) {
            long[] durs = new long[tenants.size()];
            int processed = 0;
            long s0 = System.nanoTime();
            for (int i = 0; i < tenants.size(); i++) {
                long a = System.nanoTime();
                processed += withScope(job, tenants.get(i), null, c -> { List<Long> ids = claim(c, 5); if (!ids.isEmpty()) markDone(c, ids); return ids.size(); });
                durs[i] = System.nanoTime() - a;
            }
            long total = (System.nanoTime() - s0) / 1_000_000;
            Arrays.sort(durs);
            log("J5c sweep " + sweep + ": processed=" + processed + " total=" + total + " ms per-tenant tx p50=" + durs[durs.length / 2] / 1000 + " us p95=" + durs[durs.length * 95 / 100] / 1000 + " us max=" + durs[durs.length - 1] / 1000 + " us");
        }
        app.close(); job.close(); plat.close();
        log("### done");
    }

    interface Thrower { Object get() throws Exception; }

    static String tryRun(Thrower t) {
        try { return String.valueOf(t.get()); } catch (Throwable e) { return "ERROR " + err(e); }
    }
}
