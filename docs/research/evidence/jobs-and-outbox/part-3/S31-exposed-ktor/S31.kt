// S31 spike (researcher, 2026-10-20): Exposed 1.5.1 suspendTransaction + withScope on HikariCP 7.1.0 + pgjdbc 42.7.14 vs postgres:18.6,
// and the Ktor 3.6.0 (CIO) job-loop lifecycle. Throwaway code, not product code. Two entry points: Db (X1-X6, X3b) and App (X7-X9).
// Env: PGPORT_S31 (published port of the throwaway container). Roles/policies: S30-sql-level/setup.sql (+ seed in run.sh).
import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import io.ktor.server.application.*
import io.ktor.server.cio.CIO
import io.ktor.server.engine.embeddedServer
import kotlinx.coroutines.*
import org.jetbrains.exposed.v1.core.*
import org.jetbrains.exposed.v1.core.statements.StatementType
import org.jetbrains.exposed.v1.core.vendors.ForUpdateOption
import org.jetbrains.exposed.v1.jdbc.*
import org.jetbrains.exposed.v1.jdbc.transactions.suspendTransaction
import java.util.UUID

const val A = "aaaaaaaa-0000-4000-8000-000000000001"
val t0 = System.currentTimeMillis()
fun p(s: String) = println("[+${System.currentTimeMillis() - t0}ms] $s")

fun pool(user: String, name: String, size: Int = 4): HikariDataSource {
    val c = HikariConfig()
    c.jdbcUrl = "jdbc:postgresql://127.0.0.1:${System.getenv("PGPORT_S31")}/postgres"
    c.username = user; c.password = System.getenv("PGPW") ?: error("PGPW not set"); c.maximumPoolSize = size; c.poolName = name
    c.connectionTimeout = 5000
    c.addDataSourceProperty("ApplicationName", name)
    return HikariDataSource(c)
}

/** Stand-in for the ADR-0002 helper: timeout first (local), then the tenant, both via set_config(..., true) inside the Exposed transaction. */
suspend fun <T> withScope(db: Database, tenant: String?, timeoutMs: Long?, block: suspend JdbcTransaction.() -> T): T =
    suspendTransaction(db) {
        if (timeoutMs != null) ex("select set_config('transaction_timeout', ?, true)", StatementType.SELECT, "${timeoutMs}ms")
        if (tenant != null) { UUID.fromString(tenant); ex("select set_config('app.tenant_id', ?, true)", StatementType.SELECT, tenant) }
        block()
    }

fun JdbcTransaction.ex(sql: String, type: StatementType, vararg a: String) {
    if (type == StatementType.SELECT) exec(sql, a.map { TextColumnType() to it }, type) { rs -> rs.next() }
    else exec(sql, a.map { TextColumnType() to it }, type)
}
fun JdbcTransaction.strs(sql: String, vararg a: String): List<String> =
    exec(sql, a.map { TextColumnType() to it }, StatementType.SELECT) { rs -> val l = mutableListOf<String>(); while (rs.next()) l += rs.getString(1); l } ?: emptyList()
fun JdbcTransaction.longs(sql: String): List<Long> = strs(sql).map { it.toLong() }

object Outbox : Table("app.outbox") {
    val id = long("id")
    val processedAt = text("processed_at").nullable()
}
var printedSql = false
fun JdbcTransaction.claimDsl(n: Int): List<Long> {
    val q = Outbox.select(Outbox.id).where { Outbox.processedAt.isNull() }.orderBy(Outbox.id, SortOrder.ASC).limit(n)
        .forUpdate(ForUpdateOption.PostgreSQL.ForUpdate(ForUpdateOption.PostgreSQL.MODE.SKIP_LOCKED))
    if (!printedSql) { printedSql = true; p("DSL SQL: " + q.prepareSQL(this, false)) }
    return q.map { it[Outbox.id] }
}
fun JdbcTransaction.claimRaw(n: Int): List<Long> =
    longs("select id from app.outbox where processed_at is null order by id for update skip locked limit $n")

fun chain(e: Throwable): String {
    val sb = StringBuilder(); var c: Throwable? = e; var i = 0
    while (c != null && i < 4) { sb.append("${c::class.simpleName}: ${c.message?.lineSequence()?.firstOrNull()?.take(140)}${(c as? java.sql.SQLException)?.let { " [sqlState=${it.sqlState}]" } ?: ""} <- "); c = c.cause; i++ }
    return sb.toString()
}

