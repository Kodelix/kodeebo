# PROTOTYPE - NOT FOR PRODUCTION
# Question: phase 1 tamper scenarios TS-03a (edited encrypted file) and TS-05a (wrong key) on the client store
# Date: 2026-10-16
#
# Pass signals (docs/research/local-first-sync.md § 9.1.1):
#   TS-03a: the app detects the edit, refuses to use the corrupted data (never writes over it) and records
#           the event. A tampered store that opens normally and holds fewer sales than were acknowledged, or a
#           half-applied transaction, is a FAIL ("never lose money silently").
#   TS-05a: fails safely; no partial plaintext; never treats a failed open as a new install; never
#           recreates or overwrites the file; records the event.
# Store design under test (OQ28, founder 2026-10-16): rollback journal (A) + MAC'd commit high-water mark (B).
# WAL cases are kept, run with JOURNAL=wal and the marker on, to show what B alone does for P1-F1.
# Recovery from the server (TS-03b) is phase 3 and is not tested here.
# Run: .venv/bin/python harness/tamper.py   (no server needed: sales are local)
import hashlib
import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
CLIENT_PY = os.path.join(ROOT, "sut", "client.py")
OUT = os.path.join(ROOT, "runs", "tamper")
CIPHERS = ["chacha20", "sqlcipher"]
KEY = os.urandom(32).hex()    # fresh random test key per run, never a real secret
WRONG = os.urandom(32).hex()  # a different random test key
N_SALES = 5
STORE_FILES_SKIP = (".events.jsonl", ".stderr.txt", ".lock")  # .lock: SC-22 instance lock, must stay empty
LOCK_NAME = "client.db.lock"


def lock_is_empty(d):
    """SC-22's lock file is an OS lock handle only: it must never hold data (checked in every tamper row)."""
    p = os.path.join(d, LOCK_NAME)
    return not os.path.exists(p) or os.path.getsize(p) == 0


