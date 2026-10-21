# PROTOTYPE - NOT FOR PRODUCTION
# P4-F5 option 4, founder questions (2026-10-20): the background check finds the store damaged AFTER the counter has
# already sold on it. What happens to the sales made in that window?
# Pass condition for every cell (founder): NO SALE IS LOST SILENTLY. Every sale the counter acknowledged ends in exactly
# one of: on the server once (applied normally if it synced before the fault; otherwise through the salvage, which reads
# only rows that pass the page HMAC, and flagged "salvaged" for the owner); or inside a reported lost range
# (store_fault_unreadable, counted from the MAC'd marker) with an owner alert. A sale that vanishes without a count
# fails. Also: no sale is acknowledged after the fault is known; the damaged store is kept unchanged until the contact.
#   bgwindow.py run [seeds]                cells x seeds, then the mutants
#   bgwindow.py replay <seed> <cell> [mutant]
# Every cell: 200 sales synced, the app stops; it restarts with START_CHECK=background and sells while the copy runs.
#   end_online / end_offline   before the restart, the LAST leaf page of the minutes table is damaged (the background
#                              copy reads pages in order, so it finds the fault late); the window's sales are synced
#                              every 3 sales (online) or the server is down for the whole window (offline)
#   salepages_start_offline    before the restart, the pages the new sales will be written to and that the bounded
#                              start check does not read: the last leaf of the bills and of the minutes table
#   salepages_window_offline / salepages_window_online
#                              worst case: after 10 window sales are acknowledged, the pages that hold them are damaged
#                              while the app runs (every outbox page and the last leaf of the bills), as a disk that goes
#                              bad mid-day; some acknowledged sales may then be unrecoverable and must be counted
import hashlib
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import driver  # noqa: E402
from driver import Run, RETENTION_ENV, git_state, RUNS  # noqa: E402

import apsw  # noqa: E402

CELLS = ["end_online", "end_offline", "salepages_start_offline", "salepages_window_offline",
         "salepages_window_online"]
CLIENT_MUTANTS = ["bg_fault_ignored", "rebootstrap_no_salvage", "salvage_hides_lost"]  # need client lines
SERVER_MUTANTS = ["salvage_silent"]
HOT = ("counter", "sync_state", "outbox", "business_day", "sqlite_schema")


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()


def pages(db, key, table, kind=None, cold_only=False):
    """Page numbers of a table (read through a decrypting connection; safe while the app runs: a read lock only)."""
    c = apsw.Connection(db)
    c.set_busy_timeout(5000)
    c.execute("PRAGMA cipher = chacha20").fetchall()
    c.execute(f"PRAGMA key = 'raw:{key}'").fetchall()
    ps = c.execute("PRAGMA page_size").fetchall()[0][0]
    hot = set()
    if cold_only:  # pages the bounded start check (hot tables + page 1) never reads
        for tb in HOT:
            hot |= {r[0] for r in c.execute("SELECT pageno FROM dbstat WHERE name = ?", (tb,)).fetchall()}
    q_ = "SELECT pageno FROM dbstat WHERE name = ?" + (" AND pagetype = ?" if kind else "") + " ORDER BY pageno"
    got = [r[0] for r in c.execute(q_, (table, kind) if kind else (table,)).fetchall() if r[0] not in hot]
    c.close()
    return ps, got


def rightmost_leaf(db, key, table):
    """The leaf page an append to `table` writes to: the last leaf in key order (the largest dbstat path)."""
    c = apsw.Connection(db)
    c.set_busy_timeout(5000)
    c.execute("PRAGMA cipher = chacha20").fetchall()
    c.execute(f"PRAGMA key = 'raw:{key}'").fetchall()
    rows = c.execute("SELECT pageno, path FROM dbstat WHERE name = ? AND pagetype = 'leaf'", (table,)).fetchall()
    c.close()
    return max(rows, key=lambda r: [int(x, 16) for x in r[1].strip("/").split("/") if x])[0]


def damage(db, pgs, ps):
    with open(db, "r+b") as f:
        for pg in pgs:
            off = (pg - 1) * ps + ps // 2
            f.seek(off)
            b = f.read(8)
            f.seek(off)
            f.write(bytes(x ^ 0xFF for x in b))
        f.flush()
        os.fsync(f.fileno())


