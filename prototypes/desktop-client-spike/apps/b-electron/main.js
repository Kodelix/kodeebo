// PROTOTYPE - NOT FOR PRODUCTION
// Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
// Date: 2026-10-17
// Behaviour: ../SPEC.md (same modes, store, print, warm-up and instrumentation as A).
'use strict';
const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

const RT = 'b';
const dataDir = path.join(process.env.LOCALAPPDATA, 'KodeeboSpike', RT);
fs.mkdirSync(dataDir, { recursive: true });
const PRINTER = 'KSPIKE-SINK';
const now = () => Number(process.hrtime.bigint()) / 1e6;   // monotonic ms
const append = (f, s) => fs.appendFileSync(path.join(dataDir, f), s);

// ---------- store (SPEC.md "The store"; round 4 rules: README "Round 4") ----------
let Database = null;
const pkg = require('./package.json');
const SCHEMA_MAX = Number(pkg.kspikeSchema || 1);    // 1.0.1 = 1, 1.0.2 = 2 (set per build: -c.extraMetadata.kspikeSchema)
const P = (f) => path.join(dataDir, f);
const STORE = P('store.db'), COPY = P('store.db.premigrate'), COPY_TMP = P('store.db.premigrate.tmp');
// a line written and synced to disk before returning (round 3 G4.5: unsynced lines vanish in a power cut)
function appendSync(f, s) { const fd = fs.openSync(P(f), 'a'); try { fs.writeSync(fd, s); fs.fsyncSync(fd); } finally { fs.closeSync(fd); } }
function event(name, detail) { appendSync('events.txt', `event=${name} ms=${Date.now()} app=${app.getVersion()} ${detail || ''}\n`); }
class Refused extends Error {}
// hold point (round 4 G5.1): if hold.txt names this point, record it on disk and wait for the power cut
function hold(point) {
  let want = '';
  try { want = fs.readFileSync(P('hold.txt'), 'utf8').trim(); } catch (_) { return; }
  if (want !== point) return;
  appendSync('hold-reached.txt', `point=${point} ms=${Date.now()} pid=${process.pid}\n`);
  for (;;) Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 60000);
}
function fsyncFile(f) { const fd = fs.openSync(f, 'r+'); try { fs.fsyncSync(fd); } finally { fs.closeSync(fd); } }
function openRaw(hex, file) {
  const db = new Database(file || STORE, { fileMustExist: true });
  try {
    db.pragma(`hexkey='${hex}'`);                       // first statement after open (A-F1)
    db.prepare('SELECT count(*) AS n FROM sqlite_master').get();   // verifies the key
  } catch (e) { db.close(); throw e; }
  db.pragma('journal_mode=DELETE');
  db.pragma('synchronous=FULL');
  db.pragma('temp_store=MEMORY');
  return db;
}
const userVersion = (db) => Number(db.pragma('user_version', { simple: true }));
const integrity = (db) => db.pragma('integrity_check').map((r) => r.integrity_check).join('|');
function openStore() {
  Database = Database || require('better-sqlite3-multiple-ciphers');
  if (fs.existsSync(P('quarantine.txt'))) { event('store_quarantined_refused'); throw new Refused('store quarantined: recovery from the server needed'); }
  const keyFile = P('key.bin'), idFile = P('store.id');
  const storeExists = fs.existsSync(STORE);
  if (!storeExists) {
    // TS-06c: a store existed once (store.id) -> never start again as a new install
    if (fs.existsSync(idFile)) { event('store_missing', `store.id=${fs.readFileSync(idFile, 'utf8').trim()}`); throw new Refused('store missing: re-bootstrap from the server needed'); }
    if (fs.existsSync(keyFile)) { event('store_missing_key_present'); throw new Refused('key present but no store: refusing to start as a new install'); }
    // new install: key, then the store at schema SCHEMA_MAX, then store.id
    fs.writeFileSync(keyFile, crypto.randomBytes(32)); fsyncFile(keyFile);
    const db0 = new Database(STORE);
    db0.pragma(`hexkey='${fs.readFileSync(keyFile).toString('hex')}'`);
    db0.pragma('journal_mode=DELETE'); db0.pragma('synchronous=FULL');
    db0.exec(`CREATE TABLE bill(id INTEGER PRIMARY KEY, opened_ms INTEGER, closed_ms INTEGER, total_piastres INTEGER);
              CREATE TABLE bill_line(id INTEGER PRIMARY KEY, bill_id INTEGER, name TEXT, qty INTEGER, price_piastres INTEGER);
              CREATE TABLE payment(id INTEGER PRIMARY KEY, bill_id INTEGER, method TEXT, amount_piastres INTEGER);
              CREATE TABLE outbox(seq INTEGER PRIMARY KEY, bill_id INTEGER, payload TEXT);`);
    if (SCHEMA_MAX >= 2) schema2(db0);
    db0.pragma(`user_version=${SCHEMA_MAX}`); db0.close();
    fs.writeFileSync(idFile, crypto.randomBytes(8).toString('hex')); fsyncFile(idFile);
    event('store_created', `schema=${SCHEMA_MAX}`);
  }
  if (!fs.existsSync(keyFile)) { event('key_missing'); throw new Refused('store present but key.bin missing'); }
  const key = fs.readFileSync(keyFile);
  let db;
  try { db = openRaw(key.toString('hex')); }
  catch (e) {
    // wrong key and a damaged page 1 look the same here (both "not a database"): keep the file aside, never touch it
    const d = P(`damaged-${Date.now()}`); fs.mkdirSync(d); fs.copyFileSync(STORE, path.join(d, 'store.db'));
    event('store_open_failed', `key_bytes=${key.length} copy=${path.basename(d)} err=${JSON.stringify(e.message)}`);
    throw new Refused(`store cannot be opened (wrong key or damaged page 1): ${e.message}`);
  }
  if (!fs.existsSync(idFile)) { fs.writeFileSync(idFile, crypto.randomBytes(8).toString('hex')); fsyncFile(idFile); }  // stores from rounds 1-3
  return migrate(db, key.toString('hex'));
}
function schema2(db) {
  db.exec('ALTER TABLE bill ADD COLUMN shift_id INTEGER');
  hold('mid-transaction');
  db.exec('CREATE TABLE shift(id INTEGER PRIMARY KEY, opened_ms INTEGER, closed_ms INTEGER); CREATE INDEX bill_shift ON bill(shift_id);');
}
// M1 migration, SC-21a design (followups section 4.2): copy aside, one transaction, verify, delete the copy
function migrate(db, hex) {
  let v = userVersion(db) || 1;                          // stores from rounds 1-3 have user_version 0 = schema 1
  const found = `found user_version=${v} copy=${fs.existsSync(COPY)} copy_tmp=${fs.existsSync(COPY_TMP)} journal_after_open=${fs.existsSync(STORE + '-journal')}`;
  if (v > SCHEMA_MAX) { db.close(); event('store_newer_than_app', `schema=${v} app_max=${SCHEMA_MAX}`); throw new Refused(`store schema ${v} is newer than this app (max ${SCHEMA_MAX})`); }
  if (fs.existsSync(COPY_TMP)) { fs.unlinkSync(COPY_TMP); appendSync('migration.txt', `${Date.now()} removed incomplete copy (cut during the copy)\n`); }
  if (fs.existsSync(COPY)) {
    let ok; try { ok = integrity(db) === 'ok'; } catch (_) { ok = false; }
    if (ok && v === SCHEMA_MAX) { fs.unlinkSync(COPY); appendSync('migration.txt', `${Date.now()} ${found} integrity=ok -> migration was committed; copy removed now\n`); }
    else if (ok) { fs.unlinkSync(COPY); appendSync('migration.txt', `${Date.now()} ${found} integrity=ok -> store still schema ${v}; copy removed, migrating again\n`); }
    else {
      db.close(); fs.copyFileSync(COPY, STORE); fsyncFile(STORE);
      appendSync('migration.txt', `${Date.now()} ${found} integrity=FAILED -> store restored from the copy\n`);
      db = openRaw(hex); v = userVersion(db) || 1;
    }
  }
  if (v >= SCHEMA_MAX) { appendSync('migration.txt', `${Date.now()} ${found} -> no migration (schema ${v})\n`); return db; }
  const t0 = now();
  appendSync('migration.txt', `${Date.now()} ${found} -> migrating ${v} to ${SCHEMA_MAX}\n`);
  hold('before-copy');
  const buf = fs.readFileSync(STORE);
  const fd = fs.openSync(COPY_TMP, 'w');
  try {
    const half = Math.floor(buf.length / 2);
    fs.writeSync(fd, buf, 0, half);
    hold('during-copy');
    fs.writeSync(fd, buf, half, buf.length - half);
    fs.fsyncSync(fd);
  } finally { fs.closeSync(fd); }
  fs.renameSync(COPY_TMP, COPY);
  hold('after-copy');
  db.exec('BEGIN IMMEDIATE');
  try { schema2(db); db.pragma(`user_version=${SCHEMA_MAX}`); db.exec('COMMIT'); }
  catch (e) { try { db.exec('ROLLBACK'); } catch (_) { /* rolled back */ } throw e; }
  hold('after-commit');
  const iv = integrity(db), nv = userVersion(db);
  if (iv !== 'ok' || nv !== SCHEMA_MAX) throw new Error(`migration verify failed: integrity=${iv} user_version=${nv}`);
  fs.unlinkSync(COPY);
  hold('after-delete');
  appendSync('migration.txt', `${Date.now()} migrated to ${SCHEMA_MAX} in ${(now() - t0).toFixed(1)} ms; verified; copy removed\n`);
  return db;
}
// TS-03c: a store that fails its check after a good key is kept aside, never written over, and quarantined
function quarantine(why) {
  const d = P(`damaged-${Date.now()}`); fs.mkdirSync(d);
  for (const f of ['store.db', 'store.db-journal']) if (fs.existsSync(P(f))) fs.copyFileSync(P(f), path.join(d, f));
  appendSync('quarantine.txt', `${Date.now()} ${why}\n`);
  event('store_damaged_quarantined', `copy=${path.basename(d)} why=${JSON.stringify(why)}`);
}

