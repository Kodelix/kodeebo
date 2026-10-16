# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does local-first sync ever lose or double-count money or session time under faults? (phase 0 client stub)
# Date: 2026-10-16
#
# Client stub driven by JSON lines on stdin, one JSON reply per line on stdout.
# Local store: plain SQLite (encryption is phase 1), WAL, synchronous=FULL.
# Correct mode writes bill + payment + minutes + sequence counter + outbox row in ONE transaction.
# Env: MUTANT (separate_outbox_txn | double_minute), FP=name:hit (SIGKILL self at that point).
import hashlib
import http.client
import json
import os
import signal
import sqlite3
import sys
import urllib.error
import urllib.request

DB, SERVER, DEVICE = sys.argv[1], sys.argv[2], "dev-1"
MUTANT = os.environ.get("MUTANT", "")
FP = os.environ.get("FP", "")
FP_NAME, FP_AT = (FP.rsplit(":", 1)[0], int(FP.rsplit(":", 1)[1])) if FP else ("", 0)
fp_count = 0


def failpoint(name):
    global fp_count
    if name != FP_NAME:
        return
    fp_count += 1
    if fp_count == FP_AT:
        sys.stdout.flush()
        os.kill(os.getpid(), signal.SIGKILL)


con = sqlite3.connect(DB, isolation_level=None, timeout=5)
con.execute("PRAGMA journal_mode=WAL")
con.execute("PRAGMA synchronous=FULL")
con.executescript("""
CREATE TABLE IF NOT EXISTS bills (action_id TEXT PRIMARY KEY, session_id TEXT, sale_piasters INTEGER);
CREATE TABLE IF NOT EXISTS payments (action_id TEXT, piasters INTEGER);
CREATE TABLE IF NOT EXISTS minutes (action_id TEXT, session_id TEXT, minute_idx INTEGER);
CREATE TABLE IF NOT EXISTS counter (id INTEGER PRIMARY KEY CHECK (id = 1), seq INTEGER NOT NULL);
INSERT OR IGNORE INTO counter VALUES (1, 0);
CREATE TABLE IF NOT EXISTS outbox (seq INTEGER PRIMARY KEY, command_id TEXT UNIQUE, payload TEXT,
  payload_hash TEXT, status TEXT NOT NULL);
""")


def reply(obj):
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


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
        con.execute("INSERT INTO bills VALUES (?,?,?)", (a["action_id"], a["session_id"], sale))
        con.execute("INSERT INTO payments VALUES (?,?)", (a["action_id"], sale))
        con.executemany("INSERT INTO minutes VALUES (?,?,?)", [(a["action_id"], a["session_id"], m) for m in mins])

    def outbox():
        seq = con.execute("UPDATE counter SET seq = seq + 1 WHERE id = 1 RETURNING seq").fetchone()[0]
        con.execute("INSERT INTO outbox VALUES (?,?,?,?, 'pending')", (seq, cmd_id, body, h))

    failpoint("client:before_local_commit")  # P1
    if MUTANT == "separate_outbox_txn":  # planted defect: two transactions
        con.execute("BEGIN IMMEDIATE"); business(); con.execute("COMMIT")
        failpoint("client:after_business_commit")  # P3 exists only here
        con.execute("BEGIN IMMEDIATE"); outbox(); con.execute("COMMIT")
    else:
        con.execute("BEGIN IMMEDIATE")
        business()
        outbox()
        failpoint("client:mid_local_txn")  # P2: before COMMIT
        con.execute("COMMIT")
    failpoint("client:after_local_commit")  # P4: committed, not yet acknowledged
    reply({"ok": True, "op": "sale", "action_id": a["action_id"]})


def post(cmds):
    req = urllib.request.Request(SERVER + "/batch", method="POST",
                                 data=json.dumps({"device_id": DEVICE, "commands": cmds}).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read())


def rows_to_cmds(rows):
    return [{"command_id": c, "seq": s, "payload_hash": h, "payload": json.loads(p)} for s, c, p, h in rows]


def pending_count():
    return con.execute("SELECT count(*) FROM outbox WHERE status = 'pending'").fetchone()[0]


def sync():
    rows = con.execute("SELECT seq, command_id, payload, payload_hash FROM outbox WHERE status = 'pending' "
                       "ORDER BY seq LIMIT 50").fetchall()
    if not rows:
        return reply({"ok": True, "op": "sync", "pending": 0})
    failpoint("client:before_send")  # P4/P5
    try:
        resp = post(rows_to_cmds(rows))
    except (urllib.error.URLError, ConnectionError, TimeoutError, OSError, http.client.HTTPException, ValueError) as e:  # truncated reply = failed sync (P0-F2)
        return reply({"ok": False, "op": "sync", "error": str(e)[:120], "pending": pending_count()})
    failpoint("client:after_response_before_mark")  # P10
    con.execute("BEGIN IMMEDIATE")
    for r in resp["results"] or []:
        if r["result"] in ("applied", "duplicate"):
            con.execute("UPDATE outbox SET status = 'acked' WHERE command_id = ?", (r["command_id"],))
        elif r["result"] in ("payload_mismatch", "seq_conflict"):
            con.execute("UPDATE outbox SET status = 'conflict' WHERE command_id = ?", (r["command_id"],))
    con.execute("COMMIT")
    failpoint("client:after_mark")  # P12
    reply({"ok": True, "op": "sync", "results": resp["results"], "pending": pending_count()})


def replay(k):
    # Duplicate resend (SC-04): send the last k acknowledged commands again, unchanged.
    rows = con.execute("SELECT seq, command_id, payload, payload_hash FROM outbox WHERE status = 'acked' "
                       "ORDER BY seq DESC LIMIT ?", (k,)).fetchall()[::-1]
    if not rows:
        return reply({"ok": True, "op": "replay", "sent": 0})
    try:
        resp = post(rows_to_cmds(rows))
    except (urllib.error.URLError, ConnectionError, TimeoutError, OSError, http.client.HTTPException, ValueError) as e:  # truncated reply = failed sync (P0-F2)
        return reply({"ok": False, "op": "replay", "error": str(e)[:120]})
    reply({"ok": True, "op": "replay", "sent": len(rows), "results": resp["results"]})


for line in sys.stdin:
    msg = json.loads(line)
    op = msg["op"]
    if op == "sale":
        close_and_pay(msg)
    elif op == "sync":
        sync()
    elif op == "replay":
        replay(msg["k"])
    elif op == "exit":
        con.close()
        reply({"ok": True, "op": "exit"})
        break
