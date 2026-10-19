# S21 (tier E): sample the HIBP range API to (a) measure reply size and padding, (b) read response headers
# (ETag, cache-control), (c) estimate the full corpus size = mean reply bytes x 16^5 prefixes.
# Uses only synthetic hex prefixes; no password is sent. Python 3 stdlib only. Run: python3 -I s21-hibp-range-sample.py
import urllib.request, random, time, statistics, sys, json
random.seed(20261019)
prefixes = ["%05X" % random.randrange(16**5) for _ in range(24)]
rows = []
hdr_sample = None
def get(p, pad):
    req = urllib.request.Request("https://api.pwnedpasswords.com/range/" + p,
        headers={"User-Agent": "kodeebo-research-s21", **({"Add-Padding": "true"} if pad else {})})
    t = time.perf_counter()
    with urllib.request.urlopen(req, timeout=20) as r:
        body = r.read(); dt = time.perf_counter() - t
        return r.status, dict(r.headers), body, dt
for p in prefixes:
    st, h, b, dt = get(p, False)
    lines = b.decode().strip().splitlines()
    rows.append((p, st, len(b), len(lines), dt))
    hdr_sample = hdr_sample or h
pad_rows = []
for p in prefixes[:6]:
    st, h, b, dt = get(p, True)
    lines = b.decode().strip().splitlines()
    zero = sum(1 for l in lines if l.endswith(":0"))
    pad_rows.append((p, st, len(b), len(lines), zero, dt))
sizes = [r[2] for r in rows]; cnts = [r[3] for r in rows]
mean = statistics.mean(sizes)
print("unpadded samples:", len(rows), "status set:", sorted({r[1] for r in rows}))
print("bytes per reply: mean %.0f min %d max %d; lines mean %.1f min %d max %d" % (mean, min(sizes), max(sizes), statistics.mean(cnts), min(cnts), max(cnts)))
print("estimated full corpus (mean bytes x 16^5): %.1f GB (decimal)" % (mean * 16**5 / 1e9))
print("latency s: median %.3f max %.3f" % (statistics.median(r[4] for r in rows), max(r[4] for r in rows)))
print("padded samples (prefix, status, bytes, lines, zero-count lines, s):")
for r in pad_rows: print("  ", r)
print("response headers of first unpadded reply:")
for k, v in sorted(hdr_sample.items()): print("  %s: %s" % (k, v))
