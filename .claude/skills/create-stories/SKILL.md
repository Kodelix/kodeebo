---
name: create-stories
description: "Break one epic into implementable stories embedding TR-ID, ADR guidance, acceptance criteria (incl. negative and cross-tenant), story type, owner agent and the DoD evidence each story must produce. Contract-first ordering. Reads the control manifest. After /create-epics."
argument-hint: "[epic-slug | epic-path] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(date *), Bash(bash "*/.claude/skills/create-stories/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,story_granularity,qa.level,system_overrides,stack,testing.strict,performance.enforce`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.


# Create Stories

A story is a single implementable behaviour in **one code root** — small enough to
complete in one focused session, self-contained, and fully traceable to a spec
requirement and an ADR decision. Stories are what engineers pick up. Epics are
what architects define.

**Run this skill per epic**, not per layer. Run it for Foundation epics first,
then Core, and so on — matching the dependency order.

**Output:** `production/epics/[epic-slug]/story-NNN-[slug].md` files

**Previous step:** `/create-epics [context]`
**Next step after stories exist:** `/story-readiness [story-path]` then `/dev-story [story-path]` —
at `workflow: minimal`, `/dev-story [story-path]` directly (`/story-readiness` is not on the minimal path)

---

## 1. Parse Argument


See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`workflow`** for this epic's feature(s) (per `.claude/docs/workflow-modes.md`) —
use the `system_overrides` row for `<feature>` if the block lists one, else the
project value. `<feature>` is the spec filename stem of the epic's spec. The tier
sets which prerequisites block — see the note in Step 2.

**`story_granularity`** — it sets each
story's AC load: **5–10 ACs covering a whole feature slice** at `coarse` (the default, via `rigor: minimal`), **2–4 ACs
covering one task** at `balanced` (`rigor: standard`), **1 AC** at `fine` (the story name is
the AC restatement). Group or split ACs into stories to hit the target. Standard-mandated
negative and cross-tenant criteria (Step 4) count toward the load; they are never dropped to hit it.

**`docs.density`** — it controls the *depth* of each story's prose (context,
implementation notes, ADR summary), not the AC count (that is
`story_granularity`) and never the AC text itself. `modes.rigor` sets it
alongside `workflow`; set `docs.density` explicitly to vary story prose alone:
`terse` (the default, via `rigor: minimal`) = notes as bullets, no preamble; `balanced` = short context paragraph +
notes (`rigor: standard`); `thorough` = full context, implementation guidance, and ADR
rationale. The embedded TR-ID reference, ADR Version stamp, acceptance
criteria and the Definition of Done evidence table are structural and are never trimmed by density.

**`qa.level`** governs how much *additional* test evidence is required to close a
story (manual cases, coverage signal, UAT) and composes with `testing.strict.*`
(does a failure block for the other types). It **never** scales the required tests down:
Logic, Integration, Contract and Security tests exist and pass at every tier
(`coding-standards.md`). Security and run-and-observe evidence and a UI story's
retained screenshot are required at every level; a story's evidence table
(Step 6) states the effective gate level per type from `testing.strict.*`, else the
defaults in `.claude/docs/coding-standards.md`.

- `/create-stories [epic-slug]` — e.g. `/create-stories billing`
- `/create-stories production/epics/billing/EPIC.md` — full path also accepted
- **A named epic that does not exist** — if `production/epics/[slug]/EPIC.md`
  (or the given path) is missing, stop at `standard`/`full`: "No epic at
  `production/epics/[slug]/EPIC.md`. Run `/create-epics` to create it, or check
  the slug (Glob `production/epics/*/EPIC.md`)." Do not decompose from a guess. At
  `minimal` there are no `/create-epics` epics to name and that skill is not on
  the path — say so, take Step 2's `minimal` branch, and name the slug it uses.
- No argument — at `minimal` there are no epics yet (Option A): skip to Step 2's
  `minimal` branch and synthesize the epic from `design/product-brief.md`. At
  `standard`/`full`, ask "Which epic would you like to break into stories?" and
  Glob `production/epics/*/EPIC.md` to list available epics with their status.

  > **If that glob returns nothing at `standard`/`full`, stop — do not build a
  > question with no options.** Report:
  > "No epics found under `production/epics/`. Run `/create-epics layer: foundation`
  > first — an epic is what this skill decomposes."
  >
  > **The zero-epic path is load-bearing.** Asking which epic *and* globbing to
  > list them leaves an `AskUserQuestion` with nothing to offer when the glob is
  > empty. Route to `/create-epics` instead — it is named as **Previous step**
  > in this skill's own header.
  >
  > Note what this skill guarded and what it did not. Step 2's ADR validation is
  > thorough: three tiers, each with its own stop condition, and an explicit
  > message naming the missing file. That is the **deepest** input. The **first**
  > input — does an epic exist at all — went unchecked. Guarding the far end of a
  > chain while leaving the near end open is the shape to watch for.
  >
  > At `minimal` this does not apply: there are deliberately no epics, and the
  > branch above synthesizes one from the brief.

---

## 2. Load Everything for This Epic

**Read `references/2-load.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 3. Classify Stories by Type

**Read `references/3-classify.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 4. Decompose the Spec into Stories

**Read `references/4-decompose.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 4b. QA Lead Story Readiness Gate

**Read `references/4b-qa-gate.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

---

## 5. Present Stories for Review

Before writing any files, present the full story list:

```
## Stories for Epic: [name]

