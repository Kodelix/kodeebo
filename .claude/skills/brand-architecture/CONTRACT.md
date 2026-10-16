# /brand-architecture — Handoff Contract

## Role in Pipeline
Decides, with the user, how a product family is named and presented, and records
the evidence: the architecture model (branded house / endorsed / house of brands /
hybrid), name criteria, per-candidate screening (market conflicts, domain and handle
observations, Arabic/English review requests, trademark screening record), a brief
for counsel, and the per-brand visual theme handoff. Owned by `marketing-lead`;
`market-researcher` does the screening captures; `design-director` is consulted on
the visual handoff only. Follows `/brainstorm` (the product and segment) and may
precede `/gtm-plan`, `/marketing-plan` and the design work run through
`/impeccable`. Reached from `/business` (routed), `/studio` (business flow) and
directly. It screens; it never clears, files, registers, publishes or contacts anyone.

## Inputs Consumed

| File | Used for | Absent means |
|---|---|---|
| `design/product-brief.md` | what the product is, segment, positioning, product name of record | no definition of the product: architecture `NOT ASSESSED — no product/segment definition`, candidates `NOT ASSESSED`; `/brainstorm` named; nothing invented |
| `PRODUCT.md`, `DESIGN.md` (repo root) | brand and tone of record (read-only) | stated ABSENT |
| `business/market/*`, `business/competitors/*` (excluding `notes/`), `business/marketing/*` | category, neighbours, competitor names, channels | stated ABSENT; the category search is run fresh |
| `design/localization/*` | languages and locales in scope | the user names the dialect groups |
| `business/brand/*` | refresh base; older naming files are kept | new files |
| `project.yaml` via `resolve_config --keys automation,stack` | automation mode, platforms for the visual handoff | defaults per `config-resolution.md` |

### Preconditions
- A product family or naming question is given; none → the skill asks and stops
- The user states the target markets, the languages/dialect groups whose native speakers will review, the brand set in scope, and (naming) the category neighbours, domain extensions and platforms; a skipped answer is re-asked in plain text
- The architecture model, the final name and the dismissal of a flagged conflict are the user's decisions in every automation mode

## Verdicts Emitted
- *Name screen, per candidate:* `CONFLICT FOUND` / `NOT ASSESSED` / `SCREEN PASSED — NEEDS COUNSEL`. Precedence, first match wins: `CONFLICT FOUND`, `NOT ASSESSED`, `SCREEN PASSED — NEEDS COUNSEL`. `NOT ASSESSED` outranks the pass value and does not outrank a found conflict; it names the components not run (R1 category/neighbour search, R2 WIPO Global Brand Database, R3 each target-market office, R4 domain/handle observations, R5 recorded native-speaker review). A Tier 1 candidate that survived is `NOT ASSESSED` (Tier 2 not run), never passed.
- *Architecture record header:* `DECIDED` / `RECOMMENDED` / `NOT ASSESSED`. `DECIDED` only on the user's own statement; `RECOMMENDED` when a recommendation exists and the user has not decided; `NOT ASSESSED` when neither a decision nor a buildable recommendation exists.
- There is no verdict meaning "clear", "available" or "registrable".

## Outputs Produced

| File | Guaranteed sections |
|---|---|
| `business/brand/brand-architecture.md` | header with status and revisit triggers; decision (two layers) with reasons and alternatives; criteria table with evidence per cell; name inventory with screening and counsel status; naming rule for future verticals; domain/handle/store-listing structure; visual system handoff (table, constants vs variations, platforms, RTL, questions for design, `PRODUCT.md` proposal text, design-director consult state); `NEEDS COUNSEL` list; `NOT ASSESSED` list; append-only decision log; sources |
| `business/brand/naming-<date>.md` | header with markets, dialect groups, category neighbours, staleness; the limits statement; per-candidate verdict table; criteria as ranked by the user; candidates with `PROPOSED` Arabic-script renderings; per-candidate sections (conflict findings, domain/handle/store observations, trademark screening record per office, language review status, searches not run); "Searches for you to run"; language review requests; self-contained brief for counsel; `NOT SOURCEABLE`/`NOT CAPTURED` table; sources |

### Output Guarantees
- Every screening field carries exactly one mark: `VERIFIED-ON-SITE`, `OBSERVED`, `THIRD-PARTY` (source, tier), `USER-REPORTED`, `PROPOSED`, `HYPOTHESIS`, `NOT SEARCHED`, `NOT CAPTURED` or `NOT SOURCEABLE`
- Every hit has query, source URL and date; owners are companies, individuals appear only as "individual"
- Trademark results use only `HITS LISTED` / `NO HITS LISTED FOR THE QUERIES RUN` / `NOT SEARCHED — <reason>`, with the limits sentence beside the second
- DNS: only an explicit `NXDOMAIN` is written as `NO DNS RECORDS SEEN — not proof of availability`; timeouts and failures are `NOT CAPTURED`
- No Arabic or dialect meaning, class number, fee, deadline, procedure or office rule is stated without a fetched official source or a recorded user report
- The forbidden words (`clear`, `available`, `safe`, `registrable`, `no conflict`) appear only in negations or the limits statement; a `Grep` for them is run and reported
- Dates come from `date +%F`; leftover placeholders are searched for

## Immutability Rules
- WRITES only under `business/brand/`: new files with `Write`; `brand-architecture.md` is edited with `Edit` only for the name inventory, the append-only decision log, and sections the user approved; older naming files are never modified; only after "May I write ...?" (autonomous mode writes and records `log_decision`, status staying `RECOMMENDED` unless the user decided). A declined write writes nothing: the verdict stands and the report says "not saved"
- Drafts too long for the chat go in `production/session-state/drafts/`, never outside the repository
- Never edits `PRODUCT.md`, `DESIGN.md`, `design/`, `project.yaml` or code; a proposed `PRODUCT.md` change is text in the file for `design-director`

## Hard Constraints (Never Violate)
- No statement that any name, domain, handle or mark is clear, available, safe or registrable; every legal conclusion is `NEEDS COUNSEL`
- No login, account creation, CAPTCHA or bot-check bypass; no contact with owners, offices or registrars; no registration, reservation or purchase of anything; nothing filed
- No design values (colours, fonts, token values, artwork); that is `design-director` and `/impeccable`
- A search that did not run is never reported as "no hits" or as a pass

## Downstream Skill Expects
`design-director` (through the session running `/impeccable`) reads the visual handoff section; `/gtm-plan` and `/marketing-plan` read the decided architecture and the name inventory; `localization-lead` reads the Arabic-script renderings and review requests; the user hands the brief for counsel to a qualified trademark professional. `NOT ASSESSED` and `PROPOSED` items stay that way downstream.

## Known Fragile Points
- Most national office search pages are interactive forms, protected or script-driven: expect `NOT SEARCHED` and a "Searches for you to run" block; the candidate stays `NOT ASSESSED` until the user or counsel reports the result
- A search run with a query set misses similar marks and design marks by construction; the file says so beside every `NO HITS` result
- DNS observations from a restricted sandbox can fail in ways that look like absence: only an explicit `NXDOMAIN` counts
- Native-speaker review is a human step outside the session; one reviewer per dialect group is a lead, not a consensus, and the count is always shown
- `design-director` cannot run `/impeccable` itself (no `Skill` tool); the visual handoff names the command for the session or orchestrator
