# PROTOTYPE - NOT FOR PRODUCTION
# Question: phase 1 probe - apsw + SQLite3MC API behaviour the encrypted client stub relies on
# Date: 2026-10-16
# Run: prototypes/local-first-sync-spike/.venv/bin/python evidence/phase1-probe-apsw.py <empty-work-dir>
import os
import sys

import apsw

work = sys.argv[1]
KEY = os.urandom(32).hex()  # fresh random test key per run, never a real secret
WRONG = os.urandom(32).hex()
print("apsw", apsw.apsw_version(), "| sqlite", apsw.sqlite_lib_version(), "|", apsw.mc_version)
print("has Connection.execute:", hasattr(apsw.Connection, "execute"),
      "| set_busy_timeout:", hasattr(apsw.Connection, "set_busy_timeout"),
      "| Cursor.fetchone:", hasattr(apsw.Cursor, "fetchone"))


def keysql(cipher, hexkey):
    return f"PRAGMA key = 'raw:{hexkey}'" if cipher == "chacha20" else f"PRAGMA key = \"x'{hexkey}'\""


def open_db(path, cipher, hexkey):
    c = apsw.Connection(path)
    c.execute(f"PRAGMA cipher = {cipher}").fetchall()
    r = c.execute(keysql(cipher, hexkey)).fetchall()
    return c, r


for cipher in ("chacha20", "sqlcipher"):
    p = os.path.join(work, f"probe-{cipher}.db")
    c, r = open_db(p, cipher, KEY)
    print(f"\n[{cipher}] PRAGMA key result rows: {r}")
    c.execute("PRAGMA journal_mode=WAL").fetchall()
    c.execute("CREATE TABLE t (x TEXT)")
    c.execute("INSERT INTO t VALUES ('CANARY-PROBE-1')")
    print(f"[{cipher}] read back:", c.execute("SELECT x FROM t").fetchone())
    c.close()
    with open(p, "rb") as f:
        head = f.read(16)
    raw = open(p, "rb").read()
    print(f"[{cipher}] header is plaintext 'SQLite format 3': {head.startswith(b'SQLite format 3')} | canary in file: {b'CANARY' in raw}")
    # wrong key
    c, r = open_db(p, cipher, WRONG)
    print(f"[{cipher}] wrong key: PRAGMA key result rows {r}")
    try:
        print(f"[{cipher}] wrong key read:", c.execute("SELECT count(*) FROM sqlite_master").fetchone())
    except apsw.Error as e:
        print(f"[{cipher}] wrong key read raises {type(e).__name__}: {e}")
    c.close()
    print(f"[{cipher}] file unchanged after wrong-key open: {open(p, 'rb').read() == raw}")