@OptIn(ExperimentalCoroutinesApi::class)
object Db {
    @JvmStatic fun main(args: Array<String>) = runBlocking {
        val jobPool = pool("job_rt", "s31-job"); val platPool = pool("platform_rt", "s31-plat", 2)
        val job = Database.connect(jobPool); val plat = Database.connect(platPool)
        val disp = Dispatchers.IO.limitedParallelism(2, "job-db")
        p("pgjdbc/pg: " + withContext(disp) { suspendTransaction(plat) { strs("select version()")[0] } })

        // X1
        withContext(disp) {
            withScope(job, null, null) {
                p("X1 job_rt NO scope: outbox=${longs("select count(*) from app.outbox")} claim=${claimRaw(5)} tenant_status=${longs("select count(*) from app.tenant_status")}")
            }
            withScope(job, A, null) { p("X1b control, scope A: outbox=${longs("select count(*) from app.outbox")}") }
        }
        // X2
        withContext(disp) {
            suspendTransaction(plat) { p("X2 platform_rt tenants: ${strs("select tenant_id::text || ' ' || status from app.tenant_status order by 1")}") }
            try { suspendTransaction(plat) { longs("select count(*) from app.outbox") } } catch (e: Exception) { p("X2b platform_rt reads outbox: ${chain(e)}") }
        }
        // X3 two workers, same tenant, DSL claim with SKIP LOCKED
        val w1 = async(disp) { withScope(job, A, null) { val ids = claimDsl(6); p("X3 W1 claimed $ids"); Thread.sleep(1500); ids } }
        delay(400)
        val w2 = async(disp) { withScope(job, A, null) { val ids = claimDsl(6); p("X3 W2 claimed $ids"); ids } }
        val i1 = w1.await(); val i2 = w2.await()
        p("X3 result: W1=${i1.size} W2=${i2.size} overlap=${i1.intersect(i2.toSet()).size}")

        // X4 dedup + effect with the transaction
        suspend fun counts(tag: String) = withContext(disp) { withScope(job, A, null) { p("X4 $tag: dedup=${longs("select count(*) from app.inbox_dedup")} effects=${longs("select count(*) from app.effects")}") } }
        suspend fun JdbcTransaction.both(m: String) {
            ex("insert into app.inbox_dedup(tenant_id, message_id) values (?::uuid, ?)", StatementType.INSERT, A, m)
            ex("insert into app.effects(tenant_id, note) values (?::uuid, ?)", StatementType.INSERT, A, "effect of $m")
        }
        try { withContext(disp) { withScope(job, A, null) { both("m1"); error("forced failure after both inserts") } } } catch (e: IllegalStateException) { p("X4a caught: ${e.message}") }
        counts("after thrown exception (expect 0/0)")
        val j = launch(disp) { withScope(job, A, null) { both("m2"); delay(10_000) } }
        delay(500); j.cancelAndJoin()
        p("X4b cancelled mid-transaction; pool active=${jobPool.hikariPoolMXBean.activeConnections} idle=${jobPool.hikariPoolMXBean.idleConnections}")
        counts("after cancellation (expect 0/0)")
        withContext(disp) { withScope(job, A, null) { both("m3") } }
        counts("after commit (expect 1/1)")
        withContext(disp) { withScope(job, A, null) {
            val before = longs("select count(*) from app.effects")
            ex("insert into app.inbox_dedup(tenant_id, message_id) values (?::uuid, ?) on conflict do nothing", StatementType.INSERT, A, "m3")
            p("X4c redelivery of m3 with on conflict do nothing: effects before=$before (effect would be skipped by the caller)")
        } }
        try { withContext(disp) { withScope(job, A, null) { ex("insert into app.inbox_dedup(tenant_id, message_id) values (?::uuid, ?)", StatementType.INSERT, A, "m3") } } } catch (e: Exception) { p("X4d duplicate insert: ${chain(e)}") }

        // X5 traceparent
        val tp = "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
        withContext(disp) { withScope(job, A, null) {
            ex("insert into app.outbox(tenant_id, kind, ref, traceparent) values (?::uuid, 'order.created', gen_random_uuid(), ?)", StatementType.INSERT, A, tp)
        } }
        withContext(disp) { withScope(job, A, null) { val back = strs("select traceparent from app.outbox where traceparent is not null limit 1")
            p("X5 traceparent read back: $back equal=${back == listOf(tp)}") } }

        // X6 transaction_timeout applies to a claim transaction run by the helper
        val s = System.currentTimeMillis()
        try { withContext(disp) { withScope(job, A, 500) { p("X6 claimed ${claimRaw(3)} with timeout 500ms, now pg_sleep(3)"); exec("select pg_sleep(3)", emptyList(), StatementType.SELECT) { it.next() } } } }
        catch (e: Exception) { p("X6 failed after ${System.currentTimeMillis() - s}ms: ${chain(e)}") }
        for (attempt in 1..3) {
            try { withContext(disp) { withScope(job, A, null) { p("X6 follow-up attempt $attempt: transaction_timeout=${strs("select current_setting('transaction_timeout')")} claim=${claimRaw(3)}") } }; break }
            catch (e: Exception) { p("X6 follow-up attempt $attempt failed: ${chain(e)}") }
        }

        // X3b per-tenant sweep: platform_rt lists, one scoped transaction per tenant, claim + mark
        val sw = System.currentTimeMillis(); var total = 0
        val tenants = withContext(disp) { suspendTransaction(plat) { strs("select tenant_id::text from app.tenant_status order by 1") } }
        for (t in tenants) withContext(disp) { withScope(job, t, 2000) {
            val ids = claimDsl(100)
            if (ids.isNotEmpty()) ex("update app.outbox set processed_at = now(), attempts = attempts + 1 where id in (${ids.joinToString()})", StatementType.UPDATE)
            total += ids.size; p("X3b sweep tenant $t claimed+marked ${ids.size}")
        } }
        p("X3b sweep over ${tenants.size} tenants: $total rows in ${System.currentTimeMillis() - sw}ms")
        p("pool close")
        jobPool.close(); platPool.close()
        p("done")
    }
}

