"""Arithmetic-only calculator for the business skills.

Evaluates the expressions given as arguments and prints `expression = result`
for each, so the working is visible. It accepts numbers, + - * / // % **,
parentheses, the constants `pi` and `e`, and a fixed set of pure functions. It
cannot import, call anything else, read files or touch the network, which is why
skills pre-approve exactly this script instead of `python3 -I -c`.

    python3 -I .claude/skills/business-case/references/calc.py "12000 * 0.7" "median(3, 5, 9)"
    python3 -I .claude/skills/business-case/references/calc.py "sample_size(0.04, 0.05)"
    python3 -I .claude/skills/business-case/references/calc.py "sample_size(0.04, 0.05, 0.05, 0.8)"

Functions: abs, round, ceil, floor, sqrt, log, log10, exp, min, max, sum, mean,
median, inv_norm(p), sample_size(p1, p2, alpha=0.05, power=0.80) (per arm, two
proportions, two-sided; rounded up).

Exit code 0 when every expression evaluated, 2 when any was rejected or failed.
"""
import ast
import math
import statistics
import sys
from statistics import NormalDist


def _sample_size(p1, p2, alpha=0.05, power=0.80):
    z_a = NormalDist().inv_cdf(1 - alpha / 2)
    z_b = NormalDist().inv_cdf(power)
    pbar = (p1 + p2) / 2
    n = ((z_a * math.sqrt(2 * pbar * (1 - pbar))
          + z_b * math.sqrt(p1 * (1 - p1) + p2 * (1 - p2))) ** 2) / (p1 - p2) ** 2
    return math.ceil(n)


FUNCS = {
    "abs": abs, "round": round, "ceil": math.ceil, "floor": math.floor,
    "sqrt": math.sqrt, "log": math.log, "log10": math.log10, "exp": math.exp,
    "min": min, "max": max, "sum": lambda *a: sum(a),
    "mean": lambda *a: statistics.fmean(a), "median": lambda *a: statistics.median(a),
    "inv_norm": lambda p: NormalDist().inv_cdf(p), "sample_size": _sample_size,
}
CONSTS = {"pi": math.pi, "e": math.e}
BINOPS = {
    ast.Add: lambda a, b: a + b, ast.Sub: lambda a, b: a - b,
    ast.Mult: lambda a, b: a * b, ast.Div: lambda a, b: a / b,
    ast.FloorDiv: lambda a, b: a // b, ast.Mod: lambda a, b: a % b,
    ast.Pow: lambda a, b: a ** b,
}
UNOPS = {ast.UAdd: lambda a: +a, ast.USub: lambda a: -a}
MAX_EXPONENT = 1000
MAX_RESULT_BITS = 100_000


def _ev(node):
    if isinstance(node, ast.Expression):
        return _ev(node.body)
    if isinstance(node, ast.Constant) and type(node.value) in (int, float):
        return node.value
    if isinstance(node, ast.Name) and node.id in CONSTS:
        return CONSTS[node.id]
    if isinstance(node, ast.UnaryOp) and type(node.op) in UNOPS:
        return UNOPS[type(node.op)](_ev(node.operand))
    if isinstance(node, ast.BinOp) and type(node.op) in BINOPS:
        left, right = _ev(node.left), _ev(node.right)
        if isinstance(node.op, ast.Pow):
            if abs(right) > MAX_EXPONENT:
                raise ValueError("exponent too large")
            # Nested powers each pass the exponent check yet compound:
            # ((10**1000)**1000)**1000 would build a billion-digit integer.
            if isinstance(left, int) and left.bit_length() * abs(right) > MAX_RESULT_BITS:
                raise ValueError("result too large")
        return BINOPS[type(node.op)](left, right)
    if (isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
            and node.func.id in FUNCS and not node.keywords):
        return FUNCS[node.func.id](*[_ev(a) for a in node.args])
    raise ValueError("not allowed: " + type(node).__name__)


def main(argv):
    if not argv:
        print(__doc__)
        return 2
    rc = 0
    for src in argv:
        try:
            value = _ev(ast.parse(src.strip(), mode="eval"))
            print("%s = %s" % (src.strip(), value))
        except Exception as exc:  # report every failure, keep going
            print("%s = ERROR (%s)" % (src.strip(), exc))
            rc = 2
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
