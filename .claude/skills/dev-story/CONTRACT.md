# /dev-story — Handoff Contract

## Role in Pipeline
Bridges planning and code. Loads the full context for a single story (story file,
research note, threat model, contract ordering, TR registry, ADR, control manifest,
stack reference), refuses to start without the research note (or a documented
exemption) and, for a sensitive story, the threat model; resolves the layer(s)
from the story and the `stack` profile; routes to the right stack lead **through
`principal-engineer`**; plans the evidence the eight DoD gates need before coding;
drives implementation (tests first for Logic stories); runs the layer checks and
reports their real output; and leaves the story ready for `/code-review` and
`/story-done`.

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `production/epics/**/*.md` (the story file) | `Status: Ready`, `Type`, `Code root`, `Owner agent`, `TR-ID`, `Research note`, `Threat model`, `Contract`, `Governing ADR`, `Manifest Version`, `## Acceptance Criteria`, `## Test Evidence`, `## Definition of Done Evidence`, `## Dependencies`, `## Out of Scope` | **Partially mutable.** Sets `Status:` to `In Progress` and `Last Updated:` before spawning any agent (Phase 2); on an ADR mismatch answered `[A]` sets `ADR Version` and refreshes the summary and Implementation Notes; on a manifest mismatch `[A]`/`[B]` sets `Manifest Version:` (and on `[B]` adds `Manifest-Note:`); adds an `## Evidence Plan` section after the user approves it (Phase 4). Everything else is read-only |
| `docs/research/<feature>.md` | Versions, Decision, Security notes, Performance & caching notes, Observability notes, Open questions — **or** the story states `Research: exempt — [row]` | Yes |
| `docs/architecture/threat-models/<feature>.md` | Threat table with mitigations → ASVS/MASVS IDs → stories → negative tests — required when the story hits a `security-baseline.md` trigger | Yes |
| `contracts/` | The operation the story consumes or exposes; the contract story is `Complete` before a client or backend story starts | Yes (Glob/Grep) |
| `docs/architecture/tr-registry.yaml` | Entry matching the story's TR-ID with current `requirement` text | Yes |
| `docs/architecture/adr-NNNN-[slug].md` (referenced ADR) | `## Status`, `## Last Verified` (else `## Date`) — grepped; `## Decision`, `## Stack Compatibility`, `## ADR Dependencies` — read only on a version mismatch answered `[A]` | Yes — the ADR is never edited |
| `docs/architecture/control-manifest.md` | `Manifest Version:` header, layer rules | Yes |
| `project.yaml` | `stack.*`, `tenancy.model`, `distribution.model`, `core.*`, `layout.code_roots`, `naming.*` (via `resolve_config` and `resolve_code_root`) | Yes |
| `docs/stack-reference/<layer>/` + `pins.yaml` | `VERSION.md` (pinned version, risk rating), `best-practices.md`, `deprecated-apis.md`, `breaking-changes.md` | Yes |
| `docs/architecture/perf-budgets.md` | The budget row for the surface (absent → `budget not yet set`) | Yes |
| `PRODUCT.md`, `DESIGN.md` (repo root), `design/ux/<screen>.md` | UI stories only | Yes |
| `production/session-state/active.md` | (read to find active story when no argument given; created if absent) | No |

> **Tier.** The TR registry is required at `full`, optional at `standard`, not
> expected at `minimal`; a missing control manifest warns at `full`/`standard`
> and is not expected at `minimal`; an ADR blocks only when the story references
> one that is missing or not Accepted. **The research note, the threat model for
> a sensitive story, contract-first ordering and the eight DoD gates apply at
> every tier** — `minimal` has fewer documents, not weaker engineering.

### Preconditions
- The target story has `Status: Ready` (validated by `/story-readiness` at `standard`/`full`; at `minimal`, `/create-stories` writes stories `Ready`)
- The research note exists (or a valid documented exemption) — **no lead is spawned without it**
- A sensitive story has a threat model (and no SL-THREAT-MODEL `REJECT`)
- Any Contract story the work depends on is `Complete`
- The referenced ADR has `Status: Accepted`; `Proposed`, `Deprecated`, `Superseded` or a missing file blocks. A story whose ADR field reads `N/A` references none
- All `## Dependencies` stories have `Status: Complete` or `Done` (or the user explicitly accepts the risk; never for a contract dependency of a client story)
- Every `stack.*` layer the story touches is set in `project.yaml` (an `unset` layer is a STOP, never a default) and `resolve_code_root` returns the roots the story names

## Outputs Produced

### Files Written
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| Source under the story's code roots (`backend/`, `web/`, `mobile/…`, `contracts/`, `deploy/` per lane) | Doc-commented public APIs; no hardcoded business values; follows ADR guidelines, control-manifest rules and the layer's `.claude/rules/` | created or modified by the leads via `principal-engineer`; roots resolved with `resolve_code_root` |
| Test files per layer test location (`*_test.go`, `src/test/kotlin/`, `src/integrationTest/kotlin/`, `*.test.ts(x)`, `src/commonTest/kotlin/`, Swift Testing targets, `contracts/` consumer tests) | One or more tests per acceptance criterion; negative and cross-tenant tests for every tenant-data story; deterministic, isolated, real dependencies for integration | created by the leads; Logic tests written first and seen failing |
| `production/qa/evidence/<STORY-ID>/` | `checks-<layer>.md` (command, exit code, trimmed output — including `not run — [reason]` lines), run-and-observe evidence (API request/response per role, screenshots incl. Arabic/RTL, one trace), `/impeccable audit` summary for UI | written by this skill (check output) and by the leads/`ui-designer` (observations) |
| `production/session-state/active.md` | `<!-- CHECKPOINT -->` block: current task, next step, blocker, files in progress, run result | block overwritten, never appended |

