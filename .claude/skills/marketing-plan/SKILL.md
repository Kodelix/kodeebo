---
name: marketing-plan
description: "Marketing plan for a product and period — channel mix with sourced benchmarks or labelled assumptions, content calendar (AR/EN), budget split, CAC targets tied to payback, attribution with product-analytics-engineer, consent rules. Writes business/marketing/marketing-<product>-<period>.md."
argument-hint: "<product> [--period <quarter or dates>] [--market eg|sa|ae|...] [--budget <amount currency>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), Agent, AskUserQuestion, WebFetch, WebSearch, Bash(python3 -I .claude/skills/business-case/references/calc.py), Bash(python3 -I .claude/skills/business-case/references/calc.py *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(date *), Bash(bash "*/.claude/skills/marketing-plan/../../hooks/yaml-helper.sh" resolve_config *)
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

# Marketing Plan

> **Arithmetic.** `calc.py` means `python3 -I .claude/skills/business-case/references/calc.py "<expr>" ...` (arithmetic only: numbers, operators, `sqrt`, `median`, `sample_size`; see the file header). Never run `python3 -c` or a heredoc script; `calc.py` runs without a prompt, anything else asks.

The operating plan under a GTM: **which channels, how much money, what content
on which dates, what each customer may cost, and how we will know.** Work is done
by `marketing-lead`, with `product-analytics-engineer` for attribution and
events, and `privacy-compliance-specialist` for consent facts, under
`.claude/docs/business-research-protocol.md`. Every channel benchmark (CPC, CPM,
audience size, search volume, platform policy) is **sourced with a date or
labelled `ASSUMPTION`**; money is local currency first with USD and a dated rate.

**Output:** `business/marketing/marketing-<product>-<period>.md` (layout and
audit checklist M1–M12 in `references/1-marketing-layout.md`).
**Verdict words (fixed):** `PLAN READY` · `PLAN READY WITH CONDITIONS` ·
`PLAN NOT READY` · `INSUFFICIENT DATA`. Precedence, first match wins:
`PLAN NOT READY` → `INSUFFICIENT DATA` → `PLAN READY WITH CONDITIONS` →
`PLAN READY`.

---

## Phase 1: Scope and Inputs

No product named → ask and stop. Parse period, market(s), budget ceiling.

Read, recording FOUND or ABSENT: `design/product-brief.md`, `PRODUCT.md`,
`business/marketing/gtm-*.md` (segment, positioning, messages, targets),
`business/pricing/*` (ARPA inputs), `business/cases/*` (gross margin, payback
limit, CAC), `business/market/*` (channel and platform data, payment methods),
`business/competitors/*`, the tracking plan (`docs/**/tracking-plan*.md`, from
`.claude/docs/templates/tracking-plan.md`) and `site/` constraints
(`docs/stack-reference/astro/best-practices.md`).

**Insufficient input rule.** No pricing/case input → the **CAC ceiling is `NOT
ASSESSED`** (M1, M4): no CAC target number is stated; the plan may proceed to
channel hypotheses and tests only, verdict `PLAN READY WITH CONDITIONS` at best.
Offer to run `/pricing-strategy` and `/business-case` first (`AskUserQuestion`,
recommended first). No GTM file → ask the user for the segment and messages or
route to `/gtm-plan`; with neither → `INSUFFICIENT DATA — no segment or message
basis`.

Ask: the budget ceiling in local currency, the period, the channels already in
use with their measured results (the user supplies real data; none is invented),
and the owners. A skipped answer is not an answer: re-ask in plain text.

## Phase 2: Plan

Read **`references/1-marketing-layout.md` now** — sections, CAC formula, channel row
fields, budget table, attribution and consent items, checklist M1–M12. Re-read
after compaction. Announce who runs and who does not (a specialist not needed is
named with the reason).

## Phase 3: Spawn

Spawn `marketing-lead` first. Fixed brief; fill only `{…}`:

```text
Marketing plan for /marketing-plan. Read .claude/docs/business-research-protocol.md and
.claude/skills/marketing-plan/references/1-marketing-layout.md first.
Product: {name}   Edition: {hosted | self-hosted}   Market(s): {list}   Period: {dates}
Budget ceiling: {amount currency or "none stated"}   Owners: {user-supplied, or "none yet"}
GTM inputs (segment, positioning, messages, targets): {rows with file paths, or "ABSENT"}
ARPA, gross margin, payback limit, CAC from other files: {rows with paths, or "ABSENT - CAC ceiling NOT ASSESSED"}
Market/platform data on disk: {paths with dates, or "none"}   Measured channel results supplied by the user: {data or "none"}
Look up each channel benchmark and each platform policy on the source's own current page with
WebFetch/WebSearch (record URL, tier, date, country scope); otherwise label ASSUMPTION. Do all budget and
funnel arithmetic with calc.py and show the working. Return the plan text only, no files. Arabic
pieces natively written; claims evidenced; no invented testimonials or case studies; no personal data of
real prospects. Money local currency first, USD with rate, source, date; VAT on media costs stated.
No legal/tax conclusions; partners named only if the user confirmed them.
```

