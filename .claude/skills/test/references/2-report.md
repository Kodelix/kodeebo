# /test — Phase 4: Report, Verdict and Evidence

> Part of `/test`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its headings still apply here.

## Report format

```markdown
## Test Run: [scope] — [date]
**Build / commit**: [git rev-parse --short HEAD] · **Diff base**: [ref | working tree] · **Changed files**: [N]
**Environment**: [host OS; stack up via compose.dev.yaml: yes/no; seeded tenant]

### Results
| Layer | Suite | Command (source) | Result | Passed / Failed / Skipped | Time |
|---|---|---|---|---|---|
| backend (Go) | unit | `...` (Makefile) | PASS | 412 / 0 / 0 | 18 s |
| backend (Go) | race | `...` | PASS | ... | |
| backend (Go) | integration | `...` | NOT RUN — container runtime unavailable | — | — |
| web | typecheck | `pnpm run ...` | PASS | n/a | |
| web | Playwright | | FAIL | 14 / 2 / 0 | |
| ios | all | — | NOT RUN — iOS suites require a macOS runner | — | — |

### Failures
[each failing test: layer, name, file:line if reported, the tool's message
(trimmed, secrets redacted), whether it also failed on re-run (N stated)]

### Not run
[every NOT RUN row again, with the reason and what closes it]

### Changed code without tests
[files/packages changed with no test file in the package; or "none found"]

### Skipped / quarantined tests touching the scope
[name, issue/owner if recorded, else "no owner recorded"]

### Coverage
[measured values from the product's own tooling, or "not measured"]

### Verdict: PASS / PASS WITH CONCERNS / NOT ASSESSED / FAIL
```

## Verdict rules — first matching rule wins

1. **FAIL** — any executed suite failed, **or** a suite that exists executed zero
   tests (a broken filter or an empty run). Name each. A failing authz or
   cross-tenant test is called out as a security failure first.
2. **NOT ASSESSED** — nothing failed, but at least one layer in scope has a
   `NOT RUN` row or no suite at all (toolchain, runtime, device, host OS,
   unconfirmed command, dependencies not installed, code roots unresolved, a
   changed contract with no contract test). List each cause and what closes it.
   A layer that is out of scope **by a stated reason** (no files changed there)
   is not a cause.
3. **PASS WITH CONCERNS** — every in-scope suite ran and passed, but skipped or
   quarantined tests touch the scope, coverage was measured and dropped (cite
   the numbers), or a flake was characterised (cite N and the rate).
4. **PASS** — every in-scope suite ran and passed, with the evidence on disk.

`testing.strict.*` (resolved above; unset = the defaults in `coding-standards.md`)
decides whether a failure *blocks a story*; this skill reports the verdict and
the strictness in force, it does not close or fail a story.

## Evidence written (after the Phase 2 approval; `[date]` comes from `date +%F`)

- `production/qa/evidence/[id]/checks-[layer].md` — per layer: commands, exit
  codes, counts, failing tests, `NOT RUN` rows. `/story-done` reads these.
- `production/qa/evidence/[id]/raw/[layer]-[suite].log` — the tool's output, with
  secrets, tokens and personal data redacted before saving.
- `production/qa/evidence/[id]/test-run.md` — the report above.

If the user declined the write: a `FAIL` or `NOT ASSESSED` stands as computed
(it needs no file to be true) and the report says the evidence was not
retained; a would-be `PASS` or `PASS WITH CONCERNS` closes as
`BLOCKED — write declined by user`, because a pass with no retained evidence is
an assertion in conversation, not evidence. Nothing is reported as recorded.

## Session state

After the run, update the checkpoint in `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md` (Current task `/test <scope> — <verdict>`,
Next step = the first Hand Off action for that verdict, plus Blocked on / Files in
progress / Open questions; append the Notes line; still updated for FAIL, NOT
ASSESSED and a declined write), and silently append (an `Edit` append; create the
file with `Write` if absent):

```
<!-- TEST RUN: [date] | Scope: [scope] | Verdict: [PASS|PASS WITH CONCERNS|NOT ASSESSED|FAIL] | Report: production/qa/evidence/[id]/test-run.md -->
```
