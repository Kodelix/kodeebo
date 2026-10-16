# /story-readiness — Handoff Contract

## Role in Pipeline
Validates that a story file contains everything a developer needs to begin
implementation and produces a READY / NEEDS WORK / BLOCKED / NOT ASSESSED verdict — sits between
`/create-stories` and `/dev-story`, acting as a blocking gate before any code is written.
It is where DoD gate 1 (research note) and the threat-model trigger
(SL-THREAT-MODEL) are first enforced against a concrete story, and where contract-first
ordering is checked.

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `production/epics/[epic-slug]/story-NNN-[slug].md` | Header fields (`Status:`, `Layer:` / owner, `Type:`, `Manifest Version:`), `## Context` (spec path, TR-ID, ADR reference, research note path, threat model path, contract reference, stack-reference notes, Control Manifest Rules), `## Acceptance Criteria`, `## Test Evidence`, `## Dependencies`, `## Out of Scope` | Yes |
| `docs/research/<feature>.md` | Exists, or the story states `Research: exempt — [row]` | Yes (if exists) |
| `docs/architecture/threat-models/<feature>.md` | Exists for any story hitting a security-baseline trigger | Yes (if exists) |
| `docs/architecture/control-manifest.md` | `Manifest Version:` date in header, layer rules | Yes (if exists) |
| `docs/architecture/tr-registry.yaml` | `id`, `status` fields per TR entry | Yes (if exists) |
| `docs/architecture/adr-NNNN-[slug].md` (all ADRs referenced in stories) | `Status:` field | Yes |
| `design/specs/domain-map.md` | Which features have approved specs | Yes |
| `contracts/` | The operation files the story names | Yes (Glob only) |

> **Tier.** The manifest, TR registry, ADR and domain-map rows are
> `standard`/`full` inputs. At `workflow: minimal` the skill is not on the path
> (`/dev-story` follows `/create-stories` directly); run anyway, it checks
> acceptance criteria, scope, the research note, the threat-model trigger and
> contract order, and treats Architecture Completeness as N/A except the
> referenced-ADR rule: an ADR the story references that is missing, `Proposed`,
> `Deprecated` or `Superseded` BLOCKS at every tier (SKILL.md and
> `references/checklist.md`, the tier note). Workflow tiers scale documents, never
> engineering: the research note and the threat model for a sensitive story are
> required at every tier.

### Preconditions
- The story file being validated was produced by `/create-stories` (or follows the same format)
- For `sprint` scope: a sprint file exists in `production/sprints/` with story path references
- For `all` scope: `production/epics/` directory exists and contains story files

## Outputs Produced

### Files Written
None. This skill is strictly read-only and produces no file modifications under any circumstance.

### Output Guarantees
- A verdict of READY, NEEDS WORK, BLOCKED or NOT ASSESSED is produced for every story file evaluated. `NOT ASSESSED` is not a synonym for `BLOCKED`: BLOCKED names a real, listable obstacle, while NOT ASSESSED means the story could not be evaluated at all. An empty scope yields `NOT ASSESSED — no stories in scope`, never a `Ready: 0 / Needs Work: 0 / Blocked: 0` summary over an empty list
- Every verdict states the story type, the evidence that type requires with its gate level, the owner agent per layer, and the research note and threat model status (path, exempt with the row, not required with the reason, or MISSING)
- Every non-READY verdict includes a specific gap list with fix instructions for each failing checklist item
- Every BLOCKED verdict names the specific blocker (missing dependency story path, Proposed ADR ID, unmerged contract story, missing threat model, or unresolved design question marker)
- A check that could not run is listed under "Not checked" with its reason and is never counted as met
- For `sprint` scope: a sprint-level escalation warning is prepended if any Must Have story is not READY (NEEDS WORK, BLOCKED or NOT ASSESSED)
- The skill offers to draft missing sections in conversation but never uses Write or Edit tools

## Immutability Rules
- READS but does NOT modify: story files, research notes, threat models, `docs/architecture/control-manifest.md`, `docs/architecture/tr-registry.yaml`, all ADR files, `design/specs/domain-map.md`, sprint files, `contracts/` (existence-only Glob checks)
- MODIFIES: nothing

