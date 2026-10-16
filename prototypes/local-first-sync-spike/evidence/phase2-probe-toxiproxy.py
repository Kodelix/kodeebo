# PROTOTYPE - NOT FOR PRODUCTION
# Question: phase 2 probe S402 - can Toxiproxy v2.13.0 cut only the response (after the server committed) or
#           only the request, between the client and the server stub?
# Date: 2026-10-16
# Run (from the prototype folder, Postgres container up, PGPASSWORD set as run.sh does):
#   .venv/bin/python evidence/phase2-probe-toxiproxy.py
import hashlib
import json
import os
import subprocess
import time
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOXI = os.path.join(ROOT, "tools", "toxiproxy-2.13.0", "extracted", "toxiproxy-server")
SERVER_BIN = os.path.join(ROOT, "sut", "server", "server")
API = "http://127.0.0.1:18474"
SERVER_ADDR, PROXY_ADDR = "127.0.0.1:18471", "127.0.0.1:18481"


def http(method, url, body=None, timeout=5):
    req = urllib.request.Request(url, method=method, data=json.dumps(body).encode() if body is not None else None,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
        return json.loads(raw) if raw else None


def cmd(seq):
    p = {"action_id": f"probe-a{seq}", "session_id": f"probe-s{seq}", "minutes": [1, 2],
         "sale_piasters": 1000, "payment_piasters": 1000}
    h = hashlib.sha256(json.dumps(p, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
    return {"device_id": "dev-1", "commands": [{"command_id": f"cmd-probe-{seq}", "seq": seq, "payload_hash": h,
                                                 "payload": p}]}


def applied(seq):
    d = http("GET", f"http://{SERVER_ADDR}/dump")
    return sum(1 for r in d["ledger"] if r["kind"] == "sale" and r["seq"] == seq)


def through_proxy(body):
    try:
        return "reply", http("POST", f"http://{PROXY_ADDR}/batch", body, timeout=4)
    except Exception as e:  # noqa: BLE001 - the probe records whatever the client sees
        return "error", f"{type(e).__name__}: {str(e)[:100]}"


toxi = subprocess.Popen([TOXI, "-host", "127.0.0.1", "-port", "18474"], stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL)
env = dict(os.environ, PG_DSN="postgres://postgres@127.0.0.1:56432/postgres", ADDR=SERVER_ADDR, RESET="1")
srv = subprocess.Popen([SERVER_BIN], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
time.sleep(1.0)
try:
    print("toxiproxy", http("GET", API + "/version"))
    http("POST", API + "/proxies", {"name": "sync", "listen": PROXY_ADDR, "upstream": SERVER_ADDR})
    cases = [
        (1, "response blackholed: timeout on downstream", {"type": "timeout", "stream": "downstream", "attributes": {"timeout": 1000}}),
        (2, "response truncated: limit_data 20 bytes on downstream", {"type": "limit_data", "stream": "downstream", "attributes": {"bytes": 20}}),
        (3, "request cut mid-body: limit_data 60 bytes on upstream", {"type": "limit_data", "stream": "upstream", "attributes": {"bytes": 60}}),
        (4, "request blackholed: timeout on upstream", {"type": "timeout", "stream": "upstream", "attributes": {"timeout": 1000}}),
    ]
    seq = 0
    for n, label, toxic in cases:
        expect_applied = toxic["stream"] == "downstream"
        seq_try = seq + 1
        http("POST", API + "/proxies/sync/toxics", {"name": "t", **toxic})
        outcome, detail = through_proxy(cmd(seq_try))
        http("DELETE", API + "/proxies/sync/toxics/t")
        time.sleep(0.3)
        n_applied = applied(seq_try)
        line = f"case {n}: {label}\n  client saw: {outcome} {detail}\n  server effects for seq {seq_try}: {n_applied}"
        if n_applied:
            seq = seq_try
            _, again = through_proxy(cmd(seq_try))  # resend the same command after the toxic is removed
            line += f"\n  resend after toxic removed: {again['results'] if isinstance(again, dict) else again}"
            line += f"; server effects now: {applied(seq_try)}"
        ok = (n_applied == 1) == expect_applied and outcome == "error"
        line += f"\n  expected: client error and {'exactly one effect (committed, reply lost)' if expect_applied else 'no effect'} -> {'AS EXPECTED' if ok else 'UNEXPECTED'}"
        print(line)
finally:
    srv.terminate()
    toxi.terminate()
    srv.wait()
    toxi.wait()
