# /architecture-decision — Handoff Contract

## Role in Pipeline
Authors a new Architecture Decision Record (ADR) by guiding a collaborative design session, cross-referencing the stack reference library, the research note and existing architectural stances, and writing a fully-structured ADR file to `docs/architecture/` as `Proposed`. Its `accept` mode is the only route to `Accepted`, and acceptance is what unblocks the stories and epics that depend on the decision.

Checks inside the run emit `NOT ASSESSED` rather than passing silently, and a
reader of the resulting ADR should expect them: **stack validation** when no stack
layer is configured for the decision or a layer is `NOT SOURCEABLE` in
`docs/stack-reference/`, the **research-note link** when `docs/research/<feature>.md`
is absent, the **registry check** when `docs/registry/architecture.yaml` is absent,
and **spec sync** when the referenced specs cannot be read. A skipped check that
says nothing is indistinguishable from a check that passed.

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `docs/stack-reference/<layer>/VERSION.md` | Pinned version, risk level, licence notes for each layer the decision touches | Yes |
| `docs/stack-reference/<layer>/breaking-changes.md`, `deprecated-apis.md` | Changes and APIs that must not be referenced in the new ADR | Yes |
| `docs/stack-reference/pins.yaml` | Machine-readable pins the ADR's stamped versions must match | Yes |
| `docs/registry/architecture.yaml` | All existing architectural stances (data ownership, tenancy rules, interface contracts, forbidden patterns, performance budgets) — checked for conflicts before the design begins. Absent → reported `NOT ASSESSED`, fallback ADR-header scan | Yes |
| `docs/research/<feature>.md` | The research note the decision rests on (gate 1). Absent → ADR cannot be Accepted | Yes |
| `docs/architecture/` (existing ADRs) | Scanned to determine the next sequential ADR number | Yes |
| `design/specs/<feature>.md` (specs relevant to the decision) | Rules, contracts, budgets or integration points that motivate the decision | Yes |
| `project.yaml` | `stack.*`, `tenancy.model`, `deploy.target`, `distribution.model` — derive the stack lead to spawn for validation (Step 5.5) and the edition constraints | Yes |
| `.claude/docs/templates/architecture-decision-record.md` | The ADR skeleton | Yes |

### Preconditions
- A stack must be configured (`/setup-stack`) — if not, the skill prompts for it
- The title or subject of the decision must be provided by the user before Step 0 proceeds (if no argument is given, the skill asks)
- If in **retrofit mode** (`retrofit [path]` argument), the target ADR file must already exist on disk
- Any conflict with a registered architectural stance in `docs/registry/architecture.yaml` must be resolved or explicitly accepted as an exception before the ADR is drafted (Step 3a is a BLOCKING gate)

## Outputs Produced

### Files Written
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `docs/architecture/adr-NNNN-[slug].md` | `## Status`, `## Date`, `## Last Verified`, `## Summary`, `## Stack Compatibility` (layers, domain, layer, knowledge risk, pinned versions, post-cutoff APIs, verification required, critical-ADR line), `## ADR Dependencies`, `## Context` (problem, constraints, requirements, research-note link), `## Decision` (+ diagram + key interfaces + implementation guidelines), `## Alternatives Considered` (>= 2, each with cost/risk/performance/operability), `## Consequences`, `## Risks`, `## Cross-Cutting Impact`, `## Performance Implications`, `## Migration Plan`, `## Validation Criteria`, `## Spec Requirements Addressed` (table), `## Related` | created after user approves ("May I write this ADR to docs/architecture/adr-NNNN-[slug].md?") |
| `docs/registry/architecture.yaml` | New stance entries (data ownership, tenancy rules, interface contracts, performance budgets, forbidden patterns) derived from the ADR; existing entries marked `status: superseded_by` if overridden | appended after separate user approval ("May I update docs/registry/architecture.yaml with these N new stances?") |

### Output Guarantees
- The ADR number is the next sequential integer after the highest existing `adr-NNNN-*` filename in `docs/architecture/`
- `## Status` is always present. Authoring writes `Proposed`; retrofit writes the status the user gives, except that an `Accepted` answer is written as `Proposed` and handed to acceptance mode. Only acceptance mode writes `Accepted`, after its dependency check, evidence report and the user's confirmation
- `## Stack Compatibility` is always populated using verified data from the stack reference — never from training data alone when the layer carries MEDIUM or HIGH risk; versions agree with `pins.yaml` or the divergence is stated
- `## Spec Requirements Addressed` is always present (a foundational ADR states "Foundational — no spec requirement" and what it enables)
- `## ADR Dependencies` is always present (fields set to "None" only when confirmed, never `UNKNOWN`)
- Every ADR states its effect on both editions when `distribution.model` is `hybrid` or `self-hosted`
- Stack lead validation (Step 5.5) runs before the file is written if a stack layer applies; blocking issues found cause the Decision section to be revised before saving

