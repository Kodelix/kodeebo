---
name: business
description: "Business entry point: ask any business question in plain Arabic or English (market, competitors, pricing, offer, go-to-market, marketing, sales, business case) and get ONE sourced answer from the business team — recommendation, numbers table, assumptions and gaps, next steps."
argument-hint: "<business question in Arabic or English>"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, WebFetch, WebSearch, Bash(python3 -I .claude/skills/business-case/references/calc.py), Bash(python3 -I .claude/skills/business-case/references/calc.py *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(date *), Bash(bash "*/.claude/skills/business/../../hooks/yaml-helper.sh" resolve_config *)
model: opus
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

`workflow` and `review_mode` do **not** relax this skill: there is no business
director gate, so nothing here is skipped at `solo` or `minimal`. Sourcing is
required at every tier.

# Business

The single front door for business questions. The user asks in plain words; this
skill classifies the question, runs the specialists who own the facts
(`market-researcher`, `pricing-strategist`, `marketing-lead`, `sales-lead`),
has `business-director` consolidate, and returns **one answer in the protocol's
shape**: recommendation → numbers table → assumptions and gaps → next steps
(`.claude/docs/business-research-protocol.md`). Markets: Egypt and GCC/MENA.
Global figures appear only as labelled comparisons.

**Reply language.** Answer in the language of the question. File artifacts are
written in English, with Arabic text only where the content itself is Arabic
(messages, copy). Numbers keep Latin digits and ISO currency codes.

**Verdict words (fixed):** `RECOMMEND` · `RECOMMEND WITH CONDITIONS` ·
`DO NOT RECOMMEND` · `INSUFFICIENT DATA`. Outcome when the question belongs
elsewhere: `ROUTED` (no verdict). Precedence, first match wins:
`DO NOT RECOMMEND` → `INSUFFICIENT DATA` → `RECOMMEND WITH CONDITIONS` →
`RECOMMEND`. `INSUFFICIENT DATA` is the "could not assess" value: it outranks
both recommendations and sits below a known failure.

**It advises; the user decides.** It never contacts anyone, publishes, commits
spend, edits product code or specs, or draws a legal, tax or accounting
conclusion (cite the official rule, name a qualified advisor).

---

## Phase 1: Understand the Question

No argument → ask what the business question is (`AskUserQuestion`: free text
via "Other"), then stop. Do not guess one.

Read, recording each as FOUND or ABSENT (never "assumed present"):
`design/product-brief.md` (ICP, positioning, decision log),
`docs/ROADMAP.md` (business model: annual subscription, one-time licence,
hosted + self-hosted), the pricing model (`design/specs/pricing-model.md` — the
canonical path; if absent, `Glob design/**/pricing-model*.md` and name the
non-canonical location in the answer), and existing files under `business/` (`market/`, `competitors/`, `pricing/`,
`marketing/`, `sales/`, `cases/`) and `docs/research/`. A sourced fact already on
disk is reused with its date, and **re-verified if older than the horizon the
user states** — ask for the horizon if none is stated.

**Insufficient input rule.** If the question turns on a product, ICP or edition
that none of those files define and the user cannot supply, the outcome is
`INSUFFICIENT DATA` naming the missing input and the skill that produces it
(`/brainstorm` or `product-director` for the ICP). Do not invent a product to
answer about.

## Phase 2: Classify and Route

**Read `references/1-routing.md` now and follow it** — classes, the out-of-scope
table, specialist waves and save paths. Read it again if the conversation was
compacted or resumed during this phase.

State in one line: the classes found, the specialists that will run, the ones
that will **not** run and why (a skipped specialist announces itself).

- Whole question out of scope → outcome `ROUTED`; stop after naming the owner.
- Part out of scope (for example a price question that also asks to change the
  edition split) → answer the business part, mark the rest "routed to
  `product-director`" in the answer.
- Three or more specialists needed → offer `/team-business`
  (`AskUserQuestion`: switch / continue answer-only with a narrower scope).

Ask only what changes the answer (`AskUserQuestion`, 2–4 options, recommended
first): country or countries, edition (hosted / self-hosted — **never blended**),
segment, decision deadline, and any threshold the user already holds (a margin
floor, a payback limit, a budget cap). Thresholds are set **before** research so
the verdict is not fitted to the result. A skipped or empty answer is not an
answer: re-ask in plain text.

## Phase 3: Run the Specialists

Spawn the wave members from the routing table via `Agent`, independent members
in one parallel block. Send a fixed brief; fill only the `{…}` slots:

```text
Business question: {question, verbatim, in the user's language}
Classes: {classes}   Countries: {list}   Edition: {hosted | self-hosted | both, separate}
Product context: {ICP, positioning and prices from the files read — or "ABSENT"}
Already sourced on disk (reuse, note date): {paths and their capture dates}
User thresholds: {margin floor, payback limit, budget cap — or "none stated"}
Read first: .claude/docs/business-research-protocol.md. Every number carries
value+unit+currency, source link+tier, date, scope. Missing data is
"NOT SOURCEABLE — <searched>" plus a low/base/high range with formula and labelled
assumptions. Local currency first, USD beside it with the FX rate, its source and
date; say whether prices include VAT. No fabricated quotes, testimonials, survey or
interview results. No legal/tax conclusions. Return text only; do not write files.
Return: findings table (Metric | Value | Source+tier | Date | Scope), assumptions
and gaps with how to close each, what you could not reach (paywalled or blocked).
```

Later waves also receive the earlier waves' tables, not a path they must re-read.
If an agent cannot be spawned, say why and the answer's "Specialists consulted"
line says which part this session did itself.

Then spawn `business-director` once with every specialist's returned table and
ask it for the consolidated answer: options on one table when a choice is asked,
conflicting numbers **side by side with the reason for the choice** (never
averaged), the three inputs that move the answer most varied by ±20 %, and the
cheapest test that would prove the recommendation wrong with a decision
threshold set before the test.

## Phase 4: Audit Before You Answer

Read the consolidated draft and count its numbers table rows:

| Class | Meaning |
|---|---|
| A | all four fields present, source tier 1–3 |
| B | four fields present, tier 4–5 (a lead — cannot drive the recommendation) |
| C | labelled `ASSUMPTION`, with how to close it |
| D | `NOT SOURCEABLE`, with what was searched and a range |
| E | missing a field — a defect |

Rules: every E row is fixed (go back to the agent) or demoted to C; a recommendation
that rests on a B row is demoted to C; USD-only money, an unlabelled
VAT status, a competitor price without a capture date, a global figure standing
in for a regional one, and any customer quote, testimonial or survey result with
no stated provenance are each sent back. Report the tally in the answer
("Rows: N — A a, B b, C c, D d, E 0"). A check not run (an agent that failed,
a source unreachable) is listed as **not run**, never as clean.

Name the **drivers** — the numbers the recommendation turns on — and choose the
verdict from them:

- `DO NOT RECOMMEND` — the sourced or base-case numbers fail a threshold the user
  set (or a protocol boundary), whatever else is unknown.
- `INSUFFICIENT DATA` — a driver is D with no defensible range, the product/ICP
  is ABSENT, or a needed specialist did not run.
- `RECOMMEND WITH CONDITIONS` — a driver is C or a range, or the recommendation
  flips under the ±20 % sensitivity; the condition is the cheapest test and its
  threshold.
- `RECOMMEND` — every driver is A, and the recommendation holds under the
  sensitivity.

## Phase 5: The Answer

Return, in this order and no other (`business-research-protocol.md` →
"What business agents deliver"):

1. **Verdict and recommendation** — the verdict word, then one paragraph.
2. **Numbers table** — Metric | Value + unit + currency | Source (tier) | Date | Scope; the tally line under it. Options and sensitivity here when a choice was asked.
3. **Assumptions and gaps** — each with how to close it (a survey, a pilot, an interview count, a price test).
4. **Next steps** — action — owner — date: concrete, for example "2-week price test at EGP X vs Y, N visitors per arm". Owners are roles the user confirms; dates are proposed, not promised.
5. **Specialists consulted, not run, not researched, unreachable sources** — and routed items.

Then ask: "May I save this answer to `business/<folder>/<slug>-<date>.md`?"
(path from `references/1-routing.md`, including `business/competitors/notes/` for a
competitor-dominant answer; header with date, author agents, question, source list). Write only after the yes; autonomous mode writes and records the
choice with `log_decision`. A competitor-dominant save is labelled a `/business` note, not a verified capture, and the offer recommends `/competitor-analysis` for the full capture.

## Phase 6: Follow-ups

**Checkpoint.** If the answer was saved or the verdict changes what happens next,
update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/business <question> —
<verdict>`, Next step = the first follow-up below (a concrete command), plus
Blocked on / Files in progress / Open questions; append the Notes line. Still
updated when the user declines the save (record nothing written and why) or the
verdict is NOT ASSESSED.

Suggest by class, only the ones that apply: `/market-research`,
`/competitor-analysis`, `/pricing-strategy` → `product-director` sign-off →
`pricing-billing-designer` → `/pricing-check`, `/offer-design`, `/gtm-plan`,
`/marketing-plan`, `/sales-playbook`, `/business-case`, `/team-business`.

---

## Collaborative Protocol

- **Never state a market figure, price, fee, tax rate, exchange rate or regulation from memory** — it is sourced in this run, reused from a dated file, or `NOT SOURCEABLE`
- **A specialist or source that did not run is reported as not run** — never as clean or as "nothing found"
- **Numbers are shown with provenance or not at all**; an assumption is labelled, never promoted to a fact by repetition
- **No fabricated customer quotes, testimonials, survey results or benchmarks**; competitors are companies, not named individuals
- **Self-hosted and hosted economics are never blended**
- **Product scope and implemented pricing are not decided here** — route to `product-director` / `pricing-billing-designer`
- **Nothing is sent, published, bought or committed** — those are the user's actions
