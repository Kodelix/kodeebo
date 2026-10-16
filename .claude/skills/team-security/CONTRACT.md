# /team-security — Handoff Contract

## Role in Pipeline
Orchestrates one security cycle for a feature, area or release: threat model
(`/threat-model`), review and scans (`/security-audit`, `/dependency-audit`,
`/tenant-check`, privacy and studio-size specialists in parallel), a penetration-test
decision (hand-off only), fixes routed to the stack leads with regression tests, then
sign-off evidence for SL-RELEASE-SECURITY. `security-lead` directs, `appsec-engineer`
reviews and tests. Called directly by the user. Follows `/team-api` and `/team-feature`
for security-sensitive changes; feeds `/release-checklist`, `/gate-check`, `/team-release`
and `/team-hardening`. `/pentest` is user-invoked only and is never spawned from here.

## Inputs Consumed

| File | Used for | Absent means |
|---|---|---|
| Argument (feature / area / release), `--pentest`, `--resume <pentest-report-path>`, `--review full\|lean\|solo` | scope; `--pentest` includes the latest user-run `/pentest` report under `production/qa/evidence/` as an input to Phases 5-6 (none exists → the user is told to run `/pentest <scope>`, hand-off written after asking, pipeline paused; never a spawn); `--resume` skips to Phase 5 with that report as input | usage guidance is output; no agents spawned, no files read, no `AskUserQuestion` |
| `project.yaml` via `resolve_config` (`review_mode`, `automation`, `team.size`, `workflow`, `qa.level`, `testing.strict`, `stack`, `tenancy`, `distribution`) and `resolve_code_root` | active set, gate depth, scoping values | defaults in `.claude/docs/config-resolution.md`; an unset `stack`/`tenancy.model`/`distribution.model` is not "not applicable": ask, or mark the affected category `NOT ASSESSED`; unresolved code root or layer without source → `NOT ASSESSED`, never zero findings |
| `security-baseline.md` "Threat modelling" triggers (authentication, authorization, billing, licensing, file upload, webhooks, PII export/delete, admin/impersonation, new external integration) | which areas need a model | a trigger with no threat model is a finding (REJECT-class), not a missing input |
| `docs/architecture/threat-models/`, latest `production/qa/security-audit-*.md`, pentest reports under `production/qa/evidence/`, `production/qa/bugs/`, `production/gate-checks/`, `production/releases/` (release scope) | state of earlier work | reported ABSENT per item |

### Preconditions
- An argument is given (else usage guidance only)
- Each input is reported FOUND or ABSENT; the Phase 1 line "Security cycle for [scope] ... Ready?" is shown
- The active set is announced before Phase 1: agents spawned and agents named but not spawned at the resolved `team.size`
- `workflow` and `qa.level` never relax this pipeline; security evidence is required at every tier
- Accepting residual risk, scheduling or approving a penetration test, and any waiver of security evidence are never delegated to an `automation` mode, and never taken by an agent

## Verdicts Emitted
`COMPLETE` / `COMPLETE — [pentest | scan | mapping] NOT ASSESSED ([reason])` / `BLOCKED` /
`BLOCKED — write declined by user`. Security evidence status (this pipeline's own,
derived mechanically; first match wins): `NOT READY`, `NOT ASSESSED`, `CONCERNS`, `READY`.
- `NOT READY`: an open CRITICAL or HIGH not accepted by the user, a REJECT threat model for an in-scope area, or a gate verdict NOT READY.
- `NOT ASSESSED`: nothing above, but a scan or audit category did not run, an in-scope scoping value is unset, the control mapping is `NOT SOURCEABLE` for a category in scope, or a trigger has no threat model.
- `CONCERNS`: accepted risks, open MEDIUM/LOW, or dynamic testing not run on a release with a self-hosted or enterprise edition.
- `READY`: none of the above.
`NOT ASSESSED` outranks `READY` and ranks below `NOT READY`. Consumed: `/threat-model` (REJECT blocks that area; CONCERNS needs revise / accept with owner and expiry / discuss), SL-THREAT-MODEL, SL-TENANT-ISOLATION (inside `/security-audit` at `full`), SL-RELEASE-SECURITY (READY / CONCERNS / NOT READY / NOT ASSESSED; spawned here only at `review_mode: full`, otherwise recorded `SL-RELEASE-SECURITY skipped — [mode] mode`).
`COMPLETE` means the cycle ran and the evidence status is the security result; `BLOCKED` is a REJECT, an unresolvable input or a stop condition (partial report produced). A declined report write is `BLOCKED — write declined by user` and nothing is reported as `COMPLETE`.

## Outputs Produced

