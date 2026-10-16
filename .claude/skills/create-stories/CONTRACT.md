# /create-stories — Handoff Contract

## Role in Pipeline
Decomposes a single epic into implementable story files by tracing spec acceptance
criteria through ADR decisions and manifest rules — one story per code root, contract
story first — and records for each story the owner agent and the Definition of Done
evidence it must produce. Sits between `/create-epics` and `/story-readiness` + `/dev-story`.

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `production/epics/[epic-slug]/EPIC.md` | `Layer:`, `Spec(s):` path, `Architecture Module:`, `Code roots:`, `Owner agents:`, `## Governing ADRs` table, `## Spec Requirements` table with TR-IDs, `## Threat Models and Contracts` | Yes |
| `design/specs/[filename].md` | The sections required at the tier, especially `## Acceptance Criteria`, `## Data & Contracts`, `## Edge Cases & Failure Modes`, `## Non-Functional Requirements` | Yes |
| `docs/architecture/adr-NNNN-[slug].md` (all governing ADRs) | `Status:`, `Decision`, `Implementation Guidelines`, `Stack Compatibility`, `Cross-Cutting Impact` | Yes |
| `docs/architecture/control-manifest.md` | Layer and context rules (required patterns, forbidden patterns, guardrails), `Manifest Version:` date in header | Yes |
| `docs/architecture/tr-registry.yaml` | All TR-IDs for the epic's feature, with stable `id` values | Yes |
| `docs/research/[feature].md`, `docs/architecture/threat-models/[feature].md`, `contracts/**`, `docs/architecture/perf-budgets.md` | Presence (and, for contracts and budgets, the rows the epic touches) | Yes |

> **Tier.** The rows above are the `standard`/`full` inputs. At `workflow: minimal`
> the only required input is `design/product-brief.md`: the skill writes
> `production/epics/<slug>/EPIC.md` itself from the brief (or uses one that already
> exists there, never rewriting it), needs no `/create-epics`
> run, and reads no spec, ADR, control manifest or TR registry. Each story traces to
> `Brief MVP feature N` instead of a TR-ID, and its ADR lines read
> `N/A (minimal — no ADRs)` (SKILL.md, the `minimal` branch of Step 2 and the
> `minimal` field mapping in Step 6). The eight DoD gates and the evidence table are not relaxed.

### Preconditions
- `/create-epics` has been run and the target `EPIC.md` has `Status: Ready`
- The EPIC.md contains a populated `## Spec Requirements` table (not empty)
- All governing ADRs listed in the EPIC.md exist as files
- Foundation epics have stories created before Core epics are started; Core before Feature; Feature before Presentation

## Outputs Produced

### Files Written
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `production/epics/[epic-slug]/story-NNN-[slug].md` | `Story ID:`, `Epic:`, `Status:`, `Layer:`, `Code root:`, `Type:`, `Owner agent:`, `Manifest Version:`, `## Context` (spec path + `TR-[feature]-NNN` + research note + threat model + contract + ADR reference + ADR Decision Summary + Stack/Risk + Stack Notes + Editions + Control Manifest Rules), `## Acceptance Criteria`, `## Implementation Notes`, `## Out of Scope`, `## Definition of Done Evidence`, `## Test Evidence`, `## Dependencies` | Created per story |
| `production/epics/[epic-slug]/EPIC.md` | `## Stories` table replacing the "Not yet created" placeholder | Updated in-place; a return visit appends rows for new stories only. At `minimal`, when none exists yet, the skill creates it from the brief, after the write ask names it |
| `production/epics/index.md` | The epic's `Stories` column set to `[N] stories` | Only when the index exists; otherwise the run prints `Epics index not updated: production/epics/index.md absent` |

