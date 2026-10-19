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


def tunnel():
    pidf = os.path.join(RUNS, "p4-tunnel.pid")
    if os.path.exists(pidf):
        try:
            os.kill(int(open(pidf).read()), 15)
        except (OSError, ValueError):
            pass
    sh("tunnel", "18471")


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
        lines = ["@echo off"] + ([f"rmdir /s /q {self.vdir} 2>nul"] if first else []) + [f"mkdir {self.vdir} 2>nul", f"mkdir {self.vdir}\\tmp 2>nul",
                 f"set SQLITE_TMPDIR={self.vdir}\\tmp", f"set TMP={self.vdir}\\tmp", f"set TEMP={self.vdir}\\tmp"]
        lines += [f"set {k}={e[k]}" for k in keep if e.get(k)]
        lines += [f"{WDIR}\\py\\python.exe -u {WDIR}\\client.py {self.vdir}\\client.db {VM_URL} 2>>{self.vdir}\\client.log"]
        cmd = os.path.join(self.dir, "run.cmd")
        with open(cmd, "w", newline="\r\n") as f:  # test key only (random per run), on the test VM, reverted after
            f.write("\n".join(lines) + "\n")
        sh("put", cmd, f"C:/Users/cashier/p4/run-{self.seed}.cmd")
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


def s104(cuts=30, nmi=10):
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
    summary = {"harness_commit": git_state(), "started": time.strftime("%Y-%m-%d %H:%M:%S"), "runs": []}
    print(f"phase 4 S104 (power-off and OS crash on Windows), commit {summary['harness_commit']}", flush=True)
    # half of each kind at a held failpoint (deterministic: inside the transaction, the send, the ack write), the rest
    # at a seeded moment after a seeded action
    pts = [p for p in driver.CLIENT_POINTS] + ["client:mid_mark"]
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


if __name__ == "__main__":
    if sys.argv[1] == "s104":
        s104(int(sys.argv[2]), int(sys.argv[3]))
