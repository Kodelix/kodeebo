"""S40 (part 4 of catalogue-and-item-model): scratch spike, tier E evidence.

Purpose: test the arithmetic claims behind the unit-of-measure and recipe
recommendations. Illustrative numbers only (not Kodeebo data, not a price list).
Stdlib only, no network, no files written. Run: python3 -I s40_units_arithmetic.py
"""
import math
import platform
from decimal import Decimal
from fractions import Fraction


def half_up(x: Fraction) -> int:
    """Round a non-negative Fraction to the nearest integer, halves up."""
    return math.floor(x + Fraction(1, 2))


print("python", platform.python_version())

# Case 1: float versus integer base unit, repeated small deductions.
f = 1000.0  # grams as float
for _ in range(10000):
    f -= 0.1
i = 1_000_000  # milligrams as integer
for _ in range(10000):
    i -= 100
print("case1 float grams left after 10000 x 0.1 g:", repr(f), "(exact answer 0.0)")
print("case1 integer mg left after 10000 x 100 mg:", i)

# Case 2: 1 kg bag, 18 g per espresso, integer milligrams.
bag_mg, dose_mg = 1_000_000, 18_000
shots, rem = divmod(bag_mg, dose_mg)
print("case2 shots per bag:", shots, "remainder mg:", rem)

# Case 3: cost per dose when the bag price does not divide evenly.
price = 33_333  # piasters, illustrative
exact = Fraction(price * dose_mg, bag_mg)
print("case3 exact cost of one dose (piasters):", exact, "=", float(exact))
n = 1000
rounded_each = half_up(exact) * n
print("case3 A: round each sale to whole piasters, 1000 sales:", rounded_each,
      "exact total:", float(exact * n), "drift:", float(rounded_each - exact * n))
# B: moving-average consumption with the running remainder carried in stock value.
value, qty = price, bag_mg
costs = []
for _ in range(shots):
    c = half_up(Fraction(value * dose_mg, qty))
    costs.append(c)
    value -= c
    qty -= dose_mg
# the rest of the bag is written off as waste (reason: end of bag)
last = half_up(Fraction(value * qty, qty)) if qty else 0
print("case3 B: 55 shots cost sum:", sum(costs), "remaining value for", qty,
      "mg left:", value, "-> total accounted:", sum(costs) + value, "must equal", price)

# Case 4: yield percentage in basis points, rounding per sale versus exact total.
net_mg = 18_000
for yield_bp in (8000, 8300):
    gross = Fraction(net_mg * 10000, yield_bp)
    per_sale = half_up(gross)
    total_exact = gross * 10000
    print(f"case4 yield {yield_bp/100}%: gross per dose {float(gross):.4f} mg, "
          f"rounded {per_sale}; 10000 sales rounded {per_sale*10000} vs exact "
          f"{float(total_exact):.1f} (drift {float(per_sale*10000 - total_exact):.1f} mg)")

# Case 5: sub-recipe. Batch: 1000 g sugar + water -> 1500 ml syrup; drink uses 20 ml.
drinks_per_batch = 1500 // 20
sugar_per_drink = Fraction(1000 * 1000 * 20, 1500)  # mg, exact
print("case5 sugar per drink (mg) exact:", sugar_per_drink, "=", float(sugar_per_drink))
print("case5 Decimal(40)/Decimal(3) g =", Decimal(40) / Decimal(3), "(not exact)")
exploded_rounded = half_up(sugar_per_drink) * drinks_per_batch
print("case5 explode at sale, rounded to mg per drink x", drinks_per_batch,
      "drinks:", exploded_rounded, "mg vs batch input 1000000 mg; drift",
      exploded_rounded - 1_000_000, "mg")
print("case5 stock the syrup in ml: deduct 20 ml x", drinks_per_batch, "=",
      20 * drinks_per_batch, "ml; raw sugar 1000000 mg moved once at batch time, drift 0")

# Case 6: void return. Reverse the stored movement versus recompute from today's recipe.
sold_with = 18_000  # mg per dose when the sale happened
recipe_now = 20_000  # recipe edited afterwards
stock = bag_mg - sold_with  # after the sale
returned_by_reversal = stock + sold_with
returned_by_recompute = stock + recipe_now
print("case6 stock after void by reversing stored movement:", returned_by_reversal,
      "| by recomputing from current recipe:", returned_by_recompute,
      "(excess", returned_by_recompute - bag_mg, "mg)")

# Case 7: purchase unit conversion into a count unit.
for cartons in (Decimal("2.5"), Decimal("2.3333"), Decimal("2.34")):
    cans = cartons * 24
    print(f"case7 {cartons} cartons x 24 = {cans} cans; whole: {cans == cans.to_integral_value()}")
