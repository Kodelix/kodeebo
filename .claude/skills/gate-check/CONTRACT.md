# /gate-check — Handoff Contract

## Role in Pipeline
Validates whether the product is ready to advance from one stage to the next by auditing required artifacts, quality checks and the Definition of Done evidence the stage depends on, producing a PASS / CONCERNS / NOT ASSESSED / FAIL verdict — **advisory; the user decides** — and, on PASS with user confirmation, or on CONCERNS when the user explicitly accepts the listed risks, writing the new stage name to `project.stage` in `project.yaml` (never creating the legacy mirror `production/stage.txt`; an already-existing one is updated in the same write). Verdict precedence, first match wins: FAIL, CONCERNS, NOT ASSESSED, PASS (NOT ASSESSED outranks PASS — a gate that could not check part of its scope has not established readiness; see `references/5-verdict.md`).

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `project.yaml` (`project.stage`, legacy mirror `production/stage.txt`) | Stage name (used when no argument is provided, to auto-detect the current stage) | Yes |
| `project.yaml` (`modes.workflow`, which follows `modes.rigor` — `minimal` by default; `workflow_overrides.system_overrides.*`, `workflow_overrides.edge_cases`, `workflow_overrides.tuning_knobs`) | Workflow tier — selects the per-gate artifact checklist (Section 2b); per-feature overrides resolved when validating feature specs | Yes |
| `project.yaml` (`stack.*`, `deploy.target`, `distribution.model`, `tenancy.model`, `layout.code_roots`, `accessibility.target`, `performance.enforce`) | Stack profile — an empty value makes the check that depends on it NOT ASSESSED, never a permissive default | Yes |
| `docs/stack-reference/pins.yaml`, `docs/stack-reference/<layer>/VERSION.md` | Pinned versions, post-cutoff risk (read for stack validation and `project-coherence.sh`) | Yes |
| `docs/consistency-failures.md` | Domain-tagged entries surfaced as increased-scrutiny context (read if exists; skip if absent) | Yes |

### Phase-specific inputs (subset read depending on target gate)
| Target Gate | Key Files Checked |
|-------------|------------------|
| Discovery → Product Design | `design/product-brief.md` (REQUIRED fields filled); at `standard`/`full` also principles (`design/product-principles.md` or in the brief), `PRODUCT.md`/brand line, fuller brief sections |
| Product Design → Architecture | `design/specs/domain-map.md`, all MVP feature specs in `design/specs/`, `design/specs/spec-cross-review-*.md`, `design/specs/pricing-model.md`, `design/registry/entities.yaml`; not applicable at `minimal` |
| Architecture → Pre-Production | `project.yaml` stack, `docs/stack-reference/`, `docs/architecture/architecture.md`, ADRs (≥3 Foundation), `requirements-traceability.md`, `tr-registry.yaml`, the architecture review report, `docs/architecture/threat-models/`, `licence-model.md` (self-hosted/hybrid), `perf-budgets.md`, `slos.md`, `PRODUCT.md`/`DESIGN.md`, `design/accessibility-requirements.md`, `design/ux/`, test framework + CI; `adr-dep-graph.sh`, `project-coherence.sh`. At `minimal`: stack configured + Foundation decisions in the brief's decision log |
| Pre-Production → Production | `prototypes/*-vertical-slice/REPORT.md` (recommended), `production/sprints/` (first sprint plan), `production/epics/` (Foundation + Core context epics, stories with TR-IDs), `docs/architecture/control-manifest.md`, Accepted Foundation/Core ADRs, `docs/research/<feature>.md` for the first features, `design/ux/` key screen specs + `/ux-review`; at `minimal` only a filled brief with build order, stories under `production/epics/`, research notes, and the two current-build checks |
| Production → Hardening | code roots (resolved per `layout.code_roots` or detection), per-layer test locations with all Logic/Integration/Contract/Security stories covered, `production/qa/smoke-*.md` (PASS or PASS WITH WARNINGS), `production/qa/` QA plan + `/team-qa` sign-off, `production/qa/usability/` (≥3 sessions at `full`), story files + `production/qa/evidence/`, `production/qa/bugs/`, migration files |
| Hardening → Release | Full story evidence for all Must Have stories, QA sign-off (and UAT sign-off where in scope), the newest full-scope `production/qa/security-audit-*-full.md` (plus any later `quick` re-run), scan results (`govulncheck`, OSV-Scanner, container scan, `gitleaks`, SBOM), `production/localization/` QA verdicts, `production/releases/` release checklist, changelog/release notes, restore-drill record, rollback plan, `docs/runbooks/`, `docs/architecture/slos.md` (`full`), `deploy/self-hosted/` (self-hosted/hybrid), `project-coherence.sh` output |
| Release → Live | `production/releases/[product]-[version].md`, `production/releases/launch-checklist-[date].md`, post-deploy smoke report, observability evidence, runbooks, tracking plan sample, store review outcomes |

