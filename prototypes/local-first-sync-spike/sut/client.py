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
# Phase 3 (SC-20, disk full; founder: keep selling as soon as space is freed, no restart; the cashier and the
# owner see a "disk full" warning; a failed marker write never crash-loops the app):
#   - A sale or ack write that hits a full disk is rolled back explicitly, answered {"ok": false, "error":
#     "disk_full", "warning": "disk_full"}, recorded and reported to the server (owner alert); the store is NOT
#     refused, so the next write after space is freed goes through.
#   - A marker write that fails after COMMIT leaves the sale saved and acknowledged ("store ahead of marker", the
#     safe direction), records "marker_behind", and the marker catches up on the next commit or start.
#   - Events are kept in memory when the event log itself cannot be written, and reported to the server
#     (POST /device_event) as soon as possible.
#   Injection: FULL_SHIM=1 puts an apsw VFS shim above SQLite3MC; ops arm_full {n, persistent} fail the n-th
#   write with SQLITE_FULL (and every later write if persistent), arm_marker_full {stage} fails the marker write at
#   write | fsync | replace, free_space clears both. MARKER_FAIL=<stage> arms the marker failure from the start.
# Phase 3 (SC-21a, app update with an unsynced outbox): SCHEMA_VERSION (1 | 2) is the app's store schema, kept
#   in PRAGMA user_version. App 2 migrates a version-1 store: copy the store files aside (<db>.premigrate/), run
#   every DDL step and the version bump in ONE transaction, verify (integrity_check and unchanged row counts),
#   refresh the marker, then delete the copy. A restart after a kill resumes from whatever the transaction left:
#   all of version 1 or all of version 2. An app older than the store refuses without writing a byte and records
#   "downgrade_refused". Pending commands keep their stored payload bytes and hash across the upgrade.
#   INSPECT=1: open (with normal crash recovery), report the schema state, never migrate (the driver's view).
# Phase 3 (SC-22, two app instances on one store): before anything touches the store (crash recovery, migration,
#   marker) the client takes an OS lock on <db>.lock (flock, exclusive, non-blocking) and holds it for its whole
#   life. A second instance takes nothing, records "second_instance_refused" and answers every op
#   {"ok": false, "error": "another_instance", "warning": "another_instance"}. The OS releases the lock when the
#   holder dies, so a restarted instance takes over with normal crash recovery. Windows (LockFileEx or a named
#   mutex) is phase 4.
# Phase 3 (SC-23, prices while offline; founder rules 2026-10-16): the device keeps the last price list it pulled
#   (per-tier station rates, cafe item price). start_session freezes the tier rate of the list the device holds at
#   that moment (G12); change_tier starts a new segment at the rate of the list the device holds at THAT moment
#   (N4); close_session bills each segment at its frozen rate (half-up per segment, a placeholder until OQ8) and
#   the cafe items at the current list. The payload carries cfg_version (newest list version used), the segments
#   and the cafe line. A new list takes effect when it is pulled, never retroactively.
#   No price list yet, or a tier/cafe price missing from it: the op is refused with a clear error code
#   ("no_price_list" / "price_missing") and nothing is billed - never a zero bill. sell_items is a cafe-only sale.
#   Only lookup errors are answered this way; a store error still refuses the store (as everywhere else).
#   OQ8 (founder, 2026-10-17): a session with several segments is rounded ONCE on its total, to the owner's
#   rounding step (round_piasters in the price list, the list held at close); never per segment.
#      MUTANT also: round_per_segment.
# Phase 3 (SC-25a, a 7-day backlog drained over short online windows cut mid-drain): the batch size adapts. It
#   starts at BATCH_MAX (50); a sync that times out halves it (down to 1), a successful one grows it by a quarter
#   (additive increase, multiplicative decrease), so a batch too large for the link's HTTP timeout shrinks instead
#   of retrying the same batch forever, and does not jump straight back to a size that times out again.
# Phase 3 (SC-25b, the N5 offline lease; founder rule 2026-10-17, sync note OQ3), LEASE=1:
#   Every server contact (a sync reply, a config pull) carries a lease {server_time, grace_s, warn_s}. The device
#   counts the lease on server time plus its monotonic counter (D1-B), never the wall clock. Every reply carries the
#   lease status: ok, warning (the last warn_s seconds: the cashier is warned) or expired. After expiry, open
#   sessions can still be closed and paid; no new session and no new sale until the device reaches the server;
#   data stays readable and exportable. A wall clock that moves more than 5 minutes against the monotonic counter
#   is recorded and reported (owner alert). Test hooks advance_mono / set_wall_offset move the device's clocks.
#   Not modelled: reboots and powered-off time (licensing note part 3); the lease is unsigned (part 2).
#      MUTANT also: wall_clock_lease (lease counted on the wall clock), expiry_blocks_close (open sessions cannot
#      be closed after expiry), no_warning (no warning before expiry), no_heartbeat (a sync with nothing to send
#      does not contact the server, so the lease is not renewed).
#      MUTANT also: fixed_batch (never shrinks), drop_on_send (outbox rows deleted when sent, before any reply,
#      without advancing the acknowledged mark, so a cut request loses them).
#      MUTANT also: zero_price_default (a missing list or price counts as 0), swallow_store_errors (the session-op
#      handler also swallows store errors instead of refusing the store).
#      MUTANT also: retroactive_price (re-prices the whole session with the list at close),
#      tier_uses_start_price (a tier change uses the list the session started with).
#      MUTANT also: no_instance_lock, lock_released_early (lock held only while opening the store).
#      MUTANT also: nonatomic_migration (each DDL step commits on its own), no_premigrate_copy,
#      reserialize_on_upgrade (rewrites stored payloads in a new byte form and recomputes their hashes).
#      MUTANT also: full_refuses (old behaviour: refuse the store on disk full), marker_crash (old behaviour: an
#      uncaught marker error), ack_despite_full (answers "saved" for a sale whose commit failed).
#      MUTANT also: prune_unconfirmed (prunes without the archive confirmation), rebuild_new_ids (rebuilt
#      commands get new command ids), config_version_only (config feed compared by version, epoch ignored).
# Phase 3 (SC-28, dashboard edit of an open bill; founder rule 2026-10-17, sync note OQ9 (2)), EDITS=1:
#   The server is the writer of an edit request, the device of the bill. Every batch reply carries the edits the
#   server holds for this device, with the server's time. The device decides each edit once, at receipt, in the
#   same transaction as the acknowledgement: "applied" if the session is still open and the reply's server time is
#   before the edit's deadline, otherwise "rejected" (bill_closed | unknown_session | expired). The decision and its
#   result command (kind edit_result, an ordinary command in the device sequence: same outbox, same dedupe) are
#   written together; an edit id already decided is never decided again. close_session adds the applied edits'
#   cafe items at the list held at close. A sync with nothing to send still contacts the server (heartbeat), so a
#   connected device receives edits. Edit results are retained like bills, so a server restore can rebuild them.
#      MUTANT also: edit_apply_twice (no dedupe on the edit id: a re-delivered edit is applied again),
#      edit_after_close (an edit for a closed bill is answered "applied" without changing the bill).
# Phase 3 (SC-29, stock policy per item; founder rule 2026-10-17, sync note OQ9 (1)):
#   The config feed carries the item catalogue (price and policy: "allow_alert" or "refuse"; no policy = a new item,
#   which defaults to allow_alert) and the owner's stock receipts. The device applies a feed when it receives it (as
#   SC-23 rule 3): items replaced, each receipt added to its stock once (receipt id). sell_stock decides on the device
#   from the policy it holds: a "refuse" item without enough stock refuses the whole sale ("out_of_stock", naming the
#   items) and nothing is billed; an "allow_alert" item may go negative. Stock is decremented in the bill's
#   transaction. The owner is alerted when an item's stock crosses from >= 0 to < 0; offline that is at most once per
#   item and offline period, because a restock needs the feed. The alert rides the sale command (neg_alerts), so the
#   server's inbox dedupe keeps it single across resends and restores.
#      MUTANT also: refuse_ignored (the refuse policy is not enforced), alert_every_sale (every negative sale alerts),
#      default_refuse (a new item defaults to refuse), stale_policy (a policy once held is never updated).
# Phase 3 (SC-30, device off while sessions run; founder rule 2026-10-17, sync note OQ8 (3)), CLOCKED=1:
#   Mechanics with an injected clock: <db>.testclock holds {boot, mono, wall}, written by the driver (a new boot id
#   and a restarted monotonic counter = the PC was powered off). A session started without start_min is anchored
#   at (boot, mono) and accumulates time across outages (D1-B). The app's one-minute timer (op tick) writes a
#   last-alive checkpoint (boot, mono, wall). At start, if the checkpoint is from an earlier boot, every open session
#   gets (checkpoint mono - its anchor) + (wall now - checkpoint wall), and its anchor moves to the new boot; the same
#   boot (the app was killed, the PC stayed on) needs no adjustment, the monotonic counter kept running. If the gap
#   since the checkpoint is longer than the tick interval, an owner notice "device was off from X to Y" (kind
#   power_off | app_down, open session count) is queued as a command in the device sequence. The adjustment, the
#   notice and the refreshed checkpoint are one transaction, so a kill during it leaves all or nothing. The outage
#   bounds rest on device wall time: trusting them is the clock question of Part D (phase 5).
#      MUTANT also: outage_not_counted (the wall-clock part of an outage is dropped), mono_across_boot (the anchor is
#      not moved: monotonic readings of two boots are subtracted), no_alive_update (the checkpoint is not refreshed
#      at start), notice_outside_txn (the notice is written after the adjustment commits), notice_every_restart
#      (a notice even for a restart inside the tick interval).
# Phase 3 (SC-31, End Day; founder rule 2026-10-17/18, sync note OQ8 (4)), ENDDAY=1:
#   The business day is a device counter, not a calendar date. Every bill carries the day it was paid in (bday).
#   end_day is refused while any bill (open tab), session or shift is open, naming them. Otherwise one transaction
#   writes the End Day command (kind end_day: the day, its bill count and total, an ordinary command in the device
#   sequence) and closes the day; the next action opens the next day. A kill during it leaves the day closed with
#   its command, or still open without one. End Day on a day already closed is refused (no_open_day).
#      MUTANT also: end_day_ignores_sessions (running sessions do not block End Day), refuse_without_names (the
#      refusal does not say what is open), end_day_two_txns (the day is closed, then the command written in a second
#      transaction), bill_old_day (after End Day a bill is stamped with the closed day).
# The spike's binding is not the product decision (README).
import errno
import fcntl
import hashlib
import hmac
import http.client
import json
import os
import shutil
import signal
import sys
import threading
import time
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
APP_SCHEMA = int(os.environ.get("SCHEMA_VERSION", "1"))
INSPECT = os.environ.get("INSPECT") == "1"
PREMIGRATE = DB + ".premigrate"
RETAIN_DAYS = int(os.environ.get("RETAIN_DAYS", "60"))
EDITS_ON = os.environ.get("EDITS") == "1"  # SC-28
CLOCKED = os.environ.get("CLOCKED") == "1"  # SC-30
ENDDAY = os.environ.get("ENDDAY") == "1"  # SC-31
TESTCLOCK = DB + ".testclock"
TICK_S = 60  # the app's last-alive timer (spike value)
fp_count = 0
MARKER_FAIL = os.environ.get("MARKER_FAIL", "")  # SC-20: write | fsync | replace
unreported = []  # SC-20: events not yet reported to the server (kept in memory when the disk is full)

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