Then, **in one parallel block**, spawn with the returned channel and budget
tables pasted in: `product-analytics-engineer` (UTMs, event names for the
tracking plan, attribution model and blind spots, funnel table, dashboard needs;
self-hosted telemetry stays off), `privacy-compliance-specialist` when personal data in campaigns, email or WhatsApp opt-in, retargeting, consent, or tracking pixels is in scope (the consent and retention
facts that apply, from the authority's text, with the advisor caveat), and
`localization-lead` for the Arabic/English calendar rows. Any not spawned is
named, with its check listed as "not run".

## Phase 4: Audit

Apply M1–M12, each MET / NOT MET / NOT ASSESSED with the reason; show the table. A check whose subject is out of scope (M5 with no paid plan, M6 with no SEO, the consent part of M9) is `N/A — not in scope (stated)`, not NOT ASSESSED, and counts as MET for the verdict.
Also:

1. **Re-run** budget, funnel and CAC arithmetic with `calc.py`; a mismatch is sent back.
2. **Number rows** A / B / C / D / E (as in `/business` Phase 4); E = 0.
3. **Traps:** a global benchmark standing in for a regional one; a platform recommended with no usage source and no flag; CAC chosen, not derived; a budget that does not sum or exceeds the ceiling unflagged; paid spend with no stop rule; a partner named without the user's confirmation; testimonials, case studies or statistics with no row behind them; prospect personal data in a file; tracking in self-hosted installs by default.
4. A specialist that did not run, a platform page that was unreachable: **not run**, never MET. The privacy specialist is spawned only when personal data in campaigns, email or WhatsApp opt-in, retargeting, consent, or tracking pixels is planned; when it is not spawned because none is in scope, say so and score the consent part of M9 `N/A — not in scope` (the "no prospect personal data stored" and "self-hosted telemetry off" parts are still checked).

**Verdict.** Precedence between Phase 1 and this phase: the CAC-ceiling rule below applies only when M1 was assessed. When M1 is `NOT ASSESSED` there is no ceiling to exceed, Phase 1's cap applies (`PLAN READY WITH CONDITIONS` at best), and the other `PLAN NOT READY` triggers (budget, stop rule, consent) still apply. `PLAN NOT READY` — blended base-case CAC exceeds the derived ceiling (M1 assessed), the budget exceeds the user's ceiling unflagged, paid spend has no cap or stop rule, or consent rules are absent where email/retargeting is planned. `INSUFFICIENT DATA` — no segment/message basis, or no data at all to choose channels even as hypotheses. `PLAN READY WITH CONDITIONS` — any check NOT ASSESSED or NOT MET for a stated reason, or channel conversions are assumptions (expected until measured); conditions name the inputs and tests that close them. `PLAN READY` — M1–M12 MET (an `N/A — not in scope` check counts as MET) and the base case clears the CAC ceiling with benchmark rows at tier 1–3 or measured.

## Phase 5: Present and Write

Present: verdict, channel mix, CAC ceiling vs base CAC per channel, budget table,
first month of the calendar, attribution blind spots, conditions.

Ask: "May I write this to `business/marketing/marketing-<product>-<period>.md`?"
Write only after the yes (autonomous: write and `log_decision`). If the user
declines, nothing is written; the verdict already presented stands and the report
says "not saved". The header date comes from `date +%F`. `Grep` for leftover
placeholders.

## Phase 6: Hand-off

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/marketing-plan <product> —
<verdict>`, Next step = the first hand-off item below, plus Blocked on / Files in
progress / Open questions; append the Notes line. INSUFFICIENT DATA, PLAN NOT
READY or a declined write still updates the checkpoint with the blocker.

- Events and UTM scheme → `product-analytics-engineer` for the tracking plan; instrumentation stories via `/create-stories`
- SEO technical items → `astro-specialist` / `web-lead`; Arabic copy → `localization-lead`
- Consent flows in the product → `privacy-compliance-specialist`
- Weekly read-outs back into `business/marketing/` as dated results files; the plan is revised from measured conversions, not opinions
- Nothing is published, bought or sent by this skill

---

## Collaborative Protocol

- **No benchmark, CPC, audience size or platform policy from memory** — sourced with a date or `ASSUMPTION`
- **CAC targets are derived** from ARPA, margin and the payback limit; no inputs, no target
- **A source or specialist that did not run is reported as not run**, never as MET
- **No fabricated testimonials, case studies, results or partner agreements**
- **No personal data of real prospects in the repository**; self-hosted telemetry stays off by default
- **No legal, tax or accounting conclusion** — consent facts from the authority's text, advisor to confirm
- **Spending, posting, emailing and contacting are the user's actions**
