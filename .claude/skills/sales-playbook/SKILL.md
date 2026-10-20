---
name: sales-playbook
description: "Sales playbook for a product — motion by ACV (self-serve, inside, enterprise), qualification, pipeline stages with conversion assumptions, enterprise terms (SLA, data residency, self-hosted licence, payment terms), partners/resellers, objection handling, proposal template. Writes business/sales/."
argument-hint: "<product> [--edition hosted|self-hosted|both] [--market eg|sa|ae|...] [--scope full|motion|terms|proposal]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), Agent, AskUserQuestion, WebFetch, WebSearch, Bash(python3 -I .claude/skills/business-case/references/calc.py), Bash(python3 -I .claude/skills/business-case/references/calc.py *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(date *), Bash(bash "*/.claude/skills/sales-playbook/../../hooks/yaml-helper.sh" resolve_config *)
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

# Sales Playbook

> **Arithmetic.** `calc.py` means `python3 -I .claude/skills/business-case/references/calc.py "<expr>" ...` (arithmetic only: numbers, operators, `sqrt`, `median`, `sample_size`; see the file header). Never run `python3 -c` or a heredoc script; `calc.py` runs without a prompt, anything else asks.

How the product is actually sold: **which motion for which deal size, how a lead
is qualified, how a deal moves, what we can and cannot promise an enterprise
buyer, who sells through partners, what the real objections are, and what a
proposal contains.** Work is done by `sales-lead` under
`.claude/docs/business-research-protocol.md`; before it runs, the people who can
*confirm* an enterprise term are asked (`sre-lead`, `licensing-specialist`,
`security-lead`, `privacy-compliance-specialist`) — the playbook never promises
what engineering has not confirmed.

**Outputs:** `business/sales/<product>-playbook.md` and
`business/sales/<product>-proposal-template.md` (layout and audit S1–S12 in
`references/1-playbook-layout.md`; proposal in `references/2-proposal-template.md`), limited by `--scope` (below). A re-run over an existing file never overwrites it: see Phase 5.
**Verdict words (fixed):** `PLAN READY` · `PLAN READY WITH CONDITIONS` ·
`PLAN NOT READY` · `INSUFFICIENT DATA`. Precedence, first match wins:
`PLAN NOT READY` → `INSUFFICIENT DATA` → `PLAN READY WITH CONDITIONS` →
`PLAN READY`.

---

## Phase 1: Scope and Inputs

No product named → ask and stop. **`--scope`** (default `full`) decides what is produced; every other section and check is `N/A — out of scope (stated)` and counts as MET:

