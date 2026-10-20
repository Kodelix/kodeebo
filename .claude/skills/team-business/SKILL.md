---
name: team-business
description: "Orchestrate the business team for one decision — market-researcher, then pricing-strategist, then marketing-lead and sales-lead in parallel, then business-director consolidates: market entry, pricing change, launch, edition or viability, with one sourced recommendation, or INSUFFICIENT DATA naming the gap that blocks one."
argument-hint: "<decision to make, e.g. 'enter KSA with the hosted plan' or 'price the self-hosted edition'>"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), Agent, AskUserQuestion, WebFetch, WebSearch, Bash(python3 -I .claude/skills/business-case/references/model.py), Bash(python3 -I .claude/skills/business-case/references/model.py *), Bash(python3 -I .claude/skills/business-case/references/calc.py), Bash(python3 -I .claude/skills/business-case/references/calc.py *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/hooks/yaml-helper.sh is_always_ask_category *), Bash(date *), Bash(bash "*/.claude/skills/team-business/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

# Team Business

> **Arithmetic.** `calc.py` means `python3 -I .claude/skills/business-case/references/calc.py "<expr>" ...` (arithmetic only: numbers, operators, `sqrt`, `median`, `sample_size`; see the file header). Never run `python3 -c` or a heredoc script; `calc.py` runs without a prompt, anything else asks.

**Argument check:** If no decision is provided, output:
> "Usage: `/team-business <decision to make>` — Provide the decision (e.g., `enter KSA with the hosted plan`, `price the self-hosted edition`, `launch an annual-prepay offer`, `is product X worth continuing`)."
Then stop immediately without spawning any subagent or reading any file.

When invoked with a valid argument, orchestrate the business team end to end for
**one decision**: facts first (`market-researcher`), then price
(`pricing-strategist`), then the go-to-market and sales plans in parallel
(`marketing-lead`, `sales-lead`), then one consolidated answer from
`business-director` — all under `.claude/docs/business-research-protocol.md`
(four fields per number, `NOT SOURCEABLE` with ranges, local currency first with a
dated rate, VAT status, no fabricated quotes or survey results, no legal/tax
conclusions; Egypt and GCC/MENA).

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,stack`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Decision Points:** at each wave transition use `AskUserQuestion` to present the
wave's result as selectable options (proceed / adjust the brief and rerun that
wave / stop). `collaborative`: the user approves before the next wave. `guided`:
advances automatically unless a wave is BLOCKED, asking at major decisions
(country set, thresholds, deliverables). `autonomous`: runs end to end and records
each outcome with `log_decision`. Decisions in `automation_always_ask` categories
always prompt. See `.claude/docs/automation-modes.md`. A skipped or empty answer
is not an answer: re-ask in plain text and wait.

`review_mode` and `workflow` do not apply: there is no business director gate to
skip, and sourcing is required at every tier. **`team.size` does not collapse
this pipeline** — it describes the engineering team; the business team is pulled
per decision, and which specialists run is decided by the matrix below and
announced.

**Verdict words (fixed):** `RECOMMEND` · `RECOMMEND WITH CONDITIONS` ·
`DO NOT RECOMMEND` · `INSUFFICIENT DATA`. Precedence, first match wins:
`DO NOT RECOMMEND` → `INSUFFICIENT DATA` → `RECOMMEND WITH CONDITIONS` →
`RECOMMEND`. A wave outcome is `DONE` / `BLOCKED` / `NOT RUN`.

---

## Phase 1: Frame the Decision

Read **`references/1-decision-matrix.md` now** — which specialists a decision needs,
the waves, the working files and the deliverables. Re-read after compaction.

Read, recording FOUND or ABSENT: `design/product-brief.md`, `.claude/docs/standing-decisions.md`
(hosted, self-hosted, annual subscription, one-time licence), `PRODUCT.md`,
and everything under `business/` and `docs/research/` (a sourced row on disk is
reused with its date and re-verified when older than the horizon the user states).

Ask (`AskUserQuestion`, 2–4 options, recommended first; one at a time where
answers depend): the **options being compared** (at least two for a choice),
countries, edition (hosted / self-hosted — **never blended**), the **decision
thresholds set before research** (margin floor, payback limit, budget cap, minimum
SOM), the decision date, and the staleness horizon. Thresholds are the user's; they
are recorded now so the verdict is not fitted to the result.

**Insufficient input rule.** No brief and no ICP from the user → `INSUFFICIENT
DATA — no ICP / product to evaluate`; stop and name `/brainstorm` /
`product-director`. An unreachable input is listed, never assumed.

**Announce the active set before spawning anything** — never let a collapse be silent:

> `Active (decision type: <row>): <agents that will run, wave by wave>.`
> `Not spawned this run: <the others> — reason: <not needed for this decision>.`
> `Working files: production/business/<slug>/. Deliverables: business/... after approval.`

Product-scope, edition-of-record and positioning-of-record questions that surface
go to `product-director` as approval requests; implementing a decided price goes to
`pricing-billing-designer` — neither is decided here.

## Phase 2: Wave 1 — Facts

Spawn `market-researcher` via `Agent`, **one per country, in one parallel block**.
Every agent prompt starts with the brief below and ends with the return contract.

```text
Wave 1 for /team-business. Read .claude/docs/business-research-protocol.md first.
Decision: {decision}   Options: {list}   Country: {one country}   Edition: {hosted | self-hosted}
Product context: {ICP, positioning from the brief, or "ABSENT"}   Horizon: {days}
Already sourced on disk (reuse, with dates): {paths}
User thresholds: {margin floor, payback, budget cap, minimum SOM}
Size this country bottom-up (unit of count defined from the source; N x share x reach x price,
low/base/high, calc.py for the arithmetic); competitor captures needed for pricing (dated,
VERIFIED-ON-SITE / THIRD-PARTY marks); buyer behaviour, payment methods and fees (provider pages),
VAT/e-invoicing and data-residency facts (authority pages, effective date, advisor caveat).
NOT SOURCEABLE with what was searched and a labelled range. No fabricated survey or interview results.
```

**Return contract (every agent in every wave).** End the prompt: "Write your full output to
`[path]` — that named path is your write authorisation under the bounded exception below, so write it without a
separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of findings, (3) any
BLOCKED/CONCERNS items and unreachable sources, one line each. Do not restate the documents you read." Substitute
the real path from the working-files table.

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires "May I write…" before a write. A subagent spawned here writes without asking as a deliberate, bounded exception, valid only when (1) the path is one this skill named, so the user approved the destination with the wave; (2) it is a **new** artifact under `production/`; (3) the wave is itself gated by an `AskUserQuestion` before the pipeline advances. Deliverables under `business/` are **not** covered: they wait for Phase 6.

Collect all returns before proceeding; surface any BLOCKED agent immediately. Gate: present the countries' sizing and key
facts, then the decision point above.

## Phase 3: Wave 2 — Price

Spawn `pricing-strategist` with the wave-1 tables **pasted in** (not a path to re-read), the thresholds, the
editions, and the corridor captures. Ask for the price table per currency (VAT status; USD with rate, source, date),
corridor, margin by plan with ±20 % sensitivity, the floor price, licence and self-hosted terms if in scope, and
the price-test design. Same return contract (`02-pricing.md`). Gate as above.

## Phase 4: Wave 3 — Plan the Go-to-Market and the Sale (parallel)

Spawn `marketing-lead` and, when the matrix says so, `sales-lead` in **one parallel block**, each with the wave-1 and
wave-2 tables pasted in. `marketing-lead`: ICP per country, positioning proposal, channels with sourced benchmarks or
`ASSUMPTION`, CAC ceiling **derived** from the pricing file (ARPA × margin × payback months), budget table, launch
sequence. `sales-lead`: motion by the rule "fully loaded selling cost ≤ CAC ceiling", qualification, pipeline and
forecast (`ILLUSTRATIVE`), enterprise terms each with a status and source (`OFFERED` only with a cited path;
else `NEEDS ENGINEERING APPROVAL`), payment terms, discount authority from the floor, objections with provenance.
Same return contract. A specialist not spawned is named in the final line. Gate as above.

## Phase 5: Wave 4 — Consolidate

Spawn `business-director` with every returned summary and the working-file paths it should read (they are written
files, not yet in its context). It returns, to `04-decision.md`: the verdict and one-paragraph recommendation; the
numbers table with the A/B/C/D/E tally; **options on one table** (addressable segment size bottom-up, price level,
payment methods, e-invoicing / data-residency obligations, language, competitors, channel cost); **conflicting numbers
side by side with the reason for the choice**, never averaged; the three inputs that move the answer most varied by
±20 % — when the decision turns on payback, LTV:CAC or margin it runs the business-case calculator
(it writes the inputs JSON in `model.py`'s shape to `production/business/<slug>/04-model-inputs.json`, a working draft; this skill then runs `python3 -I .claude/skills/business-case/references/model.py production/business/<slug>/04-model-inputs.json`, passing the file as an argument, see `/business-case`) and reports the output and exit code (a run that did not happen is **not run**); assumptions and
gaps with how to close each; the cheapest test that would prove the recommendation wrong, with its decision threshold;
next steps (action — owner — date); specialists consulted, not run, unreachable.

**Audit before presenting.** (1) Re-run the arithmetic the drafts show with `calc.py`. (2) Count rows A (four fields,
tier 1–3) / B (tier 4–5 lead) / C (`ASSUMPTION`) / D (`NOT SOURCEABLE`) / E (missing a field); E = 0. (3) Check the traps:
USD-only money; VAT unstated; a competitor price with no capture date; a global figure standing in for a regional one;
countries or editions summed; a quote, testimonial, survey or pipeline figure with no provenance; an `OFFERED` term with no
source; a legal or tax conclusion. (4) A wave that did not run or a source that was unreachable is **not run** — never clean.

**Verdict.** `DO NOT RECOMMEND` — base-case numbers fail a threshold the user set before research. `INSUFFICIENT
DATA` — a driver (SOM, price level, ARPA, margin, CAC) is `NOT SOURCEABLE` with no defensible range, or a needed
wave is `NOT RUN`/`BLOCKED`. `RECOMMEND WITH CONDITIONS` — a driver is an assumption or range, or the recommendation
flips under ±20 %; the condition is the cheapest test and its threshold. `RECOMMEND` — every driver is tier 1–3 and the
recommendation holds under the sensitivity.

## Phase 6: Present, Write and Hand Off

Present the consolidated answer in the protocol's order: verdict and recommendation, numbers table with tally,
options and sensitivity, assumptions and gaps, next steps, specialists.

Ask: "May I compile these into `business/cases/<slug>-decision-<date>.md` plus [each specialist file that exists:
`business/market/<slug>-<country>.md`, `business/pricing/<slug>-pricing.md`, `business/marketing/<slug>-marketing.md`,
`business/sales/<slug>-sales.md`]?" naming every path. Write only after the yes (autonomous: write and
`log_decision`). Each file starts with date (from `date +%F`), author agents, decision, source list. If the model ran, the inputs JSON is compiled to `business/cases/<slug>-inputs.json` in the same approved set. If the user declines, nothing under `business/` is written; the verdict already presented stands and the report says "not saved" (working drafts under `production/business/<slug>/` remain). `Grep` for leftover placeholders.

**Checkpoint.** Before the final message, update `production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`: Current task `/team-business <slug> — <verdict>`, Next step = the first hand-off below that applies, plus Blocked on (unreachable sources, a declined write) / Files in progress (the compiled `business/` files) / Open questions; append the Notes line; leave the `Flow:` line and other blocks alone. Still updated when the write was declined (record that nothing was written).

Hand-offs: price accepted → `product-director` sign-off then `pricing-billing-designer`, then `/pricing-check`;
detail plans → `/gtm-plan`, `/marketing-plan`, `/sales-playbook`, `/offer-design`; numeric model →
`/business-case`; sources that were unreachable → rerun the wave or run `/research`; legal/tax →
a qualified advisor. Nothing is published, sent, bought or committed by this skill.

---

## Collaborative Protocol

- **Facts first, price second, plans third** — no wave starts on another wave's missing output; a `BLOCKED` wave is surfaced at once and the pipeline offers to continue with that part marked `NOT RUN`
- **Thresholds are the user's and are set before research**
- **No number from memory**; every row has value + unit + currency, source + tier, date, scope — or is `ASSUMPTION` / `NOT SOURCEABLE`
- **Specialists' conflicting numbers are shown side by side**, never averaged silently
- **Hosted and self-hosted, and countries, are never blended**
- **Not spawned, not run and unreachable are all stated by name** in the output
- **No fabricated quotes, testimonials, survey results or pipeline numbers; no legal, tax or accounting conclusion**
- **Product scope and implemented pricing are not decided here**
