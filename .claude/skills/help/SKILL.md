---
name: help
description: "What should I do next? Use when stuck or you don't know what to do."
argument-hint: "[optional: what you just finished, e.g. 'finished spec-review' or 'stuck on ADRs']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(bash "*/.claude/skills/help/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash "*/.claude/skills/help/../../scripts/story-status.sh"), Bash(bash .claude/scripts/story-status.sh), Bash(bash .claude/scripts/story-status.sh *), Bash(bash .claude/scripts/artifact-check.sh *), Bash(bash ".claude/scripts/artifact-check.sh" *), Bash(bash ./.claude/scripts/artifact-check.sh *), Bash(git log *)
model: haiku
---

# Studio Help — What Do I Do Next?

This skill is read-only — it reports findings but writes no files.

This skill figures out exactly where you are in the product pipeline and tells
you what comes next. It is **lightweight** — not a full audit. For a full gap
analysis, use `/project-stage-detect`. For doing the work itself, `/studio
<goal>` is the main entry point once it is installed.

## Live Project State

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys project.stage,workflow`

These are resolved before this skill runs. Use them as-is:

- **`project.stage`** from the config block is the authoritative phase for Step 2
  — it already applies the `project.yaml` → `production/stage.txt` fallback, and
  preserves values containing spaces (`Product Design`, `Pre-Production`).
- **`workflow`** from the config block is the tier for Steps 2 and 5 — do not re-read it.
- If no config block rendered, shell preprocessing is disabled; fall back to the
  defaults in `.claude/docs/config-resolution.md`.

---

## Step 1: Read the Catalog

Read `.claude/docs/workflow-catalog.yaml`. This is the authoritative list of all
phases, their steps (in order), whether each step is required or optional, and
the artifact globs that indicate completion.

**If the file does not exist**, say so first — "`workflow-catalog.yaml` is not in
this checkout, so step completion is `NOT ASSESSED — catalog missing`" — and
continue with the phase determined in Step 2 and the artifact signals named there,
without per-step ✓ marks. Never present a phase as complete on the strength of a
catalog that could not be read.

---

## Step 1b: Find Skills Not in the Catalog

After reading the catalog, Glob `.claude/skills/*/SKILL.md` to get the full list
of installed skills. For each file, extract the `name:` field from its frontmatter.

Compare against the `command:` values in the catalog. Any skill whose name does
not appear as a catalog command is an **uncataloged skill** — still usable but not
part of the phase-gated workflow.

Collect these for the output in Step 7 — show them as a footer block:

```
### Also installed (not in workflow)
- `/skill-name` — [description from SKILL.md frontmatter]
- `/skill-name` — [description]
```

Only show this block if at least one uncataloged skill exists. Limit to the 10
most relevant based on the user's current phase (QA skills in Production,
hardening and release skills near the gate, etc.).

---

## Step 2: Determine Current Phase

**First, take `workflow` from the config block above.** If it is `minimal`, the
project is on the minimal path, not the phase ladder: skip the rest of this step,
read the session context (**Step 3**), then go to **Step 4m**. At that tier, do
not map `project.stage` — nothing on the minimal path runs `/gate-check`, so
the stage reads Discovery however far the project has got, and walking the
Discovery phase would send a project that already has stories back to the
product brief and domain map.

Otherwise, check in this order:

1. **Take `project.stage` from the config block above** — it is already resolved. Map its value to a catalog phase key:
   - "Discovery" → `discovery`
   - "Product Design" → `product-design`
   - "Architecture" → `architecture`
   - "Pre-Production" → `pre-production`
   - "Production" → `production`
   - "Hardening" → `hardening`
   - "Release" → `release`
   - "Live" → `live`

2. **If it is not set**, infer phase from artifacts (most-advanced match wins):
   - the code roots (`layout.code_roots`, else the conventional `backend/`, `web/`, `site/`, `mobile/`, `contracts/` that exist) hold 10+ source files in total → `production`
   - `production/epics/**/story-*.md` exists → `pre-production`
   - `docs/architecture/adr-*.md` exists → `architecture`
   - `design/specs/domain-map.md` exists → `product-design`
   - `design/product-brief.md` exists → `discovery`
   - Nothing → `discovery` (fresh project)

   If no code root resolves, the first signal did not run: say so rather than
   treating it as "fewer than 10 files".

3. **`workflow`** was taken at the top of this step (per
   `.claude/docs/workflow-modes.md`). It controls whether optional docs are
   surfaced as next steps (Step 5).

---

## Step 3: Read Session Context

Read `production/session-state/active.md` if it exists — but only its STATUS
and CHECKPOINT blocks (schema: `.claude/docs/templates/session-state.md`); the
narrative below them can be long. Find the markers
(`Grep pattern="<!-- /?(STATUS|CHECKPOINT) -->" path="production/session-state/active.md" output_mode="content" -n`)
and `Read` from the first to the last. A file with no markers predates the schema: read its
last `## Session Extract` block instead. Extract:
- What was most recently worked on
- Any in-progress tasks or open questions
- Current epic/feature/task from STATUS block (if present)

