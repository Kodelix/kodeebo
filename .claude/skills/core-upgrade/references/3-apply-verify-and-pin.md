# /core-upgrade — Phases 5–7: Apply, Verify, Pin, Record

> Part of `/core-upgrade`. Read again if the conversation was compacted.

## 1. Apply

Spawn `principal-engineer` via `Agent` to route the approved plan to the lead(s)
in the `/dev-story` lane order (Contract → Data → Backend → Clients → Deploy),
one stop at a time when the plan has stops. Brief with the plan path and the
approved file set; instruct:

- Change only the approved files; a needed extra file is returned as a request.
- Bump the dependency with the tool the product already uses; read the tag from
  the plan. Do **not** touch `project.yaml` (Phase 6, by this skill, after
  approval).
- Tests first for changed behaviour; do not weaken, skip or delete an existing
  test to get green.
- Do not use any symbol the CHANGELOG marks deprecated unless the plan defers it.
- Return the files changed, the commands run with real output summaries, and each
  check that could not run as `not run — <reason>`; write the report to
  `production/core/upgrade-<from>-to-<to>-<date>-impl.md` (named path) and verify
  it exists before moving on.

## 2. Verify

Run by a stack lead spawned via `Agent` as a separate verification run (not the
implementer's own claim); this skill reports the real output. Commands come from the `layer-checks.md` lookup table in the `dev-story` skill
folder (`.claude/skills/dev-story/`) and from the product's own scripts; Gradle
task names and `package.json` scripts are confirmed in the build files first.
Report each as `passed` / `FAILED` / `not run — <reason>`:

| Check | Notes |
|---|---|
| Dependency resolves from a clean state at the target; lockfile changes listed | the tool's own output |
| Compile / typecheck all layers touched | errors here are evidence of scan gaps (Phase 3 §2) |
| Unit tests, then integration tests (Testcontainers), then contract tests | a missing container runtime = `not run`, which caps the verdict at `NOT ASSESSED` |
| Security negatives for sensitive modules (authz bypass, cross-tenant, injection, rate limit) | never waived by `qa.level: minimal` |
| Lint / static analysis | |
| Dependency scan of the new transitive set | `osv-scanner` / `govulncheck`; not installed → `not run`; route `/dependency-audit` |
| `bash .claude/scripts/project-coherence.sh` | real lines, observations only |
| Run-and-observe on the dev stack for anything the changed modules make callable or visible | `.claude/docs/run-and-observe.md`; evidence retained in `production/qa/evidence/core-upgrade-<to>/` |

A failure is shown with its output and **not auto-fixed**: send back to the lead,
revert, or stop. A failing check keeps the pin where it is.

## 3. Pin update (always prompts)

Reached only when the Phase 5 verification (section 2) shows the dependency resolving and no
`FAILED` row. Show:

```
core.version: <from> → <to>
core.modules: unchanged            (or: <old name> → <new name>, if the core renamed a module)
```

`AskUserQuestion`: "May I update `core.*` in `project.yaml`?" — apply · change
target first · leave the pin (the code change stays uncommitted; verdict capped
at `COMPLETE WITH GAPS`). Apply with `Edit` after a yes; no other key is touched;
re-run `bash .claude/scripts/project-coherence.sh` and show it. With intermediate
stops, repeat Phases 5–6 per stop (the plan's stops).

## 4. Record and report

Ask: "May I write the upgrade record to
`production/core/upgrade-<from>-to-<to>-<date>.md`?" Contents: from/to, releases
read, per-module summary table, the CHANGELOG-vs-diff findings (for the core's
owners), impact table, plan reference, evidence table with `not run` rows, pin
diff, deferred deprecations (symbol, product use, core removal version/date,
owner, `/tech-debt` reference), verdict.

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/core-upgrade <from> to <to>
— <verdict>`, Next step = the first Recommended Next Step that applies
(`/code-review` on the upgrade diff, or what clears a `BLOCKED` / `NOT ASSESSED`),
plus Blocked on / Files in progress (upgrade record, pin file) / Open questions;
append the Notes line. Still updated when the user declines the record or the
pin update (record what was not written and why).

Print: the verdict; evidence table; **Not run / not checked** (always present —
modules unread, scan gaps, checks not run); the next commands. Do not claim the
upgrade is safe for self-hosted customers; say which data/config steps `release-manager`
must carry into the product's upgrade notes.
