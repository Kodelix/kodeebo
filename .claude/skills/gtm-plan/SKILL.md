---
name: gtm-plan
description: "Go-to-market plan for a product and market — segment, positioning, Arabic/English messaging, channels, launch sequence, targets and owners — with every claim evidenced and every target derived from sized numbers. Writes business/marketing/gtm-<product>-<market>.md."
argument-hint: "<product> [--market eg|sa|ae|gcc-sequence|...] [--edition hosted|self-hosted]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, WebFetch, WebSearch, Bash(python3 -I .claude/skills/business-case/references/calc.py), Bash(python3 -I .claude/skills/business-case/references/calc.py *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(date *), Bash(bash "*/.claude/skills/gtm-plan/../../hooks/yaml-helper.sh" resolve_config *)
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

# GTM Plan

> **Arithmetic.** `calc.py` means `python3 -I .claude/skills/business-case/references/calc.py "<expr>" ...` (arithmetic only: numbers, operators, `sqrt`, `median`, `sample_size`; see the file header). Never run `python3 -c` or a heredoc script; `calc.py` runs without a prompt, anything else asks.

Turns a product, a segment and a market into a **launch plan the user can run**:
who we sell to first, how we position against dated alternatives, what we say in
Arabic and English (and the evidence for each claim), which channels in which
order, a dated launch sequence with go/no-go points, targets derived from the
sized market, and an owner for every row. Work is done by `marketing-lead`
(with `sales-lead` when an enterprise or self-hosted motion is in scope and
`localization-lead` for Arabic/RTL review) under
`.claude/docs/business-research-protocol.md`. It proposes; the user launches.

**Output:** `business/marketing/gtm-<product>-<market>.md` (layout and audit
checklist G1–G11 in `references/1-gtm-layout.md`).
**Verdict words (fixed):** `PLAN READY` · `PLAN READY WITH CONDITIONS` ·
`PLAN NOT READY` · `INSUFFICIENT DATA`. Precedence, first match wins:
`PLAN NOT READY` → `INSUFFICIENT DATA` → `PLAN READY WITH CONDITIONS` →
`PLAN READY`. Checks are MET / NOT MET / NOT ASSESSED.

---

## Phase 1: Scope and Inputs

No product named → ask and stop. Parse market(s) (each market gets its own
sections) and edition (hosted and self-hosted are separate plans).

Read, recording FOUND or ABSENT: `design/product-brief.md` (ICP, positioning,
decision log), `PRODUCT.md` (brand and tone), `docs/ROADMAP.md`,
`business/market/*` (SAM/SOM and verdicts), `business/competitors/*` (dated
captures; `business/competitors/notes/` is excluded — unverified `/business` notes), `business/pricing/*` (price table; the GTM links to it, never restates
it), `business/cases/*` (CAC and payback targets), `business/marketing/*`
(earlier plans).

**Insufficient input rule.** Each ABSENT input makes its checks `NOT ASSESSED —
NO DATA` (list in `references/1-gtm-layout.md`): no brief → G1; no market note →
G2 and G7; no competitor files → G3. Missing market or pricing: `AskUserQuestion`
— run `/market-research` / `/pricing-strategy` first (recommended) or continue
with labelled hypotheses. Continuing keeps the verdict at `PLAN READY WITH
CONDITIONS` at best, and **targets are `NOT ASSESSED` with no SOM**. With no
product brief and no description from the user: `INSUFFICIENT DATA — no ICP`.

Ask (recommended first): launch window, budget ceiling in local currency (if any),
who the owners are (names or roles — the user supplies them; the skill never
invents a person), and the conditions to move from the first market to the next.
A skipped answer is not an answer: re-ask in plain text.

## Phase 2: Plan

Read **`references/1-gtm-layout.md` now** — sections, the audit checklist, the AR/EN
messaging table, owner rule. Re-read after compaction. Announce which specialists
will run and which will not (for example `sales-lead` not spawned: hosted
self-serve only).

## Phase 3: Spawn

Spawn in **one parallel block** (independent given the same inputs):
`marketing-lead` always; `sales-lead` when enterprise/self-hosted is in scope
(motion, owners, partner channel, pipeline entry criteria for the launch).
Fixed brief; fill only `{…}`:

