---
name: team-data
description: "Orchestrate a schema or data change across data-lead, migration-specialist, postgres/mongo specialists, cache-specialist and messaging-specialist: read patterns first, data design, expand-migrate-contract plan via /db-migration (user-run), persistence/outbox/cache ripple by the backend lead, tenant-isolation and migration tests, retained evidence."
argument-hint: "<feature-slug | change description> | resume [slug] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, Skill, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash .claude/scripts/migration-lint.sh), Bash(bash .claude/scripts/migration-lint.sh *), Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/hooks/yaml-helper.sh is_always_ask_category *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(bash "*/.claude/skills/team-data/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

# Team Data

If no argument is provided, output usage guidance and exit without spawning any agents or reading any files:
> Usage: `/team-data <feature-slug | change description> [--review full|lean|solo]` — name the data change (e.g. `invoice archive table`, `split address into columns`, `outbox for subscription events`, `cache plan lookups`). `/team-data resume [slug]` continues after you have run `/db-migration`. Do not use `AskUserQuestion` here; output the guidance directly.

When this skill is invoked, orchestrate a schema or data change across the data
team. Every byte a product stores has an owner, an isolation story, a retention
story and a rollout that is safe **at every intermediate release** — self-hosted
customers upgrade across several versions (`.claude/rules/migrations.md`).

**What this skill is and is not.** It coordinates the design and the ripple (the
persistence adapters, outbox rows, cache keys, events and tests that must change
with the schema). The migration files themselves, their lint, and **applying**
them belong to `/db-migration`, which only the user can run
(`disable-model-invocation`): Phase 5 prints the command and pauses, and `resume`
continues once the artifacts are on disk. **Nothing here applies a migration,
runs a backfill against real data, or deletes data.**

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode, and **these
always prompt in every mode**: an ADR (a data store or messaging decision is
critical), the story list, and **any destructive data step** — `DROP`,
`TRUNCATE`, a data-deleting statement, a hard delete, a retention purge — each
needing its own approval and a backup step in the release checklist
(`.claude/skills/studio/`, file `4-run.md`; `.claude/rules/migrations.md`). See
`.claude/docs/automation-modes.md`.

