# /automate-test — Phase 4: Prove the Tests and Record the Mapping

> Part of `/automate-test`. `SKILL.md` names when to read this file; the
> settings it resolved and the rules under its headings still apply here.

A test that was written is not a test that works. For every new test establish
**three facts from real output**, in this order.

## 1. It passes on the current build

Run it with the layer's confirmed command (the same sources `/test` uses: the
product's scripts, then the stack reference, then the tool's own help — never a
flag from memory; the per-layer command table of the `/test` skill lists them). Bring
the stack up for integration and e2e as `run-and-observe.md` says (`up --wait`,
seeded tenant; never `down -v`).

- Capture command, exit code, counts and the test's own name in the output.
  **Zero tests executed is a failed run** — a wrong filter or a tag the build
  does not pick up shows as a green exit with nothing run.
- A new test that **fails** on the current build while the spec says the
  behaviour should hold is a **product defect**: stop that row, file
  `/bug-report`, verdict `BLOCKED`. Do not change the assertion to match the
  code, and do not skip the test.
- Cannot run (toolchain missing, container runtime down, iOS on Linux) →
  `WRITTEN, NOT RUN — [reason]`; the row does not count as automated.

## 2. It can fail

- **Regression test for a bug:** run it on the **unfixed commit** — the current
  build if the fix is not merged, otherwise a scratch worktree at the pre-fix
  commit (`git worktree add --detach <dir from mktemp -d> <commit>`, then
  `git worktree remove <dir>` after; the working tree is never touched; run the
  test there with `go -C <dir>/backend test …` and the layer's equivalent).
  Save the red output. If the fix is in the current build, this pre-fix run is
  the red proof and the current-build run is the green.
- **Conversion of a manual case (no unfixed commit):** do a **one-mutation
  check** in a scratch worktree — break the single behaviour the test guards
  (invert the authz check, drop the tenant filter, change the boundary), confirm
  the test fails with a message naming the condition, restore. **One mutation
  per tool invocation**: a batch that times out leaves a broken file, and cleanup
  hooks do not survive a terminated process. The mutation is **restored by an
  `Edit` back to the original text before the worktree is removed** (a plain
  `git worktree remove` refuses a dirty tree, and `--force` is not granted, so an
  unrestored mutation is caught rather than discarded), and the working tree is
  verified clean with `git status`. This is also the method `/bug-report verify`
  uses for its unfixed-commit proof.
- A test that stays green under its mutation is rewritten or dropped; report it.

## 3. It is stable

Repeat the changed tests N times and state N and the pass count. Go: the
flake-detection form for changed tests is `timeout 900 go -C backend test -race -shuffle=on -count=N`
(`test-automation-engineer.md`; confirm each flag with `go help testflag` on this
host); other layers: N repeated runs of the same command. N is the user's call —
ask if not given (a small N for unit tests, a smaller N with a stated
reason for e2e). Any inconsistent result is a flake: **do not retry into green** —
fix the test (usually a sleep, a shared row or a real clock) or report it for
`/test-flakiness`; never quarantine without an issue and owner.

## 4. The mapping record

`production/qa/evidence/[ID]/automation.md`:

```markdown
# Automation: [story/bug ID] — [date]
**Build / commit**: [hash] · **Environment**: [stack up, seeded tenant]

| Source (TC-ID / BUG-ID) | Behaviour | Level | Test (path::name) | Passes now | Can fail (how shown) | Stable (N runs) |
|---|---|---|---|---|---|---|

## Not automated
| Source | Reason | Stays as |
|---|---|---|

## WRITTEN, NOT RUN
| Test | Reason | What closes it |

## CI wiring needed (platform-lead)
[job, shard, tag — or "none"]

## Verdict: COMPLETE / COMPLETE WITH GAPS / NOT ASSESSED / BLOCKED
```

Raw output goes in `production/qa/evidence/[ID]/raw/`, with secrets, tokens and
personal data redacted before saving. In the case file add one line under each
automated case: `Automated: [path::name] — [level] — [date]`. The manual case
text is left intact.

## 5. Verdict check

Apply the order in `SKILL.md`. If every row passed, could fail and was stable
but a case was deliberately excluded (Section 4 of `1-levels-and-rules.md`), the
verdict is `COMPLETE WITH GAPS`, with the exclusions listed — not `COMPLETE`.
