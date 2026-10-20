---
name: business-case
description: "Unit economics and a simple financial model for a product, edition and market — CAC, LTV, churn, payback, gross margin, break-even with low/base/high scenarios, every input sourced or labelled assumption, arithmetic run by script. Writes business/cases/."
argument-hint: "<product or decision> [--edition hosted|self-hosted] [--market eg|sa|ae|...] [--horizon <months>] [--refresh]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, WebFetch, WebSearch, Bash(python3 -I .claude/skills/business-case/references/model.py), Bash(python3 -I .claude/skills/business-case/references/model.py *), Bash(python3 -I .claude/skills/business-case/references/calc.py), Bash(python3 -I .claude/skills/business-case/references/calc.py *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(date *), Bash(bash "*/.claude/skills/business-case/../../hooks/yaml-helper.sh" resolve_config *)
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

# Business Case

> **Arithmetic.** `calc.py` means `python3 -I .claude/skills/business-case/references/calc.py "<expr>" ...` (arithmetic only; see the file header). Never run `python3 -c` or a heredoc script; the two pinned scripts run without a prompt, anything else asks.

Answers "does this make money, and what would change the answer?" with a model
small enough to read: ARPA, variable cost and gross margin, churn, CAC, LTV over
a stated horizon, payback, break-even — as **low / base / high** scenarios, with
**every input either sourced (value, unit, currency, source, tier, date, scope)
or labelled `ASSUMPTION`**, the three inputs that move the answer most varied by
±20 %, and the cheapest test that would prove the case wrong. The arithmetic is
done by `references/model.py` (stdlib Python, `python3 -I`), not in prose.
`business-director` owns the case; `pricing-strategist` and `marketing-lead`
supply the price, cost and CAC inputs when they are not already on disk.

**Hosted and self-hosted economics are never blended**: separate cases.

**Output:** `business/cases/<product>-<slug>.md` and
`business/cases/<product>-<slug>-inputs.json` (layout, formulas and checklist C1–C10
in `references/1-case-layout.md`).
**Verdict words (fixed):** `RECOMMEND` · `RECOMMEND WITH CONDITIONS` ·
`DO NOT RECOMMEND` · `INSUFFICIENT DATA`. Precedence, first match wins:
`DO NOT RECOMMEND` → `INSUFFICIENT DATA` → `RECOMMEND WITH CONDITIONS` →
`RECOMMEND`.

---

## Phase 1: Scope and Inputs

No product or decision named → ask and stop. Fix: edition, market, the decision
the case informs (launch / price / enter a country / spend a budget), horizon.

Read, recording FOUND or ABSENT: `business/pricing/*` (ARPA, licence price, margin
floor), `business/market/*`, `business/competitors/*`, `business/marketing/*`
(CAC targets and channel rows), `business/sales/*` (selling cost, cycle),
`design/product-brief.md`, `.claude/docs/standing-decisions.md`, the cost inputs (`deploy/`,
`docs/architecture/perf-budgets.md`, `slos.md`, hosting notes in `docs/research/`)
and any actuals the user supplies (real churn, real CAC — only the user can
provide these).

**Insufficient input rule.** An ABSENT driver input (price, variable cost, churn,
CAC) is never filled silently. Ask (`AskUserQuestion`, recommended first): run the
upstream skill first (`/pricing-strategy`, `/market-research`, `/marketing-plan`)
/ proceed on **labelled assumption ranges** the user approves / stop. With
assumptions approved the case runs and the verdict cannot be `RECOMMEND`; with no
answer the affected checks are `NOT ASSESSED — NO DATA` and the verdict is
`INSUFFICIENT DATA`.

**Decision criteria come first.** Ask the user for maximum payback months,
minimum LTV:CAC, minimum gross margin % and the horizon **before** any model runs
(`references/1-case-layout.md` → "Decision criteria"). A user without criteria may
adopt the offered starting points, which are unsourced conventions and are written
as such. A skipped answer is not an answer: re-ask in plain text.

## Phase 2: Plan

Read **`references/1-case-layout.md` now** — formulas, inputs table, input
sources, decision criteria, sections, checklist C1–C10 — and skim the header of
`references/model.py` for its input shape. Re-read after compaction. Announce
which specialists will run to fill missing inputs and which will not.

## Phase 3: Gather Missing Inputs (parallel)

For inputs ABSENT on disk, spawn in **one parallel block**: `pricing-strategist`
(ARPA, price net of VAT, variable cost per customer by component from the
infrastructure files, payment fees from the provider's page — dated) and
`marketing-lead` (CAC per channel with sources or labelled assumptions, funnel
conversions). Fixed brief; fill only `{…}`:

```text
Business-case inputs for /business-case. Read .claude/docs/business-research-protocol.md and
.claude/skills/business-case/references/1-case-layout.md ("Inputs table", "Input family") first.
Product: {name}   Edition: {hosted | self-hosted}   Market: {country}   Currency: {local}
Return ONLY an inputs table: Input | Low (pessimistic) | Base | High (optimistic) | Unit + currency |
Source (link) + tier, or ASSUMPTION with reason | Date | Scope, for: {the missing inputs}.
Net of VAT. Local currency first; FX rate with source and date if you convert. Text only, no files.
Never fabricate benchmarks or past results; where no source exists write NOT SOURCEABLE - <searched>
and give a labelled range. Cost items must be traceable to {paths} or labelled ASSUMPTION.
```

Then spawn `business-director` with the user's criteria, the inputs found on disk
(with paths), and the specialists' tables. Ask it to return the complete **inputs
table** (every row with provenance, low = pessimistic) and the **JSON inputs
document** in the shape of `references/model.py`; it does **not** compute results.

## Phase 4: Run the Model

The inputs JSON is part of the case, so it lives where the case lives, never
outside the repo: ask "May I write `business/cases/<product>-<slug>-inputs.json`
so the model can run on it?" and write it only after the yes (autonomous: write
and `log_decision`). It is a new file; an existing one is never overwritten (a
re-run with changed inputs gets a new dated slug). Then run, passing the file as
an argument (no shell redirect):

