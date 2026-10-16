---
name: api-contract
description: "Contract-first OpenAPI change in contracts/ per api-standards.md: design, checklist review, lint, breaking-change diff against the last released contract, client regeneration (TS/KMP/Swift), contract-test plan; an ADR (CTO-ADR) when the change is breaking."
argument-hint: "[feature-slug | check [service]] [--service <name>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git status), Bash(git status *), Bash(git diff *), Bash(git show *), Bash(git tag --list), Bash(git tag --list *), Bash(git tag --sort=*), Bash(git tag -n1 *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Write, Edit, Agent, AskUserQuestion, Bash(date *), Bash(bash "*/.claude/skills/api-contract/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,automation_always_ask,testing.strict,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt). Choosing between a new major
version and an ADR for a **breaking** change, and running a generator that
rewrites client code, are major decisions: they ask in `guided` and are logged
in `autonomous` unless an always-ask category applies.

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**`workflow`** does **not** relax this skill. The API contract is the product's
contract with its own clients and with self-hosted customers who lag several
versions; contract-first, the checklist and the breaking-change diff apply at
every tier (`workflow-modes.md`: tiers scale documents, never engineering).

# API Contract

The API is the contract between the backend and every client: web, Android,
iOS, self-hosted integrations, customer automations. **Contract first**
(`.claude/docs/api-standards.md`): the change lands in `contracts/` and is
reviewed before a handler is written. This skill drives one contract change from
design to a reviewed, linted, diffed, client-generating and test-planned state.
The design is `api-designer`'s; the decisions are the user's.

**Modes**
- **change** (default, `[feature-slug]`): design or alter operations for a feature.
- **`check [service]`**: no design; run the checklist, lint, breaking-change diff
  and client-generation check on the contract as it is in the working tree.

**Output:** the edited `contracts/openapi/<service>.yaml` (or
`contracts/proto/**` only when an ADR chose gRPC), regenerated clients **only
through the generator**, and a contract-change record with the checklist result,
the tooling table and the contract-test plan.

> **Tooling that is not in the stack reference is `NOT SOURCEABLE`.** The OpenAPI
> linter, the breaking-change diff tool and the client generators (TypeScript,
> KMP, Swift) are not pinned anywhere in `docs/stack-reference/`. Their commands
> and flags are never written from memory. Each is run only if the repository
> already defines it (an ADR, a CI job, a package or Gradle task, a `tools/`
> script); otherwise it is reported **`not run - tooling not in the stack
> reference and not set up in this repository`**, routed to `dev-tooling-engineer`
> (through `principal-engineer`) to set up, and to `/research` to choose and pin.
> A hand read of the YAML is a *review*, labelled as such, never a lint.

> **Verdicts:** `COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`.
> Precedence: `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH GAPS`, then
> `COMPLETE`. `BLOCKED`: an unresolved breaking change (no new major and no
> Accepted ADR), a checklist failure on a security item, or a CTO-ADR REJECT.
> `NOT ASSESSED`: lint, breaking-change diff or client generation did not run, the
> last released contract could not be found, or an input is absent. `COMPLETE`
> needs all three tool results real and clean. Each cause is named.

---

## Phase 1: Parse, Inputs and Mode

**Read `references/1-inputs-and-modes.md` now and follow it.** It parses the
argument, resolves the service and the contract file(s), finds the **last
released contract** (a git tag or release record), reads the spec, research
note, threat model and ADRs (JSON field-case convention, generator choice), and
records every input as FOUND or ABSENT. Read it again if the conversation was
compacted or resumed.

## Phase 2: Design Proposal (api-designer)

Skip in `check` mode. Spawn `api-designer` via `Agent` with the fixed brief in
`references/1-inputs-and-modes.md` ("Design brief"). It returns a **proposal as
text**: operations (method, path, `operationId`), schemas, error catalogue,
pagination/filter/sort, idempotency and concurrency, auth and tenant semantics,
webhooks if any, examples, and a self-assessed breaking-change classification.
It does not write to `contracts/` yet.

When the change spans independent services or an inbound/outbound webhook
catalogue, spawn one `api-designer` per independent contract file in parallel.
If `api-designer` cannot be spawned, say why, design the change here against
the same checklist, and let the record's **Designed by** line say so.

## Phase 3: Checklist Review

**Read `references/2-contract-checklist.md` now and follow it.** Review the
proposal (or, in `check` mode, the file) item by item against
`.claude/rules/contracts.md`, `api-standards.md` and the security baseline. Every
item is `met` / `not met` / `n/a - reason` with a `file:line` or proposal
section. This is a **review**, not a lint; the report says so.

