// S24: JVM-track tenant-context spike. Kotlin 2.4.21, Exposed 1.5.1, HikariCP 7.1.0, pgjdbc 42.7.14,
// kotlinx.coroutines 1.11.0, jOOQ 3.21.9 (open-source edition), postgres:18.6, PgBouncer 1.26.0 (transaction mode).
// Role app_rt: LOGIN NOSUPERUSER NOBYPASSRLS, not the table owner; table has ENABLE + FORCE RLS (setup.sql).
import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import kotlinx.coroutines.*
import org.jetbrains.exposed.v1.core.VarCharColumnType
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.JdbcTransaction
import org.jetbrains.exposed.v1.jdbc.transactions.suspendTransaction
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import org.jooq.SQLDialect
import org.jooq.impl.DSL
import java.sql.Connection
import java.sql.SQLException
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger
import javax.sql.DataSource

const val A = "11111111-1111-4111-8111-111111111111"
const val B = "22222222-2222-4222-8222-222222222222"
var failures = 0
fun obs(s: String) = println("OBS  $s")
fun check(name: String, ok: Boolean, detail: String = "") {
    println((if (ok) "PASS " else "FAIL ") + name + (if (detail.isNotEmpty()) "  [$detail]" else ""))
    if (!ok) failures++
}

fun pool(port: Int, urlSuffix: String = ""): HikariDataSource {
    val c = HikariConfig()
    c.jdbcUrl = "jdbc:postgresql://127.0.0.1:$port/postgres$urlSuffix"
    c.username = "app_rt"; c.password = "ti_p2_throwaway"
    c.maximumPoolSize = 1; c.minimumIdle = 1; c.connectionTimeout = 2000
    return HikariDataSource(c)
}

data class St(val pid: Int, val rows: Int, val guc: String) { fun clean() = guc == "" || guc == "<NULL>" }
const val STATE_SQL = "select pg_backend_pid(), (select count(*) from app.orders), coalesce(current_setting('app.tenant_id', true),'<NULL>')"

fun Connection.state(): St = createStatement().use { s -> s.executeQuery(STATE_SQL).use { rs -> rs.next(); St(rs.getInt(1), rs.getInt(2), rs.getString(3)) } }
fun JdbcTransaction.state(): St = exec(STATE_SQL) { rs -> rs.next(); St(rs.getInt(1), rs.getInt(2), rs.getString(3)) }!!
fun JdbcTransaction.setTenant(t: String?) { exec("SELECT set_config('app.tenant_id', ?, true)", listOf(VarCharColumnType(64) to t)) { rs -> rs.next(); rs.getString(1) } }
fun sqlState(e: Throwable?): String? = generateSequence(e) { it.cause }.filterIsInstance<SQLException>().firstOrNull()?.sqlState

/** Guard: refuse (and evict) a pooled connection that still carries a tenant value or an open tx. */
class GuardedDs(private val d: HikariDataSource) : DataSource by d {
    var evicted = 0
    override fun getConnection(): Connection {
        repeat(3) {
            val c = d.connection
            if (c.state().clean()) return c
            evicted++; d.evictConnection(c); c.close()
        }
        throw IllegalStateException("could not obtain a clean connection")
    }
}

