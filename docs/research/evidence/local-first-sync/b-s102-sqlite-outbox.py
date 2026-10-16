# b-s102-sqlite-outbox.py: probes of the client-side transactional outbox on plain SQLite (NOT SQLCipher).
# Run: python3 -I b-s102-sqlite-outbox.py <work-dir>
# Shows: (1) business rows + outbox row commit or vanish together across a hard process exit;
#        (2) AUTOINCREMENT ids can gap after a failed insert, a counter-row sequence cannot;
#        (3) a copy restored from a backup reuses sequence numbers already sent.
import os, sqlite3, subprocess, sys, json

work = sys.argv[1]
os.makedirs(work, exist_ok=True)

SCHEMA = """
CREATE TABLE IF NOT EXISTS payment(id INTEGER PRIMARY KEY, bill_id TEXT NOT NULL, amount_piasters INTEGER NOT NULL CHECK(amount_piasters>=0));
CREATE TABLE IF NOT EXISTS device_seq(only_row INTEGER PRIMARY KEY CHECK(only_row=1), next_seq INTEGER NOT NULL);
INSERT OR IGNORE INTO device_seq VALUES (1, 1);
CREATE TABLE IF NOT EXISTS outbox(
  device_seq INTEGER PRIMARY KEY,            -- gap-free per-device sequence, assigned inside the business transaction
  command_id TEXT NOT NULL UNIQUE,           -- client-generated, stable across retries
  payload TEXT NOT NULL,
  sent_state TEXT NOT NULL DEFAULT 'pending' -- pending | sent | acked | rejected
);
"""

def connect(path):
    c = sqlite3.connect(path, isolation_level=None)   # autocommit; we issue BEGIN IMMEDIATE ourselves
    c.execute("PRAGMA journal_mode=WAL"); c.execute("PRAGMA synchronous=FULL")
    c.executescript(SCHEMA)
    return c

def record_action(c, bill, amount, cmd, crash_before_commit=False):
    """One business action: payment row + outbox row in ONE local transaction."""
    c.execute("BEGIN IMMEDIATE")
    try:
        c.execute("INSERT INTO payment(bill_id,amount_piasters) VALUES (?,?)", (bill, amount))
        seq = c.execute("SELECT next_seq FROM device_seq").fetchone()[0]
        c.execute("UPDATE device_seq SET next_seq=next_seq+1")
        c.execute("INSERT INTO outbox(device_seq,command_id,payload) VALUES (?,?,?)",
                  (seq, cmd, json.dumps({"bill": bill, "amount_piasters": amount})))
        if crash_before_commit:
            os._exit(9)            # hard exit, no rollback, no atexit: simulates power loss / kill -9 mid-transaction
        c.execute("COMMIT")
        return seq
    except Exception:
        c.execute("ROLLBACK"); raise

if len(sys.argv) > 2 and sys.argv[2] == "child-crash":
    c = connect(os.path.join(work, "t1.db")); record_action(c, "B2", 7500, "cmd-crash", crash_before_commit=True)

print("python", sys.version.split()[0], "sqlite", sqlite3.sqlite_version)
print("\n=== (1) atomicity across a hard exit")
p = os.path.join(work, "t1.db")
for f in (p, p + "-wal", p + "-shm"):
    if os.path.exists(f): os.remove(f)
c = connect(p)
print("committed action -> seq", record_action(c, "B1", 5000, "cmd-1"))
c.close()
r = subprocess.run([sys.executable, "-I", os.path.abspath(__file__), work, "child-crash"], capture_output=True)
print("child exit code (9 = os._exit before COMMIT):", r.returncode)
c = connect(p)
print("payments:", c.execute("SELECT bill_id,amount_piasters FROM payment ORDER BY id").fetchall())
print("outbox  :", c.execute("SELECT device_seq,command_id,sent_state FROM outbox ORDER BY device_seq").fetchall())
print("next_seq:", c.execute("SELECT next_seq FROM device_seq").fetchone()[0])
print("integrity_check:", c.execute("PRAGMA integrity_check").fetchone()[0])
c.close()

print("\n=== (2) AUTOINCREMENT gap after a failed insert vs counter-row sequence")
q = sqlite3.connect(":memory:", isolation_level=None)
q.execute("CREATE TABLE a(id INTEGER PRIMARY KEY AUTOINCREMENT, k TEXT UNIQUE)")
q.execute("INSERT INTO a(k) VALUES ('x')")                      # id 1
try: q.execute("INSERT INTO a(k) VALUES ('x')")                 # unique violation
except sqlite3.IntegrityError as e: print("expected failure:", e)
q.execute("BEGIN"); q.execute("INSERT INTO a(k) VALUES ('rolledback')"); q.execute("ROLLBACK")
q.execute("INSERT INTO a(k) VALUES ('y')")
print("AUTOINCREMENT ids:", [r[0] for r in q.execute("SELECT id FROM a ORDER BY id")], "(a gap shows a consumed id)")
print("sqlite_sequence  :", q.execute("SELECT name,seq FROM sqlite_sequence").fetchall())
c = connect(os.path.join(work, "t2.db"))
for i in range(3):
    record_action(c, f"B{i}", 100 + i, f"cmd-ok-{i}")
try: record_action(c, "BAD", -5, "cmd-bad")                     # CHECK violation -> whole transaction rolls back
except sqlite3.IntegrityError as e: print("expected failure:", e)
record_action(c, "B9", 900, "cmd-ok-9")
print("counter-row outbox seqs:", [r[0] for r in c.execute("SELECT device_seq FROM outbox ORDER BY device_seq")])
c.close()

print("\n=== (3) backup restore reuses sequence numbers the server already holds")
live = os.path.join(work, "t3.db"); bak = os.path.join(work, "t3.bak.db")
for f in (live, live + "-wal", live + "-shm", bak):
    if os.path.exists(f): os.remove(f)
c = connect(live)
for i in range(1, 4): record_action(c, f"B{i}", 1000 * i, f"cmd-live-{i}")
b = sqlite3.connect(bak); c.backup(b); b.close()               # backup API (desktop-note F107)
for i in range(4, 7): record_action(c, f"B{i}", 1000 * i, f"cmd-live-{i}")   # seq 4..6 are sent to the server
server_inbox = {r[0]: (r[1], r[2]) for r in c.execute("SELECT device_seq,command_id,payload FROM outbox")}
c.close()
print("server holds seq:", sorted(server_inbox))
r = sqlite3.connect(bak, isolation_level=None)                  # the restored copy
r.execute("PRAGMA journal_mode=WAL"); r.executescript(SCHEMA)
new_seq = record_action(r, "B4x", 4242, "cmd-restored-4")
print("restored device now issues seq", new_seq, "command cmd-restored-4")
held = server_inbox.get(new_seq)
print("server already has seq", new_seq, "with command", held[0], "->",
      "SAME command: replay" if held[0] == "cmd-restored-4" else "DIFFERENT command for a used seq: clone/restore signal")
