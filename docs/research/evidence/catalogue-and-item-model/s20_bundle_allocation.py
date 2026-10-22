"""S20: allocate one combo price across child lines by largest remainder, integer piasters only.

Rule under test (research part 2, F219; ADR-0014 D4 allocation mode):
  weight_i = list_price_i * qty_i (piasters, >= 0)
  base_i   = P * weight_i // W          (W = sum of weights)
  rem_i    = P * weight_i %  W          (exact fractional part, as a numerator over W)
  the R = P - sum(base) leftover piasters go one each to the R largest rem_i;
  ties broken by larger weight, then by slot order (stable, input-independent key).
  W == 0 (every component free): equal weights.
Checks: sum exact; every share >= 0; |share - exact| < 1; a zero-weight component gets 0
when W > 0; result independent of input order; products stay below 2**63 for the stated bounds.
Deterministic: seeded RNG (seed 20), no clock.
"""
import random
from fractions import Fraction

LONG_MAX = 2**63 - 1

def allocate(price, comps):
    # comps: list of (slot_order, list_price, qty)
    if price < 0 or any(lp < 0 or q <= 0 for _, lp, q in comps):
        raise ValueError("negative price, negative list price or non-positive quantity")
    weights = [lp * q for _, lp, q in comps]
    if sum(weights) == 0:
        weights = [1] * len(comps)
    W = sum(weights)
    for w in weights:
        if price * w > LONG_MAX:
            raise OverflowError(f"price*weight {price*w} exceeds Long")
    base = [price * w // W for w in weights]
    rem = [price * w % W for w in weights]
    R = price - sum(base)
    order = sorted(range(len(comps)), key=lambda i: (-rem[i], -weights[i], comps[i][0]))
    for i in order[:R]:
        base[i] += 1
    return base, weights

def check(price, comps, label=None):
    shares, weights = allocate(price, comps)
    W = sum(weights)
    assert sum(shares) == price, (label, shares)
    assert all(s >= 0 for s in shares), (label, shares)
    for s, w in zip(shares, weights):
        assert abs(Fraction(s) - Fraction(price * w, W)) < 1, (label, shares)
    if sum(lp * q for _, lp, q in comps) > 0:
        for s, (_, lp, q) in zip(shares, comps):
            if lp * q == 0:
                assert s == 0, (label, "zero-weight component got a share", shares)
    # order independence: shuffle input, map back by slot order
    rnd = random.Random(price)
    shuffled = comps[:]
    rnd.shuffle(shuffled)
    s2, _ = allocate(price, shuffled)
    by_slot = {c[0]: s for c, s in zip(shuffled, s2)}
    assert [by_slot[c[0]] for c in comps] == shares, (label, "order dependent")
    if label:
        print(f"{label}: price {price}, components {[(lp, q) for _, lp, q in comps]} -> {shares} (sum {sum(shares)})")
    return shares

print("S20 largest-remainder allocation, run with python3 -I (stdlib only)")
print("-- named edge cases --")
check(6000, [(1, 4500, 1), (2, 2500, 1), (3, 0, 1)], "1 one component free (burger 45, drink 25, free sauce) in a 60 EGP combo")
check(1, [(1, 3000, 1), (2, 2000, 1), (3, 1000, 1)], "2 one-piaster combo, three components")
check(1, [(1, 1000, 1), (2, 1000, 1), (3, 1000, 1)], "3 one-piaster combo, three equal components (tie -> slot order)")
check(10000, [(1, 3333, 1), (2, 3333, 1), (3, 3334, 1)], "4 three components, 100 EGP")
check(100, [(1, 1, 1), (2, 1, 1), (3, 1, 1)], "5 100 piasters over three equal components")
check(0, [(1, 4500, 1), (2, 2500, 1)], "6 zero-price combo (giveaway)")
check(500, [(1, 0, 1), (2, 0, 1), (3, 0, 1)], "7 every component free -> equal split")
check(9000, [(1, 2500, 2), (2, 3000, 1)], "8 quantity 2 on a slot (two drinks)")
check(12000, [(1, 4500, 1), (2, 2500, 1)], "9 combo dearer than its parts")
check(6000, [(1, 6000, 1)], "10 single component")
for bad in [(-1, [(1, 100, 1)]), (100, [(1, -5, 1)]), (100, [(1, 5, 0)])]:
    try:
        allocate(*bad); print("11 FAIL: accepted", bad)
    except ValueError:
        print(f"11 rejected {bad}")
print("-- bound check (Kotlin Long) --")
big_price, big_list = 10**9, 10**9   # 10 million EGP combo, 10 million EGP component
check(big_price, [(1, big_list, 1), (2, 1, 1)], "12 10M EGP price, 10M EGP component")
try:
    allocate(10**10, [(1, 10**9, 1)]); print("13 FAIL: no overflow flagged")
except OverflowError as e:
    print("13 overflow flagged above the bound:", e)
print("-- property run, seed 20 --")
rnd = random.Random(20)
n = 0
for _ in range(200_000):
    k = rnd.randint(1, 8)
    comps = [(s + 1, rnd.choice([0, 0, 1, 99, 250, 999, 1500, 4500, 33333]) if rnd.random() < 0.3 else rnd.randint(0, 50_000), rnd.randint(1, 4)) for s in range(k)]
    price = rnd.choice([0, 1, 2, 3, 7, 99, 100]) if rnd.random() < 0.2 else rnd.randint(0, 500_000)
    check(price, comps)
    n += 1
print(f"property cases passed: {n} (sum exact, non-negative, within 1 piaster of exact, zero weight -> 0, order independent)")
