"""Unit-economics calculator for /business-case.

Reads one JSON document (the path given as the first argument, else stdin) and
prints markdown tables on stdout. It computes and reports; it never judges.
Thresholds, if supplied, are echoed as PASS/FAIL observations against the user's
own numbers. Run:

    python3 -I .claude/skills/business-case/references/model.py business/cases/<product>-<slug>-inputs.json

Input shape (all money in ONE currency, net of VAT, per the stated period):

{
  "name": "product / edition label",
  "type": "subscription" | "licence",
  "currency": "EGP",
  "horizon_months": 36,
  "fx": {"local_per_usd": 50.0, "source": "url", "date": "YYYY-MM-DD"},   (optional)
  "thresholds": {"max_payback_months": 12, "min_ltv_cac": 3, "min_gross_margin": 0.7},   (optional, user's)
  "scenarios": {"low": {...}, "base": {...}, "high": {...}}
}

subscription scenario keys:
  arpa_monthly, hosting_monthly, support_monthly, third_party_monthly,
  payment_fee_pct, other_cost_pct, churn_monthly (or churn_annual), cac,
  fixed_monthly (optional), new_customers_per_month (optional)

licence scenario keys:
  licence_price, delivery_cost, included_years, maintenance_pct,
  maintenance_attach_rate, support_cost_per_year, cac, horizon_years (optional)

"low" is the pessimistic case, "high" the optimistic one, for every input
(so low has the lower price and the HIGHER churn and CAC).
"""
import json
import math
import sys


def fmt(x, nd=2):
    if x is None:
        return "n/a"
    if isinstance(x, int) and not isinstance(x, bool):
        return f"{x:,d}"
    if isinstance(x, float) and (math.isinf(x) or math.isnan(x)):
        return "n/a (non-positive margin)" if x > 0 else "n/a"
    return f"{x:,.{nd}f}"


def churn_of(s):
    if "churn_monthly" in s:
        return float(s["churn_monthly"])
    if "churn_annual" in s:
        return 1 - (1 - float(s["churn_annual"])) ** (1 / 12)
    raise SystemExit("scenario needs churn_monthly or churn_annual")


def sub_calc(s, horizon):
    arpa = float(s["arpa_monthly"])
    costs = (float(s.get("hosting_monthly", 0)) + float(s.get("support_monthly", 0))
             + float(s.get("third_party_monthly", 0)))
    pct = float(s.get("payment_fee_pct", 0)) + float(s.get("other_cost_pct", 0))
    gm = arpa * (1 - pct) - costs
    gm_pct = gm / arpa if arpa else float("nan")
    c = churn_of(s)
    cac = float(s["cac"])
    if gm > 0:
        payback = cac / gm
    else:
        payback = float("inf")
    if c > 0:
        ltv_h = gm * (1 - (1 - c) ** horizon) / c
        ltv_inf = gm / c if gm > 0 else float("nan")
    else:
        ltv_h = gm * horizon
        ltv_inf = None  # zero churn: uncapped LTV is unbounded, use the horizon figure
    out = {
        "arpa_monthly": arpa, "gross_margin_month": gm, "gross_margin_pct": gm_pct,
        "churn_monthly": c, "cac": cac, "payback_months": payback,
        "ltv_horizon": ltv_h, "ltv_uncapped": ltv_inf,
        "ltv_cac": (ltv_h / cac) if cac > 0 else float("inf"),
        "contribution_over_horizon": ltv_h - cac,
    }
    fixed = float(s.get("fixed_monthly", 0))
    if fixed > 0:
        out["break_even_customers"] = math.ceil(fixed / gm) if gm > 0 else None
    n = s.get("new_customers_per_month")
    if n is not None:
        n = float(n)
        cust, cum, peak, be_op, be_cum = 0.0, 0.0, 0.0, None, None
        for t in range(1, horizon + 1):
            cust = cust * (1 - c) + n
            profit = cust * gm - fixed - n * cac
            cum += profit
            peak = min(peak, cum)
            if be_op is None and profit >= 0:
                be_op = t
            if be_cum is None and cum >= 0 and t > 1:
                be_cum = t
        out.update({"customers_end": cust, "peak_cash_need": -peak,
                    "first_profitable_month": be_op, "cumulative_break_even_month": be_cum})
    return out


def lic_calc(s, horizon_years):
    price = float(s["licence_price"])
    deliv = float(s.get("delivery_cost", 0))
    inc = int(s.get("included_years", 1))
    m_pct = float(s.get("maintenance_pct", 0))
    att = float(s.get("maintenance_attach_rate", 0))
    sup = float(s.get("support_cost_per_year", 0))
    cac = float(s["cac"])
    cum = price - deliv - cac
    cum0 = cum
    payback_year = 0 if cum >= 0 else None
    for y in range(1, horizon_years + 1):
        active = 1.0 if y <= inc else att ** (y - inc)
        rev = 0.0 if y <= inc else price * m_pct * active
        cum += rev - sup * active
        if payback_year is None and cum >= 0:
            payback_year = y
    return {"licence_price": price, "year0_margin_after_cac": cum0,
            "contribution_over_horizon": cum, "payback_year": payback_year,
            "horizon_years": horizon_years}