function closeBillTx(db) {
  const t = Date.now();
  const prices = [2500, 1500, 3000, 1000, 4500];
  const total = prices.reduce((a, b) => a + b, 0);
  db.exec('BEGIN IMMEDIATE');
  try {
    const billId = db.prepare('INSERT INTO bill(opened_ms, closed_ms, total_piastres) VALUES (?,?,?)').run(t - 3600000, t, total).lastInsertRowid;
    const line = db.prepare('INSERT INTO bill_line(bill_id, name, qty, price_piastres) VALUES (?,?,1,?)');
    prices.forEach((p, i) => line.run(billId, `item ${i}`, p));
    db.prepare("INSERT INTO payment(bill_id, method, amount_piastres) VALUES (?,'cash',?)").run(billId, total);
    db.prepare('INSERT INTO outbox(bill_id, payload) VALUES (?,?)').run(billId, JSON.stringify({ bill: Number(billId), total }));
    db.exec('COMMIT');
  } catch (e) {
    try { db.exec('ROLLBACK'); } catch (_) { /* already rolled back */ }
    throw e;
  }
}

// SHA-256 over the queued rows' stored bytes (seq|bill_id|payload, in seq order): byte-identical across the migration
function outboxSha(db) {
  const h = crypto.createHash('sha256');
  for (const r of db.prepare('SELECT seq, bill_id, payload FROM outbox ORDER BY seq').raw().iterate()) h.update(`${r[0]}|${r[1]}|${r[2]}\n`);
  return h.digest('hex').slice(0, 16);
}
function checkStore() {
  const db = openStore();
  const one = (sql) => Object.values(db.prepare(sql).get())[0];
  let integrity;
  try { integrity = db.pragma('integrity_check').map((r) => r.integrity_check).join('|'); }
  catch (e) { db.close(); quarantine(`integrity_check threw: ${e.message}`); throw new Refused(`store damaged: ${e.message}`); }
  if (integrity !== 'ok') { db.close(); quarantine(`integrity_check: ${integrity.slice(0, 200)}`); throw new Refused('store damaged: integrity_check failed'); }
  const bad = one(`SELECT count(*) FROM bill b WHERE
      (SELECT count(*) FROM bill_line l WHERE l.bill_id=b.id)<>5 OR
      (SELECT count(*) FROM payment p WHERE p.bill_id=b.id)<>1 OR
      (SELECT count(*) FROM outbox o WHERE o.bill_id=b.id)<>1 OR
      b.total_piastres <> (SELECT coalesce(sum(qty*price_piastres),0) FROM bill_line l WHERE l.bill_id=b.id)`);
  const orphans = one(`SELECT (SELECT count(*) FROM bill_line WHERE bill_id NOT IN (SELECT id FROM bill)) +
      (SELECT count(*) FROM payment WHERE bill_id NOT IN (SELECT id FROM bill)) +
      (SELECT count(*) FROM outbox WHERE bill_id NOT IN (SELECT id FROM bill))`);
  const line = `integrity=${integrity} bills=${one('SELECT count(*) FROM bill')} lines=${one('SELECT count(*) FROM bill_line')} ` +
    `payments=${one('SELECT count(*) FROM payment')} outbox=${one('SELECT count(*) FROM outbox')} consistent=${bad === 0 && orphans === 0}` +
    ` schema=${userVersion(db) || 1} outbox_sha=${outboxSha(db)} app=${app.getVersion()}`;
  db.close();
  return line;
}

