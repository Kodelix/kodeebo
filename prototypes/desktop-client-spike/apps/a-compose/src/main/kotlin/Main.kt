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

// ---------- store (SPEC.md "The store"; round 4 rules: README "Round 4") ----------
val SCHEMA_MAX = System.getProperty("kspike.schema", "1").toInt()   // 1.0.1 = 1, 1.0.2 = 2 (gradle -PschemaMax)
fun f(name: String) = File(dataDir, name)
val STORE get() = f("store.db")
val COPY get() = f("store.db.premigrate")
val COPY_TMP get() = f("store.db.premigrate.tmp")
// a line written and synced to disk before returning (round 3 G4.5: unsynced lines vanish in a power cut)
fun appendSync(name: String, s: String) = java.io.FileOutputStream(f(name), true).use { it.write(s.toByteArray()); it.fd.sync() }
fun event(name: String, detail: String = "") =
    appendSync("events.txt", "event=$name ms=${System.currentTimeMillis()} app=${System.getProperty("kspike.version")} $detail\n")
class Refused(msg: String) : Exception(msg)
// hold point (round 4 G5.1): if hold.txt names this point, record it on disk and wait for the power cut
fun hold(point: String) {
    val want = runCatching { f("hold.txt").readText().trim() }.getOrNull() ?: return
    if (want != point) return
    appendSync("hold-reached.txt", "point=$point ms=${System.currentTimeMillis()} pid=${ProcessHandle.current().pid()}\n")
    while (true) Thread.sleep(60_000)
}
fun fsyncFile(file: File) = java.io.RandomAccessFile(file, "rw").use { it.fd.sync() }
fun hex(b: ByteArray) = b.joinToString("") { "%02x".format(it) }
// The key must be applied by the driver while it opens the connection (A-F1): a "PRAGMA hexkey" sent after
// DriverManager.getConnection() works only on a new file; every later process then gets SQLITE_NOTADB.
fun openRaw(key: ByteArray, file: File = STORE): Connection {
    if (!file.exists()) throw Refused("no file ${file.name}")       // the driver would create an empty file otherwise
    val c = SQLiteMCConfig.Builder().withHexKey(key).build().createConnection("jdbc:sqlite:" + file.path)
    try {
        c.createStatement().use { s ->
            s.executeQuery("SELECT count(*) FROM sqlite_master").use { it.next() }   // verifies the key
            s.execute("PRAGMA journal_mode=DELETE")
            s.execute("PRAGMA synchronous=FULL")
            s.execute("PRAGMA temp_store=MEMORY")
        }
    } catch (e: Exception) { c.close(); throw e }
    return c
}
fun Connection.exec(sql: String) = createStatement().use { it.execute(sql) }
fun Connection.userVersion(): Int = createStatement().use { s -> s.executeQuery("PRAGMA user_version").use { it.next(); it.getInt(1) } }
fun Connection.integrity(): String = createStatement().use { s -> s.executeQuery("PRAGMA integrity_check").use { r -> buildList { while (r.next()) add(r.getString(1)) }.joinToString("|") } }
fun schema2(c: Connection) {
    c.exec("ALTER TABLE bill ADD COLUMN shift_id INTEGER")
    hold("mid-transaction")
    c.exec("CREATE TABLE shift(id INTEGER PRIMARY KEY, opened_ms INTEGER, closed_ms INTEGER)")
    c.exec("CREATE INDEX bill_shift ON bill(shift_id)")
}
fun openStore(): Connection {
    if (f("quarantine.txt").exists()) { event("store_quarantined_refused"); throw Refused("store quarantined: recovery from the server needed") }
    val keyFile = f("key.bin"); val idFile = f("store.id")
    if (!STORE.exists()) {
        // TS-06c: a store existed once (store.id) -> never start again as a new install
        if (idFile.exists()) { event("store_missing", "store.id=${idFile.readText().trim()}"); throw Refused("store missing: re-bootstrap from the server needed") }
        if (keyFile.exists()) { event("store_missing_key_present"); throw Refused("key present but no store: refusing to start as a new install") }
        keyFile.writeBytes(ByteArray(32).also { SecureRandom().nextBytes(it) }); fsyncFile(keyFile)
        SQLiteMCConfig.Builder().withHexKey(keyFile.readBytes()).build().createConnection("jdbc:sqlite:" + STORE.path).use { c ->
            c.exec("PRAGMA journal_mode=DELETE"); c.exec("PRAGMA synchronous=FULL")
            c.exec("CREATE TABLE bill(id INTEGER PRIMARY KEY, opened_ms INTEGER, closed_ms INTEGER, total_piastres INTEGER)")
            c.exec("CREATE TABLE bill_line(id INTEGER PRIMARY KEY, bill_id INTEGER, name TEXT, qty INTEGER, price_piastres INTEGER)")
            c.exec("CREATE TABLE payment(id INTEGER PRIMARY KEY, bill_id INTEGER, method TEXT, amount_piastres INTEGER)")
            c.exec("CREATE TABLE outbox(seq INTEGER PRIMARY KEY, bill_id INTEGER, payload TEXT)")
            if (SCHEMA_MAX >= 2) schema2(c)
            c.exec("PRAGMA user_version=$SCHEMA_MAX")
        }
        idFile.writeText(hex(ByteArray(8).also { SecureRandom().nextBytes(it) })); fsyncFile(idFile)
        event("store_created", "schema=$SCHEMA_MAX")
    }
    if (!keyFile.exists()) { event("key_missing"); throw Refused("store present but key.bin missing") }
    val key = keyFile.readBytes()
    // G5-F4: SQLite replays a hot journal inside the open, before any check; keep the pre-open state aside first
    val jf = f("store.db-journal")
    val pre = if (jf.exists()) f("prejournal-${System.currentTimeMillis()}").also { d ->
        d.mkdirs()
        for (n in listOf("store.db", "store.db-journal")) { f(n).copyTo(File(d, n)); fsyncFile(File(d, n)) }
        event("hot_journal_found", "copy=${d.name} journal_bytes=${jf.length()}")
    } else null
    val c = try { openRaw(key) } catch (e: Exception) {
        // wrong key and a damaged page 1 look the same here (both "not a database"): keep the file aside, never touch it
        val d = f("damaged-${System.currentTimeMillis()}").apply { mkdirs() }; STORE.copyTo(File(d, "store.db"))
        event("store_open_failed", "key_bytes=${key.size} copy=${d.name} pre_open_copy=${pre?.name ?: "none"} err=\"${e.message}\"")
        throw Refused("store cannot be opened (wrong key or damaged page 1): ${e.message}")
    }
    if (!idFile.exists()) { idFile.writeText(hex(ByteArray(8).also { SecureRandom().nextBytes(it) })); fsyncFile(idFile) }   // stores from rounds 1-3
    if (pre != null) {   // after a replayed journal: verify before the copy goes; a failed check keeps it and quarantines
        val iv = runCatching { c.integrity() }.getOrElse { "threw: ${it.message}" }
        if (iv != "ok") { c.close(); quarantine("after hot-journal replay: $iv; pre-open copy in ${pre.name}"); throw Refused("store damaged after journal replay: recovery from the server needed") }
        pre.deleteRecursively(); event("hot_journal_replayed_ok", "copy removed=${pre.name}")
    }
    return migrate(c, key)
}
// M1 migration, SC-21a design (followups section 4.2): copy aside, one transaction, verify, delete the copy
fun migrate(c0: Connection, key: ByteArray): Connection {
    var c = c0
    var v = c.userVersion().let { if (it == 0) 1 else it }      // stores from rounds 1-3 have user_version 0 = schema 1
    val found = "found user_version=$v copy=${COPY.exists()} copy_tmp=${COPY_TMP.exists()} journal_after_open=${f("store.db-journal").exists()}"
    if (v > SCHEMA_MAX) { c.close(); event("store_newer_than_app", "schema=$v app_max=$SCHEMA_MAX"); throw Refused("store schema $v is newer than this app (max $SCHEMA_MAX)") }
    if (COPY_TMP.exists()) { COPY_TMP.delete(); appendSync("migration.txt", "${System.currentTimeMillis()} removed incomplete copy (cut during the copy)\n") }
    if (COPY.exists()) {
        val ok = runCatching { c.integrity() == "ok" }.getOrDefault(false)
        if (ok && v == SCHEMA_MAX) { COPY.delete(); appendSync("migration.txt", "${System.currentTimeMillis()} $found integrity=ok -> migration was committed; copy removed now\n") }
        else if (ok) { COPY.delete(); appendSync("migration.txt", "${System.currentTimeMillis()} $found integrity=ok -> store still schema $v; copy removed, migrating again\n") }
        else {
            c.close(); COPY.copyTo(STORE, overwrite = true); fsyncFile(STORE)
            appendSync("migration.txt", "${System.currentTimeMillis()} $found integrity=FAILED -> store restored from the copy\n")
            c = openRaw(key); v = c.userVersion().let { if (it == 0) 1 else it }
        }
    }
    if (v >= SCHEMA_MAX) { appendSync("migration.txt", "${System.currentTimeMillis()} $found -> no migration (schema $v)\n"); return c }
    val t0 = System.nanoTime()
    appendSync("migration.txt", "${System.currentTimeMillis()} $found -> migrating $v to $SCHEMA_MAX\n")
    hold("before-copy")
    val buf = STORE.readBytes()
    java.io.FileOutputStream(COPY_TMP).use { o ->
        val half = buf.size / 2
        o.write(buf, 0, half); o.flush()
        hold("during-copy")
        o.write(buf, half, buf.size - half)
        o.fd.sync()
    }
    check(COPY_TMP.renameTo(COPY)) { "rename of the copy failed" }
    hold("after-copy")
    c.exec("BEGIN IMMEDIATE")
    try { schema2(c); c.exec("PRAGMA user_version=$SCHEMA_MAX"); c.exec("COMMIT") }
    catch (e: Exception) { runCatching { c.exec("ROLLBACK") }; throw e }
    hold("after-commit")
    val iv = c.integrity(); val nv = c.userVersion()
    check(iv == "ok" && nv == SCHEMA_MAX) { "migration verify failed: integrity=$iv user_version=$nv" }
    check(COPY.delete()) { "copy delete failed" }
    hold("after-delete")
    appendSync("migration.txt", "${System.currentTimeMillis()} migrated to $SCHEMA_MAX in %.1f ms; verified; copy removed\n".format((System.nanoTime() - t0) / 1e6))
    return c
}
// TS-03c: a store that fails its check after a good key is kept aside, never written over, and quarantined
fun quarantine(why: String) {
    val d = f("damaged-${System.currentTimeMillis()}").apply { mkdirs() }
    for (n in listOf("store.db", "store.db-journal")) if (f(n).exists()) f(n).copyTo(File(d, n))
    appendSync("quarantine.txt", "${System.currentTimeMillis()} $why\n")
    event("store_damaged_quarantined", "copy=${d.name} why=\"${why.take(200)}\"")
}
fun outboxSha(c: Connection): String {
    val md = java.security.MessageDigest.getInstance("SHA-256")
    c.createStatement().use { s -> s.executeQuery("SELECT seq, bill_id, payload FROM outbox ORDER BY seq").use { r ->
        while (r.next()) md.update("${r.getLong(1)}|${r.getLong(2)}|${r.getString(3)}\n".toByteArray())
    } }
    return hex(md.digest()).take(16)
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
    val integrity = try { c.integrity() } catch (e: Exception) {
        c.close(); quarantine("integrity_check threw: ${e.message}"); throw Refused("store damaged: ${e.message}")
    }
    if (integrity != "ok") { c.close(); quarantine("integrity_check: ${integrity.take(200)}"); throw Refused("store damaged: integrity_check failed") }
    val bad = one("""SELECT count(*) FROM bill b WHERE
        (SELECT count(*) FROM bill_line l WHERE l.bill_id=b.id)<>5 OR
        (SELECT count(*) FROM payment p WHERE p.bill_id=b.id)<>1 OR
        (SELECT count(*) FROM outbox o WHERE o.bill_id=b.id)<>1 OR
        b.total_piastres <> (SELECT coalesce(sum(qty*price_piastres),0) FROM bill_line l WHERE l.bill_id=b.id)""").toInt()
    val orphans = one("""SELECT (SELECT count(*) FROM bill_line WHERE bill_id NOT IN (SELECT id FROM bill)) +
        (SELECT count(*) FROM payment WHERE bill_id NOT IN (SELECT id FROM bill)) +
        (SELECT count(*) FROM outbox WHERE bill_id NOT IN (SELECT id FROM bill))""").toInt()
    val line = "integrity=$integrity bills=${one("SELECT count(*) FROM bill")} lines=${one("SELECT count(*) FROM bill_line")} " +
        "payments=${one("SELECT count(*) FROM payment")} outbox=${one("SELECT count(*) FROM outbox")} consistent=${bad == 0 && orphans == 0}" +
        " schema=${c.userVersion().let { if (it == 0) 1 else it }} outbox_sha=${outboxSha(c)} app=${System.getProperty("kspike.version")}"
    c.close()
    return line
}

