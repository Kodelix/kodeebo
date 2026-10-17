#!/usr/bin/env python3 -I
"""S40b: what plaintext residue does a plain (unencrypted) SQLite file keep after DELETE, and what do
secure_delete, VACUUM, WAL checkpoint modes and journal_mode=PERSIST do about it?
This is the worst case for an UNENCRYPTED store; SQLCipher / SQLite3MC are NOT available here, so the encrypted
case is PENDING - S41. Canary strings are counted in the raw bytes of each file. Files live in a fresh mkdtemp dir."""
import os, shutil, sqlite3, sys, tempfile

CANARY = b"CANARY-TENANT-A-ORDER-"
N = 300

def count(path):
    try:
        with open(path, "rb") as f:
            return f.read().count(CANARY)
    except FileNotFoundError:
        return None

def size(path):
    try:
        return os.path.getsize(path)
    except FileNotFoundError:
        return None

def fresh(d, name):
    p = os.path.join(d, name)
    for s in ("", "-wal", "-shm", "-journal"):
        if os.path.exists(p + s):
            os.remove(p + s)
    return p

def fill(con):
    con.execute("CREATE TABLE IF NOT EXISTS orders(id INTEGER PRIMARY KEY, note TEXT)")
    con.executemany("INSERT INTO orders(note) VALUES (?)", [(CANARY.decode() + str(i) + "-" + "x" * 40,) for i in range(N)])
    con.commit()

d = tempfile.mkdtemp(prefix="ti-p4-s40b-")
print("sqlite3 library version:", sqlite3.sqlite_version, "python", sys.version.split()[0])
con = sqlite3.connect(":memory:")
print("compile option SECURE_DELETE present:", any("SECURE_DELETE" in r[0] for r in con.execute("PRAGMA compile_options")))
con.close()

def case_basic(label, pre=None, post=None, mode="DELETE"):
    p = fresh(d, label + ".db")
    con = sqlite3.connect(p, isolation_level=None)
    con.execute("PRAGMA journal_mode=%s" % mode)
    if pre:
        con.execute(pre)
    con.execute("BEGIN"); fill(con) if False else None
    con.execute("COMMIT")
    con.isolation_level = ""
    fill(con)
    before = count(p)
    con.execute("DELETE FROM orders"); con.commit()
    after_delete = count(p)
    if post:
        con.execute(post); con.commit() if con.in_transaction else None
    after_post = count(p)
    sd = con.execute("PRAGMA secure_delete").fetchone()[0]
    con.close()
    print("%-34s secure_delete=%s canaries: after insert=%s after DELETE=%s after post-step=%s  file bytes=%s" % (label, sd, before, after_delete, after_post, size(p)))

print("--- main file after DELETE of all rows (rollback-journal mode, connection closed afterwards)")
case_basic("default-delete-only")
case_basic("secure_delete-ON-before-delete", pre="PRAGMA secure_delete=ON")
case_basic("secure_delete-FAST-before-delete", pre="PRAGMA secure_delete=FAST")
case_basic("default-then-VACUUM", post="VACUUM")

print("--- WAL mode: canaries in the -wal file, then checkpoint modes (connection kept open, files read while open)")
p = fresh(d, "wal.db")
con = sqlite3.connect(p); con.execute("PRAGMA journal_mode=WAL"); con.execute("PRAGMA synchronous=FULL"); fill(con)
print("after insert+commit: db canaries=%s  wal canaries=%s wal bytes=%s" % (count(p), count(p + "-wal"), size(p + "-wal")))
con.execute("DELETE FROM orders"); con.commit()
print("after DELETE+commit: db canaries=%s  wal canaries=%s wal bytes=%s" % (count(p), count(p + "-wal"), size(p + "-wal")))
r = con.execute("PRAGMA wal_checkpoint(PASSIVE)").fetchone()
print("after checkpoint(PASSIVE) %s: db canaries=%s  wal canaries=%s wal bytes=%s" % (r, count(p), count(p + "-wal"), size(p + "-wal")))
r = con.execute("PRAGMA wal_checkpoint(TRUNCATE)").fetchone()
print("after checkpoint(TRUNCATE) %s: db canaries=%s  wal canaries=%s wal bytes=%s" % (r, count(p), count(p + "-wal"), size(p + "-wal")))
con.close()
print("after close: wal file exists=%s" % os.path.exists(p + "-wal"))

print("--- WAL mode with secure_delete=ON and journal_size_limit=0 (does the -wal keep canaries after a full checkpoint?)")
p = fresh(d, "wal2.db")
con = sqlite3.connect(p); con.execute("PRAGMA journal_mode=WAL"); con.execute("PRAGMA secure_delete=ON"); con.execute("PRAGMA journal_size_limit=0"); fill(con)
con.execute("DELETE FROM orders"); con.commit()
r = con.execute("PRAGMA wal_checkpoint(RESTART)").fetchone()
print("after DELETE+checkpoint(RESTART) %s: db canaries=%s wal canaries=%s wal bytes=%s" % (r, count(p), count(p + "-wal"), size(p + "-wal")))
con.execute("INSERT INTO orders(note) VALUES ('small')"); con.commit()
print("after one more small commit: wal canaries=%s wal bytes=%s" % (count(p + "-wal"), size(p + "-wal")))
con.close()

print("--- rollback journal: pre-images of deleted pages are in the -journal while the transaction is open")
p = fresh(d, "jr.db")
con = sqlite3.connect(p); con.execute("PRAGMA journal_mode=DELETE"); fill(con)
con.execute("DELETE FROM orders")          # open transaction, not committed
print("during uncommitted DELETE: journal exists=%s journal canaries=%s journal bytes=%s" % (os.path.exists(p + "-journal"), count(p + "-journal"), size(p + "-journal")))
snap = p + "-journal.copy"; shutil.copy(p + "-journal", snap)
con.commit()
print("after commit (journal_mode=DELETE): journal exists=%s ; the copy taken during the transaction still holds canaries=%s" % (os.path.exists(p + "-journal"), count(snap)))
con.close()

print("--- journal_mode=PERSIST: the journal file stays after commit with only its header zeroed")
p = fresh(d, "jp.db")
con = sqlite3.connect(p); con.execute("PRAGMA journal_mode=PERSIST"); fill(con)
con.execute("DELETE FROM orders"); con.commit()
print("after commit (PERSIST): journal exists=%s journal canaries=%s journal bytes=%s" % (os.path.exists(p + "-journal"), count(p + "-journal"), size(p + "-journal")))
con.close()
print("after close (PERSIST): journal exists=%s journal canaries=%s" % (os.path.exists(p + "-journal"), count(p + "-journal")))

print("--- journal_mode=TRUNCATE")
p = fresh(d, "jt.db")
con = sqlite3.connect(p); con.execute("PRAGMA journal_mode=TRUNCATE"); fill(con)
con.execute("DELETE FROM orders"); con.commit()
print("after commit (TRUNCATE): journal exists=%s journal bytes=%s" % (os.path.exists(p + "-journal"), size(p + "-journal")))
con.close()
shutil.rmtree(d)
print("work dir removed")
