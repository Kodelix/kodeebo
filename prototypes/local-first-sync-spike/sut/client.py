# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does local-first sync ever lose or double-count money or session time under faults? (client stub, phases 0-1)
# Date: 2026-10-16
#
# Client stub driven by JSON lines on stdin, one JSON reply per line on stdout.
# Store: plain SQLite (phase 0) or SQLite3 Multiple Ciphers via apsw (phase 1, STORE=sqlite3mc).
# WAL, synchronous=FULL, temp_store=MEMORY. Correct mode writes bill + payment + minutes +
# sequence counter + outbox row in ONE transaction.
# On start the store is verified (key, then a full integrity check that reads every page). If that
# fails, the client records an event next to the database and refuses every operation; it never
# recreates or overwrites the file. A store error during operation does the same.
# Commit high-water mark (OQ28 option B): after every commit that advances the device sequence, the
# client writes <db>.hwm = {seq, MAC(key, seq)} atomically. On start a store whose sequence is lower than
# the mark (committed sales missing), a mark with a bad MAC, or a missing mark beside a non-empty store is
# refused and recorded.
# Env: MUTANT (separate_outbox_txn | double_minute), FP=name:hit (SIGKILL self at that point),
#      STORE (sqlite3mc), CIPHER (chacha20 | sqlcipher), SPIKE_DB_KEY (64 hex, test key only),
#      JOURNAL (delete = rollback journal, the OQ28 option A default | wal), CACHE_PAGES (tamper tests only).
# The spike's binding is not the product decision (README).
import hashlib
import hmac
import http.client
import json
import os
import shutil
import signal
import sys
import urllib.error
import urllib.request

DB, SERVER, DEVICE = sys.argv[1], sys.argv[2], "dev-1"
MUTANT = os.environ.get("MUTANT", "")
FP = os.environ.get("FP", "")
FP_NAME, FP_AT = (FP.rsplit(":", 1)[0], int(FP.rsplit(":", 1)[1])) if FP else ("", 0)
STORE = os.environ.get("STORE", "")
CIPHER = os.environ.get("CIPHER", "chacha20")
EVENTS = DB + ".events.jsonl"
MARKER = DB + ".hwm"
JOURNAL = os.environ.get("JOURNAL", "delete")
fp_count = 0

if STORE == "sqlite3mc":
    import apsw
    STORE_ERRORS = (apsw.Error,)
else:
    import sqlite3
    STORE_ERRORS = (sqlite3.DatabaseError,)


def failpoint(name):
    global fp_count
    if name != FP_NAME:
        return
    fp_count += 1
    if fp_count == FP_AT:
        sys.stdout.flush()
        os.kill(os.getpid(), signal.SIGKILL)


def reply(obj):
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


def record_event(kind, err, **extra):
    # Plain-text event log beside the database: kind and error class only, no business data.
    with open(EVENTS, "a") as f:
        f.write(json.dumps({"event": kind, "error": f"{type(err).__name__}: {str(err)[:160]}", **extra}) + "\n")
        f.flush()
        os.fsync(f.fileno())


class MarkerError(RuntimeError):
    pass


def _mac(seq):
    k = os.environ.get("SPIKE_DB_KEY", "")
    try:
        kb = bytes.fromhex(k)
    except ValueError:
        kb = k.encode()
    return hmac.new(kb, f"kodeebo-spike-hwm:{seq}".encode(), hashlib.sha256).hexdigest()


def write_marker(seq):
    tmp = MARKER + ".tmp"
    with open(tmp, "w") as f:
        json.dump({"seq": seq, "mac": _mac(seq)}, f)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, MARKER)
    d = os.open(os.path.dirname(os.path.abspath(MARKER)), os.O_RDONLY)
    os.fsync(d)
    os.close(d)


def check_marker(c):
    seq = c.execute("SELECT seq FROM counter WHERE id = 1").fetchall()[0][0]
    if not os.path.exists(MARKER):
        if seq == 0:
            write_marker(0)  # first start of an empty store
            return
        raise MarkerError(f"commit marker missing beside a store at sequence {seq}")
    try:
        m = json.load(open(MARKER))
        mseq, mmac = int(m["seq"]), str(m["mac"])
    except (ValueError, KeyError, TypeError) as e:
        raise MarkerError(f"commit marker unreadable: {e}")
    if not hmac.compare_digest(mmac, _mac(mseq)):
        raise MarkerError("commit marker MAC invalid")
    if seq < mseq:
        raise MarkerError(f"committed sales missing: store sequence {seq} < marker {mseq}")
    if seq > mseq:
        write_marker(seq)  # crash after a commit, before its marker write: the store is ahead, which is safe


def key_pragma(hexkey):
    # Raw 256-bit key, no key derivation (SQLite3MC docs, "PRAGMA key / hexkey", example 2).
    return f"PRAGMA key = 'raw:{hexkey}'" if CIPHER == "chacha20" else f"PRAGMA key = \"x'{hexkey}'\""