### Preconditions
- The target phase argument must be one of: `product-design`, `architecture`, `pre-production`, `production`, `hardening`, `release`, `live`; if omitted, auto-detects from `project.stage` and validates the next transition, after confirming with the user. At `Live` there is no next gate.
- The skill does not require any prior skill to have run in the same session, but it will surface missing prerequisites (e.g., missing ADRs, missing usability sessions) as blockers in the verdict.

## Outputs Produced

### Files Written
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `production/gate-checks/gate-[phase]-[date].md` (or path chosen by user) | Full checklist with per-item status, "Checks that did not run", Blockers list, Recommendations, Verdict, Chain-of-Verification note | written only after user approves ("May I write this gate check report to production/gate-checks/?") |
| `project.yaml` (`project.stage`) + legacy `production/stage.txt` only if it already exists | New stage name (never creates `stage.txt`; updates it only if it exists) | written ONLY when the verdict is PASS and the user explicitly confirms, or the verdict is CONCERNS and the user explicitly accepts the listed risks; never written on FAIL or NOT ASSESSED; never creates `project.yaml` |
| `production/session-state/active.md` | One appended line: gate, verdict, date, report path | append only |

### Output Guarantees
- The gate report always contains: artifact checklist (with file sizes or "MISSING"), quality check results, a "Checks that did not run" list (empty only if everything ran), list of blockers (empty if PASS), recommendations, the Director Panel summary with omitted perspectives named, and the Chain-of-Verification note — plus an `### Accepted Risks` section (each concern, accepted by the user, dated) when the user advanced on CONCERNS
- `project.stage` (and the legacy mirror, only if it already exists) is updated to the new stage name only on a confirmed PASS, or on CONCERNS after the user explicitly accepts the risks — never speculatively
- Any item that cannot be automatically verified is marked `MANUAL CHECK NEEDED` and the user is asked before the verdict is finalized
- A script (`artifact-check.sh`, `spec-structure-check.sh`, `adr-dep-graph.sh`, `project-coherence.sh`, `migration-lint.sh`) that did not run, or printed `SKIPPED`, is named in the report; it never counts as a clean result

## Immutability Rules
- READS but does NOT modify: all feature specs in `design/specs/`, all ADRs and threat models in `docs/architecture/`, `docs/architecture/control-manifest.md`, `docs/architecture/tr-registry.yaml`, `docs/stack-reference/**`, all story files in `production/epics/`, all sprint files in `production/sprints/`, QA, evidence and release files, source files in the code roots (Grep only), deploy files, test files (run via Bash, local stack and seeded test tenant only)
- MODIFIES: `project.yaml` (`project.stage` only) + legacy `production/stage.txt` (only if it already exists; never created; written on a confirmed PASS or an accepted CONCERNS override only), `production/gate-checks/[report].md` (new file, with user approval), `production/session-state/active.md` (append)
- Does NOT modify story files, ADRs, specs, or any source/test code