Story 001 [contracts/]: [title] — Contract — ADR-NNNN — owner: api-designer
  Covers: TR-[feature]-001 ([1-line summary of requirement])
  Evidence: contracts/ diff + consumer contract tests
  Unblocks: 002, 004, 005

Story 002 [backend/]: [title] — Logic — ADR-NNNN — owner: go-lead
  Covers: TR-[feature]-001
  Depends on: 001
  Evidence: unit tests beside the code (+ cross-tenant negative test)

Story 003 [backend/]: [title] — Security — ADR-MMMM — owner: appsec-engineer + go-lead
  Covers: TR-[feature]-002, TR-[feature]-003
  Standards: ASVS [IDs], threat model docs/architecture/threat-models/[feature].md [present | MISSING]
  Evidence: negative tests + ASVS mapping in production/qa/evidence/[STORY-ID]/

Story 004 [web/]: [title] — UI — ADR-NNNN — owner: web-lead
  Covers: TR-[feature]-004
  Depends on: 001 (and 002 for run-and-observe)
  Evidence: screenshots (AR/RTL + EN) + /impeccable audit in production/qa/evidence/[STORY-ID]/

[N stories total: N Contract, N Logic, N Integration, N Security, N Performance, N UI, N Config]
Research note: docs/research/[feature].md [present | MISSING — /story-readiness will return NEEDS WORK until it exists]
Blocked: [stories with a Proposed/Deprecated/Superseded ADR, with the reason]
Dropped / not decomposed: [requirements with no story and why, or "None"]
```

Use `AskUserQuestion`:
- Prompt: "May I write these [N] stories to `production/epics/[epic-slug]/`, and update `production/epics/[epic-slug]/EPIC.md` and `production/epics/index.md`?" — name every file Step 6 touches: at `minimal` say *create* `EPIC.md` only when none exists yet (the Step 2 draft, shown with the stories), and leave `index.md` out when it does not exist.
- Options: `[A] Yes — write all [N] stories` / `[B] Not yet — I want to review or adjust first`

---

## 6. Write Story Files

**Read `references/6-story-format.md` now and follow it** — it holds the story template, the `minimal` field mapping, and the EPIC.md and index updates.

---

## 7. After Writing

**Checkpoint.** First, update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/create-stories <epic-slug>
— <verdict>`, Next step = option [A] below (`/story-readiness
[first-story-path]`, or `/dev-story` at `minimal`), plus Blocked on / Files in
progress (the story files, EPIC.md) / Open questions (MISSING research notes or
threat models); append the Notes line. Still updated on `BLOCKED` / `NOT
ASSESSED` or a declined write (record nothing written and why).

Use `AskUserQuestion` to close with context-aware next steps:

Check:
- Are there other epics in `production/epics/` without stories yet? List them.
- Is this the last epic? If so, include `/sprint-plan` as an option — except at `workflow: minimal`, which has no sprints: the brief's build order is the plan.
- Do any written stories show `Research note: MISSING` or `Threat model: MISSING`? List them with the skill that closes each (`/research`, `/threat-model`).

Widget:
- Prompt: "[N] stories written to `production/epics/[epic-slug]/`. What next?"
- Options (include all that apply — at most four, the tool's limit):
  - `[A] Start implementing — run /dev-story [first-story-path]` at `minimal`, `/story-readiness [first-story-path]` otherwise (Recommended; the first story is the epic's contract story when one exists)
  - `[B] Close a gap — run /research [feature] or /threat-model [feature]` (only if a story shows one MISSING)
  - `[C]` one of (the two never both apply): `Create stories for [next-epic-slug] — run /create-stories [slug]` if other epics have no stories yet; otherwise `Plan the sprint — run /sprint-plan new` (never at `minimal` — omit [C] then)
  - `[D] Stop here for this session`

Note in output: "Work through stories in order — each story's `Depends on:` field tells you what must be DONE before you can start it. Contract stories come first."

---

## Not-Run Reporting

The closing report names what did not run or could not be resolved, in the output
and not only in the files: QL-STORY-READY skipped by review mode or NOT ASSESSED
(per story), stories written without qa-lead specs, TR-IDs written as
`TR-[feature]-???`, research notes and threat models marked MISSING, stack risk
`NOT ASSESSED`, ADR checks relaxed by tier, requirements left with no story. A
silent skip and a clean run must not look alike.

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **Read before presenting** — load all inputs silently before showing the story list
2. **Ask once** — present all stories for the epic in one summary, not one at a time
3. **Warn on blocked stories** — flag any story with a Proposed ADR before writing
4. **Ask before writing** — get approval for the full story set before writing files
5. **No invention** — acceptance criteria come from specs (and the studio standards for negative, cross-tenant and observability criteria, labelled as such), implementation notes from ADRs, rules from the manifest
6. **Never start implementation** — this skill stops at the story file level

After writing (or declining):

- **Verdict: COMPLETE** — [N] stories written to `production/epics/[epic-slug]/`. Run `/dev-story` (at `minimal`) or `/story-readiness` → `/dev-story` to begin implementation.
- **Verdict: COMPLETE WITH GAPS** — stories written with named gaps (QL-STORY-READY `NOT ASSESSED` or skipped by mode, stories embedded `Blocked` for missing ADRs, MISSING research notes or threat models, `Risk: NOT ASSESSED`). List each.
- **Verdict: NOT ASSESSED** — an input could not be read (nothing was decomposed); name it.
- **Verdict: BLOCKED** — a prerequisite is missing (no epic, no brief, a required ADR absent: name it), or `BLOCKED — write declined by user`. No story files written.
