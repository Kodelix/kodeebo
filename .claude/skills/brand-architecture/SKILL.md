---
name: brand-architecture
description: "Brand architecture decision (branded house, endorsed, house of brands or hybrid; the user decides), product-name criteria and candidate screening — market conflicts, domain and handle observations, Arabic and English review requests, a trademark screening record and a brief for counsel (never a clearance) — and the per-brand visual theme handoff. Writes business/brand/."
argument-hint: "<product family or naming question> [--mode architecture|naming|both] [--markets eg,sa,ae,...] [--candidates a,b,c] [--refresh]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, WebFetch, WebSearch, Bash(dig *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(date *), Bash(bash "*/.claude/skills/brand-architecture/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.
No director gate applies; `review_mode` and `workflow` do not relax sourcing or the
screening rules. **Three decisions here are the user's in every mode and are never
picked on their behalf:** the architecture model, the final name, and dismissing a
conflict the screening flagged. In `autonomous` mode the skill records its
recommendation (`log_decision`), leaves the status `RECOMMENDED`, and lists the
decision as open in the checkpoint; `DECIDED` needs the user's own statement in chat.

# Brand Architecture

Decides, with the user, **how the product family is named and presented**, and
records the evidence behind it: the architecture model (branded house, endorsed,
house of brands, hybrid), the name criteria, the screening of each name candidate,
and the handoff of per-brand visual themes to design. Owned by `marketing-lead`
(architecture, criteria, candidates); `market-researcher` does the screening
captures; `design-director` is **consulted** on the visual handoff only. All under
`.claude/docs/business-research-protocol.md`. Markets: Egypt and GCC/MENA unless
the user names others.

**This is screening, not clearance.** The skill never states that a name or mark is
clear, available, safe or registrable. It records what was searched, where, when and
what was listed; it lists what was **not** searched; and it writes a **brief for
counsel**. Every legal conclusion (registrability, conflict, scope, ownership, risk)
is tagged `NEEDS COUNSEL` and left to a qualified trademark professional the user
engages. Domain and handle observations are observations, not availability.
Arabic and dialect meanings are **never asserted from model memory**: the skill
prepares questions and renderings for native speakers and records only what they
(through the user) report.

**Reply language.** Answer in the language of the question. File artifacts are
written in English, with Arabic text only where the content itself is Arabic (name
renderings, review questions). Money, if any, keeps ISO currency codes.

**Outputs:** `business/brand/brand-architecture.md` (the living decision record:
one per product family, decision log append-only) and `business/brand/naming-<date>.md`
(one file per naming round, including the screening record and the brief for
counsel; `<date>` comes from `date +%F`, and a second round on the same day takes
the suffix `-2`). Layouts: `references/3-files.md`.

**Verdict words (fixed), two scopes.**
- *Name screen, per candidate:* `CONFLICT FOUND` · `NOT ASSESSED` · `SCREEN PASSED — NEEDS COUNSEL`.
  Precedence, first match wins: `CONFLICT FOUND` → `NOT ASSESSED` → `SCREEN PASSED — NEEDS COUNSEL`.
  `NOT ASSESSED` is the "could not assess" value: it outranks the pass value (a
  candidate with any required component not run is not passed) and does **not**
  outrank a found conflict. The report names which component and why. There is no
  verdict meaning "clear".
- *Architecture record header:* `DECIDED` · `RECOMMENDED` · `NOT ASSESSED`.
  `NOT ASSESSED` when neither a user decision nor a buildable recommendation exists
  (no product or vertical list, no target markets); `RECOMMENDED` when the skill has
  a recommendation and the user has not decided; `DECIDED` only on the user's own
  statement. A decision the user made before the run is recorded `DECIDED`; any part
  of the consequence check that could not run is listed by name as `NOT ASSESSED`.

---

## Phase 1: Scope and Inputs

No argument → ask which product family or naming question this is, then stop.

