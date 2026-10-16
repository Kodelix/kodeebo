---
name: offer-design
description: "Design a launch deal, discount, bundle, trial or referral offer with guardrails — floor price, duration, eligibility, stacking, caps, abuse cases — expected impact with stated assumptions, and a measurement plan. Writes business/pricing/offer-<slug>.md."
argument-hint: "<offer idea or goal> [--product <name>] [--type launch|discount|bundle|trial|referral|partner|poc]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), Agent, AskUserQuestion, WebFetch, WebSearch, Bash(python3 -I .claude/skills/business-case/references/calc.py), Bash(python3 -I .claude/skills/business-case/references/calc.py *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(date *), Bash(bash "*/.claude/skills/offer-design/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.
No director gate applies; `review_mode` and `workflow` do not relax the guardrails.

# Offer Design

> **Arithmetic.** `calc.py` means `python3 -I .claude/skills/business-case/references/calc.py "<expr>" ...` (arithmetic only: numbers, operators, `sqrt`, `median`, `sample_size`; see the file header). Never run `python3 -c` or a heredoc script; `calc.py` runs without a prompt, anything else asks.

An offer is a **price with a purpose, an end date and a way to be abused**. This
skill designs launch deals, discounts, coupons, bundles, trials, referral rewards
and partner/POC terms so each one has: a purpose, eligibility, maximum depth,
duration, stacking rule, a **floor price it cannot cross**, a budget cap,
start/end dates, a control for every abuse case, an **expected-impact scenario
with every assumption stated**, and a **measurement plan**. Work is done by
`pricing-strategist` (with `marketing-lead` for launch-deal copy and timing)
under `.claude/docs/business-research-protocol.md`.

It designs; it does not publish, apply a coupon in a billing system or send a
campaign. Catalogue rows go to `pricing-billing-designer`; events to
`product-analytics-engineer`.

**Output:** `business/pricing/offer-<slug>.md` (layout and field definitions in
`references/1-offer-spec.md`). `<slug>` is the kebab-case offer name the user confirms in Phase 1.
**Verdict words (fixed):** `RECOMMEND` · `RECOMMEND WITH CONDITIONS` ·
`DO NOT RECOMMEND` · `INSUFFICIENT DATA`. Precedence, first match wins:
`DO NOT RECOMMEND` → `INSUFFICIENT DATA` → `RECOMMEND WITH CONDITIONS` →
`RECOMMEND`.

---

## Phase 1: Understand the Offer and the Inputs

No argument → ask what the offer is meant to achieve and stop. Classify the type
(launch / discount / bundle / trial / referral / partner / POC) and the edition
(hosted, self-hosted — separate offers).

Read, recording FOUND or ABSENT: `business/pricing/*` (price table, **margin
floor**, grandfathering rule), the pricing model
(`design/specs/pricing-model.md` — the canonical path; if absent,
`Glob design/**/pricing-model*.md` and name the non-canonical location; live
plans, existing trials/coupons), `business/cases/*`
(CAC, payback, churn), `business/market/*`, `business/competitors/*` (their
public offers, dated), `design/product-brief.md`.

**Insufficient input rule.** No price table or margin floor → there is no floor
price to guard, and **no floor is invented**: the verdict is `INSUFFICIENT DATA —
no floor price`, naming `/pricing-strategy` as the producer. No unit-cost or CAC
input → the impact section is `NOT ASSESSED` unless the user approves labelled
assumptions (then `RECOMMEND` is unreachable). If the user declines the
assumptions, the offer's economics cannot be computed and the verdict is
`INSUFFICIENT DATA — no unit-cost / CAC input` (naming `/business-case` as the
producer); the guardrail table is still presented.

Ask (`AskUserQuestion`, 2–4 options, recommended first): the single behaviour the
offer should change, the offer name as a kebab-case `<slug>` to confirm (for example `eid-annual-launch`), the budget cap in local currency, the earliest and latest
dates, and whether existing customers may take it. A skipped answer is not an
answer: re-ask in plain text.

## Phase 2: Design

Read **`references/1-offer-spec.md` now** — guardrail fields, the eleven abuse
cases, the impact formula and break-even incremental share, the measurement plan
and the file layout. Re-read after compaction.

## Phase 3: Spawn

