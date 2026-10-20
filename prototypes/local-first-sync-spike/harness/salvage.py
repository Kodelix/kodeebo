# PROTOTYPE - NOT FOR PRODUCTION
# OQ31 (founder 2026-10-20), method (A): the store fails its check while the device is offline and the outbox holds
# sales the server never saw. Expected: no new sales; the damaged store and a copy kept untouched; every command whose
# pages pass the cipher's authentication salvaged into a small salvage store; at the next contact the salvage goes up
# first (applied once, flagged "salvaged" for the owner), then the re-bootstrap; every unreadable sequence is one
# reported lost range with an owner alert; nothing is sold on a fresh empty store.
#   salvage.py run [seeds]           cells x seeds, then the mutants
#   salvage.py replay <seed> <cell> [mutant]
# Cells (40 synced sales, then the server goes away, 30 more sales, the app stops, a page is damaged):
#   i_outside      a leaf page of the minutes table (neither the outbox nor the retained bills)
#   ii_outbox      every page of the outbox (the retained bills still hold the commands)
#   iii_both       every page of the outbox and the last leaf page of the bills (some commands unreadable)
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

CELLS = ["i_outside", "ii_outbox", "iii_both"]
CLIENT_MUTANTS = ["rebootstrap_no_salvage", "salvage_after_rebootstrap", "sell_on_fresh"]
SERVER_MUTANTS = ["salvage_silent"]


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()


def pages(db, key, table, kind=None):
    c = apsw.Connection(db)
    c.execute("PRAGMA cipher = chacha20").fetchall()
    c.execute(f"PRAGMA key = 'raw:{key}'").fetchall()
    ps = c.execute("PRAGMA page_size").fetchall()[0][0]
    q_ = "SELECT pageno, pagetype FROM dbstat WHERE name = ?" + (" AND pagetype = ?" if kind else "") + " ORDER BY pageno"
    rows = c.execute(q_, (table, kind) if kind else (table,)).fetchall()
    c.close()
    return ps, [r[0] for r in rows]


def damage(db, key, pgnos, ps):
    with open(db, "r+b") as f:
        for pg in pgnos:
            off = (pg - 1) * ps + ps // 2
            f.seek(off)
            b = f.read(8)
            f.seek(off)
            f.write(bytes(x ^ 0xFF for x in b))