This tells you what the user just finished or is stuck on — use it to personalize
the output. It runs at every tier: at `minimal` it is the only read of the
checkpoint Step 4m relies on (a checkpoint saying "Next step: /story-done" means
the work is written). From here, `minimal` goes to **Step 4m**, not Step 4.

---

## Step 4: Check Step Completion for the Current Phase

For each step in the current phase (from the catalog):

### Artifact-based checks

**Resolve these deterministically — one call, not a glob per step:**

```
Bash: bash .claude/scripts/artifact-check.sh --phase [current-phase]
```

Run it exactly as written, here and below: from the project root, with the
relative path — no absolute path, no `cd`, no `2>&1`. This skill's permission
grant matches that form; any other asks the user to approve it.

It evaluates every `glob`, `pattern`, `min_count` and `any_of` in the catalog
against the working tree and reports one line per step. Map its statuses:

| status | Report as |
|---|---|
| `PRESENT` | **Complete** |
| `ABSENT` | **Incomplete** |
| `SHORT` | **Incomplete** — say how far short (`count=`/`min=` are given) |
| `PATTERN_MISS` | **Incomplete** — the file exists but lacks its marker; say so, since "missing" would send the user to recreate a file they already have |
| `NO_CHECK` | **MANUAL** if the step carries a `note=`, else **UNKNOWN** — completion is not trackable (e.g. repeatable implementation work) |

Do not re-derive any of this with Glob/Grep. `any_of` in particular is a list of
**alternatives** — one match is enough — and hand-evaluating it has already
produced a false "incomplete" once: the script reports which alternative matched
(`alt=`/`match=`).

**`NO_CHECK` never means done.** The script prints a `NO_CHECK:` total before the
rows; if most of a phase is NO_CHECK, say that plainly rather than implying the
phase is nearly complete. If the script prints no `STEPS:` line, or reports zero
steps, it did not evaluate the catalog: report `NOT ASSESSED` for the phase, not
"nothing incomplete".

### Special case: production phase — read `sprint-status.yaml`

When the current phase is `production`, check for `production/sprint-status.yaml`
before doing any glob-based story checks. If it exists, read it directly:

- Stories with `status: in-progress` → surface as "currently active"
- Stories with `status: ready-for-dev` → surface as "next up"
- Stories with `status: done` → count as complete
- Stories with `status: blocked` → surface as blocker with the `blocker` field

This gives precise per-story status without markdown scanning. Skip the glob
artifact check for the `implement` and `story-done` steps — the YAML is authoritative.

### Special case: `repeatable: true` (non-production)

For repeatable steps outside production (e.g. "feature specs"), the artifact
check tells you whether *any* work has been done, not whether it's finished.
Label these differently — show what's been detected, then note it may be ongoing.

---

## Step 4m: The Minimal Path (`workflow: minimal` only)

At `minimal` the route is the catalog's `paths.minimal`, not a phase: stack
configured → `design/product-brief.md` → stories → `/dev-story` ↔ `/story-done`.
Resolve it in one call:

