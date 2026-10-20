---
name: team-feature
description: "Orchestrate one feature end to end — research, spec, threat model when triggered, contract first, data and cache design, backend/web/mobile leads in parallel after the contract, QA, then the story-done hand-off. Owner routing through principal-engineer. Same backbone as the /studio feature flow."
argument-hint: "<feature description | feature-slug> | resume [feature-slug] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, Skill, AskUserQuestion, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/hooks/yaml-helper.sh is_always_ask_category *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(go -C * vet *), Bash(go -C * test *), Bash(pnpm -C * install --frozen-lockfile), Bash(pnpm -C * lint), Bash(pnpm -C * typecheck), Bash(pnpm -C * test), Bash(pnpm -C * test *), Bash(pnpm -C * build), Bash(pnpm -C * exec playwright *), Bash(pnpm -C * audit), Bash(pnpm -C * audit *), Bash(pnpm test), Bash(pnpm audit), Bash(swift test), Bash(swiftlint), Bash(bash .claude/scripts/spec-structure-check.sh), Bash(bash .claude/scripts/project-coherence.sh), Bash(bash .claude/scripts/project-coherence.sh *), Bash(docker compose -f deploy/compose.dev.yaml up -d --wait), Bash(docker compose -f deploy/compose.dev.yaml ps), Bash(docker compose -f deploy/compose.dev.yaml ps *), Bash(docker compose -f deploy/compose.dev.yaml logs *), Bash(docker compose -f deploy/compose.dev.yaml down), Bash(bash "*/.claude/skills/team-feature/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/spec-structure-check.sh *), Bash(bash .claude/scripts/migration-lint.sh *), Bash(gofmt *), Bash(go vet *), Bash(go test *), Bash(golangci-lint run *), Bash(govulncheck *), Bash(osv-scanner scan *), Bash(./gradlew *), Bash(pnpm install --frozen-lockfile), Bash(pnpm lint), Bash(pnpm typecheck), Bash(pnpm test *), Bash(pnpm build), Bash(pnpm preview), Bash(pnpm dev), Bash(pnpm exec playwright *), Bash(pnpm audit *), Bash(swift test *), Bash(xcodebuild test *), Bash(swiftlint *), Bash(gitleaks git *), Bash(gitleaks dir *), Bash(docker compose logs *)
model: sonnet
---

# Team Feature

If no argument is provided, output usage guidance and exit without spawning any agents or reading any files:
> Usage: `/team-feature <feature description | feature-slug> [--review full|lean|solo]` — name the feature (e.g. `team invitations`, `annual plan upgrade`, `csv export`). `/team-feature resume [feature-slug]` continues a run recorded in `production/session-state/active.md`. Do not use `AskUserQuestion` here; output the guidance directly.

When this skill is invoked, orchestrate the team through the feature backbone
in the `/studio` skill folder (`.claude/skills/studio/`, file `3-flows.md`): **research → spec → threat
model (if triggered) → contract → data/cache → architecture → stories →
implementation by layer → QA → story-done**. `/studio` runs the same backbone
step by step from a goal in plain words; this skill is the team form for when you
already know it is a feature and want the layers worked **in parallel after the
contract**.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. **The gates listed in Phase 0 always prompt, in every mode**, as
in `/studio` (`.claude/skills/studio/`, file `4-run.md`). Decisions in
`automation_always_ask` categories (`is_always_ask_category` helper) always
prompt regardless of mode. See `.claude/docs/automation-modes.md`.

## Phase 0: Resolve Config

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,team.size,workflow,story_granularity,qa.level,testing.strict,performance.enforce,system_overrides,project.stage,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**Gates that always prompt, every automation mode** (identical to `/studio`):
research conclusion · spec approval · threat-model residual risk · ADR · story
list · each story's Done · release go/no-go · any destructive data step
(migration apply, deletion) · anything publishing externally. `guided` and
`autonomous` change how *other* decisions are passed, never these.