// TS-05b: n opens with random wrong keys in one process; none may return a row or change the file
function keyAttempts(n) {
  Database = Database || require('better-sqlite3-multiple-ciphers');
  let opened = 0, failed = 0, firstErr = '';
  for (let i = 0; i < n; i++) {
    try { const db = openRaw(crypto.randomBytes(32).toString('hex')); opened++; db.close(); }
    catch (e) { failed++; if (!firstErr) firstErr = e.message; }
  }
  event('key_attempts', `n=${n} opened=${opened} failed=${failed} err=${JSON.stringify(firstErr)}`);
  append('keyattempts.txt', `n=${n} opened=${opened} failed=${failed} err=${firstErr}\n`);
}

// TS-03c journal leg: a transaction big enough that SQLite writes uncommitted pages into store.db before COMMIT (cache of
// 2 pages), stopped at hold point 'spill-before-commit', so a power cut leaves a hot journal that the next open must use
function spillHold() {
  const db = openStore();
  db.pragma('cache_size=2');
  db.exec('BEGIN IMMEDIATE');
  db.exec('CREATE TABLE IF NOT EXISTS spill(id INTEGER PRIMARY KEY, pad TEXT)');
  db.exec("UPDATE bill SET total_piastres = total_piastres");   // touches the bill pages too
  const ins = db.prepare('INSERT INTO spill(pad) VALUES (?)');
  for (let i = 0; i < 1000; i++) ins.run('x'.repeat(400));
  appendSync('spill.txt', `spilled ms=${Date.now()} store_bytes=${fs.statSync(STORE).size} journal_bytes=${fs.existsSync(STORE + '-journal') ? fs.statSync(STORE + '-journal').size : 0}\n`);
  hold('spill-before-commit');
  db.exec('ROLLBACK');   // without a hold: undo, the store keeps no spill table
  db.close();
}

