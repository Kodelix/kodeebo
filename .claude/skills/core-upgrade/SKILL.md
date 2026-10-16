---
name: core-upgrade
description: "Bump the product's core.version: read every consumed module's CHANGELOG between the pin and the target, diff the ports, list breaking changes, deprecations and migration steps, scan the product for impact, apply and run the product tests, then update the pin with approval. check mode reports available upgrades without changing anything."
argument-hint: "[<release-tag> | latest | check] [--module <name>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git diff *), Bash(git show *), Bash(git ls-remote *), Bash(git -C * rev-parse *), Bash(bash .claude/scripts/project-coherence.sh), Bash(bash .claude/scripts/project-coherence.sh *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(date *), Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/core-upgrade/../../hooks/yaml-helper.sh" resolve_config *), Bash(git diff)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,automation_always_ask,qa.level,testing.strict,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md` (collaborative asks
always · guided major-only · autonomous logs and proceeds; `automation_always_ask`
categories always prompt). The upgrade decision (Phase 4) and the `core.version`
edit (Phase 6) are `version_bumps` and `schema_changes` decisions: the pin edit
**always prompts**, in every mode.

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

# Core Upgrade

A product pins **one** released core version (`core.version`) and a list of the
modules it consumes (`core.modules`). Moving the pin is a dependency upgrade
whose changelog is written by someone else: this skill reads it **in full**,
checks it against the actual port diff, finds what the product uses that
changed, plans and applies the migration, runs the product's own tests, and only
then moves the pin.

**It never edits core, never pins a branch or commit, and never moves the pin
down.** A core bug is reported upstream (`/core-extract` if it is a missing
capability; a bug report to the core's owners otherwise); a rollback is a revert
of the upgrade change set and the pin together, on the user's instruction.

**Modes**
- **upgrade** (default; `<release-tag>` or `latest`): Phases 1–7.
- **`check`**: Phases 1–3 only. Reports what a bump to the latest release would
  involve for each consumed module; changes nothing; writes the report only
  after approval.

**Output:** the product changes (written by the stack lead), the `core.version`
edit (after approval), and `production/core/upgrade-<from>-to-<to>-<date>.md`.

> **Never from memory.** What changed between two core tags is read from the
> core repo (`core.repo`): module CHANGELOGs, port files, build files, docs. Where
> the core repo does not say, the answer is `NOT SOURCEABLE — <what> is not in
> <core repo>@<tag>`. A semantic-version number is a **claim to check against the
> diff**, not evidence that nothing breaks. No tool, flag or command for
> comparing public APIs is assumed: only what the core repo or the product repo
> already defines is run; otherwise a `git diff` of the port files, labelled
> as a manual review (`.claude/rules/skill-authoring.md`).

> **Verdicts:** `COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`.
> Precedence: `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH GAPS`, then
> `COMPLETE`. `BLOCKED`: a removed or changed symbol still used and not
> migrated, a failing product test, an unresolved dependency, a refused approval,
> a pin that is not a released tag. `NOT ASSESSED`: a consumed module's
> CHANGELOG or diff could not be read, the CHANGELOG lacks its Breaking /
> Deprecated / Migration headings (which is **not** "no breaking changes"), or
> the product tests / dependency scan did not run. `COMPLETE WITH GAPS`: upgraded
> and verified, with deferred deprecations (each with a sunset date and an owner)
> or CHANGELOG/diff inconsistencies reported to the core. `COMPLETE` is
> unreachable while any Phase 5 check reads `not run`.

---

## Phase 1: Inputs, Target and Scope

**Read `references/1-inputs-and-changes.md` sections 1–2 now and follow them.**
Reads `core.*`, the core repo's release tags, selects the target, and fixes the
module scope (consumed modules only; others are named as not read).

## Phase 2: Read the Changes

**Read `references/1-inputs-and-changes.md` sections 3–4 now and follow them.**
Per consumed module and per intermediate release: CHANGELOG sections, the real
port diff, toolchain floors, config and data changes, and a consistency check
between the two. This is the evidence the rest depends on.

## Phase 3: Impact on the Product

**Read `references/2-impact-and-plan.md` sections 1–2 now and follow them.**
Greps the code roots for every changed, deprecated and removed symbol; the
output is the impact table (file:line per use).

*(In `check` mode stop after this phase: print the per-module summary — breaking
count, deprecations, migration steps, product files affected, verdict — and the
exact command to run the upgrade.)*

## Phase 4: Plan and Decide

**Read `references/2-impact-and-plan.md` sections 3–4 now and follow them.**
Migration steps in order, deferred-deprecation handling, hand-offs to
`/db-migration`, `/api-contract`, `/team-data`; the decision gate: upgrade fully,
stop at an intermediate release, or defer — and approval of the file set.

## Phase 5: Apply and Verify

**Read `references/3-apply-verify-and-pin.md` sections 1–2 now and follow them.**
The stack lead applies the approved plan; a separate verification run (a stack
lead via `Agent` — this skill holds no test-runner grants) executes the checks and
this skill reports their real output.

## Phase 6: Pin Update (always prompts)

**Read `references/3-apply-verify-and-pin.md` section 3 now and follow it.**

## Phase 7: Record and Report

**Read `references/3-apply-verify-and-pin.md` section 4 now and follow it.**

## Error Recovery Protocol

**First, verify the artifact.** If an agent's return contract named a path,
check it exists before treating the phase as done; a fluent reply with no file
is a failed phase — resume it naming the unmet contract. If any agent returns
BLOCKED, errors, or cannot complete: surface it immediately, do not proceed past
a dependency it blocks, offer skip / retry narrower / stop, and produce a
partial report. Full procedure: `.claude/docs/error-recovery-protocol.md`.

## Collaborative Protocol

- **Question → Options → Decision → Draft → Approval.** The target version, the
  handling of each deprecation, the file set and the pin edit are the user's.
- **Never auto-fix a failing check** — show it and ask: send back, revert, stop.
- **No core edits, no pushes, no commits** without an explicit instruction.
- **A skipped or dismissed question is not an answer** — re-ask in plain text.

---

## Recommended Next Steps

`/code-review` on the upgrade diff; `/dependency-audit` if the scan was `not
run`; `/db-migration` or `/team-data` for each data step the plan handed off;
`/release-notes` and `/changelog` when the upgrade changes anything customers or
self-hosted operators see; `/tech-debt` for deferred deprecations.
