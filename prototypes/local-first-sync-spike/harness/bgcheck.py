# PROTOTYPE - NOT FOR PRODUCTION
# P4-F5 option 4 on Linux: the start check modes against a damaged page that the bounded start check does not read.
# A store of 1,500 sales (minute rows fill many pages); one byte flipped in a page of the minutes table's data, at a
# page the hot-table check (counter, sync_state, outbox, business_day) never reads.
#   background          -> ready at once; the background copy/check finds the fault; later sales refused; event
#   partial             -> ready at once; nothing finds the fault while the counter sells (the control: why option 4)
#   full                -> refused at start (the phase 0-3 rule)
#   background_unclean  -> after a kill with a hot journal: the full check runs before any sale
#   background (clean)  -> on an undamaged store the background check ends "ok" and sales go on
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tamper as t  # noqa: E402

import apsw  # noqa: E402

N = 1500
OUT = os.path.join(t.ROOT, "runs", "bgcheck")


def store(name, end="clean"):
    db = t.fresh(os.path.join(OUT, name))
    c = t.Client(db, "chacha20", t.KEY)
    for i in range(N):
        r = c.send(t.sale(i, minutes=120))
        assert (r or {}).get("ok"), r
    if end == "open":
        return db, c
    c.exit() if end == "clean" else c.kill()
    return db, None


def minutes_page_offset(db):
    """The file offset of a leaf page of the minutes table, from dbstat over a decrypting connection."""
    c = apsw.Connection(db)
    c.execute("PRAGMA cipher = chacha20").fetchall()
    c.execute(f"PRAGMA key = 'raw:{t.KEY}'").fetchall()
    ps = c.execute("PRAGMA page_size").fetchall()[0][0]
    hot = set()
    for tb in ("counter", "sync_state", "outbox", "business_day", "sqlite_schema"):
        hot |= {r[0] for r in c.execute("SELECT pageno FROM dbstat WHERE name = ?", (tb,)).fetchall()}
    pages = [r[0] for r in c.execute("SELECT pageno FROM dbstat WHERE name = 'minutes' AND pagetype = 'leaf'").fetchall()
             if r[0] not in hot]
    c.close()
    pg = pages[len(pages) // 2]
    return (pg - 1) * ps + ps // 2, pg


def run(mode, damaged=True, end="clean", stress=False):
    name = f"{mode}-{'damaged' if damaged else 'clean'}-{end}" + ("-stress" if stress else "")
    db, c = store(name, "open" if end == "kill" else "clean")
    if end == "kill":
        c.send({"op": "sale", "action_id": "k", "session_id": "k", "start_min": 0, "end_min": 5, "rate_per_hour": 6000,
                "cafe_piasters": 0})
        c.kill()
    pg = None
    if damaged:
        off, pg = minutes_page_offset(db)
        t.flip(db, off)
    t0 = time.perf_counter()
    env = {"START_CHECK": mode, "BG_IDLE_S": "0.2", "BG_STEP": "16"}
    if stress:  # set 2 finding: a sale that arrived during a copy step failed (ThreadingViolationError) and the store
        env.update(BG_IDLE_S="0", BG_STEP="400")  # was refused; now it must wait for the step: long steps, short gaps
    cl = t.Client(db, "chacha20", t.KEY, extra_env=env)
    first = cl.send({"op": "marker"})  # a light first op (stats reads every table)
    ready_ms = round((time.perf_counter() - t0) * 1000, 1)
    sales, refused_at, bg = [], None, {}
    for k in range(200):
        r = cl.send(t.sale(10000 + k, minutes=5))
        sales.append(bool((r or {}).get("ok")))
        if r and r.get("error") == "store_fault" and refused_at is None:
            refused_at = k
        bg = cl.send({"op": "bg_state"}) or {}
        if bg.get("state") in ("ok", "fault") and k > 2 and (bg.get("state") == "ok" or refused_at is not None):
            break
        time.sleep(0.02 if stress else 0.3)
    _, rc = cl.exit()
    return {"case": name, "damaged_page": pg, "ready_ms": ready_ms, "store_at_start": "refused" if (first or {}).get("store") == "refused" else ("open" if first else "no reply"),
            "sales_ok": sum(sales), "sales_tried": len(sales), "first_refused_sale": refused_at,
            "bg_state": bg.get("state"), "bg_fault": bg.get("fault"), "events": t.events(db)}


if __name__ == "__main__":
    rows = [run("background"), run("partial"), run("full"), run("background_unclean", end="kill"),
            run("background", damaged=False), run("background", damaged=False, stress=True)]
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "summary.json"), "w") as f:
        json.dump(rows, f, indent=1)
    for r in rows:
        print(json.dumps(r))
