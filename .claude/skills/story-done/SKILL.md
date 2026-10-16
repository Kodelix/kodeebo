---
name: story-done
description: "Close a story: verify every acceptance criterion with evidence, the eight DoD gates (PE-DOD), run-and-observe evidence on disk, spec/ADR deviations; then status update and next story."
argument-hint: "[story-file-path] [--review full|lean|solo]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/story-done/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(bash .claude/hooks/yaml-helper.sh is_always_ask_category *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/scripts/story-status.sh), Bash(bash .claude/scripts/story-status.sh *), Bash(bash .claude/scripts/migration-lint.sh *), Bash(bash .claude/scripts/project-coherence.sh), Bash(bash .claude/scripts/project-coherence.sh *), Bash(date *), Bash(git status), Bash(git status *), Bash(git diff *), Bash(git log *), Bash(stat *), Bash(gofmt *), Bash(go vet *), Bash(go test *), Bash(go -C * vet *), Bash(go -C * test *), Bash(golangci-lint run *), Bash(govulncheck *), Bash(osv-scanner scan *), Bash(./gradlew *), Bash(pnpm install --frozen-lockfile), Bash(pnpm -C * install --frozen-lockfile), Bash(pnpm lint), Bash(pnpm -C * lint), Bash(pnpm typecheck), Bash(pnpm -C * typecheck), Bash(pnpm test), Bash(pnpm test *), Bash(pnpm -C * test), Bash(pnpm -C * test *), Bash(pnpm build), Bash(pnpm -C * build), Bash(pnpm exec playwright *), Bash(pnpm -C * exec playwright *), Bash(pnpm audit), Bash(pnpm audit *), Bash(pnpm -C * audit), Bash(pnpm -C * audit *), Bash(swift test), Bash(swift test *), Bash(xcodebuild test *), Bash(swiftlint), Bash(swiftlint *), Bash(gitleaks git *), Bash(gitleaks dir *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,story_granularity,qa.level,testing.strict,performance.enforce,system_overrides,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

# Story Done

This skill closes the loop between design and implementation. Run it at the end
of implementing any story. It ensures every acceptance criterion is verified
**with evidence on disk**, each of the **eight Definition of Done gates**
(`.claude/docs/coding-standards.md`) is met or validly waived, the run-and-observe
record exists in `production/qa/evidence/<STORY-ID>/`, spec and ADR deviations are
explicitly documented rather than silently introduced, code review is checked
rather than forgotten, and the story file reflects actual completion status.

**Output:** Updated story file (Status: Complete) + the eight-gate table with
evidence paths + surfaced next story.

> **Solo skips opinions, never evidence.** Review mode decides whether the PE-DOD,
> QL-TEST-COVERAGE, SL-TENANT-ISOLATION and PE-CODE-REVIEW *directors* are spawned
> (`director-gates.md` → Review Modes). It never decides whether a DoD gate is
> checked: Phase 6 checks all eight mechanically in every mode, and a skipped gate
> review is recorded as skipped, never as passed.
>
> **A check that did not run is reported as `not run`.** A test suite nobody
> executed, a dependency scan that is not installed, a load test not performed, a
> screenshot that is named but not on disk — each is `not run` / `absent` in the
> report and never counts as met. A BLOCKING gate resting on one cannot reach
> `COMPLETE` (`.claude/rules/skill-authoring.md`).

---

## Phase 1: Find the Story

**Read `references/1-find-story.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 2: Read the Story

**Read `references/2-read-story.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 3: Verify Acceptance Criteria and Test Results

**Read `references/3-verify-criteria.md` now and follow it** — this phase's steps are in that file, not here. It verifies each criterion with evidence, builds the test-criterion traceability table, establishes whether the tests actually **passed**, and resolves the run-and-observe record. Read it again if the conversation was compacted or resumed during this phase.

## Phase 4: Check for Deviations (and the QA, Tenant-Isolation Gates)

**Read `references/4-deviations.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 5: Code Review Gate

**Read `references/5-code-review-gate.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 6: The Eight DoD Gates (PE-DOD)

**Read `references/6-dod-gates.md` now and follow it** — this phase's steps are in that file, not here. It builds the eight-gate table with evidence paths, resolves waivers, and runs the PE-DOD gate. Read it again if the conversation was compacted or resumed during this phase.

## Phase 7: Present the Completion Report

**Read `references/7-completion-report.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 8: Update Story Status

**Read `references/8-update-status.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 9: Surface the Next Story

**Read `references/9-next-story.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Error Recovery Protocol

**First, verify the artifact.** If a spawned gate agent's return contract named a
path, check it exists before treating the phase as done; a fluent verdict with no
evidence rows behind it is not a verdict. If any spawned agent returns BLOCKED,
errors, or cannot complete: surface it immediately, don't proceed past a
dependency it blocks, and always produce a partial report. Full procedure:
`.claude/docs/error-recovery-protocol.md`. A gate agent that could not run is
recorded `NOT ASSESSED — [what was missing]` and keeps the verdict at best
`NOT ASSESSED`.

## Collaborative Protocol

**In `collaborative` mode (the default).** For `guided` and `autonomous` modes,
see `.claude/docs/automation-modes.md` — the rules below describe collaborative
behavior. The BLOCKED/NOT ASSESSED-override close (Phase 8) always prompts
regardless of mode (it's a `scope_changes` always-ask decision).

- **Decision records follow the tier.** "An ADR" in this skill means an ADR (at
  `modes.workflow: minimal`, an entry in the brief's decision log, `design/product-brief.md`).
- **Never mark a story complete without user approval** — Phase 8 requires an
  explicit "yes" before any file is edited.
- **Never auto-fix failing criteria** — report them and ask what to do.
- **Deviations are facts, not judgments** — present them neutrally; the user
  decides if they are acceptable.
- **A waiver is the user's, never the model's.** A DoD gate that is unmet is
  waived only by a written reason in the story file that the user approves
  (Phase 6). The model never proposes waiving **security evidence on a
  security-sensitive story**; the only path past it is the explicit
  close-anyway override, with residual risk named, owned and dated.
- **BLOCKED and NOT ASSESSED verdicts are advisory** — the user can override and
  mark complete anyway; document the risk explicitly if they do. For NOT
  ASSESSED, the documented risk is that the criterion or gate was never
  evaluated, not that it failed — record which, so the gap is recoverable later
  rather than closed over.
- **Describe only images you have opened.** Evidence screenshots are read with
  `Read` and compared to the criteria; a filename is not an observation.
- Use `AskUserQuestion` for the code review prompt, for batching manual
  criteria confirmations, and for waivers.

---

## Recommended Next Steps

- At `minimal`: run `/dev-story [next-story-path]` (`/story-done` for an In Review one); when every story is Complete, run the product end to end on the compose stack, then `/create-stories` for more or `/settings` to raise `modes.rigor`
- With a sprint plan: run `/story-readiness [next-story-path]` to validate the next story before starting implementation
- If a sprint plan exists and all its Must Have stories are complete: run `/smoke-check sprint` → `/team-qa sprint` → `/gate-check`
- If tech debt was logged: track it via `/tech-debt` to keep the register current