## Phase 0: Resolve Config

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,team.size,workflow,qa.level,testing.strict,performance.enforce,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**Which stores.** From `stack`: `data=` (any of `postgres`, `mongo`, `redis`,
`dragonfly`), `tenancy=` (the tenancy model: `shared-schema-rls`,
`schema-per-tenant`, `db-per-tenant`, `single-tenant`), `distribution=`, and the
backend (`go` → `go-lead`, `ktor` → `ktor-lead` with `kotlin-persistence-specialist`,
`go+ktor` → the service the change names). The messaging choice (`stack.messaging`) is not on the resolved line: read it from `project.yaml`; unset or `none` for a change that publishes events means the broker is an unmade decision — an ADR for `cto`, not a default. **A value printed `unset` that the
change needs is not defaulted:** `data` unset → STOP, `/setup-stack`; `tenancy`
unset for a tenant-owned table → STOP (the tenancy model is decided by `cto`
via ADR on `multitenancy-specialist`'s recommendation, never guessed here); a store
named in the change but absent from `stack.data` is a **new store** — that is an
ADR for `cto` and, for customer bundles, a licence review (Valkey for cache,
the official Mongo image reference only, Dragonfly hosted-only —
`.claude/docs/standing-decisions.md` L1–L3), not something this skill adds.

`review_mode` sets director-gate depth. This pipeline spawns no gate itself:
`CTO-ADR` runs inside `/architecture-decision`, `SL-TENANT-ISOLATION` inside
`/tenant-check` and `/story-done`, each per `review_mode`, recorded `[GATE-ID]
skipped — <mode> mode` when skipped. A skipped gate waives the director's opinion,
never the evidence: tenant-isolation tests, the migration test matrix and lint are
required at every mode and every `workflow` tier (`workflow-modes.md`).

**`team.size`**: which agents this skill spawns **directly**. A specialist whose
concern *is* the change is always spawned, whatever the size (a cache-only change
spawns `cache-specialist`, via `/cache-design`).
- **`individual`** (default): `data-lead` (design and review) + `migration-specialist`
  (rollout of any schema/data change) + the store specialist(s) of the stores
  touched (`postgres-specialist`, `mongo-specialist`) + the backend lead for the
  ripple. Cache and messaging concerns that are *incidental* are consulted
  through `data-lead` with an informational note.
- **`small`**: + `cache-specialist` and `messaging-specialist` when their trigger
  fires, + `multitenancy-specialist` for tenant-owned tables, + `test-automation-engineer`
  (integration and migration tests).
- **`studio`**: + `privacy-compliance-specialist` (retention, DSAR),
  `performance-engineer` (query plans, load), `infra-engineer` (backups, bundle),
  `security-lead` review, the persistence specialist the backend lead names
  (`kotlin-persistence-specialist`, `go-concurrency-specialist`), and an
  adversarial review pass: Phase 7's reviewers are told "your job is not to
  confirm this model is sound — find where it loses or leaks data", and the
  report says the pass ran.
A non-core agent needed at a smaller size routes through the nearest active core
agent with an informational note.

**Announce the active set before Phase 1:**

> `Active set (team.size: <resolved>): <agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

The collapse is correct (`team.size` is the token lever). Naming it is what keeps
a correctly collapsed run distinguishable from a broken pipeline.

## Team Composition

- **data-lead** — store choice per context, data model review, retention and deletion, backups, cross-store consistency; reconciles specialist output
- **postgres-specialist** — schema, constraints, indexes, query plans, RLS, partitioning; **mongo-specialist** — document model, validators, indexes, tenant filters
- **migration-specialist** — expand→migrate→contract, lock-safe DDL, resumable backfills, multi-version upgrade paths, rollback
- **cache-specialist** — cache decisions, keys, TTL, invalidation, stampede, engine portability; **messaging-specialist** — outbox, delivery semantics, idempotent consumers, DLQ, event schema versioning
- **backend lead** (`go-lead` / `ktor-lead`) — persistence adapters and the ripple; **multitenancy-specialist**, **test-automation-engineer**, and the studio-size reviewers above

## How to Delegate

Use the `Agent` tool for agents and the `Skill` tool for `/cache-design`,
`/tenant-check`, `/api-contract`, `/architecture-decision`, `/create-stories`.
Independent agents are spawned **in parallel** — issue every independent `Agent`
call before waiting for any result (`.claude/docs/coordination-rules.md`).

**Brief each agent — do not dump context.** Read the shared inputs **once** and
pass a distilled brief inline; pass a path only for a document you have not read
and only that agent needs. Every data agent also reads `docs/stack-reference/<store>/`
(all four files) and `docs/stack-reference/pins.yaml` itself; **anything those
files do not cover is `NOT SOURCEABLE` and routed to `/research`** — for example
the MongoDB backup and restore method (`data-lead.md`).

**End every agent prompt with a return contract:** "Write your full output to
`[path]` — that named path is your write authorisation under the bounded
exception below, so write it without a separate approval prompt. Return **only**
(1) the path written, (2) a ≤5-bullet summary of decisions, (3) any
BLOCKED/CONCERNS items, one line each. Do not restate the documents you read."
**Implementation files are the exception:** the backend lead returns the files it
will create or change first; it writes them only after you asked once for the set
and the user said yes.

**Substitute a real path.** Artifacts go under `production/data/<slug>/`, one
file per agent:

| Phase / agent | Writes to |
|---|---|
| 2 data-lead | `data-lead-review.md` |
| 3 each specialist | `<agent>.md` (e.g. `postgres-specialist.md`, `migration-specialist.md`); cache via `/cache-design` at its own path |
| 4 data-lead (consolidation) | `data-change-brief.md` |
| 6 backend lead | `impl-ripple.md`; the code roots for code (outside the exception) |
| 7 reviewers, test-automation-engineer | `review-<agent>.md`, `data-tests.md` |
| 8 close | `team-data-report.md` |

The migration plan and files are written by `/db-migration` at its own paths
(`docs/architecture/migration-plans/<slug>.md`, the project's migration layout).

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an
> agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent
> spawned here writes **without** asking, a deliberate, bounded exception that
> holds only when (1) the path is one **you** named in the prompt, (2) it is a new
> artifact under `production/`, `docs/` or a test directory, never an edit to
> existing source or config, and (3) the phase is gated by an `AskUserQuestion`
> before the pipeline advances. Migration files and schema are not covered: they
> go through `/db-migration`. Outside those three the agent must ask. **Do not
> "fix" this by asking per subagent.**

## Pipeline

Each phase names a reference to read when you reach it; read it again if the
conversation was compacted. Report each phase in one line as you leave it:
`Phase n — <name>: ran | skipped — <named reason> | BLOCKED — <what>`.

### Phase 1: Intake and Classification

**Read `references/1-intake-and-design.md` sections 1–2 now and follow them.**
Slug, inventory (FOUND/ABSENT), the change classified against the expand/contract
taxonomy, stores and triggers fired (each with its evidence or the named reason it
did not fire).

### Phase 2: Data-Lead Review (read patterns first)

**Read `references/1-intake-and-design.md` section 3 now and follow it.**
`data-lead` writes the review; no design is accepted before the read patterns are
written down.

### Phase 3: Specialist Designs (parallel)

**Read `references/1-intake-and-design.md` section 4 now and follow it.**

### Phase 4: The Data Change Brief

**Read `references/1-intake-and-design.md` section 5 now and follow it.** Gate:
design approved; ADR for a critical decision; destructive steps listed for their
own approvals.

### Phase 5: Migration (user-run `/db-migration`)

**Read `references/2-migration-and-ripple.md` sections 1–2 now and follow them.**
Prints the command, pauses, and on `resume` verifies the artifacts on disk.

### Phase 6: Stories and the Ripple

**Read `references/2-migration-and-ripple.md` sections 3–4 now and follow them.**
Stories (gate), then the backend lead's persistence, outbox, cache and tenancy
changes.

### Phase 7: Verification

**Read `references/3-verify-and-close.md` sections 1–2 now and follow them.**

### Phase 8: Report

**Read `references/3-verify-and-close.md` section 3 now and follow it.**

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the path
exists before treating the phase as done — **a named artifact that is not on disk
is a failed phase, however fluent the response reads.** Resume the agent naming
the unmet contract. The same applies to what `/db-migration` and `/cache-design`
should have produced.

If any spawned agent or skill returns BLOCKED, errors, or cannot complete:
**surface it immediately, don't proceed past a dependency it blocks, and always
produce a partial report.** A skipped agent's section stays a named gap — never
fill it with content of your own; **a skip does not clear a block.** Full
procedure: `.claude/docs/error-recovery-protocol.md`.

Common blockers:
- `stack.data` / `tenancy` unset → `/setup-stack`; a store not in `stack.data` → ADR via `cto`
- Read patterns not written → no design is accepted
- A tenant-owned table without `tenant_id NOT NULL`, a leading-`tenant_id` index and the isolation backing for `tenancy.model` → the model is not accepted
- A dual write (database then broker/Mongo/cache with no outbox or reconciliation) → rejected by `data-lead`
- Table size unknown for a change that could lock a hot table → asked; unknown is treated as hot
- `/db-migration` not yet run → the ripple and verification wait; the run is `NOT ASSESSED` until it is
- `migration-lint.sh` DANGER/WARN/MISSING unresolved → the migration is not accepted
- An API or event contract changes → `/api-contract` (or `/team-api`) first

## File Write Protocol

Writes are delegated to sub-skills (they ask per the Collaboration Protocol) and
sub-agents (named `production/data/<slug>/` paths under the bounded exception;
implementation files returned as a set, asked once, written after a yes). The
orchestrator writes only the checkpoint in `production/session-state/active.md`
(exempt from the prompt) and nothing else without asking.

## Output

A summary report (`production/data/<slug>/team-data-report.md`, after approval):
classification; stores and triggers; the decisions taken (store, tenancy,
retention, consistency) and the ADRs; the step table (release, change, why safe
alone, rollback); migration artifacts and the lint output; ripple files; the test
matrix with every cell `passed` / `FAILED` / `not run — reason`; query plans or
`not run`; backup/restore impact; evidence paths; gates run or skipped by mode;
**Not run / not checked** (always present).

Verdict: **COMPLETE** — design approved, migration artifacts on disk and linted,
ripple implemented, every verification cell run and passed, evidence retained.
Verdict: **COMPLETE WITH GAPS** — named gaps with owners (a deferred contract step
scheduled for a later release, a CONCERNS from a review, a restore drill owed).
Verdict: **NOT ASSESSED** — `/db-migration` not yet run, tests or query plans not
run, table size unknown, a sourced method missing (`NOT SOURCEABLE`); name each.
Verdict: **BLOCKED — write declined by user** — the user declined the report or the
ripple file set; nothing is reported as COMPLETE.
Verdict: **BLOCKED** — a tenant-isolation test failing or absent for a
tenant-owned table, an unresolved lint DANGER, a failing migration test, a
cross-context table access, a dual write, or a destructive step with no approval
and backup step.
Precedence: BLOCKED, NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE.

## Collaborative Protocol

- **The user decides at every gate**; silence or an agent's report is never
  approval. A skipped or dismissed question is not an answer — re-ask in plain text.
- **Read patterns before design; expand before contract; every step safe alone.**
- **Nothing is applied from here**: no migration, no backfill on real data, no
  deletion, no connection string or credential in any command, file or transcript;
  the environment reference the repo defines is used.
- **No commits, pushes or deploys** without an explicit instruction.
- **A check that did not run is reported as `not run`**, never as passed.

## Next Steps

`/db-migration <slug>` (Phase 5, user-run) then `/team-data resume <slug>`;
`/code-review` per lane and `/story-done <story>` (user-run); `/tenant-check` for
any tenant-owned table not covered; `/load-test` for a budgeted hot path;
`/release-checklist` for the backup step and the migration order; `/team-qa`.