**`stack` is the only source for routing.** From it, work out which layers the
feature touches: backend (`go` → `go-lead`, `ktor` → `ktor-lead`, `go+ktor` → the
service the feature names), web (`vite-react` → `web-lead`), site (`astro` →
`web-lead`), mobile (`kmp` → `kmp-specialist` + `android-lead`, `kmp+swiftui` →
`kmp-specialist` + `android-lead` + `ios-lead`, `compose` → `android-lead`,
`swiftui` → `ios-lead`), data stores (`stack.data`). A layer printed `unset`
that the feature needs is **not implemented by this run** — say so and recommend
`/setup-stack`. Never choose a framework or a lead yourself.

`review_mode` sets director-gate depth, and **this orchestrator spawns no
director gate itself**: `PD-SPEC-ALIGN`, `SL-THREAT-MODEL`, `CTO-ADR`,
`QL-STORY-READY`, `PE-CODE-REVIEW` and the story-done gates run inside the skills
this pipeline invokes, each applying `review_mode` itself and recording `[GATE-ID]
skipped — <mode> mode` when skipped. A skipped gate waives the director's
opinion, never the evidence: the research note, the threat model for a sensitive
feature, the eight DoD gates and run-and-observe are required at every mode and
every `workflow` tier (`workflow-modes.md`: tiers scale documents, never
engineering).

**`team.size`**: which agents this skill spawns **directly** (orthogonal to
review_mode and workflow). Skills it invokes apply `team.size` themselves.
- **`individual`** (default): `principal-engineer` (routing, plan, integration of
  results) + the stack lead(s) of the layers touched. Everything else is reached
  through the skills this pipeline invokes, or consulted through
  `principal-engineer`'s routing note.
- **`small`**: + `domain-architect` and `pricing-billing-designer` at Phase 3
  when their trigger fires, + `test-automation-engineer` (contract/integration
  gaps at Phase 7), + `appsec-engineer` reviewing security-sensitive stories.
- **`studio`**: + the layer specialists the leads name (`react-specialist`,
  `kmp-specialist`, `compose-ui-specialist`, `swiftui-specialist`, `go-api-specialist`,
  `kotlin-persistence-specialist`...), + `security-lead` at Phases 4 and 7,
  + `qa-lead` spawned directly at Phase 8, + an adversarial review pass: Phase 7's
  reviewers are told "your job is not to confirm this matches the spec — find
  where it fails it", and the report says the pass ran.
A non-core agent needed at a smaller size routes through the nearest active core
agent with an informational note.

**Announce the active set before Phase 1 — never let the collapse be silent.**
State in one line which agents this run will spawn directly and which the pipeline
names but will **not** spawn:

> `Active set (team.size: <resolved>): <agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

The collapse is correct: `team.size` is rigor-fronted and the narrow default is
the token lever. Without saying so, a reader cannot tell a correctly collapsed run
from a broken pipeline — **a constraint that is enforced but never surfaced is
indistinguishable from one that was never enforced.**

## Team Composition

- **principal-engineer** — routing to leads and the shared-core boundary; module design before code; integrates results; reviews at phase gates
- **go-lead / ktor-lead** — backend layer; **web-lead** — SPA and site; **kmp-specialist** — shared mobile module; **android-lead**, **ios-lead** — native apps
- **api-designer**, **data-lead** (and its specialists) — spawned by `/api-contract`, `/team-api`, `/team-data`, `/cache-design`; never bypassed
- **domain-architect**, **pricing-billing-designer** — new context / plans and entitlements (Phase 3)
- **test-automation-engineer**, **qa-lead**, **appsec-engineer**, **security-lead** — as the active set above allows

## How to Delegate

Use the `Agent` tool to spawn each member (`subagent_type` = the agent name in
`.claude/docs/agent-roster.md`), and the `Skill` tool for the skills named in the
phases. **Skills that only the user can run** — every skill with
`disable-model-invocation: true` (derive the list, do not trust a copy:
`grep -l "disable-model-invocation: true" .claude/skills/*/SKILL.md`; today
`/dev-story`, `/story-done`, `/db-migration`, `/hotfix`, `/post-release-fix`,
`/incident`, `/pentest`, `/core-release`, the same set `/studio` pauses on) —
are **never invoked from here**: the pipeline
prints the exact command with its arguments, pauses at that step, and verifies
the artifact the command should have produced before continuing (Phase 5 for
`/db-migration`, Phase 9 for `/story-done`). If the Skill tool refuses a skill,
that is the same hand-off, not an error to route around by doing its work
yourself.

**Brief each agent — do not dump context.** Read shared inputs **once** and pass
a distilled brief inline (the lines each agent needs); pass a path only for a
document you have not read and only that agent needs. Independent agents are
spawned **in parallel** — issue every independent `Agent` call before waiting for
any result (`.claude/docs/coordination-rules.md`, Parallel Task Protocol).

**End every agent prompt with a return contract:** "Write your full output to
`[path]` — that named path is your write authorisation under the bounded
exception below, so write it without a separate approval prompt. Return **only**
(1) the path written, (2) a ≤5-bullet summary of decisions, (3) any
BLOCKED/CONCERNS items, one line each. Do not restate the documents you read."
**Implementation files are the exception:** an agent writing code first returns
the files it will create or change; its return contract names them only after you
asked once for the set and the user said yes (File Write Protocol).

**Substitute a real path for `[path]`.** Working artifacts go under
`production/features/<feature-slug>/` — one file per agent, so parallel work never
shares a file:

| Phase / agent | Writes to |
|---|---|
| 1 principal-engineer | `routing.md` |
| 3 domain-architect / pricing-billing-designer | `consult-<agent>.md` |
| 6 principal-engineer (architecture proposal) | `architecture.md` |
| 7 stack lead per story and lane | `impl-<story-id>-<lane>.md`; the code roots for code (outside the exception) |
| 7 reviewers | `review-<story-id>-<agent>.md` |
| 9 close | `feature-report.md` |

Specs, ADRs, contracts, migration plans, stories, QA plans and evidence are
written by the skills that own them, at their own paths, with their own approvals.

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an
> agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent
> spawned here writes **without** asking, a deliberate, bounded exception that
> holds only when all three are true: (1) the path is one **you** named in the
> prompt, so the user approved the destination when they approved the phase; (2)
> it is a new artifact under `production/`, `docs/` or a test directory, never an
> edit to existing source or config; (3) the phase that produced it is itself
> gated by an `AskUserQuestion` before the pipeline advances. Outside those three
> the agent must ask. **Do not "fix" this by asking per subagent.**

## Pipeline

Each phase below names a reference to read **when you reach it** and follow; read
it again if the conversation was compacted or resumed in that phase. Report a
phase's status in one line as you leave it: `Phase n — <name>: ran | skipped —
<named reason> | BLOCKED — <what>`. **A skipped step is named, never silent.**

### Phase 1: Intake, Routing and the Plan

**Read `references/1-intake-and-routing.md` now and follow it.** Resolves the
feature slug, inventories existing artifacts (FOUND/ABSENT), runs the core-first
check, has `principal-engineer` write the routing note, builds the plan table
(step · runs? · trigger or the named reason it is skipped) and asks "Run this
plan?" — the gate before any work.

### Phase 2: Research

**Read `references/2-discovery.md` section 1 now and follow it.** `/research`;
gate: research conclusion.

### Phase 3: Spec

**Read `references/2-discovery.md` section 2 now and follow it.** `/design-spec`
or `/quick-spec`; consultants by trigger; gate: spec approval.

### Phase 4: Threat Model (if triggered)

**Read `references/2-discovery.md` section 3 now and follow it.** `/threat-model`;
gate: residual risk.

### Phase 5: Contract, Data, Cache and UX Specs (parallel after the spec)

**Read `references/3-design.md` sections 1–2 now and follow them.** Contract
first; data and cache design; UX spec — independent lanes started together.

### Phase 6: Architecture and Stories

**Read `references/3-design.md` sections 3–4 now and follow them.** ADRs for each
architectural choice; epics and stories; gate: ADR, gate: story list.

### Phase 7: Implementation by Layer (waves)

**Read `references/4-implementation-waves.md` now and follow it.** Per story:
readiness → leads in the lane order, **clients in parallel once the contract is
merged** → review. The user chooses, once, whether this skill implements through
the leads or prints the `/dev-story` commands.

### Phase 8: QA

**Read `references/5-qa-and-close.md` section 1 now and follow it.** `/smoke-check`,
then `/team-qa feature: <slug>`.

### Phase 9: Close and Hand-Off

**Read `references/5-qa-and-close.md` sections 2–4 now and follow them.** Release
notes if user-visible; the `/story-done` hand-off per story; the report; the
checkpoint in `production/session-state/active.md`.

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not on
disk is a failed phase, however fluent the response reads.** An agent can burn a
full phase and return a plausible preamble having written nothing, which is
neither BLOCKED nor an error. Resume it naming the unmet contract; the context is
usually still there. The same applies to a skill that was supposed to produce a
file (a spec, a contract change record, stories): check the path.

If any spawned agent or invoked skill returns BLOCKED, errors, or cannot
complete: **surface it immediately, don't proceed past a dependency it blocks, and
always produce a partial report.** A skipped agent's section stays a named gap —
never fill it with content of your own; **a skip does not clear a block.** Full
procedure: `.claude/docs/error-recovery-protocol.md`.

Conflicts: product → `product-director`; technical → `cto`; schedule/cross-team →
`producer`. Present the conflict and the owner's recommendation; the user decides.

Common blockers:
- No `stack` value for a layer the feature needs → `/setup-stack`
- `PRODUCT.md` absent for a UI feature → `/impeccable init`, then re-run
- Spec / research note / threat model missing for a story → the phase that writes it
- ADR `Proposed` → stories referencing it stay Blocked until `/architecture-decision accept ADR-NNNN`
- Contract not merged → no client or backend story starts
- A core module the feature needs is not released → `/core-extract`, then `/core-use` after `/core-release`; a risk entry, never a local copy
- Scope too large (a story spans more than three lanes) → split via `/create-stories`

## File Write Protocol

All writes are delegated: to sub-skills (they ask per the Collaboration
Protocol; the bounded exception does not reach them) and to sub-agents (named
`production/features/<slug>/` paths follow the bounded exception; **implementation
files** are returned as a set, asked once, and written after a yes). This
orchestrator writes only `production/session-state/active.md` (the checkpoint,
exempt from the prompt) and nothing else without asking.

## Output

A summary report (`production/features/<slug>/feature-report.md`, written after
approval) covering: the plan table with every step's status (ran / skipped —
reason / BLOCKED), the active set, artifacts produced with paths, gates run or
skipped by mode, per story: layers, evidence folder and the `/story-done` command,
the QA verdict, **Not run / not checked** (always present), and open issues.

Verdict: **COMPLETE** — every planned step ran, every story is implemented with
its evidence on disk and `PE-CODE-REVIEW`/`/code-review` not REJECT, QA verdict
APPROVED; stories are **ready for `/story-done`** (only `/story-done` marks a
story Done).
Verdict: **COMPLETE WITH GAPS** — as above with named gaps (QA `APPROVED WITH
CONDITIONS`, a gate skipped by mode, a deferred step the user accepted).
Verdict: **NOT ASSESSED** — a required check could not run (QA `NOT ASSESSED`, no
container runtime, a layer's `stack` unset, evidence missing); name each.
Verdict: **BLOCKED** — a gate verdict REJECT, QA `NOT APPROVED`, or an unresolved
blocker; name the phase.
Precedence: BLOCKED, NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE. A user override
past a gate is recorded with the verdict, the concerns left open and that the user
chose to proceed.

## Collaborative Protocol

- **The user decides at every gate.** Silence, a subagent's report or a hook
  message is never approval. A skipped or dismissed question is not an answer:
  re-ask in plain text and wait.
- **One decision at a time:** produced (paths) · what it decides · options · a
  recommendation citing an artifact.
- **Standing decisions are not re-asked** (`.claude/docs/standing-decisions.md`: web stack, licence
  rules L1–L4, core per track, markets).
- **No commits, pushes, deploys or publications** without an explicit instruction
  for that action; no migration applied from here.
- **Report checks honestly:** a check that did not run is "not run".

## Next Steps

- `/story-done <story-path>` for each story (printed in Phase 9), then `/sprint-status`.
- `/team-security` or `/security-audit` before release when the feature was security-sensitive; `/team-release` when shipping.
- `/studio resume` to continue under the orchestrator.
