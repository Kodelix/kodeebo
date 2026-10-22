# PROTOTYPE - NOT FOR PRODUCTION
"""S42: time a counter sale that writes its bill line, N stock-movement rows and one outbox row in ONE local
transaction, on the shared Windows VM (4 GB HDD-class proxy), and a void that copies the stored movements reversed.

Store settings mirror the sync spike client (prototypes/local-first-sync-spike/sut/client.py, read only):
SQLite3 Multiple Ciphers via apsw, cipher chacha20 with a raw 256-bit test key generated per run and never saved,
journal_mode=DELETE (the client default), synchronous=FULL, temp_store=MEMORY; plus STRICT tables and
foreign_keys=ON, which ADR-0014 requires on the counter (S41/S52).

Usage: python -B s42.py <work dir>      env: SALES_PER_N (400), VOIDS_PER_N (100), GAP_S (1.0), HISTORY_LINES (50000)
Writes <work dir>/s42-results.csv and s42-summary.json; prints the summary.
"""
import json
import os
import random
import sys
import time

import apsw

W = sys.argv[1]
DB = os.path.join(W, "s42.db")
NS = [0, 1, 5, 10, 20, 40]
SALES_PER_N = int(os.environ.get("SALES_PER_N", "400"))
VOIDS_PER_N = int(os.environ.get("VOIDS_PER_N", "100"))
GAP_S = float(os.environ.get("GAP_S", "1.0"))
HISTORY_LINES = int(os.environ.get("HISTORY_LINES", "50000"))
STOCK_ITEMS = 200
rnd = random.Random(42)
KEY = os.urandom(32).hex()  # test key for this run only; never written anywhere

for suffix in ("", "-journal"):
    if os.path.exists(DB + suffix):
        os.remove(DB + suffix)


def connect():
    c = apsw.Connection(DB)
    c.set_busy_timeout(5000)
    c.execute("PRAGMA cipher = chacha20").fetchall()
    c.execute(f"PRAGMA key = 'raw:{KEY}'").fetchall()
    c.execute("PRAGMA temp_store=MEMORY").fetchall()
    c.execute("PRAGMA journal_mode=DELETE").fetchall()
    c.execute("PRAGMA synchronous=FULL").fetchall()
    c.execute("PRAGMA foreign_keys=ON").fetchall()
    return c


con = connect()
con.execute("""
CREATE TABLE stock_item (id INTEGER PRIMARY KEY, name TEXT NOT NULL, unit_cost_milli INTEGER NOT NULL) STRICT;
CREATE TABLE variant (id INTEGER PRIMARY KEY, n INTEGER NOT NULL, price_piasters INTEGER NOT NULL) STRICT;
CREATE TABLE recipe_flat (variant_id INTEGER NOT NULL REFERENCES variant(id), stock_item_id INTEGER NOT NULL
  REFERENCES stock_item(id), qty_base INTEGER NOT NULL CHECK (qty_base > 0), PRIMARY KEY (variant_id, stock_item_id)) STRICT;
CREATE TABLE bill_line (id INTEGER PRIMARY KEY, bill_id INTEGER NOT NULL, variant_id INTEGER NOT NULL REFERENCES variant(id),
  qty INTEGER NOT NULL, amount_piasters INTEGER NOT NULL, voids_line_id INTEGER REFERENCES bill_line(id),
  created_ms INTEGER NOT NULL) STRICT;
CREATE TABLE stock_movement (id INTEGER PRIMARY KEY, line_id INTEGER NOT NULL REFERENCES bill_line(id),
  stock_item_id INTEGER NOT NULL REFERENCES stock_item(id), qty_base INTEGER NOT NULL, value_piasters INTEGER NOT NULL,
  reason TEXT NOT NULL) STRICT;
CREATE INDEX stock_movement_line ON stock_movement(line_id);
CREATE INDEX stock_movement_item ON stock_movement(stock_item_id);
CREATE TABLE outbox (seq INTEGER PRIMARY KEY, command_id TEXT NOT NULL UNIQUE, payload TEXT NOT NULL, status TEXT NOT NULL) STRICT;
""")
with con:
    con.executemany("INSERT INTO stock_item VALUES (?, ?, ?)",
                    [(i, f"item {i}", rnd.randint(1, 50_000)) for i in range(1, STOCK_ITEMS + 1)])
    for n in NS + [3, 6, 8]:  # 3, 6, 8: history-only variants
        vid = 1000 + n
        con.execute("INSERT INTO variant VALUES (?, ?, ?)", (vid, n, rnd.randint(1_000, 20_000)))
        con.executemany("INSERT INTO recipe_flat VALUES (?, ?, ?)",
                        [(vid, s, rnd.randint(1, 250_000)) for s in rnd.sample(range(1, STOCK_ITEMS + 1), n)])