// TS-03c / TS-06c "while it runs": hold the store open and read it every 2 s; on a failed read, quarantine and stop
function serve(seconds) {
  const db = openStore();
  const end = Date.now() + seconds * 1000;
  append('serve.txt', `start pid=${process.pid} ms=${Date.now()}\n`);
  while (Date.now() < end) {
    let r;
    try { r = integrity(db); if (r === 'ok') db.prepare('SELECT sum(total_piastres) FROM bill').get(); }
    catch (e) { r = `threw: ${e.message}`; }
    if (r !== 'ok') { append('serve.txt', `read failed ms=${Date.now()} ${r}\n`); try { db.close(); } catch (_) { /* closed */ } quarantine(`while serving: ${r}`); return; }
    append('serve.txt', `ok ms=${Date.now()} store_exists=${fs.existsSync(STORE)}\n`);
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 2000);
  }
  db.close();
  append('serve.txt', `end ms=${Date.now()}\n`);
}

// ---------- Win32 through koffi 2.16.3 (prebuilt; koffi 3 compiles at install: B-F1) ----------
let W = null;
function win32() {
  if (W) return W;
  const koffi = require('koffi');
  const HANDLE = koffi.pointer('HANDLE', koffi.opaque());
  const DOC_INFO_1W = koffi.struct('DOC_INFO_1W', { pDocName: 'str16', pOutputFile: 'str16', pDatatype: 'str16' });
  koffi.struct('IO_COUNTERS', { readOps: 'uint64', writeOps: 'uint64', otherOps: 'uint64', readBytes: 'uint64', writeBytes: 'uint64', otherBytes: 'uint64' });
  koffi.struct('FILETIME', { lo: 'uint32', hi: 'uint32' });
  const k32 = koffi.load('kernel32.dll');
  W = {
    koffi, HANDLE, DOC_INFO_1W,
    GetLastError: k32.func('uint32 __stdcall GetLastError()'),
    GetCurrentProcess: k32.func('HANDLE __stdcall GetCurrentProcess()'),
    GetProcessIoCounters: k32.func('bool __stdcall GetProcessIoCounters(HANDLE h, _Out_ IO_COUNTERS *c)'),
    GetProcessTimes: k32.func('bool __stdcall GetProcessTimes(HANDLE h, _Out_ FILETIME *c, _Out_ FILETIME *e, _Out_ FILETIME *k, _Out_ FILETIME *u)'),
    spool: null,
  };
  return W;
}
function spool() {
  const w = win32();
  if (w.spool) return w.spool;
  const ws = w.koffi.load('winspool.drv');
  w.spool = {
    OpenPrinterW: ws.func('bool __stdcall OpenPrinterW(str16 name, _Out_ HANDLE *h, void *def)'),
    StartDocPrinterW: ws.func('uint32 __stdcall StartDocPrinterW(HANDLE h, uint32 level, DOC_INFO_1W *doc)'),
    StartPagePrinter: ws.func('bool __stdcall StartPagePrinter(HANDLE h)'),
    WritePrinter: ws.func('bool __stdcall WritePrinter(HANDLE h, void *buf, uint32 n, _Out_ uint32 *written)'),
    EndPagePrinter: ws.func('bool __stdcall EndPagePrinter(HANDLE h)'),
    EndDocPrinter: ws.func('bool __stdcall EndDocPrinter(HANDLE h)'),
    ClosePrinter: ws.func('bool __stdcall ClosePrinter(HANDLE h)'),
  };
  return w.spool;
}
let receipt = null;
function check(ok, what) { if (!ok) throw new Error(`${what} failed: ${win32().GetLastError()}`); }