### Output Guarantees
- Every story file contains a `TR-[feature]-NNN` reference in its `## Context` section (or `TR-[feature]-???` with a warning if the registry has no match) — at `minimal`, `Brief MVP feature N` instead
- Every story file records `Research note:` as present or `MISSING`, and — for Security stories and sensitive areas — `Threat model:` as present, `MISSING` or `not required: [reason]`. A MISSING value is stated, never omitted
- Every story file contains an `ADR Governing Implementation:` line referencing at least one ADR, or an explicit `ADR: N/A — [reason]` note
- Every story file has a `Status:` field — either `Ready` or `Blocked` (if the governing ADR is `Proposed`, `Deprecated` or `Superseded`)
- Every story file has a `Type:` field — one of: Logic, Integration, Contract, Security, Performance, UI, Config — and exactly one `Code root:` and one `Owner agent:`
- A boundary consumed by a client or another context has a Contract story numbered before every backend and client story that depends on it, or an explicit `existing, unchanged` contract note; no backend or client story defines HTTP shape
- Every story touching tenant data has a cross-tenant negative acceptance criterion; every story adding an endpoint has anonymous and wrong-role criteria; each standard-sourced criterion is labelled with its source
- Every story file has a `Manifest Version:` field matching the date from `docs/architecture/control-manifest.md`'s header at time of writing — at `minimal`, `N/A (minimal — no control manifest)`
- Every story file has a `## Definition of Done Evidence` table with all eight gates plus run-and-observe, each row stating the evidence or a written waiver reason, and a `## Test Evidence` section stating the expected evidence location and the effective gate level for its type
- Every story file has a `## Acceptance Criteria` section with at least one checkbox item copied from the spec — at `minimal`, derived from `design/product-brief.md`
- Every story file has a `## Dependencies` section (may say "None" but is never omitted)
- The EPIC.md `## Stories` table is updated with a row per story including `#`, `Story ID`, `Story` title, `Type`, `Code root`, `Owner`, `Status`, and `ADR`
- Stories with a `Proposed` ADR have `Status: Blocked` and a note: `BLOCKED: ADR-NNNN is Proposed — accept it with /architecture-decision accept ADR-NNNN once decided`; a `Deprecated` or `Superseded` ADR blocks the same way, naming its successor
- Every story file has a `Stack` and a `Risk` field. `Risk` is taken from the ADR or `docs/stack-reference/<layer>/VERSION.md`; when neither assigns a level, `Risk` is **`NOT ASSESSED (no stack-reference risk rating)`** — never a guessed level
- **`NOT ASSESSED` is an emittable value of the `Risk` field**, and downstream readers must handle it. `/dev-story` treats it as HIGH when deciding whether a stack-lead review is mandatory: an unknown risk is not a low one
- Every spec requirement of the epic has a story or is named in the run's "Dropped / not decomposed" list

## Immutability Rules
- READS but does NOT modify: the epic's spec(s), all ADR files, `docs/architecture/tr-registry.yaml`, `docs/architecture/control-manifest.md`, `contracts/**`, `docs/research/**`
- MODIFIES: `production/epics/[epic-slug]/story-NNN-[slug].md` (creates), `production/epics/[epic-slug]/EPIC.md` (updates Stories section only; created at `minimal` when none exists yet), `production/epics/index.md` (the epic's row, when the index exists) — all after one write ask that names them

## Hard Constraints (Never Violate)
- Never start implementation — this skill stops at the story file level
- Never invent acceptance criteria — all criteria must come from the spec (from `design/product-brief.md` at `minimal`); standard-mandated criteria are labelled with their source and unresolved ones are written as `OPEN`
- Never invent implementation notes — all guidance must come from the referenced ADR
- Never write story files without presenting the full story list for approval first
- Never mark a story `Status: Ready` if its governing ADR has `Status: Proposed`, `Deprecated` or `Superseded`
- Never omit the `Manifest Version:` field — downstream readiness checks depend on it
- Never reuse a story number (NNN) that already exists in the epic directory
- Never let one story span more than one code root, and never let a backend or client story change `contracts/`
- Never record a research note or threat model as present without finding the file

## Downstream Skill Expects
**Next skill:** /story-readiness (then /dev-story)

It will read:
- Each `story-NNN-[slug].md` file — specifically: `Status:`, `Type:`, `Owner agent:`, `Manifest Version:` (header), `TR-[feature]-NNN` and the research-note and threat-model lines (in `## Context`), `ADR Governing Implementation:` line, `## Acceptance Criteria` section, `## Definition of Done Evidence`, `## Test Evidence` section, `## Dependencies` section
- `docs/architecture/control-manifest.md` — to compare its `Manifest Version:` against the story's embedded version
- The referenced ADR file — to verify its `Status:` field is still `Accepted`

It assumes:
- `Manifest Version:` in the story header is a date string that can be compared against the manifest's current `Manifest Version:` date
- `TR-[feature]-NNN` IDs are resolvable in `docs/architecture/tr-registry.yaml`
- The ADR referenced by name in `ADR Governing Implementation:` exists as a file in `docs/architecture/` (pattern: `adr-NNNN-[slug].md`)
- `Status: Ready` means the story is a candidate for assignment (not Draft, not in progress) — a `Research note: MISSING` story is `Ready` here and returns NEEDS WORK from `/story-readiness`
- `## Acceptance Criteria` contains checkbox items that are directly testable
- `## Test Evidence` specifies an exact file path or evidence directory (`production/qa/evidence/[STORY-ID]/`) where proof will be stored

## Known Fragile Points
- If the story file format (header field names, section names, checkbox syntax) changes, `/story-readiness` will silently skip checks for fields it cannot parse — stories may pass readiness that should fail
- If `control-manifest.md` is regenerated with a new `Manifest Version:` date after stories are written, all existing stories will show a stale manifest version and fail the readiness manifest check — every story in the epic will need its `Manifest Version:` updated
- If a governing ADR is renumbered or its file is renamed after stories are written, the `ADR Governing Implementation:` reference in story files will point to a missing file and `/story-readiness` will BLOCK those stories
- If `tr-registry.yaml` deprecates or supersedes a TR-ID that is already embedded in story files, `/story-readiness` will flag those stories as NEEDS WORK
- If the contract file changes after stories are written, backend and client stories still reference the older shape; re-run the epic's Contract story review
- The EPIC.md Stories table update is append-style — if `/create-stories` is run twice for the same epic, duplicate rows will appear in the table
