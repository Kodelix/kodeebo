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
#      JOURNAL (delete = rollback journal, the OQ28 option A default | wal), CACHE_PAGES (tamper tests only),
#      HTTP_TIMEOUT (seconds, default 10).
# Phase 3 (SC-19): RETENTION=1 applies the founder's device retention rule. An outbox row is deleted once a
# fully parsed ack arrives; the bill keeps its command id, sequence, payload bytes and hash, so a command can be
# rebuilt byte-identical. Every batch reports acked_seq (H) and low_seq (lowest retained sequence). OQ29
# provisional values (founder): a bill is pruned only if its sequence is below the server's durable watermark
# (highest sequence in a backup whose restore was verified) AND it is older than RETAIN_DAYS (60) days. Days are
# simulated: each sale carries the driver's day, and "today" is the latest day seen. When the server answers
# resend_from, the next sync rebuilds those commands from the bills.
#      MUTANT also: prune_unconfirmed (prunes without the archive confirmation), rebuild_new_ids (rebuilt
#      commands get new command ids), config_version_only (config feed compared by version, epoch ignored).
# The spike's binding is not the product decision (README).
import hashlib
import hmac
import http.client
import json
import os
import shutil
import signal
import sys
import threading
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
RETENTION = os.environ.get("RETENTION") == "1"
RETAIN_DAYS = int(os.environ.get("RETAIN_DAYS", "60"))
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
            "CREATE TABLE IF NOT EXISTS bills (action_id TEXT PRIMARY KEY, session_id TEXT, sale_piasters INTEGER, "
            "seq INTEGER UNIQUE, command_id TEXT, payload TEXT, payload_hash TEXT, day INTEGER NOT NULL DEFAULT 0)",
            "CREATE TABLE IF NOT EXISTS sync_state (id INTEGER PRIMARY KEY CHECK (id = 1), acked_seq INTEGER NOT NULL, "
            "archived_seq INTEGER NOT NULL, resend_from INTEGER, cfg_epoch TEXT, cfg_version INTEGER, cfg_price INTEGER, "
            "today INTEGER NOT NULL DEFAULT 0)",
            "INSERT OR IGNORE INTO sync_state (id, acked_seq, archived_seq) VALUES (1, 0, 0)",
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
        q("INSERT INTO bills (action_id, session_id, sale_piasters, day) VALUES (?,?,?,?)",
          (a["action_id"], a["session_id"], sale, int(a.get("day", 0))))
        q("UPDATE sync_state SET today = max(today, ?) WHERE id = 1", (int(a.get("day", 0)),))
        q("INSERT INTO payments VALUES (?,?)", (a["action_id"], sale))
        for m in mins:
            q("INSERT INTO minutes VALUES (?,?,?)", (a["action_id"], a["session_id"], m))

    def outbox():
        seq = q("UPDATE counter SET seq = seq + 1 WHERE id = 1 RETURNING seq")[0][0]
        q("INSERT INTO outbox VALUES (?,?,?,?, 'pending')", (seq, cmd_id, body, h))
        # The command's identity lives on with the business record (retention rule; rebuild for SC-19).
        q("UPDATE bills SET seq = ?, command_id = ?, payload = ?, payload_hash = ? WHERE action_id = ?",
          (seq, cmd_id, body, h, a["action_id"]))
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
    reply({"ok": True, "op": "sale", "action_id": a["action_id"], "seq": seq})


def report():
    """SC-19: what the device tells the server on every batch (retention mode only)."""
    if not RETENTION:
        return {}
    h = q("SELECT acked_seq FROM sync_state WHERE id = 1")[0][0]
    low = q("SELECT min(seq) FROM bills WHERE seq IS NOT NULL")[0][0]
    return {"acked_seq": h, "low_seq": low if low is not None else h + 1}


def post(cmds):
    req = urllib.request.Request(SERVER + "/batch", method="POST",
                                 data=json.dumps({"device_id": DEVICE, "commands": cmds, **report()}).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=float(os.environ.get("HTTP_TIMEOUT", "10"))) as r:
        body = json.loads(r.read())  # an empty or cut body raises here: never acknowledge on the status code (P2-F1)
    if not isinstance(body, dict) or not isinstance(body.get("results"), list):
        raise ValueError("reply without a results list")
    return body