def sha(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()[:16] if os.path.exists(path) else None


class Client:
    def __init__(self, db, cipher, key, journal="delete", fp=None, cache_pages=None, extra_env=None):
        tmp = os.path.join(os.path.dirname(db), "tmp")
        env = dict(os.environ, STORE="sqlite3mc", CIPHER=cipher, SPIKE_DB_KEY=key, SQLITE_TMPDIR=tmp, TMPDIR=tmp,
                   JOURNAL=journal)
        for k in ("FP", "MUTANT", "CACHE_PAGES"):
            env.pop(k, None)
        if fp:
            env["FP"] = fp
        if cache_pages:
            env["CACHE_PAGES"] = str(cache_pages)
        env.update(extra_env or {})
        self.err = open(db + ".stderr.txt", "a")
        self.p = subprocess.Popen([sys.executable, CLIENT_PY, db, "http://127.0.0.1:9"], env=env, text=True,
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=self.err, bufsize=1)

    def send(self, msg):
        try:
            self.p.stdin.write(json.dumps(msg) + "\n")
            self.p.stdin.flush()
            line = self.p.stdout.readline()
        except BrokenPipeError:
            line = ""
        return json.loads(line) if line else None

    def exit(self):
        r = self.send({"op": "exit"})
        self.p.wait(timeout=30)
        return r, self.p.returncode

    def kill(self):
        self.p.kill()  # SIGKILL: files stay on disk exactly as committed
        self.p.wait()


def sale(i, minutes=45):
    return {"op": "sale", "action_id": f"t-a{i}", "session_id": f"CANARY-t-sess{i}", "start_min": 10 * i,
            "end_min": 10 * i + minutes, "rate_per_hour": 6000, "cafe_piasters": 1500}


def fresh(d):
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(os.path.join(d, "tmp"))
    return os.path.join(d, "client.db")


def build(d, cipher, end, journal="delete"):
    """Make N_SALES acknowledged sales, then close cleanly, SIGKILL, or leave open."""
    db = fresh(d)
    c = Client(db, cipher, KEY, journal)
    acked = sum(1 for i in range(N_SALES) if (c.send(sale(i)) or {}).get("ok"))
    assert acked == N_SALES, f"setup acked {acked}"
    if end == "open":
        return db, c
    c.exit() if end == "clean" else c.kill()
    return db, None


def flip(path, offset):
    with open(path, "r+b") as f:
        f.seek(offset)
        b = f.read(1)
        f.seek(offset)
        f.write(bytes([b[0] ^ 0x01]))


def journal_page1_offset(journal):
    """G5-F4: the file offset of the page-1 record's page data in a rollback journal (header: sector size at byte 20,
    page size at byte 24; records of 4-byte page number, page, 4-byte checksum start one sector in). None if absent."""
    data = open(journal, "rb").read()
    if len(data) < 28:
        return None
    sector, page = int.from_bytes(data[20:24], "big") or 512, int.from_bytes(data[24:28], "big")
    if not page:
        return None
    off = sector
    while off + 4 + page + 4 <= len(data):
        if int.from_bytes(data[off:off + 4], "big") == 1:
            return off + 4
        off += 4 + page + 4
    return None


def events(db):
    p = db + ".events.jsonl"
    return [json.loads(x)["event"] for x in open(p)] if os.path.exists(p) else []


def store_hashes(d):
    return {n: sha(os.path.join(d, n)) for n in os.listdir(d)
            if n.startswith("client.db") and not n.endswith(STORE_FILES_SKIP) and os.path.isfile(os.path.join(d, n))}


def probe_after(db, cipher, key, journal="delete"):
    """Start the client and see what it does with the store."""
    d = os.path.dirname(db)
    before = store_hashes(d)
    c = Client(db, cipher, key, journal)
    stats = c.send({"op": "stats"})
    s = c.send(sale(99))
    _, rc = c.exit()
    rec = db + ".recovery"
    copies = sorted(os.listdir(rec), key=int) if os.path.isdir(rec) else []
    preserved = bool(copies) and all(sha(os.path.join(rec, copies[-1], n)) == h for n, h in before.items())
    return {"stats": stats, "sale_reply": s, "exit_rc": rc, "events": events(db), "originals_preserved": preserved,
            "main_db_unchanged": before.get("client.db") == sha(db), "lock_empty": lock_is_empty(d),
            "traceback": "Traceback" in open(db + ".stderr.txt").read()}


def refused(r):
    return (r["stats"] or {}).get("store") == "refused"


def classify(r, expect_sales):
    """PASS: refused + recorded + file not written; or opened with exactly the expected consistent state."""
    st = r["stats"] or {}
    if refused(r):
        if r["events"] and (r["main_db_unchanged"] or r["originals_preserved"]) and not r["traceback"] and r["lock_empty"]:
            how = "file not written" if r["main_db_unchanged"] else "SQLite recovery rewrote the file; originals preserved byte-identical"
            return "PASS", f"detected, refused, recorded ({r['events'][-1]}); {how}"
        return "FAIL", (f"refused but recorded={bool(r['events'])} unchanged={r['main_db_unchanged']} "
                        f"traceback={r['traceback']} lock_empty={r['lock_empty']}")
    counts = [st.get(k) for k in ("bills", "payments", "minute_actions", "outbox", "counter")]
    consistent = len(set(counts)) == 1 and st.get("integrity") == "ok"
    if consistent and counts[0] == expect_sales:
        return "PASS (no loss)", f"opened normally with all {expect_sales} expected sales, consistent"
    if consistent and counts[0] < expect_sales:
        return "FAIL", f"SILENT LOSS: opened normally with {counts[0]} of {expect_sales} sales, no event"
    return "FAIL", f"SILENT INCONSISTENCY: bills/payments/minutes/outbox/counter = {counts}, integrity {st.get('integrity')}"


def row(cipher, scenario, verdict, detail, **extra):
    return {"cipher": cipher, "scenario": scenario, "verdict": verdict, "detail": detail, **extra}


def ts03(cipher):
    rows = []
    base = os.path.join(OUT, cipher, "ts03")

    # Main database file, rollback-journal store (A + B).
    for name, off_fn in [("db_middle_page", lambda db: (os.path.getsize(db) // 4096 // 2) * 4096 + 777),
                         ("db_page1", lambda db: 300)]:
        db, _ = build(os.path.join(base, name), cipher, "clean")
        off = off_fn(db)
        flip(db, off)
        r = probe_after(db, cipher, KEY)
        rows.append(row(cipher, name, *classify(r, N_SALES), flipped=f"client.db@{off}"))

    # Hot journal: crash mid-transaction on a big 6th sale with a tiny page cache, so changed pages spill to the
    # main file and the rollback journal holds the originals. Restart must roll back to exactly 5 sales.
    for name, do_flip in [("hot_journal_crash_control", False), ("hot_journal_crash_flip", True)]:
        d = os.path.join(base, name)
        db, _ = build(d, cipher, "clean")
        c = Client(db, cipher, KEY, fp="client:mid_local_txn:1", cache_pages=5)
        c.send(sale(5, minutes=4000))  # killed before COMMIT
        c.p.wait()
        journal = db + "-journal"
        if not os.path.exists(journal) or os.path.getsize(journal) < 1024:
            rows.append(row(cipher, name, "NOT ASSESSED", "no hot journal on disk after the crash"))
            continue
        info = f"journal {os.path.getsize(journal)} bytes"
        if do_flip:
            off = os.path.getsize(journal) // 2
            flip(journal, off)
            info += f", flipped @{off}"
        r = probe_after(db, cipher, KEY)
        rows.append(row(cipher, name, *classify(r, N_SALES), flipped=info))

    # G5-F4 (desktop round 4): SQLite replays a hot journal inside the open call, before any app check, so a damaged
    # image of page 1 is written over the store. A sale does not journal page 1 before COMMIT; a schema change does.
    # Kill the app update's migration (SC-21a) mid-DDL, damage page 1's record in the hot journal, start the old app:
    # the store must be refused and recorded, with the pre-open originals kept byte-identical (copied before open).
    name = "hot_journal_page1_flip"
    db, _ = build(os.path.join(base, name), cipher, "clean")
    c = Client(db, cipher, KEY, fp="migrate:mid_ddl:1", cache_pages=5, extra_env={"SCHEMA_VERSION": "2"})
    c.p.wait()  # the migration runs at start and is killed inside its transaction
    journal = db + "-journal"
    base_off = journal_page1_offset(journal) if os.path.exists(journal) else None
    if base_off is None:
        rows.append(row(cipher, name, "NOT ASSESSED", "no page-1 record in the hot journal after the kill"))
    else:
        off = base_off + 200
        flip(journal, off)
        r = probe_after(db, cipher, KEY)
        rows.append(row(cipher, name, *classify(r, N_SALES),
                        flipped=f"journal {os.path.getsize(journal) if os.path.exists(journal) else 0} bytes, "
                                f"page-1 record flipped @{off}"))

    # Commit marker (B).
    for name in ("marker_flipped", "marker_deleted"):
        db, _ = build(os.path.join(base, name), cipher, "clean")
        if name == "marker_flipped":
            flip(db + ".hwm", 10)
        else:
            os.remove(db + ".hwm")
        r = probe_after(db, cipher, KEY)
        rows.append(row(cipher, name, *classify(r, N_SALES)))

    # Store older than its marker: copy the store after 3 sales, make 2 more, put the old copy back.
    d = os.path.join(base, "store_older_than_marker")
    db = fresh(d)
    c = Client(db, cipher, KEY)
    for i in range(3):
        c.send(sale(i))
    c.exit()
    shutil.copy(db, db + ".copy-after-3")
    c = Client(db, cipher, KEY)
    for i in range(3, 5):
        c.send(sale(i))
    c.exit()
    shutil.copy(db + ".copy-after-3", db)
    r = probe_after(db, cipher, KEY)
    rows.append(row(cipher, "store_older_than_marker", *classify(r, N_SALES)))

    # While running: flip a main-file page under the open app, ask it to verify, then restart.
    d = os.path.join(base, "db_page_while_running")
    db, c = build(d, cipher, "open")
    flip(db, (os.path.getsize(db) // 4096 // 2) * 4096 + 777)
    v = c.send({"op": "verify"})
    c.exit()
    r = probe_after(db, cipher, KEY)
    verdict, detail = classify(r, N_SALES)
    runtime = (v or {}).get("store") == "refused"
    rows.append(row(cipher, "db_page_while_running",
                    verdict if runtime or not verdict.startswith("PASS") else "PASS (at next start)",
                    f"runtime verify reply {v}; next start: {detail}"))

    # P1-F1 cases in WAL mode with the marker on: does B turn silent loss into detected loss?
    for name, off_fn in [("wal_header", lambda w, ps, n: 20),
                         ("wal_first_frame", lambda w, ps, n: 32 + 24 + 100),
                         ("wal_last_frame", lambda w, ps, n: 32 + (n - 1) * (24 + ps) + 24 + 100)]:
        db, _ = build(os.path.join(base, "walmode-" + name), cipher, "kill", journal="wal")
        wal = db + "-wal"
        ps = 4096
        n = (os.path.getsize(wal) - 32) // (24 + ps)
        flip(wal, off_fn(wal, ps, n))
        r = probe_after(db, cipher, KEY, journal="wal")
        verdict, detail = classify(r, N_SALES)
        rows.append(row(cipher, "walmode+marker-" + name, verdict,
                        detail + " (sales in the damaged WAL are still lost; the marker makes it visible)"
                        if verdict == "PASS" else detail))
    return rows


def ts05(cipher):
    rows = []
    d = os.path.join(OUT, cipher, "ts05")
    db, _ = build(d, cipher, "clean")
    original = sha(db)
    other = "sqlcipher" if cipher == "chacha20" else "chacha20"
    for name, ciph, key, times in [("wrong_key", cipher, WRONG, 1), ("truncated_key", cipher, KEY[:62], 1),
                                   ("empty_key", cipher, "", 1), ("right_key_wrong_cipher", other, KEY, 1),
                                   ("wrong_key_x20", cipher, WRONG, 20)]:
        results = [probe_after(db, ciph, key) for _ in range(times)]
        ok = all(refused(r) and (r["sale_reply"] or {}).get("store") == "refused" and r["events"]
                 and r["exit_rc"] == 0 and not r["traceback"] for r in results)
        unchanged = sha(db) == original
        stray = sorted(n for n in os.listdir(d) if n.startswith("client.db") and
                       n not in ("client.db", "client.db.hwm", "client.db.events.jsonl", "client.db.stderr.txt", "client.db.recovery",
                                 LOCK_NAME))
        if not lock_is_empty(d):
            stray.append(LOCK_NAME + " (not empty)")
        rows.append(row(cipher, name, "PASS" if ok and unchanged and not stray else "FAIL",
                        f"all refused and recorded={ok}; file unchanged={unchanged}; extra files={stray}", attempts=times))
    r = probe_after(db, cipher, KEY)
    rows.append(row(cipher, "right_key_after_attempts", *classify(r, N_SALES)))
    leaks = [n for n in os.listdir(d) if n.startswith("client.db") and not n.endswith(STORE_FILES_SKIP)
             and b"CANARY" in open(os.path.join(d, n), "rb").read()]
    rows.append(row(cipher, "ts04a_plaintext_scan", "PASS" if not leaks else "FAIL",
                    f"canary found in {leaks}" if leaks else "no canary in any store file"))
    return rows


# The scenarios every cipher must produce, in order (checked against README "Pinned cell lists" before the run,
# and against the rows actually produced after it).
TAMPER_SCENARIOS = ["db_middle_page", "db_page1", "hot_journal_crash_control", "hot_journal_crash_flip",
                    "hot_journal_page1_flip",
                    "marker_flipped", "marker_deleted", "store_older_than_marker", "db_page_while_running",
                    "walmode+marker-wal_header", "walmode+marker-wal_first_frame", "walmode+marker-wal_last_frame",
                    "wrong_key", "truncated_key", "empty_key", "right_key_wrong_cipher", "wrong_key_x20",
                    "right_key_after_attempts", "ts04a_plaintext_scan"]

if __name__ == "__main__":
    import pins
    pins.check("tamper-scenarios", TAMPER_SCENARIOS)
    all_rows = []
    for cipher in CIPHERS:
        rows = ts03(cipher) + ts05(cipher)
        pins.check(f"tamper-scenarios", [r["scenario"] for r in rows])  # the code produced exactly the pinned rows
        all_rows += rows
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "tamper-summary.json"), "w") as f:
        json.dump(all_rows, f, indent=1)
    for r in all_rows:
        print(f"{r['cipher']:9s} {r['scenario']:34s} {r['verdict']:16s} {r['detail'][:170]}")
    sys.exit(0 if all(r["verdict"].startswith("PASS") for r in all_rows) else 1)
