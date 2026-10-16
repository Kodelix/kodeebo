---
name: db-migration
description: "Database migration with expand-migrate-contract: plan, migration files, migration-lint, resumable backfill, lock_timeout, rollback and the self-hosted multi-version upgrade path. Postgres and Mongo. The apply step is always collaborative."
argument-hint: "[feature-slug | change description] [--review full|lean|solo]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash(bash .claude/scripts/migration-lint.sh), Bash(bash .claude/scripts/migration-lint.sh *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(date *), Bash(git status), Bash(git status *), Bash(git diff *), Bash(git log *), Bash(git show *), Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/db-migration/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,automation_always_ask,testing.strict,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Planning and file-writing decisions
follow `.claude/docs/automation-modes.md`. **The apply step (Phase 6) and any
destructive statement are exempt: they always ask, in every mode**, like the
other always-collaborative skills. This skill is `disable-model-invocation`: it
runs only when the user types it.

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**`workflow`** does **not** relax this skill. Migrations are engineering:
expand-migrate-contract, lock safety, the lint and the test matrix apply at
every tier (`workflow-modes.md`).

# DB Migration

A schema or data change is deployed to running software and to customers who
upgrade across several versions. This skill plans it so **every step is safe on
its own** (`.claude/rules/migrations.md`): expand → migrate → contract across
releases, migration files that cannot take a hot table down, a backfill that is
batched, idempotent and resumable, a rollback story that is honest about
production being forward-only, and the upgrade path for self-hosted installs.

**Output:** a migration plan at `docs/architecture/migration-plans/<feature>.md`,
the migration file(s) in the layout the project's tool uses, the real output of
`bash .claude/scripts/migration-lint.sh`, the test-matrix evidence, and, only
with explicit approval, an apply against a **non-production** database.

**It never applies to production.** Production migrations run as the one-shot
job of the release pipeline before the new app version starts
(`.claude/rules/deploy.md`); this skill's apply step targets a local or
test database the user names.

> **Verdicts:** `COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`.
> Precedence: `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH GAPS`, then
> `COMPLETE`. `BLOCKED`: an unapproved destructive statement, a hot-table
> operation with no `lock_timeout`/online form, a contract step in the same
> release as its expand, a tenant-owned table without isolation, or no rollback
> story. `NOT ASSESSED`: the lint or the test matrix did not run, the table size
> is unknown (treated as hot until answered), the migration tool is undecided,
> the supported upgrade-from range is unknown, or a store has no linter (Mongo).
> **`migration-lint.sh` emits observations, not a verdict, and covers `.sql`
> files only**; a clean lint is not a clean migration. Each cause is named.

---

## Phase 1: Inputs and Classification

**Read `references/1-inputs-and-classification.md` now and follow it.** It parses
the argument, derives the data stores from `stack.data`, finds the migration
tool/layout (ADR or existing files), the existing migrations, the supported
upgrade-from versions and the table sizes, classifies the change against the
expand/contract taxonomy, and records every input as FOUND or ABSENT. An
unknown input is asked, never assumed. Read it again if the conversation was
compacted or resumed.

## Phase 2: Plan (migration-specialist)

**Read `references/2-plan.md` now.** Spawn `migration-specialist` via `Agent`
with the fixed brief in that file: the step table (release, database change,
code change, why safe alone, rollback), lock-safe SQL forms from the stack
reference, the backfill design, the skipped-release hazard and the self-hosted
upgrade path. It returns text; it writes no file yet. If it cannot be spawned,
say why, plan here against the same reference, and let the plan's **Planned
by** line say so.

## Phase 3: Review by the Store Specialists

Spawn **in parallel, in one message**, for the stores in `stack.data` that the
change touches: `postgres-specialist` (schema, indexes, lock behaviour, RLS,
roles, query plans), `mongo-specialist` (validators, `_v` lazy migration,
indexes), and `multitenancy-specialist` when a tenant-owned table or collection
is added or when `tenancy.model` is not `shared-schema-rls`. Brief:
`references/2-plan.md` "Review brief". In `full` review mode also spawn
`data-lead` to review the consolidated plan as its owner (this is an agent
review, not a director gate; `lean` and `solo` record `data-lead review skipped -
[mode] mode`). You review the returned findings; do not relay them unread.