line_id = [0]
cmd_seq = [0]


def write_sale(c, vid, created_ms, history=False):
    """One sale line: bill line + its stock movements + one outbox command, in the caller's transaction."""
    rows = c.execute("SELECT r.stock_item_id, r.qty_base, s.unit_cost_milli FROM recipe_flat r JOIN stock_item s "
                     "ON s.id = r.stock_item_id WHERE r.variant_id = ?", (vid,)).fetchall()
    price = c.execute("SELECT price_piasters FROM variant WHERE id = ?", (vid,)).fetchall()[0][0]
    line_id[0] += 1
    lid = line_id[0]
    c.execute("INSERT INTO bill_line VALUES (?, ?, ?, 1, ?, NULL, ?)", (lid, lid // 3, vid, price, created_ms))
    mv = [(lid, s, -q, -(q * cost // 1_000_000), "sale") for s, q, cost in rows]
    c.executemany("INSERT INTO stock_movement (line_id, stock_item_id, qty_base, value_piasters, reason) "
                  "VALUES (?, ?, ?, ?, ?)", mv)
    cmd_seq[0] += 1
    payload = json.dumps({"kind": "line_added", "line": lid, "variant": vid, "amount": price,
                          "movements": [[m[1], m[2], m[3]] for m in mv]}, separators=(",", ":"))
    c.execute("INSERT INTO outbox (command_id, payload, status) VALUES (?, ?, ?)",
              (f"cmd-{cmd_seq[0]}", payload, "acked" if history else "pending"))
    return lid


def write_void(c, voided, created_ms):
    """Void one line: a reversing bill line + a copy of the stored movements with the sign flipped + one command."""
    vid, amount = c.execute("SELECT variant_id, amount_piasters FROM bill_line WHERE id = ?", (voided,)).fetchall()[0]
    line_id[0] += 1
    lid = line_id[0]
    c.execute("INSERT INTO bill_line VALUES (?, ?, ?, -1, ?, ?, ?)", (lid, lid // 3, vid, -amount, voided, created_ms))
    c.execute("INSERT INTO stock_movement (line_id, stock_item_id, qty_base, value_piasters, reason) "
              "SELECT ?, stock_item_id, -qty_base, -value_piasters, 'void_return' FROM stock_movement WHERE line_id = ?",
              (lid, voided))
    cmd_seq[0] += 1
    c.execute("INSERT INTO outbox (command_id, payload, status) VALUES (?, ?, 'pending')",
              (f"cmd-{cmd_seq[0]}", json.dumps({"kind": "line_voided", "line": lid, "voids": voided})))
    return lid


# history: HISTORY_LINES past sales over the history variants (about 6 movements each), batches of 5,000
t_hist = time.perf_counter()
hist_variants = [1000 + n for n in (1, 3, 5, 6, 8, 10)]
for b in range(0, HISTORY_LINES, 5000):
    with con:
        for _ in range(min(5000, HISTORY_LINES - b)):
            write_sale(con, rnd.choice(hist_variants), 0, history=True)
hist_s = time.perf_counter() - t_hist
con.close()

# reopen as the counter would after a restart, then the timed run
con = connect()
start_check = con.execute("PRAGMA quick_check").fetchall()[0][0]
schedule = []
for block in range(SALES_PER_N):
    order = NS[:]
    rnd.shuffle(order)
    schedule += [("sale", n) for n in order]
    if VOIDS_PER_N and (block + 1) % max(1, SALES_PER_N // VOIDS_PER_N) == 0:
        order = NS[:]
        rnd.shuffle(order)
        schedule += [("void", n) for n in order]
results = []
sold = {n: [] for n in NS}
t_run = time.perf_counter()
for i, (kind, n) in enumerate(schedule):
    if kind == "void" and not sold[n]:
        continue
    t0 = time.perf_counter_ns()
    con.execute("BEGIN IMMEDIATE")
    try:
        if kind == "sale":
            lid = write_sale(con, 1000 + n, int(time.time() * 1000))
        else:
            target = sold[n].pop(rnd.randrange(len(sold[n])))
            lid = write_void(con, target, int(time.time() * 1000))
        con.execute("COMMIT")
    except Exception:
        con.execute("ROLLBACK")
        raise
    ms = (time.perf_counter_ns() - t0) / 1e6
    if kind == "sale":
        sold[n].append(lid)
    results.append((i, kind, n, round(ms, 3), round(time.perf_counter() - t_run, 3)))
    time.sleep(GAP_S)
run_s = time.perf_counter() - t_run

# invariants: every sale line has exactly N movements; every void nets its line to zero
bad_sales = con.execute("SELECT count(*) FROM bill_line b JOIN variant v ON v.id = b.variant_id WHERE b.qty = 1 AND "
                        "b.created_ms > 0 AND (SELECT count(*) FROM stock_movement m WHERE m.line_id = b.id) <> v.n"
                        ).fetchall()[0][0]
bad_voids = con.execute("SELECT count(*) FROM bill_line x WHERE x.voids_line_id IS NOT NULL AND "
                        "(SELECT coalesce(sum(qty_base), 0) FROM stock_movement WHERE line_id IN (x.id, x.voids_line_id)) <> 0"
                        ).fetchall()[0][0]
end_check = con.execute("PRAGMA quick_check").fetchall()[0][0]
counts = {t: con.execute(f"SELECT count(*) FROM {t}").fetchall()[0][0]
          for t in ("bill_line", "stock_movement", "outbox")}
con.close()


def pct(xs, p):
    xs = sorted(xs)
    return xs[max(0, -(-len(xs) * p // 100) - 1)]


summary = {"versions": {"python": sys.version.split()[0], "apsw": apsw.apsw_version(),
                        "sqlite": apsw.sqlite_lib_version()},
           "settings": {"cipher": "chacha20", "journal_mode": "DELETE", "synchronous": "FULL", "strict": True,
                        "foreign_keys": True, "gap_s": GAP_S, "sales_per_n": SALES_PER_N, "voids_per_n": VOIDS_PER_N,
                        "history_lines": HISTORY_LINES},
           "history_seed_s": round(hist_s, 1), "run_s": round(run_s, 1), "store_bytes": os.path.getsize(DB),
           "row_counts": counts, "quick_check": [start_check, end_check],
           "invariants": {"sales_with_wrong_movement_count": bad_sales, "voids_not_netting_to_zero": bad_voids},
           "first_op_ms": results[0][3] if results else None, "cells": []}
for kind in ("sale", "void"):
    base = None
    for n in NS:
        xs = [r[3] for r in results if r[1] == kind and r[2] == n]
        if not xs:
            continue
        cell = {"kind": kind, "n": n, "count": len(xs), "p50_ms": pct(xs, 50), "p95_ms": pct(xs, 95),
                "p99_ms": pct(xs, 99), "max_ms": max(xs), "over_1s": sum(x > 1000 for x in xs),
                "over_3s": sum(x > 3000 for x in xs)}
        if n == 0:
            base = cell
        if base:
            cell["p95_over_n0_ms"] = round(cell["p95_ms"] - base["p95_ms"], 3)
        cell["pass_p95_200_max_3000"] = cell["p95_ms"] <= 200 and cell["max_ms"] <= 3000
        summary["cells"].append(cell)
with open(os.path.join(W, "s42-results.csv"), "w") as f:
    f.write("i,kind,n,ms,t_s\n")
    f.writelines(",".join(map(str, r)) + "\n" for r in results)
with open(os.path.join(W, "s42-summary.json"), "w") as f:
    json.dump(summary, f, indent=1)
print(json.dumps(summary, indent=1))