```text
python3 -I .claude/skills/business-case/references/model.py business/cases/<product>-<slug>-inputs.json
```

If the inputs write is declined the model does not run: every dependent check is
`NOT ASSESSED` and the verdict is `INSUFFICIENT DATA` (reason: inputs file not
written), nothing is reported as run.

Run once per edition and once per pricing model in scope (`subscription`,
`licence`). Paste the output into the case **verbatim** and report the exit code.
If it fails or an input is missing, fix the input (never the script silently) and
re-run; a run that did not happen is reported as **not run** and every dependent
check is `NOT ASSESSED`.

Then spawn `business-director` again with the script output to write the case
(sections 3, 5–11 in the layout): the recommendation, the worked base example that
**reproduces the script's numbers**, the sensitivity reading (for each of the top
three inputs: recommendation holds / flips), the licence-vs-subscription
comparison when both ran, and the cheapest disproving test with a decision
threshold set before it.

## Phase 5: Audit

Apply C1–C10 (each MET / NOT MET / NOT ASSESSED with the reason); show the table.
Also:

1. **Re-run the model** on the final inputs file and diff against the pasted output; any difference is a defect.
2. **Check the worked example** with `calc.py` (`python3 -I .claude/skills/business-case/references/calc.py "<expr>"`) for the base case.
3. **Count input rows** A / B / C / D / E (as in `/business` Phase 4). E = 0. List the `ASSUMPTION` drivers and say how each closes (pilot of N customers, N interviews, a 2-week test).
4. **Traps:** LTV from an unsourced "5 %" churn presented as fact; CAC from a global benchmark; blended hosted and self-hosted; gross margin that omits support, payment fees or hosting; USD-only money; LTV without a horizon cap; thresholds chosen after seeing the results.

**Verdict.** `DO NOT RECOMMEND` — the base case fails a user criterion (payback above the maximum, LTV:CAC below the minimum, margin below the floor) or the base contribution is negative. `INSUFFICIENT DATA` — no decision criteria, or a driver (ARPA, variable cost, churn, CAC) has no source and no approved range, or the model did not run. `RECOMMEND WITH CONDITIONS` — the low scenario fails a criterion, any driver is an `ASSUMPTION`, or the recommendation flips under ±20 % on a top-three input; the condition is the test and its threshold. `RECOMMEND` — all three scenarios pass, every driver is a tier 1–3 row or the user's measured data, and the recommendation holds under the sensitivity. **Before launch, churn and CAC are assumptions by nature, so `RECOMMEND` is normally unreachable until pilot data exists** — the case says so.

## Phase 6: Present and Write

Present: verdict; scenario table with USD equivalents; criteria PASS/FAIL; the
top-three sensitivity; assumptions and the test that would prove the case wrong.

Ask: "May I write `business/cases/<product>-<slug>.md`?" (the inputs file was
written in Phase 4). Write only after the yes (autonomous: write and
`log_decision`). If the user declines, the case is not saved: the presented
verdict stands as an unsaved answer and the inputs file already on disk is named.
`Grep` for leftover placeholders. The header date comes from `date +%F`.

## Phase 7: Hand-off

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/business-case <product> —
<verdict>`, Next step = the first hand-off below that applies (a concrete
command), plus Blocked on (e.g. `INSUFFICIENT DATA`: the missing driver) / Files
in progress (the case and inputs files) / Open questions; append the Notes line.
Still updated when the user declines the save (inputs file stays; record the case
as not saved).

- Prices or margin that fail → `/pricing-strategy`; CAC ceilings → `/marketing-plan`, selling cost → `/sales-playbook`
- Scope or edition implications → an approval request to `product-director`
- Measured pilot data → rerun this skill with `--refresh` as a new dated file; the old case stays
- Funding, tax or accounting treatment → a qualified advisor

---

## Collaborative Protocol

- **Every input is sourced or labelled `ASSUMPTION`**; a number that appears only in the narrative and not in the inputs table does not exist
- **Arithmetic is run, not recited**; a model run that did not happen is reported as not run
- **Decision criteria are the user's and are fixed before the run**
- **Hosted, self-hosted and licence economics are never blended**
- **A driver with no source and no approved range makes the verdict `INSUFFICIENT DATA`**
- **No fabricated benchmarks, customer data or past results**; real actuals come only from the user
- **No legal, tax, accounting or investment advice**
