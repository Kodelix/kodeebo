# PROTOTYPE - NOT FOR PRODUCTION
# Runs ON THE VM (phase 4, SC-26): the counter's reads, in a second process, while the client drains a backlog.
#   sc26reader.py <db> <key> <seconds> <out.json>
# Every 50 ms one read the counter does (open sessions; today's bills and total; the price list and items), each
# timed. busy_timeout 5000 ms, as the client. Any SQLITE_BUSY / locked error that still reaches the caller is counted:
# in the product it would reach the cashier.
import json
import sys
import time

import apsw

db, key, seconds, out = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4]
c = apsw.Connection(db)
c.set_busy_timeout(5000)
c.execute("PRAGMA cipher = chacha20").fetchall()
c.execute(f"PRAGMA key = 'raw:{key}'").fetchall()
READS = {
    "open_sessions": "SELECT session_id, start_min, segments FROM sessions",
    "today_bills": "SELECT count(*), coalesce(sum(sale_piasters), 0) FROM bills WHERE day = (SELECT max(day) FROM bills)",
    "price_list": "SELECT cfg_prices, cfg_version FROM sync_state WHERE id = 1",
    "items": "SELECT item_id, price, policy FROM items",
}
samples, errors = {k: [] for k in READS}, []
t_end = time.time() + seconds
i = 0
while time.time() < t_end:
    name = list(READS)[i % len(READS)]
    i += 1
    t0 = time.perf_counter()
    try:
        c.execute(READS[name]).fetchall()
        samples[name].append(round((time.perf_counter() - t0) * 1000, 2))
    except apsw.Error as e:
        errors.append({"read": name, "error": f"{type(e).__name__}: {e}"[:160],
                       "after_ms": round((time.perf_counter() - t0) * 1000, 1)})
    time.sleep(0.05)
with open(out, "w") as f:
    json.dump({"samples": samples, "errors": errors}, f)
print(json.dumps({"reads": sum(len(v) for v in samples.values()), "errors": len(errors)}))
