# /smoke-check — Phase 6: Write and Gate

> Part of `/smoke-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 6: Write and Gate

**In this file:**

- `qa.level` first
- Resolve the gate enforcement level
- Per verdict: FAIL (blocking or advisory), NOT ASSESSED, PASS WITH WARNINGS, PASS

Present the full report in conversation, then ask:

"May I write this smoke check report to `production/qa/smoke-[date].md`, and the
Part A transcripts and any stack logs to `production/qa/evidence/smoke-[date]/`?"

**If the user declines the write:** end with `BLOCKED — write declined by user`.
The report stays in conversation only; do not announce any verdict as recorded,
and do not hand the build to QA on an unrecorded result. A FAIL or NOT ASSESSED
found in the report still stands and is repeated in that closing message. Update
the checkpoint (below) with that blocker, then stop.

Write only after approval. Evidence files must be on disk before the report
cites them: a transcript captured and discarded is an assertion, not evidence.
Redact tokens, OTP codes, passwords and personal data before saving.

**First apply `qa.level` (resolved earlier).** At `qa.level: minimal`, a FAIL is
**advisory** regardless of `testing.strict.config` — skip the resolution below and
deliver the advisory-FAIL outcome (smoke-check is optional at minimal and never
blocks hand-off). Otherwise:

**Resolve the gate enforcement level.** A FAIL verdict either *blocks* QA
hand-off or is *flagged while hand-off proceeds*, governed by the
`testing.strict` line **in the resolved-config block at the top of this skill**
(which merges `project.local.yaml` over `project.yaml` — read that block, not the
file, or a developer's local override is silently ignored):

1. Take `config=` from that `testing.strict` line. If its value is `true`
   (case-insensitive) → blocking; if `false` → advisory; `unset` → fall through.
2. Else read `testing.strict` as a plain boolean (legacy single-value form) — if
   its value is `true` or `false`, it applies.
3. Else default to **blocking** — an unset `testing.strict.config` keeps
   smoke-check's FAIL gate blocking. Smoke check is a build-health gate, so its
   unset default is strict even though the Config story type defaults to advisory
   elsewhere. The reciprocal carve-out is recorded in `.claude/docs/coding-standards.md`
   and `.claude/docs/testing-standards.md`, which own the per-story evidence table.

Only `true` and `false` (case-insensitive) are recognized at steps 1–2. A key
that is present but holds any other value — `maybe`, `1`, `yes`, etc. — is
treated as unset: continue to the next step, and surface the unrecognized value
to the user. **A failed A7 (cross-tenant exposure) is not softened by an advisory
gate**: say it is an S1 and that `qa-lead` has to be told, whatever the setting.

**Checkpoint.** After writing, update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/smoke-check <slug> —
<verdict>`, Next step = the first action of the verdict outcome below (fix the
first failure and re-run `/smoke-check`, or the QA hand-off on PASS), plus
Blocked on (a blocking FAIL, a NOT ASSESSED cause) / Files in progress (the
report and evidence paths) / Open questions; append the Notes line.

After writing, deliver the gate verdict:

**If verdict is FAIL and the gate is blocking:**

"The smoke check failed. Do not hand off to QA until these failures are
resolved:

[List each failing suite, Part A check or smoke check with a one-line description]

Fix the failures and run `/smoke-check` again to re-gate before QA hand-off."

**If verdict is FAIL and the gate is advisory** (`testing.strict.config: false`,
or `qa.level: minimal`):

"The smoke check failed, but the gate is set to advisory — QA hand-off is not
blocked. Resolve these before release:

[List each failing suite, Part A check or smoke check with a one-line description]

QA hand-off: share the QA plan found in Phase 1 (`production/qa/plan-[slug]-[date].md`) with the `qa-tester` agent to
begin verification against the running stack. Re-run `/smoke-check` once the
failures are fixed."

**If verdict is NOT ASSESSED:**

"The smoke check could not establish build health — it did not fail, it did not
run. Do not hand off to QA on this result:

[Name each check that could not execute, and why: suite unconfirmed NOT RUN,
Android instrumented / iOS `NOT RUN`, zero tests executed, Testcontainers not
exercised, Docker unavailable, no compose file, command not sourced, no seeded
tenant, tenant-isolation check not run, build not opened this session, surface
unavailable]

[For each, the one thing that would make it runnable — e.g. 'confirm the suite
result from your IDE or CI', 'start Docker', 'run `/test-setup` for the missing
layer', 'run `/research` for the Gradle test command', 'add a seeded test tenant
to `tools/seed/`', 'attach an emulator', 'run the iOS suites on a macOS runner'.]

Re-run `/smoke-check` once any of those is resolved."

This outcome is **not governed by `testing.strict.config`**. That setting decides
whether a *failure* blocks hand-off; it has nothing to say about a check that
never produced a result, and reading an unrun check as advisory-therefore-fine is
the exact substitution this verdict exists to prevent. Say what could not be
checked and let the user decide — do not resolve it to either pass or FAIL on
their behalf.

**If verdict is PASS WITH WARNINGS:**

"Smoke check passed with warnings. The build is ready for QA.

Advisory items to resolve before running `/story-done` on affected stories:
[list MISSING test evidence entries, skipped or quarantined tests, and any other
warning]

QA hand-off: share the QA plan found in Phase 1 (`production/qa/plan-[slug]-[date].md`) with the `qa-tester` agent to
begin verification against the running stack."

**If verdict is PASS:**

"Smoke check passed cleanly. The build is ready for QA.

QA hand-off: share the QA plan found in Phase 1 (`production/qa/plan-[slug]-[date].md`) with the `qa-tester` agent to
begin verification against the running stack."

---
