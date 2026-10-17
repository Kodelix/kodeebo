#!/usr/bin/env python3 -I
"""S40b run 2: same canary method as run 1 but with secure_delete explicitly OFF, to show the free-page residue of
an unencrypted SQLite file, and what VACUUM, journal_mode=PERSIST and WAL do under OFF. Unencrypted worst case only;
the encrypted store (SQLCipher/SQLite3MC) is PENDING - S41 (not available here)."""
import os, sqlite3, sys, tempfile
CANARY = b"CANARY-TENANT-A-ORDER-"; N = 300
def count(p):
    try:
        return open(p, "rb").read().count(CANARY)
    except FileNotFoundError:
        return None
def size(p):
    return os.path.getsize(p) if os.path.exists(p) else None
def fill(con):
    con.execute("CREATE TABLE IF NOT EXISTS orders(id INTEGER PRIMARY KEY, note TEXT)")
    con.executemany("INSERT INTO orders(note) VALUES (?)", [(CANARY.decode() + str(i) + "-" + "x" * 40,) for i in range(N)]); con.commit()
d = tempfile.mkdtemp(prefix="ti-p4-s40b2-")
print("sqlite3", sqlite3.sqlite_version)
def run(label, mode, post=None, close_before_count=True):
    p = os.path.join(d, label + ".db")
    con = sqlite3.connect(p); con.execute("PRAGMA journal_mode=" + mode); con.execute("PRAGMA secure_delete=OFF")
    print("%-28s journal_mode=%s secure_delete=%s" % (label, con.execute("PRAGMA journal_mode").fetchone()[0], con.execute("PRAGMA secure_delete").fetchone()[0]))
    fill(con)
    con.execute("DELETE FROM orders"); con.commit()
    if mode == "WAL":
        con.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    print("   after DELETE (+TRUNCATE checkpoint in WAL mode): db canaries=%s journal canaries=%s wal canaries=%s db bytes=%s" % (count(p), count(p + "-journal"), count(p + "-wal"), size(p)))
    if post:
        con.execute(post); con.commit() if con.in_transaction else None
        print("   after %s: db canaries=%s journal canaries=%s journal exists=%s db bytes=%s" % (post, count(p), count(p + "-journal"), os.path.exists(p + "-journal"), size(p)))
    con.close()
run("off-delete-mode", "DELETE")
run("off-delete-mode-vacuum", "DELETE", post="VACUUM")
run("off-wal-mode", "WAL")
run("off-wal-mode-vacuum", "WAL", post="VACUUM")
run("off-persist-mode", "PERSIST")
run("off-persist-mode-vacuum", "PERSIST", post="VACUUM")
import shutil; shutil.rmtree(d); print("work dir removed")