NET_ERRORS = (urllib.error.URLError, ConnectionError, TimeoutError, OSError, http.client.HTTPException, ValueError)


def rows_to_cmds(rows):
    return [{"command_id": c, "seq": s, "payload_hash": h, "payload": json.loads(p)} for s, c, p, h in rows]


def pending_count():
    n = q("SELECT count(*) FROM outbox WHERE status = 'pending'")[0][0]
    if RETENTION:
        rf, h = q("SELECT resend_from, acked_seq FROM sync_state WHERE id = 1")[0]
        if rf:
            n += max(0, h - rf + 1)
    return n


def select_rows():
    """Pending outbox rows, preceded by rebuilt commands when the server asked for a resend (SC-19)."""
    rows = q("SELECT seq, command_id, payload, payload_hash FROM outbox WHERE status = 'pending' ORDER BY seq")
    if RETENTION:
        rf, h = q("SELECT resend_from, acked_seq FROM sync_state WHERE id = 1")[0]
        if rf:
            rebuilt = q("SELECT seq, command_id, payload, payload_hash FROM bills WHERE seq >= ? AND seq <= ? ORDER BY seq",
                        (rf, h))
            if MUTANT == "rebuild_new_ids":  # planted defect: a rebuilt command gets a new identity
                rebuilt = [(s_, "cmd-r-" + c[4:], p, ph) for s_, c, p, ph in rebuilt]
            have = {r[0] for r in rebuilt}
            rows = rebuilt + [r for r in rows if r[0] not in have]
    return sorted(rows)[:50]


def sync():
    rows = select_rows()
    if not rows:
        return reply({"ok": True, "op": "sync", "pending": 0})
    failpoint("client:before_send")  # P4/P5
    try:
        resp = post(rows_to_cmds(rows))
    except NET_ERRORS as e:  # a truncated or malformed reply is a failed sync (P0-F2)
        return reply({"ok": False, "op": "sync", "error": str(e)[:120], "pending": pending_count()})
    failpoint("client:after_response_before_mark")  # P10
    q("BEGIN IMMEDIATE")
    apply_reply(resp)
    failpoint("client:mid_mark")  # P11: inside the acknowledgement write, before COMMIT
    q("COMMIT")
    failpoint("client:after_mark")  # P12
    reply({"ok": True, "op": "sync", "results": resp["results"], "pending": pending_count()})


def apply_reply(resp):
    """Inside the caller's transaction: acknowledge from a fully parsed reply, then (retention mode) record the
    server's resend request and archive confirmation, and prune what the rule allows."""
    for r in resp["results"] or []:
        if r["result"] in ("applied", "duplicate"):
            if RETENTION:
                q("DELETE FROM outbox WHERE command_id = ?", (r["command_id"],))
                q("UPDATE sync_state SET acked_seq = max(acked_seq, ?) WHERE id = 1", (r["seq"],))
            else:
                q("UPDATE outbox SET status = 'acked' WHERE command_id = ?", (r["command_id"],))
        elif r["result"] in ("payload_mismatch", "seq_conflict"):
            q("UPDATE outbox SET status = 'conflict' WHERE command_id = ?", (r["command_id"],))
    if not RETENTION:
        return
    rf = int(resp.get("resend_from") or 0)
    q("UPDATE sync_state SET resend_from = ?, archived_seq = max(archived_seq, ?) WHERE id = 1",
      (rf or None, int(resp.get("archived_seq") or 0)))
    h, watermark, today = q("SELECT acked_seq, archived_seq, today FROM sync_state WHERE id = 1")[0]
    below = h + 1 if MUTANT == "prune_unconfirmed" else watermark  # planted defect: age only, no watermark
    below = min(below, h + 1, rf or h + 1)  # never an unacknowledged record, never what the server asked for
    old = "SELECT action_id FROM bills WHERE seq IS NOT NULL AND seq < ? AND day < ?"
    args = (below, today - RETAIN_DAYS)
    q(f"DELETE FROM payments WHERE action_id IN ({old})", args)
    q(f"DELETE FROM minutes WHERE action_id IN ({old})", args)
    q("DELETE FROM bills WHERE seq IS NOT NULL AND seq < ? AND day < ?", args)


