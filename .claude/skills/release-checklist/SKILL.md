---
name: release-checklist
description: "Per-release go/no-go checklist in three tracks — hosted deploy (expand/contract migrations, verified backup, rollback, SLO/alerts), self-hosted signed bundle (licence rules L1-L4, upgrade-path matrix, installer preflight), mobile stores (Play and App Store requirements)."
argument-hint: "[version] [--track hosted|self-hosted|android|ios|all] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), Agent, AskUserQuestion, Bash(date *), Bash(bash "*/.claude/skills/release-checklist/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/scripts/migration-lint.sh *), Bash(bash .claude/scripts/project-coherence.sh), Bash(bash .claude/scripts/project-coherence.sh *), Bash(git status), Bash(git status *), Bash(git log *), Bash(git diff *), Bash(git tag -l *), Bash(git tag --list *)
model: sonnet
---
!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,rigor,workflow,project.stage,qa.level,testing.strict,performance.enforce,stack,automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

# Release Checklist

A release turns finished stories into a version that can be shipped, found,
verified, upgraded to and — if needed — rolled back, across the hosted
deployment, the self-hosted bundle and the mobile stores, **without surprises**
for customers. This skill builds the dated checklist, fills it with real
evidence, spawns the two release-readiness gates, and returns a go/no-go
verdict. `release-manager` owns the release; this skill **never** pushes a tag,
publishes a bundle, submits to a store or announces — those happen on the
user's explicit instruction naming the version and target. Its only shell use is
read-only (`git status|log|diff|tag --list`, the migration lint, the coherence
check, `resolve_code_root`, `date`); no `git tag`, `git commit`, push or deploy is
granted.

**Output:** `production/releases/[product]-[version].md`

> **Explicit invocation only**: run only when the user asks for
> `/release-checklist`. Do not auto-invoke on context matching.

**Scope this checklist to the project.** Emitting every item for every target
trains the reader to skip the list, which defeats the gate. Tracks are chosen
from the resolved `stack` line and `project.stage`:

| Track | Emitted when | `none` / explicit skip | Unset |
|---|---|---|---|
| 1 Hosted deploy (+ web app, marketing site) | `distribution=hosted` or `hybrid` | `distribution=self-hosted` → omitted, stated | **ask** which editions ship |
| 2 Self-hosted bundle | `distribution=self-hosted` or `hybrid` | `distribution=hosted` → omitted, stated | **ask** |
| 3 Android / iOS stores | `stack.mobile` includes `compose` / `kmp` (Android) or `swiftui` (iOS) | `mobile=none` → omitted, stated | **ask** which stores are in scope |

**Unset is not `none`.** `none` is a decision; unset is a missing one, and they
must not produce the same output. If a track cannot be scoped, mark it
`NOT ASSESSED — [value] unset (/setup-stack)`. `--track` narrows the run;
`modes.rigor: minimal` drops items whose only justification is process weight
(never an evidence, security or rollback item). `project.stage` earlier than
Hardening is stated ("release readiness is normally assessed from Hardening on")
and the checklist still runs — it will mostly show `[?]`.

---

## Phase 1: Parse Arguments

Read the version and `--track`. No version → ask (propose the SemVer bump by
rule in Phase 3; the user decides). `--track all` or none = every track the
config selects. Report the scope: "Release [version]: tracks [list]; omitted
[track — config value]; review mode [mode]."

## Phase 2: Load Project Context

**Read `references/1-context-and-scans.md` now and follow its "Phase 2 inputs"
and "Open bugs" sections.** Record FOUND/ABSENT for each input; an absent input
makes its dependent items `[?]`, never ticked and never failed.

## Phase 3: Scan Codebase, Git and Evidence

**Read `references/1-context-and-scans.md` and follow its "Codebase health",
"Git and artifact state", "Test, scan and evidence results" and "Stack drift"
sections.** Every count states its denominator; a result nobody supplied is `not
run`, never green. The scans are read-only.

