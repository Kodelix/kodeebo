# PROTOTYPE - NOT FOR PRODUCTION
# SC-24 store builder (host side): the phase 0-3 client sells at the OQ16 mix (1,200 sessions + 3,600 cafe orders a
# day, derived from capacity, not measured) with the retention rule on, syncing every 1,000 sales so the outbox drains
# as it would online. Uses its own server port and database (sc24), so it can run while the VM legs use 18471.
#   sc24gen.py <commands> <out_dir> [offline]  -> <out_dir>/client.db (+ .hwm), <out_dir>/key.txt (random test key)
#   offline (SC-26): nothing is synced, so the store holds a backlog of <commands> pending commands
#   sc24gen.py <commands> <out_dir> online <page_size>  (P4-F5) the same store with a larger page size
import json
import os
import random
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import driver  # noqa: E402

driver.ADDR = "127.0.0.1:18491"
driver.SERVER_URL = "http://" + driver.ADDR
driver.PG_DSN = "postgres://postgres@127.0.0.1:56432/sc24"
SESSIONS, CAFE = 1200, 3600


def build(n, out, offline=False, page_size=None):
    env = {"RETENTION": "1", "RETAIN_DAYS": "60", **({"PAGE_SIZE": str(page_size)} if page_size else {})}
    run = driver.Run(24, None, store="sqlite3mc", cipher="chacha20", fault=[], label=f"sc24-build-{n}-{page_size or 4096}",
                     client_env=env)
    rng = random.Random(f"sc24|{n}")
    per_day = SESSIONS + CAFE
    t0 = time.time()

    def script(r):
        for k in range(n):
            day = 1 + k * 60 // n if n >= per_day * 60 else 1 + k // per_day
            cafe = rng.random() < CAFE / per_day
            start = rng.randint(0, 1400)
            a = {"op": "sale", "action_id": f"g{k}", "session_id": f"gs{k}", "start_min": start,
                 "end_min": start if cafe else start + rng.randint(10, 40),
                 "rate_per_hour": rng.choice([3000, 4500, 6000, 9000]),
                 "cafe_piasters": rng.choice([1500, 2500, 4000]) * rng.randint(1, 3) if cafe else 0, "day": day}
            rep = r.send(a)
            if not (rep and rep.get("ok")):
                raise RuntimeError(f"sale {k} failed: {rep}")
            if not offline and (k % 1000 == 999 or k == n - 1):
                while (r.send({"op": "sync"}) or {}).get("pending", 0) > 0:
                    pass
            if k % 20000 == 19999:
                print(f"  {k + 1}/{n} ({round(time.time() - t0)} s)", flush=True)

    run.script = script
    if offline:  # keep the backlog: stop the client before the driver's final drain
        orig = run.send

        def send(msg):
            if msg.get("op") == "sync":
                return {"ok": True, "pending": 0}
            return orig(msg)
        run.send = send
    res = run.go()
    os.makedirs(out, exist_ok=True)
    for suffix in ("", ".hwm"):
        os.replace(run.db + suffix, os.path.join(out, "client.db" + suffix))
    with open(os.path.join(out, "key.txt"), "w") as f:  # random test key of this generated store, never a secret
        f.write(run.key)
    info = {"commands": n, "page_size": page_size or 4096, "bytes": os.path.getsize(os.path.join(out, "client.db")), "violations_except_I8": [v for v in res["violations"] if v[0] != "I8"][:5],
            # I8 ("never submitted") is expected: the builder sends sales without the driver's intent log
            "server_sales": res["server_sales"], "seconds": round(time.time() - t0, 1)}
    with open(os.path.join(out, "info.json"), "w") as f:
        json.dump(info, f, indent=1)
    print(json.dumps(info), flush=True)


if __name__ == "__main__":
    build(int(sys.argv[1]), sys.argv[2], len(sys.argv) > 3 and sys.argv[3] == "offline",
          int(sys.argv[4]) if len(sys.argv) > 4 else None)