def script_for(cell):
    def script(run):
        st = run.salv = {"cell": cell}

        def drain():
            for _ in range(30):
                r = run.send({"op": "sync"})
                if r and r.get("ok") and r.get("pending") == 0:
                    return

        for i in range(40):
            run.sale(i)
        drain()
        run.server_down = True  # the device goes offline
        run.server.terminate()
        run.server.wait()
        for i in range(40, 70):
            run.sale(i)
        run.send({"op": "exit"})
        run.client.wait()
        ps, outbox = pages(run.db, run.key, "outbox")
        if cell == "i_outside":
            _, mins = pages(run.db, run.key, "minutes", "leaf")
            target = [mins[len(mins) // 2]]
        elif cell == "ii_outbox":
            target = outbox
        else:
            _, bills = pages(run.db, run.key, "bills", "leaf")
            target = outbox + [bills[-1]]
        damage(run.db, run.key, target, ps)
        st["damaged_pages"], st["damaged_sha"] = target, sha(run.db)
        r = run.send({"op": "marker"})  # the app starts offline: the full check refuses, the salvage runs
        st["start_reply"] = r
        aid = f"s{run.seed}-offline"
        r = run.send({"op": "sale", "action_id": aid, "session_id": aid, "start_min": 0, "end_min": 5,
                      "rate_per_hour": 6000, "cafe_piasters": 0})
        st["offline_sale"] = r  # must be refused: no selling on a fresh store, no selling on the damaged one
        if r and r.get("ok"):
            run.intent.execute("INSERT INTO actions VALUES (?,?)", (aid, json.dumps(
                {"op": "sale", "action_id": aid, "session_id": aid, "start_min": 0, "end_min": 5, "rate_per_hour": 6000,
                 "cafe_piasters": 0})))
            run.intent.execute("INSERT INTO acks VALUES (?)", (aid,))
        st["salvage_exists"] = os.path.exists(run.db + ".salvage")
        st["fault_copy"] = os.path.isdir(run.db + ".fault-copy")
        st["damaged_untouched_offline"] = os.path.exists(run.db) and sha(run.db) == st["damaged_sha"]
        run.server_down = False  # the next contact (a phone hotspot)
        run.start_server()
        st["contact_reply"] = run.send({"op": "sync"})
        for i in range(100, 105):
            run.sale(i)
        drain()
        kept = [x for x in os.listdir(run.dir) if ".damaged-" in x]
        st["damaged_kept"] = any(os.path.exists(os.path.join(run.dir, k, "client.db")) and
                                 sha(os.path.join(run.dir, k, "client.db")) == st["damaged_sha"] for k in kept)
    return script


def extra(run, dump):
    st, v = run.salv, []
    lost = {s for r in dump.get("lost_seqs", []) for s in range(r["from_seq"], r["to_seq"] + 1)}
    unreadable = {s for r in dump.get("lost_seqs", []) if r["reason"] == "store_fault_unreadable"
                  for s in range(r["from_seq"], r["to_seq"] + 1)}
    st["lost"], st["unreadable"] = sorted(lost), sorted(unreadable)
    ledger = {r["action_id"]: r for r in dump["ledger"] if r["kind"] == "sale"}
    allowed = frozenset(a for a, s in run.seq_of.items() if s in lost and a not in ledger)
    # R71: a sale missing from the server is allowed only inside a reported lost range, and a reported range holds
    # no sale the server has (no double counting)
    for a, s in run.seq_of.items():
        if s in lost and a in ledger:
            v.append(("R71", f"seq {s} reported lost but {a} is on the server"))
    alerts = [e for e in dump.get("device_events", []) if e.get("kind") == "store_fault_salvage"]
    if (unreadable or st.get("salvaged_n")) and not alerts:
        v.append(("R71", "no owner alert for the salvage / the unreadable range"))
    review = {r["seq"] for r in dump.get("review_queue", []) if r["reason"] == "salvaged"}
    unsynced = {s for a, s in run.seq_of.items() if s and 41 <= s <= 70}
    on_server = {r["seq"] for r in ledger.values()}
    st["salvaged_flagged"] = len(review & unsynced)
    if (unsynced & on_server) - review:
        v.append(("R72", f"salvaged sales applied without the owner's review flag: {sorted((unsynced & on_server) - review)[:5]}"))
    if (st.get("offline_sale") or {}).get("ok"):
        v.append(("R73", "a sale was accepted offline after the store fault (fresh store or damaged store)"))
    if not st.get("salvage_exists") or not st.get("fault_copy") or not st.get("damaged_untouched_offline"):
        v.append(("R74", f"salvage store {st.get('salvage_exists')}, fault copy {st.get('fault_copy')}, damaged store "
                         f"untouched offline {st.get('damaged_untouched_offline')}"))
    if not st.get("damaged_kept"):
        v.append(("R74", "the damaged store was not kept aside unchanged after the re-bootstrap"))
    if not (st.get("contact_reply") or {}).get("ok"):
        v.append(("R75", f"the contact did not recover the device: {st.get('contact_reply')}"))
    return v, allowed


def run_one(seed, cell, mutant=None, label=None):
    srv_m = mutant if mutant in SERVER_MUTANTS else None
    cli_m = mutant if mutant in CLIENT_MUTANTS else None
    run = Run(seed, cli_m, store="sqlite3mc", cipher="chacha20", fault=[], label=label or f"salvage-{cell}",
              client_env={**RETENTION_ENV, "REBOOTSTRAP": "1", "SALVAGE": "1", "START_CHECK": "full"},
              server_env={"MUTANT": srv_m} if srv_m else None)
    run.store_refusal_expected = True
    run.script, run.extra = script_for(cell), extra
    r = run.go()
    r["salvage"] = run.salv
    return r


def main(seeds=5):
    t0 = time.time()
    summary = {"harness_commit": git_state(), "cells": {}, "mutants": {}}
    print(f"OQ31 salvage (method A), commit {summary['harness_commit']}", flush=True)
    ok = True
    for cell in CELLS:
        bad, ex = 0, None
        for s in range(1, seeds + 1):
            r = run_one(s, cell)
            bad += bool(r["violations"])
            ex = ex or {k: r["salvage"].get(k) for k in ("lost", "unreadable", "salvaged_flagged", "offline_sale",
                                                         "contact_reply")}
            if r["violations"]:
                print(f"  {cell} seed {s}: {r['violations'][:3]}", flush=True)
        summary["cells"][cell] = {"seeds": seeds, "violating": bad, "example": ex}
        ok &= bad == 0
        print(f"  {cell:10s} violating {bad}/{seeds}  lost {ex['lost']} unreadable {ex['unreadable']} "
              f"salvaged+flagged {ex['salvaged_flagged']}  {'PASS' if not bad else 'FAIL'}", flush=True)
    for m in CLIENT_MUTANTS + SERVER_MUTANTS:
        caught = None
        for cell in CELLS:
            r = run_one(1, cell, m, label=f"salvage-mutant-{m}")
            if r["violations"]:
                caught = (cell, r["violations"][0])
                break
        summary["mutants"][m] = caught
        ok &= caught is not None
        print(f"  mutant {m:26s} {'CAUGHT in ' + caught[0] + ': ' + str(caught[1]) if caught else 'SURVIVED'}", flush=True)
    summary["result"] = "PASS" if ok else "FAIL"
    summary["seconds"] = round(time.time() - t0, 1)
    with open(os.path.join(RUNS, "salvage-summary.json"), "w") as f:
        json.dump(summary, f, indent=1, default=str)
    print(f"OQ31 salvage: {summary['result']} ({summary['seconds']} s)")


if __name__ == "__main__":
    if sys.argv[1] == "run":
        main(int(sys.argv[2]) if len(sys.argv) > 2 else 5)
    else:
        r = run_one(int(sys.argv[2]), sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else None)
        print(json.dumps({"violations": r["violations"], "fired": r["fired"], "salvage": r["salvage"]}, indent=1,
                         default=str))