def run(doc):
    typ = doc["type"]
    sc = doc["scenarios"]
    months = int(doc.get("horizon_months", 36))
    res = {}
    for k in ("low", "base", "high"):
        if k not in sc:
            raise SystemExit(f"missing scenario {k}")
        res[k] = sub_calc(sc[k], months) if typ == "subscription" else lic_calc(sc[k], max(1, round(months / 12)))
    return res, months


def sensitivity(doc, months):
    typ = doc["type"]
    base = doc["scenarios"]["base"]
    keys = [k for k, v in base.items() if isinstance(v, (int, float)) and not isinstance(v, bool)
            and k not in ("included_years", "horizon_years", "new_customers_per_month", "fixed_monthly")]
    rows = []
    ref = (sub_calc(base, months) if typ == "subscription" else lic_calc(base, max(1, round(months / 12))))["contribution_over_horizon"]
    for k in keys:
        vals = []
        for f in (0.8, 1.2):
            s = dict(base)
            s[k] = base[k] * f
            r = sub_calc(s, months) if typ == "subscription" else lic_calc(s, max(1, round(months / 12)))
            vals.append(r["contribution_over_horizon"])
        rows.append((k, vals[0], vals[1], abs(vals[1] - vals[0]), ref))
    rows.sort(key=lambda r: -r[3])
    return rows


def main():
    if len(sys.argv) > 2:
        sys.exit("usage: model.py [inputs.json]  (reads stdin when no path is given)")
    if len(sys.argv) == 2:
        with open(sys.argv[1], encoding="utf-8") as fh:
            doc = json.load(fh)
    else:
        doc = json.load(sys.stdin)
    res, months = run(doc)
    cur = doc.get("currency", "")
    fx = doc.get("fx")
    th = doc.get("thresholds", {})
    print(f"# {doc.get('name', 'model')} - {doc['type']} - horizon {months} months - currency {cur} (net of VAT)")
    if fx:
        print(f"FX: {fx.get('local_per_usd')} {cur} per USD - {fx.get('source')} - {fx.get('date')}")
    print()
    if doc["type"] == "subscription":
        order = ["arpa_monthly", "gross_margin_month", "gross_margin_pct", "churn_monthly", "cac",
                 "payback_months", "ltv_horizon", "ltv_uncapped", "ltv_cac", "contribution_over_horizon",
                 "break_even_customers", "customers_end", "peak_cash_need",
                 "first_profitable_month", "cumulative_break_even_month"]
    else:
        order = ["licence_price", "year0_margin_after_cac", "contribution_over_horizon", "payback_year", "horizon_years"]
    print("| Metric | Low | Base | High |")
    print("|---|---|---|---|")
    for key in order:
        if not any(key in res[k] for k in res):
            continue
        cells = []
        for k in ("low", "base", "high"):
            v = res[k].get(key)
            nd = 4 if key in ("gross_margin_pct", "churn_monthly") else 2
            cells.append(fmt(v, nd) if isinstance(v, (int, float)) or v is None else str(v))
        print(f"| {key} | " + " | ".join(cells) + " |")
    if fx and doc["type"] == "subscription":
        r = float(fx["local_per_usd"])
        print()
        print("USD equivalents (base): " + ", ".join(
            f"{k} = USD {res['base'][k] / r:,.2f}" for k in ("cac", "ltv_horizon", "gross_margin_month")))
    if th and doc["type"] == "subscription":
        print()
        print("| Threshold (user's) | Value | Low | Base | High |")
        print("|---|---|---|---|---|")
        def mark(ok):
            return "PASS" if ok else "FAIL"
        if "max_payback_months" in th:
            print(f"| payback_months <= | {th['max_payback_months']} | " + " | ".join(
                mark(res[k]['payback_months'] <= th['max_payback_months']) for k in ('low', 'base', 'high')) + " |")
        if "min_ltv_cac" in th:
            print(f"| ltv_cac >= | {th['min_ltv_cac']} | " + " | ".join(
                mark(res[k]['ltv_cac'] >= th['min_ltv_cac']) for k in ('low', 'base', 'high')) + " |")
        if "min_gross_margin" in th:
            print(f"| gross_margin_pct >= | {th['min_gross_margin']} | " + " | ".join(
                mark(res[k]['gross_margin_pct'] >= th['min_gross_margin']) for k in ('low', 'base', 'high')) + " |")
    print()
    print("## Sensitivity of base-case contribution over horizon to +/-20 % on one input at a time")
    print("| Input | at -20 % | at +20 % | swing | base |")
    print("|---|---|---|---|---|")
    for k, lo, hi, sw, ref in sensitivity(doc, months):
        print(f"| {k} | {fmt(lo)} | {fmt(hi)} | {fmt(sw)} | {fmt(ref)} |")
    print()
    print("Top three by swing: " + ", ".join(k for k, *_ in sensitivity(doc, months)[:3]))


if __name__ == "__main__":
    main()
