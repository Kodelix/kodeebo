> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other six — one gate applies per invocation.


# Gate: Production → Hardening


**Required Artifacts:**
- [ ] The code roots have active code organized by bounded context in the `{domain, app, adapters}` layering (`.claude/docs/clean-architecture.md`); an unresolved code root is `NOT ASSESSED — code roots unresolved`, never zero findings
- [ ] All MVP features are implemented: cross-reference the brief's MVP list and `design/specs/` with the story files (`bash .claude/scripts/story-status.sh` gives each story's status as written) and with the code roots (Grep). Cite the numbers: stories Complete of total, MVP features with no story, stories Complete with no code
- [ ] The main user journey works end to end on a running stack (run-and-observe, `.claude/docs/run-and-observe.md`), with the retained observation in `production/qa/evidence/`
- [ ] Test files exist for every layer in scope (test locations in `.claude/docs/directory-structure.md` "Code roots") covering Logic, Integration, Contract and Security stories
- [ ] All Logic stories from this milestone have unit tests; Integration stories have Testcontainers suites against the real data stores; Contract stories have contract tests against `contracts/`
- [ ] Smoke check has been run with a PASS or PASS WITH WARNINGS verdict — report `production/qa/smoke-[date].md` (spot-read per Section 3)
- [ ] At least one QA plan exists in `production/qa/` (`/qa-plan`) covering this sprint, the final production sprint, or this stage — run `/qa-plan` if missing (CONCERNS — advisory, not blocking)
- [ ] QA sign-off report exists in `production/qa/` (`/team-qa`) with verdict APPROVED or APPROVED WITH CONDITIONS
- [ ] At least 3 distinct usability sessions documented in `production/qa/usability/` (`/usability-report`), covering first-run onboarding, the core journey, and an admin or billing flow
- [ ] The brief's success hypothesis (activation metric, value statement) has been explicitly validated or revised
- [ ] **Every Complete story meets the eight DoD gates or carries an approved written waiver** (`.claude/docs/coding-standards.md`): count the stories Complete, the stories whose `production/qa/evidence/<story-id>/` exists where their type requires it (UI, Security, Performance, Integration), and the waivers on file. Name the stories with neither evidence nor waiver
- [ ] PE-DOD recorded per Complete story (or recorded as skipped by mode); QL-TEST-COVERAGE recorded per story
- [ ] SL-TENANT-ISOLATION recorded for every Complete story that reads or writes tenant-owned data
- [ ] Every sensitive feature's threat-model mitigations are implemented and proven by passing negative tests (authz bypass, cross-tenant, injection) with ASVS/MASVS mapping in `production/qa/evidence/`
- [ ] Migrations in the milestone follow expand → migrate → contract and pass the lint: run `bash .claude/scripts/migration-lint.sh` over the migration files — `DANGER` lines are Blockers unless waived in the story, `MISSING` and `WARN` lines are CONCERNS (script did not run → NOT ASSESSED for this item)
- [ ] UI stories have retained screenshots (desktop and mobile, Arabic RTL and English) and a recorded `/impeccable audit` result in `production/qa/evidence/`
- [ ] Every implemented screen has a UX spec (no "designed in code" screens)

**Quality Checks:**
- [ ] Tests are passing (run the suites per layer — Section 3; `testing.strict.*` sets whether a failure is a Blocker)
- [ ] No open S1 Critical bugs in `production/qa/bugs/` or in known issues (parse `**Severity**` and `**Status**` as `/bug-triage` does; a bug file that cannot be parsed is listed, not skipped). A suspected cross-tenant exposure is S1 by definition
- [ ] The core journey behaves as the specs' acceptance criteria say (compare to the Acceptance Criteria sections, including the negative and cross-tenant cases)
- [ ] Performance is within budget: measured data against `docs/architecture/perf-budgets.md`, per `performance.enforce` (Section 3). Hot paths load-tested; no N+1 on the audited endpoints
- [ ] Observability is real: one retained trace per critical journey showing handler → use case → database/cache spans; RED metrics and structured logs carry `trace_id`; no PII in the telemetry sample inspected
- [ ] Usability findings have been reviewed and critical issues addressed (not just documented)
- [ ] No "confusion loops" — no point in the journey where more than half the participants got stuck without knowing why
- [ ] The interaction pattern library is up to date with the patterns used in the implementation
- [ ] Accessibility compliance verified against the committed target (`accessibility.target`, `design/accessibility-requirements.md`): keyboard path, contrast, screen reader on the touched screens
- [ ] User-facing strings are externalized (Grep the code roots; Section 3) — recommended here, required at the Release gate
- [ ] No Critical or High finding from a dependency or secrets scan is known to be open (a quick `/dependency-audit` result if one exists) — the full audit is the Release gate's
- [ ] No open architectural deviation: every departure from an Accepted ADR has a superseding ADR (an entry in the brief's decision log at `minimal`), and migrations are proven forward

## Floors at every tier

These never drop, whatever `workflow` and `qa.level` say (Section 2b):
- **Logic, Integration, Contract and Security tests exist and pass** for the milestone's stories.
- The **smoke check** (PASS or PASS WITH WARNINGS).
- **Security evidence** for every Security-type story that is Complete: negative tests and the ASVS/MASVS mapping.
- **Run-and-observe evidence** for every story that changed something a user can see or call.
- **Performance** against its budget, per `performance.enforce`.
- **No open S1 Critical bug.**

## Workflow tier reductions

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier; items not named keep their status above.
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

- **`full`** — all MVP features + Logic/Integration/Contract/Security tests + smoke check (PASS or PASS WITH WARNINGS) + QA sign-off + 3+ usability sessions + per-story eight-gate evidence and PE-DOD/QL-TEST-COVERAGE/SL-TENANT-ISOLATION records + UX specs for every screen all required
- **`standard`** — QA sign-off + per-story test coverage records + PE-DOD/QL-TEST-COVERAGE records → recommended; **all MVP features + smoke check + the main journey end to end + 1+ documented usability session + no open S1 Critical bugs + the eight-gate evidence for Complete stories + SL-TENANT-ISOLATION records + threat-model negative tests** required
- **`minimal`** — **the required tests (Logic/Integration/Contract/Security) + smoke check + the main journey end to end + no open S1 Critical bugs + the floors above** required; the "all MVP features" cross-check → recommended; everything else **drops**. Reductions relax what must *exist*, never what must *work* — and never what proves the product was run: a gate that closes Production on "it boots" alone has not asked whether the product does its job.

## Director gates at this transition

The PHASE-GATE panel (Section 4b) runs at the width `workflow` sets. Recorded,
not re-spawned: PE-CODE-REVIEW and PE-DOD, QL-TEST-COVERAGE (per story),
SL-TENANT-ISOLATION (per story touching tenant data), PR-MILESTONE (per
milestone), PD-USABILITY (per usability report). Absence is recorded as
"skipped — [mode]" or is a CONCERNS finding (Section 3, "Recorded director
verdicts"). In `solo` the directors are skipped but every mechanical check above
runs — solo skips review, never evidence.
