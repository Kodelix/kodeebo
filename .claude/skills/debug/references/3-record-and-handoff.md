# /debug — Record, Regression Test and Hand-off

> Part of `/debug`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its headings still apply here.

## 1. The diagnosis record

`production/qa/evidence/[ID]/diagnosis.md`, in the format `debugger.md` defines:

```markdown
## Symptom and impact: who, since when, which versions/tenants, severity proposed
## Reproduction: commit, environment, steps/script, failure rate (n of m)
## Evidence read: trace/log/metric/plan references (UTC timestamps)
## Hypotheses: | # | hypothesis | confirm by | kill by | outcome |
## Bisect: good, bad, first-bad commit — or "not applicable" with reason
## Root cause: PROVEN | LIKELY | UNKNOWN | NOT ASSESSED — falsifiable sentence + proof
## Regression test: path, level, red output on unfixed commit, green on fixed
## Siblings found, mitigation option, fix owner
## Not examined
**Diagnosed by**: debugger (agent) | this session
```

Severity is a **proposal**: S1–S4 is `qa-lead`'s call (rule table in
`/bug-report`), incident severity is `sre-lead`'s. Accepting a security risk is
`security-lead`'s and the user's.

## 2. The regression test

- **Lowest level that exhibits the bug:** unit, then integration (Testcontainers,
  never a mocked database or cache), then contract, then e2e only for a journey
  that makes money or loses data. Naming per `.claude/rules/test-standards.md`;
  determinism per `testing-standards.md` (injected `Clock`/ID generator, no
  sleeps, its own tenant and data).
- **Fails before, passes after.** Run it on the **unfixed** commit and save the
  failing output to `production/qa/evidence/[ID]/regression-red.md`. If the fix
  already exists (a bug diagnosed after the fact), `debugger` runs it in a scratch worktree
  at the pre-fix commit (`git worktree add`; the agent removes it afterwards). A test never seen failing is not a regression test.
- The debugger may write the test and minimal repro tooling at a path **you
  confirm with the user first** (new file under a test directory); it never edits
  product code. Use `/test-helpers` factories and fixtures; do not create a
  parallel helper library. Higher-level automation of the same case:
  `/automate-test [ID]`.
- A defect that needs a test at a layer the host cannot run (iOS on Linux) is
  specified, marked `not run — macOS only`, and the story keeps the gap.

## 3. Route the fix — never made here

1. Hand the diagnosis and the failing test to `principal-engineer`, who routes
   to the owning lead: `go-lead`, `ktor-lead`, `web-lead`, `android-lead`,
   `ios-lead` or `kmp-specialist`; data-layer causes also involve
   `postgres-specialist` or `cache-specialist`; sustained performance causes
   `performance-engineer`; signals and incident command `sre-lead` and
   `observability-engineer`.
2. The fix is a **story** (`/create-stories` or a quick-spec) for `/dev-story`,
   or `/hotfix [BUG-ID]` for S1/S2, `/incident` when live. It keeps the eight
   DoD gates (`coding-standards.md`): tests, observability, security evidence —
   the user approves the file set before the lead writes.
3. Specify the **mitigation separately** (rollback, flag off, scale, config) when
   S1/S2, so the proof is not on the critical path.
4. A cross-tenant or credential finding: `security-lead` owns the response; the
   record is shared by named recipients only.

## 4. Update the bug record

After the user says yes, append to `production/qa/bugs/BUG-[NNNN].md`:

```markdown
## Diagnosis
Root cause: [PROVEN|LIKELY|UNKNOWN|NOT ASSESSED] — [one falsifiable sentence]
Record: production/qa/evidence/[ID]/diagnosis.md · Regression test: [path] (red: [file])
Fix owner: [lead] · Mitigation: [option or none] · Siblings: [n found, n ticketed]
```

Do not change the bug's Status or Severity — `/bug-triage` and
`/bug-report verify|close` own those. For an incident, the same block goes into
the incident record the `/incident` skill keeps.

## 5. `--after-fix` pass

When the owning lead's fix is merged to the working branch:

1. Spawn `debugger` via `Agent` (this skill holds no test-runner grant) to run the regression test on the fixed commit and save the green output to
   `production/qa/evidence/[ID]/regression-green.md`, and to run the changed layer's
   suite (or the user runs `/test` and pastes the result; no output = `not run`) — the diagnosis stays `PROVEN` only if the symptom is gone
   **and** the suite is not newly red.
2. Re-run the minimal reproduction; record the result (n of m).
3. Siblings from the record: confirm each is fixed or ticketed.
4. Report; then `/bug-report verify [BUG-ID]`. If the symptom persists the cause
   was not the cause: reopen at the hypothesis table, do not stack a second fix.