```text
GTM plan for /gtm-plan. Read .claude/docs/business-research-protocol.md and
.claude/skills/gtm-plan/references/1-gtm-layout.md first.
Product: {name}   Market(s): {list}   Edition: {hosted | self-hosted | both, separate}
ICP and positioning from the brief: {text, or "ABSENT"}
Brand and tone (PRODUCT.md): {lines, or "ABSENT"}
Market note rows (SAM/SOM, verdict, buyer, channel, payment, regulatory facts): {paths and key rows, or "ABSENT"}
Competitor captures (dated): {paths, or "none"}   Price table: {rows, or "ABSENT - do not restate prices"}
CAC / payback target: {from business/cases, or "ABSENT"}
User inputs: window {dates}, budget ceiling {X}, owners {names or roles}, market-to-market conditions {text}
Return the plan in the layout of references/1-gtm-layout.md, text only, no files. Messages
natively written in Arabic and English with the evidence for each claim; no invented
testimonials, logos, case studies, review scores or statistics. Targets by formula, low/base/high,
conversions labelled ASSUMPTION. Money local currency first, USD with rate, source, date; VAT status.
No legal/tax conclusions. Mark positioning "proposal - product-director owns the positioning of record".
```

Then spawn `localization-lead` for the Arabic and English message table (native
register, RTL and mixed-direction text, numerals and date format, currency
formatting) with the table pasted in — it needs the table, so it runs after
`marketing-lead`. Not spawned → say "Arabic review: not run" in the file.

## Phase 4: Audit

Apply G1–G11 from `references/1-gtm-layout.md`, each MET / NOT MET / NOT ASSESSED
with the reason; show the table. Also:

1. **Re-run the arithmetic** for targets and funnel with `calc.py`.
2. **Number rows** counted A / B / C / D / E (as in `/business` Phase 4); E = 0.
3. **Claims audit:** every claim in the message table points at a measurement or a source, or is removed; search the draft for testimonials, logos, "customers say", review scores and statistics with no row behind them.
4. **Owners:** any row without a user-supplied owner is `UNASSIGNED` (G8 NOT MET).
5. A specialist or check that did not run (no `localization-lead`, an unreachable source) is listed as **not run**.

**Verdict.** `PLAN NOT READY` — a message makes a claim the product cannot support or evidence does not back, a target exceeds the SOM base case **without a flag**, a launch date precedes a go/no-go prerequisite, or the plan exceeds the user's stated budget ceiling. `INSUFFICIENT DATA` — no ICP, or no basis for segment and targets even as labelled hypotheses. `PLAN READY WITH CONDITIONS` — any check NOT ASSESSED or NOT MET for a stated reason (unassigned owners, targets resting on assumptions, Arabic review not run), or a target above the SOM base case that **is** flagged (G7 MET with the flag; the condition is the evidence or test that would justify the stretch); conditions are listed with the input that closes each. `PLAN READY` — G1–G11 MET and targets derive from tier 1–3 inputs.

## Phase 5: Present and Write

Present: verdict, recommendation, segment and positioning, the message table,
launch sequence, targets (low/base/high), unassigned owners, the conditions.

Ask: "May I write this to `business/marketing/gtm-<product>-<market>.md`?" Write
only after the yes (autonomous: write and `log_decision`). If the user declines,
nothing is written; the verdict already presented stands and the report says "not
saved". The header date comes from `date +%F`. `Grep` for leftover placeholders.

## Phase 6: Hand-off

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/gtm-plan <product> <market>
— <verdict>`, Next step = the first hand-off below that applies (a concrete
command), plus Blocked on / Files in progress / Open questions (unassigned
owners, unmet conditions); append the Notes line. Still updated when the user
declines the write (record nothing written and why) or the verdict is
`NOT ASSESSED`.

- Channel budgets, calendar, CAC and attribution → `/marketing-plan`
- Sales motion and enterprise terms → `/sales-playbook`; unit economics behind the targets → `/business-case`
- Positioning changes of record, edition or ICP changes → an approval request to `product-director`
- Site pages, hreflang, structured data → `web-lead` / `astro-specialist` stories via `/create-stories`; Arabic copy → `localization-lead`
- Launch readiness checklist → `/launch-checklist` with `release-manager`
- Nothing is published or sent by this skill

---

## Collaborative Protocol

- **Every claim has evidence or is removed**; no fabricated testimonials, logos, case studies, review scores or statistics
- **Targets are derived from the sized market**; with no SOM they are `NOT ASSESSED`, not guessed
- **Owners are the user's** — an unassigned row stays `UNASSIGNED`
- **Hosted and self-hosted plans are never blended**; markets are not blended
- **A check or specialist that did not run is reported as not run** — never as MET
- **The positioning of record is `product-director`'s**; this plan proposes
- **No legal, tax or accounting conclusion; nothing is published, sent or spent by this skill**
