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

// ---------- store (SPEC.md "The store") ----------
let Database = null;
function openStore() {
  Database = Database || require('better-sqlite3-multiple-ciphers');
  const keyFile = path.join(dataDir, 'key.bin');
  if (!fs.existsSync(keyFile)) fs.writeFileSync(keyFile, crypto.randomBytes(32));
  const hex = fs.readFileSync(keyFile).toString('hex');
  const db = new Database(path.join(dataDir, 'store.db'));
  db.pragma(`hexkey='${hex}'`);                       // first statement after open (A-F1)
  db.prepare('SELECT count(*) AS n FROM sqlite_master').get();   // verifies the key
  db.pragma('journal_mode=DELETE');
  db.pragma('synchronous=FULL');
  db.pragma('temp_store=MEMORY');
  db.exec(`CREATE TABLE IF NOT EXISTS bill(id INTEGER PRIMARY KEY, opened_ms INTEGER, closed_ms INTEGER, total_piastres INTEGER);
           CREATE TABLE IF NOT EXISTS bill_line(id INTEGER PRIMARY KEY, bill_id INTEGER, name TEXT, qty INTEGER, price_piastres INTEGER);
           CREATE TABLE IF NOT EXISTS payment(id INTEGER PRIMARY KEY, bill_id INTEGER, method TEXT, amount_piastres INTEGER);
           CREATE TABLE IF NOT EXISTS outbox(seq INTEGER PRIMARY KEY, bill_id INTEGER, payload TEXT);`);
  return db;
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

function checkStore() {
  const db = openStore();
  const one = (sql) => Object.values(db.prepare(sql).get())[0];
  const integrity = db.pragma('integrity_check').map((r) => r.integrity_check).join('|');
  const bad = one(`SELECT count(*) FROM bill b WHERE
      (SELECT count(*) FROM bill_line l WHERE l.bill_id=b.id)<>5 OR
      (SELECT count(*) FROM payment p WHERE p.bill_id=b.id)<>1 OR
      (SELECT count(*) FROM outbox o WHERE o.bill_id=b.id)<>1 OR
      b.total_piastres <> (SELECT coalesce(sum(qty*price_piastres),0) FROM bill_line l WHERE l.bill_id=b.id)`);
  const orphans = one(`SELECT (SELECT count(*) FROM bill_line WHERE bill_id NOT IN (SELECT id FROM bill)) +
      (SELECT count(*) FROM payment WHERE bill_id NOT IN (SELECT id FROM bill)) +
      (SELECT count(*) FROM outbox WHERE bill_id NOT IN (SELECT id FROM bill))`);
  const line = `integrity=${integrity} bills=${one('SELECT count(*) FROM bill')} lines=${one('SELECT count(*) FROM bill_line')} ` +
    `payments=${one('SELECT count(*) FROM payment')} outbox=${one('SELECT count(*) FROM outbox')} consistent=${bad === 0 && orphans === 0}`;
  db.close();
  return line;
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
const mode = args.find((a) => ['--close-bench', '--print-once', '--kill-loop', '--check', '--arabic', '--arabic-system', '--version', '--self-update'].includes(a));
if (mode === '--close-bench') {
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