// ---------- RAW print (SPEC.md "The print"), optional per-phase timing ----------
function printRaw(ph) {
  let t = now();
  const mark = (name) => { const n = now(); if (ph) ph[name] = n - t; t = n; };
  const s = spool(); receipt = receipt || fs.readFileSync(path.join(__dirname, 'receipt.bin')); mark('load_native');
  const h = [null];
  check(s.OpenPrinterW(PRINTER, h, null), 'OpenPrinterW'); mark('open_printer');
  try {
    check(s.StartDocPrinterW(h[0], 1, { pDocName: 'kodeebo spike receipt', pOutputFile: null, pDatatype: 'RAW' }) !== 0, 'StartDocPrinterW');
    check(s.StartPagePrinter(h[0]), 'StartPagePrinter'); mark('start_doc');
    const n = [0];
    check(s.WritePrinter(h[0], receipt, receipt.length, n) && n[0] === receipt.length, `WritePrinter (${n[0]} of ${receipt.length})`); mark('write');
    check(s.EndPagePrinter(h[0]), 'EndPagePrinter');
    check(s.EndDocPrinter(h[0]), 'EndDocPrinter'); mark('end_doc');
  } finally {
    s.ClosePrinter(h[0]); mark('close_printer');
  }
}

function io() { const w = win32(); const c = {}; w.GetProcessIoCounters(w.GetCurrentProcess(), c); return c; }

