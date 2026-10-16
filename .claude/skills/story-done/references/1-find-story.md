# /story-done — Phase 1: Find the Story

> Part of `/story-done`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 1: Find the Story

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Workflow tier**: resolved per the story's feature (per
`.claude/docs/workflow-modes.md`) — **the spec filename stem** of the story's
`Spec:` path (`design/specs/<stem>.md` → `<stem>`), with the `[feature]` segment of
its `TR-[feature]-NNN` ID accepted only as a fallback alias: use the
`system_overrides` row for that feature if the block lists one, else the
project value. It governs which Phase 4 deviation checks run — see Phase 4.

**Workflow companion — `modes.story_granularity`** (resolved above — supplied by
`modes.rigor` unless set explicitly): cadence expectation only — story-done fires
**every 3–5 days** at `coarse`, **every 1–2 days** at `balanced`, **multiple
times/day** at `fine`. It does not change any completion check.

**`qa.level`**: controls how much *extra* evidence is asked for on top of the
required tests, where `testing.strict` controls whether a failure blocks for the
other types, `performance.enforce` whether a missed budget blocks, and `workflow`
which docs exist. `modes.rigor` sets `qa.level` and `workflow` together; set either
explicitly to vary it alone. `testing.strict` is not fronted by `rigor` at all.
**`qa.level` never waives a test:** Logic, Integration, Contract and Security tests
must exist and pass at every tier (`coding-standards.md`), and the test-presence
checks (Phase 3), the >50%-untested traceability escalation and the Phase 4b QA gate run
at every tier. Also never waived: the retained run-and-observe evidence (API calls per
role, UI screenshots), a Security story's negative tests and ASVS/MASVS mapping,
tenant-isolation tests on tenant data, the dependency scan, and the eight-gate table
itself. At `standard`, the story's own type also requires its extra evidence (manual
cases); at `full`, every type does, plus the coverage signal.

**If a file path is provided** (e.g., `/story-done production/epics/billing/story-003-proration.md`):
read that file directly.

**If no argument is provided:**

1. Check `production/session-state/active.md` for the currently active story.
2. If not found there, read the most recent file in `production/sprints/` and
   look for stories marked IN PROGRESS.
3. If multiple in-progress stories are found, use `AskUserQuestion`:
   - "Which story are we completing?"
   - Options: list the in-progress story file names.
4. If no story can be found, ask the user to provide the path.
5. **No story to close** — the user gives no path, the path does not exist or the file
   cannot be read or parsed as a story: stop with `Verdict: BLOCKED — no readable story
   to close` (name the path tried and what the user can do: `/dev-story` first, or give a
   valid path). Nothing is written and nothing is reported as closed.

---