## Phase 4: Generate the Checklist

Start from `.claude/docs/templates/release-checklist-template.md` and apply
`references/5-gates-verdict.md` ("Common sections"). Then add the tracks:

- **Hosted deploy** — `references/2-hosted.md`: migrations expand → migrate → contract, backup verified and a restore drill, zero-downtime rollout with abort criteria, a rehearsed rollback plan, SLO/alerts/runbooks ready, post-deploy verification.
- **Self-hosted bundle** — `references/3-self-hosted.md`: licence rules L1–L4 checked against the bundle, signed bundle + SBOM + installer signature verification, preflight/install/rollback, the **upgrade-path matrix including skipped versions**, the licence-verification matrix, customer-facing notes.
- **Mobile stores** — `references/4-mobile.md`: `targetSdk` / Xcode-SDK / deployment-target requirements re-read from the stack reference with dates, privacy and store forms **flagged for `/research`**.

Read only the track files that apply. Re-read a file if the conversation was
compacted during this phase.

## Phase 4a: Release-Readiness Gates

Apply `references/5-gates-verdict.md` "Gates": spawn `security-lead`
(**SL-RELEASE-SECURITY**) and `sre-lead` (**SRE-OPERABILITY**) in `full` review
mode — in parallel, since neither needs the other's output — and record their
verdicts; in `lean` or `solo` record `[GATE-ID] skipped — [mode] mode`. A skipped
gate is recorded as skipped, never as passed; all items are still evaluated.

## Phase 4b: Confirm What Only a Person Can

Apply `references/5-gates-verdict.md` "Phase 4b". Skipped in `autonomous` mode,
and said so.

## Phase 5: Verdict and Save

Compute the verdict with `references/5-gates-verdict.md` "Verdict":
**READY / CONCERNS / NOT ASSESSED / NOT READY**, first match wins, with
NOT ASSESSED outranking CONCERNS and READY and ranking below NOT READY. Present
the checklist, then ask to write it to `production/releases/[product]-[version].md`
(nothing is created before the yes). If the user declines, close with
`BLOCKED — write declined by user`: the checklist and its go/no-go verdict stay in
conversation, marked not recorded, and the release gate sees no record.

## Phase 6: Next Steps

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/release-checklist <version>
— <verdict>`, Next step = the first applicable item below, plus Blocked on /
Files in progress / Open questions; append the Notes line. NOT READY, NOT
ASSESSED or a declined write still updates the checkpoint with the blocker.

- Draft the changelog and customer notes if not done: `/changelog`, `/release-notes` — the release gate checks them.
- Missing evidence: `/security-audit` (SL-RELEASE-SECURITY input), `/load-test`, `/smoke-check`, `/dependency-audit`, `/tenant-check`; missing store-form answers: `/research`.
- Run `/gate-check` for the Hardening → Release transition (it spawns the same two gates at PHASE-GATE class).
- After READY: coordinate the release with `/team-release`; ordering is migrate → deploy → verify → announce. For the first public launch run `/launch-checklist` too.
- A failed post-release check: `/hotfix` or `/post-release-fix`; a production incident: `/incident`.

## Collaborative Protocol

- **Never publish, tag, submit or announce** — the checklist is a decision aid; the user gives the explicit instruction naming version and target
- **A check that did not run is reported as not run** — a scan, a restore drill, a clean-host install, a store requirement the reference does not source: `[?]` or a failed scan, never ticked
- **Never recall a store requirement, version or date** — read it from `docs/stack-reference/` and write the date; unsourced is `NOT SOURCEABLE` and `/research`
- **Waivers need a written reason and a named approver** — this skill, `release-manager` and the gates do not waive quality or security items on the company's behalf
- **Solo skips the opinion, never the evidence**
- **Never print secrets, signing keys or customer data** into the checklist; refer to the secret store path
- **No write before the user says yes**