@OptIn(ExperimentalCoroutinesApi::class)
object App {
    @JvmStatic fun main(args: Array<String>) {
        val mode = System.getenv("MODE") ?: "B2"            // B1: Application.launch ; B2: own JobRunner scope stopped from ApplicationStopping
        val work = System.getenv("WORK") ?: "delay"         // delay (cooperative) | block (Thread.sleep) | pg (pg_sleep)
        val workSec = (System.getenv("WORK_SEC") ?: "3").toLong()
        val closeAt = System.getenv("CLOSE_AT") ?: "stopped" // stopped | stopping
        val grace = (System.getenv("GRACE_MS") ?: "-1").toLong()
        val tmo = (System.getenv("TIMEOUT_MS") ?: "-1").toLong()
        val runnerStopMs = (System.getenv("RUNNER_STOP_MS") ?: "10000").toLong()
        val jobPool = pool("job_rt", "s31-app-job"); val platPool = pool("platform_rt", "s31-app-plat", 2)
        val job = Database.connect(jobPool); val plat = Database.connect(platPool)
        val disp = Dispatchers.IO.limitedParallelism(2, "job-db")
        p("config: MODE=$mode WORK=$work WORK_SEC=$workSec CLOSE_AT=$closeAt GRACE_MS=$grace TIMEOUT_MS=$tmo")

        suspend fun loop() {
            try {
                while (true) {
                    val tenants = withContext(disp) { suspendTransaction(plat) { strs("select tenant_id::text from app.tenant_status order by 1") } }
                    for (t in tenants) withContext(disp) { withScope(job, t, null) {
                        val ids = claimDsl(2)
                        if (ids.isNotEmpty()) {
                            p("loop: claimed $ids for $t, work=$work ${workSec}s")
                            when (work) {
                                "delay" -> delay(workSec * 1000)
                                "block" -> Thread.sleep(workSec * 1000)
                                else -> exec("select pg_sleep($workSec)", emptyList(), StatementType.SELECT) { it.next() }
                            }
                            p("loop: work finished, committing")
                        }
                    } }
                    delay(200)
                }
            } catch (e: CancellationException) { p("loop: cancelled (${e::class.simpleName})"); throw e }
            catch (e: Throwable) { p("loop: failed ${chain(e)}"); throw e }
            finally { p("loop: exited") }
        }
        fun closePools(at: String) { p("pools: closing at $at"); try { jobPool.close(); platPool.close(); p("pools: closed") } catch (e: Throwable) { p("pools: close failed ${chain(e)}") } }

        val server = embeddedServer(CIO, configure = {
            connectors.add(io.ktor.server.engine.EngineConnectorBuilder().apply { host = "127.0.0.1"; port = 18090 })
            if (grace >= 0) shutdownGracePeriod = grace
            if (tmo >= 0) shutdownTimeout = tmo
        }) {
            monitor.subscribe(ApplicationStarting) { p("event ApplicationStarting") }
            monitor.subscribe(ApplicationStarted) { p("event ApplicationStarted") }
            monitor.subscribe(ServerReady) { p("event ServerReady") }
            monitor.subscribe(ApplicationStopPreparing) { p("event ApplicationStopPreparing") }
            val runner = CoroutineScope(SupervisorJob() + disp)
            if (mode == "B1") launch(disp) { loop() }
            else monitor.subscribe(ApplicationStarted) { runner.launch { loop() } }
            monitor.subscribe(ApplicationStopping) {
                p("event ApplicationStopping")
                if (mode == "B2") {
                    val s = System.currentTimeMillis()
                    val done = runBlocking { withTimeoutOrNull(runnerStopMs) { runner.coroutineContext[Job]!!.cancelAndJoin(); true } }
                    p("runner: stop() ${if (done == true) "joined" else "TIMED OUT"} after ${System.currentTimeMillis() - s}ms")
                }
                if (closeAt == "stopping") closePools("ApplicationStopping")
            }
            monitor.subscribe(ApplicationStopped) {
                p("event ApplicationStopped")
                if (closeAt == "stopped") closePools("ApplicationStopped")
            }
        }
        p("engineConfig: shutdownGracePeriod=${server.engineConfig.shutdownGracePeriod} shutdownTimeout=${server.engineConfig.shutdownTimeout}")
        server.start(wait = true)
        p("main: start(wait=true) returned")
    }
}