Read, recording FOUND or ABSENT: `design/product-brief.md` (segment, positioning,
named alternatives, product name of record), `PRODUCT.md` and `DESIGN.md` at the repo
root (brand and tone of record — read-only here), `.claude/docs/standing-decisions.md`,
`business/market/*`, `business/competitors/*` (excluding `notes/`),
`business/marketing/*`, `design/localization/*`, and existing `business/brand/*`
(to refresh, not duplicate; older naming files are kept). `project.yaml` names the
stack only; product-name keys are the user's to change.

Ask (`AskUserQuestion`, at most four options, recommended first; a skipped or empty
answer is not an answer — re-ask in plain text):
1. **Mode** — architecture / naming / both (`--mode`).
2. **Where the user already is** — for example "model already chosen", "names already shortlisted", "starting from nothing". A decision the user states is recorded as `USER-STATED, <date>` and **not** re-litigated; the skill still runs the consequence check on it.
3. **Target markets and languages/dialects** the name must work in (`--markets`; the user names the dialect groups whose native speakers will review — never inferred).
4. **The brand set in scope** — master/family name, company or endorser name, verticals or product lines, mascot, tagline. Each name the user puts in scope is screened or listed `NOT SCREENED`.

For `naming`/`both`: also the **category and its neighbours** the clash screen covers
(the user confirms the neighbour list), the domain extensions and social platforms
that matter, and the staleness horizon for screening records (if the user has none,
propose a horizon and label it a studio convention, not a sourced figure).

**Insufficient input rule.** No description of what the product is and for whom
(no brief and the user cannot supply it) → architecture header `NOT ASSESSED — no
product/segment definition`, naming candidates `NOT ASSESSED`; the skill names
`/brainstorm` as the producer and does not invent a product.

## Phase 2: Plan and Announce

Read **`references/1-architecture.md`** (models, decision criteria, record format)
for `architecture`/`both` and **`references/2-naming.md`** (criteria, tiers,
screening components, language protocol, trademark screening record, verdict
derivation) for `naming`/`both`, and **`references/3-files.md`** (output layouts,
visual handoff, audit checklist) always. Re-read them after compaction.

Announce: which phases run and which do not (a skipped phase says so, with the
reason), the specialists that will and will not be spawned, the capture limits
(public pages only; no logins or account creation; no CAPTCHA or bot-check bypass;
no contact with owners of existing marks, companies or registrars; no purchase of a
domain or handle), and that the result is a screening, not a clearance.

## Phase 3: Architecture Decision (`architecture` / `both`)

Spawn `marketing-lead` via `Agent` with a fixed brief; fill only `{…}`:

```text
Brand architecture analysis for /brand-architecture. Read .claude/docs/business-research-protocol.md,
.claude/skills/brand-architecture/references/1-architecture.md and references/3-files.md first.
Product family: {name, verticals/lines, buyer and user per vertical}   Markets: {list}   Languages: {list}
Company/endorser: {name}   Mascot/other assets: {list}   Brief and positioning: {summary + paths, or "ABSENT"}
User already decided: {model and endorsement rule with date, or "nothing yet"}
Return text only, no files: the two-layer decision frame (family model; company relationship), the
four models against every criterion in references/1-architecture.md with FAVOURS / NEUTRAL / AGAINST /
UNKNOWN and the evidence for each cell (user statement, file path, or JUDGEMENT), a recommendation
with what would change it and the revisit triggers, the consequence check (name inventory, naming
rule for future verticals, domain/handle/store-listing structure options, what the visual system
must keep constant), and the list of NEEDS COUNSEL questions. No scores summed into one number.
No trademark, registrability or cost claim: those are NEEDS COUNSEL. No market figure without the
protocol's four fields.
```

Present the model table and the recommendation. Then ask the user to decide
(`AskUserQuestion`: the four models, recommended first, or "Other" for a hybrid with
its per-product rule; and a second question for the company-endorsement rule). A
hybrid with no per-product rule is not a decision: re-ask. If the user had already
decided, skip the question, say "recommendation step skipped: user already decided",
and run only the consequence check.