// ---------- warm-up (SPEC.md) ----------
let warmDb = null;
function warmUp() {
  let t = now();
  const lap = () => { const n = now(); const d = n - t; t = n; return d; };
  const db = openStore(); const open = lap();
  const s = spool(); receipt = receipt || fs.readFileSync(path.join(__dirname, 'receipt.bin'));
  const h = [null];
  check(s.OpenPrinterW(PRINTER, h, null), 'warm-up OpenPrinterW'); s.ClosePrinter(h[0]); const print = lap();
  db.exec('BEGIN IMMEDIATE'); db.exec('INSERT INTO bill(opened_ms, closed_ms, total_piastres) VALUES (0, 0, 0)'); db.exec('ROLLBACK');
  const tx = lap();
  warmDb = db;
  return `warmup_ms=${(open + print + tx).toFixed(1)} parts=${open.toFixed(1)},${print.toFixed(1)},${tx.toFixed(1)}`;
}

// ---------- modes ----------
function bench(n, warm) {
  const stamp = Date.now();
  const phasesFile = `phases-${stamp}.txt`;
  const tb = now(); win32();                                  // loads koffi's native module (counterpart of A's jna_boot)
  append(phasesFile, `ffi_boot_ms=${(now() - tb).toFixed(1)} warmup=${warm}\n`);
  const header = warm ? warmUp() : null;
  const db = warmDb || openStore();
  const rows = [];
  for (let i = 1; i <= n; i++) {
    const ph = i <= 3 ? {} : null;
    const io0 = i <= 3 ? io() : null;
    const t0 = now(); closeBillTx(db);
    const t1 = now(); printRaw(ph);
    const t2 = now();
    rows.push([t1 - t0, t2 - t1, t2 - t0]);
    if (io0) {
      const io1 = io();
      const d = (k) => Number(BigInt(io1[k]) - BigInt(io0[k]));
      append(phasesFile, `run ${i} db=${(t1 - t0).toFixed(1)} ` + Object.entries(ph).map(([k, v]) => `${k}=${v.toFixed(1)}`).join(' ') +
        ` read_bytes=${d('readBytes')} write_bytes=${d('writeBytes')} read_ops=${d('readOps')} write_ops=${d('writeOps')}\n`);
    }
  }
  db.close();
  const tot = rows.map((r) => r[2]).sort((a, b) => a - b);
  const pct = (p) => tot[Math.min(tot.length - 1, Math.floor(p * tot.length))];
  let out = header ? header + '\n' : '';
  rows.forEach((r, i) => { out += `${i + 1} ${r[0].toFixed(3)} ${r[1].toFixed(3)} ${r[2].toFixed(3)}\n`; });
  out += `max ${tot[tot.length - 1].toFixed(3)}\np95 ${pct(0.95).toFixed(3)}\np50 ${pct(0.5).toFixed(3)}\n`;
  fs.writeFileSync(path.join(dataDir, `bench-${stamp}.txt`), out);
}

function killLoop() {
  const db = openStore();
  for (let n = 1; ; n++) { closeBillTx(db); fs.writeFileSync(path.join(dataDir, 'killloop.txt'), String(n)); }
}

// Headless modes: every error goes to error.txt and exit 1 (SPEC.md).
function guarded(mode, body) {
  try { body(); return 0; } catch (e) { append('error.txt', `${mode} ${Date.now()} ${e && e.message}\n`); return 1; }
}