## Phase 4: Decisions and Plan File

Present the consolidated plan and the findings. Decisions are the user's:
which option for the skipped-release hazard, hot-table approach if size is
unknown or large, which release carries the contract step, whether a
destructive step is approved at all. Then ask: "May I write the migration plan
to `docs/architecture/migration-plans/<feature>.md`?" Write only after approval.

## Phase 5: Migration Files, Lint, Tests

**Read `references/3-files-lint-and-tests.md` now and follow it.** It has
`migration-specialist` write the approved `.sql` (and Mongo script) files at the
approved paths, runs `bash .claude/scripts/migration-lint.sh` on each and
reports its real output line by line, resolves every DANGER/WARN/MISSING
explicitly (fixed, or approved by the user with the reason recorded), and runs
the test matrix from `testing-standards.md` using the commands the repository
defines.

## Phase 6: Apply (always collaborative)

**Read `references/4-apply-and-record.md` now and follow it.** Applying a
migration is a separate, explicit request every time: the exact target
(environment, database name, no credentials), the exact command the repo
defines, the effect, and the rollback, are shown, and the user says yes to
that run. Production is refused. Destructive steps need their own approval and a
backup step in the release checklist. The record and the report are written
last.

---

## Error Recovery Protocol

**First, verify the artifact.** If a spawned agent was told to write a path,
check the file exists and matches the approved plan; a reply without the file is
a failed phase. If any agent returns BLOCKED, errors or cannot complete: surface
it immediately, do not proceed past a dependency it blocks, offer skip / retry
narrower / stop via `AskUserQuestion`, and always produce a partial report. A
skip does not clear a block. Full procedure:
`.claude/docs/error-recovery-protocol.md`.

## Collaborative Protocol

- **Decision records follow the tier.** "An ADR" in this skill means an ADR (at
  `modes.workflow: minimal`, an entry in the brief's decision log, `design/product-brief.md`).
- **Question -> Options -> Decision -> Draft -> Approval.** The release carrying
  the contract step, destructive statements and every apply are the user's.
- **Apply is never implicit.** Writing a file is not applying it; the PostToolUse
  migration hook prints advisory lint observations only. No command that
  executes SQL runs without the per-run approval in Phase 6, in any mode.
- **Never run against production**, never print a connection string or
  credential, never put a credential in a command line: use the environment
  reference the repo defines.
- **Destructive statements** (`DROP`, `TRUNCATE`, `DELETE`) need explicit
  approval, are always the contract phase, and carry a backup step in the
  release checklist (`rules/migrations.md`).
- **Never write an engine feature, flag, setting or version-dependent syntax from
  memory.** Use `docs/stack-reference/postgres/` and `mongo/`; anything absent
  is `NOT SOURCEABLE` and goes to `/research`. Check version-qualified features
  against **both** the hosted pin and the self-hosted bundle pin
  (`docs/stack-reference/pins.yaml`).
- **A check that did not run is reported as `not run`, never as passed.** An
  empty lint output on a file the script did not scan is `not scanned`.
- **No hardcoded tunables:** batch size, throttle and timeouts in backfill code
  come from configuration with typed defaults (`coding-standards.md`).
- A skipped, dismissed or empty answer is not an answer: act on nothing, ask
  again in plain text and wait.

---

## Recommended Next Steps

- Plan and files approved: `/create-stories` (a Config/Integration story per step; the backfill job is a story for the stack lead) or `/story-readiness [story]`; link the plan in the story
- Backfill code, dual-write and the read switch: `/dev-story [story]` via `principal-engineer` to `data-lead` and the stack lead
- Add the backup step, the migration order and the self-hosted upgrade note to the release: `/release-checklist`
- New tenant-owned tables: `/tenant-check [feature]`; schema touching PII: `/threat-model [feature]`
- New repository queries on the new shape: `/cache-design [feature]` if cached; `/perf-profile` for the affected hot paths
- Tooling or an engine feature `NOT SOURCEABLE`: `/research`; a data-store or tenancy decision: `/architecture-decision`
