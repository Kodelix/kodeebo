# /prototype — Phase 5: Implement

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 5: Implement

Ask: "May I create the prototype directory at `prototypes/[name]/` and begin
implementation?" (`prototypes/<name>/` is the layout `.claude/rules/prototype-code.md`
requires; the report and index live there too.)

If the user declines, create nothing and stop with
`NOT ASSESSED — prototype directory declined by user` (a prototype nobody built has no verdict).

If yes, create the directory and write **`prototypes/[name]/README.md` first** — the
rules require it: the hypothesis being tested, how to run it, status
(`in-progress`), findings (filled when it concludes), the shortcuts taken and the
safety notes (sandbox credentials via environment variables, local bind only).

Every code file must begin with:

```
[comment] PROTOTYPE - NOT FOR PRODUCTION
[comment] Question: [Core question being tested]
[comment] Date: [Current date]
```

Write `[comment]` in each file's own comment syntax — `//` in Go, Kotlin, Swift and
JavaScript/TypeScript, `#` in Python and shell, `--` in SQL, `<!-- … -->` in HTML
and Markdown. A header in another language's syntax is a parse error, not a label.
Files that cannot hold a comment (JSON, lockfiles, generated files) are exempt.

Standards are intentionally relaxed (`.claude/rules/prototype-code.md`):

- Hardcode values freely; singletons and global state are fine
- Use placeholder data and copy
- Skip error handling and tests
- Use the simplest approach that works; copy rather than import
- No architecture, no patterns, no abstractions

**What stays strict:** no real secrets or customer data in the repository; no
network exposure beyond `127.0.0.1`; no file edits outside `prototypes/[name]/`;
no imports from or into production code; nothing deployed. A dependency added to a
spike is installed inside the prototype directory only — never into a production
`go.mod`, `package.json` or Gradle catalog.

**Do not add polish.** No menus, no settings, no onboarding unless it IS the
thing being tested.

### Code spike: multi-turn loop

After writing the initial code:

> "The spike is written. Run it now (`README.md` has the command). If there are
> errors, paste them here and I'll fix them. If it runs, paste the numbers or
> describe what you see and whether it answers the question."

Iterate until the spike runs and produces its measurement. Each loop: user runs →
reports errors or output; agent fixes; repeat until it answers the question or the
sunk-cost rule triggers. **Record the real output** in the README findings — a
spike result nobody can reproduce is an anecdote. A measurement is reported with
its conditions (data volume, hardware, warm/cold, tool and command).

### Click-through mock: single output

Write `prototypes/[name]/prototype.html` with all styles, logic and sample data
inline; openable by double-clicking with no server.

### Concierge / manual: playbook + log

Write `prototypes/[name]/playbook.md` (the manual steps, tools, time budget) and an
empty `prototypes/[name]/log.md` the team fills per delivery: user (role, not
name), date, time spent, outcome, reaction, what broke. No participant's personal
data is committed.

### Paper: document + walkthrough

Write `prototypes/[name]/rules.md` and `prototypes/[name]/walkthrough.md`: one
complete scenario traced step by step, plus the wrong-role, other-tenant and
over-quota/edge cases.

**Wizard of Oz:** to test a behaviour before building it (recommendations,
matching, automation), one person acts as the "system" by hand behind a simple
front. Note in the report that the behaviour was simulated.

---
