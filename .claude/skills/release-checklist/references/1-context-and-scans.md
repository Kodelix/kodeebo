# /release-checklist — Context and Scans (Phases 2–3)

> Everything here is read-only. Each scan states its **denominator**: these scans
> look for something bad, so `0` means either "searched and found none" or
> "there was nothing to search", and on a release gate those are opposite
> findings. A bare `0` is not a result.

## Phase 2 inputs — record FOUND / ABSENT for each

| Input | Used for |
|---|---|
| `project.yaml` (`project.name`, `core.version`) | product name, pinned core version |
| `design/product-brief.md` | release scope at `minimal` (build order is the plan) |
| Latest milestone in `production/milestones/` (when present) | what should be in the release |
| Previous `production/releases/*.md` | prior version, upgrade-from matrix, last restore-drill date |
| `CHANGELOG.md` (repo root, from `/changelog`) and release notes (`/release-notes`) | notes final? upgrade steps present? |
| Open bugs `production/qa/bugs/*.md` | quality gate |
| `production/qa/smoke-*.md`, `production/qa/evidence/` | smoke verdict, run-and-observe, restore drill, load results |
| `docs/architecture/perf-budgets.md`, `slos.md`, `docs/runbooks/` | performance, SLO and alert readiness |
| `docs/architecture/threat-models/` | sensitive features changed in this release |
| Latest `/security-audit` report (`production/qa/security-audit-*.md`) | SL-RELEASE-SECURITY input |
| `contracts/` and the previous released contract version | breaking-change check |
| `deploy/hosted/`, `deploy/self-hosted/` | tracks 1 and 2 |
| `mobile/android/`, `mobile/ios/` build files | track 3 |
| `docs/stack-reference/compose/VERSION.md`, `swiftui/VERSION.md` | store requirements and their verified date |

An input that is ABSENT makes the items that depend on it `[?]`
(`NOT ASSESSED — [input] absent`), not ticked and not failed.

## Open bugs (quality gate)

Grep the `**Severity**` and `**Status**` lines of `production/qa/bugs/*.md` (as
`/bug-triage` does). A bug is open unless its Status is `Closed` or `Verified
Fixed`. **No bug files** → the bug items read `NOT ASSESSED — no bug records`;
never zero and never ticked, since an absent record and a clean one must not
produce the same checklist (bugs are filed with `/bug-report`). An unparsable bug
file counts as open and is named.

Thresholds (the stricter of `qa-lead` and `release-manager`, which both say the
release gate blocks on S1/S2; the template's older note allows S2 below `full`
only with a written exception — that is what is applied here):

| Severity | Blocks the release when open |
|---|---|
| S1 | Always, at every `workflow` tier — no exception |
| S2 | Always, unless a **written exception** (reason, named approver, date) is recorded in the checklist; **no exceptions at `workflow: full`** |
| S3 | Needs a named owner, ticket and target release; at `workflow: full` must be zero |
| S4 | Never |

Security-related open bugs are listed with their SLA date from `/bug-triage`; a
breached SLA is a blocker to name.

## Codebase health (with denominators)

Resolve the code roots: `bash .claude/hooks/yaml-helper.sh resolve_code_root`.
**Empty result → `NOT ASSESSED — code roots unresolved`.** A root with no source
files → `NOT ASSESSED — no source files under <root>`.

Count `TODO`, `FIXME`, `HACK` in source under the roots (excluding generated
code and lockfiles) and report
`scanned [N] source files in [roots]: [M] TODO, [M] FIXME, [M] HACK`. List all
FIXME and HACK (potential blockers). Also grep the release-facing code and
config for: leftover debug output and test endpoints, `localhost`/`127.0.0.1`
and sample credentials in non-test code or in `deploy/` release config, and
feature flags not at their production defaults. Each line reads
`scanned [N] files, [M] hits` or `NOT ASSESSED — [reason]`.

## Git and artifact state (read-only: `git status`, `git log`, `git tag`)

- Is the working tree clean and is the release commit identified? A dirty tree → blocker ("release from a tagged commit, clean CI").
- The version: from the argument, else ask. Propose the SemVer bump **by rule**
  (`release-manager`): major for a breaking API/contract, config or data-format
  change or a dropped upgrade path; minor for backward-compatible features;
  patch for fixes. Show the evidence (commit types since the last tag, contract
  diff) and let the user decide — the skill does not pick the number.
- Does the tag already exist? A published version is never re-tagged or
  force-pushed — a new patch is published instead.
- Do component versions agree (backend, web, mobile, bundle, contract)?

## Test, scan and evidence results — report real output or `not run`

Look for CI logs or test output directories. **If none are found, say so** —
`Test results: NOT ASSESSED — no test output or CI logs found`. Do not run the
whole suite here unless the user asks; `/smoke-check` is the build gate. For the
following, cite the file and date, or write `not found`:

- Latest `/smoke-check` verdict on the release candidate (`production/qa/smoke-*.md`)
- Contract tests and the breaking-change check against the previous released `contracts/` version
- Migration evidence: files in this release (`git diff --name-only <prev-tag>..HEAD -- '**/migrations/**' '**/*.sql'`) and, when any, run
  `bash .claude/scripts/migration-lint.sh <those files>` and quote its
  `DANGER`/`WARN`/`MISSING` lines verbatim; tested up on empty, up on a seeded and
  production-sized copy (duration, locks), down in dev
- Scans on the release commit: gitleaks, `govulncheck`, OSV-Scanner, image scan, SBOM —
  from the latest `/security-audit` report, or `not run`
- Load results vs `perf-budgets.md` for the top journeys (`/load-test`), with
  environment and data volume
- Restore drill record in `production/qa/evidence/` (date, environment, data
  check, measured RTO) — a backup that has never been restored is untested
- Run-and-observe evidence for every user-visible story in the release
  (`production/qa/evidence/<story-id>/`): list stories missing it

## Stack drift

Run `bash .claude/scripts/project-coherence.sh` and quote its output for lines
that matter to a release: `BEHIND`, `FLOATING` (non-reproducible image tags),
`LICENCE` (engines that break the customer-bundle decisions), `SKIPPED` (a
comparison that did not run is reported as such). It is an observation, never a
verdict.
