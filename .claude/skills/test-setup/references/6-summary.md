# /test-setup — Phase 6: Post-Setup Summary

> Part of `/test-setup`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 6: Post-Setup Summary

After writing all files, report:

```
Test infrastructure created for [stack summary].

Files created:
- production/qa/README.md, smoke-tests.md, evidence/.gitkeep, cases/.gitkeep
- [per layer: the test locations and config files created]
- .github/workflows/tests.yml  [jobs written: ...]

Skipped (already existed): [list]
Layers not touched: [layer — reason]

Pending (NOT SOURCEABLE — not created):
- [item — what is missing — file that would cover it]
  (or: "None")

Manual steps:
- [e.g. add the iOS test targets in Xcode; the Gradle integrationTest source set]
- CI stays red until each layer has its first test: a job that runs zero tests
  fails by design.

Next steps:
1. Run `/research test-infrastructure` for every Pending item, then re-run
   `/test-setup force` to create what was deferred
2. Run `/test-helpers` to scaffold factories, fakes, the injected clock and ID
   generator, and the Testcontainers fixtures per store
3. Write your first test beside the code (or in the layer's test location above)
4. Run `/qa-plan sprint` before your first sprint to classify stories and set
   test evidence requirements. At `workflow: minimal` — the default — skip
   this: there are no sprints. `/dev-story` writes the Logic, Integration,
   Contract and Security tests at every `qa.level`; `qa.level` only changes how
   much extra evidence is asked for (raise it with `/settings`)
5. `/smoke-check` before every QA hand-off

Gate note: the Pre-Production gate checks test infrastructure for each configured
layer, the CI workflow and at least one example test file. At `workflow: minimal`
it requires only the stack. Run /test-setup and write one example test before
advancing — confirm the exact list against `/gate-check`.

Verdict: **COMPLETE** — test framework scaffolded and CI/CD wired up.
         | **PARTIAL** — [what was created]; [what is pending and why]
         | **NOT ASSESSED** — [code roots unresolved (scan did not run) | coherence check SKIPPED and a layer depends on it]
         | **BLOCKED** — [stack not configured | pins.yaml missing | approval declined]
```

Use **COMPLETE** only when nothing is listed under Pending and the workflow was
written. A `PARTIAL` run that says COMPLETE hides the layers that cannot run
tests.

**Checkpoint.** Before the final message, update
`production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`:
Current task `/test-setup — <verdict>`, Next step = the first item of the Next
steps list above (`/research test-infrastructure` when anything is Pending,
else `/test-helpers`), plus Blocked on (Pending items, an unconfigured stack) /
Files in progress (the scaffolds and workflow written) / Open questions; append
the Notes line. Still updated for NOT ASSESSED, BLOCKED and a declined write.

---