// TS-05b: n opens with random wrong keys in one process; none may return a row or change the file
fun keyAttempts(n: Int) {
    var opened = 0; var failed = 0; var firstErr = ""
    repeat(n) {
        runCatching { openRaw(ByteArray(32).also { k -> SecureRandom().nextBytes(k) }).close(); opened++ }
            .onFailure { failed++; if (firstErr.isEmpty()) firstErr = it.message ?: it::class.simpleName.orEmpty() }
    }
    event("key_attempts", "n=$n opened=$opened failed=$failed err=\"$firstErr\"")
    f("keyattempts.txt").appendText("n=$n opened=$opened failed=$failed err=$firstErr\n")
}

// TS-03c journal leg: a transaction big enough that SQLite writes uncommitted pages into store.db before COMMIT (cache of
// 2 pages), stopped at hold point 'spill-before-commit', so a power cut leaves a hot journal that the next open must use
fun spillHold() {
    val c = openStore()
    c.exec("PRAGMA cache_size=2")
    c.exec("BEGIN IMMEDIATE")
    c.exec("CREATE TABLE IF NOT EXISTS spill(id INTEGER PRIMARY KEY, pad TEXT)")
    c.exec("UPDATE bill SET total_piastres = total_piastres")    // touches the bill pages too
    c.prepareStatement("INSERT INTO spill(pad) VALUES (?)").use { p -> repeat(1000) { p.setString(1, "x".repeat(400)); p.executeUpdate() } }
    val j = f("store.db-journal")
    appendSync("spill.txt", "spilled ms=${System.currentTimeMillis()} store_bytes=${STORE.length()} journal_bytes=${if (j.exists()) j.length() else 0}\n")
    hold("spill-before-commit")
    c.exec("ROLLBACK")    // without a hold: undo, the store keeps no spill table
    c.close()
}