def q(sql, params=()):
    return con.execute(sql, params).fetchall()


def preserve_before_recovery():
    """After a crash a hot journal or WAL makes SQLite rewrite the main file while opening it (rollback) or at
    close (checkpoint). Copy the store files aside first, so a store that then fails verification still has its
    untouched originals for recovery and evidence (spike finding P1-F3). Returns the copy's path or None."""
    if not any(os.path.exists(p) and os.path.getsize(p) > 0 for p in (DB + "-journal", DB + "-wal")):
        return None
    base = DB + ".recovery"
    os.makedirs(base, exist_ok=True)
    dest = os.path.join(base, str(len(os.listdir(base)) + 1))
    os.makedirs(dest)
    for suffix in ("", "-journal", "-wal", "-shm", ".hwm"):
        if os.path.exists(DB + suffix):
            shutil.copy2(DB + suffix, os.path.join(dest, os.path.basename(DB) + suffix))
    return dest


def open_store():
    """Open and verify the store. Returns (connection, None, copy) or (None, error, copy)."""
    copy = preserve_before_recovery()
    try:
        if STORE == "sqlite3mc":
            c = apsw.Connection(DB)
            c.set_busy_timeout(5000)
            c.execute(f"PRAGMA cipher = {CIPHER}").fetchall()
            c.execute(key_pragma(os.environ.get("SPIKE_DB_KEY", ""))).fetchall()  # answers 'ok' even for a wrong key
        else:
            c = sqlite3.connect(DB, isolation_level=None, timeout=5)
        # Verification before any write: a wrong key or a damaged page fails here.
        result = c.execute("PRAGMA integrity_check").fetchall()
        if result != [("ok",)]:
            raise RuntimeError(f"integrity_check: {result[:3]}")
        c.execute("PRAGMA temp_store=MEMORY").fetchall()
        c.execute(f"PRAGMA journal_mode={JOURNAL.upper()}").fetchall()
        if os.environ.get("CACHE_PAGES"):
            c.execute(f"PRAGMA cache_size={int(os.environ['CACHE_PAGES'])}").fetchall()
        c.execute("PRAGMA synchronous=FULL").fetchall()
        for stmt in [
            "CREATE TABLE IF NOT EXISTS bills (action_id TEXT PRIMARY KEY, session_id TEXT, sale_piasters INTEGER)",
            "CREATE TABLE IF NOT EXISTS payments (action_id TEXT, piasters INTEGER)",
            "CREATE TABLE IF NOT EXISTS minutes (action_id TEXT, session_id TEXT, minute_idx INTEGER)",
            "CREATE TABLE IF NOT EXISTS counter (id INTEGER PRIMARY KEY CHECK (id = 1), seq INTEGER NOT NULL)",
            "INSERT OR IGNORE INTO counter VALUES (1, 0)",
            "CREATE TABLE IF NOT EXISTS outbox (seq INTEGER PRIMARY KEY, command_id TEXT UNIQUE, payload TEXT, "
            "payload_hash TEXT, status TEXT NOT NULL)",
        ]:
            c.execute(stmt).fetchall()
        check_marker(c)
        if copy:
            shutil.rmtree(copy)  # verified: the crash recovery was clean, the copy is not needed
        return c, None, None
    except (*STORE_ERRORS, RuntimeError) as e:
        return None, e, copy


con, open_error, recovery_copy = open_store()
if open_error is not None:
    record_event("store_unusable_at_start", open_error, originals_preserved_in=recovery_copy)


def close_and_pay(a):
    end = a["end_min"] + 1 if MUTANT == "double_minute" else a["end_min"]  # planted off-by-one
    mins = list(range(a["start_min"], end))
    session = (len(mins) * a["rate_per_hour"] + 30) // 60  # integer piasters, half-up
    sale = session + a["cafe_piasters"]
    payload = {"action_id": a["action_id"], "session_id": a["session_id"], "minutes": mins,
               "sale_piasters": sale, "payment_piasters": sale}
    body = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    h = hashlib.sha256(body.encode()).hexdigest()
    cmd_id = "cmd-" + a["action_id"]

    def business():
        q("INSERT INTO bills VALUES (?,?,?)", (a["action_id"], a["session_id"], sale))
        q("INSERT INTO payments VALUES (?,?)", (a["action_id"], sale))
        for m in mins:
            q("INSERT INTO minutes VALUES (?,?,?)", (a["action_id"], a["session_id"], m))

    def outbox():
        seq = q("UPDATE counter SET seq = seq + 1 WHERE id = 1 RETURNING seq")[0][0]
        q("INSERT INTO outbox VALUES (?,?,?,?, 'pending')", (seq, cmd_id, body, h))
        return seq

    failpoint("client:before_local_commit")  # P1
    if MUTANT == "separate_outbox_txn":  # planted defect: two transactions
        q("BEGIN IMMEDIATE"); business(); q("COMMIT")
        failpoint("client:after_business_commit")  # P3 exists only here
        q("BEGIN IMMEDIATE"); seq = outbox(); q("COMMIT")
    else:
        q("BEGIN IMMEDIATE")
        business()
        seq = outbox()
        failpoint("client:mid_local_txn")  # P2: before COMMIT
        q("COMMIT")
    failpoint("client:after_local_commit")  # P4: committed, marker not yet written, not yet acknowledged
    write_marker(seq)
    reply({"ok": True, "op": "sale", "action_id": a["action_id"]})


