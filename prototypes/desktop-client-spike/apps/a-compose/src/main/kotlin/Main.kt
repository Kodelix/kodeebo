// PROTOTYPE - NOT FOR PRODUCTION
// Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
// Date: 2026-10-16
// Behaviour: ../../SPEC.md (same modes, store and print in A, B and C).
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import com.sun.jna.Library
import com.sun.jna.Native
import com.sun.jna.Pointer
import com.sun.jna.Structure
import com.sun.jna.WString
import com.sun.jna.ptr.IntByReference
import com.sun.jna.ptr.PointerByReference
import java.io.File
import java.security.SecureRandom
import java.sql.Connection
import org.sqlite.mc.SQLiteMCConfig
import kotlin.system.exitProcess

const val RT = "a"
val dataDir = File(System.getenv("LOCALAPPDATA"), "KodeeboSpike\\$RT").apply { mkdirs() }
const val PRINTER = "KSPIKE-SINK"

// ---------- store (SPEC.md "The store") ----------
fun openStore(): Connection {
    val keyFile = File(dataDir, "key.bin")
    if (!keyFile.exists()) keyFile.writeBytes(ByteArray(32).also { SecureRandom().nextBytes(it) })
    // The key must be applied by the driver while it opens the connection (A-F1): a "PRAGMA hexkey" sent after
    // DriverManager.getConnection() works only on a new file; every later process then gets SQLITE_NOTADB.
    val c = SQLiteMCConfig.Builder().withHexKey(keyFile.readBytes()).build()
        .createConnection("jdbc:sqlite:" + File(dataDir, "store.db").path)
    c.createStatement().use { s ->
        s.executeQuery("SELECT count(*) FROM sqlite_master").use { it.next() }   // verifies the key
        s.execute("PRAGMA journal_mode=DELETE")
        s.execute("PRAGMA synchronous=FULL")
        s.execute("PRAGMA temp_store=MEMORY")
        s.execute("CREATE TABLE IF NOT EXISTS bill(id INTEGER PRIMARY KEY, opened_ms INTEGER, closed_ms INTEGER, total_piastres INTEGER)")
        s.execute("CREATE TABLE IF NOT EXISTS bill_line(id INTEGER PRIMARY KEY, bill_id INTEGER, name TEXT, qty INTEGER, price_piastres INTEGER)")
        s.execute("CREATE TABLE IF NOT EXISTS payment(id INTEGER PRIMARY KEY, bill_id INTEGER, method TEXT, amount_piastres INTEGER)")
        s.execute("CREATE TABLE IF NOT EXISTS outbox(seq INTEGER PRIMARY KEY, bill_id INTEGER, payload TEXT)")
    }
    return c
}

fun closeBillTx(c: Connection) {
    val now = System.currentTimeMillis()
    val prices = intArrayOf(2500, 1500, 3000, 1000, 4500)
    val total = prices.sum()
    c.createStatement().use { it.execute("BEGIN IMMEDIATE") }
    try {
        val billId = c.prepareStatement("INSERT INTO bill(opened_ms, closed_ms, total_piastres) VALUES (?,?,?)").use { p ->
            p.setLong(1, now - 3_600_000); p.setLong(2, now); p.setInt(3, total); p.executeUpdate()
            c.createStatement().use { s -> s.executeQuery("SELECT last_insert_rowid()").use { it.next(); it.getLong(1) } }
        }
        c.prepareStatement("INSERT INTO bill_line(bill_id, name, qty, price_piastres) VALUES (?,?,1,?)").use { p ->
            prices.forEachIndexed { i, pr -> p.setLong(1, billId); p.setString(2, "item $i"); p.setInt(3, pr); p.executeUpdate() }
        }
        c.prepareStatement("INSERT INTO payment(bill_id, method, amount_piastres) VALUES (?,'cash',?)").use { p ->
            p.setLong(1, billId); p.setInt(2, total); p.executeUpdate()
        }
        c.prepareStatement("INSERT INTO outbox(bill_id, payload) VALUES (?,?)").use { p ->
            p.setLong(1, billId); p.setString(2, "{\"bill\":$billId,\"total\":$total}"); p.executeUpdate()
        }
        c.createStatement().use { it.execute("COMMIT") }
    } catch (e: Exception) {
        runCatching { c.createStatement().use { it.execute("ROLLBACK") } }
        throw e
    }
}

