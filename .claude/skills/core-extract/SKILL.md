---
name: core-extract
description: "Promote a product capability into saas-core-<track>: evidence it is reusable (2+ products or a core-module category), design the port with conformance tests and deprecation policy, an ADR (CTO-ADR), an upstream proposal written for the core repo, and the migration plan for the product to consume it back."
argument-hint: "<capability description | product path> [--module <proposed-name>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Skill, Agent, AskUserQuestion, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(bash "*/.claude/skills/core-extract/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,automation_always_ask,testing.strict,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md` (collaborative asks
always · guided major-only · autonomous logs and proceeds; `automation_always_ask`
categories always prompt). Deciding **what belongs in the core** is a system
boundary decision (`architecture_decisions`): it is a major decision, asked in
`guided`, and **always asked** when that category is in
`modes.automation_always_ask`. Overriding the reusability rule (Phase 2) is
always asked, in every mode.

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**`workflow`** does not waive the ADR for a core extraction: this is a
foundation-layer, cross-product decision, so the ADR is written at `standard`
and `full`, and at `minimal` the decision-log line in `design/product-brief.md`
carries it **plus** the proposal (the proposal is the artifact the core repo
needs, whatever the tier).

# Core Extract

A capability a product built belongs in `saas-core-<track>` only when it is
**reusable**, has a **port**, **conformance tests** and a **deprecation policy**
(`cto.md`, Senior Bar). Otherwise it stays in the product. This skill decides
which of the two it is — with evidence — and, when it belongs upstream, produces
everything the core repo needs to build it and everything the product needs to
consume it back. **It builds none of the core.**

**A product never edits core from inside the product repo**
(`directory-structure.md`; `cto.md`, `principal-engineer.md`: Must Not). The
upstream proposal is a **file written in this product repo** for a human to carry
into the core repo; the core repo's own team (using the same studio, `/studio`)
builds and releases it with `/core-release`; then this product takes it back with
`/core-use` and the migration plan written here.

**Output (all in this product repo):**
1. `production/core/proposals/<module>/evidence.md` — the reusability evidence and its verdict.
2. `production/core/proposals/<module>/review-<agent>.md` — one specialist review each.
3. `docs/architecture/adr-NNNN-<slug>.md` — the ADR, via `/architecture-decision` (`CTO-ADR`).
4. `production/core/proposals/<module>/proposal.md` — the upstream proposal, from `.claude/docs/templates/technical-design-document.md`.
5. `production/core/proposals/<module>/consume-back.md` — the product's migration plan.

> **Never from memory.** The core's current module list, layout, versioning and
> deprecation policy are read from the core repo (`core.repo`); what it does not
> contain is `NOT SOURCEABLE — <what> is not in <core repo path>`. Stack versions
> and APIs come from `docs/stack-reference/`. Evidence of a second product is a
> file you opened, not a statement (`.claude/rules/skill-authoring.md`).

> **Verdicts:** `COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`.
> Precedence: `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH GAPS`, then
> `COMPLETE`. `COMPLETE` = reusability evidenced (or an accepted exception),
> port + conformance list + deprecation policy designed, ADR `Accepted` (at
> `workflow: minimal`, the decision-log entry written), proposal and consume-back
> plan written. An ADR still `Proposed` caps the verdict at `COMPLETE WITH GAPS`. `BLOCKED`: reusability
> not evidenced and no accepted exception; the capability is product-specific;
> ADR rejected; sensitive capability with no threat model. `NOT ASSESSED`: the
> core repo or the second product's evidence could not be read, or a required
> review could not run. `COMPLETE WITH GAPS`: ADR still `Proposed` awaiting
> `cto`, a review skipped by mode, the other track's parity undecided.
> Evidence verdict words (Phase 2): `EVIDENCED` / `CATEGORY` / `NOT EVIDENCED` /
> `NOT ASSESSED`.

---

## Phase 1: Inputs and Scope

**Read `references/1-inputs-and-evidence.md` now and follow it** (sections 1–3).
It identifies the capability and its code, checks the core does not already
host it (then the answer is `/core-use`), and lists what must be stripped to
make it product-neutral.

## Phase 2: Reusability Evidence (the extraction rule)

**Read `references/1-inputs-and-evidence.md` section 4 now and follow it.** The
rule: **at least two products** with an opened artifact each, **or** the
capability falls in a **core-module category**. Prose claims are not evidence.
Ends in the evidence verdict and a user decision — including the only way past
`NOT EVIDENCED`, a recorded exception.

## Phase 3: Port Design (parallel specialists)

**Read `references/2-port-design.md` now and follow it.** `principal-engineer`
and the track's backend lead design the port, adapters, conformance suite,
fakes, config, error model, tenancy and observability contract, and the
deprecation/versioning stance; category specialists review in parallel. Each
writes its output to a path this skill names.

## Phase 4: ADR

**Read `references/3-adr-proposal-and-migration.md` section 1 now and follow
it.** The ADR is written through `/architecture-decision` and reviewed by
`CTO-ADR`; it is the decision of record that the capability belongs in the core,
what the port is, and what stays in the product.

## Phase 5: Upstream Proposal

**Read `references/3-adr-proposal-and-migration.md` section 2 now and follow
it.** Written for the core repo's team: self-contained, free of product secrets
and customer data, with acceptance criteria the core repo can turn into stories.

## Phase 6: Consume-Back Migration Plan

**Read `references/3-adr-proposal-and-migration.md` section 3 now and follow
it.** The product keeps its local implementation until a released core version
passes parity tests; the plan sequences cross-repo work and records the
dependency as a risk (`producer.md`: a product story never waits on an
unreleased core change without a risk entry).

## Phase 7: Report and Hand-Off

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/core-extract <capability> —
<verdict>`, Next step = the first hand-off below (the exact command, e.g.
`/create-stories` for the consume-back stories), plus Blocked on / Files in
progress (the five artifacts) / Open questions; append the Notes line. Still
updated when the evidence verdict is negative, the run is `BLOCKED` / `NOT
ASSESSED`, or a write was declined (record nothing written and why).

