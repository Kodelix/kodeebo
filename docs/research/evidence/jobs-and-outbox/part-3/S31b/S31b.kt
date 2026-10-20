// S31b spike (researcher, 2026-10-20): (a) Exposed 1.5.1 attempt count vs transaction_timeout, counted by a side-effect counter outside the DB;
// (b) Ktor 3.6.0 stop with a REAL blocking JDBC statement (select pg_sleep(n)) in the claim transaction. Throwaway code, not product code.
// Same jars as S31 (no downloads). Entry points: Db2 (case a), App2 (case b). Env: PGPORT_S31 (published port of the throwaway container).
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

const val A = "aaaaaaaa-0000-4000-8000-000000000001"
val t0 = System.currentTimeMillis()
fun p(s: String) = println("[+${System.currentTimeMillis() - t0}ms] $s")

fun pool(user: String, name: String, size: Int = 4): HikariDataSource {
    val c = HikariConfig()
    c.jdbcUrl = "jdbc:postgresql://127.0.0.1:${System.getenv("PGPORT_S31")}/postgres"
    c.username = user; c.password = System.getenv("PGPW") ?: error("PGPW not set"); c.maximumPoolSize = size; c.poolName = name
    c.connectionTimeout = 5000
    c.addDataSourceProperty("ApplicationName", name)
    System.getenv("CCCI_MS")?.let { c.addDataSourceProperty("options", "-c client_connection_check_interval=$it") }
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

fun chain(e: Throwable): String {
    val sb = StringBuilder(); var c: Throwable? = e; var i = 0
    while (c != null && i < 4) { sb.append("${c::class.simpleName}: ${c.message?.lineSequence()?.firstOrNull()?.take(140)}${(c as? java.sql.SQLException)?.let { " [sqlState=${it.sqlState}]" } ?: ""} <- "); c = c.cause; i++ }
    return sb.toString()
}

@OptIn(ExperimentalCoroutinesApi::class)
object Db2 {
    @JvmStatic fun main(args: Array<String>) = runBlocking {
        val disp = Dispatchers.IO.limitedParallelism(2, "job-db")
        // name, DatabaseConfig default attempts (null = Exposed default), attempts set inside the block (null = not set)
        suspend fun case(name: String, defaultAttempts: Int?, inBlock: Int?) {
            val ds = pool("job_rt", "s31b-$name", 2)
            val db = if (defaultAttempts != null) Database.connect(ds, databaseConfig = DatabaseConfig { this.defaultMaxAttempts = defaultAttempts }) else Database.connect(ds)
            val counter = AtomicInteger(0)
            val s = System.currentTimeMillis()
            p("CASE $name: defaultMaxAttempts=${defaultAttempts ?: "(Exposed default)"} maxAttempts-in-block=${inBlock ?: "(not set)"}")
            try {
                withContext(disp) { withScope(db, A, 500) {
                    if (inBlock != null) maxAttempts = inBlock
                    val n = counter.incrementAndGet()
                    p("  $name body run #$n: transaction.maxAttempts=$maxAttempts claimed ${claimRaw(3)}, now pg_sleep(3)")
                    exec("select pg_sleep(3)", emptyList(), StatementType.SELECT) { it.next() }
                } }
                p("  $name unexpectedly succeeded")
            } catch (e: Exception) { p("  $name FAILED after ${System.currentTimeMillis() - s}ms; body ran ${counter.get()} time(s); ${chain(e)}") }
            for (attempt in 1..3) {
                try { withContext(disp) { withScope(db, A, null) { p("  $name next borrower (attempt $attempt): transaction_timeout=${strs("select current_setting('transaction_timeout')")} claim=${claimRaw(3)}") } }; break }
                catch (e: Exception) { p("  $name next borrower attempt $attempt failed: ${chain(e)}") }
            }
            ds.close()
        }
        case("a1-default", null, null)
        case("a2-config1", 1, null)
        case("a3-block1", null, 1)
        p("done")
    }
}

@OptIn(ExperimentalCoroutinesApi::class)
object App2 {
    @JvmStatic fun main(args: Array<String>) {
        val workSec = (System.getenv("WORK_SEC") ?: "3").toLong()
        val grace = (System.getenv("GRACE_MS") ?: "-1").toLong()
        val tmo = (System.getenv("TIMEOUT_MS") ?: "-1").toLong()
        val runnerStopMs = (System.getenv("RUNNER_STOP_MS") ?: "10000").toLong()
        val jobPool = pool("job_rt", "s31b-app-job"); val platPool = pool("platform_rt", "s31b-app-plat", 2)
        val job = Database.connect(jobPool); val plat = Database.connect(platPool)
        val disp = Dispatchers.IO.limitedParallelism(2, "job-db")
        p("config: WORK_SEC=$workSec GRACE_MS=$grace TIMEOUT_MS=$tmo RUNNER_STOP_MS=$runnerStopMs CCCI_MS=${System.getenv("CCCI_MS")}")
        var stmtStart = 0L

        suspend fun loop() {
            try {
                while (true) {
                    val tenants = withContext(disp) { suspendTransaction(plat) { strs("select tenant_id::text from app.tenant_status order by 1") } }
                    for (t in tenants) withContext(disp) { withScope(job, t, null) {
                        val ids = claimRaw(2)
                        if (ids.isNotEmpty()) {
                            p("loop: claimed $ids for $t; client_connection_check_interval=${strs("select current_setting('client_connection_check_interval')")}; now REAL blocking JDBC: select pg_sleep($workSec)")
                            stmtStart = System.currentTimeMillis()
                            exec("select pg_sleep($workSec)", emptyList(), StatementType.SELECT) { it.next() }
                            p("loop: pg_sleep returned after ${System.currentTimeMillis() - stmtStart}ms (statement was NOT interrupted if this is about ${workSec * 1000}ms)")
                        }
                    } }
                    delay(200)
                }
            } catch (e: CancellationException) { p("loop: cancelled (${e::class.simpleName})"); throw e }
            catch (e: Throwable) { p("loop: failed ${chain(e)}"); throw e }
            finally { p("loop: exited") }
        }

        val server = embeddedServer(CIO, configure = {
            connectors.add(io.ktor.server.engine.EngineConnectorBuilder().apply { host = "127.0.0.1"; port = 18091 })
            if (grace >= 0) shutdownGracePeriod = grace
            if (tmo >= 0) shutdownTimeout = tmo
        }) {
            val runner = CoroutineScope(SupervisorJob() + disp)
            monitor.subscribe(ApplicationStarted) { p("event ApplicationStarted"); runner.launch { loop() } }
            monitor.subscribe(ServerReady) { p("event ServerReady") }
            monitor.subscribe(ApplicationStopPreparing) { p("event ApplicationStopPreparing") }
            monitor.subscribe(ApplicationStopping) {
                p("event ApplicationStopping")
                val s = System.currentTimeMillis()
                val done = runBlocking { withTimeoutOrNull(runnerStopMs) { runner.coroutineContext[Job]!!.cancelAndJoin(); true } }
                p("runner: stop() ${if (done == true) "joined" else "TIMED OUT"} after ${System.currentTimeMillis() - s}ms")
            }
            monitor.subscribe(ApplicationStopped) {
                p("event ApplicationStopped; closing pools")
                try { jobPool.close(); platPool.close(); p("pools: closed") } catch (e: Throwable) { p("pools: close failed ${chain(e)}") }
            }
        }
        p("engineConfig: shutdownGracePeriod=${server.engineConfig.shutdownGracePeriod} shutdownTimeout=${server.engineConfig.shutdownTimeout}")
        server.start(wait = true)
        p("main: start(wait=true) returned")
    }
}