def script_for(cell):
    def script(run):
        st = run.win = {"cell": cell, "window": [], "synced_before_fault": [], "sent": []}

        def drain():
            for _ in range(30):
                r = run.send({"op": "sync"})
                if r and r.get("ok") and r.get("pending") == 0:
                    return

        for i in range(200):
            run.sale(i)
        drain()
        run.send({"op": "exit"})
        run.client.wait()
        online = cell.endswith("_online")
        if cell.startswith("end_"):
            # the highest-numbered minutes leaf that new sales never write to: not the rightmost leaf in the table's
            # key order (an append goes there), which dbstat names by the largest path
            ps, mins = pages(run.db, run.key, "minutes", "leaf", cold_only=True)
            right = rightmost_leaf(run.db, run.key, "minutes")
            target = [max(p_ for p_ in mins if p_ != right)]
        elif cell == "salepages_start_offline":
            ps, mins = pages(run.db, run.key, "minutes", "leaf", cold_only=True)
            _, bills = pages(run.db, run.key, "bills", "leaf", cold_only=True)
            target = [bills[-1], mins[-1]]
        else:
            target = []  # damaged during the window
        if target:
            damage(run.db, target, ps)
        st["damaged_pages"] = target
        st["damaged_sha"] = sha(run.db) if target else None
        if not online:
            run.server_down = True
            run.server.terminate()
            run.server.wait()
        st["start_reply"] = run.send({"op": "marker"})  # the bounded start check passes: the page is not a hot one
        bgs, k = {}, 0
        for k in range(400):
            i = 300 + k
            run.sale(i)
            aid = f"s{run.seed}-a{i}"
            r = run.sale_replies.get(aid) or {}
            if r.get("ok"):
                st["window"].append(aid)
            else:  # refused: store_fault after the check, or a store error on a damaged page (the cashier sees it)
                st.setdefault("refused", []).append((aid, r.get("error") or r.get("store") or r))
                if "sha_at_fault" not in st:  # the fault is known (the check, or an operation that read the damage)
                    st["fault_after"] = len(st["window"])
                    st["sha_at_fault"] = sha(run.db) if os.path.exists(run.db) else None
                if bgs.get("state") == "fault" or len(st["refused"]) >= 3:
                    st["first_refused"] = st["refused"][0][0]
                    break
            if cell.startswith("salepages_window") and len(st["window"]) == 10 and not st["damaged_pages"]:
                ps, ob = pages(run.db, run.key, "outbox")
                _, bills = pages(run.db, run.key, "bills", "leaf")
                st["damaged_pages"] = ob + [bills[-1]]
                damage(run.db, st["damaged_pages"], ps)  # a disk going bad under acknowledged sales
                st["damaged_sha"] = sha(run.db)
            if online and k % 3 == 2:
                st["sent"] = list(st["window"])  # every pending window sale goes out in this attempt
                r = run.send({"op": "sync"})
                if r and r.get("ok") and r.get("pending") == 0:
                    st["synced_before_fault"] = list(st["window"])
            bgs = run.send({"op": "bg_state"}) or {}
            if bgs.get("state") == "fault" and "sha_at_fault" not in st:
                st["fault_after"] = len(st["window"])  # every later sale must be refused
                st["sha_at_fault"] = sha(run.db) if os.path.exists(run.db) else None
            # 10 sales close together (no idle gap: the copy waits), then pauses long enough for the copy to finish:
            # today's copy restarts at every sale (its own connection), so it completes only in an idle gap
            time.sleep(0.05 if len(st["window"]) < 10 else 2.0)
        st["bg_final"] = {x: bgs.get(x) for x in ("state", "fault", "pages", "total")}
        # from the moment the fault is known, nothing may write to the damaged store before the contact
        st["damaged_untouched"] = st.get("sha_at_fault") is not None and os.path.exists(run.db) and \
            sha(run.db) == st["sha_at_fault"]
        if not online:
            run.server_down = False
            run.start_server()
        st["contact_reply"] = run.send({"op": "sync"})
        for i in range(800, 805):
            run.sale(i)
        drain()
    return script


