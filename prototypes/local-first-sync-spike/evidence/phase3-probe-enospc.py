# PROTOTYPE - NOT FOR PRODUCTION
# Question: phase 3 probe for SC-20 (disk full). (1) Can an apsw VFS shim above SQLite3MC fail the n-th write with
#           SQLITE_FULL while the cipher still applies? (2) After SQLITE_FULL inside "close and pay", is the
#           transaction still open (statement rolled back) or gone (whole transaction rolled back)? (sync note F443)
#           (3) The same on a real size-capped tmpfs (run inside `unshare -r -m`, see run line).
# Date: 2026-10-16
# Run (from the prototype folder):
#   .venv/bin/python evidence/phase3-probe-enospc.py shim <empty-dir>
#   unshare -r -m sh -c 'mount -t tmpfs -o size=96k tmpfs <empty-dir> && .venv/bin/python evidence/phase3-probe-enospc.py real <empty-dir>'
import os
import sys

import apsw

mode, work = sys.argv[1], sys.argv[2]
KEY = os.urandom(32).hex()  # fresh random test key per run, never a real secret
print("apsw", apsw.apsw_version(), "| sqlite", apsw.sqlite_lib_version(), "|", apsw.mc_version)


class State:
    armed_at = 0  # fail the n-th write after arming (0 = off)
    writes = 0
    persistent = False
    tripped = False


class FullFile(apsw.VFSFile):
    def __init__(self, vfs, name, flags):
        super().__init__(vfs, name, flags)

    def xWrite(self, data, offset):
        if State.armed_at:
            State.writes += 1
            if State.tripped and State.persistent or State.writes == State.armed_at:
                State.tripped = True
                raise apsw.FullError("injected SQLITE_FULL")
        return super().xWrite(data, offset)


class FullVFS(apsw.VFS):
    def __init__(self):
        self.base = apsw.vfs_names()[0]  # the default VFS: SQLite3MC's cipher shim when it is the default
        super().__init__("fullshim", self.base)

    def xOpen(self, name, flags):
        return FullFile(self.base, name, flags)


def connect(path, vfs=None):
    c = apsw.Connection(path, vfs=vfs) if vfs else apsw.Connection(path)
    c.execute("PRAGMA cipher = chacha20").fetchall()
    c.execute(f"PRAGMA key = 'raw:{KEY}'").fetchall()
    c.execute("PRAGMA journal_mode=DELETE").fetchall()
    c.execute("PRAGMA synchronous=FULL").fetchall()
    return c


def setup(c):
    c.execute("CREATE TABLE IF NOT EXISTS bills (id INTEGER PRIMARY KEY, body TEXT)")
    c.execute("CREATE TABLE IF NOT EXISTS outbox (id INTEGER PRIMARY KEY, body TEXT)")


def close_and_pay(c, n, pad):
    c.execute("BEGIN IMMEDIATE")
    c.execute("INSERT INTO bills (body) VALUES (?)", (f"CANARY-bill-{n}" + "x" * pad,))
    c.execute("INSERT INTO outbox (body) VALUES (?)", (f"cmd-{n}" + "y" * pad,))
    c.execute("COMMIT")


def counts(c):
    return c.execute("SELECT (SELECT count(*) FROM bills), (SELECT count(*) FROM outbox)").fetchone()


if mode == "shim":
    print("VFS list:", apsw.vfs_names()[:4])
    vfs = FullVFS()
    for cache, persistent in ((None, False), (None, True), (2, False), (2, True)):
        if cache:
            print(f"-- cache_size={cache}: dirty pages spill to disk mid-transaction, so writes happen before COMMIT")
        for n in range(1, 9):
            path = os.path.join(work, f"shim-{cache}-{int(persistent)}-{n}.db")
            c = connect(path, vfs="fullshim")
            setup(c)
            close_and_pay(c, 0, 50)
            if cache:
                c.execute(f"PRAGMA cache_size={cache}").fetchall()
            State.armed_at, State.writes, State.persistent, State.tripped = n, 0, persistent, False
            err = None
            try:
                close_and_pay(c, 1, 3000)  # bigger rows: several page writes
            except apsw.Error as e:
                err = type(e).__name__
            in_txn = c.in_transaction
            State.armed_at = 0
            if in_txn:
                c.execute("ROLLBACK")
            print(f"persistent={persistent} fail write #{n}: error={err}, txn still open={in_txn}, "
                  f"after ROLLBACK counts={counts(c)}, integrity={c.execute('PRAGMA integrity_check').fetchone()[0]}")
            c.close()
            raw = open(path, "rb").read()
            if b"CANARY" in raw or raw.startswith(b"SQLite format 3"):
                print("  WARNING: plaintext on disk through the shim")
elif mode == "pagecap":
    # SQLITE_FULL that is not an I/O error: the page-count limit. Fail the SECOND statement of "close and pay".
    path = os.path.join(work, "pagecap.db")
    c = connect(path)
    setup(c)
    close_and_pay(c, 0, 50)
    pages = c.execute("PRAGMA page_count").fetchone()[0]
    c.execute(f"PRAGMA max_page_count = {pages + 2}").fetchall()
    c.execute("BEGIN IMMEDIATE")
    c.execute("INSERT INTO bills (body) VALUES (?)", ("CANARY-bill-1",))  # fits
    err = None
    try:
        c.execute("INSERT INTO outbox (body) VALUES (?)", ("y" * 20000,))  # needs more pages than allowed
    except apsw.Error as e:
        err = f"{type(e).__name__}: {e}"
    in_txn = c.in_transaction
    print(f"pagecap: outbox insert failed with {err}; txn still open={in_txn}; "
          f"inside the open txn counts={counts(c) if in_txn else 'n/a'}")
    if in_txn:  # what an app that does NOT roll back would commit
        c.execute("COMMIT")
        print(f"COMMIT without ROLLBACK -> counts={counts(c)}: a bill without its outbox row")
    c.close()
elif mode == "real":
    path = os.path.join(work, "real.db")
    c = connect(path)
    setup(c)
    n, err = 0, None
    while err is None and n < 1000:
        n += 1
        try:
            close_and_pay(c, n, 2000)
        except apsw.Error as e:
            err = f"{type(e).__name__}: {e}"
    in_txn = c.in_transaction
    print(f"real tmpfs: sale {n} failed with {err}; txn still open={in_txn}")
    if in_txn:
        c.execute("ROLLBACK")
    print(f"after ROLLBACK counts={counts(c)} (expected {n - 1} each), integrity={c.execute('PRAGMA integrity_check').fetchone()[0]}")
    print("files:", sorted(os.listdir(work)))
    c.close()