Print: the verdict; the evidence verdict; the five artifacts with paths or
`not written — <reason>`; the ADR status; gates run or skipped
(`[GATE-ID] skipped — <mode> mode`); **Not run / not checked** (always present).

Hand-off, as exact commands for the user (this skill does none of them):
- **In the core repo:** `/studio` with the proposal path as the goal (it
  classifies as a feature there), then `/core-release` when built and tested.
- **In this product:** `/create-stories` for the consume-back stories (ordered by
  `consume-back.md`), then `/core-use <module> --version <released tag>` once the
  release exists.
- The proposal is never pushed or sent anywhere by this skill; opening an issue
  or PR in the core repo is the user's action.

## Error Recovery Protocol

**First, verify the artifact.** If an agent's return contract named a path,
check it exists before treating the phase as done; a fluent reply with no file
is a failed phase — resume it naming the unmet contract. If any agent returns
BLOCKED, errors, or cannot complete: surface it immediately, do not proceed past
a dependency it blocks, offer skip / retry narrower / stop, and produce a
partial report. A skipped review stays a named gap — never fill it with content
of your own. Full procedure: `.claude/docs/error-recovery-protocol.md`.

## Collaborative Protocol

- **Question → Options → Decision → Draft → Approval.** What goes in the core,
  the port shape, the ADR and each file are the user's.
- **The user's `cto` decision is not simulated.** `cto` recommends; the ADR
  moves to `Accepted` only on the user's explicit confirmation (ADR template).
- **No core edits, no pushes, no commits** without an explicit instruction.
- **A skipped or dismissed question is not an answer** — re-ask in plain text.
- Agents write only the paths named in their brief (bounded exception, see
  `references/2-port-design.md`); everything else is asked: "May I write …?"

---

## Recommended Next Steps

`/create-stories` for the consume-back work; `/studio resume`; in the core repo
`/studio` with the proposal, then `/core-release`; here `/core-use` after the
release.