```
Bash: bash .claude/scripts/artifact-check.sh --path minimal
```

Map the statuses exactly as in Step 4. `implement` and `story-done` are
`NO_CHECK` by design — the story status lines below are their check. The next
step is the first of these that applies:

1. stack setup not PRESENT → `/setup-stack`
2. product brief not PRESENT → `/brainstorm` (at `minimal` it writes the one-page brief)
3. stories not PRESENT → `/create-stories` with no argument (at `minimal` it
   builds the stories straight from the brief's MVP list)
4. Stories exist → the list below was printed by `.claude/scripts/story-status.sh`
   before you read this skill: one line per unfinished story, **already in
   the route's order** — `IN_REVIEW`, then `IN_PROGRESS`, then `TODO` (a
   `Ready` or `Not Started` story) in build order — then `BLOCKED`, `OTHER`,
   `NO_STATUS` and the `COMPLETE` count:

!`bash "${CLAUDE_SKILL_DIR}/../../scripts/story-status.sh"`

   **Next up is the story on the first `IN_REVIEW`, `IN_PROGRESS` or `TODO`
   line.** The list is already current; do not run the script again, and do
   not re-read or re-rank the story files:
   an `In Review` story is closed before an `In Progress` one continues — its
   work is written, and `/story-done` is quick.
   - `IN_REVIEW` → its work is written and waiting to be closed:
     `/story-done [path]`
   - `IN_PROGRESS` → it is **not** done — whatever the code or commits
     suggest, only `/story-done` makes a story Complete. Recommend
     `/story-done [path]` only if the user, `active.md` or the git log says
     its implementation is written; otherwise `/dev-story [path]` to carry on
   - `TODO` → `/dev-story [path]` — but first check `docs/research/<feature>.md`
     exists for that story's feature (gate 1 of the Definition of Done: no code
     from memory). If it does not, the next step is the research note: `/research`
     if `.claude/skills/research/SKILL.md` exists, otherwise ask the `researcher`
     agent. Say which of the two applied.
   - a `BLOCKED` story → name it and its blocker; it is never Next up
   - **no `IN_REVIEW`, `IN_PROGRESS` or `TODO` line, but `BLOCKED`, `OTHER` or
     `NO_STATUS` lines remain** → nothing can be built next, and the build
     order is **not** done. Name each of those stories with its status as
     written, and a blocked story's blocker (read it from that story's file).
     Next up is clearing the first of them: resolve its blocker, or give an
     `OTHER` or `NO_STATUS` story a `Status:` line the route reads (`Ready`
     once it can be built)
   - **every story `Complete` (or `Done`)** → the brief's build order is done.
     Say so, and offer three ways on: run the product and look at it; add the
     next stories from the brief with `/create-stories`; or, if the product has
     outgrown a one-page brief, `/settings` to raise `modes.rigor`.

**At `minimal`, never present any of these as required or as a blocker:** the
domain map, feature specs, ADR files, `/create-epics`, a sprint plan,
`/gate-check`, or sprint close-out (`/smoke-check`, `/team-qa`,
`/retrospective`). The brief replaces the design docs and its build order
replaces the sprint plan (`.claude/docs/workflow-modes.md` — `minimal` floor).
Every one of them still runs if the user asks for it; mention one only when the
user's argument asks about it. The **eight Definition of Done gates are not on
that list** — they are engineering, not documents, and apply at every tier.

Then skip Steps 5 and 8, and present with the `minimal` shape in Step 7.

---

## Step 5: Find Position and Identify Next Steps

From the completion data, determine:

1. **Last confirmed complete step** — the furthest completed required step
2. **Current blocker** — the first incomplete *required* step (this is what the
   user must do next)
3. **Optional opportunities** — incomplete *optional* steps that can be done
   before or alongside the blocker. **Surface these per the workflow tier**: at
   `full`, list all of them; at `standard`, list an optional doc only if it is
   required for the current feature/phase (do not flag genuinely-optional docs as
   gaps). At `minimal` this step does not run — Step 4m replaces it
4. **Upcoming required steps** — required steps after the current blocker
   (show as "coming up" so user can plan ahead)