def mark(resp):
    q("BEGIN IMMEDIATE")
    apply_reply(resp)
    q("COMMIT")


def sync_concurrent():
    # SC-05: the same pending batch sent twice at once (a retry fired while the first is still in flight).
    rows = select_rows()
    if not rows:
        return reply({"ok": True, "op": "sync_concurrent", "pending": 0})
    cmds = rows_to_cmds(rows)
    out = [None, None]

    def worker(i):
        try:
            out[i] = post(cmds)
        except NET_ERRORS as e:
            out[i] = e
    threads = [threading.Thread(target=worker, args=(i,)) for i in (0, 1)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    for o in out:  # acknowledge from every reply that parsed; the second is a duplicate
        if isinstance(o, dict):
            mark(o)
    reply({"ok": True, "op": "sync_concurrent",
           "replies": [o["results"] if isinstance(o, dict) else f"error: {str(o)[:60]}" for o in out],
           "pending": pending_count()})


def ping():
    try:
        with urllib.request.urlopen(f"{SERVER}/ping?device={DEVICE}", timeout=float(os.environ.get("HTTP_TIMEOUT", "10"))) as r:
            r.read()
        reply({"ok": True, "op": "ping"})
    except NET_ERRORS as e:
        reply({"ok": False, "op": "ping", "error": str(e)[:80]})


def replay(k):
    # Duplicate resend (SC-04): send the last k acknowledged commands again, unchanged.
    if RETENTION:  # acknowledged outbox rows are gone; resend from the retained business records
        rows = q("SELECT seq, command_id, payload, payload_hash FROM bills WHERE seq IS NOT NULL AND seq <= "
                 "(SELECT acked_seq FROM sync_state WHERE id = 1) ORDER BY seq DESC LIMIT ?", (k,))[::-1]
    else:
        rows = q("SELECT seq, command_id, payload, payload_hash FROM outbox WHERE status = 'acked' "
                 "ORDER BY seq DESC LIMIT ?", (k,))[::-1]
    if not rows:
        return reply({"ok": True, "op": "replay", "sent": 0})
    try:
        resp = post(rows_to_cmds(rows))
    except NET_ERRORS as e:
        return reply({"ok": False, "op": "replay", "error": str(e)[:120]})
    reply({"ok": True, "op": "replay", "sent": len(rows), "results": resp["results"]})


def pull_config():
    """SC-19(d): server-to-device config feed. The epoch changes on every server restore, so a version number
    seen before the restore can come back with different content; compare epoch first."""
    try:
        with urllib.request.urlopen(f"{SERVER}/config", timeout=float(os.environ.get("HTTP_TIMEOUT", "10"))) as r:
            cfg = json.loads(r.read())
        epoch, version, price = str(cfg["epoch"]), int(cfg["version"]), int(cfg["price"])
    except (*NET_ERRORS, KeyError) as e:
        return reply({"ok": False, "op": "pull_config", "error": str(e)[:80]})
    le, lv = q("SELECT cfg_epoch, cfg_version FROM sync_state WHERE id = 1")[0]
    if MUTANT == "config_version_only":  # planted defect: version numbers only
        take = lv is None or version > lv
    else:
        take = le != epoch or lv is None or version > lv
        if le is not None and le != epoch:
            record_event("config_epoch_changed", RuntimeError(f"server epoch {le} -> {epoch}"),
                         local_version=lv, server_version=version)
    if take:
        q("UPDATE sync_state SET cfg_epoch = ?, cfg_version = ?, cfg_price = ? WHERE id = 1", (epoch, version, price))
    reply({"ok": True, "op": "pull_config", "applied": take})


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
        elif op == "sync_concurrent":
            sync_concurrent()
        elif op == "ping":
            ping()
        elif op == "pull_config":
            pull_config()
        elif op == "state":  # SC-19 view for the driver: retention and config state
            st = q("SELECT acked_seq, archived_seq, resend_from, cfg_epoch, cfg_version, cfg_price FROM sync_state WHERE id = 1")[0]
            reply({"ok": True, "op": op, "acked_seq": st[0], "archived_seq": st[1], "resend_from": st[2],
                   "cfg": [st[3], st[4], st[5]],
                   "bills": [list(r) for r in q("SELECT action_id, seq, command_id, payload_hash FROM bills ORDER BY seq")]})
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
