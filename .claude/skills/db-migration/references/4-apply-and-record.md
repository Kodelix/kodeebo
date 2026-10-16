# /db-migration - Phase 6: Apply (always collaborative) and Record

> Phase 6 of `SKILL.md`. Applying is a separate, explicit request every time. In
> `autonomous` mode it still asks.

## 1. When apply is even on the table

Offer apply only when: the files are written, the lint is resolved, the plan is
approved, and the user wants a run against a **non-production** database. If the
user asks for production, refuse: production migrations run as the release
pipeline's one-shot job before the new app starts (`.claude/rules/deploy.md`),
after the backup step; point to `/release-checklist` and stop. If the target's
environment is not stated, ask; an unknown or ambiguous environment is treated as
production.

## 2. The approval, every run

`AskUserQuestion` with all of:

- **Target:** environment label and database name (never a connection string,
  user, password or token). The connection is taken from the environment
  reference the repo defines; nothing secret appears in the command or the
  transcript.
- **Exact command**, as the repo defines it (no flags written from memory). If the
  repo defines no apply command: `not run - no apply command defined`; route to
  `dev-tooling-engineer` and `/research`.
- **Effect:** which migration(s), expected locks (from the plan), expected
  duration, and that it is **not reversible except by the plan's rollback**.
- **Destructive steps:** each named, each with its own explicit yes, and the
  backup state ("a backup exists / does not exist"). No backup = do not apply a
  destructive step.
- **Rollback:** the exact `down` or the restore.

Options: apply / apply only steps [list] / do not apply. A skipped, dismissed or
empty answer is **not** a yes: nothing runs. Each subsequent run (another step,
another database) asks again; an approval is not carried over.

## 3. Run and observe

Run only the approved command. A migration apply is never in `allowed-tools`: the
explicit yes above is the first confirmation and the harness permission prompt for
that exact command is the second, or the exact command is printed for the user to run
and the user pastes the exit code and output (no output returned = `not run`).
Capture exit code and output. Then:

1. Verify the result in the database with the read-only queries the plan names,
   run the same way (permission-prompted or by the user; the migration is recorded, the index is valid, the constraint is validated,
   row counts match). Show the real output.
2. Have `test-automation-engineer` run the integration suite for the layer and show the real output, or `not run
   - reason`.
3. A failure stops the sequence: do not continue to the next step, do not apply
   a "fix" without a new approval. Report the state of the database exactly
   (which statements committed), and the rollback options.

## 4. Record

Ask: "May I write the migration record to
`production/qa/evidence/<STORY-ID>/migration-<NNNN>.md`?" (or
`production/qa/migration-<feature>-<date>.md` when there is no story). It holds
the plan link, lint output and its resolutions, the test matrix result, and for
an apply: target label, command, exit code, trimmed output, verification
queries and results, the date and who approved. Verify it exists before
reporting it written.

## 5. Verdict (first match wins)

| Verdict | When |
|---|---|
| `BLOCKED` | an unapproved destructive statement; a hot or unknown-size table altered without `lock_timeout` or an online form; the contract step in the same release as the expand it depends on; a tenant-owned table without isolation; no rollback story; an apply failure left unresolved; a write the user declined (`BLOCKED — write declined by user`) |
| `NOT ASSESSED` | the lint did not run; a required test-matrix row did not run; table size unknown (treated as hot until answered); migration tool undecided so no file was written; supported upgrade-from range unknown; a Mongo step with no runner or linter; an engine pin unreadable; version-qualified syntax `NOT SOURCEABLE`. Each cause is named with what closes it |
| `COMPLETE WITH GAPS` | unresolved WARNs recorded as gaps with owners; review by a specialist skipped; a non-blocking open question |
| `COMPLETE` | plan approved, files linted with every observation resolved, full matrix ran green, upgrade path covered, rollback stated |

`NOT ASSESSED` ranks above `COMPLETE` and below `BLOCKED`. The apply result is
reported separately and does not turn a plan verdict into `COMPLETE`.

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/db-migration <feature> —
<verdict>`, Next step = the first Recommended Next Step in `SKILL.md` that applies
(`/create-stories` for the steps; for `BLOCKED` / `NOT ASSESSED` the step that
clears the cause), plus Blocked on / Files in progress (plan, migration files,
record) / Open questions; append the Notes line. State whether the migration was
applied (and to which environment label) or not. Still updated when the user
declines a write or the apply.

## 6. Report

```text
Migration: <feature>   Verdict: COMPLETE | COMPLETE WITH GAPS | NOT ASSESSED | BLOCKED
Stores: <list>  Tenancy: <model | assumed>  Tool: <name | undecided>
Plan: <path>  Planned by: migration-specialist | this session (reason)
Steps: N across N releases (expand R+0, contract R+n)   Skipped-release option: A | B | C | undecided
Files: <paths>  Lint: <N DANGER / N WARN / N MISSING; files scanned; files not scanned>
Exceptions approved by the user: <list with reasons | none>
Tests: up-empty <ran|not run - reason> ... (each matrix row)
Reviews: postgres-specialist <done|skipped>, mongo-specialist <...>, multitenancy-specialist <...>, data-lead <done|skipped - mode>
Apply: APPLIED to <env label> | NOT APPLIED (declined) | not run - <reason> | refused - production
Release checklist items: <backup step, order, flags>
NOT ASSESSED / BLOCKED causes: <each, with what closes it>
```