LEASE_ON = os.environ.get("LEASE") == "1"
WALL_DRIFT_S = 300  # wall clock against monotonic counter: beyond this the move is reported (spike value)
clocks = {"mono_offset": 0.0, "wall_offset": 0.0}  # SC-25b test hooks
lease = {}


def test_clock():
    """SC-30: the injected device clock {boot, mono, wall}."""
    with open(TESTCLOCK) as f:
        return json.load(f)


def device_mono():
    return test_clock()["mono"] if CLOCKED else time.monotonic() + clocks["mono_offset"]


def device_wall():
    return test_clock()["wall"] if CLOCKED else time.time() + clocks["wall_offset"]


def take_lease(l):
    """A server contact renews the lease: server time now, and the device's clocks at this moment."""
    if LEASE_ON and isinstance(l, dict):
        lease.clear()
        lease.update(server_time=float(l["server_time"]), grace_s=float(l["grace_s"]), warn_s=float(l["warn_s"]),
                     mono_at=device_mono(), wall_at=device_wall(), drift_reported=False)


def lease_status():
    if not lease:
        return {"status": "none"}
    mono_elapsed = device_mono() - lease["mono_at"]
    wall_elapsed = device_wall() - lease["wall_at"]
    elapsed = wall_elapsed if MUTANT == "wall_clock_lease" else mono_elapsed  # planted defect: the wall clock
    remaining = lease["grace_s"] - elapsed
    if remaining <= 0:
        status = "expired"
    elif remaining <= lease["warn_s"] and MUTANT != "no_warning":
        status = "warning"
    else:
        status = "ok"
    if abs(wall_elapsed - mono_elapsed) > WALL_DRIFT_S and not lease["drift_reported"]:
        lease["drift_reported"] = True
        record_event("wall_clock_moved", RuntimeError(f"wall clock moved {wall_elapsed - mono_elapsed:+.0f} s "
                                                      "against the monotonic counter"))
    return {"status": status, "remaining_s": round(remaining), "server_now_estimate": lease["server_time"] + mono_elapsed}


def reply(obj):
    if LEASE_ON and "lease" not in obj:
        obj["lease"] = lease_status()
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


def record_event(kind, err, **extra):
    # Plain-text event log beside the database: kind and error class only, no business data. On a full disk the
    # log itself may not be writable: the event is then kept in memory (SC-20); it is always queued for the server.
    ev = {"event": kind, "error": f"{type(err).__name__}: {str(err)[:160]}", **extra}
    unreported.append(ev)
    try:
        with open(EVENTS, "a") as f:
            f.write(json.dumps(ev) + "\n")
            f.flush()
            os.fsync(f.fileno())
    except OSError:
        ev["log_write_failed"] = True


def report_events():
    """SC-20: send queued device events to the server (owner alert); best effort, short timeout."""
    if not unreported:
        return
    body = json.dumps({"device_id": DEVICE, "events": unreported}).encode()
    try:
        req = urllib.request.Request(SERVER + "/device_event", method="POST", data=body,
                                     headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=2) as r:
            r.read()
        unreported.clear()
    except (urllib.error.URLError, ConnectionError, TimeoutError, OSError, http.client.HTTPException, ValueError):
        pass


def disk_full(e):
    """True when a store error means the disk (or its quota) is full rather than a damaged store."""
    if STORE == "sqlite3mc" and isinstance(e, apsw.FullError):
        return True
    try:
        return shutil.disk_usage(os.path.dirname(os.path.abspath(DB))).free < 64 * 1024
    except OSError:
        return False


class MarkerError(RuntimeError):
    pass


class DowngradeError(RuntimeError):
    pass


