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


class Run:
    def __init__(self, seed, mutant, verbose=False):
        self.seed, self.mutant, self.verbose = seed, mutant, verbose
        self.rng = random.Random(seed)
        self.dir = os.path.join(RUNS, mutant or "correct", f"seed-{seed}")
        shutil.rmtree(self.dir, ignore_errors=True)
        os.makedirs(self.dir)
        self.db = os.path.join(self.dir, "client.db")
        self.intent = sqlite3.connect(os.path.join(self.dir, "intent.db"), isolation_level=None)
        self.intent.execute("CREATE TABLE actions (action_id TEXT PRIMARY KEY, body TEXT)")
        self.intent.execute("CREATE TABLE acks (action_id TEXT PRIMARY KEY)")
        self.server = self.client = None
        self.fault, self.fired = self.pick_fault(), []
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
        return e

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
        return {"op": "sale", "action_id": f"s{self.seed}-a{i}", "session_id": f"s{self.seed}-sess{i}",
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
        c = sqlite3.connect(self.db)
        integrity = c.execute("PRAGMA integrity_check").fetchone()[0]
        client = {"bills": [r[0] for r in c.execute("SELECT action_id FROM bills")]}
        c.close()
        intent = [json.loads(b) for (b,) in self.intent.execute("SELECT body FROM actions")]
        acked = [a for (a,) in self.intent.execute("SELECT action_id FROM acks")]
        violations = oracle.check(intent, acked, client, dump, quiesced, integrity)
        result = {"seed": self.seed, "mutant": self.mutant, "fault": self.fault, "fired": self.fired,
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


if __name__ == "__main__":
    if sys.argv[1] == "selftest":
        sys.exit(0 if selftest() else 1)
    if sys.argv[1] == "replay":
        r = Run(int(sys.argv[2]), sys.argv[3] if len(sys.argv) > 3 else None, verbose=True).go()
        print(json.dumps({k: r[k] for k in ("fault", "fired", "actions", "acked", "server_sales", "violations")}, indent=1))