fun checkStore(): String {
    val c = openStore()
    fun one(sql: String): String = c.createStatement().use { s -> s.executeQuery(sql).use { it.next(); it.getString(1) } }
    val integrity = c.createStatement().use { s -> s.executeQuery("PRAGMA integrity_check").use { r -> buildList { while (r.next()) add(r.getString(1)) }.joinToString("|") } }
    val bad = one("""SELECT count(*) FROM bill b WHERE
        (SELECT count(*) FROM bill_line l WHERE l.bill_id=b.id)<>5 OR
        (SELECT count(*) FROM payment p WHERE p.bill_id=b.id)<>1 OR
        (SELECT count(*) FROM outbox o WHERE o.bill_id=b.id)<>1 OR
        b.total_piastres <> (SELECT coalesce(sum(qty*price_piastres),0) FROM bill_line l WHERE l.bill_id=b.id)""").toInt()
    val orphans = one("""SELECT (SELECT count(*) FROM bill_line WHERE bill_id NOT IN (SELECT id FROM bill)) +
        (SELECT count(*) FROM payment WHERE bill_id NOT IN (SELECT id FROM bill)) +
        (SELECT count(*) FROM outbox WHERE bill_id NOT IN (SELECT id FROM bill))""").toInt()
    val line = "integrity=$integrity bills=${one("SELECT count(*) FROM bill")} lines=${one("SELECT count(*) FROM bill_line")} " +
        "payments=${one("SELECT count(*) FROM payment")} outbox=${one("SELECT count(*) FROM outbox")} consistent=${bad == 0 && orphans == 0}"
    c.close()
    return line
}

// ---------- RAW print (SPEC.md "The print") ----------
@Structure.FieldOrder("pDocName", "pOutputFile", "pDatatype")
class DocInfo1 : Structure() {
    @JvmField var pDocName: WString? = WString("kodeebo spike receipt")
    @JvmField var pOutputFile: WString? = null
    @JvmField var pDatatype: WString? = WString("RAW")
}

interface WinSpool : Library {
    fun OpenPrinterW(name: WString, handle: PointerByReference, defaults: Pointer?): Boolean
    fun StartDocPrinterW(h: Pointer, level: Int, doc: DocInfo1): Int
    fun StartPagePrinter(h: Pointer): Boolean
    fun WritePrinter(h: Pointer, buf: ByteArray, count: Int, written: IntByReference): Boolean
    fun EndPagePrinter(h: Pointer): Boolean
    fun EndDocPrinter(h: Pointer): Boolean
    fun ClosePrinter(h: Pointer): Boolean
}

val receipt: ByteArray by lazy { object {}.javaClass.getResourceAsStream("/receipt.bin")!!.readBytes() }
val spool: WinSpool by lazy { Native.load("winspool.drv", WinSpool::class.java) }

