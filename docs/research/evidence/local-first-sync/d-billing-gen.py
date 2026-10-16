# d-billing-gen.py - generate deterministic billing test vectors and the Python reference result.
# Run: python3 -I d-billing-gen.py <out-dir>      (Python 3.14.7, seed fixed, no network)
# Reference algorithm A (a PROPOSAL used only to test cross-language determinism; rates/minimums come from vectors, not code):
#   total_ms   = sum(seg.elapsed_ms)
#   floor_ms   = max(total_ms, min_billable_minutes*60000)
#   unit_ms    = increment_minutes*60000
#   rounded_ms = ceil(floor_ms/unit_ms)*unit_ms (mode up) | floor(floor_ms/unit_ms + 1/2)*unit_ms (nearest) | floor(...)*unit_ms (down)
#   rounded_ms = max(rounded_ms, min_billable_minutes*60000)
#   extra_ms   = rounded_ms - total_ms  (may be negative in mode down/nearest; charged at the LAST segment's rate)
#   num        = sum(seg.elapsed_ms*seg.rate_pph) + extra_ms*last.rate_pph
#   amount     = floor((2*num + 3600000) / (2*3600000))  (round half up, integer piasters)
import json, random, sys, os
out = sys.argv[1]
rnd = random.Random(20261016)
modes = ["up", "nearest", "down"]
cases = []
def mk(i, segs, minm, inc, mode):
    return {"id": i, "segments": segs, "min_billable_minutes": minm, "increment_minutes": inc, "mode": mode}
i = 0
# edge cases
edge = [
  ([(0, 3000)], 0, 1, "up"), ([(1, 3000)], 15, 15, "up"), ([(3599999, 3000)], 0, 1, "nearest"),
  ([(3600000, 1)], 0, 1, "down"), ([(90*60000, 4500), (30*60000, 6000)], 10, 5, "up"),
  ([(59999, 2999)], 1, 1, "nearest"), ([(86400000, 100000)], 0, 1, "up"),
]
for segs, minm, inc, mode in edge:
    cases.append(mk(i, [{"elapsed_ms": a, "rate_pph": b} for a, b in segs], minm, inc, mode)); i += 1
for _ in range(5000):
    n = rnd.choice([1, 1, 1, 2, 3])
    segs = [{"elapsed_ms": rnd.randrange(0, 12*3600*1000), "rate_pph": rnd.choice([2500, 3000, 3500, 4500, 6000, 7777, 12345])} for _ in range(n)]
    cases.append(mk(i, segs, rnd.choice([0, 5, 10, 15, 30]), rnd.choice([1, 5, 10, 15, 30]), rnd.choice(modes))); i += 1
def amount(c):
    segs = c["segments"]; total = sum(s["elapsed_ms"] for s in segs)
    unit = c["increment_minutes"]*60000; floor_ms = max(total, c["min_billable_minutes"]*60000)
    if c["mode"] == "up": r = -(-floor_ms // unit) * unit
    elif c["mode"] == "down": r = (floor_ms // unit) * unit
    else: r = ((2*floor_ms + unit) // (2*unit)) * unit
    r = max(r, c["min_billable_minutes"]*60000)
    extra = r - total
    num = sum(s["elapsed_ms"]*s["rate_pph"] for s in segs) + extra*segs[-1]["rate_pph"]
    return (2*num + 3600000) // (2*3600000)
def amount_float(c):  # negative control: the float shortcut people write
    segs = c["segments"]; total = sum(s["elapsed_ms"] for s in segs)
    unit = c["increment_minutes"]*60000; floor_ms = max(total, c["min_billable_minutes"]*60000)
    import math
    if c["mode"] == "up": r = math.ceil(floor_ms/unit)*unit
    elif c["mode"] == "down": r = math.floor(floor_ms/unit)*unit
    else: r = round(floor_ms/unit)*unit   # Python banker's rounding
    r = max(r, c["min_billable_minutes"]*60000)
    h = sum(s["elapsed_ms"]/3600000*s["rate_pph"] for s in segs) + (r-total)/3600000*segs[-1]["rate_pph"]
    return round(h)
with open(os.path.join(out, "d-billing-vectors.json"), "w") as f: json.dump(cases, f)
with open(os.path.join(out, "d-billing-expected-python.txt"), "w") as f:
    for c in cases: f.write(f'{c["id"]},{amount(c)}\n')
diff = sum(1 for c in cases if amount(c) != amount_float(c))
print(f"cases={len(cases)} float_shortcut_disagreements_with_integer={diff}")