const args = process.argv.slice(1).filter((a) => a.startsWith('--') || /^\d+$/.test(a));
const mode = args.find((a) => ['--close-bench', '--print-once', '--kill-loop', '--check', '--arabic', '--arabic-system', '--version', '--self-update', '--key-attempts', '--serve', '--spill-hold'].includes(a));
if (mode === '--spill-hold') {
  process.exit(guarded('spill', spillHold));
} else if (mode === '--key-attempts') {
  process.exit(guarded('keyattempts', () => keyAttempts(Number(args[args.indexOf('--key-attempts') + 1]))));
} else if (mode === '--serve') {
  process.exit(guarded('serve', () => serve(Number(args[args.indexOf('--serve') + 1]))));
} else if (mode === '--close-bench') {
  const n = Number(args[args.indexOf('--close-bench') + 1]);
  process.exit(guarded('bench', () => bench(n, args.includes('--warmup'))));
} else if (mode === '--print-once') {
  let err = null;
  const code = guarded('print', () => { try { printRaw(); } catch (e) { err = e; throw e; } });
  append('print.txt', err ? `error ${err.message}\n` : 'ok\n');
  process.exit(code);
} else if (mode === '--kill-loop') {
  process.exit(guarded('killloop', killLoop));
} else if (mode === '--version') {
  // round 3 (G4): the packaged version (package.json "version", set per build)
  append('version.txt', `version=${app.getVersion()} pid=${process.pid} ms=${Date.now()}\n`);
  process.exit(0);
} else if (mode === '--self-update') {
  // round 3 (G4): start the NSIS installer detached (/S = silent), then exit so the app's files are free.
  // The path comes from the raw argv: the filter above keeps only flags and numbers.
  const inst = process.argv[process.argv.indexOf('--self-update') + 1];
  process.exit(guarded('selfupdate', () => {
    require('child_process').spawn(inst, ['/S'], { detached: true, stdio: 'ignore' }).unref();
    append('selfupdate.txt', `started ${inst} at ${Date.now()} from version ${app.getVersion()}\n`);
  }));
} else if (mode === '--check') {
  let line;
  try { line = checkStore(); } catch (e) { line = `open-failed: ${e.message}`; }
  append('check.txt', line + '\n');
  process.exit(0);
} else {
  // GUI
  ipcMain.on('painted', (_e, firstFrameMs) => {
    const w = win32(); const c = {}, x = {}, k = {}, u = {};
    w.GetProcessTimes(w.GetCurrentProcess(), c, x, k, u);
    const procStartMs = Math.round((c.hi * 4294967296 + c.lo) / 10000 - 11644473600000);
    append('ready.txt', `pid=${process.pid} proc_start_ms=${procStartMs} first_frame_ms=${firstFrameMs}\n`);
  });
  ipcMain.handle('close-bill', () => {
    const t0 = now();
    const db = openStore(); try { closeBillTx(db); } finally { db.close(); }
    printRaw();
    return now() - t0;
  });
  // round 2 G3: --arabic (bundled Naskh) / --arabic-system (Segoe UI); ../ARABIC-SHEET.md
  const arabic = mode === '--arabic' || mode === '--arabic-system';
  if (arabic) {
    ipcMain.removeAllListeners('painted');
    ipcMain.on('painted', (_e, ms) => append('ready.txt', `arabic=${mode === '--arabic' ? 'naskh' : 'system'} pid=${process.pid} shown_ms=${ms}\n`));
  }
  app.whenReady().then(() => {
    const win = new BrowserWindow({ width: 1024, height: 700, title: arabic ? `Kodeebo spike B — Arabic (${mode === '--arabic' ? 'Naskh' : 'system font'})` : `Kodeebo spike B ${app.getVersion()}`,
      webPreferences: { preload: path.join(__dirname, 'preload.js'), contextIsolation: true, nodeIntegration: false, sandbox: true } });
    win.setMenuBarVisibility(false);
    win.on('page-title-updated', (e) => e.preventDefault());   // keep the title set here (round 3 shows the version)
    if (arabic) { win.maximize(); win.loadFile(path.join(__dirname, 'arabic.html'), { hash: mode === '--arabic' ? 'naskh' : 'system' }); }
    else win.loadFile(path.join(__dirname, 'index.html'));
  });
  app.on('window-all-closed', () => app.quit());
}
