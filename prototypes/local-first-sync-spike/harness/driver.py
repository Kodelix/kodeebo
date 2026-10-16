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

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import oracle  # noqa: E402  (same folder; never imports SUT code)

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


class Run:
    def __init__(self, seed, mutant, verbose=False, store=None, cipher=None, fault=None, label=None):
        self.seed, self.mutant, self.verbose = seed, mutant, verbose
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
        e.update(PG_DSN=PG_DSN, ADDR=ADDR, RESET="1" if first else "0")
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
        self.client = subprocess.Popen([sys.executable, CLIENT_PY, self.db, SERVER_URL], env=self.env("client", first),
                                       stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1,
                                       stderr=open(os.path.join(self.dir, "client.log"), "a"))

    def ensure_alive(self):
        if self.server.poll() is not None:
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

    # --- the script ------------------------------------------------------------
    def new_action(self, i):
        start = self.rng.randint(0, 600)
        sess = f"{'CANARY-' if self.store else ''}s{self.seed}-sess{i}"  # canary: must never appear on disk in plaintext
        return {"op": "sale", "action_id": f"s{self.seed}-a{i}", "session_id": sess,
                "start_min": start, "end_min": start + self.rng.randint(1, 180),
                "rate_per_hour": self.rng.choice([3000, 4500, 6000, 9000, 12000]),
                "cafe_piasters": self.rng.choice([0, 1500, 2500, 4000, 7550])}

    def go(self):
        self.log(f"seed={self.seed} mutant={self.mutant or 'none'} fault={self.fault}")
        self.start_server(first=True)
        self.start_client(first=True)
        for i in range(ACTIONS_PER_RUN):
            a = self.new_action(i)
            self.intent.execute("INSERT INTO actions VALUES (?,?)", (a["action_id"], json.dumps(a)))  # before submit
            r = self.send(a)
            if r and r.get("ok"):
                self.intent.execute("INSERT INTO acks VALUES (?)", (a["action_id"],))
                self.log(f"sale {a['action_id']} acknowledged")
            else:
                self.log(f"sale {a['action_id']} no acknowledgement (client died)")
            if self.rng.random() < 0.5:
                self.log("sync", self.send({"op": "sync"}))
            if self.rng.random() < 0.2:
                self.log("replay", self.send({"op": "replay", "k": self.rng.randint(1, 3)}))
        # quiescence: faults are one-shot; restart anything dead and drain the outbox
        quiesced = False
        for _ in range(20):
            r = self.send({"op": "sync"})
            if r and r.get("ok") and r.get("pending") == 0:
                quiesced = True
                break
        self.send({"op": "exit"})
        self.client.wait()
        dump = json.loads(urllib.request.urlopen(SERVER_URL + "/dump", timeout=10).read())
        self.server.terminate()
        self.server.wait()
        self.scan("after clean exit")
        c = self.open_client_store()
        integrity = c.execute("PRAGMA integrity_check").fetchall()[0][0]
        client = {"bills": [r[0] for r in c.execute("SELECT action_id FROM bills").fetchall()]}
        c.close()
        intent = [json.loads(b) for (b,) in self.intent.execute("SELECT body FROM actions")]
        acked = [a for (a,) in self.intent.execute("SELECT action_id FROM acks")]
        violations = oracle.check(intent, acked, client, dump, quiesced, integrity)
        events = self.db + ".events.jsonl"
        if os.path.exists(events):  # no tamper in these runs, so any refusal is a store failure
            violations.append(("I9", f"client refused its store: {open(events).read()[:200]}"))
        violations += [("I10", leak) for leak in self.leaks]  # TS-04a: plaintext on disk
        result = {"seed": self.seed, "mutant": self.mutant, "store": self.store, "cipher": self.cipher,
                  "fault": self.fault, "fired": self.fired,
                  "actions": len(intent), "acked": len(acked), "server_sales": sum(1 for r in dump["ledger"] if r["kind"] == "sale"),
                  "violations": violations}
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


if __name__ == "__main__":
    if sys.argv[1] == "selftest":
        sys.exit(0 if selftest() else 1)
    if sys.argv[1] == "phase1":
        sys.exit(0 if phase1() else 1)
    if sys.argv[1] == "replay1":  # replay1 <seed> <cipher> <point> [mutant]
        s, cipher, point = int(sys.argv[2]), sys.argv[3], sys.argv[4]
        r = Run(s, sys.argv[5] if len(sys.argv) > 5 else None, verbose=True, store="sqlite3mc", cipher=cipher,
                fault=phase1_fault(s, point), label="replay1").go()
        print(json.dumps({k: r[k] for k in ("fault", "fired", "actions", "acked", "server_sales", "violations")}, indent=1))
    if sys.argv[1] == "replay":
        r = Run(int(sys.argv[2]), sys.argv[3] if len(sys.argv) > 3 else None, verbose=True).go()
        print(json.dumps({k: r[k] for k in ("fault", "fired", "actions", "acked", "server_sales", "violations")}, indent=1))