fun main(args: Array<String>) {
    val direct = args[0].toInt(); val pgb200 = args[1].toInt(); val pgb0 = args[2].toInt()
    println("### java ${System.getProperty("java.version")}  kotlin ${KotlinVersion.CURRENT}")

    // ---------------- Exposed on HikariCP (pool size 1) ----------------
    val ds = pool(direct); val db = Database.connect(ds)
    run {
        val s = transaction(db) { state() }
        check("K1a forgotten context (Exposed transaction{}): 0 rows visible", s.rows == 0, "$s")
        val e = runCatching { transaction(db) { exec("insert into app.orders(tenant_id,note) values ('$A','forgot')") } }.exceptionOrNull()
        check("K1b forgotten context: INSERT rejected with SQLSTATE 42501", sqlState(e) == "42501", "sqlState=${sqlState(e)}")
        val cnt = runCatching { transaction(db) { setTenant(A); state() } }.getOrNull()
        check("K2a set_config(...,true) first, then query: tenant A sees 3 rows", cnt?.rows == 3, "$cnt")
        val after = ds.connection.use { it.state() }
        check("K2b next borrower (same backend, no tx context): clean GUC, 0 rows", after.clean() && after.rows == 0 && after.pid == cnt?.pid, "$after")
        val bad = runCatching { transaction(db) { setTenant("not-a-uuid"); state() } }.exceptionOrNull()
        check("K2c malformed tenant id: error 22P02 (not silently 0 rows)", sqlState(bad) == "22P02", "sqlState=${sqlState(bad)}")
    }

    // ---------------- coroutine hop inside suspendTransaction ----------------
    runBlocking {
        val r = suspendTransaction(db) {
            setTenant(A)
            val t1 = Thread.currentThread().name
            delay(20)
            val t2 = withContext(Dispatchers.Default) { Thread.currentThread().name to this@suspendTransaction.state() }
            Triple(t1, t2.first, t2.second)
        }
        check("K3 suspendTransaction + withContext(Default) hop: GUC follows the connection (3 rows)", r.third.rows == 3, "threads ${r.first} -> ${r.second}, ${r.third}")
        val after = ds.connection.use { it.state() }
        check("K3b after suspendTransaction: next borrower clean", after.clean() && after.rows == 0, "$after")
    }

    // ---------------- ThreadLocal pitfalls (a naive 'current tenant' holder) ----------------
    run {
        val tl = ThreadLocal<String?>()
        val single = Executors.newFixedThreadPool(1)
        single.submit { tl.set(A) }.get()                          // request 1 sets A and never clears
        val seen = single.submit<String?> { tl.get() }.get()       // request 2 (other tenant, forgot to set) runs on the reused thread
        single.shutdown()
        check("K4a ThreadLocal on a reused pool thread: request 2 reads request 1's tenant (leak demonstrated)", seen == A, "request 2 saw $seen")
    }
    runBlocking {
        val disp = Executors.newFixedThreadPool(4).asCoroutineDispatcher()
        val tl = ThreadLocal<String?>()
        val bad = AtomicInteger(); val bad2 = AtomicInteger()
        coroutineScope {
            (1..400).map { i ->
                async(disp) {
                    tl.set("t$i"); delay(1); yield()
                    if (tl.get() != "t$i") bad.incrementAndGet()          // plain ThreadLocal across suspension
                    withContext(tl.asContextElement("u$i")) {
                        delay(1); yield()
                        if (tl.get() != "u$i") bad2.incrementAndGet()     // ThreadContextElement
                    }
                }
            }.awaitAll()
        }
        disp.close()
        check("K4b plain ThreadLocal across delay()/yield() on a 4-thread dispatcher: mismatches > 0 (demonstrated)", bad.get() > 0, "mismatches=${bad.get()} of 400")
        check("K4c ThreadLocal.asContextElement across the same suspension: mismatches == 0", bad2.get() == 0, "mismatches=${bad2.get()} of 400")
    }

    // ---------------- nested transactions share the connection ----------------
    runBlocking {
        val res = suspendTransaction(db) {
            setTenant(A)
            val before = state().rows
            val inner = suspendTransaction(db) { setTenant(B); state().rows }
            val outerAfter = state()
            Triple(before, inner, outerAfter)
        }
        check("K5 nested suspendTransaction with another tenant changes the OUTER context (shared connection)", res.third.rows == 5, "outer before=${res.first} inner=${res.second} outer after inner=${res.third}")
    }

    // ---------------- HikariCP: what it resets and what it does not ----------------
    run {
        val s = ds.connection.use { c ->               // autoCommit = true (HikariCP default)
            c.createStatement().use { it.execute("select set_config('app.tenant_id','$A',true)") }
            c.state()
        }
        check("K6a autoCommit=true: set_config(...,true) is lost before the next statement (context silently absent, 0 rows)", s.rows == 0, "$s")
        val pidBefore = ds.connection.use { it.state().pid }
        ds.connection.use { c ->                         // transaction left open on return
            c.autoCommit = false
            c.createStatement().use { it.execute("select set_config('app.tenant_id','$A',true)") }
        }
        val s2 = ds.connection.use { it.state() }
        check("K6b connection returned with an open tx: HikariCP rolls back and reuses it; next borrower clean", s2.clean() && s2.rows == 0 && s2.pid == pidBefore, "same backend=${s2.pid == pidBefore} $s2")
        ds.connection.use { c -> c.createStatement().use { it.execute("select set_config('app.tenant_id','$A',false)") } }   // is_local=false: the anti-pattern
        val s3 = ds.connection.use { it.state() }
        check("K6c NEGATIVE CONTROL session-level set_config(...,false): HikariCP does NOT reset it; next borrower sees tenant A", s3.rows == 3, "$s3")
        val g = GuardedDs(ds)
        val s4 = g.connection.use { it.state() }
        check("K6d guard wrapper detects the dirty connection, evicts it, hands out a clean one", g.evicted == 1 && s4.clean() && s4.rows == 0, "evicted=${g.evicted} $s4")
    }

    // ---------------- jOOQ (alternative) ----------------
    run {
        val dsl = DSL.using(ds, SQLDialect.POSTGRES)
        val forgot = dsl.fetchOne("select count(*) from app.orders")!!.get(0, Int::class.java)
        check("K7a jOOQ forgotten context: 0 rows", forgot == 0, "rows=$forgot")
        val n = dsl.transactionResult { cfg ->
            val d = DSL.using(cfg)
            d.fetch("select set_config('app.tenant_id', ?, true)", A)
            d.fetchOne("select count(*) from app.orders")!!.get(0, Int::class.java)
        }
        check("K7b jOOQ transactionResult: set_config(...,true) then query in one connection: 3 rows", n == 3, "rows=$n")
        val after = ds.connection.use { it.state() }
        check("K7c jOOQ: next borrower clean", after.clean() && after.rows == 0, "$after")
    }
    ds.close()

    // ---------------- pgjdbc through PgBouncer transaction mode ----------------
    fun rounds(port: Int, suffix: String): String? {
        val p1 = pool(port, suffix); val p2 = pool(port, suffix)
        try {
            repeat(30) { i ->
                for (p in listOf(p1, p2)) {
                    val tenant = if (i % 2 == 0) A else B
                    p.connection.use { c ->
                        c.autoCommit = false
                        c.prepareStatement("select set_config('app.tenant_id', ?, true)").use { ps -> ps.setString(1, tenant); ps.executeQuery().close() }
                        c.prepareStatement("select count(*) from app.orders").use { ps -> ps.executeQuery().use { rs -> rs.next() } }
                        c.commit()
                    }
                }
            }
            return null
        } catch (e: Exception) { return "${e.javaClass.simpleName}: ${e.message?.lineSequence()?.first()}" } finally { p1.close(); p2.close() }
    }
    val e1 = rounds(pgb200, "")
    check("K8a pgjdbc default props via PgBouncer 1.26.0 tx mode, max_prepared_statements=200: no error in 60 tx", e1 == null, "$e1")
    val e2 = rounds(pgb0, "")
    obs("K8b pgjdbc default props (prepareThreshold=5) via PgBouncer max_prepared_statements=0: first error = $e2")
    val e3 = rounds(pgb0, "?prepareThreshold=0")
    check("K8c pgjdbc prepareThreshold=0 via PgBouncer max_prepared_statements=0: no error in 60 tx", e3 == null, "$e3")

    println("### failures=$failures")
    System.exit(if (failures == 0) 0 else 1)
}
