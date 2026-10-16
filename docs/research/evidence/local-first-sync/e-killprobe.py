#!/usr/bin/env python3
"""Tier-E mechanism probe (NOT a finding about any product design).
Shows that an enumerated-failpoint + SIGKILL + independent-oracle harness detects the
'client crash between local commit and outbox enqueue' defect (fault point P3) in a
deliberately bad design B, and passes the single-transaction design A.
Toy: plain SQLite (python stdlib), no encryption, no network, no server. Linux only (SIGKILL).
Usage: python3 -I e-killprobe.py <reps_per_point>
"""
import os, signal, sqlite3, subprocess, sys, tempfile, json

def child(design, die_at, db):
    con = sqlite3.connect(db, isolation_level=None)
    con.execute("PRAGMA journal_mode=WAL"); con.execute("PRAGMA synchronous=FULL")
    con.execute("CREATE TABLE IF NOT EXISTS bill(id TEXT PRIMARY KEY, amount INTEGER)")
    con.execute("CREATE TABLE IF NOT EXISTS outbox(action_id TEXT PRIMARY KEY, amount INTEGER)")
    def fp(name):
        if die_at == name: os.kill(os.getpid(), signal.SIGKILL)
    fp("before_begin")
    if design == "A":              # bill + outbox in ONE local transaction
        con.execute("BEGIN IMMEDIATE")
        con.execute("INSERT INTO bill VALUES('b1',500)")
        fp("mid_tx")
        con.execute("INSERT INTO outbox VALUES('b1',500)")
        con.execute("COMMIT")
        fp("after_commit")
    else:                          # design B: two transactions (the defect)
        con.execute("BEGIN IMMEDIATE"); con.execute("INSERT INTO bill VALUES('b1',500)")
        fp("mid_tx")
        con.execute("COMMIT")
        fp("after_bill_commit")    # P3: bill committed, outbox not yet written
        con.execute("BEGIN IMMEDIATE"); con.execute("INSERT INTO outbox VALUES('b1',500)"); con.execute("COMMIT")
        fp("after_commit")
    print("ACK b1", flush=True)   # the user-visible acknowledgement

def oracle(db, acked):
    con = sqlite3.connect(db)
    ok = con.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
    bills = {r[0] for r in con.execute("SELECT id FROM bill")} if con.execute("SELECT name FROM sqlite_master WHERE name='bill'").fetchone() else set()
    outb = {r[0] for r in con.execute("SELECT action_id FROM outbox")} if con.execute("SELECT name FROM sqlite_master WHERE name='outbox'").fetchone() else set()
    # I1(local): every committed bill has exactly an outbox row; every acked bill is present
    return ok and bills == outb and acked <= bills, {"integrity": ok, "bills": sorted(bills), "outbox": sorted(outb)}

if __name__ == "__main__":
    if sys.argv[1] == "--child":
        child(sys.argv[2], sys.argv[3], sys.argv[4]); sys.exit(0)
    reps = int(sys.argv[1])
    print("sqlite lib version:", sqlite3.sqlite_version, "python:", sys.version.split()[0])
    points = {"A": ["before_begin", "mid_tx", "after_commit", "none"],
              "B": ["before_begin", "mid_tx", "after_bill_commit", "after_commit", "none"]}
    for design, pts in points.items():
        for p in pts:
            viol = 0
            for _ in range(reps):
                d = tempfile.mkdtemp(prefix="killprobe-"); db = os.path.join(d, "t.db")
                r = subprocess.run([sys.executable, "-I", os.path.abspath(__file__), "--child", design, p, db],
                                   capture_output=True, text=True)
                acked = {"b1"} if "ACK b1" in r.stdout else set()
                good, info = oracle(db, acked)
                if not good: viol += 1; last = info
            print(f"design {design} kill_at={p:<18} runs={reps} violations={viol}" + (f" example={json.dumps(last)}" if viol else ""))
