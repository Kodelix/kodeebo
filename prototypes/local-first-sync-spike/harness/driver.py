# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does local-first sync ever lose or double-count money or session time under faults? (phase 0 driver)
# Date: 2026-10-16
#
# Driver: never killed. Generates a seeded script, writes each action to its own intent log
# BEFORE submitting it, injects one fault per run, supervises and restarts the SUT processes,
# waits for quiescence, then runs the independent oracle.
#   python3 harness/driver.py selftest
#   python3 harness/driver.py replay <seed> [mutant]
import json
import os
import random
import shutil
import sqlite3
import subprocess
import sys
import time
import urllib.request
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import oracle  # noqa: E402  (same folder; never imports SUT code)
import pins  # noqa: E402  (pinned cell lists, README "Pinned cell lists")

PG_DSN = "postgres://postgres@127.0.0.1:56432/postgres"  # password from PGPASSWORD (set by run.sh)
ADDR = "127.0.0.1:18471"
SERVER_URL = "http://" + ADDR
SERVER_BIN = os.path.join(ROOT, "sut", "server", "server")
CLIENT_PY = os.path.join(ROOT, "sut", "client.py")
RUNS = os.path.join(ROOT, "runs")

CLIENT_POINTS = ["client:before_local_commit", "client:mid_local_txn", "client:after_business_commit",
                 "client:after_local_commit", "client:before_send", "client:after_response_before_mark",
                 "client:after_mark"]
SERVER_POINTS = ["server:before_commit", "server:after_commit_before_response",
                 "server:after_response_before_commit"]
MUTANTS = ["separate_outbox_txn", "no_dedupe", "ack_before_commit", "double_minute"]
ACTIONS_PER_RUN = 8
# Phase 1 cells: client fault points on the correct path (P1, P2, P4, before send, P10, P11, P12).
PHASE1_POINTS = ["client:before_local_commit", "client:mid_local_txn", "client:after_local_commit",
                 "client:before_send", "client:after_response_before_mark", "client:mid_mark", "client:after_mark"]
CIPHERS = ["chacha20", "sqlcipher"]
CANARY = b"CANARY"

# --- Phase 2: network faults through Toxiproxy v2.13.0 (tools/, verified, README "Tools fetched") ----------
TOXI_BIN = os.path.join(ROOT, "tools", "toxiproxy-2.13.0", "extracted", "toxiproxy-server")
TOXI_API = "http://127.0.0.1:18474"
PROXY_ADDR = "127.0.0.1:18481"
PROXY_URL = "http://" + PROXY_ADDR
# Each fault is a list of toxics (direction per README v2.13.0: downstream = server->client, upstream = client->server),
# or "down" (proxy disabled = connection refused).
TOXICS = {
    "resp_blackhole": [{"type": "timeout", "stream": "downstream", "attributes": {"timeout": 300}}],  # P9
    "resp_cut_1": [{"type": "limit_data", "stream": "downstream", "attributes": {"bytes": 1}}],
    "resp_cut_20": [{"type": "limit_data", "stream": "downstream", "attributes": {"bytes": 20}}],  # "200 OK", no body (P2-F1)
    "resp_cut_150": [{"type": "limit_data", "stream": "downstream", "attributes": {"bytes": 150}}],
    "req_cut_10": [{"type": "limit_data", "stream": "upstream", "attributes": {"bytes": 10}}],  # P5
    "req_cut_120": [{"type": "limit_data", "stream": "upstream", "attributes": {"bytes": 120}}],
    "req_cut_400": [{"type": "limit_data", "stream": "upstream", "attributes": {"bytes": 400}}],
    "req_blackhole": [{"type": "timeout", "stream": "upstream", "attributes": {"timeout": 300}}],
    "reset_peer": [{"type": "reset_peer", "stream": "downstream", "attributes": {"timeout": 0}}],
    "slicer": [{"type": "slicer", "stream": "downstream", "attributes": {"average_size": 4, "size_variation": 2, "delay": 1000}}],
    "slow": [{"type": "latency", "stream": "downstream", "attributes": {"latency": 150, "jitter": 100}},
             {"type": "latency", "stream": "upstream", "attributes": {"latency": 150, "jitter": 100}}],
    "down": "down",
}
# Toxics used by later phases only. Kept out of TOXICS, because phase 2 derives its cells and its random campaign
# from TOXICS (adding one there changed phase 2; found by the a5900db regression).
EXTRA_TOXICS = {
    # SC-25a: a slow uplink; a 50-command batch takes longer than the 2 s HTTP timeout, a small one does not
    "bandwidth_3k": [{"type": "bandwidth", "stream": "upstream", "attributes": {"rate": 3}}],
}


class Toxi:
    """One Toxiproxy process for a phase 2 session; proxy "sync" in front of the server stub, loopback only."""

    def __init__(self, log_dir):
        os.makedirs(log_dir, exist_ok=True)
        self.p = subprocess.Popen([TOXI_BIN, "-host", "127.0.0.1", "-port", "18474"], stdout=subprocess.DEVNULL,
                                  stderr=open(os.path.join(log_dir, "toxiproxy.log"), "a"))
        for _ in range(100):
            if self.p.poll() is not None:
                raise RuntimeError("toxiproxy exited at start (port 18474 in use?); see toxiproxy.log")
            try:
                self.api("GET", "/version")
                break
            except OSError:
                time.sleep(0.05)
        self.api("POST", "/proxies", {"name": "sync", "listen": PROXY_ADDR, "upstream": ADDR})
        self.active = []

    def api(self, method, path, body=None):
        req = urllib.request.Request(TOXI_API + path, method=method, headers={"Content-Type": "application/json"},
                                     data=json.dumps(body).encode() if body is not None else None)
        with urllib.request.urlopen(req, timeout=5) as r:
            return r.read()

    def apply(self, name):
        if not name:
            return
        spec = TOXICS[name] if name in TOXICS else EXTRA_TOXICS[name]
        if spec == "down":
            self.api("POST", "/proxies/sync", {"enabled": False})
            self.active.append("down")
            return
        for i, t in enumerate(spec):
            self.api("POST", "/proxies/sync/toxics", {"name": f"t{i}", **t})
            self.active.append(f"t{i}")

    def clear(self):
        for a in self.active:
            if a == "down":
                self.api("POST", "/proxies/sync", {"enabled": True})
            else:
                self.api("DELETE", f"/proxies/sync/toxics/{a}")
        self.active = []

    def stop(self):
        self.p.terminate()
        self.p.wait()


class Net:
    """Which network fault each sync, concurrent sync or replay gets. mode: a TOXICS name (single-fault cell),
    "concurrent" (every sync is a concurrent double send under "slow"), or "random" (the randomized campaign)."""

    def __init__(self, toxi, mode):
        self.toxi, self.mode = toxi, mode

    def pick(self, rng):
        if self.mode == "concurrent":
            return "sync_concurrent", "slow"
        if self.mode == "random":
            op = "sync_concurrent" if rng.random() < 0.25 else "sync"
            fault = None if rng.random() < 0.35 else rng.choice(sorted(TOXICS))
            return op, fault
        return "sync", self.mode


class Run:
    def __init__(self, seed, mutant, verbose=False, store=None, cipher=None, fault=None, label=None, net=None,
                 server_env=None, client_env=None):
        self.seed, self.mutant, self.verbose = seed, mutant, verbose
        self.net, self.server_env = net, server_env or {}
        self.client_env = client_env or {}
        self.script = None  # optional replacement for the random action loop (TS-09, SC-19)
        self.extra = None  # optional extra oracle: f(run, dump) -> (violations, allowed_missing) (SC-19)
        self.server_down = False  # a planned outage: do not restart the server (SC-19 restore window)
        self.seq_of = {}  # action id -> device sequence, from the sale replies
        self.day = 0  # simulated day stamped on each sale (SC-19: retention by age)
        self.sale_replies = {}  # action id -> the client's reply to the sale (SC-20: failed sales must be visible)
        # Phase 2 exercise counters: ops sent under a toxic, of those how many failed, and "duplicate" outcomes
        # on normal syncs (= a command the server committed whose reply the client never got).
        self.net_stats = {"faulted_ops": 0, "failed_ops": 0, "duplicates_seen": 0, "concurrent_both_parsed": 0}
        self.store, self.cipher = store, cipher
        self.rng = random.Random(seed)
        self.dir = os.path.join(RUNS, label or (mutant or "correct"), f"seed-{seed}")
        shutil.rmtree(self.dir, ignore_errors=True)
        os.makedirs(self.dir)
        self.db = os.path.join(self.dir, "client.db")
        self.tmp = os.path.join(self.dir, "tmp")
        os.makedirs(self.tmp)
        self.intent = sqlite3.connect(os.path.join(self.dir, "intent.db"), isolation_level=None)
        self.intent.execute("CREATE TABLE actions (action_id TEXT PRIMARY KEY, body TEXT)")
        self.intent.execute("CREATE TABLE acks (action_id TEXT PRIMARY KEY)")
        self.server = self.client = None
        self.fault, self.fired = (fault if fault is not None else self.pick_fault()), []
        # Test key only: a fresh random 256-bit key per run, never a real secret.
        self.key = "%064x" % self.rng.getrandbits(256) if store else ""
        self.leaks = []
        self.trace = []

    def log(self, *a):
        self.trace.append(" ".join(str(x) for x in a))
        if self.verbose:
            print(*a)

    def pick_fault(self):
        r = self.rng.random()
        if r < 0.1:
            return None
        point = self.rng.choice(CLIENT_POINTS + SERVER_POINTS)
        return point, self.rng.randint(1, 3)

    def env(self, side, first):
        e = dict(os.environ, MUTANT=self.mutant or "")
        e.pop("FP", None)
        if first and self.fault and self.fault[0].startswith(side):
            e["FP"] = f"{self.fault[0]}:{self.fault[1]}"
        if side == "client" and self.store:
            e.update(STORE=self.store, CIPHER=self.cipher, SPIKE_DB_KEY=self.key, SQLITE_TMPDIR=self.tmp, TMPDIR=self.tmp)
        return e

    # --- TS-04a: plaintext scan of the store files and the temp directory --------
    def scan(self, when):
        if not self.store:
            return
        paths = []
        for root in (self.dir, self.tmp):
            for top, _, files in os.walk(root):  # includes <db>.recovery/ copies made before SQLite recovery
                rel = os.path.relpath(top, self.dir)
                for n in files:
                    if (n.startswith("client.db") or root == self.tmp or "recovery" in rel) and not n.endswith(".events.jsonl"):
                        paths.append(os.path.join(top, n))
        for p in paths:
            with open(p, "rb") as f:
                data = f.read()
            if CANARY in data:
                self.leaks.append(f"{when}: canary plaintext in {os.path.basename(p)}")
            if data.startswith(b"SQLite format 3") and not p.endswith("-shm"):
                self.leaks.append(f"{when}: plaintext SQLite header in {os.path.basename(p)}")

    def open_client_store(self):
        if self.store:
            import apsw
            c = apsw.Connection(self.db)
            c.execute(f"PRAGMA cipher = {self.cipher}").fetchall()
            k = f"PRAGMA key = 'raw:{self.key}'" if self.cipher == "chacha20" else f"PRAGMA key = \"x'{self.key}'\""
            c.execute(k).fetchall()
            return c
        return sqlite3.connect(self.db)

    # --- process supervision -------------------------------------------------
    def start_server(self, first=False):
        e = self.env("server", first)
        e.update(PG_DSN=PG_DSN, ADDR=ADDR, RESET="1" if first else "0", **self.server_env)
        self.server = subprocess.Popen([SERVER_BIN], env=e, stdout=subprocess.DEVNULL,
                                       stderr=open(os.path.join(self.dir, "server.log"), "a"))
        for _ in range(200):
            try:
                urllib.request.urlopen(SERVER_URL + "/health", timeout=1).read()
                return
            except OSError:
                if self.server.poll() is not None:
                    raise RuntimeError("server exited at start; see server.log")
                time.sleep(0.02)
        raise RuntimeError("server did not start")

    def start_client(self, first=False):
        e = self.env("client", first)
        if self.net:
            e["HTTP_TIMEOUT"] = "2"
        e.update(self.client_env)
        self.client = subprocess.Popen([sys.executable, CLIENT_PY, self.db, PROXY_URL if self.net else SERVER_URL], env=e,
                                       stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1,
                                       stderr=open(os.path.join(self.dir, "client.log"), "a"))

    def ensure_alive(self):
        if not self.server_down and self.server.poll() is not None:
            self.fired.append(f"server died rc={self.server.returncode}")
            self.log("  server died, restarting without fault")
            self.start_server()
        if self.client.poll() is not None:
            self.fired.append(f"client died rc={self.client.returncode}")
            self.scan("after client death")  # the WAL and temp files are on disk exactly as the kill left them
            self.log("  client died, restarting without fault")
            self.start_client()

    def send(self, msg):
        """Send one op to the client; return its reply, or None if the client died."""
        self.ensure_alive()
        try:
            self.client.stdin.write(json.dumps(msg) + "\n")
            self.client.stdin.flush()
            line = self.client.stdout.readline()
        except BrokenPipeError:
            line = ""
        if not line:
            self.client.wait()
            return None
        return json.loads(line)

    def note(self, op, fault, r):
        """Count what a phase 2 op did; returns r."""
        st = self.net_stats
        if fault:
            st["faulted_ops"] += 1
            if not r or not r.get("ok") or any(isinstance(x, str) for x in r.get("replies", [])):
                st["failed_ops"] += 1
        if r and op in ("sync", "sync_concurrent"):
            res = r.get("results") or [x for rep_ in r.get("replies", []) if isinstance(rep_, list) for x in rep_]
            st["duplicates_seen"] += sum(1 for x in res if x["result"] == "duplicate")
            if op == "sync_concurrent" and len([x for x in r.get("replies", []) if isinstance(x, list)]) == 2:
                st["concurrent_both_parsed"] += 1
        return r

    def net_op(self, op, fault, msg=None):
        self.net.toxi.apply(fault)
        try:
            r = self.note(op, fault, self.send(msg or {"op": op}))
        finally:
            self.net.toxi.clear()
        self.log(op, fault, r)
        return r

    # --- the script ------------------------------------------------------------
    def new_action(self, i):
        start = self.rng.randint(0, 600)
        sess = f"{'CANARY-' if self.store else ''}s{self.seed}-sess{i}"  # canary: must never appear on disk in plaintext
        return {"op": "sale", "action_id": f"s{self.seed}-a{i}", "session_id": sess,
                "start_min": start, "end_min": start + self.rng.randint(1, 180),
                "rate_per_hour": self.rng.choice([3000, 4500, 6000, 9000, 12000]),
                "cafe_piasters": self.rng.choice([0, 1500, 2500, 4000, 7550])}

    def sale(self, i):
        a = self.new_action(i)
        if self.day:
            a["day"] = self.day
        self.intent.execute("INSERT INTO actions VALUES (?,?)", (a["action_id"], json.dumps(a)))  # before submit
        r = self.send(a)
        self.sale_replies[a["action_id"]] = r
        if r and r.get("ok"):
            self.seq_of[a["action_id"]] = r.get("seq")
            self.intent.execute("INSERT INTO acks VALUES (?)", (a["action_id"],))
            self.log(f"sale {a['action_id']} acknowledged")
        else:
            self.log(f"sale {a['action_id']} not acknowledged: {r if r else 'no reply (client died)'}")

    def go(self):
        self.log(f"seed={self.seed} mutant={self.mutant or 'none'} fault={self.fault}")
        self.start_server(first=True)
        self.start_client(first=True)
        for i in ([] if self.script else range(ACTIONS_PER_RUN)):
            self.sale(i)
            if self.net:  # phase 2: every sync, concurrent sync and replay may cross a network fault
                if self.net.mode != "random" or self.rng.random() < 0.6:
                    op, fault = self.net.pick(self.rng)
                    self.net_op(op, fault)
                if self.rng.random() < 0.2:
                    _, fault = self.net.pick(self.rng)
                    self.net_op("replay", fault, {"op": "replay", "k": self.rng.randint(1, 3)})
                continue
            if self.rng.random() < 0.5:
                self.log("sync", self.send({"op": "sync"}))
            if self.rng.random() < 0.2:
                self.log("replay", self.send({"op": "replay", "k": self.rng.randint(1, 3)}))
        if self.script:
            self.script(self)
        # quiescence: faults are one-shot; restart anything dead and drain the outbox
        if self.net:
            self.net.toxi.clear()
        quiesced = False
        for _ in range(20):
            r = self.note("sync", None, self.send({"op": "sync"}))
            if r and r.get("ok") and r.get("pending") == 0:
                quiesced = True
                break
        self.send({"op": "exit"})
        self.client.wait()
        dump = json.loads(urllib.request.urlopen(SERVER_URL + "/dump", timeout=180).read())  # SC-25a: large dumps
        self.server.terminate()
        self.server.wait()
        self.scan("after clean exit")
        c = self.open_client_store()
        integrity = c.execute("PRAGMA integrity_check").fetchall()[0][0]
        client = {"bills": [r[0] for r in c.execute("SELECT action_id FROM bills").fetchall()]}
        c.close()
        intent = [json.loads(b) for (b,) in self.intent.execute("SELECT body FROM actions")]
        acked = [a for (a,) in self.intent.execute("SELECT action_id FROM acks")]
        extra, allowed = self.extra(self, dump) if self.extra else ([], frozenset())
        violations = oracle.check(intent, acked, client, dump, quiesced, integrity, allowed) + extra
        events = self.db + ".events.jsonl"
        if os.path.exists(events):  # no tamper in these runs, so any store refusal is a store failure
            refusals = [ln for ln in open(events) if json.loads(ln).get("event", "").startswith("store_")]
            if refusals:
                violations.append(("I9", f"client refused its store: {refusals[0][:200]}"))
        violations += [("I10", leak) for leak in self.leaks]  # TS-04a: plaintext on disk
        result = {"seed": self.seed, "mutant": self.mutant, "store": self.store, "cipher": self.cipher,
                  "fault": self.fault, "fired": self.fired,
                  "actions": len(intent), "acked": len(acked), "server_sales": sum(1 for r in dump["ledger"] if r["kind"] == "sale"),
                  "net": self.net_stats, "offline": dump.get("offline", []),
                  "reconcile_events": dump.get("reconcile", []), "violations": violations}
        with open(os.path.join(self.dir, "result.json"), "w") as f:
            json.dump({**result, "trace": self.trace}, f, indent=1)
        return result