def post(cmds):
    req = urllib.request.Request(SERVER + "/batch", method="POST",
                                 data=json.dumps({"device_id": DEVICE, "commands": cmds}).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read())


NET_ERRORS = (urllib.error.URLError, ConnectionError, TimeoutError, OSError, http.client.HTTPException, ValueError)


def rows_to_cmds(rows):
    return [{"command_id": c, "seq": s, "payload_hash": h, "payload": json.loads(p)} for s, c, p, h in rows]


def pending_count():
    return q("SELECT count(*) FROM outbox WHERE status = 'pending'")[0][0]


def sync():
    rows = q("SELECT seq, command_id, payload, payload_hash FROM outbox WHERE status = 'pending' ORDER BY seq LIMIT 50")
    if not rows:
        return reply({"ok": True, "op": "sync", "pending": 0})
    failpoint("client:before_send")  # P4/P5
    try:
        resp = post(rows_to_cmds(rows))
    except NET_ERRORS as e:  # a truncated or malformed reply is a failed sync (P0-F2)
        return reply({"ok": False, "op": "sync", "error": str(e)[:120], "pending": pending_count()})
    failpoint("client:after_response_before_mark")  # P10
    q("BEGIN IMMEDIATE")
    for r in resp["results"] or []:
        if r["result"] in ("applied", "duplicate"):
            q("UPDATE outbox SET status = 'acked' WHERE command_id = ?", (r["command_id"],))
        elif r["result"] in ("payload_mismatch", "seq_conflict"):
            q("UPDATE outbox SET status = 'conflict' WHERE command_id = ?", (r["command_id"],))
    failpoint("client:mid_mark")  # P11: inside the acknowledgement write, before COMMIT
    q("COMMIT")
    failpoint("client:after_mark")  # P12
    reply({"ok": True, "op": "sync", "results": resp["results"], "pending": pending_count()})


def replay(k):
    # Duplicate resend (SC-04): send the last k acknowledged commands again, unchanged.
    rows = q("SELECT seq, command_id, payload, payload_hash FROM outbox WHERE status = 'acked' "
             "ORDER BY seq DESC LIMIT ?", (k,))[::-1]
    if not rows:
        return reply({"ok": True, "op": "replay", "sent": 0})
    try:
        resp = post(rows_to_cmds(rows))
    except NET_ERRORS as e:
        return reply({"ok": False, "op": "replay", "error": str(e)[:120]})
    reply({"ok": True, "op": "replay", "sent": len(rows), "results": resp["results"]})


def verify():
    # Runtime check used by the tamper tests: full integrity check of the open store.
    result = q("PRAGMA integrity_check")
    if result != [("ok",)]:
        raise RuntimeError(f"integrity_check: {result[:3]}")
    reply({"ok": True, "op": "verify"})


def checkpoint():
    reply({"ok": True, "op": "checkpoint", "result": q("PRAGMA wal_checkpoint(TRUNCATE)")})


refused = open_error is not None
for line in sys.stdin:
    msg = json.loads(line)
    op = msg["op"]
    if op == "exit":
        if con is not None:
            con.close()
        reply({"ok": True, "op": "exit"})
        break
    if refused:
        reply({"ok": False, "op": op, "store": "refused"})
        continue
    try:
        if op == "sale":
            close_and_pay(msg)
        elif op == "sync":
            sync()
        elif op == "replay":
            replay(msg["k"])
        elif op == "verify":
            verify()
        elif op == "checkpoint":
            checkpoint()
        elif op == "count_bills":
            reply({"ok": True, "op": op, "bills": q("SELECT count(*) FROM bills")[0][0]})
        elif op == "stats":  # consistency view for the tamper tests
            reply({"ok": True, "op": op, "bills": q("SELECT count(*) FROM bills")[0][0],
                   "payments": q("SELECT count(*) FROM payments")[0][0],
                   "minute_actions": q("SELECT count(DISTINCT action_id) FROM minutes")[0][0],
                   "outbox": q("SELECT count(*) FROM outbox")[0][0],
                   "counter": q("SELECT seq FROM counter WHERE id = 1")[0][0],
                   "integrity": q("PRAGMA integrity_check")[0][0]})
    except (*STORE_ERRORS, RuntimeError) as e:
        record_event("store_error_during_operation", e)
        refused = True
        reply({"ok": False, "op": op, "store": "refused"})
