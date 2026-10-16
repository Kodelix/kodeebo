# Output layouts, visual handoff and audit checklist — `/brand-architecture`

Read in Phase 2. Both files are English; Arabic appears only for name renderings and
review questions. Dates come from `date +%F`.

## `business/brand/brand-architecture.md` (living record, one per product family)

```
# Brand architecture - <family>
Date: <date>  Author: marketing-lead via /brand-architecture; design-director consulted (visual section)
Status: DECIDED | RECOMMENDED | NOT ASSESSED (<reason>)   Stale-after / revisit triggers: <list>
Sources: <list with dates>

## Decision
Layer A - family model: <model, per-product rule if hybrid>   Decided by: user, <date> | USER-STATED before the run | pending
Layer B - company relationship: <endorsement rule: where the line appears and where it does not>
Reasons the user gave: <paraphrase, dated>   Alternatives considered: <models and why not chosen>

## Criteria table
| Criterion | Branded house | Endorsed | House of brands | Hybrid | Evidence (USER-STATED / file / JUDGEMENT) |
(FAVOURS / NEUTRAL / AGAINST / UNKNOWN per cell; no scores; the drivers and what would change the recommendation under it)

## Name inventory
| Asset | Type | Latin form | Arabic-script rendering | Screening status | Naming file | Counsel status |
(master, endorser/company, each vertical descriptor, mascot, tagline, logo; NOT SCREENED is a valid, visible value; counsel status stays "not reported" unless the user reports otherwise)

## Naming rule for future verticals
<pattern, approval, screening duty>

## Domain, handle and store-listing structure
<options, the decision if made, observations from naming files with dates and their limits; registry/store rules with URL and date or NOT CAPTURED>

## Visual system handoff
Handed to: design-director (via /impeccable). This skill records structure and questions only.
| Brand / vertical | Audience (USER DIRECTION) | Feel the user asked for (user words, not styled) | Keeps constant (family recognition) | May vary | Platforms | Arabic/RTL notes |
Token structure asked of design (tiers: what is shared across brands, what a vertical overrides, and the theme layer each platform consumes) - decided by design-director against docs/stack-reference/; format not asserted here.
Mascot: role, name screening status, art ownership question (NEEDS COUNSEL), cultural review questions.
PRODUCT.md update proposed (text only; applying it is design-director's change after the user approves): <text>
Questions design must settle first: <list>   design-director consult: ran | not run (<reason>)

## NEEDS COUNSEL
<every legal question, each with the section that raised it>

## NOT ASSESSED / not run
<each component or check that did not run, the reason, what closes it>

## Decision log (append-only)
| Date | Decision or change | By | Note |

## Sources
| # | URL or file | Tier | Date |
```

## `business/brand/naming-<date>.md` (one per naming round)

```
# Naming round - <family> - <date>
Author: marketing-lead and market-researcher via /brand-architecture   Markets: <list>   Languages/dialect groups: <list>
Category and neighbours: <list>   Staleness horizon: <days> (studio convention if proposed by this skill)   Stale after: <date>
Limits: This is a screening record, not a clearance or a legal opinion. No name, domain, handle or mark in it is stated to be clear, available or registrable. Legal conclusions are tagged NEEDS COUNSEL.

## Verdict table
| Candidate | Tier | Verdict (CONFLICT FOUND / NOT ASSESSED / SCREEN PASSED - NEEDS COUNSEL) | Reason(s): flagged hit, or components not run (R1-R5) |

## Criteria (the user's ranking, as given)

## Candidates
| # | Name | Proposed Arabic-script renderings (PROPOSED - native review) | Role | Proposed by | Rationale |

## Per candidate (repeat)
### <name> - <verdict>
Category and neighbour findings: <table: query, source URL, date, what was found, mark>
Domain observations: <table: extension, command, status line, word used, date>   Handles: <table>   App stores: <table>
Trademark screening record: <per office block as in references/2-naming.md>
Language review: <status per dialect group, reviewers n, responses>
Searches not run: <list with reasons>

## Searches for you to run
<per office that was NOT SEARCHED: URL, queries to type, classes to select, what to copy back>

## Language review requests
<question set per dialect group; the places to return the answers to: the user pastes them back and re-runs /brand-architecture --refresh>

## Brief for counsel
<as in references/2-naming.md - self-contained>

## NOT SOURCEABLE / NOT CAPTURED
| Field | Why | Searched |

## Sources
| # | URL | Tier | Date fetched |
```

A refresh writes a **new** dated naming file that cites the earlier one; earlier
captures are never edited. `brand-architecture.md` is edited in place only for the
name inventory (screening status) and the append-only decision log, and any other
section only with the user's approval.

## Visual handoff checks

- No colour value, font name, token name or value, or artwork appears in the file; user words about feel are quoted or paraphrased and labelled `USER DIRECTION`.
- Every brand/vertical row names what stays constant and what may vary, so design can check recognition across verticals.
- `design-director` consulted: its answer is summarised under the table; "not run" is stated with the reason and the handoff is `NOT ASSESSED` for feasibility.
- No one runs `/impeccable` from this skill; the file names the command for the session or orchestrator to run.

## Audit checklist (Phase 6: MET / NOT MET / NOT ASSESSED)

| # | Check | NOT ASSESSED when |
|---|---|---|
| B1 | Every screening field has one mark; every hit has query, URL, date | — |
| B2 | No forbidden word (`clear`, `available`, `safe`, `registrable`, `no conflict`) except in a negation or the limits statement | the Grep did not run |
| B3 | Each candidate's verdict follows `references/2-naming.md`; every `NOT ASSESSED` names its components | — |
| B4 | No dialect or Arabic meaning stated as fact; all such items are `HYPOTHESIS` or `USER-REPORTED` | — |
| B5 | No class number, fee, deadline, procedure or office rule without a fetched official source | — |
| B6 | Office URLs confirmed to be the office's own domain | an office page was not fetched |
| B7 | Owners recorded as companies; individuals as "individual" | — |
| B8 | Name inventory complete for the brand set the user put in scope; `NOT SCREENED` visible | brand set not given |
| B9 | Architecture: both layers decided or pending; hybrid has a per-product rule; every criterion cell has evidence or `UNKNOWN` | brief ABSENT |
| B10 | Visual handoff has no design values and shows the design-director consult state | consult not run |
| B11 | Brief for counsel self-contained; `USER TO FILL` fields visible; every legal question tagged | — |
| B12 | Markets kept separate in every table; no finding from one market stated for another | — |