// Optional per-phase timing (ms) for the first-print instrumentation (SPEC.md).
fun printRaw(ph: MutableMap<String, Double>? = null) {
    var t = System.nanoTime()
    fun mark(name: String) { val now = System.nanoTime(); ph?.put(name, (now - t) / 1e6); t = now }
    val ws = spool; receipt; mark("load_native")              // first use: JNA loads winspool.drv; receipt read from the jar
    val ref = PointerByReference()
    check(ws.OpenPrinterW(WString(PRINTER), ref, null)) { "OpenPrinterW failed: ${Native.getLastError()}" }
    mark("open_printer")
    val h = ref.value
    try {
        check(ws.StartDocPrinterW(h, 1, DocInfo1()) != 0) { "StartDocPrinterW failed: ${Native.getLastError()}" }
        check(ws.StartPagePrinter(h)) { "StartPagePrinter failed: ${Native.getLastError()}" }
        mark("start_doc")
        val n = IntByReference()
        check(ws.WritePrinter(h, receipt, receipt.size, n) && n.value == receipt.size) { "WritePrinter wrote ${n.value} of ${receipt.size}: ${Native.getLastError()}" }
        mark("write")
        check(ws.EndPagePrinter(h)) { "EndPagePrinter failed" }
        check(ws.EndDocPrinter(h)) { "EndDocPrinter failed" }
        mark("end_doc")
    } finally {
        ws.ClosePrinter(h)
        mark("close_printer")
    }
}

// ---------- process I/O counters (first-print instrumentation) ----------
@Structure.FieldOrder("readOps", "writeOps", "otherOps", "readBytes", "writeBytes", "otherBytes")
class IoCounters : Structure() {
    @JvmField var readOps = 0L; @JvmField var writeOps = 0L; @JvmField var otherOps = 0L
    @JvmField var readBytes = 0L; @JvmField var writeBytes = 0L; @JvmField var otherBytes = 0L
}
interface K32 : Library {
    fun GetCurrentProcess(): Pointer
    fun GetProcessIoCounters(h: Pointer, c: IoCounters): Boolean
}
lateinit var k32: K32
fun io(): IoCounters = IoCounters().also { k32.GetProcessIoCounters(k32.GetCurrentProcess(), it) }

// ---------- warm-up (SPEC.md) ----------
fun warmUp(): String {
    var t = System.nanoTime()
    fun lap(): Double { val now = System.nanoTime(); val d = (now - t) / 1e6; t = now; return d }
    val c = openStore(); val open = lap()
    val ws = spool; receipt
    val ref = PointerByReference()
    check(ws.OpenPrinterW(WString(PRINTER), ref, null)) { "warm-up OpenPrinterW failed: ${Native.getLastError()}" }
    ws.ClosePrinter(ref.value); val print = lap()
    c.createStatement().use { s ->
        s.execute("BEGIN IMMEDIATE")
        s.execute("INSERT INTO bill(opened_ms, closed_ms, total_piastres) VALUES (0, 0, 0)")
        s.execute("ROLLBACK")
    }
    val tx = lap()
    warmConn = c
    return "warmup_ms=%.1f parts=%.1f,%.1f,%.1f".format(open + print + tx, open, print, tx)
}
var warmConn: Connection? = null

// ---------- modes ----------
fun bench(n: Int, warm: Boolean) {
    val stamp = System.currentTimeMillis()
    val phasesFile = File(dataDir, "phases-$stamp.txt")
    val tb = System.nanoTime()
    k32 = Native.load("kernel32", K32::class.java)          // loads JNA's own native library (one-time unpack)
    phasesFile.appendText("jna_boot_ms=%.1f warmup=%s\n".format((System.nanoTime() - tb) / 1e6, warm))
    val header = if (warm) warmUp() else null
    val c = warmConn ?: openStore()
    val rows = ArrayList<DoubleArray>()
    for (i in 1..n) {
        val ph = if (i <= 3) LinkedHashMap<String, Double>() else null
        val io0 = if (i <= 3) io() else null
        val t0 = System.nanoTime(); closeBillTx(c)
        val t1 = System.nanoTime(); printRaw(ph)
        val t2 = System.nanoTime()
        rows.add(doubleArrayOf((t1 - t0) / 1e6, (t2 - t1) / 1e6, (t2 - t0) / 1e6))
        if (io0 != null && ph != null) {
            val io1 = io()
            phasesFile.appendText("run %d db=%.1f %s read_bytes=%d write_bytes=%d read_ops=%d write_ops=%d\n".format(
                i, (t1 - t0) / 1e6, ph.entries.joinToString(" ") { "%s=%.1f".format(it.key, it.value) },
                io1.readBytes - io0.readBytes, io1.writeBytes - io0.writeBytes, io1.readOps - io0.readOps, io1.writeOps - io0.writeOps))
        }
    }
    c.close()
    val tot = rows.map { it[2] }.sorted()
    fun pct(p: Double) = tot[((p * tot.size).toInt()).coerceAtMost(tot.size - 1)]
    val out = File(dataDir, "bench-$stamp.txt")
    out.writeText(buildString {
        if (header != null) append(header).append('\n')
        rows.forEachIndexed { i, r -> append("%d %.3f %.3f %.3f\n".format(i + 1, r[0], r[1], r[2])) }
        append("max %.3f\np95 %.3f\np50 %.3f\n".format(tot.last(), pct(0.95), pct(0.50)))
    })
}