def extra(run, dump):
    st, v = run.win, []
    acked = {a: s_ for a, s_ in run.seq_of.items() if s_}
    ledger = {r["action_id"]: r for r in dump["ledger"] if r["kind"] == "sale"}
    review = {r["seq"] for r in dump.get("review_queue", []) if r["reason"] == "salvaged"}
    lost = {s_ for r in dump.get("lost_seqs", []) if r["reason"] == "store_fault_unreadable"
            for s_ in range(r["from_seq"], r["to_seq"] + 1)}
    alerts = [e for e in dump.get("device_events", []) if e.get("kind") == "store_fault_salvage"]
    synced, sent = set(st["synced_before_fault"]), set(st["sent"])
    win = st["window"]
    st["outcome"] = {"window": len(win), "on_server": sum(1 for a in win if a in ledger),
                     "flagged": sum(1 for a in win if a in ledger and acked[a] in review),
                     "counted_lost": sum(1 for a in win if a not in ledger and acked[a] in lost),
                     "silent": sum(1 for a in win if a not in ledger and acked[a] not in lost)}
    if not win and st["cell"] != "salepages_start_offline":  # there the first sale may hit a damaged page at once
        v.append(("W0", "no sale was acknowledged in the window: the case proves nothing (harness)"))
    # W1 (founder): no sale lost silently, and a counted range never holds a sale the server has (no double count)
    for a, s_ in acked.items():
        if a not in ledger and s_ not in lost:
            v.append(("W1", f"{a} (seq {s_}) acknowledged, not on the server and not counted: lost silently"))
        if a in ledger and s_ in lost:
            v.append(("W1", f"{a} (seq {s_}) is on the server but also reported lost"))
    if lost and not alerts:
        v.append(("W1", "unrecoverable sales were counted but the owner was not alerted"))
    # W2: synced before the fault (the sync replied) -> applied normally, never flagged; never sent before the fault
    # -> it can reach the server only through the salvage, so it must be flagged. A sale sent in a sync attempt that
    # did not reply (the operation that found the damage) may have been applied normally by that batch: either way.
    for a in win:
        if a in synced and acked[a] in review:
            v.append(("W2", f"{a} was synced before the fault but is flagged salvaged"))
        if a not in sent and a in ledger and acked[a] not in review:
            v.append(("W2", f"{a} reached the server only through the salvage but is not flagged for the owner"))
    # W3: the fault stops sales; nothing is acknowledged once the fault is known
    if "first_refused" not in st:
        v.append(("W3", f"no sale was refused after the fault: {st.get('bg_final')}"))
    if st.get("fault_after") is not None and len(win) > st["fault_after"]:
        v.append(("W3", f"{len(win) - st['fault_after']} sale(s) acknowledged after the background check reported the fault"))
    # W4: the owner is told, the damaged store is kept unchanged until the contact, and the contact recovers the device
    if not alerts:
        v.append(("W4", "no owner alert for the store fault"))
    if not st.get("damaged_untouched"):
        v.append(("W4", "the damaged store changed before the contact"))
    if not (st.get("contact_reply") or {}).get("ok"):
        v.append(("W4", f"the contact did not recover the device: {st.get('contact_reply')}"))
    return v, frozenset(a for a, s_ in acked.items() if a not in ledger and s_ in lost)


def run_one(seed, cell, mutant=None, label=None):
    srv_m = mutant if mutant in SERVER_MUTANTS else None
    cli_m = mutant if mutant in CLIENT_MUTANTS else None
    run = Run(seed, cli_m, store="sqlite3mc", cipher="chacha20", fault=[], label=label or f"bgwindow-{cell}",
              client_env={**RETENTION_ENV, "REBOOTSTRAP": "1", "SALVAGE": "1", "START_CHECK": "background",
                          "BG_IDLE_S": "0.3", "BG_STEP": "16"},
              server_env={"MUTANT": srv_m} if srv_m else None)
    run.store_refusal_expected = True
    run.script, run.extra = script_for(cell), extra
    r = run.go()
    r["win"] = run.win
    return r


def main(seeds=5):
    t0 = time.time()
    summary = {"harness_commit": git_state(), "cells": {}, "mutants": {}}
    print(f"P4-F5 window sales (background check finds the fault after sales), commit {summary['harness_commit']}",
          flush=True)
    ok = True
    for cell in CELLS:
        bad, ex = 0, None
        for s in range(1, seeds + 1):
            r = run_one(s, cell)
            bad += bool(r["violations"])
            ex = ex or {k: r["win"].get(k) for k in ("outcome", "first_refused", "bg_final")}
            if r["violations"]:
                print(f"  {cell} seed {s}: {r['violations'][:3]}", flush=True)
        summary["cells"][cell] = {"seeds": seeds, "violating": bad, "example": ex}
        ok &= bad == 0
        print(f"  {cell:8s} violating {bad}/{seeds}  example {ex}  {'PASS' if not bad else 'FAIL'}", flush=True)
    for m in CLIENT_MUTANTS + SERVER_MUTANTS:
        caught = None
        for cell in ("end_offline", "salepages_window_offline", "end_online"):
            r = run_one(1, cell, m, label=f"bgwindow-mutant-{m}")
            if r["violations"]:
                caught = (cell, r["violations"][0])
                break
        summary["mutants"][m] = caught
        ok &= caught is not None
        print(f"  mutant {m:24s} {'CAUGHT in ' + caught[0] + ': ' + str(caught[1]) if caught else 'SURVIVED'}",
              flush=True)
    summary["result"] = "PASS" if ok else "FAIL"
    summary["seconds"] = round(time.time() - t0, 1)
    with open(os.path.join(RUNS, "bgwindow-summary.json"), "w") as f:
        json.dump(summary, f, indent=1, default=str)
    print(f"P4-F5 window sales: {summary['result']} ({summary['seconds']} s)")


if __name__ == "__main__":
    if sys.argv[1] == "run":
        main(int(sys.argv[2]) if len(sys.argv) > 2 else 5)
    else:
        r = run_one(int(sys.argv[2]), sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else None)
        print(json.dumps({"violations": r["violations"], "fired": r["fired"], "win": r["win"]}, indent=1, default=str))
