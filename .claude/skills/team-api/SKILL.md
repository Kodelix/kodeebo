---
name: team-api
description: "Orchestrate a contract change across api-designer, the backend lead and the client leads (web, KMP, Android, iOS): contract first via /api-contract, the breaking-change and deprecation policy with Deprecation/Sunset headers, backend and clients in parallel after the contract merges, contract and authz tests, run-and-observe evidence."
argument-hint: "<feature-slug | change description> [--service <name>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, Skill, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/hooks/yaml-helper.sh is_always_ask_category *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(bash "*/.claude/skills/team-api/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

# Team API

If no argument is provided, output usage guidance and exit without spawning any agents or reading any files:
> Usage: `/team-api <feature-slug | change description> [--service <name>] [--review full|lean|solo]` — name the contract change (e.g. `invoice list cursor pagination`, `rename plan_code to plan_id`, `webhook: subscription.renewed`). Do not use `AskUserQuestion` here; output the guidance directly.

When this skill is invoked, orchestrate the contract change across the teams
that must change with it. **The contract lands first** (`api-standards.md`,
`.claude/rules/contracts.md`): `api-designer` designs it through `/api-contract`;
the backend lead and every client lead start only after it is approved and
written; a **breaking** change never ships without a new major version or an
Accepted ADR (at `modes.workflow: minimal`, an entry in the brief's decision log), a deprecation path and the headers that announce it.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode, and **the
breaking-change route (Phase 3), the story list and any publication of a
deprecation notice always prompt in every mode** (`/studio` always-prompt gates:
ADR · story list · anything publishing externally). See
`.claude/docs/automation-modes.md`.

## Phase 0: Resolve Config

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,team.size,workflow,qa.level,testing.strict,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**Which layers.** From `stack` derive the lanes — never from a default:

| Lane | Condition | Lead (via `principal-engineer`'s routing) | Generated client |
|---|---|---|---|
| Backend | `stack.backend` = `go`, `ktor` or `go+ktor` (the service the change names) | `go-lead` (+ `go-api-specialist`) for Go; `ktor-lead` for Ktor | - |
| Web | `stack.web` = `vite-react` | `web-lead` (+ `react-specialist`) | TypeScript |
| KMP shared | `stack.mobile` contains `kmp` | `kmp-specialist` | KMP |
| Android | `stack.mobile` = `compose`, `kmp` or `kmp+swiftui` | `android-lead` | via the KMP client or its own |
| iOS | `stack.mobile` = `swiftui` or `kmp+swiftui` | `ios-lead` | Swift |

A lane whose `stack` value is `unset` but which consumes the changed operations is
**not changed by this run** — say so and recommend `/setup-stack`; the contract
change is then `COMPLETE WITH GAPS` at best (a consumer that was not migrated).
Only lanes that **consume** the changed operations are spawned (Phase 1 finds
them); a lane with no use of them is `skipped — does not consume <operations>`.

`review_mode` sets director-gate depth. This pipeline spawns no gate itself:
`CTO-ADR` (a breaking change's ADR) runs inside `/api-contract` and
`/architecture-decision` per `review_mode`, recorded `CTO-ADR skipped — <mode>
mode` when skipped. A skipped gate waives the director's opinion, never the
evidence: lint, the breaking-change diff, the contract tests and the authz tests
below are required at every mode and every `workflow` tier.

**`team.size`**: which agents this skill spawns **directly**.
- **`individual`** (default): `api-designer` (through `/api-contract`), the backend
  lead, and the client leads of the consuming lanes.
- **`small`**: + `test-automation-engineer` (contract tests per consumer) and,
  for a breaking or deprecating change, `technical-writer` (API docs, migration
  guide) and `release-manager` (deprecation timeline, minimum supported app versions).
- **`studio`**: + `appsec-engineer` (contract and endpoint security review),
  `go-api-specialist` / the layer specialists the leads name, `customer-success`
  (customer notice for a breaking change), and an adversarial review pass: the
  Phase 5 reviewers are told "your job is not to confirm this matches the
  contract — find where it fails it", and the report says the pass ran.
A non-core agent needed at a smaller size routes through the nearest active core
agent with an informational note.

**Announce the active set before Phase 1:**

> `Active set (team.size: <resolved>): <agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

The collapse is correct (`team.size` is the token lever); naming it is what keeps
a correctly collapsed run distinguishable from a broken pipeline.

## Team Composition

- **api-designer** — the contract: operations, schemas, errors, pagination, idempotency, versioning; breaking-change classification; client-generation plan
- **backend lead** (`go-lead` / `ktor-lead`) — handlers, DTOs, problem-details mapping, authz and tenant scoping, deprecation headers, contract and authz tests
- **web-lead**, **kmp-specialist**, **android-lead**, **ios-lead** — consume the regenerated client, map errors by stable `code`, tolerate unknown enum values, migrate off deprecated operations
- **test-automation-engineer**, **technical-writer**, **release-manager**, **appsec-engineer** — as the active set allows

## How to Delegate

Use the `Agent` tool for agents and the `Skill` tool for `/api-contract`,
`/architecture-decision`, `/create-stories`, `/changelog`, `/release-notes`.
Independent agents are spawned **in parallel** — issue every independent `Agent`
call before waiting for any result (`.claude/docs/coordination-rules.md`).
`/db-migration` is user-run (`disable-model-invocation`): when the change needs a
schema step, this skill prints the command and the backend lane waits on its
artifacts (or hands the whole data change to `/team-data`).

**Brief each agent — do not dump context.** Read shared inputs **once** and pass a
distilled brief inline; pass a path only for a document you have not read and only
that agent needs.

**End every agent prompt with a return contract:** "Write your full output to
`[path]` — that named path is your write authorisation under the bounded
exception below, so write it without a separate approval prompt. Return **only**
(1) the path written, (2) a ≤5-bullet summary of decisions, (3) any
BLOCKED/CONCERNS items, one line each. Do not restate the documents you read."
**Implementation files are the exception:** a lead first returns the files it will
create or change; it writes them only after you asked once for the set and the
user said yes.

**Substitute a real path.** Artifacts go under `production/api/<slug>/`, one file
per agent:

| Phase / agent | Writes to |
|---|---|
| 1 principal-engineer (routing, only if the consumers are unclear) | `routing.md` |
| 3 release-manager / technical-writer | `deprecation-plan.md` (release-manager), `migration-guide-draft.md` (technical-writer) |
| 4 each lead | `impl-<lane>.md`; the code roots for code (outside the exception) |
| 5 reviewers, test-automation-engineer (at `individual`, where it is not spawned, the backend lead) | `review-<agent>.md`, `contract-tests.md` |
| 6 close | `team-api-report.md` |

The contract itself and the contract-change record are written by `/api-contract`
at its own paths with its own approvals.

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an
> agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent
> spawned here writes **without** asking, a deliberate, bounded exception that
> holds only when (1) the path is one **you** named in the prompt, (2) it is a new
> artifact under `production/`, `docs/` or a test directory, never an edit to
> existing source or config — `contracts/` is existing config, so the contract is
> written only through `/api-contract` after approval — and (3) the phase is gated
> by an `AskUserQuestion` before the pipeline advances. Outside those three the
> agent must ask. **Do not "fix" this by asking per subagent.**

## Pipeline

Each phase names a reference to read when you reach it; read it again if the
conversation was compacted. Report each phase in one line as you leave it:
`Phase n — <name>: ran | skipped — <named reason> | BLOCKED — <what>`.

### Phase 1: Intake and Consumers

**Read `references/1-intake-and-contract.md` sections 1–2 now and follow them.**
Slug, service, existing artifacts (FOUND/ABSENT), and the **consumer map** —
which lanes, which operations — with what could not be enumerated said plainly.

### Phase 2: The Contract (api-designer)

**Read `references/1-intake-and-contract.md` section 3 now and follow it.**
`/api-contract` produces the reviewed, linted, diffed, client-generating change
and the contract-change record; this phase verifies the artifacts on disk and
reads the classification: ADDITIVE / DEPRECATING / BREAKING.

### Phase 3: Breaking-Change and Deprecation Policy

**Read `references/2-policy-and-lanes.md` sections 1–2 now and follow them.**
Runs only when the classification is DEPRECATING or BREAKING; otherwise
`skipped — classification ADDITIVE`. Gate: the route, the support window, the
timeline.

### Phase 4: Stories and Lanes in Parallel

**Read `references/2-policy-and-lanes.md` sections 3–4 now and follow them.**
Stories per consuming lane (gate: story list); backend ‖ web ‖ KMP, then Android ‖
iOS; old-client compatibility during any deprecation window.

### Phase 5: Verification

**Read `references/3-verify-and-close.md` sections 1–2 now and follow them.**
Contract tests per consumer, authz and negative tests per operation, header
checks, run-and-observe evidence, re-run lint and diff.

### Phase 6: Docs, Notice, Report

**Read `references/3-verify-and-close.md` sections 3–4 now and follow them.**

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the path
exists before treating the phase as done — **a named artifact that is not on disk
is a failed phase, however fluent the response reads.** Resume the agent naming
the unmet contract. The same applies to what `/api-contract` should have produced
(the contract change in `contracts/`, the contract-change record).

If any spawned agent or skill returns BLOCKED, errors, or cannot complete:
**surface it immediately, don't proceed past a dependency it blocks, and always
produce a partial report.** A skipped agent's section stays a named gap — never
fill it with content of your own; **a skip does not clear a block.** Full
procedure: `.claude/docs/error-recovery-protocol.md`.

Common blockers:
- A BREAKING change with neither a new major nor an Accepted ADR (decision-log entry at `minimal`) → `/architecture-decision`, then `accept`
- The contract not written or the contract-change record absent → back to Phase 2; no lane starts
- Lint, breaking-change diff or client generation `not run` (tooling not set up in the repo) → `NOT ASSESSED`; `dev-tooling-engineer` via `principal-engineer` sets it up, `/research` chooses and pins it
- A consuming lane with `stack` unset → `/setup-stack`; the lane is a named gap
- The change needs a schema step → `/db-migration` (user-run) or `/team-data`; the backend lane waits on its files
- A story spans more than three lanes → split via `/create-stories`

## File Write Protocol

Writes are delegated to sub-skills (they ask per the Collaboration Protocol) and
sub-agents (named `production/api/<slug>/` paths under the bounded exception;
implementation files returned as a set, asked once, written after a yes). The
orchestrator writes only the checkpoint in `production/session-state/active.md`
(exempt from the prompt; its own `## API pipeline — <slug>` block, never the
`## Studio flow` block that only `/studio` writes) and nothing else without asking.
Shell commands (dev stack, lint, generators, test suites) are run by the leads and
`test-automation-engineer` through `Agent` or by `/api-contract`; this skill grants
only the helper calls and `date`.

## Output

A summary report (`production/api/<slug>/team-api-report.md`, after approval):
the classification and route; operations added / changed / deprecated / removed;
consumer map and what could not be enumerated; per lane: the generated client
status (`regenerated by <generator>` or `not regenerated — <reason>`), files,
tests; lint, diff and generation results (real output or `not run — reason`);
contract and authz test results; headers verified; deprecation timeline; evidence
paths; gates run or skipped by mode; **Not run / not checked** (always present).

Verdict: **COMPLETE** — contract written and approved, tooling ran clean, every
consuming lane migrated and tested, no unresolved BREAKING row, evidence on disk.
Verdict: **COMPLETE WITH GAPS** — named gaps (a lane unset in `stack`, a consumer
with no test location, no API policy recorded for a deprecation, `CTO-ADR` CONCERNS).
Verdict: **NOT ASSESSED** — lint, diff, generation, a consumer test or the
run-and-observe step did not run, or external consumers could not be assessed
beyond what the repo shows; name each.
Verdict: **BLOCKED** — an unresolved breaking change, a failing contract or authz
test, a missing contract, or a `CTO-ADR` REJECT.
Verdict: **BLOCKED — write declined by user** — the user declined the report or the
implementation file set; nothing is reported as COMPLETE.
Precedence: BLOCKED, NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE.

## Collaborative Protocol

- **The user decides at every gate**; silence or an agent's report is never
  approval. A skipped or dismissed question is not an answer — re-ask in plain text.
- **Contract before code.** No handler, client change or test of the new behaviour
  precedes the approved contract; no hand edits to generated clients.
- **No invented numbers.** A support window comes from the product's API policy or
  the user; a header value format comes from the cited primary source; a tool's
  flags come from the repo — otherwise `NOT SOURCEABLE`.
- **No commits, pushes, deploys, migrations applied, or published notices** without
  an explicit instruction for that action.
- **A check that did not run is reported as `not run`**, never as passed.

## Next Steps

`/code-review` per lane, then `/story-done <story>` for each (user-run);
`/team-qa feature: <context>` for the cycle; `/changelog` and `/release-notes`
when the change is public; `/team-security` or `/security-audit` before release for
auth, billing, licensing, webhook and admin surfaces; `/tech-debt` for the removal
story scheduled after the sunset.