## Hard Constraints (Never Violate)
- Never use Write or Edit tools under any circumstances
- Never draft corrections directly into files — offer drafts in conversation only
- Never mark a story READY if its governing ADR has `Status: Proposed`, `Deprecated` or `Superseded`, at any tier
- Never mark a story READY if a dependency story file is missing or has `Status: Draft`
- Never mark a backend or client story READY while the contract story it depends on is not `Complete`
- Never mark a security-sensitive story READY without a threat model (or, at `minimal`, a research note whose Security notes cover the model), at any tier or review mode
- Never mark a non-exempt story READY without its research note, or with a `Draft` note whose gaps the user has not accepted in writing on the story
- Never mark a security-sensitive story READY while its threat model's residual risk has no named acceptor (any tier or review mode)
- Never re-read the same ADR file multiple times in one run — cache ADR statuses after the first read
- Never penalize a story for missing `Manifest Version:` if `control-manifest.md` does not exist
- Never penalize a story for missing TR-ID if `tr-registry.yaml` does not exist — and never report it as passed either: it is `not checked — tr-registry.yaml absent` (NOT ASSESSED for that item at `full`, a Gap at `standard`/`minimal`)
- Solo or lean review mode skips the QL-STORY-READY and SL-THREAT-MODEL director opinions, never the checklist

## Downstream Skill Expects
**Next skill:** /dev-story

It will rely on this skill's verdict as follows:
- If verdict is READY: `/dev-story` proceeds with implementation using the story file as its source of truth
- If verdict is NEEDS WORK, BLOCKED or NOT ASSESSED: `/dev-story` must not be run until the story is corrected (or, for NOT ASSESSED, made readable) and re-validated — a story nobody could evaluate has not been shown ready
- `/dev-story` reads the same story fields this skill validates — a READY verdict is an implicit guarantee that those fields are present, parseable, and internally consistent:
  - `Type:` field is set to a valid story type
  - `## Acceptance Criteria` contains specific, testable checkbox items
  - `## Test Evidence` specifies a concrete evidence path
  - The research note exists (or the exemption is valid) and, for sensitive stories, the threat model exists and is linked
  - The contract story it depends on is merged
  - The governing ADR exists and has `Status: Accepted`
  - `Manifest Version:` matches the current control manifest
  - `TR-ID` in `## Context` is present and resolves in `docs/architecture/tr-registry.yaml` (when the registry exists)
  - `## Dependencies` section is present (may say "None")
  - `## Out of Scope` section is present (checked for existence; `/dev-story` uses it to enforce implementation boundaries)

## Known Fragile Points
- If `control-manifest.md` is regenerated with a new `Manifest Version:` date, every story that embeds the old date will fail the manifest version check — a bulk update of all story `Manifest Version:` fields is required before stories can pass readiness again
- If an ADR is silently renamed or moved after stories reference it by ID, the ADR file-existence check will BLOCK those stories even though the decision content is unchanged
- The manifest version comparison is a string date match, not a semantic version comparison — if the date format changes (e.g., from `2026-01-15` to `Jan 15 2026`), all stories will fail the check regardless of actual currency
- Referenced-file checks use Glob — a path-separator or case mismatch may cause a Glob miss that incorrectly flags a file as missing
- Without a registry the TR-ID status check is `not checked` (never a pass), so placeholder IDs like `TR-[feature]-???` surface as a Gap instead of slipping through; at `full` it makes the story NOT ASSESSED for that item
- The research note is matched to a story by feature slug when the story does not name it; a renamed spec breaks the match and the story reads as "research MISSING" until the link is added
- The threat-model trigger is judged from the story text and its spec; a story that does not mention a sensitive area it actually touches is under-detected — the spec's Non-Functional Requirements and the research note are the cross-check
- Contract-merged status is read from the contract story's `Status:` line, not from git; a contract story marked Complete but not actually merged passes this check
- For `sprint` scope, the skill depends on sprint file formatting to extract story paths — if the sprint file format changes, story paths may not be parsed and the scope silently reduces to zero stories validated