// TS-03c / TS-06c "while it runs": hold the store open and read it every 2 s; on a failed read, quarantine and stop
fun serve(seconds: Int) {
    val c = openStore()
    val end = System.currentTimeMillis() + seconds * 1000L
    f("serve.txt").appendText("start pid=${ProcessHandle.current().pid()} ms=${System.currentTimeMillis()}\n")
    while (System.currentTimeMillis() < end) {
        val r = runCatching { c.integrity().also { if (it == "ok") c.createStatement().use { s -> s.executeQuery("SELECT sum(total_piastres) FROM bill").use { q -> q.next() } } } }
            .getOrElse { "threw: ${it.message}" }
        if (r != "ok") {
            f("serve.txt").appendText("read failed ms=${System.currentTimeMillis()} $r\n"); runCatching { c.close() }
            quarantine("while serving: $r"); return
        }
        f("serve.txt").appendText("ok ms=${System.currentTimeMillis()} store_exists=${STORE.exists()}\n")
        Thread.sleep(2000)
    }
    c.close()
    f("serve.txt").appendText("end ms=${System.currentTimeMillis()}\n")
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
        // round 3 (G4): version check and self-update (start the installer detached, then exit so files are free)
        "--version" -> {
            File(dataDir, "version.txt").appendText("version=${System.getProperty("kspike.version", "unknown")} pid=${ProcessHandle.current().pid()} ms=${System.currentTimeMillis()}\n")
            exitProcess(0)
        }
        "--self-update" -> guarded("selfupdate") {
            val msi = args[1]
            val log = File(dataDir, "selfupdate-msi-${System.currentTimeMillis()}.log").path
            // cmd /c start "" ... returns at once; msiexec keeps running after this process exits
            ProcessBuilder("cmd.exe", "/c", "start", "\"\"", "msiexec.exe", "/i", msi, "/qn", "/l*v", log).start().waitFor()
            File(dataDir, "selfupdate.txt").appendText("started msiexec for $msi at ${System.currentTimeMillis()} from version ${System.getProperty("kspike.version")}\n")
            exitProcess(0)
        }
        "--key-attempts" -> { guarded("keyattempts") { keyAttempts(args[1].toInt()) }; exitProcess(0) }   // round 4 G5.2
        "--serve" -> { guarded("serve") { serve(args[1].toInt()) }; exitProcess(0) }                       // round 4 G5.3/G5.4
        "--spill-hold" -> { guarded("spill") { spillHold() }; exitProcess(0) }                            // round 4 G5.3 journal leg
        "--arabic" -> { arabicSheet(bundledFont = true); return }           // round 2 G3 (ArabicSheet.kt)
        "--arabic-system" -> { arabicSheet(bundledFont = false); return }
        "--check" -> {
            val line = runCatching { checkStore() }.getOrElse { "open-failed: ${it.message}" }
            File(dataDir, "check.txt").appendText(line + "\n")
            exitProcess(0)
        }
    }
    val procStart = ProcessHandle.current().info().startInstant().map { it.toEpochMilli() }.orElse(-1L)
    var painted = false
    application {
        Window(onCloseRequest = ::exitApplication, title = "Kodeebo spike A ${System.getProperty("kspike.version", "")}") {
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
