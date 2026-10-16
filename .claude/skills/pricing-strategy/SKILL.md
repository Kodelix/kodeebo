---
name: pricing-strategy
description: "Pricing strategy for a product — value metric, packaging, EGP/SAR/AED/USD price levels, annual vs monthly, one-time licence + maintenance, self-hosted enterprise pricing, margin vs infrastructure cost, price-test design; writes business/pricing/ and a hand-off for pricing-billing-designer."
argument-hint: "<product> [--scope full|regional|licence|self-hosted|price-test] [--currency EGP,SAR,AED,USD]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), Agent, AskUserQuestion, WebFetch, WebSearch, Bash(python3 -I .claude/skills/business-case/references/calc.py), Bash(python3 -I .claude/skills/business-case/references/calc.py *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(date *), Bash(bash "*/.claude/skills/pricing-strategy/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.
No director gate applies; `review_mode` and `workflow` do not relax sourcing.

# Pricing Strategy

> **Arithmetic.** `calc.py` means `python3 -I .claude/skills/business-case/references/calc.py "<expr>" ...` (arithmetic only: numbers, operators, `sqrt`, `median`, `sample_size`; see the file header). Never run `python3 -c` or a heredoc script; `calc.py` runs without a prompt, anything else asks.

Decides **what to charge, for what, in which currency, and how to test it** so the
product earns a margin that survives infrastructure and support cost, then hands
the decided model to `pricing-billing-designer` as data. Work is done by
`pricing-strategist` under `.claude/docs/business-research-protocol.md`: every
price and fee has value + unit + currency, source + tier, date, scope; local
currency first with USD and a dated rate; VAT status stated.

**It recommends; it does not implement.** The value metric and plans of record
need `product-director`'s sign-off (an approval request to the user, not a gate);
the catalogue and pricing model are written by `pricing-billing-designer`;
`/pricing-check` then tests the result. This skill writes no spec, code or
pricing model.

**Outputs:** `business/pricing/<product>-<topic>.md` and
`business/pricing/<product>-handoff-<date>.md`.
**Verdict words (fixed):** `RECOMMEND` · `RECOMMEND WITH CONDITIONS` ·
`DO NOT RECOMMEND` · `INSUFFICIENT DATA`. Precedence, first match wins:
`DO NOT RECOMMEND` → `INSUFFICIENT DATA` → `RECOMMEND WITH CONDITIONS` →
`RECOMMEND`. Individual checks are MET / NOT MET / NOT ASSESSED.

---

## Phase 1: Scope and Inputs

No product named → ask and stop. Parse `--scope` (default `full`) and currencies
(default EGP, SAR, AED, USD).

Read, recording FOUND or ABSENT: `design/product-brief.md` (ICP, positioning,
pricing hypotheses, decision log), `docs/ROADMAP.md` (annual subscription and
one-time licence; hosted + self-hosted), existing pricing model
(`design/specs/pricing-model.md` — the canonical path; if absent,
`Glob design/**/pricing-model*.md` and name the non-canonical location),
`business/pricing/*`,
`business/competitors/*`, `business/market/*`, the licence model artifact for
self-hosted, and the cost inputs: `deploy/` Compose files,
`docs/architecture/perf-budgets.md`, `slos.md`, hosting notes in `docs/research/`.

**Insufficient input rule.** An ABSENT input makes the dependent check `NOT
ASSESSED — NO DATA` (checklist in `references/1-pricing-brief.md`): no corridor
→ P3; no cost inputs → P5, P6. Never estimate a cost to fill the gap silently:
ask the user whether to proceed on **labelled assumptions** (then the margin rows
are `ASSUMPTION` and the verdict cannot be `RECOMMEND`) or to stop. With no
product brief and no answer from the user, the outcome is `INSUFFICIENT DATA —
no ICP / value to price`.

Corridor check: count `VERIFIED-ON-SITE` captures in `business/competitors/`
(never `business/competitors/notes/` — those are unverified `/business` notes)
younger than the user's horizon. Fewer than three → `AskUserQuestion`: run
`/competitor-analysis` first (recommended) / proceed with the count found plus
`NOT SOURCEABLE` for the rest. Ask also (recommended first, one question at a
time where answers depend): margin floor (the user's number, set **before**
research), VAT display per market, grandfathering preference, edition scope.
A skipped answer is not an answer: re-ask in plain text.

## Phase 2: Licence Mechanics (conditional)

When one-time licence or self-hosted is in scope and no licence-model artifact is
FOUND, spawn `licensing-specialist` with one question: which update-eligibility,
grace-period, offline-activation and renewal mechanics the commercial terms may
rely on, with the file or decision each answer comes from. No source → "not
decided" and the terms that depend on it are conditions. If the artifact exists,
read it instead and say so. Not in scope → say `licence mechanics: not in scope`.

## Phase 3: Spawn the Strategist

**Read `references/1-pricing-brief.md` now** (sections, audit checklist P1–P12)
and `references/3-price-test.md`. Re-read after compaction.

Spawn `pricing-strategist` via `Agent`. Fixed brief; fill only `{…}`:

