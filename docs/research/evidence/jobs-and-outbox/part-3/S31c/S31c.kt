// S31c spike (researcher, 2026-10-21): stop during a REAL blocking JDBC statement (select pg_sleep) with the withScope helper's
// transaction_timeout set BELOW the runner stop timeout, attempts = 1 (DatabaseConfig { defaultMaxAttempts = 1 }), and the pool WITHOUT
// client_connection_check_interval. Throwaway code, not product code. Derived from S31b.kt (App2). Password comes from env PGPW (no literal).
// Env: PGPORT_S31 (published postgres port), KPORT (Ktor port), WORK_SEC, TX_TIMEOUT_MS, RUNNER_STOP_MS, TIMEOUT_MS (shutdownTimeout), GRACE_MS.
import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import io.ktor.server.application.*
import io.ktor.server.cio.CIO
import io.ktor.server.engine.embeddedServer
import kotlinx.coroutines.*
import org.jetbrains.exposed.v1.core.*
import org.jetbrains.exposed.v1.core.statements.StatementType
import org.jetbrains.exposed.v1.jdbc.*
import org.jetbrains.exposed.v1.jdbc.transactions.suspendTransaction
import java.util.UUID
import java.util.concurrent.atomic.AtomicInteger

val t0 = System.currentTimeMillis()
fun p(s: String) { val n = System.currentTimeMillis(); println("[+${n - t0}ms @$n] $s") }

fun pool(user: String, name: String, size: Int = 4): HikariDataSource {
    val c = HikariConfig()
    c.jdbcUrl = "jdbc:postgresql://127.0.0.1:${System.getenv("PGPORT_S31")}/postgres"
    c.username = user; c.password = System.getenv("PGPW") ?: error("PGPW not set"); c.maximumPoolSize = size; c.poolName = name
    c.connectionTimeout = 5000
    c.addDataSourceProperty("ApplicationName", name)   // client_connection_check_interval deliberately NOT set
    return HikariDataSource(c)
}

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
fun JdbcTransaction.claimRaw(n: Int): List<Long> =
    longs("select id from app.outbox where processed_at is null order by id for update skip locked limit $n")

fun sqlState(e: Throwable): String? { var c: Throwable? = e; var i = 0; while (c != null && i < 6) { (c as? java.sql.SQLException)?.let { return it.sqlState }; c = c.cause; i++ }; return null }
fun chain(e: Throwable): String {
    val sb = StringBuilder(); var c: Throwable? = e; var i = 0
    while (c != null && i < 4) { sb.append("${c::class.simpleName}: ${c.message?.lineSequence()?.firstOrNull()?.take(120)}${(c as? java.sql.SQLException)?.let { " [sqlState=${it.sqlState}]" } ?: ""} <- "); c = c.cause; i++ }
    return sb.toString()
}

@OptIn(ExperimentalCoroutinesApi::class)
object App3 {
    @JvmStatic fun main(args: Array<String>) {
        fun env(n: String, d: String) = System.getenv(n) ?: d
        val workSec = env("WORK_SEC", "12").toLong(); val txMs = env("TX_TIMEOUT_MS", "1500").toLong()
        val grace = env("GRACE_MS", "500").toLong(); val tmo = env("TIMEOUT_MS", "4000").toLong(); val runnerStopMs = env("RUNNER_STOP_MS", "3000").toLong()
        val jobPool = pool("job_rt", "s31c-app-job"); val platPool = pool("platform_rt", "s31c-app-plat", 2)
        val job = Database.connect(jobPool, databaseConfig = DatabaseConfig { defaultMaxAttempts = 1 })
        val plat = Database.connect(platPool)
        val disp = Dispatchers.IO.limitedParallelism(2, "job-db")
        val bodyRuns = AtomicInteger(0); val okRuns = AtomicInteger(0); val cancelled = AtomicInteger(0); val failed25P04 = AtomicInteger(0); val failedOther = AtomicInteger(0)
        p("config: WORK_SEC=$workSec TX_TIMEOUT_MS=$txMs RUNNER_STOP_MS=$runnerStopMs shutdownTimeout=$tmo grace=$grace defaultMaxAttempts=1")

        suspend fun loop() {
            try {
                while (true) {
                    currentCoroutineContext().ensureActive()
                    val tenants = withContext(disp) { suspendTransaction(plat) { strs("select tenant_id::text from app.tenant_status order by 1") } }
                    for (t in tenants) {
                        try {
                            withContext(disp) { withScope(job, t, txMs) {
                                val ids = claimRaw(2)
                                if (ids.isNotEmpty()) {
                                    val n = bodyRuns.incrementAndGet()
                                    p("loop: body run #$n (transaction.maxAttempts=$maxAttempts) claimed $ids for $t; client_connection_check_interval=${strs("select current_setting('client_connection_check_interval')")} transaction_timeout=${strs("select current_setting('transaction_timeout')")}; REAL blocking JDBC: select pg_sleep($workSec)")
                                    exec("select pg_sleep($workSec)", emptyList(), StatementType.SELECT) { it.next() }
                                    okRuns.incrementAndGet(); p("loop: pg_sleep returned normally")
                                }
                            } }
                        } catch (e: CancellationException) { cancelled.incrementAndGet(); p("loop: outcome=CANCELLED (${e::class.simpleName}) - not counted as a failed attempt"); throw e }
                        catch (e: Exception) {
                            val st = sqlState(e)
                            if (st == "25P04") failed25P04.incrementAndGet() else failedOther.incrementAndGet()
                            p("loop: outcome=FAILED sqlState=$st ${chain(e)}")
                            currentCoroutineContext().ensureActive()
                        }
                    }
                    delay(200)
                }
            } catch (e: CancellationException) { p("loop: cancelled (${e::class.simpleName})"); throw e }
            finally { p("loop: exited") }
        }

        val server = embeddedServer(CIO, configure = {
            connectors.add(io.ktor.server.engine.EngineConnectorBuilder().apply { host = "127.0.0.1"; port = env("KPORT", "18092").toInt() })
            shutdownGracePeriod = grace; shutdownTimeout = tmo
        }) {
            val runner = CoroutineScope(SupervisorJob() + disp)
            monitor.subscribe(ApplicationStarted) { p("event ApplicationStarted"); runner.launch { loop() } }
            monitor.subscribe(ApplicationStopPreparing) { p("event ApplicationStopPreparing") }
            monitor.subscribe(ApplicationStopping) {
                p("event ApplicationStopping")
                val s = System.currentTimeMillis()
                val done = runBlocking { withTimeoutOrNull(runnerStopMs) { runner.coroutineContext[Job]!!.cancelAndJoin(); true } }
                p("runner: stop() ${if (done == true) "JOINED" else "TIMED OUT"} after ${System.currentTimeMillis() - s}ms (runner timeout $runnerStopMs)")
            }
            monitor.subscribe(ApplicationStopped) {
                p("event ApplicationStopped; bodyRuns=${bodyRuns.get()} ok=${okRuns.get()} cancelled=${cancelled.get()} failed25P04=${failed25P04.get()} failedOther=${failedOther.get()}; closing pools")
                try { jobPool.close(); platPool.close(); p("pools: closed") } catch (e: Throwable) { p("pools: close failed ${chain(e)}") }
            }
        }
        server.start(wait = true)
        p("main: start(wait=true) returned")
    }
}