class InstanceBusy(RuntimeError):
    pass


def take_instance_lock():
    """SC-22: one app instance per store. Returns the locked descriptor, or None if another instance holds it."""
    fd = os.open(DB + ".lock", os.O_RDWR | os.O_CREAT, 0o600)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        os.close(fd)
        return None
    return fd


def _mac(seq):
    k = os.environ.get("SPIKE_DB_KEY", "")
    try:
        kb = bytes.fromhex(k)
    except ValueError:
        kb = k.encode()
    return hmac.new(kb, f"kodeebo-spike-hwm:{seq}".encode(), hashlib.sha256).hexdigest()


def _marker_fault(stage):
    if MARKER_FAIL == stage:
        raise OSError(errno.ENOSPC, f"injected ENOSPC at marker {stage}")


def write_marker(seq):
    tmp = MARKER + ".tmp"
    with open(tmp, "w") as f:
        _marker_fault("write")
        json.dump({"seq": seq, "mac": _mac(seq)}, f)
        f.flush()
        _marker_fault("fsync")
        os.fsync(f.fileno())
    _marker_fault("replace")
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
    if seq > mseq:  # crash or failed marker write after a commit: the store is ahead, which is safe
        try:
            write_marker(seq)
        except OSError as e:
            if MUTANT == "marker_crash":
                raise
            record_event("marker_behind", e, store_seq=seq, marker_seq=mseq, at="start")


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


if STORE == "sqlite3mc" and os.environ.get("FULL_SHIM") == "1":
    class FullState:  # SC-20 injection: fail the n-th write after arming; persistent = every later write too
        armed_at, writes, persistent, tripped = 0, 0, False, False

    class FullFile(apsw.VFSFile):
        def xWrite(self, data, offset):
            if FullState.armed_at:
                FullState.writes += 1
                if (FullState.tripped and FullState.persistent) or FullState.writes == FullState.armed_at:
                    FullState.tripped = True
                    raise apsw.FullError("injected SQLITE_FULL")
            return super().xWrite(data, offset)

    class FullVFS(apsw.VFS):
        def __init__(self):
            self.base = apsw.vfs_names()[0]  # SQLite3MC's cipher VFS is the default; the shim sits above it
            super().__init__("fullshim", self.base)

        def xOpen(self, name, flags):
            return FullFile(self.base, name, flags)

    full_vfs = FullVFS()


MIGRATION = [  # schema 1 -> 2 (SC-21a): a new column, a new table, and a rebuilt outbox with an envelope column
    "ALTER TABLE bills ADD COLUMN tax_piasters INTEGER NOT NULL DEFAULT 0",
    "CREATE TABLE bill_lines (action_id TEXT NOT NULL, item TEXT NOT NULL, piasters INTEGER NOT NULL)",
    "CREATE TABLE outbox_v2 (seq INTEGER PRIMARY KEY, command_id TEXT UNIQUE, payload TEXT, payload_hash TEXT, "
    "status TEXT NOT NULL, envelope INTEGER NOT NULL DEFAULT 1)",
    "INSERT INTO outbox_v2 (seq, command_id, payload, payload_hash, status) "
    "SELECT seq, command_id, payload, payload_hash, status FROM outbox",
    "DROP TABLE outbox",
    "ALTER TABLE outbox_v2 RENAME TO outbox",
    "PRAGMA user_version = 2",
]
COUNTED = ("bills", "payments", "minutes", "outbox")


def row_counts(c):
    return {t: c.execute(f"SELECT count(*) FROM {t}").fetchall()[0][0] for t in COUNTED}


def verify_migrated(c, before):
    result = c.execute("PRAGMA integrity_check").fetchall()
    if result != [("ok",)]:
        raise RuntimeError(f"migration verification: integrity_check {result[:3]}")
    if before is not None and row_counts(c) != before:
        raise RuntimeError(f"migration verification: row counts {row_counts(c)} != {before}")


def migrate(c):
    """Schema 1 -> 2. The copy aside is kept until the migrated store has been verified."""
    seq = c.execute("SELECT seq FROM counter WHERE id = 1").fetchall()[0][0]
    before = row_counts(c)
    failpoint("migrate:before_copy")
    if MUTANT != "no_premigrate_copy":
        if os.path.exists(PREMIGRATE):
            shutil.rmtree(PREMIGRATE)  # a copy from an attempt that never committed: take a fresh one
        os.makedirs(PREMIGRATE)
        for suffix in ("", ".hwm"):
            if os.path.exists(DB + suffix):
                shutil.copy2(DB + suffix, os.path.join(PREMIGRATE, os.path.basename(DB) + suffix))
    failpoint("migrate:after_copy")
    atomic = MUTANT != "nonatomic_migration"
    if atomic:
        c.execute("BEGIN IMMEDIATE").fetchall()
    for k, stmt in enumerate(MIGRATION):
        c.execute(stmt).fetchall()
        if k == 2:
            failpoint("migrate:mid_ddl")
    if MUTANT == "reserialize_on_upgrade":  # planted defect: new byte form for stored payloads, new hashes
        for table, key in (("outbox", "seq"), ("bills", "action_id")):
            for k_, payload in c.execute(f"SELECT {key}, payload FROM {table} WHERE payload IS NOT NULL").fetchall():
                body = json.dumps(json.loads(payload))  # default separators, no key sort
                c.execute(f"UPDATE {table} SET payload = ?, payload_hash = ? WHERE {key} = ?",
                          (body, hashlib.sha256(body.encode()).hexdigest(), k_)).fetchall()
    if atomic:
        c.execute("COMMIT").fetchall()
    failpoint("migrate:after_commit")
    verify_migrated(c, before)
    failpoint("migrate:before_marker")
    try:
        write_marker(seq)
    except OSError as e:
        record_event("marker_behind", e, store_seq=seq, at="migration")
    failpoint("migrate:before_cleanup")
    if os.path.exists(PREMIGRATE):
        shutil.rmtree(PREMIGRATE)