## Hard Constraints (Never Violate)
- Never creates `production/stage.txt` — it is updated only when it already exists (a project created before 2026-10-13), in the same approved write as `project.yaml`
- Never writes stage (either `project.yaml` `project.stage` or legacy `production/stage.txt`) unless the verdict is PASS and the user has explicitly confirmed advancement, or the verdict is CONCERNS and the user has explicitly accepted every listed risk (recorded in the report's `### Accepted Risks`)
- Never writes stage on a FAIL or NOT ASSESSED verdict under any circumstances — no override turns either into a stage change
- Never auto-advances stage — even a PASS verdict requires explicit user confirmation before the file is written
- Never assumes PASS for items that cannot be automatically verified — always marks them `MANUAL CHECK NEEDED` and asks the user
- Never blocks the user from working — the verdict decides only whether the stage is written; a CONCERNS override records the accepted risks in the gate report
- Never passes a director "none" for an artifact the target gate does not require yet — that is "not expected before [phase]" (or "not required at `workflow: [tier]`"), and not a finding; "none" is reserved for an artifact the gate asks for that does not exist
- Always runs Chain-of-Verification (5 challenge questions) after drafting the verdict before finalizing it
- Never runs anything against a shared, staging or production environment, never deletes volumes, never makes a payment, never asks for a secret
- If a vertical slice was built and any validation item is NO at the Pre-Production → Production gate, the verdict is automatically FAIL regardless of all other checks, at every tier; at `minimal`, where the slice items drop, a "no" to either current-build check (the core journey delivers its value, it runs end to end) is FAIL the same way (tier reductions relax what must *exist*, never make a broken build passable)
- At Hardening → Release: any `LICENCE` line from `project-coherence.sh` for `deploy/self-hosted/`, any open CRITICAL/HIGH in the newest full-scope security audit (unaccepted), or a required scan that did not run is a Blocker at every tier. `distribution.model` empty makes the licence check NOT ASSESSED
- Workflow-tier reductions (Section 2b) only ever *relax* a requirement (Required → CONCERNS-if-absent, or drop); they never add one, and never drop a floor a gate file names. The sole exception that adds is `workflow_overrides`: a feature pinned via `system_overrides` to a higher tier than the project blocks the gate until that one feature's spec meets the higher section count; `edge_cases` / `tuning_knobs` force those sections required. An override key that matches no spec in `design/specs/` is reported as a CONCERNS-level error naming the key and the stems that exist
- gate-check honors `modes.workflow` but is exempt from `modes.automation` — the collaborative prompting protocol (the Collaborative Protocol section) always applies; a phase gate is never auto-run

## Downstream Skill Expects
**Next skill (on PASS):** varies by gate

| Gate Passed | Enabled downstream skill |
|-------------|-------------------------|
| Discovery → Product Design | `/map-domains` — or `/design-spec` for the first feature when `design/specs/domain-map.md` already exists |
| Product Design → Architecture | `/create-architecture` first — the architecture blueprint and the ADR work plan (it needs the stack, so `/setup-stack` if none is configured) — then `/threat-model` for sensitive features and `/architecture-decision` |
| Architecture → Pre-Production | `/create-control-manifest` if `docs/architecture/control-manifest.md` does not exist yet, then `/vertical-slice`; `/create-epics` and `/create-stories` once the slice has validated the architecture and core journey |
| Pre-Production → Production | `/dev-story`, `/sprint-plan`, `/story-readiness` |
| Production → Hardening | `/team-hardening`, `/security-audit full`, `/load-test`, `/perf-profile`, `/smoke-check` |
| Hardening → Release | `/launch-checklist`, `/team-release` (the release checklist, changelog and security audit are done before this gate) |
| Release → Live | `/team-growth`, `/retrospective`; `/incident` and `/hotfix` as needed |

- Downstream skills read `project.stage` from `project.yaml` (fallback `production/stage.txt`) to confirm their stage is active before proceeding
- `/create-epics` reads `docs/architecture/control-manifest.md` — required at `full`, read if present at `standard` — and the Pre-Production → Production gate checks it

## Known Fragile Points
- `project.stage` in `project.yaml` (with the legacy mirror `production/stage.txt`) is the authoritative stage indicator — if either is manually edited to a wrong value outside of `/gate-check`'s stage write, auto-detection in future sessions will be incorrect; never edit them outside `/gate-check`'s stage write. A stage name with the wrong spelling or case is dropped by `resolve_config`
- The Production → Hardening and Hardening → Release gates run the test suites via Bash. If no command is sourced for a layer or the runner fails to start, the test check yields `NOT ASSESSED`, which outranks PASS — so the gate cannot advance a stage on the strength of a suite that never ran
- The Pre-Production → Production gate has a hard vertical slice validation block; any subjective checklist item (e.g., "the core journey feels sound") requires a user response via `AskUserQuestion` — if the user answers without having used the build, a false PASS is possible
- Gate report files in `production/gate-checks/` are not validated for completeness by any downstream skill; a partial report written due to a session interruption will look identical to a complete one
- `docs/consistency-failures.md` is optional context that adjusts scrutiny but does not change the formal checklist; if this file exists but is stale, the increased-scrutiny signals may point at resolved issues
- `artifact-check.sh` depends on the workflow catalog; when it is missing the script does not run and the existence scan falls back to Glob, which the report must say
- The Release → Live gate relies on records the team made in production; this skill does not observe production and cannot tell a fabricated record from a real one beyond a consistency read
