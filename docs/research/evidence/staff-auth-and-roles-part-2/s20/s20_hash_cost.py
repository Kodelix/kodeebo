# S20 - hash cost and keyspace arithmetic for the offline cashier PIN.
# EVIDENCE: tier E. Run on a LINUX dev machine (not a 4 GB Windows PC): the timings are a lower-bound proxy only.
# Run: python3 -I s20_hash_cost.py   (no third-party modules, no network, no download)
import hashlib, math, os, statistics, subprocess, sys, time

os.sched_setaffinity(0, {0})          # one core, to mimic a single-threaded verify call
PW = b"A7k2Qz"                        # a made-up 6 char test PIN, not a real secret
SALT = bytes(range(16))
REPEAT = 5

def timeit(fn):
    ts = []
    for _ in range(REPEAT):
        t0 = time.perf_counter(); fn(); ts.append(time.perf_counter() - t0)
    return min(ts), statistics.median(ts)

rows = []
for it in (100_000, 210_000, 600_000):
    mn, md = timeit(lambda it=it: hashlib.pbkdf2_hmac("sha256", PW, SALT, it, 32))
    rows.append((f"PBKDF2-HMAC-SHA256 iter={it}", "~0 MiB", mn, md))
for logn, r, p in ((14, 8, 1), (15, 8, 1), (16, 8, 1), (17, 8, 1)):
    n = 1 << logn
    mem = 128 * n * r * p
    mn, md = timeit(lambda n=n, r=r, p=p, mem=mem: hashlib.scrypt(PW, salt=SALT, n=n, r=r, p=p, maxmem=mem * 2 + (1 << 20), dklen=32))
    rows.append((f"scrypt N=2^{logn} r={r} p={p}", f"{mem // (1 << 20)} MiB", mn, md))

# Argon2id through the OpenSSL 3.6.5 command line (OpenSSL provides ARGON2ID if the build has it)
def argon(m, t, p, threads):
    cmd = ["openssl", "kdf", "-keylen", "32", "-kdfopt", "pass:" + PW.decode(), "-kdfopt", "hexsalt:" + SALT.hex(),
           "-kdfopt", f"iter:{t}", "-kdfopt", f"memcost:{m}", "-kdfopt", f"lanes:{p}", "-kdfopt", f"threads:{threads}", "ARGON2ID"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip()[:200])
for (m, t, p, th) in ((7168, 5, 1, 1), (19456, 2, 1, 1), (47104, 1, 1, 1), (65536, 3, 4, 1), (65536, 3, 4, 2), (131072, 2, 1, 1), (262144, 1, 1, 1)):
    try:
        mn, md = timeit(lambda m=m, t=t, p=p, th=th: argon(m, t, p, th))
        rows.append((f"Argon2id m={m} KiB t={t} p={p} threads={th} (openssl CLI, incl. process start)", f"{m // 1024} MiB", mn, md))
    except Exception as e:
        rows.append((f"Argon2id m={m} t={t} p={p} threads={th}", "n/a", float("nan"), float("nan")))
        print("ARGON2 ERROR:", e, file=sys.stderr)
        break

print("machine: python", sys.version.split()[0], "| cpus visible", os.cpu_count(), "| pinned to 1 core for python rows")
print(f"{'function':80s} {'memory':>9s} {'min s':>8s} {'median s':>9s}")
for name, mem, mn, md in rows:
    print(f"{name:80s} {mem:>9s} {mn:8.3f} {md:9.3f}")

print()
print("KEYSPACE (uniformly random characters; real PINs chosen by people are weaker)")
print(f"{'alphabet':28s} {'len':>3s} {'combinations':>16s} {'bits':>6s}")
alph = {"digits (10)": 10, "lower+digits (36)": 36, "mixed case+digits (62)": 62}
for name, a in alph.items():
    for L in (4, 5, 6, 8, 10):
        print(f"{name:28s} {L:3d} {a ** L:16,d} {L * math.log2(a):6.1f}")

print()
print("EXHAUSTIVE OFFLINE SEARCH if the verifier is copied: seconds per guess x combinations / parallel guessers; this Linux core, NOT a Windows PC, NOT a GPU")
ref = {r[0]: r[2] for r in rows}
for key in ("PBKDF2-HMAC-SHA256 iter=600000", "scrypt N=2^15 r=8 p=1"):
    for k, v in ref.items():
        if k.startswith(key) and v == v:
            per = v
            print(f"-- using {k}: {per:.3f} s/guess/core")
            for name, a in alph.items():
                for L in (4, 6, 8):
                    full = a ** L * per
                    for cores in (1, 16):
                        s = full / cores / 2   # expected time = half the space
                        print(f"   {name:24s} len {L}: expected {s:14,.0f} s = {s / 86400:12,.2f} days on {cores:2d} cores")
