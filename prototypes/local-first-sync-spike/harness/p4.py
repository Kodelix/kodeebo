# PROTOTYPE - NOT FOR PRODUCTION
# Phase 4 (sync note 9.1): the same client, store and oracle as phases 0-3, with the client on the shared Windows 10
# VM (4 GB, disk throttled to 100 IOPS + 80 MiB/s) and the server + PostgreSQL on this host (127.0.0.1 only, reached
# from the VM through an SSH reverse tunnel opened by harness/p4.sh). The VM is reached with the desktop spike's key
# by path only (p4.sh); this file never reads it.
#   s104 <cuts> <nmi>   S104: hard power-offs (virsh destroy) and OS crashes (NMI -> bugcheck) at seeded moments while
#                       the client sells and syncs; after the reboot the client restarts, drains, and the phase 0
#                       oracle (I1-I10) checks the server against every sale the client acknowledged before the cut
import json
import os
import random
import shutil
import subprocess
import sys
import threading
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import driver  # noqa: E402
from driver import Run, RUNS, git_state  # noqa: E402

P4 = os.path.join(HERE, "p4.sh")
V = ["virsh", "-c", "qemu:///system"]
DOM = "kodeebo-win10"
WDIR = r"C:\Users\cashier\p4"
VM_URL = "http://127.0.0.1:18471"  # the VM end of the reverse tunnel


def sh(*args, timeout=600):
    return subprocess.run(["bash", P4, *args], capture_output=True, text=True, timeout=timeout).stdout


def vm_state():
    return subprocess.run(V + ["domstate", DOM], capture_output=True, text=True).stdout.strip()


def ssh_argv():
    """The ssh command line p4.sh uses (key and known_hosts by path only), for a piped client process."""
    return [x for x in sh("argv", timeout=30).split("\n") if x]


def wait_boot(timeout=1800):
    t0 = time.time()
    while time.time() - t0 < timeout:
        if "up" in sh("cs", "echo up", timeout=30):
            return time.time() - t0
        time.sleep(5)
    raise RuntimeError("VM did not come back")


def tunnel(tries=10):
    """(Re)open the reverse tunnel and check it end to end from the VM (S104 run 1, seed 15: a tunnel whose ssh
    process was alive carried nothing after the reboot, so the drain never reached the server)."""
    pidf = os.path.join(RUNS, "p4-tunnel.pid")
    for _ in range(tries):
        if os.path.exists(pidf):
            try:
                os.kill(int(open(pidf).read()), 15)
            except (OSError, ValueError):
                pass
        time.sleep(2)
        sh("tunnel", "18471")
        # the forward must be bound on the VM side (the host server may not be running yet)
        if "LISTENING" in sh("cs", "netstat -an -p TCP | findstr 127.0.0.1:18471", timeout=30):
            return True
        time.sleep(5)
    raise RuntimeError("reverse tunnel did not carry traffic after retries")


