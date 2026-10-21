#!/usr/bin/env python3
"""S50 (part 5): arithmetic of elapsed-time station pricing in integer piasters.

Tier E evidence for docs/research/catalogue-and-item-model.part-5.md.
Run: python3 -I s50_station_time_arithmetic.py > s50_station_time_arithmetic.output.txt
Standard library only. All numbers are ILLUSTRATIVE, not Kodeebo prices.
It shows what the arithmetic does; it does not test PostgreSQL, SQLite or the counter.
"""
from fractions import Fraction
import math


def half_up(x: Fraction) -> int:
    """Round a non-negative exact value to whole piasters, half up."""
    return int((x * 2 + 1) // 2)


def line(rate_per_hour: int, seconds: int) -> Fraction:
    """Exact charge in piasters (a rational) for seconds at an hourly rate."""
    return Fraction(rate_per_hour * seconds, 3600)


print("== case 1: rounding mode and float, one session line ==")
rate = 5400  # 54.00 EGP per hour = 1.5 piasters per second
for s in (1, 3, 5, 4033):
    ex = line(rate, s)
    print(f"rate={rate} s={s} exact={float(ex):.4f} half_up={half_up(ex)} "
          f"python_round_float={round(rate * s / 3600)} floor={math.floor(ex)} ceil={math.ceil(ex)}")
diff = {}
for r in (6000, 5400, 7000, 4500, 3000):
    n = 0
    for s in range(1, 86401):
        if round(r * s / 3600) != half_up(line(r, s)):
            n += 1
    diff[r] = n
print("seconds in 1..86400 where python round(float) != exact half_up, by hourly rate:", diff)

print("\n== case 2: rate boundary and pauses, round per segment vs once per line ==")
peak, off = 8000, 5000
segs = [(peak, 1230), (off, 1500)]
once = half_up(sum(line(r, s) for r, s in segs))
per_seg = sum(half_up(line(r, s)) for r, s in segs)
print(f"two segments {segs}: round once={once} sum of rounded segments={per_seg}")
cut_a = [(off, 1500)]
cut_b = [(off, 740), (off, 760)]  # same 1500 s, cut by a pause
print("same 1500 s at off-peak, uncut vs cut by a pause:")
print(f"  round once: {half_up(sum(line(r, s) for r, s in cut_a))} vs {half_up(sum(line(r, s) for r, s in cut_b))}")
print(f"  per piece : {sum(half_up(line(r, s)) for r, s in cut_a)} vs {sum(half_up(line(r, s)) for r, s in cut_b)}")

print("\n== case 3: blocks and minimum charge ==")
for elapsed in (100, 4033):
    blocks = math.ceil(elapsed / 900)
    charge = half_up(line(6000, blocks * 900))
    print(f"elapsed={elapsed}s blocks_of_15min={blocks} block_charge={charge} minimum=6000 -> {max(charge, 6000)}")

print("\n== case 4: rule priority, stackable or not, tie on priority ==")
base = Fraction(6000)
rules = {  # id: (priority, stackable, percent off)
    "R1": (10, True, 10),
    "R2": (10, False, 20),
}


def apply(order):
    v = base
    for rid in order:
        _, stack, pct = rules[rid]
        v = Fraction(half_up(v * (100 - pct) / 100))
        if not stack:
            break
    return int(v)


print("order R1,R2 (R1 stackable -10%, R2 non-stackable -20%):", apply(["R1", "R2"]))
print("order R2,R1 (same priority, other tie-break)           :", apply(["R2", "R1"]))

print("\n== case 5: extras per hour, one line per unit vs one line with quantity ==")
secs = 3300
per_unit = half_up(line(1000, secs))
print(f"headset 1000/h for {secs}s: one unit={per_unit}; two units as two rounded lines={per_unit * 2}; "
      f"two units as one line (qty x rate x time, round once)={half_up(2 * line(1000, secs))}")

print("\n== case 6: bundle with one included hour, session longer or shorter ==")
for elapsed in (4800, 3000):
    over = max(0, elapsed - 3600)
    print(f"elapsed={elapsed}s included=3600s overtime={over}s overtime_charge={half_up(line(6000, over))}")
