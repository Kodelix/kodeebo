# /story-done — Handoff Contract

## Role in Pipeline
Closes the implementation loop for a single story by verifying every acceptance
criterion **with evidence**, establishing that tests actually passed, checking the
**eight Definition of Done gates** with evidence paths (PE-DOD), confirming the
run-and-observe record is on disk in `production/qa/evidence/<STORY-ID>/`,
detecting spec/ADR/threat-model deviations, and — after user approval — updating
the story file to `Status: Complete` with a `## Completion Notes` section.

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `production/epics/**/*.md` (the story file) | `Status:` (expected `In Progress`, or `In Review`; `Ready` if `/dev-story` was skipped), `Story ID`, `Type:`, `Code root`, `Manifest Version`, TR-ID(s), ADR reference(s), `Research note`, `Threat model`, `Contract`, `## Acceptance Criteria`, `## Test Evidence` paths, `## Definition of Done Evidence` | No — status, DoD table rows, gate-verdict header lines and completion notes written after approval |
| `docs/research/<feature>.md` | Exists (or the story's valid exemption), dated before the first implementation commit, pinned versions, sources | Yes |
| `production/qa/evidence/<STORY-ID>/` | `checks-<layer>.md` test/lint/scan output, run-and-observe records (API per role incl. negative path, screenshots incl. Arabic/RTL, one trace), ASVS/MASVS mapping and negative-test results (Security), load-test result (Performance), `/impeccable audit` summary (UI) | Yes (this skill may add `checks-<layer>.md` files when it runs the checks itself) |
| `docs/architecture/threat-models/<feature>.md` | For any sensitive story | Yes |
| `docs/architecture/perf-budgets.md` | The surface's budget row (absent → `budget not yet set`) | Yes |
| `docs/architecture/tr-registry.yaml` | Entry per TR-ID with current `requirement` text | Yes |
| Spec section referenced by each TR-ID | Acceptance criteria and key rules for cross-check | Yes |
| `docs/architecture/adr-NNNN-[slug].md` (referenced ADR) | `## Decision`, `## Consequences` | Yes |
| `docs/architecture/control-manifest.md` | `Manifest Version:` header date, forbidden patterns | Yes (existence checked; absent = skip staleness check, stated) |
| `docs/stack-reference/<layer>/deprecated-apis.md` | Deprecated entries scanned for | Yes |
| `production/session-state/active.md` | Active story path; the `Run result:` line | No — `<!-- CHECKPOINT -->` block overwritten |

> **Tier.** The TR registry, spec-section and ADR rows are `standard`/`full`
> inputs. At `workflow: minimal` the story traces to `design/product-brief.md` and
> Phase 4 runs the acceptance-criteria check only for spec/ADR traceability; the
> manifest, hardcoded-value, scope, research-note and tenancy/secret checks still
> run. `qa.level` never waives
> a test: Logic, Integration, Contract and Security tests exist and pass at every
> tier, and so do run-and-observe, a UI story's screenshots, a Security story's
> negatives and ASVS/MASVS mapping, tenant-isolation tests, the dependency scan and
> the eight-gate table. It only changes the *extra* evidence asked for.

### Test Evidence by story type (presence checked; pass state established separately)
| Story Type | Expected evidence |
|------------|-------------------|
| Logic | Unit tests beside the code, **passing** |
| Integration | Testcontainers tests against the real dependency, passing |
| Contract | Consumer contract test + breaking-change output, passing; authz tests per endpoint |
| Security | Negative tests passing + ASVS/MASVS mapping in `production/qa/evidence/<STORY-ID>/`; sign-off |
| Performance | k6 result vs the `perf-budgets.md` row, with environment and data volume |
| UI | Retained screenshots of every screen (1440/390 px, Arabic/RTL + English) + `/impeccable audit` result |
| Config | `production/qa/smoke-*.md` |

### Preconditions
- The story file must be findable by argument path, in `production/session-state/active.md`, or in the current sprint file as `IN PROGRESS`
- Implementation must have been attempted — this skill verifies; it does not implement
- Code roots resolve (`resolve_code_root`); an empty result makes the code-scanning checks `NOT ASSESSED`, never "zero hits"

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH NOTES` / `NOT ASSESSED` / `BLOCKED`.

Precedence: `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH NOTES`, then
`COMPLETE`. `NOT ASSESSED` outranks `COMPLETE` — a criterion or gate could not be
evaluated (a test run, a scan, a measurement that did not happen), which is not the
same as evaluating it and finding it met — and ranks below `BLOCKED`. Gate-agent
verdicts map: PE-DOD / PE-CODE-REVIEW / SL-TENANT-ISOLATION `REJECT` or QL-TEST-COVERAGE
`INADEQUATE` → BLOCKED; `CONCERNS` / `GAPS` → COMPLETE WITH NOTES at best;
`NOT ASSESSED` → NOT ASSESSED at best.

## Outputs Produced

### Files Written
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `production/epics/**/*.md` (the story file) | `Status: Complete`, DoD Evidence table statuses, gate-verdict header lines, `## Completion Notes` (date, criteria count, deviations, test evidence and tests-not-run, run-and-observe result, eight-gate summary with evidence folder, waivers, security override, code review status, untested criteria) | updated after explicit user approval |
| `production/qa/evidence/<STORY-ID>/checks-<layer>.md` | command, exit code, trimmed output or `not run — [reason]` | only when this skill runs the checks itself (user chose "run now") |
| `production/sprint-status.yaml` | `status: done`, `completed: [date]`, top-level `updated` | updated silently alongside the story file if the file exists (stated if absent) |
| `docs/tech-debt-register.md` | Advisory deviation/gap rows, Security rows for an override (if user agrees) | appended per `/tech-debt`'s register format |
| `production/session-state/active.md` | `<!-- CHECKPOINT -->` block with the final verdict and the next story | overwritten, never appended |

### Output Guarantees
- `Status: Complete` is written only after the user explicitly approves, and on a BLOCKED or NOT ASSESSED verdict only when the user explicitly asks to close anyway (the Phase 8 override, always prompted as `scope_changes`), with the override risk recorded
- The report always carries: the criterion traceability table, test results per layer (`passed` / `FAILED` / `not run` / `stale`), the run-and-observe line and folder listing, **the eight-gate table with level, status and an evidence path or number in every row**, waivers, gate/review lines (verdict or `skipped — [mode]`), deviations, and a `Not run / not checked` list
- Every waiver is a written, user-approved reason in the story file; the model never authors or infers one; **security evidence on a security-sensitive story is never offered for waiver**
- A close-anyway on a sensitive story records the residual risk with owner, expiry and the user's acceptance
- `## Completion Notes` always contains: completion date, criteria pass count, deviation summary, test evidence (or "None required"), tests not run, DoD gates, waivers, code review status
- A skipped director gate is recorded `skipped — [mode]`, never as passed; skipping PE-DOD never skips the eight-gate table

## Immutability Rules
- READS but does NOT modify: `docs/architecture/tr-registry.yaml`, ADR files (Decision + Consequences only), spec sections, `docs/architecture/control-manifest.md`, `docs/research/**`, threat models, `docs/stack-reference/**`, source files under the code roots (Grep only) and test files (existence and content; they are run only via the layer-checks table after the user chooses "run now")
- MODIFIES: the story `.md` file (status, DoD rows, gate header lines, completion notes), `production/sprint-status.yaml`, `production/session-state/active.md` (checkpoint), `docs/tech-debt-register.md` (append rows and update its `Last updated:` / `Total items:` lines, only with user approval), and new `checks-<layer>.md` files under the evidence folder
- Does NOT write to the code roots or edit test files under any circumstances

## Hard Constraints (Never Violate)
- Never sets `Status: Complete` without explicit user approval (Phase 8's `AskUserQuestion` menu — "Verification complete. How do you want to proceed?" with `Close the story` as an option — is that approval; a menu choice other than a close option writes nothing)
- Never counts a test file's existence as the tests passing — pass state comes from output; `not run` and `stale` are reported as such
- Never marks a story COMPLETE while a BLOCKING DoD gate (or BLOCKING story-type evidence) is unmet, `not run` or `not checked` and not validly waived (`unmet` → BLOCKED; `not run` / `not checked` → NOT ASSESSED)
- Never marks a UI story Complete on missing retained screenshots; never describes an image it has not opened with `Read`
- Never treats a `NOT VERIFIED` run result on a user-visible or callable change as satisfied
- Never auto-fixes failing acceptance criteria — report failures and ask the user what to do
- Never proceeds to Phase 8 on its own on a BLOCKED or NOT ASSESSED verdict — list blockers and offer help; Phase 8 is reached only on the user's explicit request to close anyway, and then always prompts, even in autonomous mode
- Never silently overrides a BLOCKED verdict — document the override risk in `## Completion Notes`
- Never recalls ASVS/MASVS requirement IDs — they are quoted from the threat model/research note or marked `not checked`
- Never runs `git commit` — it suggests the command only

## Downstream Skill Expects
**Next skill:** `/gate-check` (phase gate) or the end-of-sprint review (`/smoke-check sprint` → `/team-qa sprint`)
- It reads: story files for `Status: Complete` and `## Completion Notes`
- It assumes: a Complete story whose resolved gate level is BLOCKING had its evidence **exist and pass**, with the output retained in `production/qa/evidence/<STORY-ID>/`; a `Tests not run` entry or a waiver in the notes is a recorded exception, not a pass
- It assumes: every Complete UI story has retained screenshots, every Complete Security story has negative tests and an ASVS/MASVS mapping, and every Complete story that touched tenant data has an isolation test result
- It reads: `production/sprint-status.yaml` for `status: done` entries, `docs/tech-debt-register.md` for logged debt

## Known Fragile Points
- The story's `## Test Evidence` section must contain the exact paths written by `/dev-story`; a mismatch causes a false BLOCKING result even if the file exists elsewhere
- If `Type:` is absent from the story header, evidence enforcement is ADVISORY only — stories can slip through without tests
- The research-first check and every freshness check follow the Dating rule in `references/2-read-story.md` (git commit date for tracked, clean files; file mtime for uncommitted ones; the artifact's own date line otherwise) and print the `freshness source:`; mtime is weaker evidence (a fresh checkout resets it) and a same-day date-line comparison cannot order two artifacts, so a squashed history or no usable source reports `dated: not determinable` (then gate 1 is `not checked`, not `met`)
- Manifest staleness is skipped when the control manifest does not exist; the skip is stated, non-blocking
- `production/sprint-status.yaml` update is silent; a different key structure makes it silently fail and sprint tracking stale
- The >50% UNTESTED escalation can be triggered by criteria that are legitimately DEFERRED (deployed stack, live provider, store review) — mark them `DEFERRED` explicitly to avoid false escalation
- Running the layer checks needs the toolchain, a container runtime and (iOS) macOS; where absent the result is `not run`, which keeps BLOCKING gates unmet