### Output Guarantees
- No lead is spawned for a story that lacks its research note (or valid exemption), a required threat model, or a merged contract. The refusal names the fix (`/research`, `/threat-model`, the contract story, `/setup-stack`)
- Routing follows the `stack` profile and the story's code root; an `unset` layer is reported, not defaulted. Leads are reached through `principal-engineer`; UI stories go through `ui-designer` and `/impeccable`
- An eight-gate evidence plan (plus run-and-observe) exists before code is written, and the user approved it; waivers are the user's, never the model's, and security evidence on a sensitive story cannot be waived by the model
- Logic stories show tests failing before they pass
- The summary reports **real output** for every layer check (command, exit code, decisive lines). A check that could not run is listed under **Not run** with its reason and is never counted as passed; a failing check keeps the story from `Implementation Complete`
- The summary states a **run result** — `OBSERVED` (with retained paths), `OBSERVED — partial`, `NOT VERIFIED — <reason>` or `N/A — <reason>`. Not waived at any `qa.level`
- Tests are never waived by `qa.level`: Logic, Integration, Contract and Security tests exist and pass at every tier; a missing tests row is reported as a gap. Security negatives, tenant-isolation tests, run-and-observe and UI screenshots are not waived either
- **Completion is not assumed.** If a lead stopped early, an artifact is not on disk or a check fails, the story is reported INCOMPLETE / Needs Attention with the breakage named

## Immutability Rules
- READS but does NOT modify: `project.yaml`, `docs/architecture/tr-registry.yaml`, ADR files, `design/specs/**`, `docs/architecture/control-manifest.md`, `docs/research/**` (a contradicted note is updated by the lead *first*, after the user is told — never silently), threat models, `docs/stack-reference/**`, `contracts/` outside the contract lane
- MODIFIES, via agents: the story's code roots and test files
- MODIFIES, itself, each after an ask that names the file (in `collaborative` mode; `.claude/docs/automation-modes.md` governs the others): the story file's `Status:`, `Last Updated:`, `Started:`, `Research gap accepted:`, `ADR Version`, `**ADR Decision Summary**`, `## Implementation Notes`, `Manifest Version:`, `Manifest-Note:`, `## Evidence Plan`; the story's entry in `production/sprint-status.yaml`; a dependency story's `Status:` (option `[C]` only); a Config story's data file
- MODIFIES without an ask: `production/session-state/active.md` checkpoint; new files under `production/qa/evidence/<STORY-ID>/` that this skill names (check output)
- Sets the story's own `Status` to `In Progress` (Phase 2, with a `Started:` date) and, only when the Phase 7 headline is `Implementation Complete`, to `In Review` (the hand-off `/story-done`, `/story-readiness` and `/studio resume` read). Never `Complete`: closing the story is the exclusive responsibility of `/story-done`

## Hard Constraints (Never Violate)
- Never begins implementation without the research note or a valid documented exemption, and — for a sensitive story — the threat model
- Never lets a client story start before its contract story is Complete
- Never marks a story `Done`/`Complete` on its own judgement (dependency option `[C]` excepted, after an ask)
- Never implements a story whose referenced ADR has `Status: Proposed`, `Deprecated` or `Superseded`
- Never defaults an `unset` stack layer, and never writes an API, flag, config key or version from memory — the stack reference wins; a gap is `NOT SOURCEABLE`, not filled
- Never reports a check that did not run as passed
- Never weakens, skips or deletes a test, lint rule, scan or gate to make work pass
- Never touches files in `## Out of Scope` without explicit user approval
- Never deviates from the ADR's Implementation Guidelines silently; never makes an architectural decision in code that no ADR covers — it is raised and recorded
- Never modifies ADR files or spec files; never edits `saas-core-*` from a product repo
- Source and test files are written by leads via `Agent`; this orchestrator writes none directly (Config data files after an ask excepted)

## Downstream Skill Expects
**Next skills:** `/code-review`, then `/story-done`
- They read: the story file (`Status`, `## Acceptance Criteria`, `## Test Evidence` paths, `Type:`, ADR, TR-ID, `## Evidence Plan`), the research note, the threat model, `production/qa/evidence/<STORY-ID>/`
- They assume: the test files declared in `## Test Evidence` exist on disk at those exact paths; `production/session-state/active.md` records the story path, files changed, the `Run result:` line and the open "Not run" checks; the files under the code roots match the criterion descriptions so Grep-based deviation checks can run

## Known Fragile Points
- A test path in `## Test Evidence` that does not match what the runner picks up produces a false "tests exist" downstream — the Phase 6 test-count check exists to catch it
- Stale research note (older versions than `pins.yaml`) — Phase 2 asks rather than silently proceeding
- A story `Risk:` that disagrees with `docs/stack-reference/<layer>/VERSION.md` — the reference wins; an unknown counts as HIGH
- Integration tests, `-race` and run-and-observe need a container runtime; Swift tests need macOS — hosts without them produce `not run`, which must carry through to `/story-done` as an unmet BLOCKING gate, not a pass
- Sub-agent failures are non-fatal by design (partial reports are surfaced), but a blocked lead means no source files are written — `/story-done` will fail its file-existence checks
- Config stories produce no test file; `/story-done` must see `Type: Config` in the header to classify the story correctly
