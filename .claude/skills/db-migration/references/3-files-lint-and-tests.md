# /db-migration - Phase 5: Files, Lint, Tests

> Phase 5 of `SKILL.md`. A check that did not run is `not run - reason`, never
> passed.

## 1. Write the files

After the plan is approved, name every path in one question: "May I write these
migration files: [paths]?" (the new files, in the project's layout and
sequence). Then resume `migration-specialist` with the approved paths named; it
writes exactly those and returns the list. Verify each exists. If the layout is
the tool's (goose, golang-migrate/dbmate, Flyway styles are the ones
`migration-lint.sh` recognises), use the convention the project already follows;
never introduce a second layout. The PostToolUse hook `validate-migration.sh`
may print lint observations when a file is written; they are advisory and do
**not** replace step 2.

Mongo changes are scripts or code in the project's convention (`.claude/rules/mongo-data.md`:
indexes declared in code/migrations); name the path and the runner the repo
defines. If none exists: `no Mongo migration runner defined`, the Mongo step is
`NOT ASSESSED`, routed to `/research` and `/architecture-decision`.

## 2. Run the lint and report every line

```text
bash .claude/scripts/migration-lint.sh <file>...
```

Pass all `.sql` files written in this change. Paste the output as is. The script
prints `DANGER`, `WARN` and `MISSING` lines and exits 0 whatever it finds, so
the exit code says nothing: **read the lines.** Empty output means "no observation
on the `.sql` files given" - it does not cover Mongo scripts, application code,
backfill jobs or anything the script cannot parse. Say which files it scanned
and which it did not.

Resolve every line, one row each:

| Level | Meaning (script header) | Resolution |
|---|---|---|
| DANGER | data loss or long table lock is likely (drops, `TRUNCATE`, `DELETE` without `WHERE`) | Only valid in the contract phase of an expand/contract plan; needs the user's **explicit approval** (`AskUserQuestion` naming the statement and table) and a backup step in the release checklist. Not approved = remove it; `BLOCKED` meanwhile |
| WARN | needs a deliberate decision (index without `CONCURRENTLY`, `ALTER COLUMN TYPE`, `NOT NULL` without default, foreign key without `NOT VALID`, `RENAME`, missing `tenant_id`/RLS, `SERIAL`, floating money, no `lock_timeout`) | Fix the file, or record a one-line reason the user approves. A WARN left unresolved is a gap |
| MISSING | a required companion is absent (down migration) | Add it |

After fixes, re-run and show the new output. The plan's section 10 records the
final output and each approved exception with its reason.

The script's rules are text pattern matches. It cannot know a table is large, a
function is volatile or that a column is read by the running version: the
plan's reasoning covers those, and the report says the lint did not.

## 3. Test matrix

`.claude/docs/testing-standards.md` "Required tests by change - Every
migration": **up on an empty database, up on a seeded database, down
(development), and the application's integration suite green afterwards.** Add
for this skill:

| Test | Purpose |
|---|---|
| Up on empty | the chain applies from nothing |
| Up on seeded | existing data survives; backfill predicate selects the right rows |
| Down (dev) | reversible in development |
| Up from the previous release's schema | the normal upgrade |
| Up from the oldest supported upgrade-from version | the self-hosted path, including the skipped-release hazard (the chosen option A/B/C is exercised, and the guard fires on an incomplete migrate phase) |
| Backfill: kill mid-run and restart | idempotent and resumable |
| Backfill batch under load | no long locks, tunables read from config |
| RLS (tenant tables) | connect as the non-owner, no-bypass application role; tenant A cannot read or write B; unset tenant returns zero rows (`docs/stack-reference/postgres/best-practices.md` section 7). A test run as a superuser passes vacuously |
| Integration suite after | the app works on the new schema |

Real dependencies via Testcontainers, never a mocked database. The commands are the
ones the repository defines for each layer (the `/test` skill finds them). This skill
holds no test-runner grants: `test-automation-engineer` (spawned via `Agent`) runs them
and returns exit code and output, or the user runs them and pastes the result. Record
command, exit code and trimmed output in
`production/qa/evidence/<STORY-ID>/migration-<NNNN>.md` after asking. A matrix
row with no runnable command is `not run - <reason>` and a gap; the verdict is
`NOT ASSESSED` while any required row did not run.

## 4. Handoff of code that is not a migration

The dual-write, the read switch, the backfill job and the guard's runner step
are application code. List them as stories for the stack lead (via
`principal-engineer`, `data-lead`); this skill writes none of them.
