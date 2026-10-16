---
name: core-use
description: "Adopt a saas-core-<track> module in a product: check core.track matches stack.backend, pick a released version from the core repo, fit-check the module, wire its port in the composition root, config, product-side integration tests, then update core.version/core.modules in project.yaml with approval."
argument-hint: "<module> [--version <release-tag>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git show *), Bash(git ls-remote *), Bash(git -C * rev-parse *), Bash(bash .claude/scripts/project-coherence.sh), Bash(bash .claude/scripts/project-coherence.sh *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(date *), Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/core-use/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,automation_always_ask,qa.level,testing.strict,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md` (collaborative asks
always · guided major-only · autonomous logs and proceeds; `automation_always_ask`
categories always prompt). Editing `project.yaml` (`core.*`) is both a
`schema_changes` and a `version_bumps` decision: it **always prompts**, in every
mode (Phase 6).

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**`workflow`** decides where the adoption decision is recorded (ADR at `full`;
critical-module ADR at `standard`; a decision-log line in `design/product-brief.md`
at `minimal`), never whether the module is tested or its dependency scanned
(`workflow-modes.md`: tiers scale documents, never engineering).

# Core Use

Shared capabilities come from `saas-core-<track>`, never from a product-local
copy (`coding-standards.md`, `principal-engineer.md` → Shared-core boundary).
This skill adopts **one module** of the core into **this product**: it reads the
core repo, selects a released version, checks the module fits, wires its port in
the composition root, proves it with product-side tests, and only then records
the pin in `project.yaml`.

**The product never edits core.** There is no step here that writes into the
core repo. A gap in the module goes upstream through `/core-extract`; a newer
release is taken with `/core-upgrade`.

**Output:** the dependency declaration, composition-root wiring, typed config
and tests in the product (written by the stack lead, never by this
orchestrator), the `core.*` change in `project.yaml` (after approval), and an
adoption record `production/core/adopt-<module>-<date>.md`.

> **The core is not in this repository and not in `docs/stack-reference/`.**
> Module names, port signatures, versions, config keys, the dependency
> coordinates and how a private core repo is resolved are read from the core
> repo itself (`core.repo`) at run time. Anything this skill cannot read there is
> `NOT SOURCEABLE — <what> is not in <core repo path>` and routed to `/research`
> or to whoever owns the core; it is never filled from memory
> (`.claude/rules/skill-authoring.md`). If the core repo cannot be read at all,
> the verdict is `NOT ASSESSED`.

> **Verdicts:** `COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`.
> Precedence: `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH GAPS`, then
> `COMPLETE`. `BLOCKED`: track mismatch, no released version, module does not
> cover the need, a sensitive module with no threat model, a failing test, or a
> refused approval. `NOT ASSESSED`: the core repo or its CHANGELOG could not be
> read, the product tests or dependency scan did not run. `COMPLETE WITH GAPS`:
> adopted and verified, with named gaps (a missing capability routed to
> `/core-extract`, a deprecated symbol in use, docs missing). Never report
> `COMPLETE` while any Phase 4 check reads `not run`.

---

## Phase 1: Inputs and Preconditions

**Read `references/1-inputs-and-preconditions.md` now and follow it.** It parses
the argument, reads `core.*` and `stack`, applies the track rule
(`core.track` must match `stack.backend`), confirms the core repo is readable,
and records every input as FOUND or ABSENT. Read it again if the conversation
was compacted or resumed.

## Phase 2: Module Fit and Version Selection

**Read `references/2-fit-and-version.md` now and follow it.** It reads the
module's docs, port and CHANGELOG at the candidate tag, checks it covers the
need and fits the product's stack, tenancy, distribution and licence rules, and
proposes the version. The version and the fit verdict are the user's decision
(Phase 2 ends in an `AskUserQuestion`).

## Phase 3: Adoption Plan

**Read `references/3-adoption-plan.md` now and follow it.** `principal-engineer`
produces the plan (where the dependency goes, which port is wired where, the
config keys, the tests, who owns each lane); the user approves the **full file
set** before anything is written.

## Phase 4: Implement and Verify

**Read `references/4-implement-and-verify.md` now and follow it.** The stack lead
implements the approved plan; a stack lead (a separate verification run) executes
the layer checks and this skill reports their real output; a check that did not run is `not run`, never passed.

## Phase 5: Pin Update (always prompts)

Only after Phase 4 shows the dependency resolving and the product tests
passing (or the exact `not run` reasons recorded and accepted by the user):

1. Show the change as from → to, key by key:
   ```
   core.track:   <old or unset> → <track>
   core.repo:    <old or unset> → <repo>        (first adoption only)
   core.version: <old or unset> → <release tag>
   core.modules: [<old list>] → [<old list> + <module>]
   ```
2. `AskUserQuestion` — "May I update `core.*` in `project.yaml`?" Options:
   apply as shown · change the version first · do not record the pin (adoption
   left unrecorded — verdict at best `COMPLETE WITH GAPS`).
3. Apply with `Edit` only after a yes. Never touch any other key. Never write a
   branch name, commit hash or range as `core.version` — a released tag only.
4. Re-run `bash .claude/scripts/project-coherence.sh` and show its real output.

If `core.version` is already set to a **different** tag, this is not an adoption
but an upgrade: stop and route to `/core-upgrade`. One product pins **one** core
version; a module at another version is not allowed.

## Phase 6: Record and Report

Ask: "May I write the adoption record to
`production/core/adopt-<module>-<date>.md`?" Contents: module, track, tag, how
the tag was verified, fit table, plan and file list, evidence table (check →
command → exit → result, or `not run — reason`), pin diff, gaps, ADR or
decision-log reference, verdict. Write only after approval.

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/core-use <module> —
<verdict>`, Next step = the first Recommended Next Step that applies
(`/code-review` on the adoption diff, or what clears a `BLOCKED` / `NOT
ASSESSED`), plus Blocked on / Files in progress (adoption record, pin file,
adopted code) / Open questions; append the Notes line. Still updated when the user
declines the record or the pin update (record what was not written and why).

Print the report: the verdict; the evidence table; **Not run / not checked**
(always present, "none" only when true); gaps with the skill that closes each
(`/core-extract`, `/threat-model`, `/tech-debt`).

## Error Recovery Protocol

**First, verify the artifact.** If an agent's return contract named a path,
check it exists before treating the phase as done; a fluent reply with no file
is a failed phase — resume it naming the unmet contract. If any agent returns
BLOCKED, errors, or cannot complete: surface it immediately, do not proceed past
a dependency it blocks, offer skip / retry narrower / stop, and produce a
partial report. Full procedure: `.claude/docs/error-recovery-protocol.md`.

## Collaborative Protocol

- **Question → Options → Decision → Draft → Approval.** Version choice, fit
  verdict, the file set and the `project.yaml` change are the user's.
- **No core edits, no pushes, no commits** without an explicit instruction for
  that action.
- **A skipped or dismissed question is not an answer** — re-ask in plain text.
- **Never print credentials.** A private core repo's access is configured by
  `platform-lead`/`infra-engineer`; this skill never asks for or writes a token.

---

## Recommended Next Steps

- `/code-review` on the adoption diff, then `/story-done` if it was a story.
- `/dependency-audit` for the new transitive dependencies if Phase 4 shows it `not run`.
- `/core-extract` for each gap the fit check routed upstream.
- `/studio resume` if this ran inside a flow.