## Phase 4: Naming — Criteria and Candidates (`naming` / `both`)

1. **Criteria.** Show the criteria from `references/2-naming.md`; ask which matter most
   (`AskUserQuestion`, at most four per question; two questions if needed). The user's
   priorities are recorded as given, not weighted into a score.
2. **Candidates.** The user's own candidates (`--candidates`) come first. If the user
   wants more, spawn `marketing-lead` (brief: the criteria, the architecture decision,
   the languages, the rule that each candidate comes with its Arabic-script rendering
   **proposals** marked `PROPOSED — native review` and its rationale; no meaning claims,
   no availability claims). The user trims the list. Tier 1 (quick screen) covers every
   remaining candidate; Tier 2 (full screen) covers at most the number the user
   approves — say how many and why before spawning.

## Phase 5: Screen (`naming` / `both`) and Consult Design

Spawn in **one parallel block**: `market-researcher`, **one agent per candidate**
(batch at most four at a time when the list is long, and say so), and — for
`architecture`/`both` after a decision exists — `design-director` for the visual
handoff. Fixed `market-researcher` brief; fill only `{…}`:

```text
Name screening for /brand-architecture. Read .claude/docs/business-research-protocol.md and
.claude/skills/brand-architecture/references/2-naming.md first.
Candidate: {name}   Rendering proposals (Arabic script): {list or "none"}   Tier: {1 | 2}
Category and neighbours: {list}   Markets: {list}   Domain extensions: {list}   Platforms: {list}
Mascot/endorser/descriptor names in scope: {list or "none"}
Do, in order, and record query + URL + date + what was shown for each: (1) category and
neighbour conflict search (web, app-store listings, public company registers where a search
page exists); (2) domain DNS observations with dig (record the full status line; only an
explicit NXDOMAIN counts as "no DNS records seen"; timeout, SERVFAIL or refusal is NOT CAPTURED);
(3) handle page observations; (4) Tier 2 only: the trademark screening record in references/2-naming.md
- WIPO Global Brand Database plus the official search page of each target-market office, found at
run time and confirmed to be the office's own domain; (5) the language review request set.
Never bypass a login, CAPTCHA or bot check; never create an account; never contact an owner,
registrar or office; never register or reserve anything. A search you cannot run is NOT SEARCHED
with the reason, never a "no hits". Companies are recorded by name, individual owners as
"individual" with no name. Do not use the words clear, available, safe or registrable.
Do not state what any Arabic or dialect word means: list hypotheses as "HYPOTHESIS - ask a
native speaker". Return the candidate section text only; do not write files.
```

`design-director` brief: the decided architecture, the verticals/brands and any
user-stated direction per vertical, the platforms from `stack`, the Arabic/RTL
requirement. Ask for: feasibility of the token-tier structure (what is shared across
brands, what each vertical overrides), constraints on the name lockup in Arabic script
and mixed direction, what `/impeccable` needs as input, questions to settle before
design starts. It returns text only; it designs nothing here and no one runs
`/impeccable` from this skill. If any agent cannot be spawned, say which and which part
the session did itself; that component is `NOT ASSESSED` unless the session ran it.

## Phase 6: Audit and Verdict

For each returned candidate section and the architecture draft:
1. **Mark audit** (marks in `references/2-naming.md`): a field with no mark, a hit with no URL/date/query, or an availability word with no observation is a defect — sent back or downgraded to `NOT CAPTURED`.
2. **Forbidden words.** `Grep` the drafts for `clear`, `cleared`, `available`, `safe`, `registrable`, `no conflict`. Every hit must be a negation ("not proof of availability"), a quoted limit statement, or a mark name; any other is rewritten.
3. **Memory-fact traps.** A dialect or Arabic meaning stated as fact; a trademark class number, fee, deadline, procedure or office rule with no fetched official source; an office URL not confirmed as the office's own domain; an owner who is an individual named; a competitor claim from a snippet.
4. **Spot re-check.** Re-run one `dig` query and re-fetch one cited hit or page per Tier 2 candidate. A mismatch is sent back. If not run: "spot re-check not run — <reason>".
5. **Verdict derivation** per `references/2-naming.md`: required components R1–R5, flagged hits, user dismissals (recorded with reason and date, tagged `NEEDS COUNSEL`). Name each `NOT ASSESSED` reason; never merge "searched, found nothing" with "could not search".
6. **Architecture record:** decision frame complete, every criterion cell evidenced, consequence check present, header status per the rules above.