## Immutability Rules
- READS but does NOT modify: all existing ADR files in `docs/architecture/` (including in retrofit mode — existing sections are never touched; superseding appends to the old ADR's Status only), all specs in `design/specs/` (unless the user picks the "update the spec" write option), `docs/stack-reference/**`, `docs/research/**`, `project.yaml`
- MODIFIES: `docs/architecture/adr-NNNN-[slug].md` (new file created; or missing sections appended in retrofit mode), `docs/registry/architecture.yaml` (append only; existing entries get `status: superseded_by` annotation, never deleted or rewritten)
- In retrofit mode: appends only the missing sections — never modifies any section that is already present in the target ADR file

## Hard Constraints (Never Violate)
- Never sets `Status: Accepted` without explicit user confirmation — the default on creation is always `Status: Proposed`
- **Acceptance route: `/architecture-decision accept ADR-NNNN`** — the only path that sets `Accepted`. It refuses when a dependency is still Proposed or when no research note is linked, and prompts for confirmation regardless of `modes.automation`. Retrofit mode's `Accepted` answer, for a decision already in force, is written as `Proposed` and handed to this route.
- **Acceptance authority: the user, or `cto` on the user's explicit confirmation — no other agent, and not this skill on its own.** This narrows *who* may set the field; it does not relax the confirmation rule above.
- Never assigns an ADR number that is already in use — always scan `docs/architecture/` first and use the next sequential number
- Never proceeds past the architectural stance conflict check (Step 3a) if a conflict exists — surface the conflict and require resolution or explicit exception acknowledgment before drafting
- Never references APIs listed in `docs/stack-reference/<layer>/deprecated-apis.md` in the Decision or Key Interfaces sections
- Never records an alternative without cost, risk, performance and operability notes, and never records fewer than two rejected alternatives
- Never selects a component for `deploy/self-hosted/` that breaks the licence rules in `.claude/rules/deploy.md`
- Never writes the ADR file without asking: "May I write this ADR to docs/architecture/adr-NNNN-[slug].md?"
- Never writes to `docs/registry/architecture.yaml` without a separate ask: "May I update docs/registry/architecture.yaml with these N new stances?"
- In retrofit mode: never modifies any existing section — only appends absent sections

## Downstream Skill Expects
**Next skills:** `/create-epics`, `/create-stories`, `/dev-story`, `/architecture-review`, `/create-control-manifest`

### `/create-epics` reads ADRs expecting:
- `## Status` field — value must be `Accepted` for epics to reference it
- `## Spec Requirements Addressed` table — used to link epics to traceability
- `## Stack Compatibility` section — checked during the Architecture → Pre-Production gate

### `/create-stories` reads ADRs expecting:
- `### Implementation Guidelines` (under `## Decision`) — the concrete "must / must never" patterns the stack leads follow; the ADR template carries this subsection
- `## ADR Dependencies` table — stories referencing a `Depends On` ADR that is still `Proposed` are automatically set `Status: Blocked`

### `/dev-story` reads ADRs expecting:
- `## Decision` (full text, verbatim — not summarized)
- `### Implementation Guidelines` (under `## Decision`, verbatim)
- `## Stack Compatibility` (post-cutoff API risks, verification required)
- `## ADR Dependencies` (to detect if this ADR's dependencies are unresolved)

### `/architecture-review` reads ADRs expecting:
- All required sections present (it flags gaps)
- `## Status` is set (required for coverage matrix)
- `## Stack Compatibility` is stamped with the pinned versions

### `/create-control-manifest` reads ADRs expecting:
- `Accepted` status, the `Layer` and critical-ADR line, and Implementation Guidelines in must / must-never form

## Known Fragile Points
- If the ADR number scan misses a file (e.g., a file in a subdirectory of `docs/architecture/` or with a non-standard naming pattern), a duplicate number can be assigned — all ADR files must follow the `adr-NNNN-[slug].md` naming convention at the top level of `docs/architecture/`
- Acceptance mode moves a story from `Blocked` to `Ready` only when the story file, under `production/epics/`, contains a Blocked Status line in any of the forms `/create-stories` writes (`> **Status**: Blocked`, `**Status:** Blocked`, `Status: Blocked`) and this ADR's id. A story blocked pending this ADR that never names its id is not found, and stays `Blocked` until it is updated by hand
- The `## Spec Requirements Addressed` table is populated based on what the user tells the skill during the collaborative session; if the user does not know which specs motivated the decision, this table may be incomplete — `/create-epics` and `/gate-check` both rely on this linkage for traceability
- Stack lead validation (Step 5.5) is skipped only when no stack layer is configured for the decision; the skip is recorded as `NOT ASSESSED`. When skipped, post-cutoff API risks are not caught before the ADR is written
- `docs/registry/architecture.yaml` is append-only by design; if a stance entry becomes permanently invalid (not superseded by another ADR), it must be manually removed — there is no cleanup mechanism
- In retrofit mode, if the existing ADR has sections present but empty (e.g., a `## Status` heading with no value), the skill treats the section as present and does not fill it — an empty Status is effectively invisible to downstream skills like `/story-readiness`