```text
Pricing recommendation for /pricing-strategy. Read first:
.claude/docs/business-research-protocol.md, .claude/skills/pricing-strategy/references/1-pricing-brief.md,
.claude/skills/pricing-strategy/references/3-price-test.md, .claude/docs/templates/pricing-model.md.
Product: {name}   Scope: {scope}   Currencies: {list}   Editions: {hosted | self-hosted | both, separate economics}
Product context: {ICP, positioning, pricing hypotheses from the brief, or "ABSENT"}
Competitor captures usable (VERIFIED-ON-SITE, within horizon): {file paths and capture dates, or "none"}
Market rows usable: {paths, or "none"}
Cost inputs: {sourced items with paths, or "ABSENT - label every cost ASSUMPTION"}
Licence mechanics: {from the licence model or licensing-specialist, or "not decided"}
User thresholds: margin floor {X or "none stated"}; VAT display {rule}; grandfathering {rule}; horizon {days}
Fetch FX rates (central-bank/authority page), payment-provider fees and VAT/e-invoicing rules
with WebFetch; record URL, tier and date for each. Do all multi-step arithmetic with calc.py and
show the working. Return the full recommendation text and the hand-off data list, text only;
do not write files, and write no price into any spec or code. No fabricated competitor prices,
willingness-to-pay data, interviews or testimonials. No legal/tax conclusions.
```

## Phase 4: Audit

Check the returned text against **P1–P12** in `references/1-pricing-brief.md`,
each MET / NOT MET / NOT ASSESSED with the reason; show the table. Then:

1. **Re-run the arithmetic** (margins, annual-vs-monthly, 3-year licence comparison, sample size) with `calc.py`; a mismatch is sent back.
2. **Count the number rows** A / B / C / D / E as in `/business` Phase 4 (four fields; tiers; assumptions; not sourceable; defects = 0). Prices of competitors without a capture date are defects.
3. **Traps:** USD list converted without market-specific points; a discount without floor, cap or end date; a plan dominated by another; a tier named by price rather than buyer; self-hosted priced like hosted; an unlimited cheapest plan; a price test without a computed sample size; a payment method priced that we cannot support; any legal/tax conclusion.
4. **Hand-off completeness** against `references/2-handoff.md`.

**Verdict.** `DO NOT RECOMMEND` — base-case margin below the user's floor, or a dominated plan / loophole the numbers show. `INSUFFICIENT DATA` — P3 or P5 is NOT ASSESSED, or P2 is NOT MET after one send-back (a price without value, currency, period and VAT status is not a price), so price **levels** cannot be set (structure and value metric may still be reported as a hypothesis). `RECOMMEND WITH CONDITIONS` — P1, P11 or P12 is NOT MET after one send-back (the condition is closing it before `product-director` sign-off or before the test runs), P3 is NOT MET as a sketch (fewer than three dated captures), P4 is a hypothesis, or any of P6–P10 is NOT ASSESSED or NOT MET for a stated reason, or any driver is `ASSUMPTION`/range; the conditions are the price test and the inputs to close. Every P1–P12 outcome therefore maps to a verdict; none is left unmapped. `RECOMMEND` — every check MET, drivers tier 1–3 rows, the recommendation holds under ±20 %. A NOT ASSESSED check is named in the summary with the input that closes it.

## Phase 5: Present and Write

Present: verdict, price table, corridor with n, margin by plan, sensitivity, the
test design, the decisions for `product-director`.

Ask: "May I write `business/pricing/<product>-<topic>.md` and
`business/pricing/<product>-handoff-<date>.md`?" Write only after the yes
(autonomous: write and `log_decision`); the date in the file name and header comes
from `date +%F`. If the user declines, nothing is written; the verdict already
presented stands and the report says "not saved". Both files start with the header
(date, author agent, verdict, source list; hand-off header per
`references/2-handoff.md`). `Grep` for leftover placeholders and report.

## Phase 6: Hand-off

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/pricing-strategy <product> —
<verdict>`, Next step = hand-off item 1 below (the decisions list to
`product-director`), plus Blocked on / Files in progress / Open questions; append
the Notes line. DO NOT RECOMMEND, INSUFFICIENT DATA or a declined write still
updates the checkpoint with the blocker.

1. Decisions list → `product-director` (value metric, plans of record, edition split) — **the user takes it there**; nothing is implemented before sign-off
2. After sign-off → `pricing-billing-designer` writes the new catalogue version and the pricing model from the hand-off file
3. Then `/pricing-check`; margin or cost surprises → `/business-case`
4. Offers on top of this price → `/offer-design`; price test run → results back into `business/pricing/` as a new dated file
5. Tax/e-invoicing implications → a qualified advisor

---

## Collaborative Protocol

- **No price, fee, tax rate or exchange rate from memory**; competitor prices are dated captures; fees come from the provider's own page
- **A check that could not run is `NOT ASSESSED`** and keeps `RECOMMEND` out of reach; an unreachable provider page is listed as not run
- **Hosted and self-hosted economics are never blended**
- **A price with no willingness-to-pay evidence is a labelled hypothesis** with a test, not a conclusion
- **Never publishes or runs a price test**; the user does, after approval
- **Never writes a price into a spec, code or the pricing model**
- **No fabricated interviews, testimonials or competitor prices; no legal, tax or accounting conclusion**
