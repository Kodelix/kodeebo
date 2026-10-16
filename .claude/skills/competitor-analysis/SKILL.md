---
name: competitor-analysis
description: "Competitor files with dated price captures — one file per competitor in business/competitors/ with plans, limits, billing, local payments, Arabic/RTL, self-hosted, data residency, reviews — plus a comparison matrix. Every field marked VERIFIED-ON-SITE or THIRD-PARTY."
argument-hint: "<competitor names | category> [--country eg,sa,ae,...] [--refresh] [--horizon <days>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, WebFetch, WebSearch, Bash(python3 -I .claude/skills/business-case/references/calc.py), Bash(python3 -I .claude/skills/business-case/references/calc.py *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(date *), Bash(bash "*/.claude/skills/competitor-analysis/../../hooks/yaml-helper.sh" resolve_config *)
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

# Competitor Analysis

> **Arithmetic.** `calc.py` means `python3 -I .claude/skills/business-case/references/calc.py "<expr>" ...` (arithmetic only: numbers, operators, `sqrt`, `median`, `sample_size`; see the file header). Never run `python3 -c` or a heredoc script; `calc.py` runs without a prompt, anything else asks.

Builds the competitor record the pricing, positioning and sales work stands on:
**one file per competitor** under `business/competitors/` with the fields the
protocol lists (`business-research-protocol.md` → "Competitor analysis"), each
**dated and marked** `VERIFIED-ON-SITE` (read on the vendor's own domain in this
run) or `THIRD-PARTY` (with source and tier), then a **comparison matrix**.
Work is done by `market-researcher`.

**Outputs:** `business/competitors/<slug>.md` per company and
`business/competitors/comparison-matrix.md`.
**Verdict words (fixed):** `COMPLETE` · `COMPLETE WITH GAPS` · `INSUFFICIENT DATA`.
Precedence (per competitor): `INSUFFICIENT DATA` → `COMPLETE WITH GAPS` →
`COMPLETE`; the overall roll-up has one exception, set out in Phase 4 (overall
`INSUFFICIENT DATA` only when no competitor has a verified capture).
`COMPLETE` requires every in-scope competitor to have a `VERIFIED-ON-SITE` price
capture (or an explicit vendor "contact sales") and every other field marked;
`INSUFFICIENT DATA` means no in-scope competitor yielded a verified capture, so a
price corridor cannot be stated. A field that could not be read is
`NOT CAPTURED`, never an inherited or remembered value.

---

## Phase 1: Scope

No argument → ask which competitors or which category, then stop.

Read, recording FOUND or ABSENT: `design/product-brief.md` (segment, positioning,
named alternatives), existing `business/competitors/*` (to refresh, not
duplicate; **`business/competitors/notes/` is excluded** — `/business` notes are not
verified captures and are neither a refresh base nor evidence), `business/market/*`, `business/pricing/*`.

**Category given, no names.** Run `WebSearch` for candidates in the segment and
countries (queries contain no confidential data and no unreleased pricing), and
present the list with each candidate's own URL and why it qualifies
(`AskUserQuestion`: pick from the list, add names; recommended first). Candidates
from tier 4–5 sources are leads; the user confirms the list before capture.
Competitors are companies; no individuals are researched.

Ask: countries to capture (prices can differ per country), staleness horizon
(`--horizon`; if the user has none, propose 90 days and label it a studio
convention), `--refresh` or new. A skipped answer is not an answer: re-ask in
plain text.

## Phase 2: Plan and Announce

Read **`references/1-competitor-file.md` now** (marks, capture rules, file
layout, staleness) and **`references/2-matrix.md`** (matrix layout). Re-read
them after compaction.

Announce: competitors × countries to capture, which existing files are refreshed
(new capture appended to the change log, older captures kept), and the capture
limits: public pages only, no logins, no paywall bypass, no scraping beyond
reading the pages a visitor can open, no contact with the vendor.

## Phase 3: Spawn the Researchers

Spawn `market-researcher` via `Agent`, **one agent per competitor, all
independent, in one parallel block** (batch at most four at a time when the list
is long, and say so). Fixed brief; fill only `{…}`:

```text
Competitor capture for /competitor-analysis. Read .claude/docs/business-research-protocol.md
and .claude/skills/competitor-analysis/references/1-competitor-file.md first.
Company: {name}   Vendor URL: {url}   Segment: {segment}   Countries: {list}
Horizon: {days}   Mode: {new | refresh of business/competitors/<slug>.md, contents pasted below}
{existing file contents for a refresh, else "none"}
Fetch the vendor's own pricing, plans, docs, security/trust, help and Arabic/regional
pages with WebFetch and record URL + capture date for each. Mark every field
VERIFIED-ON-SITE / THIRD-PARTY (source+tier) / NOT CAPTURED (say why) / NOT SOURCEABLE.
Prices as published (currency, period, per what, tax shown); conversions only with a
dated, sourced rate, original first. Reviews: site, rating, review count, date, and a
second source before relying on them. Customer logos are claims. Never use a login or
bypass a paywall, never contact the vendor. Return the full competitor file text only;
do not write files.
```

## Phase 4: Check What Came Back

For each returned file:
1. **Mark audit.** Count fields by mark: V (`VERIFIED-ON-SITE`), T (`THIRD-PARTY`), NC (`NOT CAPTURED`), NS (`NOT SOURCEABLE`). A field with no mark, or a price with no capture date, URL, currency, period or tax status, is a defect — sent back or downgraded to `NOT CAPTURED`.
2. **Spot re-check.** Re-fetch the vendor price page for at least one plan per file and compare. A mismatch is sent back. If this skill could not re-fetch, report "spot re-check not run — <reason>".
3. **Traps.** A price from a review site or snippet marked `VERIFIED-ON-SITE`; a conversion without its rate source and date; a logo wall treated as a customer count; a data-residency claim stated as fact; a review score without count and date; any personal data about individuals.
4. **Refresh integrity.** For a refresh, the older captures and the change log survive.

Then build the **comparison matrix** from the files as they stand (matrix rules
in `references/2-matrix.md`), computing the corridor with `calc.py`; with
fewer than three verified captures say so and give no median.

**Verdict.** Per competitor: `COMPLETE` (price capture V and the other fields marked) /
`COMPLETE WITH GAPS` / `INSUFFICIENT DATA` (no V price capture). Overall: the
worst per-competitor value **among those in scope**, except that
`INSUFFICIENT DATA` overall is reserved for the case where **no** competitor has a
V price capture; otherwise a few `INSUFFICIENT DATA` competitors make the overall
`COMPLETE WITH GAPS` and are named. List every `NOT CAPTURED` field with what
would close it (a person with a trial account is the user's action; this skill
never does it).

## Phase 5: Present and Write

Present: verdict, the corridor with n, the matrix, the gaps, which captures are
stale against the horizon.

Ask: "May I write `business/competitors/<slug>.md` for each of [list] and
`business/competitors/comparison-matrix.md`?" naming every path, and for a
refresh which files are modified (append-only: a refresh uses `Edit` to append
the new capture and a change-log row; it never rewrites the file with `Write`, so
older captures survive). A new competitor file uses `Write`. Write only after the
yes (autonomous mode writes and records the choice with `log_decision`). If the
user declines, nothing is written; the verdict already presented stands and the
report says "not saved". Capture dates come from `date +%F`. Then `Grep` the files
for leftover placeholders and report the result.

## Phase 6: Hand-off

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/competitor-analysis
<scope> — <verdict>`, Next step = the first hand-off below that applies (a
concrete command), plus Blocked on / Files in progress / Open questions (stale
or missing captures); append the Notes line. Still updated when the user declines
the write (record nothing written and why) or the verdict is `NOT ASSESSED`.

- Corridor ready → `/pricing-strategy` (needs ≥ 3 dated captures or the count found plus `NOT SOURCEABLE`)
- Positioning evidence → `/gtm-plan`; objections that name a competitor → `/sales-playbook`
- Capture older than the horizon → re-run with `--refresh`
- Product-scope implications of a gap ("everyone has Arabic/RTL and we do not") → an approval request to `product-director`, not a change here

---

## Collaborative Protocol

- **A price is a dated capture or it is absent** — never from memory, a review site or a search snippet
- **`VERIFIED-ON-SITE` means read on the vendor's own domain in this run** — nothing else earns it
- **A page that could not be read is `NOT CAPTURED`**, reported as not run, never as "no price exists"
- **Vendor claims (customers, residency, certifications) are claims**, not facts
- **Public pages only** — no logins, no paywall or bot-check bypass, no contact with the vendor, no scraping that the site's terms forbid
- **Companies, not individuals** — no personal data in the files
- **No fabricated reviews, testimonials or ratings**; review evidence carries site, count and date
