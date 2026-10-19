# PROTOTYPE - NOT FOR PRODUCTION
# Runs ON THE VM (phase 4, SC-24). One measurement per call, so each can run on a cold cache after a reboot:
#   sc24probe.py ready <db> <key>      start the real client, time process start -> first reply (ready to sell);
#                                      the client runs integrity_check, the marker check and its schema steps first
#   sc24probe.py integrity <db> <key>  open + key, time PRAGMA integrity_check alone
#   sc24probe.py quick <db> <key>      open + key, time PRAGMA quick_check alone
# Prints one JSON line. The key is the random test key of the generated store.
import json
import os
import subprocess
import sys
import time

mode, db, key = sys.argv[1], sys.argv[2], sys.argv[3]
here = os.path.dirname(os.path.abspath(__file__))
out = {"mode": mode, "db_bytes": os.path.getsize(db)}
if mode == "ready":
    env = dict(os.environ, STORE="sqlite3mc", CIPHER="chacha20", SPIKE_DB_KEY=key, RETENTION="1")
    t0 = time.perf_counter()
    p = subprocess.Popen([sys.executable, os.path.join(here, "client.py"), db, "http://127.0.0.1:9"], env=env,
                         stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, bufsize=1)
    p.stdin.write(json.dumps({"op": "stats"}) + "\n")
    p.stdin.flush()
    line = p.stdout.readline()
    out["ms"] = round((time.perf_counter() - t0) * 1000, 1)
    out["reply"] = json.loads(line) if line else None
    p.stdin.write(json.dumps({"op": "exit"}) + "\n")
    p.stdin.flush()
    p.wait(timeout=120)
else:
    import apsw
    t0 = time.perf_counter()
    c = apsw.Connection(db)
    c.execute("PRAGMA cipher = chacha20").fetchall()
    c.execute(f"PRAGMA key = 'raw:{key}'").fetchall()
    t1 = time.perf_counter()
    r = c.execute(f"PRAGMA {'integrity_check' if mode == 'integrity' else 'quick_check'}").fetchall()
    out["ms"] = round((time.perf_counter() - t1) * 1000, 1)
    out["open_ms"] = round((t1 - t0) * 1000, 1)
    out["result"] = r[0][0] if r else None
print(json.dumps(out), flush=True)