def open_store():
    """Open and verify the store. Returns (connection, None, copy) or (None, error, copy)."""
    copy = preserve_before_recovery()
    try:
        if STORE == "sqlite3mc":
            c = apsw.Connection(DB, vfs="fullshim") if os.environ.get("FULL_SHIM") == "1" else apsw.Connection(DB)
            c.set_busy_timeout(5000)
            c.execute(f"PRAGMA cipher = {CIPHER}").fetchall()
            c.execute(key_pragma(os.environ.get("SPIKE_DB_KEY", ""))).fetchall()  # answers 'ok' even for a wrong key
        else:
            c = sqlite3.connect(DB, isolation_level=None, timeout=5)
        # Verification before any write: a wrong key or a damaged page fails here.
        result = c.execute("PRAGMA integrity_check").fetchall()
        if result != [("ok",)]:
            raise RuntimeError(f"integrity_check: {result[:3]}")
        uv = c.execute("PRAGMA user_version").fetchall()[0][0]
        if uv > APP_SCHEMA and not INSPECT:  # SC-21a: an older app never touches a newer store
            raise DowngradeError(f"store schema {uv} is newer than this app ({APP_SCHEMA})")
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
            "today INTEGER NOT NULL DEFAULT 0, cfg_prices TEXT)",
            "CREATE TABLE IF NOT EXISTS sessions (session_id TEXT PRIMARY KEY, start_min INTEGER NOT NULL, "
            "start_prices TEXT NOT NULL, start_version INTEGER NOT NULL, segments TEXT NOT NULL)",
            "INSERT OR IGNORE INTO sync_state (id, acked_seq, archived_seq) VALUES (1, 0, 0)",
            "CREATE TABLE IF NOT EXISTS payments (action_id TEXT, piasters INTEGER)",
            "CREATE TABLE IF NOT EXISTS minutes (action_id TEXT, session_id TEXT, minute_idx INTEGER)",
            "CREATE TABLE IF NOT EXISTS counter (id INTEGER PRIMARY KEY CHECK (id = 1), seq INTEGER NOT NULL)",
            "INSERT OR IGNORE INTO counter VALUES (1, 0)",
            "CREATE TABLE IF NOT EXISTS outbox (seq INTEGER PRIMARY KEY, command_id TEXT UNIQUE, payload TEXT, "
            "payload_hash TEXT, status TEXT NOT NULL)",
            "CREATE TABLE IF NOT EXISTS edits (edit_id TEXT PRIMARY KEY, session_id TEXT, n INTEGER, result TEXT, "
            "reason TEXT, seq INTEGER UNIQUE, command_id TEXT, payload TEXT, payload_hash TEXT)",  # SC-28
            "CREATE TABLE IF NOT EXISTS items (item_id TEXT PRIMARY KEY, price INTEGER NOT NULL, policy TEXT)",  # SC-29
            "CREATE TABLE IF NOT EXISTS stock (item_id TEXT PRIMARY KEY, qty INTEGER NOT NULL)",
            "CREATE TABLE IF NOT EXISTS receipts (receipt_id TEXT PRIMARY KEY)",
            "CREATE TABLE IF NOT EXISTS alive (id INTEGER PRIMARY KEY CHECK (id = 1), boot INTEGER, mono REAL, wall REAL)",
            "CREATE TABLE IF NOT EXISTS session_clock (session_id TEXT PRIMARY KEY, boot INTEGER NOT NULL, "
            "mono_at REAL NOT NULL, accum_s REAL NOT NULL)",  # SC-30
            "CREATE TABLE IF NOT EXISTS outages (id INTEGER PRIMARY KEY, kind TEXT, from_wall REAL, to_wall REAL, "
            "open_sessions INTEGER, seq INTEGER UNIQUE, command_id TEXT, payload TEXT, payload_hash TEXT)",
            "CREATE TABLE IF NOT EXISTS business_day (id INTEGER PRIMARY KEY CHECK (id = 1), day_no INTEGER NOT NULL, "
            "opened INTEGER NOT NULL)",  # SC-31
            "INSERT OR IGNORE INTO business_day VALUES (1, 1, 1)",
            "CREATE TABLE IF NOT EXISTS bill_days (action_id TEXT PRIMARY KEY, bday INTEGER NOT NULL, piasters INTEGER)",
            "CREATE TABLE IF NOT EXISTS tabs (tab_id TEXT PRIMARY KEY)",
            "CREATE TABLE IF NOT EXISTS shifts (shift_id TEXT PRIMARY KEY)",
            "CREATE TABLE IF NOT EXISTS day_closes (bday INTEGER PRIMARY KEY, n_bills INTEGER, total INTEGER, "
            "seq INTEGER UNIQUE, command_id TEXT, payload TEXT, payload_hash TEXT)",
        ]:
            c.execute(stmt).fetchall()
        check_marker(c)
        if copy:
            shutil.rmtree(copy)  # verified: the crash recovery was clean, the copy is not needed
        if not INSPECT:
            if c.execute("PRAGMA user_version").fetchall()[0][0] == 0:
                c.execute("PRAGMA user_version = 1").fetchall()  # a store created by this spike starts at schema 1
            if APP_SCHEMA >= 2 and c.execute("PRAGMA user_version").fetchall()[0][0] < 2:
                migrate(c)
            elif os.path.exists(PREMIGRATE):  # a kill after the migration committed: verify, then finish cleanup
                verify_migrated(c, None)
                shutil.rmtree(PREMIGRATE)
        return c, None, None
    except (*STORE_ERRORS, RuntimeError) as e:
        return None, e, copy


instance_lock = -1 if MUTANT == "no_instance_lock" else take_instance_lock()
if instance_lock is None:  # another instance holds the store: touch nothing
    con, open_error, recovery_copy = None, InstanceBusy("another app instance holds this store"), None
else:
    con, open_error, recovery_copy = open_store()
    if MUTANT == "lock_released_early" and instance_lock >= 0:  # planted defect: lock only while opening
        fcntl.flock(instance_lock, fcntl.LOCK_UN)
if isinstance(open_error, InstanceBusy):
    record_event("second_instance_refused", open_error)
elif isinstance(open_error, DowngradeError):
    record_event("downgrade_refused", open_error)  # refused on purpose: the store was not touched
elif open_error is not None:
    record_event("store_unusable_at_start", open_error, originals_preserved_in=recovery_copy)


def close_and_pay(a, priced=None, also=None):
    """priced (SC-23): (minutes, sale, extra payload fields) computed by close_session from the device's prices.
    also (SC-29): more writes that belong to the same transaction as the bill (the stock decrement)."""
    if priced:
        mins, sale, extra = priced
    else:
        end = a["end_min"] + 1 if MUTANT == "double_minute" else a["end_min"]  # planted off-by-one
        mins = list(range(a["start_min"], end))
        session = (len(mins) * a["rate_per_hour"] + 30) // 60  # integer piasters, half-up
        sale, extra = session + a["cafe_piasters"], {}
    payload = {"action_id": a["action_id"], "session_id": a["session_id"], "minutes": mins,
               "sale_piasters": sale, "payment_piasters": sale, **extra}
    if ENDDAY:  # SC-31: the business day this bill is paid in (a closed day means the next one opens now)
        payload["bday"] = next_bday()
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
        if priced:
            q("DELETE FROM sessions WHERE session_id = ?", (a["session_id"],))
            q("DELETE FROM session_clock WHERE session_id = ?", (a["session_id"],))
        if ENDDAY:
            open_day()
            q("INSERT INTO bill_days VALUES (?,?,?)", (a["action_id"], payload["bday"], sale))
        if also:
            also()

    def outbox():
        seq = q("UPDATE counter SET seq = seq + 1 WHERE id = 1 RETURNING seq")[0][0]
        q("INSERT INTO outbox (seq, command_id, payload, payload_hash, status) VALUES (?,?,?,?, 'pending')",
          (seq, cmd_id, body, h))
        # The command's identity lives on with the business record (retention rule; rebuild for SC-19).
        q("UPDATE bills SET seq = ?, command_id = ?, payload = ?, payload_hash = ? WHERE action_id = ?",
          (seq, cmd_id, body, h, a["action_id"]))
        return seq

    failpoint("client:before_local_commit")  # P1
    try:
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
    except STORE_ERRORS as e:
        if MUTANT == "full_refuses" or not disk_full(e):
            raise  # a damaged store: refuse (old behaviour for disk full in the full_refuses mutant)
        rollback()
        record_event("disk_full", e, during="sale")
        report_events()
        if MUTANT == "ack_despite_full":  # planted defect: tells the cashier the sale was saved
            return reply({"ok": True, "op": "sale", "action_id": a["action_id"], "seq": None})
        return reply({"ok": False, "op": "sale", "action_id": a["action_id"], "error": "disk_full",
                      "warning": "disk_full"})
    failpoint("client:after_local_commit")  # P4: committed, marker not yet written, not yet acknowledged
    warning = None
    try:
        write_marker(seq)
    except OSError as e:  # the sale is committed: it stays saved; the marker catches up later (fail safe)
        if MUTANT == "marker_crash":
            raise
        record_event("marker_behind", e, store_seq=seq, at="sale")
        report_events()
        warning = "disk_full" if e.errno == errno.ENOSPC else "marker_behind"
    reply({"ok": True, "op": "sale", "action_id": a["action_id"], "seq": seq, **({"warning": warning} if warning else {})})