class WinRun(Run):
    """A phase 0 run whose client lives on the VM; `cut` = ("power" | "nmi", k, delay): the cut fires `delay`
    seconds after action k is sent, so it lands inside a sale, a sync, a replay or a marker write."""

    def __init__(self, seed, cut, actions=60, **kw):
        super().__init__(seed, None, store="sqlite3mc", cipher="chacha20", fault=[], label=kw.pop("label", "p4-s104"),
                         client_env={"RETENTION": "1"}, **kw)
        self.cut, self.actions, self.cut_fired = cut, actions, None
        self.vdir = f"{WDIR}\\runs\\seed-{seed}"
        self.fetched = False
        self.boot_s = None

    def start_client(self, first=False):
        e = self.env("client", first)
        e.update(self.client_env)
        if first and len(self.cut) == 4:  # a held point: (kind, None, point, hit)
            e.update(FP=f"{self.cut[2]}:{self.cut[3]}", FP_HOLD="1")
        keep = ["STORE", "CIPHER", "SPIKE_DB_KEY", "RETENTION", "MUTANT", "FP", "FP_HOLD"]
        clear = first and not getattr(self, "keep_dir", False)
        lines = ["@echo off"] + ([f"rmdir /s /q {self.vdir} 2>nul"] if clear else []) + [f"mkdir {self.vdir} 2>nul", f"mkdir {self.vdir}\\tmp 2>nul",
                 f"set SQLITE_TMPDIR={self.vdir}\\tmp", f"set TMP={self.vdir}\\tmp", f"set TEMP={self.vdir}\\tmp"]
        keep += [k for k in self.client_env if k not in keep]  # TIMING, ENDDAY, REALCLOCK, SCHEMA_VERSION, MACHINE_ID...
        lines += [f"set {k}={e[k]}" for k in keep if e.get(k)]
        lines += [f"{WDIR}\\py\\python.exe -u {WDIR}\\client.py {self.vdir}\\client.db {VM_URL} 2>>{self.vdir}\\client.log"]
        cmd = os.path.join(self.dir, "run.cmd")
        with open(cmd, "w", newline="\r\n") as f:  # test key only (random per run), on the test VM, reverted after
            f.write("\n".join(lines) + "\n")
        for _ in range(12):  # S104 run 1 seed 1002: right after a slow boot the copy failed silently once
            sh("put", cmd, f"C:/Users/cashier/p4/run-{self.seed}.cmd")
            if "YES" in sh("cs", f"if exist {WDIR}\\run-{self.seed}.cmd (echo YES) else (echo NO)", timeout=30):
                break
            time.sleep(5)
        self.client = subprocess.Popen(ssh_argv() + [f"{WDIR}\\run-{self.seed}.cmd"], stdin=subprocess.PIPE,
                                       stdout=subprocess.PIPE, text=True, bufsize=1,
                                       stderr=open(os.path.join(self.dir, "ssh.log"), "a"))

    def fire(self):
        kind = self.cut[0]
        t = time.time()
        if kind == "power":
            subprocess.run(V + ["destroy", DOM], capture_output=True)
        else:
            subprocess.run(V + ["inject-nmi", DOM], capture_output=True)
        if len(self.cut) == 4:
            self.cut_fired = {"kind": kind, "held_at": self.cut[2], "hit": self.cut[3]}
            self.fired.append(f"{kind} cut while held at {self.cut[2]} (hit {self.cut[3]})")
        else:
            self.cut_fired = {"kind": kind, "after_action": self.cut[1], "delay_s": self.cut[2]}
            self.fired.append(f"{kind} cut {self.cut[2]:.2f} s after action {self.cut[1]} was sent")

    def recover(self):
        """After the cut: bring the VM back (a power-off needs a start; an NMI bugcheck reboots by itself)."""
        if self.cut[0] == "power":
            subprocess.run(V + ["start", DOM], capture_output=True)
        else:
            time.sleep(20)
            if vm_state() == "shut off":
                subprocess.run(V + ["start", DOM], capture_output=True)
        try:
            self.boot_s = round(wait_boot(900), 1)
        except RuntimeError:
            subprocess.run(V + ["screenshot", DOM, os.path.join(self.dir, "vm-screen.ppm")], capture_output=True)
            raise
        subprocess.run(V + ["blkdeviotune", DOM, "sda", "--live", "--total-iops-sec", "100",
                            "--total-bytes-sec", "83886080"], capture_output=True)
        tunnel()
        self.log(f"VM back after {self.boot_s} s")

    def ensure_alive(self):
        if not self.server_down and self.server.poll() is not None:
            self.fired.append(f"server died rc={self.server.returncode}")
            self.start_server()
        if self.client.poll() is not None:
            if self.cut_fired and self.boot_s is None:
                self.recover()
            else:
                self.fired.append(f"client died rc={self.client.returncode}")
            self.start_client()

    def scan(self, when):
        if when == "after clean exit" and not self.fetched:  # fetch the store files from the VM, then scan here
            for n in ("client.db", "client.db-journal", "client.db.hwm", "client.db.events.jsonl"):
                sh("get", f"{self.vdir}\\{n}".replace("\\", "/"), os.path.join(self.dir, n))
            self.fetched = True
            # exercised: a hot journal at restart makes the client copy the store aside first (P1-F3), leaving the
            # (emptied) client.db.recovery folder behind
            self.hot_journal = "HOT" in sh("cs", f"if exist {self.vdir}\\client.db.recovery (echo HOT) else (echo NONE)")
            super().scan(when)

    def go(self):
        self.script = self.loop
        self.hot_journal = None
        r = super().go()
        r["hot_journal_at_restart"] = self.hot_journal
        r["boot_s"] = self.boot_s
        return r

    def watch_hold(self):
        """Held point: poll the VM for the client's hold file, then cut (the client sleeps inside the failpoint)."""
        while not self.stop_watch.is_set() and not self.cut_fired:
            if "HELD" in sh("cs", f"if exist {self.vdir}\\client.db.hold (echo HELD) else (echo NO)", timeout=30):
                self.fire()
                return
            time.sleep(1)

    def loop(self, run):
        timer = None
        self.stop_watch = threading.Event()
        if len(self.cut) == 4:
            timer = threading.Thread(target=self.watch_hold)
            timer.start()
        i = 0
        while i < self.actions:
            if i == self.cut[1]:
                timer = threading.Timer(self.cut[2], self.fire)
                timer.start()
            self.sale(i)
            i += 1
            if self.rng.random() < 0.5:
                self.log("sync", self.send({"op": "sync"}))
            if self.rng.random() < 0.2:
                self.log("replay", self.send({"op": "replay", "k": self.rng.randint(1, 3)}))
        self.stop_watch.set()
        if timer:
            timer.join()
        if self.boot_s is None:  # the cut came after the last action: recover anyway
            self.send({"op": "stats"})
        for j in range(self.actions, self.actions + 5):  # sales after the recovery
            self.sale(j)


def prep_crash():
    assert vm_state() == "running", "bring the VM up with harness/p4.sh up + install first"
    sh("ad", "reg add HKLM\\SYSTEM\\CurrentControlSet\\Control\\CrashControl /v NMICrashDump /t REG_DWORD /d 1 /f")
    sh("ad", "reg add HKLM\\SYSTEM\\CurrentControlSet\\Control\\CrashControl /v CrashDumpEnabled /t REG_DWORD /d 0 /f")
    sh("ad", "reg add HKLM\\SYSTEM\\CurrentControlSet\\Control\\CrashControl /v AutoReboot /t REG_DWORD /d 1 /f")
    # P4-F1: without these, two unexpected shutdowns within 2 min of boot stop Windows at the Recovery screen
    sh("ad", "bcdedit /set {current} recoveryenabled No")
    sh("ad", "bcdedit /set {current} bootstatuspolicy IgnoreAllFailures")
    sh("ad", "shutdown /r /t 0")  # NMICrashDump and the boot settings take effect at the next boot
    time.sleep(40)
    wait_boot()
    subprocess.run(V + ["blkdeviotune", DOM, "sda", "--live", "--total-iops-sec", "100",
                        "--total-bytes-sec", "83886080"], capture_output=True)
    tunnel()


def s104_one(kind, seed, point, hit):
    """Replay one held-point run (for example S104 run 1 seed 15: power, client:after_mark, hit 2)."""
    prep_crash()
    r = WinRun(seed, (kind, None, point, int(hit)), label="p4-s104-replay").go()
    print(json.dumps({k: r[k] for k in ("seed", "fired", "acked", "server_sales", "hot_journal_at_restart", "boot_s")}
                     | {"violations": r["violations"][:5]}))