## Phase 7: Present and Write

Present: architecture status and table, the per-candidate verdict table with the
`NOT ASSESSED` reasons, conflicts found (with sources), the searches **not** run and
who could run them, the language review requests, the brief for counsel, the visual
handoff.

Ask: "May I write `business/brand/brand-architecture.md` and `business/brand/naming-<date>.md`?" naming
every path actually written, and for an existing `brand-architecture.md` which sections
are edited (the decision log is append-only; the name inventory is updated in place;
older naming files are never modified). New files use `Write`, refreshed ones `Edit`.
Write only after the yes (autonomous: write, `log_decision`, status stays
`RECOMMENDED` if the user has not decided). A draft too long for the chat goes in
`production/session-state/drafts/` (asked for like any new file; never outside the
repository). If the user declines, nothing is written; the verdict stands and the
report says "not saved". Dates come from `date +%F`. Then `Grep` the files for leftover
placeholders and forbidden words and report the result.

## Phase 8: Hand-off

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/brand-architecture <scope> —
<status and verdicts>`, Next step = the first hand-off below that applies, plus
Blocked on (searches not run, language reviews outstanding, counsel not engaged, an
undecided architecture) / Files in progress / Open questions; append the Notes line.
Still updated when the write was declined or the verdict is `NOT ASSESSED`.

- Native-speaker review of Arabic renderings, dialect meanings and pronunciation → **the user** collects it (the file lists the questions) and re-runs `/brand-architecture --refresh`; Arabic-script lockup and mixed-direction text → `localization-lead`
- Trademark searches the skill could not run and the clearance question → **the user** hands the brief for counsel to a qualified trademark professional; nothing is sent or filed from here
- Per-vertical themes, tokens, name lockup and mascot rules → `design-director`, via the session running `/impeccable` (`PRODUCT.md` text proposed in the file; applying it is `design-director`'s change)
- A change to the product name, positioning of record or `project.yaml` → an approval request to `product-director`
- Messaging and launch → `/gtm-plan`, `/marketing-plan`; domain and site structure → `astro-specialist` and `web-lead`; store listing names → `release-manager`
- Screening older than the horizon, or any new candidate or market → re-run with `--refresh`

---

## Collaborative Protocol

- **Screening is not clearance.** No mark, name, domain or handle is called clear, available, safe or registrable; legal conclusions are `NEEDS COUNSEL`
- **The user decides** the architecture, the name, and any dismissal of a flagged conflict; the skill recommends and records
- **A search that did not run is `NOT SEARCHED` / `NOT ASSESSED`**, named with its reason, never "no hits" and never a pass
- **Arabic and dialect meanings are never asserted from model memory**, in either direction ("no bad meaning" is also an assertion); only a native-speaker review the user reports is recorded, with reviewer role, dialect, date and count — no names
- **No trademark class, fee, deadline, procedure or office rule from memory**; fetch the official page, record URL and date, or write `NOT SOURCEABLE`
- **Public pages only** — no logins, accounts, CAPTCHA or bot-check bypass, no contact with owners or offices, no registering or reserving a name
- **Companies, not individuals** — owners who are individuals are recorded as "individual"
- **No visual design here** — hex values, fonts and token files are `design-director`'s and `/impeccable`'s; this skill records the structure and the asks
- **No commit and no filing**; the user engages counsel and files