def rollback():
    """Explicit ROLLBACK after a write error: SQLite may have rolled back already (sync note F443, probe P3)."""
    try:
        if con.in_transaction:
            q("ROLLBACK")
    except STORE_ERRORS:
        pass


# Every retained command, bills and SC-28 edit results alike: a server restore can ask for any of them again.
RETAINED = ("SELECT seq, command_id, payload, payload_hash FROM bills WHERE seq IS NOT NULL "
            "UNION ALL SELECT seq, command_id, payload, payload_hash FROM edits WHERE seq IS NOT NULL "
            "UNION ALL SELECT seq, command_id, payload, payload_hash FROM outages WHERE seq IS NOT NULL "
            "UNION ALL SELECT seq, command_id, payload, payload_hash FROM day_closes WHERE seq IS NOT NULL")


def report():
    """SC-19: what the device tells the server on every batch (retention mode only)."""
    if not RETENTION:
        return {}
    h = q("SELECT acked_seq FROM sync_state WHERE id = 1")[0][0]
    low = q(f"SELECT min(seq) FROM ({RETAINED})")[0][0]
    return {"acked_seq": h, "low_seq": low if low is not None else h + 1}


def post(cmds):
    req = urllib.request.Request(SERVER + "/batch", method="POST",
                                 data=json.dumps({"device_id": DEVICE, "commands": cmds, **report()}).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=float(os.environ.get("HTTP_TIMEOUT", "10"))) as r:
        body = json.loads(r.read())  # an empty or cut body raises here: never acknowledge on the status code (P2-F1)
    if not isinstance(body, dict) or not isinstance(body.get("results"), list):
        raise ValueError("reply without a results list")
    take_lease(body.get("lease"))  # a parsed reply from the server renews the lease
    return body


BATCH_MAX = int(os.environ.get("BATCH_MAX", "50"))
batch = BATCH_MAX  # SC-25a: adaptive batch size


def timed_out(e):
    return isinstance(e, TimeoutError) or "timed out" in str(e).lower() or isinstance(
        getattr(e, "reason", None), TimeoutError)


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
            rebuilt = q(f"SELECT * FROM ({RETAINED}) WHERE seq >= ? AND seq <= ? ORDER BY seq", (rf, h))
            if MUTANT == "rebuild_new_ids":  # planted defect: a rebuilt command gets a new identity
                rebuilt = [(s_, "cmd-r-" + c[4:], p, ph) for s_, c, p, ph in rebuilt]
            have = {r[0] for r in rebuilt}
            rows = rebuilt + [r for r in rows if r[0] not in have]
    return sorted(rows)[:batch]