def s104(cuts=30, nmi=10):
    prep_crash()
    summary = {"harness_commit": git_state(), "started": time.strftime("%Y-%m-%d %H:%M:%S"), "runs": []}
    print(f"phase 4 S104 (power-off and OS crash on Windows), commit {summary['harness_commit']}", flush=True)
    # half of each kind at a held failpoint (deterministic: inside the transaction, the send, the ack write), the rest
    # at a seeded moment after a seeded action
    pts = [p for p in driver.CLIENT_POINTS if p != "client:after_business_commit"] + ["client:mid_mark"]
    # (after_business_commit exists only in the separate_outbox_txn mutant: never reached by the correct client)
    plan = [("power", s) for s in range(1, cuts + 1)] + [("nmi", s) for s in range(1001, 1001 + nmi)]
    bad = 0
    for kind, seed in plan:
        rr = random.Random(f"p4|{seed}")
        n_kind = cuts if kind == "power" else nmi
        idx = seed - (1 if kind == "power" else 1001)
        if idx < n_kind // 2:
            at = (None, pts[idx % len(pts)], 1 + (idx // len(pts)) % 3)
        else:
            at = (rr.randint(3, 55), round(rr.uniform(0.0, 0.8), 2))
        t0 = time.time()
        r = WinRun(seed, (kind, *at)).go()
        bad += bool(r["violations"])
        row = {"seed": seed, "kind": kind, "cut": list(at), "hot_journal_at_restart": r["hot_journal_at_restart"], "boot_s": r["boot_s"],  "fired": r["fired"], "acked": r["acked"],
               "server_sales": r["server_sales"], "violations": r["violations"][:3], "seconds": round(time.time() - t0)}
        summary["runs"].append(row)
        where = f"held at {at[1]} #{at[2]}" if at[0] is None else f"after a{at[0]:02d}+{at[1]:.2f}s"
        print(f"  {kind:5s} seed {seed:5d} {where:42s} fired {bool(r['fired'])} acked {r['acked']:3d} server {r['server_sales']:3d} "
              f"hot journal {r['hot_journal_at_restart']} boot {r['boot_s']} s violations {len(r['violations'])} "
              f"{r['violations'][:1]} ({row['seconds']} s)", flush=True)
    summary["hot_journal_runs"] = sum(1 for x in summary["runs"] if x["hot_journal_at_restart"])
    summary["result"] = "PASS" if not bad else "FAIL"
    with open(os.path.join(RUNS, "p4-s104-summary.json"), "w") as f:
        json.dump(summary, f, indent=1, default=str)
    print(f"S104: {summary['result']}  ({len(plan)} runs, violating {bad}, a hot journal at restart in "
          f"{summary['hot_journal_runs']})")


def reboot_cold():
    """Clean restart for a cold cache: unthrottled boot, 60 s for the post-logon burst, then the throttle again."""
    subprocess.run(V + ["blkdeviotune", DOM, "sda", "--live", "--total-iops-sec", "0", "--total-bytes-sec", "0"],
                   capture_output=True)
    sh("ad", "shutdown /r /t 0")
    time.sleep(40)
    b = wait_boot()
    time.sleep(60)
    subprocess.run(V + ["blkdeviotune", DOM, "sda", "--live", "--total-iops-sec", "100",
                        "--total-bytes-sec", "83886080"], capture_output=True)
    return round(b + 40, 1)


SC24_SIZES = (30000, 100000, 300000)


def sc24(reps=3):
    """SC-24: start-up check time on stores of 30k / 100k / 300k money commands (OQ16 x OQ29, derived from capacity),
    cold cache (a reboot before every measurement), throttled disk."""
    assert vm_state() == "running"
    summary = {"harness_commit": git_state(), "started": time.strftime("%Y-%m-%d %H:%M:%S"), "rows": []}
    print(f"phase 4 SC-24 (start-up check time, cold), commit {summary['harness_commit']}", flush=True)
    sh("put", os.path.join(HERE, "guest", "sc24probe.py"), "C:/Users/cashier/p4/sc24probe.py")
    keys = {}
    for n in SC24_SIZES:
        src = os.path.join(RUNS, "sc24", f"n{n}")
        keys[n] = open(os.path.join(src, "key.txt")).read().strip()
        sh("cs", f"mkdir {WDIR}\\sc24\\n{n}")
        for f in ("client.db", "client.db.hwm"):
            sh("put", os.path.join(src, f), f"C:/Users/cashier/p4/sc24/n{n}/{f}", timeout=3600)
    for rep in range(1, reps + 1):
        for mode in ("ready", "integrity", "quick"):
            for n in SC24_SIZES:
                boot = reboot_cold()
                out = sh("cs", f"{WDIR}\\py\\python.exe {WDIR}\\sc24probe.py {mode} {WDIR}\\sc24\\n{n}\\client.db "
                               f"{keys[n]}", timeout=3600)
                try:
                    r = json.loads([ln for ln in out.splitlines() if ln.startswith("{")][-1])
                except (IndexError, ValueError):
                    r = {"error": out[-300:]}
                row = {"rep": rep, "mode": mode, "commands": n, "boot_s": boot, **{k: v for k, v in r.items() if k != "reply"},
                       "ready_reply_ok": (r.get("reply") or {}).get("ok") if mode == "ready" else None}
                summary["rows"].append(row)
                print(f"  rep {rep} {mode:9s} {n:6d} commands  {r.get('db_bytes', 0) / 1e6:7.1f} MB  "
                      f"{r.get('ms')} ms  {r.get('result', '')}{row['ready_reply_ok'] if mode == 'ready' else ''}", flush=True)
    with open(os.path.join(RUNS, "p4-sc24-summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    print("SC-24: done (measured; judged against perf-budgets.md in the README)")


def pct(xs, q_):
    xs = sorted(xs)
    return xs[min(len(xs) - 1, int(round(q_ * (len(xs) - 1))))] if xs else None


class TimedRun(WinRun):
    """Counter-action timings (perf-budgets.md): the client with TIMING=1 on the throttled VM, server reachable."""

    def __init__(self, seed, iterations, **kw):
        super().__init__(seed, ("none", None, 0.0), label=kw.pop("label", "p4-timings"), **kw)
        self.client_env.update(TIMING="1", ENDDAY="1")
        self.iterations = iterations
        self.samples = {}

    def go(self):
        self.script = self.timed
        self.hot_journal = None
        return Run.go(self)

    def op(self, msg, record=True):
        t0 = time.perf_counter()
        r = self.send(msg)
        rt = (time.perf_counter() - t0) * 1000
        if record and r is not None:
            self.samples.setdefault(msg["op"], []).append({"rt": round(rt, 2), **(r.get("ms") or {}), "ok": r.get("ok")})
        return r

    def timed(self, run):
        driver.post_json("/config", {"prices": {"std": 6000, "vip": 9000, "cafe": 1500, "round_piasters": 25}})
        self.op({"op": "pull_config"}, record=False)
        for k in range(self.iterations + 10):
            rec = k >= 10  # 10 warm-up iterations, not recorded
            sid = f"t{k}"
            self.op({"op": "start_session", "session_id": sid, "start_min": 0, "tier": "std"}, rec)
            self.op({"op": "change_tier", "session_id": sid, "at_min": 10, "tier": "vip"}, rec)
            r = self.op({"op": "close_session", "action_id": f"c{k}", "session_id": sid, "end_min": 30, "cafe_n": 2}, rec)
            r = self.op({"op": "sell_items", "action_id": f"i{k}", "n": 2}, rec)
            if k % 50 == 49:
                self.op({"op": "sync"}, rec)
            if k % 100 == 99:
                self.op({"op": "end_day"}, rec)


def timings(iterations=200):
    assert vm_state() == "running"
    tunnel()
    t0 = time.time()
    run = TimedRun(1, iterations)
    r = run.go()
    # priced sales (close_session, sell_items) are not in the driver's intent log, so I8 is expected and skipped
    out = {"harness_commit": git_state(), "iterations": iterations,
           "violations": [v for v in r["violations"] if v[0] != "I8"][:5], "ops": {}}
    print(f"phase 4 counter timings, commit {out['harness_commit']}, {iterations} iterations, throttled VM", flush=True)
    for op_, xs in run.samples.items():
        row = {"n": len(xs), "failed": sum(1 for x in xs if not x["ok"])}
        for f in ("total", "txn", "commit", "marker", "rt"):
            v = [x[f] for x in xs if f in x]
            if v:
                row[f] = {"p50": pct(v, 0.5), "p95": pct(v, 0.95), "p99": pct(v, 0.99), "max": max(v)}
        out["ops"][op_] = row
        print(f"  {op_:14s} n {row['n']:4d} failed {row['failed']}  " + "  ".join(
            f"{f} p50/p95/max {row[f]['p50']}/{row[f]['p95']}/{row[f]['max']}" for f in ("total", "commit", "marker", "rt")
            if f in row), flush=True)
    out["seconds"] = round(time.time() - t0)
    with open(os.path.join(RUNS, "p4-timings-summary.json"), "w") as f:
        json.dump({**out, "samples": run.samples}, f, indent=1)
    print(f"timings: violations {len(out['violations'])} ({out['seconds']} s)")


class DrainRun(WinRun):
    """SC-26: the client drains a pre-built 35,000-command backlog (store copied to the VM) while sc26reader.py, a
    second process, times the counter's reads."""

    def __init__(self, key, reader_s, **kw):
        super().__init__(26, ("none", None, 0.0), label="p4-sc26", **kw)
        self.key, self.keep_dir, self.reader_s = key, True, reader_s
        self.vdir = f"{WDIR}\\sc26"
        self.drain = {}

    def go(self):
        self.script = self.drain_script
        self.hot_journal = None
        return Run.go(self)

    def reader(self, label, seconds):
        out = sh("cs", f"{WDIR}\\py\\python.exe {WDIR}\\sc26reader.py {self.vdir}\\client.db {self.key} {seconds} "
                       f"{self.vdir}\\reader-{label}.json", timeout=seconds + 600)
        sh("get", f"C:/Users/cashier/p4/sc26/reader-{label}.json", os.path.join(self.dir, f"reader-{label}.json"))
        return out

    def drain_script(self, run):
        self.send({"op": "stats"})  # the client is up; nothing is sent yet
        self.drain["baseline"] = self.reader("baseline", 120)  # reads with no sync running
        th = threading.Thread(target=lambda: self.drain.__setitem__("during", self.reader("drain", self.reader_s)))
        t0 = time.time()
        th.start()
        n = 0
        while True:
            r = self.send({"op": "sync"})
            n += 1
            if r and r.get("ok") and r.get("pending") == 0:
                break
        self.drain.update(syncs=n, drain_s=round(time.time() - t0, 1))
        th.join()


def sc26(reader_s=900):
    assert vm_state() == "running"
    tunnel()
    src = os.path.join(RUNS, "sc26", "backlog35k")
    key = open(os.path.join(src, "key.txt")).read().strip()
    sh("put", os.path.join(HERE, "guest", "sc26reader.py"), "C:/Users/cashier/p4/sc26reader.py")
    sh("cs", f"mkdir {WDIR}\\sc26")
    for f in ("client.db", "client.db.hwm"):
        sh("put", os.path.join(src, f), f"C:/Users/cashier/p4/sc26/{f}", timeout=3600)
    run = DrainRun(key, reader_s)
    r = run.go()
    res = {"harness_commit": git_state(), "server_sales": r["server_sales"], **run.drain,
           "violations_except_I8": [v for v in r["violations"] if v[0] != "I8"][:5]}
    for label in ("baseline", "drain"):
        p_ = os.path.join(run.dir, f"reader-{label}.json")
        if os.path.exists(p_):
            d = json.load(open(p_))
            allv = [x for v in d["samples"].values() for x in v]
            res[label] = {"reads": len(allv), "errors": len(d["errors"]), "first_errors": d["errors"][:3],
                          "p50": pct(allv, 0.5), "p95": pct(allv, 0.95), "p99": pct(allv, 0.99),
                          "max": max(allv) if allv else None}
    with open(os.path.join(RUNS, "p4-sc26-summary.json"), "w") as f:
        json.dump(res, f, indent=1)
    print(json.dumps(res, indent=1))


def sc27(iterations=200):
    """SC-27: the counter-timings workload while Windows Defender scans: a full scan for the whole run plus a custom
    scan of the client's folder every 20 s (each opens the store, journal and marker files). Same oracle; latencies
    are compared with the plain `timings` run."""
    assert vm_state() == "running"
    tunnel()
    status = sh("ad", "powershell -NoProfile -Command \"Get-MpComputerStatus | Select-Object AMServiceEnabled,"
                      "RealTimeProtectionEnabled,AntivirusSignatureVersion | ConvertTo-Json\"")
    stop = threading.Event()
    scans = {"custom": 0, "full": None}

    def full():
        t = time.time()
        sh("ad", "powershell -NoProfile -Command \"Start-MpScan -ScanType FullScan\"", timeout=14400)
        scans["full"] = round(time.time() - t)

    def custom():
        while not stop.is_set():
            sh("ad", f"powershell -NoProfile -Command \"Start-MpScan -ScanType CustomScan -ScanPath {WDIR}\\runs\"",
               timeout=600)
            scans["custom"] += 1
            stop.wait(20)

    threads = [threading.Thread(target=full, daemon=True), threading.Thread(target=custom, daemon=True)]
    for t in threads:
        t.start()
    time.sleep(10)
    t0 = time.time()
    run = TimedRun(27, iterations, label="p4-sc27")
    r = run.go()
    stop.set()
    out = {"harness_commit": git_state(), "defender": status, "iterations": iterations, "scans": scans,
           "violations": [v for v in r["violations"] if v[0] != "I8"][:5], "ops": {}}
    for op_, xs in run.samples.items():
        row = {"n": len(xs), "failed": sum(1 for x in xs if not x["ok"])}
        for f in ("total", "commit", "marker", "rt"):
            v = [x[f] for x in xs if f in x]
            if v:
                row[f] = {"p50": pct(v, 0.5), "p95": pct(v, 0.95), "p99": pct(v, 0.99), "max": max(v)}
        out["ops"][op_] = row
    events = run.db + ".events.jsonl"
    out["client_events"] = open(events).read().splitlines()[:10] if os.path.exists(events) else []
    out["seconds"] = round(time.time() - t0)
    with open(os.path.join(RUNS, "p4-sc27-summary.json"), "w") as f:
        json.dump({**out, "samples": run.samples}, f, indent=1)
    print(json.dumps({k: v for k, v in out.items()}, indent=1))


def probe(mode="read"):
    out = sh("cs", f"{WDIR}\\py\\python.exe {WDIR}\\clockprobe.py {mode}", timeout=120)
    try:
        return json.loads([ln for ln in out.splitlines() if ln.startswith("{")][-1])
    except (IndexError, ValueError):
        return {"error": out[-300:]}


def wait_off(timeout=900):
    t0 = time.time()
    while time.time() - t0 < timeout:
        if vm_state() == "shut off":
            return True
        time.sleep(3)
    return False


TRANSITIONS = ("restart", "hybrid", "full", "poweroff", "hibernate")


def s30x(reps=10, off_s=30):
    """S301/S302 (+ S305's hibernate leg): every clock and boot marker across restart, Fast Startup shutdown
    (hybrid), full shutdown, hard power-off and hibernate; `off_s` seconds powered off each time."""
    assert vm_state() == "running"
    sh("put", os.path.join(HERE, "guest", "clockprobe.py"), "C:/Users/cashier/p4/clockprobe.py")
    setup = {"powercfg_a_before": sh("ad", "powercfg /a")}
    sh("ad", "powercfg /h on")
    sh("ad", "reg add \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Power\" /v HiberbootEnabled "
             "/t REG_DWORD /d 1 /f")
    setup["powercfg_a_after"] = sh("ad", "powercfg /a")
    summary = {"harness_commit": git_state(), "setup": setup, "rows": []}
    print(f"phase 4 S301/S302 clocks and boot markers, commit {summary['harness_commit']}", flush=True)
    for rep in range(1, reps + 1):
        for t in TRANSITIONS:
            before = probe("mark")
            time.sleep(5)
            if t == "restart":
                sh("ad", "shutdown /r /t 0")
                time.sleep(15)
                off = None
            else:
                if t == "poweroff":
                    subprocess.run(V + ["destroy", DOM], capture_output=True)
                else:
                    sh("ad", {"hybrid": "shutdown /s /hybrid /t 0", "full": "shutdown /s /full /t 0",
                              "hibernate": "shutdown /h"}[t])
                ok = wait_off()
                t_off = time.time()
                time.sleep(off_s)
                subprocess.run(V + ["start", DOM], capture_output=True)
                off = round(time.time() - t_off, 1) if ok else "did not power off"
            boot = round(wait_boot(), 1)
            time.sleep(20)
            after = probe("read")
            d = lambda k: round(after[k] - before[k], 3) if isinstance(after.get(k), (int, float)) and \
                isinstance(before.get(k), (int, float)) else None
            row = {"rep": rep, "transition": t, "off_s": off, "back_s": boot,
                   "wall_delta": d("wall"), "tick_delta": d("tick_s"), "qpc_delta": d("qpc_s"),
                   "unbiased_delta": d("unbiased_s"), "interrupt_delta": d("interrupt_s"),
                   "py_monotonic_delta": d("py_monotonic"),
                   "boot_from_tick_changed": after.get("boot_from_tick") != before.get("boot_from_tick"),
                   "boot_id_before_after": [before.get("boot_id"), after.get("boot_id")],
                   "volatile_marker_survived": after.get("volatile_marker") == before.get("volatile_marker_set"),
                   "boot_event_27_after": after.get("boot_event_27"), "before": before, "after": after}
            summary["rows"].append(row)
            print(f"  rep {rep:2d} {t:9s} off {off} s back {boot} s wall +{row['wall_delta']} tick +{row['tick_delta']} "
                  f"qpc +{row['qpc_delta']} unbiased +{row['unbiased_delta']} boot_from_tick changed "
                  f"{row['boot_from_tick_changed']} BootId {row['boot_id_before_after']} volatile survived {row['volatile_marker_survived']} "
                  f"event27 {(row['boot_event_27_after'] or {}).get('desc', '')[:70]}", flush=True)
    with open(os.path.join(RUNS, "p4-s30x-summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    print("S301/S302: done")


class ClockRun(WinRun):
    """TS-07b + S304: a session on the real clocks of the VM (REALCLOCK=1, CLOCKED=1), the Windows clock edited by an
    administrator while the app runs, while it is closed, or before a reboot."""

    def __init__(self, seed, case, shift_h, **kw):
        super().__init__(seed, ("none", None, 0.0), label=kw.pop("label", "p4-ts07b"), **kw)
        self.client_env.update(REALCLOCK="1", CLOCKED="1")
        self.case, self.shift_h, self.result = case, shift_h, {}

    def go(self):
        self.script = self.clock_script
        self.hot_journal = None
        return Run.go(self)

    def set_clock(self, hours):
        return sh("ad", f"powershell -NoProfile -Command \"Set-Date -Adjust ([TimeSpan]::FromHours({hours})) | Out-Null; "
                        f"(Get-Date).ToString('o')\"").strip()

    def clock_script(self, run):
        driver.post_json("/config", {"prices": {"std": 6000, "vip": 9000, "cafe": 1500, "round_piasters": 1}})
        self.send({"op": "pull_config"})
        self.send({"op": "tick"})
        sid = f"ts07b-{self.seed}"
        r0 = self.send({"op": "start_session", "session_id": sid, "tier": "std"})
        t0 = time.time()
        time.sleep(90)
        self.send({"op": "tick"})
        if self.case == "running":
            self.result["clock_after_edit"] = self.set_clock(self.shift_h)
            time.sleep(90)
            self.send({"op": "tick"})
        elif self.case == "closed":
            self.send({"op": "exit"})
            self.client.wait()
            self.result["clock_after_edit"] = self.set_clock(self.shift_h)
            time.sleep(90)
            self.start_client()
            self.send({"op": "tick"})
        elif self.case == "reboot":
            self.send({"op": "exit"})
            self.client.wait()
            self.result["clock_after_edit"] = self.set_clock(self.shift_h)
            self.cut_fired = {"kind": "reboot"}
            sh("ad", "shutdown /r /t 0")
            time.sleep(15)
            self.recover()
            self.start_client()
            self.send({"op": "tick"})
        real_s = time.time() - t0
        r = self.send({"op": "close_session", "action_id": f"c{self.seed}", "session_id": sid, "cafe_n": 0})
        while (self.send({"op": "sync"}) or {}).get("pending", 1) > 0:
            time.sleep(1)
        dump = json.loads(driver.urllib.request.urlopen(driver.SERVER_URL + "/dump", timeout=60).read())
        sale = [x for x in dump["ledger"] if x["action_id"] == f"c{self.seed}" and x["kind"] == "sale"]
        self.result["billed_minutes"] = sale[0]["amount_piasters"] / 100 if sale else None  # std 6000/h, step 1
        self.result.update(start=r0, close=r, real_elapsed_s=round(real_s, 1),
                           expected_minutes=int(real_s // 60), probe=probe("read"))
        self.result["restore"] = sh("ad", "powershell -NoProfile -Command \"w32tm /resync /force; (Get-Date).ToString('o')\"")
        self.result["restore_fallback"] = self.set_clock(-self.shift_h) if "error" in self.result["restore"].lower() \
            or "not" in self.result["restore"].lower() else None


def ts07b():
    assert vm_state() == "running"
    tunnel()
    sh("put", os.path.join(HERE, "guest", "clockprobe.py"), "C:/Users/cashier/p4/clockprobe.py")
    out = {"harness_commit": git_state(), "cases": []}
    print(f"phase 4 TS-07b + S304 (real clock edits), commit {out['harness_commit']}", flush=True)
    for seed, (case, h) in enumerate([("running", 1), ("running", -1), ("closed", 1), ("closed", -1),
                                      ("reboot", 1), ("reboot", -1)], start=701):
        run = ClockRun(seed, case, h)
        r = run.go()
        events = []
        ev = run.db + ".events.jsonl"
        if os.path.exists(ev):
            events = [json.loads(x) for x in open(ev).read().splitlines() if x.strip()]
        row = {"seed": seed, "case": case, "shift_h": h, **{k: v for k, v in run.result.items() if k != "probe"},
               "time_changed_event_visible_to_cashier": run.result.get("probe", {}).get("time_changed_event_1"),
               "events": [e.get("event") + (f" {e.get('move_s')}" if e.get("move_s") is not None else "") for e in events],
               "violations": [v for v in r["violations"] if v[0] != "I8"][:5]}
        out["cases"].append(row)
        print(f"  {case:8s} {h:+d} h: real {row.get('real_elapsed_s')} s, expected {row.get('expected_minutes')} min, "
              f"billed {row.get('billed_minutes')} min, events {row['events']}", flush=True)
    with open(os.path.join(RUNS, "p4-ts07b-summary.json"), "w") as f:
        json.dump(out, f, indent=1, default=str)
    print("TS-07b: done")


S303_UTC = ["2026-04-23T21:59:00Z", "2026-04-23T22:01:00Z", "2026-04-24T12:00:00Z", "2026-10-29T20:59:00Z",
            "2026-10-29T21:01:00Z", "2026-10-30T12:00:00Z", "2027-01-15T12:00:00Z"]


def s303():
    """S303: Egypt's UTC offset on this Windows build (Egypt Standard Time) against PostgreSQL's (Africa/Cairo)."""
    assert vm_state() == "running"
    ps = ("$tz=[TimeZoneInfo]::FindSystemTimeZoneById('Egypt Standard Time'); "
          + "; ".join(f"'{u} ' + $tz.GetUtcOffset([DateTimeOffset]::Parse('{u}')).TotalHours" for u in S303_UTC)
          + "; [Environment]::OSVersion.Version.ToString(); (Get-ItemProperty 'HKLM:\\SOFTWARE\\Microsoft\\Windows NT"
            "\\CurrentVersion').UBR")
    win = sh("cs", f'powershell -NoProfile -Command "{ps}"')
    rows = []
    for u in S303_UTC:
        w = next((ln.split()[1] for ln in win.splitlines() if ln.startswith(u)), None)
        pg = driver.psql(f"SELECT (('{u}'::timestamptz AT TIME ZONE 'Africa/Cairo') - ('{u}'::timestamptz AT TIME ZONE 'UTC'))")
        rows.append({"utc": u, "windows_offset_h": float(w) if w else None, "postgres_offset": pg})
    out = {"harness_commit": git_state(), "windows_build": win.splitlines()[-2:], "pg_version": driver.psql("SHOW server_version"),
           "pg_tzdata": "postgres:18.6 image", "rows": rows,
           "equal": all(r["windows_offset_h"] is not None and abs(r["windows_offset_h"] * 3600 - int(r["postgres_offset"].split(":")[0]) * 3600) < 1
                        for r in rows)}
    with open(os.path.join(RUNS, "p4-s303-summary.json"), "w") as f:
        json.dump(out, f, indent=1)
    print(json.dumps(out, indent=1))


class HeartbeatRun(TimedRun):
    """S309: the one-minute last-alive checkpoint (`tick`, a committed write) for `hours`, with a sale every 30 s;
    measures both and the bytes the client process wrote (Win32_Process.WriteTransferCount)."""

    def __init__(self, hours, tick_s=60, sale_s=30, **kw):
        super().__init__(309, 0, label="p4-s309", **kw)
        self.client_env.update(REALCLOCK="1", CLOCKED="1")
        self.hours, self.tick_s, self.sale_s = hours, tick_s, sale_s
        self.io = []

    def io_bytes(self):
        out = sh("cs", "powershell -NoProfile -Command \"Get-CimInstance Win32_Process -Filter \\\"Name='python.exe'\\\" | "
                       "Measure-Object -Property WriteTransferCount -Sum | ForEach-Object { $_.Sum }\"")
        try:
            return int(out.strip().splitlines()[-1])
        except (ValueError, IndexError):
            return None

    def timed(self, run):
        driver.post_json("/config", {"prices": {"std": 6000, "vip": 9000, "cafe": 1500, "round_piasters": 25}})
        self.op({"op": "pull_config"}, record=False)
        t_end = time.time() + self.hours * 3600
        next_tick, next_sale, k = time.time(), time.time(), 0
        self.io.append((0, self.io_bytes()))
        t0 = time.time()
        while time.time() < t_end:
            now = time.time()
            if now >= next_tick:
                self.op({"op": "tick"})
                next_tick += self.tick_s
            if now >= next_sale:
                r = self.op({"op": "sell_items", "action_id": f"h{k}", "n": 1})
                k += 1
                next_sale += self.sale_s
                if k % 20 == 0:
                    self.op({"op": "sync"})
            if k % 120 == 0 and k and (not self.io or self.io[-1][0] != k):
                self.io.append((round(time.time() - t0), self.io_bytes()))
            time.sleep(0.2)
        self.io.append((round(time.time() - t0), self.io_bytes()))


def s309(hours=8.0):
    assert vm_state() == "running"
    tunnel()
    run = HeartbeatRun(hours)
    r = run.go()
    out = {"harness_commit": git_state(), "hours": hours, "violations": [v for v in r["violations"] if v[0] != "I8"][:5],
           "io_bytes_series": run.io, "ops": {}}
    for op_, xs in run.samples.items():
        v = [x["total"] for x in xs if "total" in x]
        out["ops"][op_] = {"n": len(xs), "failed": sum(1 for x in xs if not x["ok"]),
                           "p50": pct(v, 0.5), "p95": pct(v, 0.95), "p99": pct(v, 0.99), "max": max(v) if v else None}
    with open(os.path.join(RUNS, "p4-s309-summary.json"), "w") as f:
        json.dump({**out, "samples": run.samples}, f, indent=1)
    print(json.dumps(out, indent=1))


class UpdateRun(WinRun):
    """SC-21b, sync half: version 1 queues sales, then version 2 starts (SCHEMA_VERSION=2: the local migration);
    optionally the power is cut while version 2 is held at a migration step. Afterwards the queued commands must
    reach the server byte-identical and deduplicate across versions (I2; resends of acknowledged commands come back
    'duplicate', never 'conflict')."""

    def __init__(self, seed, point, **kw):
        super().__init__(seed, ("power", None, point, 1) if point else ("none", None, 0.0), label="p4-sc21b", **kw)
        self.point, self.v2 = point, False
        self.extra_info = {}

    def start_client(self, first=False):
        if self.v2:
            self.client_env["SCHEMA_VERSION"] = "2"
        if self.v2 and self.point and not self.cut_fired:  # arm the hold on version 2's first start
            saved, self.cut = self.cut, self.cut
            e = self.client_env
            e.update(FP=f"{self.point}:1", FP_HOLD="1")
            super().start_client(first=False)
            e.pop("FP", None)
            e.pop("FP_HOLD", None)
            return
        super().start_client(first and not self.v2)

    def env(self, side, first):
        e = super().env(side, first)
        if side == "client" and not (self.v2 and self.point and not self.cut_fired):
            e.pop("FP", None)
            e.pop("FP_HOLD", None)
        return e

    def go(self):
        self.script = self.update_script
        self.hot_journal = None
        return Run.go(self)

    def update_script(self, run):
        for k in range(10):
            self.sale(k)
        self.send({"op": "sync"})
        for k in range(10, 20):
            self.sale(k)  # queued when the update arrives
        self.send({"op": "exit"})
        self.client.wait()
        self.v2 = True
        self.stop_watch = threading.Event()
        watcher = None
        if self.point:
            watcher = threading.Thread(target=self.watch_hold)
            watcher.start()
        self.start_client()
        r = self.send({"op": "schema"})  # held: no reply until the cut and the recovery (ensure_alive restarts v2)
        if watcher:
            watcher.join(timeout=900)
        self.extra_info["schema_after"] = self.send({"op": "schema"})
        self.extra_info["sync"] = self.send({"op": "sync"})
        self.extra_info["replay"] = self.send({"op": "replay", "k": 3})
        for k in range(20, 25):
            self.sale(k)


def sc21b():
    assert vm_state() == "running"
    prep_crash()
    out = {"harness_commit": git_state(), "cases": []}
    print(f"phase 4 SC-21b sync half (update with a queued outbox on Windows), commit {out['harness_commit']}", flush=True)
    for seed, point in enumerate([None, "migrate:before_copy", "migrate:after_copy", "migrate:mid_ddl",
                                  "migrate:after_commit", "migrate:before_marker", "migrate:before_cleanup"], start=211):
        run = UpdateRun(seed, point)
        r = run.go()
        replay = (run.extra_info.get("replay") or {}).get("results") or []
        row = {"seed": seed, "cut_at": point, "fired": r["fired"], "acked": r["acked"], "server_sales": r["server_sales"],
               "schema_after": run.extra_info.get("schema_after"),
               "replay_results": sorted({x.get("result") for x in replay}),
               "violations": [v for v in r["violations"] if v[0] != "I8"][:5]}
        out["cases"].append(row)
        print(f"  cut at {point or 'none':24s} fired {bool([f for f in r['fired'] if 'cut' in f])} acked {r['acked']} "
              f"server {r['server_sales']} schema {(row['schema_after'] or {}).get('user_version')} replay {row['replay_results']} "
              f"violations {len(row['violations'])} {row['violations'][:1]}", flush=True)
    with open(os.path.join(RUNS, "p4-sc21b-summary.json"), "w") as f:
        json.dump(out, f, indent=1, default=str)
    print("SC-21b sync half: " + ("PASS" if all(not c["violations"] for c in out["cases"]) else "FAIL"))


class RollbackRun(WinRun):
    """TS-01c (Windows half of TS-01): an administrator copies the store files, the cashier sells, the copy is put
    back. (a) the later sales were synced first: the server must see the reused sequence numbers; (b) they never
    reached the server: the known blind spot (OQ27), expected to go unseen by the server."""

    def __init__(self, seed, variant, while_running, **kw):
        super().__init__(seed, ("none", None, 0.0), label="p4-ts01c", **kw)
        self.client_env.update(MACHINE_ID="m1")
        self.variant, self.while_running, self.info = variant, while_running, {}

    def go(self):
        self.script = self.rb_script
        self.hot_journal = None
        return Run.go(self)

    def admin_copy(self, src_suffix, dst_suffix):
        files = " ".join(f"{self.vdir}\\client.db{x}" for x in ("", ".hwm"))
        cmds = [f"copy /Y {self.vdir}\\client.db{x}{src_suffix} {self.vdir}\\client.db{x}{dst_suffix}" for x in ("", ".hwm")]
        return sh("ad", " & ".join(cmds))

    def rb_script(self, run):
        for k in range(5):
            self.sale(k)
        self.send({"op": "sync"})
        if not self.while_running:
            self.send({"op": "exit"})
            self.client.wait()
        self.info["copy"] = self.admin_copy("", ".bak")
        if not self.while_running:
            self.start_client()
        for k in range(5, 10):
            self.sale(k)
        if self.variant == "a":
            self.info["sync_before_restore"] = self.send({"op": "sync"})
        self.send({"op": "exit"})
        self.client.wait()
        self.info["restore"] = self.admin_copy(".bak", "")
        sh("ad", f"del /Q {self.vdir}\\client.db-journal 2>nul")
        self.start_client()
        for k in range(10, 13):
            self.sale(k)
        self.info["sync_after_restore"] = self.send({"op": "sync"})
        dump = json.loads(driver.urllib.request.urlopen(driver.SERVER_URL + "/dump", timeout=60).read())
        self.info["server_view"] = {k: dump.get(k) for k in ("quarantine", "review_queue", "lost_seqs", "gaps")}


def ts01c():
    assert vm_state() == "running"
    tunnel()
    out = {"harness_commit": git_state(), "cases": []}
    print(f"phase 4 TS-01c (store copy restored on Windows), commit {out['harness_commit']}", flush=True)
    for seed, (variant, running) in enumerate([("a", False), ("b", False), ("a", True), ("b", True)], start=101):
        run = RollbackRun(seed, variant, running)
        r = run.go()
        sv = run.info.get("server_view", {})
        row = {"seed": seed, "variant": variant, "copied_while_running": running, "copy": run.info.get("copy"),
               "server_view": sv, "after_restore_sync": run.info.get("sync_after_restore"),
               "violations": [v for v in r["violations"] if v[0] != "I8"][:8]}
        out["cases"].append(row)
        print(f"  ({variant}) copy while running {running}: quarantine {sv.get('quarantine')} review {len(sv.get('review_queue') or [])} "
              f"lost {sv.get('lost_seqs')} gaps {sv.get('gaps')} violations {len(row['violations'])} {row['violations'][:2]}",
              flush=True)
    with open(os.path.join(RUNS, "p4-ts01c-summary.json"), "w") as f:
        json.dump(out, f, indent=1, default=str)
    print("TS-01c: done")


if __name__ == "__main__":
    if sys.argv[1] == "s104":
        s104(int(sys.argv[2]), int(sys.argv[3]))
    elif sys.argv[1] == "s104one":
        s104_one(sys.argv[2], int(sys.argv[3]), sys.argv[4], sys.argv[5])
    elif sys.argv[1] == "sc26":
        sc26(int(sys.argv[2]) if len(sys.argv) > 2 else 900)
    elif sys.argv[1] == "sc27":
        sc27(int(sys.argv[2]) if len(sys.argv) > 2 else 200)
    elif sys.argv[1] == "s30x":
        s30x(int(sys.argv[2]) if len(sys.argv) > 2 else 10)
    elif sys.argv[1] == "ts07b":
        ts07b()
    elif sys.argv[1] == "s303":
        s303()
    elif sys.argv[1] == "s309":
        s309(float(sys.argv[2]) if len(sys.argv) > 2 else 8.0)
    elif sys.argv[1] == "sc21b":
        sc21b()
    elif sys.argv[1] == "ts01c":
        ts01c()
    elif sys.argv[1] == "timings":
        timings(int(sys.argv[2]) if len(sys.argv) > 2 else 200)
    elif sys.argv[1] == "sc24":
        sc24(int(sys.argv[2]) if len(sys.argv) > 2 else 3)