| `--scope` | Files written | Layout sections produced | Checks active |
|---|---|---|---|
| `full` | playbook + proposal template | 1–14 | S1–S12 |
| `motion` | playbook | 1–5, 9, 10, 13, 14 | S1, S2, S3, S7, S8, S10, S11, S12 |
| `terms` | playbook | 1, 2, 6, 7, 8, 11, 13, 14 | S4, S5, S6, S10, S11, S12 |
| `proposal` | proposal template | the nine template sections (reads an existing playbook's `OFFERED` terms and prices; none found → slots only, terms "subject to written engineering confirmation") | S9, S10, S11, S12 |

Phase 2 runs only for scopes with enterprise or self-hosted terms (`full`, `terms`, and `proposal` when it cites terms). Hosted and self-hosted get separate motions,
cycles, win rates and support loads; **never blended in one forecast**.

Read, recording FOUND or ABSENT: `design/product-brief.md` (ICP), `.claude/docs/standing-decisions.md`
(hosted + self-hosted, licence decisions), `business/pricing/*` (prices, **floor
price**, licence terms), `business/cases/*` (CAC ceiling, margin, payback limit),
`business/market/*` (buyer roles, procurement, payment methods, tax facts),
`business/competitors/*`, `business/marketing/*`, the licence-model artifact,
`docs/architecture/slos.md` (SLA basis), the backup/DR design, and existing
`business/sales/*`.

**Insufficient input rule.** ABSENT price file **with a price basis supplied by the user** (labelled `ASSUMPTION`) → ACV and the discount-authority
floor are `NOT ASSESSED` (S1, S6): no ACV is invented and no motion is chosen from
a remembered threshold. ABSENT price file **and no price basis from the user** → `INSUFFICIENT DATA — no price basis`. ABSENT SLO/backup/licence design → the matching enterprise
terms are `NEEDS ENGINEERING APPROVAL`, never `OFFERED`. No brief and no ICP from
the user → `INSUFFICIENT DATA — no ICP`. Offer `/pricing-strategy` and
`/business-case` first (`AskUserQuestion`, recommended first) or continue with
labelled assumptions (verdict `PLAN READY WITH CONDITIONS` at best).

Ask: markets, the real conversations the user can supply notes or counts from
(none → objections are hypotheses), whether partners exist (names only on the
user's confirmation), owners (user-supplied roles). A skipped answer is not an
answer: re-ask in plain text.

## Phase 2: Confirm What Can Be Promised (enterprise / self-hosted in scope)

Read **`references/1-playbook-layout.md` now** (sections, term statuses
`OFFERED` / `NEEDS ENGINEERING APPROVAL` / `REFUSED`, checklist S1–S12) and
`references/2-proposal-template.md`. Re-read after compaction.

Spawn in **one parallel block** (independent), each with one narrow question and
the evidence paths it should cite — SLA/RPO/RTO feasibility (`sre-lead`),
licence term, bounds, offline grace, update window, expiry (`licensing-specialist`),
questionnaire-level security answers that can be evidenced (`security-lead`),
residency options and subprocessors (`privacy-compliance-specialist`). Each
returns, per item: `can promise today` + the file, ADR or test that proves it /
`needs work` + what / `not planned`. **No evidence → "not confirmed".** Agents not
spawned (scope excludes enterprise) are named with "enterprise terms: not in
scope".

## Phase 3: Spawn the Sales Lead

Spawn `sales-lead` via `Agent`. Fixed brief; fill only `{…}`:

```text
Sales playbook for /sales-playbook. Read .claude/docs/business-research-protocol.md and
.claude/skills/sales-playbook/references/1-playbook-layout.md and 2-proposal-template.md first.
Product: {name}   Edition(s): {hosted | self-hosted, separate}   Market(s): {list}
ICP: {text, or "ABSENT"}   Price table and floor: {rows, or "ABSENT"}   CAC ceiling / payback limit: {rows, or "ABSENT"}
Market facts (buyer roles, procurement, payment, tax): {rows with sources and dates, or "none"}
Engineering confirmations: {the Phase 2 answers verbatim, or "enterprise not in scope"}
User-supplied conversation data: {counts and notes, or "none - objections are HYPOTHESIS"}
Partners confirmed by the user: {list or "none"}   Owners: {roles or "none yet"}
Scope: {full | motion | terms | proposal} - return only that scope's documents/sections as text, no files. Motion by the rule (selling cost <= CAC ceiling), not by a remembered
cut-off. Every enterprise term gets a status and a source; no source means NEEDS ENGINEERING APPROVAL.
Forecast low/base/high computed with calc.py; example deals marked ILLUSTRATIVE; no invented customers,
references, logos, quotes or pipeline numbers. VAT/e-invoicing from the authority's page, dated, with the
advisor caveat. Money local currency first, USD with rate, source, date. No legal/tax conclusions; contracts
are for the user's legal advisor.
```

## Phase 4: Audit

Apply S1–S12, each MET / NOT MET / NOT ASSESSED with the reason; show the table. A check whose subject is out of scope (S4 when neither enterprise nor self-hosted is in scope) is `N/A — out of scope (stated)`, not NOT ASSESSED, and counts as MET for the verdict. Also:

1. **Re-run** ACV, selling-cost-vs-ceiling and forecast arithmetic with `calc.py`.
2. **Terms audit:** list every enterprise term with status and source; a term marked `OFFERED` without a cited path is demoted to `NEEDS ENGINEERING APPROVAL`; a promise of an unshipped capability, a residency region or an SLA is removed.
3. **Provenance audit:** every objection is `OBSERVED` / `PUBLISHED` / `HYPOTHESIS`; any customer name, reference, logo, win story, quote or pipeline figure not supplied by the user is removed.
4. **Number rows** A / B / C / D / E (as in `/business` Phase 4); E = 0.
5. Specialists that did not run: **not run**, with the terms that depend on them left unconfirmed.

**Verdict — computed after the audit's fixes, demotions and removals** (items 1–5 above and the S1–S12 table as corrected), never from the sales-lead draft. `PLAN NOT READY` — after those corrections, an unconfirmed term is still presented as `OFFERED`, a motion's selling cost exceeds the CAC ceiling in the base case, a discount path goes below the floor, or invented references/pipeline are still present (a term demoted and a reference removed by the audit no longer count). `INSUFFICIENT DATA` — no ICP, or no price basis anywhere (file or user), so no motion can be chosen even as a labelled hypothesis. `PLAN READY WITH CONDITIONS` — any check NOT ASSESSED or NOT MET for a stated reason (conversions are assumptions, terms await engineering confirmation, owners unassigned, objections are hypotheses); conditions say how each is closed (first N deals, confirmations in writing). `PLAN READY` — S1–S12 MET (an `N/A` check counts as MET) and drivers tier 1–3 or measured, so a hosted-only playbook can reach it.

## Phase 5: Present and Write

Present: verdict, motion table, qualification summary, pipeline and forecast,
enterprise-terms table (offered / needs approval / refused), objection table,
conditions.

Ask: "May I write `business/sales/<product>-playbook.md` and
`business/sales/<product>-proposal-template.md`?" (only the files the `--scope` produces). **A re-run never overwrites or edits** (its only `Edit` grant is the session checkpoint): if either file exists, the new file is `business/sales/<product>-playbook-<date>.md` / `<product>-proposal-template-<date>.md` (`<date>` from `date +%F`; a same-day collision adds `-2`), its header carries `Supersedes: <path of the newest existing file>`, and the question names those paths. Write only after the yes
(autonomous: write and `log_decision`). If the user declines, nothing is written;
the verdict already presented stands and the report says "not saved". The header
date comes from `date +%F`. `Grep` for leftover placeholders other
than the template's deliberate `{slot}` markers.

## Phase 6: Hand-off

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/sales-playbook <product> —
<verdict>`, Next step = the first hand-off below that applies, plus Blocked on
(e.g. terms awaiting engineering confirmation) / Files in progress / Open
questions; append the Notes line. Still updated when the write was declined
(record that nothing was written).

- Terms marked `NEEDS ENGINEERING APPROVAL` → the confirmers named, as tasks for the user to put to them
- Questionnaire/RFP library → built later from evidence, with `security-lead` and `privacy-compliance-specialist`
- Discount floors or licence prices that need to change → `/pricing-strategy`; plan or edition changes → `product-director`
- Closed-deal hand-off fields → `customer-success`
- Sending proposals, contacting prospects and partners, and signing are the user's actions

---

## Collaborative Protocol

- **Nothing is promised that engineering has not confirmed in writing** — SLA, residency, certifications and features included
- **No fabricated customers, references, logos, quotes, win stories or pipeline numbers**; examples are `ILLUSTRATIVE`
- **Motion is chosen by the selling-cost-versus-CAC-ceiling rule**, not by a remembered ACV cut-off
- **Hosted and self-hosted are never blended**
- **A specialist or check that did not run is reported as not run**, never as MET
- **No personal data of real prospects in the repository; no cold outreach from scraped data**
- **No legal, tax or accounting conclusion** — contract text goes to the user's legal advisor