If the user provided an argument (e.g. "just finished spec-review"), use that
to advance past the step they named even if the artifact check is ambiguous.

---

## Step 6: Check for In-Progress Work

If `active.md` shows an active task or epic:
- Surface it prominently at the top: "It looks like you were working on [X]"
- Suggest continuing it or confirm if it's done

---

## Step 7: Present Output

Keep it **short and direct**. This is a quick orientation, not a report.

```
## Where You Are: [Phase Label]

**In progress:** [from active.md, if any]

### ✓ Done
- [completed step name]
- [completed step name]

### → Next up (REQUIRED)
**[Step name]** — [description]
Command: `[/command]`

### ~ Also available (OPTIONAL)
- **[Step name]** — [description] → `/command`
- **[Step name]** — [description] → `/command`

### Coming up after that
- [Next required step name] (`/command`)
- [Next required step name] (`/command`)

---
Approaching **[next phase]** gate → run `/gate-check` when ready.
```

**At `minimal`** use this shape instead — no phase label, no gate line. `N`
counts only stories whose status line says `Complete` or `Done`, and only those
go under ✓ Done. `N` and `M` are the two numbers on the `COMPLETE` line; it
names no finished story, so ✓ Done gives their count, not their titles:

```
## Where You Are: Minimal path — [N] of [M] stories complete

**In progress:** [from active.md, if any]

### ✓ Done
- Stack: [layers] · Product brief · [N] stories

### → Next up
**[Story NNN: title]** — [what it delivers]
Command: `/story-done [story-path]` for an In Review story, or an In Progress one whose work is written; otherwise `/dev-story [story-path]` (after its research note)

### Coming up after that
- [the next Ready stories in build order, at most 3]
```

**Formatting rules:**
- `✓` for confirmed complete
- `→` for the current required next step (only one — the first blocker)
- `~` for optional steps available now
- Show commands inline as backtick code
- If a step has no command (e.g. "Implement Stories"), explain what to do instead of showing a slash command
- For MANUAL steps, ask the user: "I can't tell if [step] is done — has it been completed?"

Verdict: **COMPLETE** — next steps identified.

---

## Step 8: Gate Warning (if close)

Skip this step at `minimal` — the minimal path has no phase gates.

After the current phase's steps, check if the user is likely approaching a gate:
- If all required steps in the current phase are complete (or nearly complete),
  add: "You're close to the **[Current] → [Next]** gate. Run `/gate-check` when ready."
- If multiple required steps remain, skip the gate warning — it's not relevant yet.

---

## Step 9: Escalation Paths

After the recommendations, if the user seems stuck or confused, add:

```
---
Need more detail?
- `/project-stage-detect` — full gap analysis with all missing artifacts listed
- `/gate-check` — formal readiness check for your next phase
- `/start` — re-orient from scratch
- `/studio <goal>` — hand the whole goal to the orchestrator (if installed)
- `/settings` — if the process feels mismatched to your product, adjust
  `modes.rigor`: a **lower** tier when the user sounds overwhelmed by process
  (and rigor isn't already `minimal`), or a **higher** tier when the product has
  outgrown it (many bounded contexts, a second engineer, enterprise customers,
  or Production stage on `workflow: minimal`)
```

Only show this if the user's input suggested confusion (e.g. "I don't know", "stuck",
"lost", "not sure"). Don't show it for simple "what's next?" queries. Show the
`/settings` rigor line only when one of those triggers actually fires — not on
every confused query. Show the `/studio` line only if
`.claude/skills/studio/SKILL.md` exists. At `minimal`, leave out the
`/gate-check` line: the minimal path has no phase gates (Step 4m).

---

## Collaborative Protocol

- **Never auto-run the next skill.** Recommend it, let the user invoke it.
- **Ask about MANUAL steps** rather than assuming complete or incomplete.
- **Match the user's tone** — if they sound stressed ("I'm totally lost"), be
  reassuring and give one action, not a list of six.
- **One primary recommendation** — the user should leave knowing exactly one thing
  to do next. Optional steps and "coming up" are secondary context.