def git_state():
    try:
        h = subprocess.run(["git", "rev-parse", "--short", "HEAD"], capture_output=True, text=True, cwd=ROOT).stdout.strip()
        dirty = subprocess.run(["git", "status", "--porcelain", "--", "."], capture_output=True, text=True, cwd=ROOT).stdout.strip()
        return h + ("+dirty" if dirty else "")
    except OSError:
        return "unknown"


def selftest(correct_runs=300, mutant_budget=200):
    t0 = time.time()
    summary = {"harness_commit": git_state(), "started": time.strftime("%Y-%m-%d %H:%M:%S")}
    print(f"phase 0 self-test, commit {summary['harness_commit']}")
    bad = []
    for s in range(1, correct_runs + 1):
        r = Run(s, None).go()
        if r["violations"]:
            bad.append(r)
            print(f"  CORRECT STUB VIOLATION seed {s}: {r['violations'][:3]}")
    summary["correct"] = {"runs": correct_runs, "violating_runs": len(bad), "seconds": round(time.time() - t0, 1)}
    print(f"correct stub: {correct_runs} runs, {len(bad)} with violations ({summary['correct']['seconds']} s)")
    kills = {}
    for m in MUTANTS:
        t1 = time.time()
        caught = None
        for s in range(1, mutant_budget + 1):
            r = Run(s, m).go()
            if r["violations"]:
                caught = r
                break
        kills[m] = {"caught": bool(caught), "runs_to_catch": s if caught else None, "budget": mutant_budget,
                    "first_violation": caught["violations"][0] if caught else None,
                    "fault": caught["fault"] if caught else None, "seconds": round(time.time() - t1, 1)}
        print(f"mutant {m:22s} {'CAUGHT' if caught else 'SURVIVED'} after {s} runs: "
              f"{caught['violations'][0] if caught else '-'}")
    summary["mutants"] = kills
    summary["gate"] = "PASS" if not bad and all(k["caught"] for k in kills.values()) else "FAIL"
    summary["seconds_total"] = round(time.time() - t0, 1)
    os.makedirs(RUNS, exist_ok=True)
    with open(os.path.join(RUNS, "selftest-summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    print(f"GATE: {summary['gate']}  (total {summary['seconds_total']} s)")
    return summary["gate"] == "PASS"


def phase1_fault(seed, point):
    # Deterministic hit number per (seed, cell), independent of the run's own RNG stream.
    return point, random.Random(f"{seed}|{point}").randint(1, 3)


def phase1(seeds=50):
    """Phase 1 gate: encrypted store under process kill. Every cell x seeds x both ciphers."""
    t0 = time.time()
    summary = {"harness_commit": git_state(), "started": time.strftime("%Y-%m-%d %H:%M:%S"), "seeds_per_cell": seeds,
               "cells": [], "mutant": {}}
    print(f"phase 1, commit {summary['harness_commit']}, {seeds} seeds per cell")
    ok = True
    for cipher in CIPHERS:
        for point in PHASE1_POINTS:
            t1 = time.time()
            bad, fired = [], 0
            for s in range(1, seeds + 1):
                r = Run(s, None, store="sqlite3mc", cipher=cipher, fault=phase1_fault(s, point),
                        label=f"phase1-{cipher}-{point.split(':')[1]}").go()
                fired += any("rc=-9" in x for x in r["fired"])
                if r["violations"]:
                    bad.append({"seed": s, "violations": r["violations"][:3]})
            exercised = fired > 0
            cell = {"cipher": cipher, "point": point, "runs": seeds, "fault_fired": fired,
                    "violating_runs": len(bad), "first_bad": bad[:3], "seconds": round(time.time() - t1, 1),
                    "result": "PASS" if exercised and not bad else ("FAIL" if bad else "NOT ASSESSED (fault never fired)")}
            ok &= cell["result"] == "PASS"
            summary["cells"].append(cell)
            print(f"  {cipher:9s} {point:36s} fired {fired:2d}/{seeds}  violating {len(bad)}  {cell['result']}")
        # The outbox mutant on the encrypted store: the oracle must still see it.
        caught = fired = 0
        for s in range(1, seeds + 1):
            r = Run(s, "separate_outbox_txn", store="sqlite3mc", cipher=cipher,
                    fault=phase1_fault(s, "client:after_business_commit"),
                    label=f"phase1-{cipher}-mutant-separate_outbox_txn").go()
            f = any("rc=-9" in x for x in r["fired"])
            fired += f
            caught += f and any(v[0] == "I1" for v in r["violations"])
        m = {"fault_fired": fired, "caught_when_fired": caught,
             "result": "PASS" if fired and caught == fired else "FAIL"}
        ok &= m["result"] == "PASS"
        summary["mutant"][cipher] = m
        print(f"  {cipher:9s} mutant separate_outbox_txn fired {fired}/{seeds}, caught {caught}  {m['result']}")
    summary["gate"] = "PASS" if ok else "FAIL"
    summary["seconds_total"] = round(time.time() - t0, 1)
    os.makedirs(RUNS, exist_ok=True)
    with open(os.path.join(RUNS, "phase1-summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    print(f"GATE (process-kill part): {summary['gate']}  (total {summary['seconds_total']} s)")
    return ok


# --- Phase 2: network faults ----------------------------------------------------------------------------------
# Single-fault cells: one toxic on every sync/replay, no process kill. "Exercised" is checked per cell so a toxic
# that never bit is reported NOT ASSESSED, never PASS.
PHASE2_CELLS = sorted(TOXICS) + ["concurrent"]
RESPONSE_LOSS = {"resp_blackhole", "resp_cut_1", "resp_cut_20", "resp_cut_150"}  # server commits, reply lost (P9)
DEGRADED_ONLY = {"slow", "slicer"}  # slow but working: must not fail, must not double-count


def exercised(cell, st):
    if cell == "concurrent":
        return st["concurrent_both_parsed"] > 0 and st["duplicates_seen"] > 0
    if cell in DEGRADED_ONLY:
        return st["faulted_ops"] > 0
    if cell in RESPONSE_LOSS:
        return st["failed_ops"] > 0 and st["duplicates_seen"] > 0  # the retry met the committed command
    return st["failed_ops"] > 0


# P3 (client:after_business_commit) exists only in the separate_outbox_txn mutant; without it that mutant
# can never be caught here (found in the phase 2 dev run). On the correct client it never fires.
PHASE2_KILL_POINTS = PHASE1_POINTS + ["client:after_business_commit"] + SERVER_POINTS


def phase2_proc_fault(seed):
    # Randomized campaign: half the runs also get one process kill (client P1-P12 points or server P6-P9 points),
    # drawn from its own RNG so the network script of a seed does not shift.
    r = random.Random(f"{seed}|p2")
    if r.random() < 0.5:
        return False
    return r.choice(PHASE2_KILL_POINTS), r.randint(1, 3)


def p2run(seed, mode, label, toxi, mutant=None, fault=False, **kw):
    return Run(seed, mutant, store="sqlite3mc", cipher="chacha20", fault=fault, label=label,
               net=Net(toxi, mode), **kw)


def phase2(seeds=50, campaign=3000, mutant_budget=400):
    t0 = time.time()
    summary = {"harness_commit": git_state(), "started": time.strftime("%Y-%m-%d %H:%M:%S"),
               "toxiproxy": "v2.13.0", "store": "sqlite3mc chacha20, journal delete + marker (OQ28 A+B)",
               "seeds_per_cell": seeds, "cells": [], "campaign": {}, "mutants": {}}
    print(f"phase 2, commit {summary['harness_commit']}, {seeds} seeds per cell, campaign {campaign}")
    pins.check("phase2-cells", PHASE2_CELLS)  # fail fast if a shared table changed phase 2
    pins.check("phase2-campaign-toxics", sorted(TOXICS))
    toxi = Toxi(RUNS)
    ok = True
    try:
        for cell in PHASE2_CELLS:
            t1 = time.time()
            bad, tot = [], {"faulted_ops": 0, "failed_ops": 0, "duplicates_seen": 0, "concurrent_both_parsed": 0}
            for s in range(1, seeds + 1):
                r = p2run(s, cell, f"phase2-{cell}", toxi).go()
                for k in tot:
                    tot[k] += r["net"][k]
                if r["violations"]:
                    bad.append({"seed": s, "violations": r["violations"][:3]})
            ex = exercised(cell, tot)
            res = "PASS" if ex and not bad else ("FAIL" if bad else "NOT ASSESSED (fault never bit)")
            ok &= res == "PASS"
            summary["cells"].append({"cell": cell, "runs": seeds, **tot, "violating_runs": len(bad),
                                     "first_bad": bad[:3], "seconds": round(time.time() - t1, 1), "result": res})
            print(f"  {cell:15s} faulted {tot['faulted_ops']:4d} failed {tot['failed_ops']:4d} "
                  f"dup {tot['duplicates_seen']:4d} both {tot['concurrent_both_parsed']:3d}  violating {len(bad)}  {res}",
                  flush=True)
        t1 = time.time()
        bad, kills, tot = [], 0, {"faulted_ops": 0, "failed_ops": 0, "duplicates_seen": 0, "concurrent_both_parsed": 0}
        for s in range(1, campaign + 1):
            r = p2run(s, "random", "phase2-random", toxi, fault=phase2_proc_fault(s)).go()
            kills += any("rc=-9" in x for x in r["fired"])
            for k in tot:
                tot[k] += r["net"][k]
            if r["violations"]:
                bad.append({"seed": s, "fault": r["fault"], "violations": r["violations"][:3]})
                print(f"  CAMPAIGN VIOLATION seed {s}: {r['violations'][:2]}", flush=True)
            if s % 250 == 0:
                print(f"  campaign {s}/{campaign}  violating {len(bad)}  ({round(time.time() - t1)} s)", flush=True)
        res = "PASS" if not bad else "FAIL"
        ok &= res == "PASS"
        summary["campaign"] = {"runs": campaign, "process_kills_fired": kills, **tot, "violating_runs": len(bad),
                               "first_bad": bad[:5], "seconds": round(time.time() - t1, 1), "result": res}
        print(f"  campaign: {campaign} runs, {kills} with a process kill, violating {len(bad)}  {res}", flush=True)
        for m in MUTANTS:
            t1 = time.time()
            caught = None
            for s in range(1, mutant_budget + 1):
                r = p2run(s, "random", f"phase2-mutant-{m}", toxi, mutant=m, fault=phase2_proc_fault(s)).go()
                if r["violations"]:
                    caught = r
                    break
            summary["mutants"][m] = {"caught": bool(caught), "runs_to_catch": s if caught else None,
                                     "budget": mutant_budget, "first_violation": caught["violations"][0] if caught else None,
                                     "fault": caught["fault"] if caught else None, "seconds": round(time.time() - t1, 1)}
            ok &= bool(caught)
            print(f"  mutant {m:22s} {'CAUGHT' if caught else 'SURVIVED'} after {s} runs: "
                  f"{caught['violations'][0] if caught else '-'}", flush=True)
        summary["ts09"] = ts09(toxi)
        ok &= summary["ts09"]["result"] == "PASS"
    finally:
        toxi.stop()
    summary["gate"] = "PASS" if ok else "FAIL"
    summary["seconds_total"] = round(time.time() - t0, 1)
    with open(os.path.join(RUNS, "phase2-summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    print(f"GATE: {summary['gate']}  (total {summary['seconds_total']} s)")
    return ok


# TS-09 (offline-alert mechanics): planned outages while the cashier keeps selling. The server, from its own clock,
# records each contact gap longer than GAP_MS once, with an owner alert only inside business hours.
TS09_GAPS = [1.2, 2.0]
TS09_TOLERANCE = 0.25


def ts09_script(run):
    obs, i = [], 0

    def pings(seconds):
        first = last = None
        end = time.time() + seconds
        while time.time() < end:
            t = time.time()
            r = run.send({"op": "ping"})
            if r and r.get("ok"):
                first = first if first is not None else t
                last = t
            time.sleep(0.1)
        return first, last

    _, last = pings(1.0)
    for g in TS09_GAPS:
        run.net.toxi.apply("down")
        t_down = time.time()
        while time.time() < t_down + g:  # selling continues offline; each sync attempt fails at the proxy
            run.sale(i)
            i += 1
            run.note("sync", "down", run.send({"op": "sync"}))
            time.sleep(0.2)
        run.net.toxi.clear()
        first, nxt = pings(1.0)
        obs.append({"planned_s": g, "last_contact_before": last, "first_contact_after": first})
        last = nxt
    run.ts09 = obs


def ts09(toxi):
    out = {"gap_ms": 500, "planned_gaps_s": TS09_GAPS, "tolerance_s": TS09_TOLERANCE, "cases": []}
    ok = True
    for bh in ("1", "0"):
        run = p2run(1, "none", f"ts09-business-hours-{bh}", toxi, server_env={"GAP_MS": "500", "BUSINESS_HOURS": bh})
        run.script = ts09_script
        r = run.go()
        rec, problems = r["offline"], []
        if len(rec) != len(run.ts09):
            problems.append(f"{len(rec)} offline periods recorded, {len(run.ts09)} planned")
        for o, p in zip(run.ts09, rec):
            if abs(p["from_s"] - o["last_contact_before"]) > TS09_TOLERANCE:
                problems.append(f"from off by {p['from_s'] - o['last_contact_before']:.3f} s")
            if abs(p["to_s"] - o["first_contact_after"]) > TS09_TOLERANCE:
                problems.append(f"to off by {p['to_s'] - o['first_contact_after']:.3f} s")
            if p["owner_alert"] != (bh == "1"):
                problems.append(f"owner_alert {p['owner_alert']} with business hours {bh}")
        problems += [f"{v[0]}: {v[1]}" for v in r["violations"]]
        case = {"business_hours": bh, "sales": r["actions"], "server_sales": r["server_sales"],
                "observed": run.ts09, "recorded": rec, "problems": problems,
                "result": "PASS" if not problems else "FAIL"}
        ok &= not problems
        out["cases"].append(case)
        print(f"  TS-09 business_hours={bh}: {len(rec)} periods, sales {r['actions']}/{r['server_sales']} on server, "
              f"{case['result']} {problems[:3]}", flush=True)
    out["result"] = "PASS" if ok else "FAIL"
    return out


# --- Phase 3, SC-19: server restored from backup / PITR -------------------------------------------------------
# Backups are real pg_dump archives of the spike database (a transaction-consistent snapshot, which is what a PITR
# target gives: the restore lands on a commit boundary). Restore = stop the server, pg_restore --clean in one
# transaction, bump meta.epoch (the restore runbook step), start the server. PostgreSQL's own WAL-archive PITR is
# not exercised: its correctness is not the question; what the devices do after any restore is.
PG_CONTAINER = "lfs-spike-pg"
SC19_CELLS = ["a_before", "a_inside", "a_after", "b_older", "b_expired", "c_offline", "d_config", "e_unverified"]
SC19_MUTANTS = ["prune_unconfirmed", "no_reconcile", "rebuild_new_ids", "config_version_only"]
RETENTION_ENV = {"RETENTION": "1", "RETAIN_DAYS": "60"}  # OQ29 provisional (founder): 60 days on the device
# Simulated calendar (days): sales on day 1 and day 8, B2 on day 31, sales on day 75 (so day < 15 is older than
# 60 days), restore on day 76. B1 is on day 20 (inside a server window shorter than 60 days), except in b_expired
# and e_unverified, where it is on day 2 (older than 60 days at the restore).
SCRATCH_DB = "verify_scratch"  # throwaway database inside the throwaway spike container


def psql(sql, db="postgres"):
    out = subprocess.run(["docker", "exec", PG_CONTAINER, "psql", "-U", "postgres", "-d", db, "-tAX",
                          "-v", "ON_ERROR_STOP=1", "-c", sql], capture_output=True, text=True, check=True)
    return out.stdout.strip()


def pg_backup(path):
    with open(path, "wb") as f:
        subprocess.run(["docker", "exec", PG_CONTAINER, "pg_dump", "-U", "postgres", "-d", "postgres", "-Fc"],
                       stdout=f, check=True)


def pg_verify(path):
    """OQ29 durable watermark: restore the backup into the scratch database and read the highest device sequence it
    holds. Returns that sequence, or None if the restore fails (then the backup confirms nothing)."""
    subprocess.run(["docker", "exec", PG_CONTAINER, "dropdb", "-U", "postgres", "--if-exists", SCRATCH_DB], check=True)
    subprocess.run(["docker", "exec", PG_CONTAINER, "createdb", "-U", "postgres", SCRATCH_DB], check=True)
    try:
        with open(path, "rb") as f:
            subprocess.run(["docker", "exec", "-i", PG_CONTAINER, "pg_restore", "-U", "postgres", "-d", SCRATCH_DB,
                            "--single-transaction"], stdin=f, check=True, stdout=subprocess.DEVNULL,
                           stderr=subprocess.PIPE)
        return int(psql("SELECT last_seq FROM cursor_ WHERE device_id = 'dev-1'", db=SCRATCH_DB))
    except subprocess.CalledProcessError:
        return None


def pg_restore(path, epoch):
    with open(path, "rb") as f:
        subprocess.run(["docker", "exec", "-i", PG_CONTAINER, "pg_restore", "-U", "postgres", "-d", "postgres",
                        "--clean", "--if-exists", "--single-transaction"], stdin=f, check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    psql(f"UPDATE meta SET epoch = '{epoch}'")  # restore runbook: every restore starts a new epoch
    return int(psql("SELECT last_seq FROM cursor_ WHERE device_id = 'dev-1'"))


def http_post(path):
    req = urllib.request.Request(SERVER_URL + path, method="POST", data=b"")
    with urllib.request.urlopen(req, timeout=5) as r:
        return json.loads(r.read())


def sc19_script(cell):
    def script(run):
        rng, i = run.rng, [0]
        run.restores, run.max_archived, run.before, run.inside = [], 0, {}, None

        def sell(n, sync_p=0.7):
            for _ in range(n):
                run.sale(i[0])
                i[0] += 1
                if rng.random() < sync_p:
                    run.log("sync", run.send({"op": "sync"}))

        def drain():
            for _ in range(10):
                r = run.send({"op": "sync"})
                if r and r.get("ok") and r.get("pending") == 0:
                    return

        def backup(name, during_sync=False, verified=True):
            path = os.path.join(run.dir, name + ".dump")
            applied = []
            if during_sync:  # restore point inside a batch: the server sleeps before COMMIT (SLOW_COMMIT_MS)
                run.ensure_alive()
                run.client.stdin.write(json.dumps({"op": "sync"}) + "\n")
                run.client.stdin.flush()
                time.sleep(0.15)
                pg_backup(path)
                line = run.client.stdout.readline().strip()
                run.log("sync (backup inside)", line[:200])
                applied = [x["seq"] for x in json.loads(line).get("results", []) if x["result"] == "applied"]
            else:
                pg_backup(path)
            wm = pg_verify(path) if verified else None  # e_unverified: the restore check of this backup fails
            if during_sync:  # the backup missed a batch that then committed
                run.inside = bool(applied) and wm is not None and wm < min(applied)
            if wm is not None:
                http_post(f"/archive?device=dev-1&seq={wm}")  # durable watermark: restore verified
                run.max_archived = max(run.max_archived, wm)
            run.log(f"backup {name} day {run.day}: watermark {wm if wm is not None else 'none (restore not verified)'}")
            return path

        def owner_edit():
            run.log("owner config", http_post(f"/config?price={rng.choice([3000, 4500, 6000, 9000, 12000]) + rng.randint(1, 99)}"))

        early_b1 = cell in ("b_expired", "e_unverified")
        owner_edit()
        run.send({"op": "pull_config"})
        run.day = 1
        sell(3)
        drain()
        if early_b1:
            run.day = 2
            b1 = backup("b1")
        run.day = 8
        sell(2)
        drain()
        if not early_b1:
            run.day = 20
            b1 = backup("b1")
        run.day = 30
        sell(3, sync_p=0 if cell in ("a_before", "a_inside") else 0.7)  # those two need pending commands
        run.day = 31
        if cell == "a_before":
            b2 = backup("b2")  # pending commands exist; the sync comes after the backup
            drain()
        elif cell == "a_inside":
            b2 = backup("b2", during_sync=True)
        else:
            drain()
            b2 = backup("b2", verified=cell != "e_unverified")
        run.day = 75
        sell(3)
        drain()  # all acknowledged; outbox rows gone; bills below the watermark and older than 60 days pruned
        for _ in range(2):
            owner_edit()
        run.send({"op": "pull_config"})
        st = run.send({"op": "state"})
        run.before = {b[1]: (b[2], b[3]) for b in st["bills"] if b[1] is not None}
        run.pruned = len(run.seq_of) - len(st["bills"])
        h_before = st["acked_seq"]
        # --- the restore, day 76 ---
        run.day = 76
        run.server_down = True
        run.server.terminate()
        run.server.wait()
        epoch = f"r{run.seed}-{cell}"
        if cell == "c_offline":
            sell(3)  # the cashier keeps selling while the server is being restored; sync attempts fail
        src = "b1" if cell in ("b_older", "b_expired", "e_unverified") else "b2"
        cur = pg_restore(b1 if src == "b1" else b2, epoch)
        run.restores.append({"epoch": epoch, "cursor_after": cur, "h_before": h_before})
        run.log(f"restored {src}: cursor {cur}, device acked {h_before}, pruned {run.pruned}, epoch {epoch}")
        run.server_down = False
        run.start_server()
        if cell == "d_config":
            for _ in range(2):
                owner_edit()  # version numbers seen before the restore come back with new content
        sell(2)
        drain()
        run.send({"op": "pull_config"})
    return script


def sc19_extra(run, dump):
    c = run.open_client_store()
    cfg = c.execute("SELECT cfg_epoch, cfg_version, cfg_price FROM sync_state WHERE id = 1").fetchall()[0]
    c.close()
    intent = [json.loads(b) for (b,) in run.intent.execute("SELECT body FROM actions")]
    return oracle.check_restore(intent, run.seq_of, dump, run.restores, run.before, cfg, run.max_archived,
                                retain_days=int(RETENTION_ENV["RETAIN_DAYS"]))


def sc19_run(seed, cell, mutant=None, label=None, verbose=False):
    env = {"SLOW_COMMIT_MS": "400"} if cell == "a_inside" else {}
    run = Run(seed, mutant, verbose=verbose, store="sqlite3mc", cipher="chacha20", fault=False,
              label=label or f"sc19-{cell}", server_env=env, client_env=RETENTION_ENV)
    run.script, run.extra = sc19_script(cell), sc19_extra
    r = run.go()
    r["restores"], r["inside"], r["pruned"] = run.restores, run.inside, run.pruned
    return r


def sc19(seeds=50, mutant_budget=60):
    t0 = time.time()
    summary = {"harness_commit": git_state(), "started": time.strftime("%Y-%m-%d %H:%M:%S"),
               "seeds_per_cell": seeds, "retention": RETENTION_ENV, "cells": [], "mutants": {}}
    print(f"phase 3 SC-19, commit {summary['harness_commit']}, {seeds} seeds per cell", flush=True)
    ok = True
    for cell in SC19_CELLS:
        t1 = time.time()
        bad, outcomes, inside, pruned = [], Counter(), 0, 0
        for s in range(1, seeds + 1):
            r = sc19_run(s, cell)
            inside += bool(r["inside"])
            pruned += r["pruned"]
            for e in r["reconcile_events"]:
                outcomes[e["outcome"]] += 1
            if r["violations"]:
                bad.append({"seed": s, "violations": r["violations"][:3]})
        # Exercised: the restore left a gap, the device had pruned something, a_inside really backed up mid-batch,
        # and b_expired really produced a lost range (the only cell where the rule allows one)
        exercised = (outcomes["resend"] + outcomes["lost_range"] > 0 and pruned > 0
                     and (cell != "a_inside" or inside > 0) and (cell != "b_expired" or outcomes["lost_range"] > 0))
        res = "FAIL" if bad else ("PASS" if exercised else "NOT ASSESSED (a cell condition never happened)")
        ok &= res == "PASS"
        summary["cells"].append({"cell": cell, "runs": seeds, "reconcile_outcomes": dict(outcomes),
                                 "backup_inside_batch": inside if cell == "a_inside" else None, "bills_pruned": pruned,
                                 "violating_runs": len(bad), "first_bad": bad[:3],
                                 "seconds": round(time.time() - t1, 1), "result": res})
        print(f"  {cell:12s} outcomes {dict(outcomes)}  pruned {pruned}{f'  inside {inside}/{seeds}' if cell == 'a_inside' else ''}"
              f"  violating {len(bad)}  {res}", flush=True)
    for m in SC19_MUTANTS:
        t1 = time.time()
        caught = None
        for n in range(mutant_budget):
            s, cell = n // len(SC19_CELLS) + 1, SC19_CELLS[n % len(SC19_CELLS)]
            r = sc19_run(s, cell, mutant=m, label=f"sc19-mutant-{m}")
            if r["violations"]:
                caught = (s, cell, r["violations"][0])
                break
        summary["mutants"][m] = {"caught": bool(caught), "runs_to_catch": n + 1 if caught else None,
                                 "seed_cell": caught[:2] if caught else None,
                                 "first_violation": caught[2] if caught else None, "seconds": round(time.time() - t1, 1)}
        ok &= bool(caught)
        print(f"  mutant {m:20s} {'CAUGHT' if caught else 'SURVIVED'} after {n + 1} runs: {caught[2] if caught else '-'}",
              flush=True)
    summary["gate"] = "PASS" if ok else "FAIL"
    summary["seconds_total"] = round(time.time() - t0, 1)
    with open(os.path.join(RUNS, "sc19-summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    print(f"SC-19: {summary['gate']}  (total {summary['seconds_total']} s)")
    return ok


# --- Phase 3, SC-20: disk full ------------------------------------------------------------------------------------
# Founder (2026-10-16): the counter keeps selling as soon as space is freed (no restart), the cashier and the owner
# see a clear "disk full" warning, and a failed marker write never crash-loops the app.
SC20_CELLS = ["a_txn_transient", "a_txn_persistent", "b_marker_write", "b_marker_fsync", "b_marker_replace",
              "c_ack_mark"]
SC20_MUTANTS = ["full_refuses", "marker_crash", "ack_despite_full"]
SC20_ENV = {**RETENTION_ENV, "FULL_SHIM": "1"}
SC20_TMPFS = "256k"  # real leg: the client's files live on a tmpfs this small


def sc20_script(cell):
    def script(run):
        rng, i = run.rng, [0]
        run.sc20 = {"cell": cell, "resumed": None, "restart_ok": None, "ack_failed": None}

        def sale():
            aid = f"s{run.seed}-a{i[0]}"
            run.sale(i[0])
            i[0] += 1
            return run.sale_replies.get(aid)

        def drain():
            for _ in range(10):
                r = run.send({"op": "sync"})
                if r and r.get("ok") and r.get("pending") == 0:
                    return

        sale()
        sale()
        drain()
        if cell.startswith("a_txn"):
            persistent = cell == "a_txn_persistent"
            run.send({"op": "arm_full", "n": rng.randint(1, 3), "persistent": persistent})
            sale()  # fails: disk full
            if persistent:
                sale()  # still full
                run.log("sync while full", run.send({"op": "sync"}))
                run.send({"op": "free_space"})
            r = sale()  # space is back (transient: the next write already succeeds)
            run.sc20["resumed"] = bool(r and r.get("ok"))
        elif cell.startswith("b_marker"):
            stage = cell.rsplit("_", 1)[1]
            run.send({"op": "arm_marker_full", "stage": stage})
            sale()
            sale()
            run.send({"op": "exit"})  # the cashier restarts the app while the disk is still full
            run.client.wait()
            run.client_env = {**run.client_env, "MARKER_FAIL": stage}
            run.start_client()
            r = run.send({"op": "marker"})
            run.sc20["restart_ok"] = bool(r and r.get("ok"))
            sale()
            run.client_env = {k: v for k, v in run.client_env.items() if k != "MARKER_FAIL"}
            run.send({"op": "free_space"})
            r = sale()
            run.sc20["resumed"] = bool(r and r.get("ok"))
        elif cell == "d_real_tmpfs":  # real ENOSPC from the kernel: the store, journal, marker and log share a tmpfs
            sale()  # left pending, so the sync on the full disk must write its acknowledgement
            filler = os.path.join(os.path.dirname(run.db), "filler")
            fd = os.open(filler, os.O_WRONLY | os.O_CREAT, 0o600)
            try:
                while True:
                    os.write(fd, b"\0" * 4096)
            except OSError:  # ENOSPC: the filesystem is full
                pass
            finally:
                os.close(fd)
            run.sc20["filled_bytes"] = os.path.getsize(filler)
            sale()
            sale()
            r = run.send({"op": "sync"})
            run.log("sync while full", r)
            run.sc20["ack_failed"] = bool(r and r.get("error") == "disk_full")
            os.remove(filler)  # the owner frees space
            r = sale()
            run.sc20["resumed"] = bool(r and r.get("ok"))
        elif cell == "c_ack_mark":
            sale()
            sale()  # pending
            run.send({"op": "arm_full", "n": 1, "persistent": True})
            r = run.send({"op": "sync"})  # the server applies the batch; the local acknowledgement write fails
            run.log("sync with full disk", r)
            run.sc20["ack_failed"] = bool(r and r.get("error") == "disk_full")
            run.send({"op": "free_space"})
            r = sale()
            run.sc20["resumed"] = bool(r and r.get("ok"))
        drain()
        run.sc20["marker"] = run.send({"op": "marker"})
    return script


def sc20_extra(run, dump):
    """SC-20 checks beside the money invariants. R6 selling resumes after space is freed; R7 every failure is
    visible to the cashier (reply) and the owner (server event with an alert); R8 the client process never died;
    R9 the marker caught up with the store; R10 a sale answered "not saved" left no trace anywhere."""
    v, st = [], run.sc20
    if st["resumed"] is not True:
        v.append(("R6", "selling did not resume after space was freed"))
    failed = [aid for aid, r in run.sale_replies.items() if r is not None and not r.get("ok")]
    for aid in failed:
        r = run.sale_replies[aid]
        if r.get("error") != "disk_full" or r.get("warning") != "disk_full":
            v.append(("R7", f"{aid} failed without a disk-full warning: {r}"))
    kinds = Counter(e["kind"] for e in dump.get("device_events", []) if e["owner_alert"])
    want = "marker_behind" if st["cell"].startswith("b_marker") else "disk_full"
    if st["cell"] == "d_real_tmpfs":  # a real full disk may hit the commit, the marker or both
        want = "disk_full" if kinds["disk_full"] or not kinds["marker_behind"] else "marker_behind"
    if not kinds[want]:
        v.append(("R7", f"no {want} owner alert on the server (events: {dict(kinds)})"))
    if st["cell"].startswith("b_marker"):
        warned = [r for r in run.sale_replies.values() if r and r.get("ok") and r.get("warning")]
        if not warned:
            v.append(("R7", "sales saved during the marker failure carried no warning"))
        if st["restart_ok"] is not True:
            v.append(("R8", "the app did not start while the marker could not be written"))
    if run.fired:
        v.append(("R8", f"client or server died: {run.fired}"))
    m = st.get("marker") or {}
    if m.get("marker_seq") != m.get("counter"):
        v.append(("R9", f"marker {m.get('marker_seq')} != store counter {m.get('counter')} after space was freed"))
    c = run.open_client_store()
    bills = {r[0] for r in c.execute("SELECT action_id FROM bills").fetchall()}
    c.close()
    on_server = {r["action_id"] for r in dump["ledger"]}
    for aid in failed:
        if aid in bills or aid in on_server:
            v.append(("R10", f"{aid} answered 'not saved' but is {'on the device' if aid in bills else 'on the server'}"))
    exercised = {"a": bool(failed), "b": kinds["marker_behind"] > 0, "c": st["ack_failed"] is True,
                 "d": bool(failed) and st["ack_failed"] is True}[st["cell"][0]]
    run.sc20["exercised"] = exercised
    return v, frozenset()


def sc20_run(seed, cell, mutant=None, label=None, verbose=False):
    env = dict(SC20_ENV)
    if cell == "d_real_tmpfs":
        env.pop("FULL_SHIM")  # real ENOSPC, no shim
    run = Run(seed, mutant, verbose=verbose, store="sqlite3mc", cipher="chacha20", fault=False,
              label=label or f"sc20-{cell}", client_env=env)
    run.script, run.extra = sc20_script(cell), sc20_extra
    fs = None
    if cell == "d_real_tmpfs":  # needs `unshare -r -m` (run.sh sc20real): a fresh size-capped tmpfs per run
        fs = os.path.join(run.dir, "fs")
        os.makedirs(fs)
        subprocess.run(["mount", "-t", "tmpfs", "-o", f"size={SC20_TMPFS}", "tmpfs", fs], check=True)
        run.db = os.path.join(fs, "client.db")
    try:
        r = run.go()
    finally:
        if fs:
            subprocess.run(["umount", fs], check=False)
    r["sc20"] = {k: v for k, v in run.sc20.items() if k != "marker"}
    return r


def sc20_real(seeds=50):
    """SC-20 real-filesystem leg; run inside `unshare -r -m` so the driver may mount a tmpfs."""
    t0 = time.time()
    summary = {"harness_commit": git_state(), "started": time.strftime("%Y-%m-%d %H:%M:%S"), "tmpfs": SC20_TMPFS,
               "seeds": seeds}
    print(f"phase 3 SC-20 real tmpfs leg, commit {summary['harness_commit']}, {seeds} seeds", flush=True)
    bad, exercised, failed_sales, marker_behind = [], 0, 0, 0
    for s in range(1, seeds + 1):
        r = sc20_run(s, "d_real_tmpfs")
        exercised += bool(r["sc20"].get("exercised"))
        if r["violations"]:
            bad.append({"seed": s, "violations": r["violations"][:3]})
    res = "FAIL" if bad else ("PASS" if exercised == seeds else f"NOT ASSESSED ({seeds - exercised} runs never hit ENOSPC)")
    summary.update({"exercised": exercised, "violating_runs": len(bad), "first_bad": bad[:3], "result": res,
                    "seconds_total": round(time.time() - t0, 1)})
    with open(os.path.join(RUNS, "sc20-real-summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    print(f"  d_real_tmpfs      exercised {exercised}/{seeds}  violating {len(bad)}  {res}  ({summary['seconds_total']} s)")
    return res == "PASS"


def sc20(seeds=50, mutant_budget=60):
    t0 = time.time()
    summary = {"harness_commit": git_state(), "started": time.strftime("%Y-%m-%d %H:%M:%S"),
               "seeds_per_cell": seeds, "cells": [], "mutants": {}}
    print(f"phase 3 SC-20 (disk full), commit {summary['harness_commit']}, {seeds} seeds per cell", flush=True)
    ok = True
    for cell in SC20_CELLS:
        t1 = time.time()
        bad, exercised = [], 0
        for s in range(1, seeds + 1):
            r = sc20_run(s, cell)
            exercised += bool(r["sc20"].get("exercised"))
            if r["violations"]:
                bad.append({"seed": s, "violations": r["violations"][:3]})
        res = "FAIL" if bad else ("PASS" if exercised == seeds else f"NOT ASSESSED ({seeds - exercised} runs never hit the fault)")
        ok &= res == "PASS"
        summary["cells"].append({"cell": cell, "runs": seeds, "exercised": exercised, "violating_runs": len(bad),
                                 "first_bad": bad[:3], "seconds": round(time.time() - t1, 1), "result": res})
        print(f"  {cell:17s} exercised {exercised}/{seeds}  violating {len(bad)}  {res}", flush=True)
    for m in SC20_MUTANTS:
        t1 = time.time()
        caught = None
        for n in range(mutant_budget):
            s, cell = n // len(SC20_CELLS) + 1, SC20_CELLS[n % len(SC20_CELLS)]
            r = sc20_run(s, cell, mutant=m, label=f"sc20-mutant-{m}")
            if r["violations"]:
                caught = (s, cell, r["violations"][0])
                break
        summary["mutants"][m] = {"caught": bool(caught), "runs_to_catch": n + 1 if caught else None,
                                 "seed_cell": caught[:2] if caught else None,
                                 "first_violation": caught[2] if caught else None, "seconds": round(time.time() - t1, 1)}
        ok &= bool(caught)
        print(f"  mutant {m:18s} {'CAUGHT' if caught else 'SURVIVED'} after {n + 1} runs: {caught[2] if caught else '-'}",
              flush=True)
    summary["gate"] = "PASS" if ok else "FAIL"
    summary["seconds_total"] = round(time.time() - t0, 1)
    with open(os.path.join(RUNS, "sc20-summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    print(f"SC-20: {summary['gate']}  (total {summary['seconds_total']} s)")
    return ok


# --- Phase 3, SC-21a: app update with an unsynced outbox and a local schema migration ----------------------------
SC21_KILLS = ["before_copy", "after_copy", "mid_ddl", "after_commit", "before_marker", "before_cleanup"]
SC21_CELLS = ["none"] + SC21_KILLS + ["downgrade"]
SC21_MUTANTS = ["nonatomic_migration", "no_premigrate_copy", "reserialize_on_upgrade"]
SC21_COMMITTED = {"after_commit", "before_marker", "before_cleanup"}  # killed after the migration committed


def file_sha(path):
    import hashlib
    return hashlib.sha256(open(path, "rb").read()).hexdigest() if os.path.exists(path) else None


def sc21_script(cell):
    def script(run):
        i = [0]
        run.sc21 = {"cell": cell, "killed": None, "after_kill": None, "copy_after_kill": None, "final": None,
                    "downgrade": None}

        def sale():
            aid = f"s{run.seed}-a{i[0]}"
            run.sale(i[0])
            i[0] += 1
            return run.sale_replies.get(aid)

        def drain():
            for _ in range(10):
                r = run.send({"op": "sync"})
                if r and r.get("ok") and r.get("pending") == 0:
                    return

        def restart(**env):
            if run.client.poll() is None:
                run.send({"op": "exit"})
                run.client.wait()
            run.client_env = {k: v for k, v in {**run.client_env, **env}.items() if v is not None}
            run.start_client()

        # App version 1: synced sales, then pending ones; the ack of two that the server applies is lost
        for _ in range(3):
            sale()
        drain()
        sale()
        sale()
        restart(FP="client:mid_mark:1")
        run.log("sync with lost ack", run.send({"op": "sync"}))  # the server applies both; the client dies mid-ack
        run.client.wait()
        restart(FP=None)
        sale()  # three pending now, two of them already applied on the server
        # The update: app version 2 starts, killed at the cell's migration point
        restart(SCHEMA_VERSION="2", FP=None if cell in ("none", "downgrade") else f"migrate:{cell}:1")
        r = run.send({"op": "schema"})
        if r is None:  # died at the failpoint
            run.client.wait()
            run.sc21["killed"] = True
            copy_db = os.path.join(run.db + ".premigrate", os.path.basename(run.db))
            run.sc21["copy_after_kill"] = sc21_copy_state(run, copy_db)
            restart(SCHEMA_VERSION="2", FP=None, INSPECT="1")  # look at the store as the kill left it
            run.sc21["after_kill"] = run.send({"op": "schema"})
            restart(SCHEMA_VERSION="2", INSPECT=None)  # the app starts again and finishes the migration
            r = run.send({"op": "schema"})
        run.sc21["final"] = r
        sale()
        sale()
        drain()
        if cell == "downgrade":  # the old app is started again on the new store
            run.send({"op": "exit"})
            run.client.wait()
            before = (file_sha(run.db), file_sha(run.db + ".hwm"))
            run.client_env = {**run.client_env, "SCHEMA_VERSION": "1"}
            run.start_client()
            r1 = run.send({"op": "sale", "action_id": f"s{run.seed}-old", "session_id": "x", "start_min": 0,
                           "end_min": 1, "rate_per_hour": 3000, "cafe_piasters": 0})
            run.send({"op": "exit"})
            run.client.wait()
            after = (file_sha(run.db), file_sha(run.db + ".hwm"))
            events = open(run.db + ".events.jsonl").read() if os.path.exists(run.db + ".events.jsonl") else ""
            run.sc21["downgrade"] = {"refused": bool(r1) and r1.get("store") == "refused",
                                     "unchanged": before == after and not os.path.exists(run.db + "-journal"),
                                     "event": "downgrade_refused" in events}
            run.client_env = {**run.client_env, "SCHEMA_VERSION": "2"}
            run.start_client()
            sale()
            drain()
    return script


def sc21_copy_state(run, path):
    """The pre-migration copy as the kill left it: None, or (user_version, integrity)."""
    if not os.path.exists(path):
        return None
    import apsw
    c = apsw.Connection(path, flags=apsw.SQLITE_OPEN_READONLY)
    c.execute("PRAGMA cipher = chacha20").fetchall()
    c.execute(f"PRAGMA key = 'raw:{run.key}'").fetchall()
    try:
        return [c.execute("PRAGMA user_version").fetchall()[0][0], c.execute("PRAGMA integrity_check").fetchall()[0][0]]
    except apsw.Error as e:
        return ["unreadable", type(e).__name__]
    finally:
        c.close()


def sc21_extra(run, dump):
    """R11 after any kill the store is all schema 1 or all schema 2; R12 the pre-migration copy (a valid schema-1
    store) exists from before the commit until verification, and is gone at the end; R13 every command on the
    server carries the canonical payload hash; R14 an older app refuses a newer store without touching it."""
    v, st = [], run.sc21
    ak = st["after_kill"]
    if ak:
        parts = (ak["bills_tax"], ak["bill_lines"], ak["outbox_envelope"])
        v1 = ak["user_version"] in (0, 1) and not any(parts)
        v2 = ak["user_version"] == 2 and all(parts)
        if not (v1 or v2):
            v.append(("R11", f"half-migrated store after kill at {st['cell']}: {ak}"))
        if st["cell"] in SC21_COMMITTED:
            cs = st["copy_after_kill"]
            if not cs or cs[0] not in (0, 1) or cs[1] != "ok":
                v.append(("R12", f"no valid pre-migration copy after a kill at {st['cell']}: {cs}"))
    fin = st["final"] or {}
    if fin.get("user_version") != 2 or fin.get("premigrate"):
        v.append(("R12", f"final state not migrated and clean: {fin}"))
    intent = {json.loads(b)["action_id"]: json.loads(b) for (b,) in run.intent.execute("SELECT body FROM actions")}
    by_seq = {s_: aid for aid, s_ in run.seq_of.items() if s_}
    for row in dump["inbox"]:
        aid = by_seq.get(row["seq"])
        if aid in intent and row["payload_hash"] != oracle.expected_hash(intent[aid]):
            v.append(("R13", f"seq {row['seq']} hash differs from the canonical payload of {aid}"))
    if st["cell"] == "downgrade":
        d = st["downgrade"] or {}
        if not (d.get("refused") and d.get("unchanged") and d.get("event")):
            v.append(("R14", f"downgrade not refused cleanly: {d}"))
    killed_ok = st["cell"] in ("none", "downgrade") or st["killed"]
    run.sc21["exercised"] = bool(killed_ok) and (st["cell"] != "downgrade" or st["downgrade"] is not None)
    return v, frozenset()


def sc21_run(seed, cell, mutant=None, label=None, verbose=False):
    run = Run(seed, mutant, verbose=verbose, store="sqlite3mc", cipher="chacha20", fault=False,
              label=label or f"sc21-{cell}", client_env={**RETENTION_ENV, "SCHEMA_VERSION": "1"})
    run.script, run.extra = sc21_script(cell), sc21_extra
    r = run.go()
    r["sc21"] = run.sc21
    return r


def sc21(seeds=50, mutant_budget=40):
    t0 = time.time()
    summary = {"harness_commit": git_state(), "started": time.strftime("%Y-%m-%d %H:%M:%S"),
               "seeds_per_cell": seeds, "cells": [], "mutants": {}}
    print(f"phase 3 SC-21a (app update + migration), commit {summary['harness_commit']}, {seeds} seeds per cell", flush=True)
    ok = True
    for cell in SC21_CELLS:
        t1 = time.time()
        bad, exercised, dups = [], 0, 0
        for s in range(1, seeds + 1):
            r = sc21_run(s, cell)
            exercised += bool(r["sc21"].get("exercised"))
            if r["violations"]:
                bad.append({"seed": s, "violations": r["violations"][:3]})
        res = "FAIL" if bad else ("PASS" if exercised == seeds else f"NOT ASSESSED ({seeds - exercised} runs not exercised)")
        ok &= res == "PASS"
        summary["cells"].append({"cell": cell, "runs": seeds, "exercised": exercised, "violating_runs": len(bad),
                                 "first_bad": bad[:3], "seconds": round(time.time() - t1, 1), "result": res})
        print(f"  {cell:15s} exercised {exercised}/{seeds}  violating {len(bad)}  {res}", flush=True)
    for m in SC21_MUTANTS:
        t1 = time.time()
        caught = None
        for n in range(mutant_budget):
            s, cell = n // len(SC21_CELLS) + 1, SC21_CELLS[n % len(SC21_CELLS)]
            r = sc21_run(s, cell, mutant=m, label=f"sc21-mutant-{m}")
            if r["violations"]:
                caught = (s, cell, r["violations"][0])
                break
        summary["mutants"][m] = {"caught": bool(caught), "runs_to_catch": n + 1 if caught else None,
                                 "seed_cell": caught[:2] if caught else None,
                                 "first_violation": caught[2] if caught else None, "seconds": round(time.time() - t1, 1)}
        ok &= bool(caught)
        print(f"  mutant {m:22s} {'CAUGHT' if caught else 'SURVIVED'} after {n + 1} runs: {caught[2] if caught else '-'}",
              flush=True)
    summary["gate"] = "PASS" if ok else "FAIL"
    summary["seconds_total"] = round(time.time() - t0, 1)
    with open(os.path.join(RUNS, "sc21-summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    print(f"SC-21a: {summary['gate']}  (total {summary['seconds_total']} s)")
    return ok


# --- Phase 3, SC-22: two app instances started on the same store ----------------------------------------------
SC22_CELLS = ["a_simultaneous", "b_second_later", "c_kill_holder"]
SC22_MUTANTS = ["no_instance_lock", "lock_released_early"]
SC22_ROUNDS = 5  # simultaneous starts per a_simultaneous run


def spawn(run):
    """Start another client process on the same store; run.client is left unchanged."""
    old = run.client
    run.start_client()
    new, run.client = run.client, old
    return new


def talk(proc, msg):
    try:
        proc.stdin.write(json.dumps(msg) + "\n")
        proc.stdin.flush()
        line = proc.stdout.readline()
    except BrokenPipeError:
        line = ""
    return json.loads(line) if line else None


def stop(proc):
    if proc.poll() is None:
        talk(proc, {"op": "exit"})
    proc.wait()


def sc22_script(cell):
    def script(run):
        i = [0]
        run.sc22 = {"cell": cell, "both_served": [], "loser_ok": [], "marker": [], "torn_marker": 0,
                    "refused_seen": 0, "took_over": None, "hot_journal": None}

        def mark_sample():
            try:
                m = json.load(open(run.db + ".hwm"))
                run.sc22["marker"].append(int(m["seq"]))
            except FileNotFoundError:
                pass
            except (ValueError, KeyError, TypeError):
                run.sc22["torn_marker"] += 1

        def sale_on(proc):
            a = run.new_action(i[0])
            i[0] += 1
            run.intent.execute("INSERT INTO actions VALUES (?,?)", (a["action_id"], json.dumps(a)))
            r = talk(proc, a)
            run.sale_replies[a["action_id"]] = r
            if r and r.get("ok"):
                run.seq_of[a["action_id"]] = r.get("seq")
                run.intent.execute("INSERT INTO acks VALUES (?)", (a["action_id"],))
            run.log(f"sale {a['action_id']} on pid {proc.pid}: {r}")
            mark_sample()
            return r

        def drain(proc):
            for _ in range(10):
                r = talk(proc, {"op": "sync"})
                mark_sample()
                if r and r.get("ok") and r.get("pending") == 0:
                    return

        if cell == "a_simultaneous":
            stop(run.client)
            for _ in range(SC22_ROUNDS):
                p1, p2 = spawn(run), spawn(run)  # started back to back: they race for the store
                r1, r2 = talk(p1, {"op": "state"}), talk(p2, {"op": "state"})
                served = [p for p, r in ((p1, r1), (p2, r2)) if r and r.get("ok")]
                run.sc22["both_served"].append(len(served))
                if len(served) == 1:
                    winner = served[0]
                    loser = p2 if winner is p1 else p1
                    sale_on(winner)
                    r = sale_on(loser)
                    run.sc22["refused_seen"] += bool(r and r.get("error") == "another_instance")
                    drain(winner)
                else:
                    for p in served:
                        r = sale_on(p)
                        run.sc22["loser_ok"].append(bool(r and r.get("ok")))
                    drain(served[0] if served else p1)
                stop(p1)
                stop(p2)
            run.start_client()
        elif cell == "b_second_later":
            sale_on(run.client)  # the first instance has the store before the second starts
            sale_on(run.client)
            drain(run.client)
            b = spawn(run)  # the cashier double-clicks the app while it is running
            for _ in range(2):
                r = sale_on(b)
                run.sc22["refused_seen"] += bool(r and r.get("error") == "another_instance")
                run.sc22["loser_ok"].append(bool(r and r.get("ok")))
                sale_on(run.client)
            drain(run.client)
            stop(b)
        elif cell == "c_kill_holder":
            talk(run.client, {"op": "state"})  # the holder has the store before the second instance starts
            b = spawn(run)  # started while the holder (killed at its k-th sale, mid-transaction) is alive
            r = talk(b, {"op": "state"})
            run.sc22["refused_seen"] += bool(r and r.get("error") == "another_instance")
            died = False
            for _ in range(6):
                if sale_on(run.client) is None:  # the holder died mid-transaction
                    died = True
                    break
            if died:
                run.client.wait()
            else:
                stop(run.client)
            run.sc22["hot_journal"] = os.path.exists(run.db + "-journal")
            stop(b)
            run.start_client()  # the cashier starts the app again: it takes the store over
            r = talk(run.client, {"op": "state"})
            run.sc22["took_over"] = bool(r and r.get("ok"))
            sale_on(run.client)
            drain(run.client)
    return script


def sc22_extra(run, dump):
    """R15 the commit marker never tears or moves backwards; R16 at most one instance serves the store at a time;
    R17 a sale refused because another instance holds the store says so and leaves no trace."""
    v, st = [], run.sc22
    if st["torn_marker"]:
        v.append(("R15", f"marker unreadable {st['torn_marker']} times"))
    m = st["marker"]
    if any(b < a for a, b in zip(m, m[1:])):
        v.append(("R15", f"marker moved backwards: {m}"))
    if any(n > 1 for n in st["both_served"]) or any(st["loser_ok"]):
        v.append(("R16", f"two instances served the store (rounds {st['both_served']}, second accepted {st['loser_ok']})"))
    c = run.open_client_store()
    bills = {r[0] for r in c.execute("SELECT action_id FROM bills").fetchall()}
    c.close()
    on_server = {r["action_id"] for r in dump["ledger"]}
    for aid, r in run.sale_replies.items():
        if r and r.get("error") == "another_instance":
            if r.get("warning") != "another_instance":
                v.append(("R17", f"{aid} refused without a warning"))
            if aid in bills or aid in on_server:
                v.append(("R17", f"{aid} answered 'another instance' but was saved"))
    if st["cell"] == "c_kill_holder" and st["took_over"] is not True:
        v.append(("R16", "the restarted instance could not take the store over after the holder died"))
    ex = {"a_simultaneous": len(st["both_served"]) == SC22_ROUNDS,
          "b_second_later": st["refused_seen"] > 0 or any(st["loser_ok"]),
          "c_kill_holder": st["hot_journal"] is True}[st["cell"]]
    run.sc22["exercised"] = ex
    return v, frozenset()


def sc22_run(seed, cell, mutant=None, label=None, verbose=False):
    fault = ("client:mid_local_txn", random.Random(f"{seed}|sc22").randint(1, 4)) if cell == "c_kill_holder" else False
    run = Run(seed, mutant, verbose=verbose, store="sqlite3mc", cipher="chacha20", fault=fault,
              label=label or f"sc22-{cell}", client_env=dict(RETENTION_ENV))
    run.script, run.extra = sc22_script(cell), sc22_extra
    r = run.go()
    r["sc22"] = {k: v for k, v in run.sc22.items() if k != "marker"}
    return r


def sc22(seeds=50, mutant_budget=30):
    t0 = time.time()
    summary = {"harness_commit": git_state(), "started": time.strftime("%Y-%m-%d %H:%M:%S"),
               "seeds_per_cell": seeds, "cells": [], "mutants": {}}
    print(f"phase 3 SC-22 (two instances), commit {summary['harness_commit']}, {seeds} seeds per cell", flush=True)
    ok = True
    for cell in SC22_CELLS:
        t1 = time.time()
        bad, exercised, refused = [], 0, 0
        for s in range(1, seeds + 1):
            r = sc22_run(s, cell)
            exercised += bool(r["sc22"].get("exercised"))
            refused += r["sc22"]["refused_seen"]
            if r["violations"]:
                bad.append({"seed": s, "violations": r["violations"][:3]})
        res = "FAIL" if bad else ("PASS" if exercised == seeds else f"NOT ASSESSED ({seeds - exercised} runs not exercised)")
        ok &= res == "PASS"
        summary["cells"].append({"cell": cell, "runs": seeds, "exercised": exercised, "second_refused": refused,
                                 "violating_runs": len(bad), "first_bad": bad[:3],
                                 "seconds": round(time.time() - t1, 1), "result": res})
        print(f"  {cell:15s} exercised {exercised}/{seeds}  second instance refused {refused}x  violating {len(bad)}  {res}",
              flush=True)
    for m in SC22_MUTANTS:
        t1 = time.time()
        caught = None
        for n in range(mutant_budget):
            s, cell = n // len(SC22_CELLS) + 1, SC22_CELLS[n % len(SC22_CELLS)]
            r = sc22_run(s, cell, mutant=m, label=f"sc22-mutant-{m}")
            if r["violations"]:
                caught = (s, cell, r["violations"][0])
                break
        summary["mutants"][m] = {"caught": bool(caught), "runs_to_catch": n + 1 if caught else None,
                                 "seed_cell": caught[:2] if caught else None,
                                 "first_violation": caught[2] if caught else None, "seconds": round(time.time() - t1, 1)}
        ok &= bool(caught)
        print(f"  mutant {m:20s} {'CAUGHT' if caught else 'SURVIVED'} after {n + 1} runs: {caught[2] if caught else '-'}",
              flush=True)
    summary["gate"] = "PASS" if ok else "FAIL"
    summary["seconds_total"] = round(time.time() - t0, 1)
    with open(os.path.join(RUNS, "sc22-summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    print(f"SC-22: {summary['gate']}  (total {summary['seconds_total']} s)")
    return ok


# --- Phase 3, SC-23: the owner changes prices while the device is offline with sessions running -------------------
# Founder rules (2026-10-16): (1) a running session keeps the prices frozen at its start (G12); a tier change (N4)
# uses the price list the device holds at that moment. (2) A sale offline at the last price the device knew is a
# valid fact: no per-sale review flag, ONE owner summary per offline period. (3) A new price takes effect on the
# device when it is received, never retroactively; the server never re-prices a recorded sale.
# Rule 2 widened (founder, 2026-10-17): one summary per period in which the device lacked the current list, offline
# or simply not yet pulled; judged by the sale's cfg_version against the server's list, never by device time.
SC23_CELLS = ["a_offline_session", "b_tier_change", "c_two_periods", "d_online_lag", "e_no_price_list",
              "f_corrupt_session_op"]
SC23_MUTANTS = ["reprice_on_server", "per_sale_flag", "retroactive_price", "tier_uses_start_price", "offline_only",
                "zero_price_default", "swallow_store_errors", "round_per_segment"]
SC23_LAG_TOLERANCE = 0.5  # seconds between the driver's view and the server's lag period bounds
SC23_GAP = 0.8  # seconds without device contact: an offline period for a server with GAP_MS=500


def post_json(path, body):
    req = urllib.request.Request(SERVER_URL + path, method="POST", data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=5) as r:
        return json.loads(r.read())


def sc23_script(cell):
    def script(run):
        rng, n = run.rng, [0]
        m = {"server_v": 1, "device": None, "sessions": {}, "pending": [], "offline": False, "edit_t": {}, "pull_t": []}
        run.sc23 = {"cell": cell, "expected": {}, "expected_offline": {}, "bills": {}, "tier_changes": 0,
                    "refusals": []}

        def owner(drop=()):  # the owner edits the price list on the server
            prices = {"std": rng.choice([3000, 4500, 6000]) + rng.randint(1, 99),
                      "vip": rng.choice([7500, 9000, 12000]) + rng.randint(1, 99),
                      "cafe": rng.choice([1000, 1500, 2500]) + rng.randint(1, 49),
                      "round_piasters": rng.choice([1, 25, 50, 100])}  # the owner's rounding step (OQ8)
            prices = {k: p_ for k, p_ in prices.items() if k not in drop}
            r = post_json("/config", {"prices": prices})
            m["server_v"] = r["version"]
            m["edit_t"][r["version"]] = time.time()
            run.log(f"owner price list v{r['version']}: {prices}")

        def pull():
            r = run.send({"op": "pull_config"})
            m["device"] = (r["version"], r["prices"])  # what the device received, and from now on uses
            m["pull_t"].append((r["version"], time.time()))

        def start(tier, at):
            sid = f"s{run.seed}-sess{n[0]}"
            n[0] += 1
            v, prices = m["device"]
            run.send({"op": "start_session", "session_id": sid, "start_min": at, "tier": tier})
            m["sessions"][sid] = {"start": at, "segs": [(at, tier, prices[tier], v)]}
            return sid

        def change(sid, at, tier):
            v, prices = m["device"]
            run.send({"op": "change_tier", "session_id": sid, "at_min": at, "tier": tier})
            m["sessions"][sid]["segs"].append((at, tier, prices[tier], v))
            run.sc23["tier_changes"] += 1

        def close(sid, end):
            v, prices = m["device"]
            ss = m["sessions"].pop(sid)
            exact, used = 0, []  # piaster-minutes over all segments
            for k, (frm, tier, rate, sv) in enumerate(ss["segs"]):
                until = ss["segs"][k + 1][0] if k + 1 < len(ss["segs"]) else end
                exact += (until - frm) * rate
                used.append(sv)
            step = prices["round_piasters"]  # rounded once on the total, at the step of the list held at close
            total = (exact + 30 * step) // (60 * step) * step
            cafe_n = rng.randint(0, 3)
            total += cafe_n * prices["cafe"]
            if cafe_n:
                used.append(v)
            aid = f"s{run.seed}-a{sid.rsplit('sess', 1)[1]}"
            a = {"op": "close_session", "action_id": aid, "session_id": sid, "start_min": ss["start"], "end_min": end,
                 "cafe_n": cafe_n, "expected_piasters": total, "cfg_version": max(used)}
            run.intent.execute("INSERT INTO actions VALUES (?,?)", (aid, json.dumps(a)))
            r = run.send(a)
            run.sale_replies[aid] = r
            if r and r.get("ok"):
                run.seq_of[aid] = r.get("seq")
                run.intent.execute("INSERT INTO acks VALUES (?)", (aid,))
            run.sc23["bills"][aid] = (total, max(used))
            m["pending"].append(max(used))
            run.log(f"close {sid}: expected {total} (versions {used}) -> {r}")

        def offline():
            m["offline"] = True
            time.sleep(SC23_GAP)  # no device contact for longer than the server's GAP_MS

        def sync():  # back online (or still online): upload everything, then count what was billed at an old price
            for _ in range(10):
                r = run.send({"op": "sync"})
                if r and r.get("ok") and r.get("pending") == 0:
                    break
            # One summary per old version the device was still on (rule 2 widened), offline or online.
            for v in (v for v in m["pending"] if v < m["server_v"]):
                run.sc23["expected"][v] = run.sc23["expected"].get(v, 0) + 1
                run.sc23["expected_offline"][v] = run.sc23["expected_offline"].get(v, False) or m["offline"]
            m["pending"], m["offline"] = [], False
            run.sc23["edit_t"], run.sc23["pull_t"] = m["edit_t"], m["pull_t"]

        t = [0]

        def at(k):
            t[0] += k
            return t[0]

        if cell == "e_no_price_list":
            # A device that has never received a price list refuses to start a session or sell; nothing is billed.
            for op in ({"op": "start_session", "session_id": f"s{run.seed}-x0", "start_min": 0, "tier": "std"},
                       {"op": "sell_items", "action_id": f"s{run.seed}-x1", "n": 2},
                       {"op": "close_session", "action_id": f"s{run.seed}-x2", "session_id": f"s{run.seed}-x0",
                        "end_min": 30, "cafe_n": 1}):
                r = run.send(op)
                run.sc23["refusals"].append((op["op"], r))
            run.sc23["stats_before_list"] = run.send({"op": "stats"})
            owner(drop=("vip",))  # a list without a vip price
            pull()
            r = run.send({"op": "start_session", "session_id": f"s{run.seed}-x3", "start_min": 0, "tier": "vip"})
            run.sc23["refusals"].append(("start_session vip (no vip price)", r))
            s1 = start("std", at(0))  # std is priced: works
            close(s1, at(rng.randint(10, 60)))
            sync()
            return
        owner()
        pull()
        if cell == "a_offline_session":
            s1 = start("std", at(0))
            sync()
            offline()
            owner()  # the device does not know this list yet
            close(s1, at(rng.randint(20, 120)))  # frozen at start (rule 1), billed at the old list: valid (rule 2)
            s2 = start("vip", at(5))  # started offline: the last list the device knew
            close(s2, at(rng.randint(10, 90)))
            sync()
            pull()  # the new list takes effect now, not before (rule 3)
            s3 = start("std", at(5))
            close(s3, at(rng.randint(10, 90)))
            sync()
        elif cell == "b_tier_change":
            s1 = start("std", at(0))
            sync()
            owner()
            pull()  # online: the device has the new list
            change(s1, at(rng.randint(10, 60)), "vip")  # N4: the vip part at the list the device holds now
            close(s1, at(rng.randint(10, 60)))  # the std part stays at the rate frozen at start
            sync()
            offline()
            owner()
            s2 = start("std", at(5))
            change(s2, at(rng.randint(10, 60)), "vip")  # offline: still the last list the device knew
            close(s2, at(rng.randint(10, 60)))
            sync()
            pull()
        elif cell == "d_online_lag":
            s1 = start("std", at(0))
            sync()
            owner()  # the device stays online but has not pulled the new list yet
            close(s1, at(rng.randint(10, 60)))  # online, at the old list: valid, counted in a lag summary
            sync()
            s2 = start("vip", at(5))
            close(s2, at(rng.randint(10, 60)))
            sync()  # same lag period (same old version): the same summary
            pull()  # the lag ends here
            s3 = start("std", at(5))
            close(s3, at(rng.randint(10, 60)))
            sync()  # current list: not counted
            offline()
            owner()
            s4 = start("std", at(5))
            close(s4, at(rng.randint(10, 60)))
            sync()  # offline period summary of 1
            s5 = start("vip", at(5))
            close(s5, at(rng.randint(10, 60)))
            sync()  # back online, still not pulled: a lag summary on that version
            pull()
        elif cell == "e_no_price_list":
            pass  # handled before owner()/pull(): see below
        elif cell == "c_two_periods":
            offline()
            owner()
            s1 = start("std", at(0))
            close(s1, at(rng.randint(10, 90)))
            sync()  # period 1: one sale at the previous price
            pull()
            offline()
            s2 = start("vip", at(5))
            close(s2, at(rng.randint(10, 90)))
            sync()  # period 2: no price change, no summary
            offline()
            owner()
            for _ in range(2):
                s = start(rng.choice(["std", "vip"]), at(5))
                close(s, at(rng.randint(10, 90)))
            sync()  # period 3: two sales at the previous price
            pull()
    return script


def sc23_extra(run, dump):
    """R18 every bill equals the driver's price model (device and server; the server never re-prices);
    R19 exactly one owner summary per offline period with previous-price sales, with the right count, none online;
    R20 every bill carries the price-list version it used."""
    v, st = [], run.sc23
    c = run.open_client_store()
    bills = {r[0]: (r[1], r[2]) for r in c.execute("SELECT action_id, sale_piasters, payload FROM bills").fetchall()}
    c.close()
    for aid, (want, ver) in st["bills"].items():
        if aid in bills:
            got, payload = bills[aid]
            if got != want:
                v.append(("R18", f"{aid} billed {got} on the device, model says {want}"))
            if payload and json.loads(payload).get("cfg_version") != ver:
                v.append(("R20", f"{aid} carries version {json.loads(payload).get('cfg_version')}, model says {ver}"))
    summaries = dump.get("price_summaries", [])
    got = {s_["period_key"]: s_["n_sales"] for s_ in summaries if s_["kind"] == "lacking"}
    other = [s_ for s_ in summaries if s_["kind"] != "lacking"]
    if got != st["expected"] or other:
        v.append(("R19", f"summaries per lacking period {got} (other kinds {other}), expected {st['expected']}"))
    if any(not s_["owner_alert"] or s_["from_s"] is None for s_ in summaries):
        v.append(("R19", f"summary without an owner alert or without its period: {summaries}"))
    for s_ in summaries:  # the period runs from the next version's publication to the device's next pull
        if s_["kind"] == "lacking" and bool(s_["offline_periods"]) != st["expected_offline"].get(s_["period_key"], False):
            v.append(("R19", f"v{s_['period_key']}: {s_['offline_periods']} offline periods inside, model says "
                             f"{'some' if st['expected_offline'].get(s_['period_key']) else 'none'}"))
        if s_["kind"] == "lacking":
            want_from = st["edit_t"].get(s_["period_key"] + 1)
            want_to = next((t for ver, t in st["pull_t"] if ver > s_["period_key"]), None)
            if want_from is None or abs(s_["from_s"] - want_from) > SC23_LAG_TOLERANCE:
                v.append(("R19", f"period on v{s_['period_key']} starts {s_['from_s']}, model {want_from}"))
            if want_to is None or s_["to_s"] is None or abs(s_["to_s"] - want_to) > SC23_LAG_TOLERANCE:
                v.append(("R19", f"period on v{s_['period_key']} ends {s_['to_s']}, model {want_to}"))
    if st["cell"] == "e_no_price_list":  # R21: no price list or no price -> refused with a clear code, nothing billed
        for what, r in st["refusals"]:
            if not r or r.get("ok") or r.get("error") not in ("no_price_list", "price_missing", "unknown_session"):
                v.append(("R21", f"{what} without a price list was not refused clearly: {r}"))
        before = st.get("stats_before_list") or {}
        if before.get("bills") or before.get("outbox"):
            v.append(("R21", f"something was billed before the device had a price list: {before}"))
        zero = [r["action_id"] for r in dump["ledger"] if r["amount_piasters"] == 0]
        if zero:
            v.append(("R21", f"zero bills on the server: {zero}"))
    online_only = [k for k in st["expected"] if not st["expected_offline"].get(k)]
    st["exercised"] = {"b_tier_change": st["tier_changes"] >= 2, "e_no_price_list": len(st["refusals"]) == 4,
                       "d_online_lag": bool(online_only) and len(st["expected"]) >= 2}.get(st["cell"], bool(st["expected"]))
    return v, frozenset()


def sc23_corrupt(seed, mutant=None, verbose=False):
    """SC-23 f: a store damaged while the app runs is still REFUSED when a session op is the first to read the damaged
    page; the session-op handler (no price list, unknown session) must not swallow store errors. R22."""
    run = Run(seed, mutant, verbose=verbose, store="sqlite3mc", cipher="chacha20", fault=False,
              label=f"sc23-f_corrupt_session_op{'-' + mutant if mutant else ''}",
              client_env={**RETENTION_ENV, "CACHE_PAGES": "2"}, server_env={"GAP_MS": "500"})
    v, info = [], {}
    run.start_server(first=True)
    run.start_client(first=True)
    try:
        post_json("/config", {"prices": {"std": 6000, "vip": 9000, "cafe": 1500}})
        run.send({"op": "pull_config"})
        for k in range(6):  # enough rows for several pages
            sid = f"s{seed}-f{k}"
            run.send({"op": "start_session", "session_id": sid, "start_min": 0, "tier": "std"})
            run.send({"op": "close_session", "action_id": f"s{seed}-fa{k}", "session_id": sid, "end_min": 30 + k, "cafe_n": 1})
        run.send({"op": "release_cache"})  # the next read of every page comes from disk
        ps = 4096  # SQLite3MC default page size
        size = os.path.getsize(run.db)
        info["pages"] = size // ps
        with open(run.db, "r+b") as f:  # flip one byte in the middle of every page after page 1
            for pg in range(1, size // ps):
                f.seek(pg * ps + ps // 2)
                b = f.read(1)
                f.seek(pg * ps + ps // 2)
                f.write(bytes([b[0] ^ 0xFF]))
        damaged = file_sha(run.db)
        r1 = run.send({"op": "start_session", "session_id": f"s{seed}-f9", "start_min": 0, "tier": "std"})
        r2 = run.send({"op": "stats"})
        events = open(run.db + ".events.jsonl").read() if os.path.exists(run.db + ".events.jsonl") else ""
        info.update({"session_op_reply": r1, "next_op_reply": r2, "event": "store_error_during_operation" in events,
                     "unchanged_after_detection": file_sha(run.db) == damaged})
        if not (r1 and r1.get("store") == "refused"):
            v.append(("R22", f"the session op did not refuse the damaged store: {r1}"))
        if not (r2 and r2.get("store") == "refused"):
            v.append(("R22", f"the store was not refused for the next op: {r2}"))
        if not info["event"]:
            v.append(("R22", "no store_error_during_operation event"))
        if not info["unchanged_after_detection"]:
            v.append(("R22", "the damaged file was written after detection"))
    finally:
        if run.client.poll() is None:
            run.send({"op": "exit"})
            run.client.wait()
        run.server.terminate()
        run.server.wait()
    return {"violations": v, "sc23": {"cell": "f_corrupt_session_op", "exercised": info.get("pages", 0) > 1, **info}}


def sc23_run(seed, cell, mutant=None, label=None, verbose=False):
    if cell == "f_corrupt_session_op":
        return sc23_corrupt(seed, mutant, verbose)
    run = Run(seed, mutant, verbose=verbose, store="sqlite3mc", cipher="chacha20", fault=False,
              label=label or f"sc23-{cell}", client_env=dict(RETENTION_ENV),
              server_env={"GAP_MS": "500", "BUSINESS_HOURS": "1"})
    run.script, run.extra = sc23_script(cell), sc23_extra
    r = run.go()
    r["sc23"] = {k: v for k, v in run.sc23.items() if k not in ("bills", "edit_t", "pull_t")}
    r["price_summaries"] = r.get("price_summaries")
    return r


def sc23(seeds=50, mutant_budget=30):
    t0 = time.time()
    summary = {"harness_commit": git_state(), "started": time.strftime("%Y-%m-%d %H:%M:%S"),
               "seeds_per_cell": seeds, "gap_s": SC23_GAP, "cells": [], "mutants": {}}
    print(f"phase 3 SC-23 (prices while offline), commit {summary['harness_commit']}, {seeds} seeds per cell", flush=True)
    ok = True
    for cell in SC23_CELLS:
        t1 = time.time()
        bad, exercised, summaries = [], 0, 0
        for s in range(1, seeds + 1):
            r = sc23_run(s, cell)
            exercised += bool(r["sc23"].get("exercised"))
            summaries += len(r["sc23"].get("expected", {}))
            if r["violations"]:
                bad.append({"seed": s, "violations": r["violations"][:3]})
        res = "FAIL" if bad else ("PASS" if exercised == seeds else f"NOT ASSESSED ({seeds - exercised} runs not exercised)")
        ok &= res == "PASS"
        summary["cells"].append({"cell": cell, "runs": seeds, "exercised": exercised, "summaries_expected": summaries,
                                 "violating_runs": len(bad), "first_bad": bad[:3],
                                 "seconds": round(time.time() - t1, 1), "result": res})
        print(f"  {cell:18s} exercised {exercised}/{seeds}  summaries {summaries}  violating {len(bad)}  {res}", flush=True)
    for mu in SC23_MUTANTS:
        t1 = time.time()
        caught = None
        for k in range(mutant_budget):
            s, cell = k // len(SC23_CELLS) + 1, SC23_CELLS[k % len(SC23_CELLS)]
            r = sc23_run(s, cell, mutant=mu, label=f"sc23-mutant-{mu}")
            if r["violations"]:
                caught = (s, cell, r["violations"][0])
                break
        summary["mutants"][mu] = {"caught": bool(caught), "runs_to_catch": k + 1 if caught else None,
                                  "seed_cell": caught[:2] if caught else None,
                                  "first_violation": caught[2] if caught else None, "seconds": round(time.time() - t1, 1)}
        ok &= bool(caught)
        print(f"  mutant {mu:22s} {'CAUGHT' if caught else 'SURVIVED'} after {k + 1} runs: {caught[2] if caught else '-'}",
              flush=True)
    summary["gate"] = "PASS" if ok else "FAIL"
    summary["seconds_total"] = round(time.time() - t0, 1)
    with open(os.path.join(RUNS, "sc23-summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    print(f"SC-23: {summary['gate']}  (total {summary['seconds_total']} s)")
    return ok


# --- Phase 3, SC-25a: a 7-day offline backlog drained over short online windows, each cut mid-drain --------------
# OQ16 (founder 2026-10-17), "derived from capacity, not measured": 25 stations, 24 h, one session per station every
# 30 minutes (1,200 sessions/day), 3 cafe orders per session (3,600/day), about 5,000 money commands/day; the longest
# offline period is 7 days (about 35,000 commands), drained over online windows of a few minutes at shift changes,
# which can end mid-drain.
SC25_SCALES = {"tenth": 0.1, "full": 1.0}
SC25_SEEDS = {"tenth": 30, "full": 3}
SC25_DAYS = 7
SC25_SESSIONS_PER_DAY, SC25_CAFE_PER_DAY = 1200, 3600
SC25_WINDOWS = 6  # online windows; the first five are cut, the last one drains to the end
SC25_MUTANTS = ["fixed_batch", "drop_on_send"]
SC25_CUTS = ["resp_cut_150", "req_cut_120", "reset_peer"]  # reply lost after commit / request cut / connection reset


def sc25_script(scale):
    def script(run):
        rng, toxi = run.rng, run.net.toxi
        i = [0]
        st = run.sc25 = {"scale": scale, "windows": [], "commands": 0, "dups": 0}
        pending_intents, pending_acks = [], []

        def flush_intents():
            # The driver is never killed in SC-25, so its log is written in large batches (it must be complete before
            # the oracle runs, not durable per sale).
            run.intent.execute("BEGIN")
            run.intent.executemany("INSERT INTO actions VALUES (?,?)", pending_intents)
            run.intent.executemany("INSERT INTO acks VALUES (?)", pending_acks)
            run.intent.execute("COMMIT")
            pending_intents.clear()
            pending_acks.clear()

        def sell(day):
            k = i[0]
            i[0] += 1
            cafe = rng.random() < SC25_CAFE_PER_DAY / (SC25_CAFE_PER_DAY + SC25_SESSIONS_PER_DAY)
            start = rng.randint(0, 1400)
            a = {"op": "sale", "action_id": f"s{run.seed}-a{k}", "session_id": f"s{run.seed}-sess{k}",
                 "start_min": start, "end_min": start if cafe else start + rng.randint(10, 40),
                 "rate_per_hour": rng.choice([3000, 4500, 6000, 9000]),
                 "cafe_piasters": rng.choice([1500, 2500, 4000]) * rng.randint(1, 3) if cafe else 0, "day": day}
            pending_intents.append((a["action_id"], json.dumps(a)))
            r = run.send(a)
            if r and r.get("ok"):
                run.seq_of[a["action_id"]] = r.get("seq")
                pending_acks.append((a["action_id"],))
            if len(pending_intents) >= 5000:
                flush_intents()
            st["commands"] += 1

        def cursor():
            return int(psql("SELECT last_seq FROM cursor_ WHERE device_id = 'dev-1'"))

        def acked():  # drain progress on the device: its acknowledged high mark (duplicates count as progress)
            return run.send({"op": "state"})["acked_seq"]

        def sync():
            r = run.send({"op": "sync"})
            if r and r.get("results"):
                st["dups"] += sum(1 for x in r["results"] if x["result"] == "duplicate")
            return r

        # Seven days offline at the OQ16 bound (scaled).
        toxi.apply("down")
        per_day = round((SC25_SESSIONS_PER_DAY + SC25_CAFE_PER_DAY) * scale)
        t0 = time.time()
        for day in range(1, SC25_DAYS + 1):
            run.day = day
            for _ in range(per_day):
                sell(day)
        flush_intents()
        st["generate_seconds"] = round(time.time() - t0, 1)
        toxi.clear()
        backlog = st["commands"]
        slow_window = rng.randrange(SC25_WINDOWS - 1)
        for w in range(SC25_WINDOWS):
            last = w == SC25_WINDOWS - 1
            before, acked_before, t1 = cursor(), acked(), time.time()
            if w == slow_window:
                toxi.apply("bandwidth_3k")  # a slow uplink for this whole window
            syncs, batches = 0, []
            if last:  # the final window drains everything
                for _ in range(backlog // 5 + 100):
                    r = sync()
                    syncs += 1
                    if r and r.get("ok") and r.get("pending") == 0:
                        break
            else:
                budget = rng.randint(max(2, backlog // 50 // 12), max(3, backlog // 50 // 6))  # 8-17 % of the backlog
                for n in range(budget):
                    r = sync()
                    syncs += 1
                    batches.append(r.get("batch") if r else None)
                    if n % 10 == 9:
                        sell(SC25_DAYS + 1)  # the cashier keeps selling during the drain
                cut = rng.choice(SC25_CUTS)
                toxi.clear()
                toxi.apply(cut)
                sync()  # the window ends in the middle of this batch
                toxi.clear()
            toxi.clear()
            after = cursor()
            st["windows"].append({"window": w, "slow": w == slow_window, "cut": None if last else cut,
                                  "syncs": syncs, "cursor_before": before, "cursor_after": after,
                                  "acked_before": acked_before, "acked_after": acked(),
                                  "seconds": round(time.time() - t1, 1), "batch_sizes_seen": sorted(
                                      {b for b in batches if b})})
            if not last:
                toxi.apply("down")  # offline until the next shift change; the cashier keeps selling
                for _ in range(max(1, backlog // 200)):
                    sell(SC25_DAYS + 1)
                toxi.clear()
        st["final_cursor"] = cursor()
        flush_intents()
    return script


def sc25_extra(run, dump):
    """R23 every online window advances the server cursor (none makes zero progress or starts over) and the last
    one drains everything; duplicates stay within one batch per cut."""
    v, st = [], run.sc25
    for w in st["windows"]:  # progress = the device's acknowledged mark moved (a window after a lost reply may only
        # collect "duplicate" acks, which moves the device and not the server cursor)
        if w["acked_after"] <= w["acked_before"]:
            v.append(("R23", f"window {w['window']} ({'slow uplink' if w['slow'] else 'normal'}) made no progress: "
                             f"device acked {w['acked_before']} -> {w['acked_after']}, cursor {w['cursor_before']} -> "
                             f"{w['cursor_after']}"))
    if st["final_cursor"] != st["commands"]:
        v.append(("R23", f"final cursor {st['final_cursor']} != {st['commands']} commands"))
    if st["dups"] > (SC25_WINDOWS - 1) * 50:
        v.append(("R23", f"{st['dups']} duplicate results: more than one batch per cut was re-sent"))
    st["exercised"] = any(w["slow"] for w in st["windows"]) and len(st["windows"]) == SC25_WINDOWS
    return v, frozenset()


def sc25_run(seed, scale_name, toxi, mutant=None, label=None, verbose=False):
    run = Run(seed, mutant, verbose=verbose, store="sqlite3mc", cipher="chacha20", fault=False,
              label=label or f"sc25-{scale_name}", net=Net(toxi, "none"), client_env=dict(RETENTION_ENV))
    run.script, run.extra = sc25_script(SC25_SCALES[scale_name]), sc25_extra
    t0 = time.time()
    r = run.go()
    r["sc25"] = {**run.sc25, "seconds": round(time.time() - t0, 1)}
    return r


def sc25(scales=("tenth", "full"), mutant_budget=6):
    t0 = time.time()
    summary = {"harness_commit": git_state(), "started": time.strftime("%Y-%m-%d %H:%M:%S"),
               "load": "OQ16 bound, derived from capacity, not measured", "cells": [], "mutants": {}}
    print(f"phase 3 SC-25a (7-day backlog, cut windows), commit {summary['harness_commit']}", flush=True)
    toxi = Toxi(RUNS)
    ok = True
    try:
        for sc in scales:
            t1 = time.time()
            bad, exercised, runs = [], 0, []
            for s in range(1, SC25_SEEDS[sc] + 1):
                r = sc25_run(s, sc, toxi)
                exercised += bool(r["sc25"].get("exercised"))
                w = r["sc25"]["windows"]
                runs.append({"seed": s, "commands": r["sc25"]["commands"], "seconds": r["sc25"]["seconds"],
                             "generate_s": r["sc25"]["generate_seconds"], "dups": r["sc25"]["dups"],
                             "windows": [{"acked": x["acked_after"] - x["acked_before"],
                                          "cursor": x["cursor_after"] - x["cursor_before"], "s": x["seconds"],
                                          "slow": x["slow"], "cut": x["cut"], "batches": x["batch_sizes_seen"]}
                                         for x in w]})
                if r["violations"]:
                    bad.append({"seed": s, "violations": r["violations"][:3]})
                print(f"    {sc} seed {s}: {r['sc25']['commands']} commands, {r['sc25']['seconds']} s "
                      f"(generate {r['sc25']['generate_seconds']} s), acked per window "
                      f"{[x['acked_after'] - x['acked_before'] for x in w]}, "
                      f"violations {r['violations'][:2]}", flush=True)
            n = SC25_SEEDS[sc]
            res = "FAIL" if bad else ("PASS" if exercised == n else f"NOT ASSESSED ({n - exercised} runs not exercised)")
            ok &= res == "PASS"
            summary["cells"].append({"cell": sc, "runs": n, "exercised": exercised, "violating_runs": len(bad),
                                     "first_bad": bad[:3], "per_run": runs, "seconds": round(time.time() - t1, 1),
                                     "result": res})
            print(f"  {sc:6s} exercised {exercised}/{n}  violating {len(bad)}  {res}", flush=True)
        for mu in SC25_MUTANTS:
            t1 = time.time()
            caught = None
            for s in range(1, mutant_budget + 1):
                r = sc25_run(s, "tenth", toxi, mutant=mu, label=f"sc25-mutant-{mu}")
                if r["violations"]:
                    caught = (s, r["violations"][0])
                    break
            summary["mutants"][mu] = {"caught": bool(caught), "runs_to_catch": s if caught else None,
                                      "first_violation": caught[1] if caught else None,
                                      "seconds": round(time.time() - t1, 1)}
            ok &= bool(caught)
            print(f"  mutant {mu:14s} {'CAUGHT' if caught else 'SURVIVED'} after {s} runs: {caught[1] if caught else '-'}",
                  flush=True)
    finally:
        toxi.stop()
    summary["gate"] = "PASS" if ok else "FAIL"
    summary["seconds_total"] = round(time.time() - t0, 1)
    with open(os.path.join(RUNS, "sc25-summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    print(f"SC-25a: {summary['gate']}  (total {summary['seconds_total']} s)")
    return ok


# --- Phase 3, SC-25b: the N5 offline lease runs out mid-shift (mechanics, injected clocks) -------------------------
# Founder rule (2026-10-17, sync note OQ3): (1) the cashier and the owner are warned 24 hours before the lease (G =
# 7 days on the base plan) ends; (2) at expiry open sessions can still be closed and paid; (3) no new session and no
# new sale until the device reaches the server; (4) local data stays readable and exportable, and the whole backlog
# is accepted on reconnect. The lease is counted on server time plus the device's monotonic counter, never the wall
# clock. The driver moves both clocks (device monotonic, server) by the same amount; the wall clock is moved alone
# in b_wall_clock_back.
SC25B_CELLS = ["a_expiry_mid_shift", "b_wall_clock_back", "c_warning_boundary"]
SC25B_MUTANTS = ["wall_clock_lease", "expiry_blocks_close", "no_warning", "reject_after_expiry", "no_heartbeat"]
SC25B_PRICES = {"std": 6000, "vip": 9000, "cafe": 1500, "round_piasters": 1}
LEASE_G, LEASE_W = 7 * 86400, 86400


def sc25b_script(cell):
    def script(run):
        toxi = run.net.toxi
        n = [0]
        st = run.sc25b = {"cell": cell, "checks": [], "export": None, "after_reconnect": None}
        tiers = {}

        def advance(seconds):  # time passes for the device (monotonic) and the server alike
            run.send({"op": "advance_mono", "seconds": seconds})
            post_json(f"/test/clock?advance={seconds}", {})

        def owner_view():
            d = json.loads(urllib.request.urlopen(SERVER_URL + "/dump", timeout=60).read())
            return (d.get("lease_status") or [{}])[0]

        def look(label, elapsed):
            """What the device and the server say now, against the model (elapsed since the last contact)."""
            r = run.send({"op": "stats"})
            dev = (r or {}).get("lease", {})
            own = owner_view()
            want = "expired" if elapsed >= LEASE_G else ("warning" if elapsed >= LEASE_G - LEASE_W else "ok")
            st["checks"].append({"at": label, "elapsed_s": elapsed, "want": want, "device": dev.get("status"),
                                 "owner_warning": own.get("owner_warning"), "owner_expired": own.get("expired")})
            return want

        def start(tier="std"):
            sid = f"s{run.seed}-sess{n[0]}"
            n[0] += 1
            r = run.send({"op": "start_session", "session_id": sid, "start_min": 0, "tier": tier})
            tiers[sid] = tier
            return sid, r

        def close(sid, end=45):
            aid = f"s{run.seed}-a{sid.rsplit('sess', 1)[1]}"
            a = {"op": "close_session", "action_id": aid, "session_id": sid, "start_min": 0, "end_min": end,
                 "cafe_n": 1, "expected_piasters": None}
            r = run.send(a)
            if r and r.get("ok"):
                p_ = SC25B_PRICES
                total = (end * p_[tiers[sid]] + 30 * p_["round_piasters"]) // (60 * p_["round_piasters"]) \
                    * p_["round_piasters"] + p_["cafe"]
                a["expected_piasters"] = total
                run.intent.execute("INSERT INTO actions VALUES (?,?)", (aid, json.dumps(a)))
                run.intent.execute("INSERT INTO acks VALUES (?)", (aid,))
                run.seq_of[aid] = r.get("seq")
            return r

        post_json("/config", {"prices": SC25B_PRICES})
        run.send({"op": "pull_config"})  # contact: the lease starts now (server time T0, device monotonic m0)
        s1, _ = start()
        s2, _ = start("vip")
        s0, _ = start()
        close(s0)
        run.send({"op": "sync"})  # contact again: the lease restarts here
        toxi.apply("down")  # the internet goes; the shift goes on
        elapsed = 0
        if cell == "c_warning_boundary":
            for step in (LEASE_G - LEASE_W - 60, 120):  # one minute before the warning, one minute after
                advance(step)
                elapsed += step
                look(f"{elapsed / 3600:.2f} h", elapsed)
        else:
            for step, label in ((5 * 86400, "day 5"), (86400 + 22 * 3600, "6 d 22 h"), (3 * 3600, "7 d 1 h")):
                if cell == "b_wall_clock_back" and label == "6 d 22 h":
                    run.send({"op": "set_wall_offset", "seconds": -3 * 86400})  # someone sets the Windows clock back
                advance(step)
                elapsed += step
                want = look(label, elapsed)
                if want == "expired":  # rule 2, 3, 4 at expiry
                    st["new_session_after_expiry"] = start()[1]
                    st["sell_after_expiry"] = run.send({"op": "sell_items", "action_id": f"s{run.seed}-x1", "n": 1})
                    st["close_after_expiry"] = [close(s1, 120), close(s2, 150)]
                    st["export"] = run.send({"op": "export"})
                elif want == "ok":
                    st["sell_before_expiry"] = run.send({"op": "sell_items", "action_id": f"s{run.seed}-y{elapsed}",
                                                         "n": 1})
                    if st["sell_before_expiry"] and st["sell_before_expiry"].get("ok"):
                        a = {"op": "sell_items", "action_id": f"s{run.seed}-y{elapsed}", "start_min": 0, "end_min": 0,
                             "expected_piasters": 1500}
                        run.intent.execute("INSERT INTO actions VALUES (?,?)", (a["action_id"], json.dumps(a)))
                        run.intent.execute("INSERT INTO acks VALUES (?)", (a["action_id"],))
        toxi.clear()  # back online: the backlog goes up and the lease is renewed
        for _ in range(10):
            r = run.send({"op": "sync"})
            if r and r.get("ok") and r.get("pending") == 0:
                break
        st["after_reconnect"] = {"sync": r, "new_session": start()[1], "lease": (r or {}).get("lease")}
        if st["after_reconnect"]["new_session"] and st["after_reconnect"]["new_session"].get("ok"):
            close(f"s{run.seed}-sess{n[0] - 1}")
        for _ in range(5):
            r = run.send({"op": "sync"})
            if r and r.get("ok") and r.get("pending") == 0:
                break
    return script


def sc25b_extra(run, dump):
    """R24 warnings (device and owner) exactly in the last 24 h; R25 no new session or sale after expiry, allowed
    before; R26 open sessions closed and paid after expiry (and on the server: I1); R27 data exportable after
    expiry; R28 after reconnect the backlog is accepted and the lease renewed; R29 a wall-clock change moves
    nothing and reaches the owner."""
    v, st = [], run.sc25b
    for c in st["checks"]:
        if c["device"] != c["want"]:
            v.append(("R24", f"{c['at']}: device lease {c['device']}, model {c['want']}"))
        if bool(c["owner_warning"]) != (c["want"] in ("warning", "expired")):
            v.append(("R24", f"{c['at']}: owner warning {c['owner_warning']}, model {c['want']}"))
    if st["cell"] != "c_warning_boundary":
        for key in ("new_session_after_expiry", "sell_after_expiry"):
            r = st.get(key)
            if not r or r.get("ok") or r.get("error") != "lease_expired":
                v.append(("R25", f"{key}: {r}"))
        r = st.get("sell_before_expiry")
        if not r or not r.get("ok"):
            v.append(("R25", f"a sale before expiry was refused: {r}"))
        for r in st.get("close_after_expiry", []):
            if not r or not r.get("ok"):
                v.append(("R26", f"an open session could not be closed and paid after expiry: {r}"))
        e = st.get("export") or {}
        if not e.get("ok") or not e.get("bills"):
            v.append(("R27", f"export after expiry: {e}"))
    ar = st.get("after_reconnect") or {}
    if not (ar.get("new_session") or {}).get("ok"):
        v.append(("R28", f"after reconnect a new session was refused: {ar.get('new_session')}"))
    le = ar.get("lease") or {}
    if le.get("status") != "ok" or le.get("remaining_s", 0) < LEASE_G - 60:
        v.append(("R28", f"after reconnect the lease was not renewed in full: {le}"))
    if st["cell"] == "b_wall_clock_back":
        if not any(e["kind"] == "wall_clock_moved" and e["owner_alert"] for e in dump.get("device_events", [])):
            v.append(("R29", "the wall-clock change did not reach the owner"))
    st["exercised"] = len(st["checks"]) >= 2
    return v, frozenset()


def sc25b_run(seed, cell, toxi, mutant=None, label=None, verbose=False):
    run = Run(seed, mutant, verbose=verbose, store="sqlite3mc", cipher="chacha20", fault=False,
              label=label or f"sc25b-{cell}", net=Net(toxi, "none"), client_env={**RETENTION_ENV, "LEASE": "1"},
              server_env={"LEASE_G_S": str(LEASE_G), "LEASE_WARN_S": str(LEASE_W)})
    run.script, run.extra = sc25b_script(cell), sc25b_extra
    r = run.go()
    r["sc25b"] = run.sc25b
    return r


def sc25b(seeds=20, mutant_budget=12):
    t0 = time.time()
    summary = {"harness_commit": git_state(), "started": time.strftime("%Y-%m-%d %H:%M:%S"),
               "lease": {"G_s": LEASE_G, "warn_s": LEASE_W}, "cells": [], "mutants": {}}
    print(f"phase 3 SC-25b (N5 lease expiry, injected clocks), commit {summary['harness_commit']}", flush=True)
    toxi = Toxi(RUNS)
    ok = True
    try:
        for cell in SC25B_CELLS:
            t1 = time.time()
            bad, exercised = [], 0
            for s in range(1, seeds + 1):
                r = sc25b_run(s, cell, toxi)
                exercised += bool(r["sc25b"].get("exercised"))
                if r["violations"]:
                    bad.append({"seed": s, "violations": r["violations"][:3]})
            res = "FAIL" if bad else ("PASS" if exercised == seeds else f"NOT ASSESSED ({seeds - exercised})")
            ok &= res == "PASS"
            summary["cells"].append({"cell": cell, "runs": seeds, "exercised": exercised, "violating_runs": len(bad),
                                     "first_bad": bad[:3], "seconds": round(time.time() - t1, 1), "result": res})
            print(f"  {cell:20s} exercised {exercised}/{seeds}  violating {len(bad)}  {res}", flush=True)
        for mu in SC25B_MUTANTS:
            t1 = time.time()
            caught = None
            for k in range(mutant_budget):
                s, cell = k // len(SC25B_CELLS) + 1, SC25B_CELLS[k % len(SC25B_CELLS)]
                r = sc25b_run(s, cell, toxi, mutant=mu, label=f"sc25b-mutant-{mu}")
                if r["violations"]:
                    caught = (s, cell, r["violations"][0])
                    break
            summary["mutants"][mu] = {"caught": bool(caught), "runs_to_catch": k + 1 if caught else None,
                                      "seed_cell": caught[:2] if caught else None,
                                      "first_violation": caught[2] if caught else None,
                                      "seconds": round(time.time() - t1, 1)}
            ok &= bool(caught)
            print(f"  mutant {mu:20s} {'CAUGHT' if caught else 'SURVIVED'} after {k + 1} runs: "
                  f"{caught[2] if caught else '-'}", flush=True)
    finally:
        toxi.stop()
    summary["gate"] = "PASS" if ok else "FAIL"
    summary["seconds_total"] = round(time.time() - t0, 1)
    with open(os.path.join(RUNS, "sc25b-summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    print(f"SC-25b: {summary['gate']}  (total {summary['seconds_total']} s)")
    return ok


if __name__ == "__main__":
    if sys.argv[1] == "selftest":
        sys.exit(0 if selftest() else 1)
    if sys.argv[1] == "phase1":
        sys.exit(0 if phase1() else 1)
    if sys.argv[1] == "sc19":  # sc19 [seeds_per_cell]
        sys.exit(0 if sc19(*(int(x) for x in sys.argv[2:3])) else 1)
    if sys.argv[1] == "sc20":  # sc20 [seeds_per_cell]
        sys.exit(0 if sc20(*(int(x) for x in sys.argv[2:3])) else 1)
    if sys.argv[1] == "sc25b":  # sc25b [seeds_per_cell]
        sys.exit(0 if sc25b(*(int(x) for x in sys.argv[2:3])) else 1)
    if sys.argv[1] == "replay25b":  # replay25b <seed> <cell> [mutant]
        t = Toxi(RUNS)
        try:
            r = sc25b_run(int(sys.argv[2]), sys.argv[3], t, mutant=sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] else None,
                          label="replay25b", verbose=True)
            print(json.dumps({k: r.get(k) for k in ("actions", "acked", "server_sales", "fired", "sc25b", "violations")},
                             indent=1, default=str))
        finally:
            t.stop()
    if sys.argv[1] == "sc25":  # sc25 [tenth|full|both]
        which = sys.argv[2] if len(sys.argv) > 2 else "both"
        sys.exit(0 if sc25(("tenth", "full") if which == "both" else (which,)) else 1)
    if sys.argv[1] == "replay25":  # replay25 <seed> <tenth|full> [mutant]
        t = Toxi(RUNS)
        try:
            r = sc25_run(int(sys.argv[2]), sys.argv[3], t, mutant=sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] else None,
                         label="replay25")
            print(json.dumps({k: r.get(k) for k in ("actions", "acked", "server_sales", "fired", "sc25", "violations")},
                             indent=1, default=str))
        finally:
            t.stop()
    if sys.argv[1] == "sc23":  # sc23 [seeds_per_cell]
        sys.exit(0 if sc23(*(int(x) for x in sys.argv[2:3])) else 1)
    if sys.argv[1] == "replay23":  # replay23 <seed> <cell> [mutant]
        r = sc23_run(int(sys.argv[2]), sys.argv[3], mutant=sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] else None,
                     label="replay23", verbose=True)
        print(json.dumps({k: r.get(k) for k in ("actions", "acked", "server_sales", "fired", "sc23", "violations")}, indent=1))
    if sys.argv[1] == "sc22":  # sc22 [seeds_per_cell]
        sys.exit(0 if sc22(*(int(x) for x in sys.argv[2:3])) else 1)
    if sys.argv[1] == "replay22":  # replay22 <seed> <cell> [mutant]
        r = sc22_run(int(sys.argv[2]), sys.argv[3], mutant=sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] else None,
                     label="replay22", verbose=True)
        print(json.dumps({k: r[k] for k in ("actions", "acked", "server_sales", "fired", "sc22", "violations")}, indent=1))
    if sys.argv[1] == "sc21":  # sc21 [seeds_per_cell]
        sys.exit(0 if sc21(*(int(x) for x in sys.argv[2:3])) else 1)
    if sys.argv[1] == "replay21":  # replay21 <seed> <cell> [mutant]
        r = sc21_run(int(sys.argv[2]), sys.argv[3], mutant=sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] else None,
                     label="replay21", verbose=True)
        print(json.dumps({k: r[k] for k in ("actions", "acked", "server_sales", "fired", "sc21", "violations")}, indent=1))
    if sys.argv[1] == "sc20real":  # sc20real [seeds] - inside unshare -r -m
        sys.exit(0 if sc20_real(*(int(x) for x in sys.argv[2:3])) else 1)
    if sys.argv[1] == "replay20":  # replay20 <seed> <cell> [mutant]
        r = sc20_run(int(sys.argv[2]), sys.argv[3], mutant=sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] else None,
                     label="replay20", verbose=True)
        print(json.dumps({k: r[k] for k in ("actions", "acked", "server_sales", "fired", "sc20", "violations")}, indent=1))
    if sys.argv[1] == "replay19":  # replay19 <seed> <cell> [mutant]
        r = sc19_run(int(sys.argv[2]), sys.argv[3], mutant=sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] else None,
                     label="replay19", verbose=True)
        print(json.dumps({k: r[k] for k in ("actions", "acked", "server_sales", "restores", "reconcile_events",
                                            "violations")}, indent=1))
    if sys.argv[1] == "phase2":  # phase2 [seeds_per_cell] [campaign_runs]
        sys.exit(0 if phase2(*(int(x) for x in sys.argv[2:4])) else 1)
    if sys.argv[1] == "ts09":
        t = Toxi(RUNS)
        try:
            print(json.dumps(ts09(t), indent=1))
        finally:
            t.stop()
    if sys.argv[1] == "replay2":  # replay2 <seed> <cell|random> [mutant]
        t = Toxi(RUNS)
        try:
            s, cell = int(sys.argv[2]), sys.argv[3]
            r = p2run(s, cell, "replay2", t, mutant=sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] else None,
                      fault=phase2_proc_fault(s) if cell == "random" else False, verbose=True).go()
            print(json.dumps({k: r[k] for k in ("fault", "fired", "actions", "acked", "server_sales", "net", "violations")}, indent=1))
        finally:
            t.stop()
    if sys.argv[1] == "replay1":  # replay1 <seed> <cipher> <point> [mutant]
        s, cipher, point = int(sys.argv[2]), sys.argv[3], sys.argv[4]
        r = Run(s, sys.argv[5] if len(sys.argv) > 5 else None, verbose=True, store="sqlite3mc", cipher=cipher,
                fault=phase1_fault(s, point), label="replay1").go()
        print(json.dumps({k: r[k] for k in ("fault", "fired", "actions", "acked", "server_sales", "violations")}, indent=1))
    if sys.argv[1] == "replay":
        r = Run(int(sys.argv[2]), sys.argv[3] if len(sys.argv) > 3 else None, verbose=True).go()
        print(json.dumps({k: r[k] for k in ("fault", "fired", "actions", "acked", "server_sales", "violations")}, indent=1))
