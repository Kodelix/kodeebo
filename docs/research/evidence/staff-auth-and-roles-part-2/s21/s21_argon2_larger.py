# S21 - follow-up to S20: S20 stopped at the first Argon2 error (threads=2 is refused by this OpenSSL build: thread pool 0).
# EVIDENCE: tier E, LINUX dev machine, not a Windows PC. Run: python3 -I s21_argon2_larger.py
import os, statistics, subprocess, time
os.sched_setaffinity(0, {0})
PW = "A7k2Qz"; SALT = bytes(range(16)).hex()
def run(args):
    t0 = time.perf_counter(); r = subprocess.run(args, capture_output=True, text=True); return time.perf_counter() - t0, r
def stat(args):
    ts = []
    for _ in range(5):
        t, r = run(args)
        if r.returncode: return None, r.stderr.strip()[:160]
        ts.append(t)
    return (min(ts), statistics.median(ts)), ""
base, _ = stat(["openssl", "kdf", "-keylen", "32", "-kdfopt", "pass:x", "-kdfopt", "hexsalt:" + SALT, "-kdfopt", "iter:1", "PBKDF2"])
print("process-start baseline (PBKDF2 iter=1 via the same CLI): min %.3f s median %.3f s" % base)
print("%-62s %8s %9s" % ("Argon2id (OpenSSL 3.6.5 CLI, single core, threads=1)", "min s", "median s"))
for m, t, p in ((19456, 2, 1), (65536, 3, 4), (65536, 3, 1), (131072, 2, 1), (131072, 3, 1), (262144, 1, 1), (262144, 2, 1), (524288, 1, 1)):
    v, err = stat(["openssl", "kdf", "-keylen", "32", "-kdfopt", "pass:" + PW, "-kdfopt", "hexsalt:" + SALT, "-kdfopt", f"iter:{t}",
                   "-kdfopt", f"memcost:{m}", "-kdfopt", f"lanes:{p}", "-kdfopt", "threads:1", "ARGON2ID"])
    print("m=%7d KiB (%4d MiB) t=%d p=%d%s" % (m, m // 1024, t, p, ("  -> %.3f %.3f" % v) if v else "  ERROR " + err))