Spawn `pricing-strategist` via `Agent`; for a launch deal spawn `marketing-lead`
in the **same parallel block** for timing, channel and message constraints (it
needs only the offer idea, not the strategist's output). Fixed brief; fill `{…}`:

```text
Offer design for /offer-design. Read .claude/docs/business-research-protocol.md and
.claude/skills/offer-design/references/1-offer-spec.md first.
Offer: {idea, type, edition, goal}   Product: {name}
Price table and margin floor: {rows with sources and dates, or "ABSENT"}
Unit economics available: {CAC, churn, variable cost per customer with sources, or "ABSENT - label ASSUMPTION"}
Competitor offers (dated): {paths, or "none"}
User constraints: budget cap {X}, window {dates}, existing customers {yes/no}
Return text only, no files: every guardrail field filled; all eleven abuse cases with control
or "accepted risk - needs the user's decision"; lowest price reachable by any stack vs floor;
impact formula with low/base/high and break-even incremental share (run with calc.py);
measurement plan; assumptions with how to close each. Money local currency first, USD with rate,
source and date; VAT status stated. No fabricated results from past campaigns, no legal/tax conclusions.
```

Then spawn `product-analytics-engineer` with the strategist's terms table, impact scenarios and
draft measurement plan pasted in (it needs them, so it runs **after** the strategist): events and
properties for the tracking plan, holdout or staggered start, the sample size and duration feasible at
the stated reach, guard metrics, and an explicit "agreed" or the changes it requires. Self-hosted
telemetry stays off by default. If it cannot be spawned or returns nothing, the measurement plan is
**not agreed**: that check is `NOT ASSESSED`, the section says "agreement with `product-analytics-engineer`: not run", and `RECOMMEND` is unreachable.

`marketing-lead` brief: message and timing constraints for the offer in Arabic and
English (claims it may make, none that the terms do not support), expected
audience size with source or `ASSUMPTION`, and the consent rules for any email.

## Phase 4: Audit

1. **Re-run the arithmetic** (lowest reachable price, impact, break-even `i`) with `calc.py`.
2. **Guardrail completeness:** every field in `references/1-offer-spec.md` filled; end date present; cap present; floor sourced; lowest stacked price ≥ floor.
3. **Abuse cases:** all eleven walked; each has a control, or is marked "accepted risk" for the user to accept or reject. This skill never accepts a risk.
4. **Impact:** every rate is sourced or `ASSUMPTION`; cannibalisation (`i`) is explicit; low/base/high shown; break-even stated.
5. **Number rows** counted A / B / C / D / E as in `/business` Phase 4; E = 0.
6. **Measurement:** holdout or staggered start; events named for the tracking plan; sample size computed; stop rule written; agreement of `product-analytics-engineer` recorded (it ran and agreed) — otherwise `NOT ASSESSED`.
7. **Boundaries:** no hidden auto-renew or hard-to-cancel mechanic; no unprovable claim in copy; no legal/tax conclusion; self-hosted telemetry stays off by default.

**Verdict.** `DO NOT RECOMMEND` — a stack reaches below the floor, the base case has negative incremental margin, there is no cap or end date, or an abuse case that breaches the floor has no control. `INSUFFICIENT DATA` — no floor price, or the offer's economics cannot be computed (no unit-cost / CAC input and the user declined labelled assumptions, or still not computable with approved ones). `RECOMMEND WITH CONDITIONS` — any rate is an assumption, any abuse case is an accepted risk, the measurement plan is not yet agreed with `product-analytics-engineer` (it ran and asked for changes), or that agreement is `NOT ASSESSED` because the specialist did not run — in which case `RECOMMEND` stays out of reach. `RECOMMEND` — floor, cap, dates and controls complete, impact inputs tier 1–3 or measured, and the base case holds with the break-even comfortably inside the assumed range — defined as: the break-even incremental share `i*` is at most 80 % of the **low**-scenario `i` (a studio convention, unsourced, stated as such in the file). A check that did not run is reported as not run.

## Phase 5: Present and Write

Present: verdict, the terms table, floor check, abuse table, impact scenarios with
break-even, the measurement plan, the open decisions.

Ask: "May I write this to `business/pricing/offer-<slug>.md`?" (the `<slug>` confirmed in Phase 1) Write only after
the yes (autonomous: write and `log_decision`). If the user declines, nothing is
written; the verdict already presented stands and the report says "not saved".
The header date comes from `date +%F`. `Grep` for leftover placeholders.

## Phase 6: Hand-off

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/offer-design <slug> —
<verdict>`, Next step = the first hand-off item below, plus Blocked on / Files in
progress / Open questions; append the Notes line. DO NOT RECOMMEND, INSUFFICIENT
DATA or a declined write still updates the checkpoint with the blocker.

- Catalogue rows (coupon, trial, bundle) → `pricing-billing-designer`, then `/pricing-check`
- Copy and timing → `/marketing-plan` or `/gtm-plan`
- Events and holdout → `product-analytics-engineer`; consent facts → `privacy-compliance-specialist`
- Offers that change plans or entitlements of record → an approval request to `product-director`
- POC licence enforcement → `licensing-specialist`
- Read-out date, kill criteria and owner are written in the file; the user launches and ends the offer

---

## Collaborative Protocol

- **No floor price is invented**; the floor comes from the pricing file or the verdict is `INSUFFICIENT DATA`
- **Every offer has an end date, a cap and an abuse control per case**; accepting a residual risk is the user's decision, never this skill's
- **Expected impact is a labelled scenario**, with cannibalisation explicit; a past-campaign result is cited only if the user supplies the data
- **A check that did not run is `NOT ASSESSED`** and keeps `RECOMMEND` out of reach
- **Nothing is published, applied in billing or sent**; those are the user's actions
- **No dark patterns** — cancellation as easy as sign-up, renewal terms shown before purchase
- **No fabricated testimonials or results; no legal, tax or accounting conclusion**