| File | Guaranteed sections |
|---|---|
| `production/qa/evidence/security-[slug]/team-security-report.md` | scope and triggers; active set; threat-model verdicts; audit and scan results with every NOT ASSESSED cause; penetration-test status; findings by severity and status; fixes routed and negative tests added; gate verdict or skip; control-mapping table (requirement ID with source URL or `NOT SOURCEABLE`, story, negative test, evidence path, status); scans table (tool, version, scope, result or `not run`); residual-risk list (owner, expiry); security evidence status; accepted risks. Written only after "May I write the team security report to ...?" and a yes |
| `production/qa/evidence/security-[slug]/privacy-review.md`, `review-[agent].md`, `fix-routing.md` | `privacy-compliance-specialist`; `auth-identity-specialist` / `multitenancy-specialist` (studio); `principal-engineer` (finding → owner → story or bug → fix window) |
| `production/qa/evidence/security-[slug]/pentest-handoff.md` | when a test is scheduled: targets, threat-model abuse cases and audit leads as test cases, seeded accounts; written after asking |
| Negative tests | test directories of the owning layer, at the paths the approved set named |
| Sub-skill artifacts (`/threat-model`, `/security-audit`, `/dependency-audit`, `/tenant-check`, `/bug-report`) | by those skills under their own protocols and approvals |
| `production/session-state/active.md` | this skill's own `## Security pipeline — <slug>` block, replaced in place with `Edit` (added after existing content if absent; `Write` only if the file is absent; no other block touched): scope, phase reached, evidence status, result, report path, next command, date |

### Output Guarantees
- Severity summary carries the NOT ASSESSED list beside it (scanners not installed, unscanned lockfiles, unset scoping values, requirement IDs `NOT SOURCEABLE`); a scanner not installed is `not run`
- A suspected live secret or cross-tenant exposure is announced immediately and routed to `security-lead`, not held to the phase end
- Fix windows are policy defaults (CRITICAL 48 h, HIGH 7 d, MEDIUM 30 d, LOW 90 d from triage) unless an ADR changed them; cross-tenant and credential findings are S1
- A finding is `OPEN` until re-verification evidence exists (`/security-audit quick`, `/test` on changed layers, `/pentest retest` for a pentest); re-verification output replaces the earlier status; a fix without its regression test is not done
- Penetration test not scheduled → `Penetration test: not scheduled — dynamic testing NOT ASSESSED`; for a self-hosted or enterprise release this is a CONCERN in Phase 6, not silence
- A named artifact that is not on disk is a failed phase; a skipped agent's section stays a named gap
- At `studio`, reviewers get the adversarial instruction and the report says the pass ran
- The report date comes from `date +%F`

## Immutability Rules
- **`penetration-tester` is never spawned by this skill or by `security-lead`**; `/pentest` is run only when the user types it (`disable-model-invocation`), and it refuses without written scope, a named approver and a window
- Security agents never make fixes; stack leads (via `principal-engineer`) write them after the file set was approved once
- Subagents write without asking only to paths this skill named, as new artifacts under `production/`, `docs/` or a test directory, in a phase gate; never an edit to existing source or config
- No `Edit` beyond the `active.md` line; the user alone accepts residual risk (with owner and expiry) or waives evidence
- A declined report write is `BLOCKED — write declined by user`

## Hard Constraints (Never Violate)
- The model never proposes waiving security evidence on a security-sensitive story; a finding left open is an accepted risk recorded by the user
- A REJECT threat model blocks implementation of that area; the pipeline continues only on unaffected scope if the user chooses
- Requirement IDs come from the official ASVS 5.0.0 / MASVS 2.1.0 / API Top 10 2023 documents with a source URL or are `NOT SOURCEABLE`
- A `security-lead` vs stack-lead conflict on a fix escalates to `cto`, then the user decides

## Downstream Skill Expects
`/release-checklist` and `/gate-check` read the report for SL-RELEASE-SECURITY (`/gate-check` still runs the gate when it was skipped here); `/team-release` for the release; `/dev-story` per open finding and `/security-audit quick` after each batch; `/team-hardening` for the performance, accessibility and QA passes beside it. `NOT ASSESSED` stays so downstream; an open finding is not closed by absence of evidence.

## Known Fragile Points
- `--pentest` with no report on disk produces only an instruction and a hand-off file; dynamic testing stays `NOT ASSESSED` until the user runs `/pentest`
- Phase 5 may start on the audit findings while a pentest is pending only if the user says so
- Nested spawning from a subagent may be unavailable; this skill spawns every agent
- Live scanner output, real `SL-RELEASE-SECURITY` verdict text and `/pentest` refusal behaviour cannot be checked statically
