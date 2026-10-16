---
name: market-research
description: "Bottom-up market sizing (TAM/SAM/SOM) per country — never summed blindly — plus segments, buyer behaviour, payment and VAT/e-invoicing facts for Egypt and GCC/MENA, every number sourced and dated. Writes business/market/<topic>.md."
argument-hint: "<topic or question> [--country eg,sa,ae,...] [--segment <name>] [--edition hosted|self-hosted]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, WebFetch, WebSearch, Bash(python3 -I .claude/skills/business-case/references/calc.py), Bash(python3 -I .claude/skills/business-case/references/calc.py *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(date *), Bash(bash "*/.claude/skills/market-research/../../hooks/yaml-helper.sh" resolve_config *)
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

# Market Research

> **Arithmetic.** `calc.py` means `python3 -I .claude/skills/business-case/references/calc.py "<expr>" ...` (arithmetic only: numbers, operators, `sqrt`, `median`, `sample_size`; see the file header). Never run `python3 -c` or a heredoc script; `calc.py` runs without a prompt, anything else asks.

Sizes a market **bottom-up** (count of organisations × share with the problem ×
reachable share × annual price), per country, and gathers the buyer, channel,
payment and regulatory facts a plan needs — all under
`.claude/docs/business-research-protocol.md`: every number has value + unit +
currency, source + tier, date, scope; what cannot be found is `NOT SOURCEABLE`
with a transparent low/base/high estimate. Work is done by `market-researcher`.

**Output:** `business/market/<topic>.md` (layout in `references/2-note-template.md`).

**Verdict words (fixed), per country and overall:** `SIZED` · `SIZED WITH
ASSUMPTIONS` · `INSUFFICIENT DATA`. Precedence (worst wins): `INSUFFICIENT DATA`
→ `SIZED WITH ASSUMPTIONS` → `SIZED`. `INSUFFICIENT DATA` is the "could not
assess" value and outranks the pass values. The overall verdict is the worst
country verdict, and the report names each country's.

---

## Phase 1: Scope and Inputs

No argument → ask for the topic and stop. Parse: countries (each is sized on its
own), segment, edition (hosted and self-hosted are **never blended**), horizon.

Read, recording FOUND or ABSENT: `design/product-brief.md` (ICP, jurisdiction,
positioning), `docs/ROADMAP.md`, existing `business/market/*`,
`business/competitors/*`, `business/pricing/*` (price points used as `P`), and
`docs/research/`. An existing sourced row is reused with its date and re-verified
when older than the horizon the user states (ask for it if none).

**Insufficient input rule.** With no ICP/segment definition anywhere and none
supplied by the user, there is nothing to count: the outcome is `INSUFFICIENT
DATA — no segment defined`, naming `/brainstorm` / `product-director`. With no
price point for `P` the price row is an `ASSUMPTION` taken from competitor
captures if `business/competitors/` has them (not `notes/`), else `NOT SOURCEABLE`; either keeps
the country below `SIZED`.

Ask (`AskUserQuestion`, 2–4 options, recommended first) only what changes the
work: which countries first, the unit of count to size (for example firms with
≥ N staff vs registered firms), the staleness horizon, and which price basis to
use. A skipped answer is not an answer: re-ask in plain text and wait.

## Phase 2: Plan the Research

Read **`references/1-sizing-method.md` now** — the unit-definition rule, the
formula, per-country separation, the top-down cross-check rule, the buyer
behaviour table and the `NOT SOURCEABLE` procedure. Re-read after compaction.

Announce the plan in one block: countries × quantities to size, the source
families to try first per country (national statistics office / ministry /
regulator / central bank — tier 1), and the data most likely to be missing.

## Phase 3: Spawn the Researchers

Spawn one `market-researcher` per country via `Agent`, **all in one parallel
block** (countries are independent). One country → one agent. Fixed brief; fill
only the `{…}` slots:

