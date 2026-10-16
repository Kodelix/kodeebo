---
name: core-release
description: "Run inside a saas-core-<track> repo: decide the semver bump per module from the real port diff, write the CHANGELOG and release notes for product teams, run conformance tests on every adapter (Testcontainers), enforce the deprecation policy, and create the release tag locally. Never pushes or publishes without an explicit instruction."
argument-hint: "[<module>... | all] [--review full|lean|solo]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash(git status), Bash(git status *), Bash(git diff *), Bash(git log *), Bash(git rev-parse *), Bash(git tag --list), Bash(git tag --list *), Bash(git tag --sort=*), Bash(git tag -n1 *), Bash(git branch --list), Bash(git branch --list *), Bash(git branch --show-current), Bash(git branch --contains *), Bash(date *), Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/core-release/../../hooks/yaml-helper.sh" resolve_config *), Bash(git diff)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,automation_always_ask,qa.level,testing.strict,stack`

**Automation mode.** A release is irreversible once consumers pin it, so this
skill is **always collaborative**, like `/hotfix` and `/gate-check`
(`automation-modes.md`, Exemptions): every `AskUserQuestion` below prompts in
`guided` and `autonomous` too, and nothing is logged-and-proceeded. Only
`review_mode` (director-gate depth) and `workflow` are read from the block.

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

# Core Release

`saas-core-<track>` is consumed by every product that pins it. A release is a
promise: the version number tells consumers what may break, the CHANGELOG tells
them what to do, the conformance results tell them every adapter behaves, and the
deprecation policy tells them how long old things live. This skill makes those
four statements true before it creates the tag — and says plainly which it could
not make true.

**Run it inside the core repo** (`saas-core-go` or `saas-core-kotlin`), never in
a product: a product never edits or releases core code
(`directory-structure.md`, "Core repositories"). Phase 1 refuses to continue
otherwise.

**Output (all in the core repo, left uncommitted until you say so):**
module `CHANGELOG` entries, `docs/releases/<tag>.md` release notes for product
teams, a release record `production/releases/core-<tag>.md`, and — on your
explicit decision — a release commit and a **local** annotated tag. **No push, no
registry publish, no announcement.**

> **Never from memory.** The core's layout, tag scheme, versioning and
> deprecation policy are read from the core repo's own `docs/` (they were fixed by
> ADR when it was built); adapter and test commands come from the repo's scripts
> and build files and from the `layer-checks.md` lookup table in the `dev-story`
> skill folder (`.claude/skills/dev-story/`). Anything not found is `NOT SOURCEABLE
> — <what> is not in <path>` and routed to `/research` or an ADR
> (`/architecture-decision`). No public-API-diff tool is assumed: only one the repo
> defines is run; otherwise the diff is a `git diff` read by hand and labelled a
> manual review (`.claude/rules/skill-authoring.md`).

> **Verdicts:** `COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`.
> Precedence: `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH GAPS`, then
> `COMPLETE`. The tag state is reported beside it: `Tag: created locally (not
> pushed)` / `not created — <reason>`.
> `BLOCKED` (no tag offered, no override): any conformance test `FAILED` on any
> adapter; a bump lower than the diff supports; a removal inside the deprecation
> window or with no policy; a dirty tree at start; a CHANGELOG without the three
> mandatory headings. `NOT ASSESSED`: an adapter/suite that did not run, an
> unreadable policy, a scanner not installed (the tag may still be created on the
> user's explicit decision, with every unverified item stated in the release
> notes; the verdict stays `NOT ASSESSED`). `COMPLETE WITH GAPS`: all checks ran
> and passed, but files are uncommitted or untagged by choice, or a non-blocking
> inconsistency is reported. `COMPLETE`: every row of the Phase 4 matrix `passed`,
> no gap, tag created.

---

## Phase 1: Preconditions

**Read `references/1-preconditions-and-semver.md` sections 1–2 now and follow
them.** Confirms this is a core repo and the track, requires a clean tree,
finds the last release per module, and settles the tag scheme (policy, or a
recorded decision) before anything is classified.

## Phase 2: Semver Decision per Module

**Read `references/1-preconditions-and-semver.md` sections 3–4 now and follow
them.** Per module: the change set since its last tag, the classification
against the rules, the evidence (changed public symbols with file:line) and the
proposed bump. `principal-engineer` reviews the API surface; `release-manager`
checks the version arithmetic; the bump per module is the user's decision, and it
may not be lower than the evidence supports.

## Phase 3: Deprecation Policy

**Read `references/2-deprecation-and-conformance.md` sections 1–2 now and follow
them.** Every deprecation added has a replacement and an earliest-removal
version; every removal in this release was deprecated for the policy's window;
no policy readable means no removal.

## Phase 4: Conformance and Quality Checks (every adapter)

**Read `references/2-deprecation-and-conformance.md` sections 3–4 now and follow
them.** The module × adapter × engine matrix runs the conformance suite with real
dependencies (Testcontainers) on **every** adapter, including the in-memory fake;
unit tests, lint, vulnerability and secret scans run too. Each cell is `passed`,
`FAILED` or `not run — reason`.

## Phase 5: CHANGELOG and Release Notes

**Read `references/3-docs-and-tag.md` sections 1–2 now and follow them.**

## Phase 6: Release Decision, Commit, Tag

**Read `references/3-docs-and-tag.md` sections 3–4 now and follow them.** A
go/no-go the user decides with the evidence in front of them; the commit and the
tag are separate, explicit asks; nothing is pushed.

## Phase 7: Report

**Read `references/3-docs-and-tag.md` section 5 now and follow it.**

## Error Recovery Protocol

**First, verify the artifact.** If an agent's return contract named a path,
check it exists before treating the phase as done; a fluent reply with no file
is a failed phase — resume it naming the unmet contract. If any agent returns
BLOCKED, errors, or cannot complete: surface it immediately, do not proceed past
a dependency it blocks (a missing conformance result blocks the tag), offer
skip / retry narrower / stop, and produce a partial report. A skip does not
clear a block. Full procedure: `.claude/docs/error-recovery-protocol.md`.

A test suite that is flaky is not retried until green: report the failure, and
treat it as `FAILED` until it is fixed or quarantined with an owner
(`testing-standards.md`: never disable a failing test to pass).

## Collaborative Protocol

- **Decision records follow the tier.** "An ADR" in this skill means an ADR (at
  `modes.workflow: minimal`, an entry in the brief's decision log, `design/product-brief.md`).
- **Question → Options → Decision → Draft → Approval.** The tag scheme, each
  bump, each deprecation, the notes, the commit and the tag are the user's.
- **`git add`, `git commit` and `git tag` are never pre-approved.** They are not in
  `allowed-tools`: each is run only after the user's explicit yes to that one
  action in this session (the harness permission prompt for the exact command is
  the second confirmation), or the exact command is printed for the user to run.
  A yes to the release decision (Phase 6) is not a yes to the commit or the tag.
- **No tag without a go.** The tag is created only after Phase 6's explicit
  decision, only on a commit that contains the CHANGELOG and notes, never with
  `--force`, never over an existing tag.
- **No push, no registry publish, no announcement** unless the user instructs
  that exact action in this session; the skill then prints the exact command and
  remote and asks again. Publishing to a package registry is `NOT SOURCEABLE`
  until the core's release policy defines it.
- **A skipped or dismissed question is not an answer** — re-ask in plain text.

---

## Recommended Next Steps

Products: `/core-upgrade` (existing consumers) or `/core-use` (first adoption)
with the new tag. Core repo: push the tag yourself when ready; `/gate-check`
if a stage transition depends on this release; `/tech-debt` for deprecations
whose removal date is approaching.
