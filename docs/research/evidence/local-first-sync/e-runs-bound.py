#!/usr/bin/env python3
"""Runs needed so that, if every one of n independent randomized runs shows zero
defects, the true per-run defect probability p is bounded above by p_max with
confidence 1-alpha.  Zero-failure exact (Clopper-Pearson one-sided) bound:
    (1-p)^n <= alpha   =>   n >= ln(alpha) / ln(1-p)
Rule of three: n ~ 3/p (alpha=0.05); 4.6/p (alpha=0.01); 6.9/p (alpha=0.001).
Also: power to see a defect of rate p at least once in n runs: 1-(1-p)^n.
Usage: python3 -I e-runs-bound.py
"""
import math
print("n_exact = ceil(ln(alpha)/ln(1-p)) for zero observed failures")
print(f"{'p (per run)':>12} | {'alpha=0.05 exact':>16} {'3/p':>8} | {'alpha=0.01 exact':>16} {'4.6/p':>8} | {'alpha=0.001 exact':>17}")
for p in [0.1, 0.05, 0.01, 0.005, 0.001, 0.0001]:
    ex = lambda a: math.ceil(math.log(a) / math.log(1 - p))
    print(f"{p:>12} | {ex(0.05):>16} {math.ceil(3/p):>8} | {ex(0.01):>16} {math.ceil(4.6/p):>8} | {ex(0.001):>17}")
print()
print("Probability that n runs show >=1 defect when true rate is p: 1-(1-p)^n")
for n in [100, 300, 1000, 3000, 10000]:
    print(f"n={n:>6}: " + "  ".join(f"p={p}:{1-(1-p)**n:.3f}" for p in [0.01, 0.003, 0.001, 0.0003]))
print()
print("Upper bound on p after n runs with 0 failures, alpha=0.05 (exact 1-alpha^(1/n)):")
for n in [100, 300, 1000, 3000, 10000, 30000]:
    print(f"n={n:>6}: exact={1-0.05**(1/n):.6f}  3/n={3/n:.6f}")