fun killLoop() {
    val c = openStore()
    var n = 0L
    while (true) {
        closeBillTx(c); n++
        File(dataDir, "killloop.txt").writeText(n.toString())
    }
}

// An exception escaping main() makes the jpackage launcher show a blocking "Failed to launch JVM" dialog (A-F2):
// headless modes write the error to error.txt and exit 1 instead.
fun guarded(mode: String, body: () -> Unit) {
    runCatching(body).onFailure {
        File(dataDir, "error.txt").appendText("$mode ${System.currentTimeMillis()} ${it::class.simpleName}: ${it.message}\n")
        exitProcess(1)
    }
}

fun main(args: Array<String>) {
    when (args.firstOrNull()) {
        "--close-bench" -> { guarded("bench") { bench(args[1].toInt(), args.getOrNull(2) == "--warmup") }; exitProcess(0) }
        "--print-once" -> {
            val r = runCatching { printRaw() }
            File(dataDir, "print.txt").appendText(r.fold({ "ok\n" }, { "error ${it.message}\n" }))
            exitProcess(if (r.isSuccess) 0 else 1)
        }
        "--kill-loop" -> guarded("killloop") { killLoop() }
        "--check" -> {
            val line = runCatching { checkStore() }.getOrElse { "open-failed: ${it.message}" }
            File(dataDir, "check.txt").appendText(line + "\n")
            exitProcess(0)
        }
    }
    val procStart = ProcessHandle.current().info().startInstant().map { it.toEpochMilli() }.orElse(-1L)
    var painted = false
    application {
        Window(onCloseRequest = ::exitApplication, title = "Kodeebo spike A") {
            var label by remember { mutableStateOf("Close bill") }
            Column(Modifier.fillMaxSize().background(Color.White).drawWithContent {
                drawContent()
                if (!painted) {
                    painted = true
                    val now = System.currentTimeMillis()
                    Thread { File(dataDir, "ready.txt").appendText("pid=${ProcessHandle.current().pid()} proc_start_ms=$procStart first_frame_ms=$now\n") }.start()
                }
            }) {
                Box(Modifier.padding(8.dp).background(Color(0xFF2E7D32)).clickable {
                    label = "…"
                    Thread {
                        val t0 = System.nanoTime()
                        val r = runCatching { openStore().use { closeBillTx(it) }; printRaw() }
                        val ms = (System.nanoTime() - t0) / 1e6
                        label = r.fold({ "Close bill (last %.0f ms)".format(ms) }, { "Close bill failed: ${it.message}" })
                    }.start()
                }.padding(12.dp)) { BasicText(label) }
                LazyColumn(Modifier.fillMaxSize()) {
                    items(200) { i -> BasicText("Station ${i + 1} — 0:%02d — EGP %d.00".format(i % 60, 25 + i), Modifier.padding(horizontal = 12.dp, vertical = 4.dp)) }
                }
            }
        }
    }
}