```text
Market research for /market-research. Read .claude/docs/business-research-protocol.md
and .claude/skills/market-research/references/1-sizing-method.md first.
Country: {country}   Segment: {segment}   Edition: {hosted | self-hosted}   Horizon: {horizon}
Product context: {ICP and price basis from the files read, or "ABSENT"}
Reusable sourced rows on disk (with capture dates): {paths, or "none"}
Return a market note for this country in the layout of
.claude/skills/market-research/references/2-note-template.md, text only (do not write files):
findings table, unit definition in words, formula with low/base/high computed with
calc.py (show the working), buyer/channel/payment/regulatory tables, NOT SOURCEABLE
entries with what was searched, assumptions and gaps with how to close each, and
which sources were paywalled or unreachable. Do not size from a global percentage.
No fabricated survey, interview or quote. No legal/tax conclusion.
```

## Phase 4: Verify What Came Back

For each country note:
1. **Re-run the arithmetic** with `calc.py` from the note's own input rows; a mismatch is sent back.
2. **Count rows:** A (four fields, tier 1–3), B (tier 4–5 lead), C (`ASSUMPTION`), D (`NOT SOURCEABLE`), E (missing a field — a defect, fixed or demoted to C). Show "Rows: N — A a, B b, C c, D d, E 0".
3. **Check the traps:** a unit definition stated; no global percentage standing as TAM; no regional figure standing in for a country figure; no country summed with another without the overlap and definitions (an `ILLUSTRATIVE SUM` only on request); USD never alone; VAT status stated; FX rate has source and date; regulatory rows have an effective date and the advisor caveat; no personal data of real people; no quote or survey result without provenance.
4. **Assign the verdict per country** with the rules at the end of `references/1-sizing-method.md`; the overall verdict is the worst.
5. A source a researcher could not open is listed as **not run — unreachable/paywalled**, never as "nothing found".

## Phase 5: Present and Write

Present in conversation: verdict per country, the sizing table (low/base/high,
local currency first with USD, rate, source, date), the biggest assumptions, the
gaps and the cheapest research that would close each.

Ask: "May I write this to `business/market/<topic>.md`?" (name every file when
there are several; when the user chose a dated section appended to an existing
note instead of a new dated file, name that note and use `Edit` to append only —
never rewrite it). Write only after the yes; autonomous mode writes and records
the choice with `log_decision`. If the user declines, nothing is written; the
verdicts already presented stand and the report says "not saved". The header date
comes from `date +%F`. After writing, `Grep` the file for leftover
placeholders (`[`…`]`, `TODO`, `TBD`) and report the result.

## Phase 6: Hand-off

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/market-research <topic> —
<verdict>`, Next step = the first hand-off item below that applies, plus Blocked
on / Files in progress / Open questions; append the Notes line. INSUFFICIENT
DATA or a declined write still updates the checkpoint with the blocker.

- Competitor prices or plan limits missing → `/competitor-analysis`
- Price points → `/pricing-strategy`; a go/no-go on entering a country → `/business` or `/team-business`
- Segment/ICP of record disagrees with the findings → an approval request to `product-director`; this skill changes no brief
- Privacy-law or data-residency interpretation → `privacy-compliance-specialist`; tax/e-invoicing interpretation → a qualified advisor
- `INSUFFICIENT DATA` countries → name the research that closes it (interview count, price test, distributor calls) and offer to scope it; nothing is contacted by this skill

---

## Collaborative Protocol

- **No count, rate, price, FX or regulation from memory** — fetched and cited this run, reused from a dated file, or `NOT SOURCEABLE`
- **A source that was unreachable, paywalled or blocked is reported as such** — never quoted from a snippet and never counted as "no data exists"
- **A country with no sourced count is `INSUFFICIENT DATA`**, not a small number
- **Never sum countries or editions silently**; never use a regional figure as a country figure
- **No fabricated survey, interview or testimonial**; interviews are recorded only if they happened, with count and role mix
- **Never bypass logins or paywalls, or contact companies**; competitors and buyers are companies/roles, not named individuals
- **No legal, tax or accounting conclusion**