## Phase 4: Decide, Then Write

Present the proposal summary, the checklist result and the breaking-change
classification. Decisions are the user's (Question -> Options -> Decision): field
case if no ADR fixes it, resource shape alternatives, and for any **breaking**
change `AskUserQuestion` between **(a) a new major version** (`/v2`, old kept for
the support window), **(b) an ADR plus `Deprecation`/`Sunset` headers**, or
**(c) rework as an additive change**. Route (b) to `/architecture-decision` (tell the user to run it — this skill does not run other skills;
it runs CTO-ADR) and treat the change as `BLOCKED` until that ADR is
Accepted; in `full` review mode, if the ADR exists but no CTO-ADR verdict is on
record, spawn `cto` for **CTO-ADR** (the prompt tells it to read
`.claude/docs/director-gates/cto-adr.md` first; you do not read it). In `lean`
or `solo` record `CTO-ADR skipped - [mode] mode`.

Then ask: "May I write the contract change to `contracts/openapi/<service>.yaml`
[and list every other path]?" Write only after approval, by resuming
`api-designer` with the approved paths named (or yourself, from the approved
proposal). A new artifact under `docs/`, `design/` or `production/` that a skill
names is the sanctioned subagent write; `contracts/` is existing config, so the
approval above is what authorises it.

## Phase 5: Lint, Breaking-Change Diff, Client Generation

**Read `references/3-tooling-and-diff.md` now and follow it.** It discovers
which of lint, breaking-change diff and generators the repository defines, runs
those that exist and reports their real output, performs the manual diff against
the last released contract as a labelled hand-check, and reports every missing
tool as `not run`. Generated clients are produced **only by the generator** and
are never hand-edited; if a generator is missing, the clients are `not
regenerated` and the verdict says so.

## Phase 6: Contract-Test Plan and Record

**Read `references/4-tests-and-handoff.md` now and follow it.** It produces the
contract-test plan per consumer and the per-endpoint authz/negative cases,
states the deprecation and changelog obligations for a breaking or deprecating
change, and writes the contract-change record after asking. Read it again after
compaction.

---

## Error Recovery Protocol

**First, verify the artifact.** If a spawned agent was told to write a path,
check that the path exists and that the change matches the approved proposal; a
proposal returned as a preamble with no operations is a failed phase. If any
agent returns BLOCKED, errors or cannot complete: surface it immediately, do not
proceed past a dependency it blocks, offer skip / retry narrower / stop via
`AskUserQuestion`, and always produce a partial report. A skip does not clear a
block. A gate agent that could not run is `NOT ASSESSED - [what was missing]`.
Full procedure: `.claude/docs/error-recovery-protocol.md`.

## Collaborative Protocol

- **Decision records follow the tier.** "An ADR" in this skill means an ADR (at
  `modes.workflow: minimal`, an entry in the brief's decision log, `design/product-brief.md`).
- **Question -> Options -> Decision -> Draft -> Approval.** Resource design
  choices, the breaking-change route and every write are the user's.
- **The contract lands before handler code.** This skill never writes a handler,
  a migration or a client by hand; it routes them to the stack lead through
  `principal-engineer`.
- **Never hand-edit generated client code.** A generated file that differs from
  what the generator produces is a review failure.
- **Never write a tool name's flags, a generator option, an OpenAPI keyword
  behaviour or a version from memory.** Run what the repo defines, or write `not
  run` / `NOT SOURCEABLE`.
- **A breaking change is not smuggled in as additive.** Removed or renamed
  field, tightened validation, changed type, new required input, changed
  semantics or status code - the diff names each.
- **A check that did not run is reported as `not run`, never as passed.**
- A skipped, dismissed or empty answer is not an answer: act on nothing, ask
  again in plain text and wait.

---

## Recommended Next Steps

- Contract approved and written: `/create-stories` (a Contract story per consumer) or `/story-readiness [story]`; the story's `Contract:` line points at the change record
- Tooling `not run`: ask `dev-tooling-engineer` (via `principal-engineer`) to add lint, breaking-change diff and generation to CI; `/research` to choose and pin them, then `/architecture-decision` for the generator
- Breaking change: `/architecture-decision` (ADR with the support window), then `/changelog` and `/release-notes` for the deprecation notice
- Sensitive surface (auth, billing, licensing, webhooks, upload, admin): `/threat-model [feature]` before handlers
- New or changed endpoints: `/observability-plan plan [feature]` (route templates, RED metrics, `trace_id` in errors)
- Handlers: `/dev-story [story]`, which reads the contract first