def sync():
    global batch
    report_events()
    rows = select_rows()
    if not rows:
        if (LEASE_ON or EDITS_ON) and MUTANT != "no_heartbeat":  # SC-25b/SC-28: a contact with nothing to send
            try:
                resp = post([])
            except NET_ERRORS as e:
                return reply({"ok": False, "op": "sync", "error": str(e)[:120], "pending": 0})
            if EDITS_ON and resp.get("edits"):  # SC-28: edits arrive on the heartbeat too
                return finish_sync(resp)
        return reply({"ok": True, "op": "sync", "pending": 0})
    failpoint("client:before_send")  # P4/P5
    if MUTANT == "drop_on_send":  # planted defect: forget the commands as soon as they are sent
        q("BEGIN IMMEDIATE")
        for r in rows:
            q("DELETE FROM outbox WHERE command_id = ?", (r[1],))
        q("COMMIT")
    try:
        resp = post(rows_to_cmds(rows))
    except NET_ERRORS as e:  # a truncated or malformed reply is a failed sync (P0-F2)
        if timed_out(e) and MUTANT != "fixed_batch":
            batch = max(1, batch // 2)  # too big for this link: shrink, never retry the same batch forever
        return reply({"ok": False, "op": "sync", "error": str(e)[:120], "pending": pending_count(), "batch": batch})
    batch = min(BATCH_MAX, batch + max(1, batch // 4))
    return finish_sync(resp)


def finish_sync(resp):
    failpoint("client:after_response_before_mark")  # P10
    try:
        q("BEGIN IMMEDIATE")
        apply_reply(resp)
        decided = apply_edits(resp) if EDITS_ON else []
        failpoint("client:mid_mark")  # P11: inside the acknowledgement write, before COMMIT
        q("COMMIT")
    except STORE_ERRORS as e:
        if MUTANT == "full_refuses" or not disk_full(e):
            raise
        rollback()  # the acks are lost locally; the commands stay pending and come back as "duplicate"
        record_event("disk_full", e, during="ack_mark")
        report_events()
        return reply({"ok": False, "op": "sync", "error": "disk_full", "warning": "disk_full",
                      "pending": pending_count()})
    failpoint("client:after_mark")  # P12
    if decided:  # the edit results advanced the device sequence: the marker follows (fail safe, as for a sale)
        try:
            write_marker(q("SELECT seq FROM counter WHERE id = 1")[0][0])
        except OSError as e:
            record_event("marker_behind", e, at="edit")
    reply({"ok": True, "op": "sync", "results": resp["results"], "pending": pending_count(), "batch": batch,
           **({"edits": decided} if decided else {})})


def apply_edits(resp):
    """SC-28, inside the caller's transaction: decide each edit the server sent, once, and queue its result."""
    decided = []
    server_time = float(resp.get("server_time") or 0)
    for e in resp.get("edits") or []:
        key = e["edit_id"]
        if MUTANT == "edit_apply_twice":  # planted defect: no dedupe on the edit id
            key = f"{key}#{q('SELECT count(*) FROM edits')[0][0]}"
        elif q("SELECT 1 FROM edits WHERE edit_id = ?", (key,)):
            continue  # decided before (a re-delivery): its result is already queued or acknowledged
        open_ = bool(q("SELECT 1 FROM sessions WHERE session_id = ?", (e["session_id"],)))
        if server_time >= float(e["deadline"]):
            result, reason = "rejected", "expired"
        elif open_ or MUTANT == "edit_after_close":
            result, reason = "applied", None
        else:
            closed = q("SELECT 1 FROM bills WHERE session_id = ?", (e["session_id"],))
            result, reason = "rejected", "bill_closed" if closed else "unknown_session"
        payload = {"kind": "edit_result", "edit_id": e["edit_id"], "session_id": e["session_id"], "result": result,
                   "reason": reason}
        body = json.dumps(payload, sort_keys=True, separators=(",", ":"))
        h = hashlib.sha256(body.encode()).hexdigest()
        seq = q("UPDATE counter SET seq = seq + 1 WHERE id = 1 RETURNING seq")[0][0]
        cmd_id = f"cmd-edit-{e['edit_id']}-{seq}" if MUTANT == "edit_apply_twice" else f"cmd-edit-{e['edit_id']}"
        q("INSERT INTO outbox (seq, command_id, payload, payload_hash, status) VALUES (?,?,?,?, 'pending')",
          (seq, cmd_id, body, h))
        q("INSERT INTO edits VALUES (?,?,?,?,?,?,?,?,?)",
          (key, e["session_id"], int(e["n"]) if result == "applied" else 0, result, reason, seq, cmd_id, body, h))
        decided.append({"edit_id": e["edit_id"], "result": result, "reason": reason})
    return decided


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
            try:
                mark(o)
            except STORE_ERRORS as e:
                if MUTANT == "full_refuses" or not disk_full(e):
                    raise
                rollback()
                record_event("disk_full", e, during="ack_mark")
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
        rows = q(f"SELECT * FROM ({RETAINED}) WHERE seq <= "
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


class PriceError(ValueError):
    """A counter action that cannot be priced from the device's price list; carries the reply error code."""

    def __init__(self, code, detail):
        super().__init__(detail)
        self.code = code


class ZeroPrices(dict):  # zero_price_default mutant only
    def __missing__(self, key):
        return 0


def device_prices():
    v, p = q("SELECT cfg_version, cfg_prices FROM sync_state WHERE id = 1")[0]
    prices = json.loads(p) if p else None
    if MUTANT == "zero_price_default":  # planted defect: bill at zero rather than refuse
        return v or 0, ZeroPrices(prices or {})
    if not prices:
        raise PriceError("no_price_list", "this device has not received a price list yet")
    return v, prices


def price_of(prices, key):
    if MUTANT == "zero_price_default":  # planted defect: a missing price is billed at zero
        return prices.get(key, 0) if isinstance(prices, dict) else 0
    if key not in prices:
        raise PriceError("price_missing", f"the device's price list has no price for {key!r}")
    return prices[key]


def start_session(m):
    v, prices = device_prices()
    clocked = CLOCKED and "start_min" not in m  # SC-30: anchored on the device clock
    start = 0 if clocked else m["start_min"]
    seg = [{"from": start, "tier": m["tier"], "rate": price_of(prices, m["tier"]), "v": v}]
    q("BEGIN IMMEDIATE")
    if ENDDAY:
        open_day()
    q("INSERT INTO sessions VALUES (?,?,?,?,?)", (m["session_id"], start, json.dumps(prices), v, json.dumps(seg)))
    if clocked:
        c = test_clock()
        q("INSERT INTO session_clock VALUES (?,?,?,0)", (m["session_id"], c["boot"], c["mono"]))
    q("COMMIT")
    reply({"ok": True, "op": "start_session", "rate": seg[0]["rate"], "v": v})


def session_elapsed_s(session_id):
    """SC-30: time accumulated before the current boot plus the monotonic time since the anchor."""
    boot, mono_at, accum = q("SELECT boot, mono_at, accum_s FROM session_clock WHERE session_id = ?", (session_id,))[0]
    return accum + (test_clock()["mono"] - mono_at)


def tick():
    """SC-30: the app's one-minute timer writes the last-alive checkpoint."""
    c = test_clock()
    q("INSERT INTO alive VALUES (1,?,?,?) ON CONFLICT (id) DO UPDATE SET boot = excluded.boot, mono = excluded.mono, "
      "wall = excluded.wall", (c["boot"], c["mono"], c["wall"]))
    reply({"ok": True, "op": "tick"})


def check_outage():
    """SC-30, at start: account the time the device or the app was down to every open session, and queue one owner
    notice, in one transaction with the refreshed checkpoint."""
    c = test_clock()
    row = q("SELECT boot, mono, wall FROM alive WHERE id = 1")
    q("BEGIN IMMEDIATE")
    notice = None
    if row:
        boot0, mono0, wall0 = row[0]
        gap = c["wall"] - wall0
        if boot0 != c["boot"] and MUTANT != "mono_across_boot":  # powered off: the monotonic counter restarted
            down = 0 if MUTANT == "outage_not_counted" else gap
            for sid, mono_at in q("SELECT session_id, mono_at FROM session_clock WHERE boot = ?", (boot0,)):
                q("UPDATE session_clock SET accum_s = accum_s + ? + ?, boot = ?, mono_at = ? WHERE session_id = ?",
                  (mono0 - mono_at, down, c["boot"], c["mono"], sid))
        if gap > TICK_S or MUTANT == "notice_every_restart":
            n_open = q("SELECT count(*) FROM sessions")[0][0]
            notice = {"kind": "device_off", "off_kind": "power_off" if boot0 != c["boot"] else "app_down",
                      "from_wall": wall0, "to_wall": c["wall"], "open_sessions": n_open}
    if MUTANT != "no_alive_update":
        q("INSERT INTO alive VALUES (1,?,?,?) ON CONFLICT (id) DO UPDATE SET boot = excluded.boot, "
          "mono = excluded.mono, wall = excluded.wall", (c["boot"], c["mono"], c["wall"]))
    if MUTANT == "notice_outside_txn":  # planted defect: the notice is a second transaction
        q("COMMIT")
        failpoint("client:outage_mid")
        q("BEGIN IMMEDIATE")
    if notice:
        body = json.dumps(notice, sort_keys=True, separators=(",", ":"))
        h = hashlib.sha256(body.encode()).hexdigest()
        seq = q("UPDATE counter SET seq = seq + 1 WHERE id = 1 RETURNING seq")[0][0]
        cmd_id = f"cmd-off-{c['boot']}-{int(c['wall'])}"
        q("INSERT INTO outbox (seq, command_id, payload, payload_hash, status) VALUES (?,?,?,?, 'pending')",
          (seq, cmd_id, body, h))
        q("INSERT INTO outages (kind, from_wall, to_wall, open_sessions, seq, command_id, payload, payload_hash) "
          "VALUES (?,?,?,?,?,?,?,?)", (notice["off_kind"], notice["from_wall"], notice["to_wall"],
                                       notice["open_sessions"], seq, cmd_id, body, h))
    if MUTANT != "notice_outside_txn":
        failpoint("client:outage_mid")  # inside the transaction: a kill here leaves nothing
    q("COMMIT")
    if notice:
        try:
            write_marker(q("SELECT seq FROM counter WHERE id = 1")[0][0])
        except OSError as e:
            record_event("marker_behind", e, at="outage")


def change_tier(m):
    v, prices = device_prices()
    start_prices, start_v, segs = q("SELECT start_prices, start_version, segments FROM sessions WHERE session_id = ?",
                                    (m["session_id"],))[0]
    if MUTANT == "tier_uses_start_price":  # planted defect: the list the session started with
        v, prices = start_v, json.loads(start_prices)
    rate = price_of(prices, m["tier"])
    segs = json.loads(segs) + [{"from": m["at_min"], "tier": m["tier"], "rate": rate, "v": v}]
    q("UPDATE sessions SET segments = ? WHERE session_id = ?", (json.dumps(segs), m["session_id"]))
    reply({"ok": True, "op": "change_tier", "rate": rate, "v": v})


def next_bday():
    """SC-31: the day a new action belongs to (the instance lock makes this process the store's only writer)."""
    day_no, opened = q("SELECT day_no, opened FROM business_day WHERE id = 1")[0]
    return day_no if opened or MUTANT == "bill_old_day" else day_no + 1


def open_day():
    """SC-31, inside the caller's transaction: the first action after End Day opens the next business day."""
    if MUTANT != "bill_old_day":
        q("UPDATE business_day SET day_no = day_no + 1, opened = 1 WHERE id = 1 AND opened = 0")


def end_day():
    """SC-31: refused while anything is open; otherwise the day's command and the close in one transaction."""
    open_now = {"bills": [r[0] for r in q("SELECT tab_id FROM tabs ORDER BY tab_id")],
                "sessions": [] if MUTANT == "end_day_ignores_sessions" else
                [r[0] for r in q("SELECT session_id FROM sessions ORDER BY session_id")],
                "shifts": [r[0] for r in q("SELECT shift_id FROM shifts ORDER BY shift_id")]}
    if any(open_now.values()):
        return reply({"ok": False, "op": "end_day", "error": "day_has_open_items", "warning": "day_has_open_items",
                      **({} if MUTANT == "refuse_without_names" else {"open": open_now})})
    day_no, opened = q("SELECT day_no, opened FROM business_day WHERE id = 1")[0]
    if not opened:
        return reply({"ok": False, "op": "end_day", "error": "no_open_day"})
    n, total = q("SELECT count(*), coalesce(sum(piasters), 0) FROM bill_days WHERE bday = ?", (day_no,))[0]
    payload = {"kind": "end_day", "bday": day_no, "n_bills": n, "total": total}
    body = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    h = hashlib.sha256(body.encode()).hexdigest()
    q("BEGIN IMMEDIATE")
    q("UPDATE business_day SET opened = 0 WHERE id = 1")
    if MUTANT == "end_day_two_txns":  # planted defect: the close and its command in two transactions
        q("COMMIT")
        failpoint("client:end_day_mid")
        q("BEGIN IMMEDIATE")
    seq = q("UPDATE counter SET seq = seq + 1 WHERE id = 1 RETURNING seq")[0][0]
    cmd_id = f"cmd-endday-{day_no}"
    q("INSERT INTO outbox (seq, command_id, payload, payload_hash, status) VALUES (?,?,?,?, 'pending')",
      (seq, cmd_id, body, h))
    q("INSERT INTO day_closes VALUES (?,?,?,?,?,?,?)", (day_no, n, total, seq, cmd_id, body, h))
    if MUTANT != "end_day_two_txns":
        failpoint("client:end_day_mid")  # inside the transaction: a kill leaves the day open, nothing queued
    q("COMMIT")
    failpoint("client:end_day_after_commit")  # closed and queued; the reply is lost
    try:
        write_marker(seq)
    except OSError as e:
        record_event("marker_behind", e, at="end_day")
    reply({"ok": True, "op": "end_day", "bday": day_no, "n_bills": n, "total": total, "seq": seq})


def day_state():
    day_no, opened = q("SELECT day_no, opened FROM business_day WHERE id = 1")[0]
    reply({"ok": True, "op": "day_state", "day_no": day_no, "opened": bool(opened),
           "closes": [list(r) for r in q("SELECT bday, n_bills, total FROM day_closes ORDER BY bday")]})


def open_item(table, key, value):
    """SC-31: open a tab (an open bill) or a shift; the first action after End Day opens the next day."""
    q("BEGIN IMMEDIATE")
    open_day()
    q(f"INSERT INTO {table} VALUES (?)", (value,))
    q("COMMIT")
    reply({"ok": True, "op": f"open_{key}"})


def close_shift(m):
    q("DELETE FROM shifts WHERE shift_id = ?", (m["shift_id"],))
    reply({"ok": True, "op": "close_shift"})


def pay_tab(m):
    """SC-31: an open bill is paid: a cafe sale priced at the device's list, the tab removed in the bill's transaction."""
    v, prices = device_prices()
    n, price = int(m["n"]), price_of(prices, "cafe")
    extra = {"cfg_version": v, "segments": [], "cafe": {"n": n, "price": price}}
    a = {"action_id": m["action_id"], "session_id": m["tab_id"], "day": m.get("day", 0)}
    close_and_pay(a, priced=([], n * price, extra), also=lambda: q("DELETE FROM tabs WHERE tab_id = ?", (m["tab_id"],)))


def round_half_up(units, step):
    """units / 60 piasters, rounded half-up to a multiple of step piasters (the owner's rounding setting)."""
    return (units + 30 * step) // (60 * step) * step


def close_session(m):
    v, prices = device_prices()
    if CLOCKED and "end_min" not in m:  # SC-30: billable minutes from the device clock (whole minutes, floor)
        m = {**m, "end_min": int(session_elapsed_s(m["session_id"]) // 60)}
    start, segs = q("SELECT start_min, segments FROM sessions WHERE session_id = ?", (m["session_id"],))[0]
    segs = json.loads(segs)
    if MUTANT == "retroactive_price":  # planted defect: today's list applied to the whole session
        segs = [{**sg, "rate": prices[sg["tier"]], "v": v} for sg in segs]
    lines, units = [], 0
    for k, sg in enumerate(segs):
        until = segs[k + 1]["from"] if k + 1 < len(segs) else m["end_min"]
        n = until - sg["from"]
        units += n * sg["rate"]  # piaster-minutes per hour-rate; rounded once on the total (OQ8)
        lines.append({"tier": sg["tier"], "mins": n, "rate": sg["rate"], "v": sg["v"]})
    step = price_of(prices, "round_piasters")  # owner setting (OQ8): never a value fixed in code
    if MUTANT == "round_per_segment":  # planted defect: each segment rounded on its own
        total = sum(round_half_up(ln["mins"] * ln["rate"], step) for ln in lines)
    else:
        total = round_half_up(units, step)
    cafe_n = int(m.get("cafe_n", 0))
    edits = q("SELECT edit_id, n FROM edits WHERE session_id = ? AND result = 'applied' ORDER BY edit_id",
              (m["session_id"],)) if EDITS_ON else []
    cafe_n += sum(n for _, n in edits)  # SC-28: items the owner added from the dashboard, at the list held at close
    cafe_price = price_of(prices, "cafe") if cafe_n else prices.get("cafe", 0)
    total += cafe_n * cafe_price
    used = [sg["v"] for sg in segs] + ([v] if cafe_n else [])
    extra = {"cfg_version": max(used), "segments": lines, "cafe": {"n": cafe_n, "price": cafe_price},
             **({"edits": [k for k, _ in edits]} if edits else {})}
    a = {"action_id": m["action_id"], "session_id": m["session_id"], "day": m.get("day", 0)}
    close_and_pay(a, priced=(list(range(start, m["end_min"])), total, extra))


def sell_items(m):
    """A cafe-only sale (no station session), priced from the device's current list."""
    v, prices = device_prices()
    n = int(m["n"])
    price = price_of(prices, "cafe")
    extra = {"cfg_version": v, "segments": [], "cafe": {"n": n, "price": price}}
    a = {"action_id": m["action_id"], "session_id": m["action_id"], "day": m.get("day", 0)}
    close_and_pay(a, priced=([], n * price, extra))


def sell_stock(m):
    """SC-29: a sale of catalogue items, refused or allowed from the policy and stock the device holds."""
    v = q("SELECT cfg_version FROM sync_state WHERE id = 1")[0][0]
    lines, out, alerts = [], [], []
    for ln in sorted(m["lines"], key=lambda x: x["item"]):
        row = q("SELECT price, policy FROM items WHERE item_id = ?", (ln["item"],))
        if not row:
            raise PriceError("price_missing", f"the device's catalogue has no item {ln['item']!r}")
        price, policy = row[0]
        policy = policy or ("refuse" if MUTANT == "default_refuse" else "allow_alert")  # a new item: allow and alert
        n = int(ln["n"])
        have = (q("SELECT qty FROM stock WHERE item_id = ?", (ln["item"],)) or [(0,)])[0][0]
        if policy == "refuse" and have - n < 0 and MUTANT != "refuse_ignored":
            out.append(ln["item"])
        if have - n < 0 and (have >= 0 or MUTANT == "alert_every_sale"):
            alerts.append(ln["item"])  # crossed below zero: one owner alert
        lines.append({"item": ln["item"], "n": n, "price": price})
    if out:  # refused at the counter; nothing is billed and no stock moves
        return reply({"ok": False, "op": "sell_stock", "error": "out_of_stock", "warning": "out_of_stock", "items": out})

    def decrement():
        for ln in lines:
            q("INSERT INTO stock VALUES (?, 0) ON CONFLICT (item_id) DO NOTHING", (ln["item"],))
            q("UPDATE stock SET qty = qty - ? WHERE item_id = ?", (ln["n"], ln["item"]))
    extra = {"cfg_version": v or 0, "segments": [], "lines": lines, "neg_alerts": alerts}
    a = {"action_id": m["action_id"], "session_id": m["action_id"], "day": m.get("day", 0)}
    close_and_pay(a, priced=([], sum(ln["n"] * ln["price"] for ln in lines), extra), also=decrement)


def apply_catalogue(cfg):
    """SC-29, inside the caller's transaction: the catalogue as received, and each new stock receipt once."""
    for item, it in (cfg.get("items") or {}).items():
        old = q("SELECT policy FROM items WHERE item_id = ?", (item,))
        policy = old[0][0] if old and MUTANT == "stale_policy" else it.get("policy")  # planted defect: keeps the old
        q("INSERT INTO items VALUES (?,?,?) ON CONFLICT (item_id) DO UPDATE SET price = excluded.price, "
          "policy = excluded.policy", (item, int(it["price"]), policy))
    for r in cfg.get("receipts") or []:
        if not q("SELECT 1 FROM receipts WHERE receipt_id = ?", (r["receipt_id"],)):
            q("INSERT INTO receipts VALUES (?)", (r["receipt_id"],))
            q("INSERT INTO stock VALUES (?, 0) ON CONFLICT (item_id) DO NOTHING", (r["item_id"],))
            q("UPDATE stock SET qty = qty + ? WHERE item_id = ?", (int(r["qty"]), r["item_id"]))


def pull_config():
    """SC-19(d): server-to-device config feed. The epoch changes on every server restore, so a version number
    seen before the restore can come back with different content; compare epoch first."""
    try:
        with urllib.request.urlopen(f"{SERVER}/config?device={DEVICE}", timeout=float(os.environ.get("HTTP_TIMEOUT", "10"))) as r:
            cfg = json.loads(r.read())
        epoch, version, price = str(cfg["epoch"]), int(cfg["version"]), int(cfg["price"])
        prices = json.dumps(cfg.get("prices") or {})
        take_lease(cfg.get("lease"))
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
        q("BEGIN IMMEDIATE")
        q("UPDATE sync_state SET cfg_epoch = ?, cfg_version = ?, cfg_price = ?, cfg_prices = ? WHERE id = 1",
          (epoch, version, price, prices))
        apply_catalogue(cfg)
        q("COMMIT")
    reply({"ok": True, "op": "pull_config", "applied": take, "version": version, "prices": json.loads(prices)})


def verify():
    # Runtime check used by the tamper tests: full integrity check of the open store.
    result = q("PRAGMA integrity_check")
    if result != [("ok",)]:
        raise RuntimeError(f"integrity_check: {result[:3]}")
    reply({"ok": True, "op": "verify"})


def checkpoint():
    reply({"ok": True, "op": "checkpoint", "result": q("PRAGMA wal_checkpoint(TRUNCATE)")})


refused = open_error is not None
if CLOCKED and not refused and not INSPECT:
    try:
        check_outage()
    except (*STORE_ERRORS, RuntimeError) as e:
        record_event("store_error_during_operation", e)
        refused = True
for line in sys.stdin:
    msg = json.loads(line)
    op = msg["op"]
    if op == "exit":
        if con is not None:
            con.close()
        reply({"ok": True, "op": "exit"})
        break
    if refused:
        if isinstance(open_error, InstanceBusy):
            reply({"ok": False, "op": op, "error": "another_instance", "warning": "another_instance"})
        else:
            reply({"ok": False, "op": op, "store": "refused"})
        continue
    gated = ("sale", "start_session", "sell_items", "sell_stock") + (("close_session",) if MUTANT == "expiry_blocks_close" else ())
    if LEASE_ON and op in gated and lease_status()["status"] in ("expired", "none"):
        reply({"ok": False, "op": op, "error": "lease_expired", "warning": "lease_expired"})  # until the server is reached
        report_events()
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
        elif op == "arm_full":  # SC-20
            FullState.armed_at, FullState.writes = int(msg["n"]), 0
            FullState.persistent, FullState.tripped = bool(msg.get("persistent")), False
            reply({"ok": True, "op": op})
        elif op == "arm_marker_full":  # SC-20
            MARKER_FAIL = msg["stage"]
            reply({"ok": True, "op": op})
        elif op == "free_space":  # SC-20: space is back
            if os.environ.get("FULL_SHIM") == "1":
                FullState.armed_at, FullState.tripped = 0, False
            MARKER_FAIL = ""
            report_events()
            reply({"ok": True, "op": op})
        elif op == "schema":  # SC-21a view: schema state of the open store
            cols = {t: [r[1] for r in q(f"PRAGMA table_info({t})")] for t in ("bills", "outbox", "bill_lines")}
            reply({"ok": True, "op": op, "user_version": q("PRAGMA user_version")[0][0],
                   "bills_tax": "tax_piasters" in cols["bills"], "bill_lines": bool(cols["bill_lines"]),
                   "outbox_envelope": "envelope" in cols["outbox"], "premigrate": os.path.exists(PREMIGRATE)})
        elif op == "marker":  # SC-20 view: marker sequence against the store counter
            m = json.load(open(MARKER)) if os.path.exists(MARKER) else {}
            reply({"ok": True, "op": op, "marker_seq": m.get("seq"),
                   "counter": q("SELECT seq FROM counter WHERE id = 1")[0][0], "unreported": len(unreported)})
        elif op == "pull_config":
            pull_config()
        elif op in ("start_session", "change_tier", "close_session", "sell_items", "sell_stock"):  # SC-23, SC-29
            handled = (Exception,) if MUTANT == "swallow_store_errors" else (ValueError, KeyError, IndexError)
            try:
                {"start_session": start_session, "change_tier": change_tier, "close_session": close_session,
                 "sell_items": sell_items, "sell_stock": sell_stock}[op](msg)
            except handled as e:  # no price list, a price missing, an unknown session: refuse the action, not the store
                code = getattr(e, "code", "unknown_session" if isinstance(e, (KeyError, IndexError)) else "invalid")
                reply({"ok": False, "op": op, "error": code, "warning": code, "detail": str(e)[:100]})
        elif op == "end_day":  # SC-31
            end_day()
        elif op == "day_state":
            day_state()
        elif op == "open_tab":
            open_item("tabs", "tab", msg["tab_id"])
        elif op == "open_shift":
            open_item("shifts", "shift", msg["shift_id"])
        elif op == "close_shift":
            close_shift(msg)
        elif op == "pay_tab":
            pay_tab(msg)
        elif op == "tick":  # SC-30: the app's last-alive timer
            tick()
        elif op == "advance_mono":  # SC-25b test hook: time passes on the device's monotonic counter
            clocks["mono_offset"] += float(msg["seconds"])
            clocks["wall_offset"] += float(msg["seconds"])  # the wall clock runs too, unless moved separately
            reply({"ok": True, "op": op})
        elif op == "set_wall_offset":  # SC-25b test hook: someone changes the Windows clock
            clocks["wall_offset"] += float(msg["seconds"])
            reply({"ok": True, "op": op})
        elif op == "export":  # SC-25b: local data stays readable and exportable, lease or not
            rows = q("SELECT action_id, sale_piasters FROM bills ORDER BY seq")
            reply({"ok": True, "op": op, "bills": len(rows), "total_piasters": sum(r[1] for r in rows)})
        elif op == "release_cache":  # test hook (SC-23 f): drop cached pages so the next read comes from disk
            q("PRAGMA shrink_memory")
            reply({"ok": True, "op": op})
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
