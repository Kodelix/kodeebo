---
name: start
description: "First-run onboarding — new product, existing codebase, or just exploring; sets rigor and automation, then points to /studio and /setup-stack."
argument-hint: "[no arguments]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/start/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys rigor,review_mode,automation,project.stage,stack`

Resolved above — use as-is. No block (a fresh project with no `project.yaml`) →
defaults in `.claude/docs/config-resolution.md`.

# Guided Onboarding

This skill writes `project.yaml` — the `project.stage`, `modes.rigor` and
`modes.automation` settings. It **never creates** the legacy mirror
`production/stage.txt`; every reader prefers `project.stage` and uses the mirror
only as a fallback. If `production/stage.txt` already exists (a project created
before 2026-10-13), it is updated in the same approved write so the two never
disagree. `modes.rigor` and `modes.automation` have no legacy mirror; they are
written to `project.yaml` only.

> **`/start` never writes `modes.review_mode`, in either location.** It is a
> rigor-fronted knob: writing it explicitly pins it and shadows the `modes.rigor`
> expansion, so the Phase 3d question would stop changing director-review depth
> (see Phase 3d, and the header comment of `project.yaml`). It must
> **not** write `production/review-mode.txt` either — the legacy step sits
> **above** the rigor expansion in the resolution chain, deliberately, so a
> genuine older project's explicit choice survives migration. On a new project
> that ordering works against you: a mirror file written here would outrank the
> expansion permanently. Verified: `rigor: minimal` plus a `review-mode.txt`
> containing `lean` resolves to `lean`, not the expected `solo`.
>
> The other knobs `modes.rigor` fronts — `modes.workflow`, `docs.density`,
> `qa.level`, `modes.story_granularity`, `team.size` — are never written by
> `/start` either: each would pin its value over the rigor expansion.

This skill is the entry point for a new user. It does NOT assume you have a
product idea, a stack preference, or any prior experience with the studio. It
asks first, then routes you to the right workflow. It never chooses a stack:
that is `/setup-stack`, which Phase 4 hands off to.

---

**Automation mode**: use the resolved `automation` value from the config block
above (`project.local.yaml` → `project.yaml` → default `collaborative`; no prose
chain to hand-resolve). **Note**: on a fresh project no
`modes.automation` is set yet, so `/start` runs collaboratively — it is
creating the config. Its core onboarding questions (starting point, rigor,
automation) are project-shaping and always prompt regardless of mode. Stack
choice is **not** among them — it is deferred to `/setup-stack`.
If `/start` is re-run on an already-configured project, the resolved mode
applies per `.claude/docs/automation-modes.md`.

## Phase 1: Detect Project State

Before asking anything, silently gather context so you can tailor your guidance.
Do NOT show these results unprompted — they inform your recommendations, not the
conversation opener.

Check:
- **Stack configured?** Read `stack.backend` (and `stack.web`, `stack.mobile`, `stack.desktop`) in
  `project.yaml`. Any non-empty layer means a stack has been chosen. Empty or
  absent means not set — never guess one from the files on disk.
- **Product brief exists?** Check `design/product-brief.md`. A file that is only
  the template (its fields still hold `[...]` placeholders) counts as absent.
- **Domain map / feature specs?** Check `design/specs/domain-map.md`, and count
  markdown files in `design/specs/` other than the map.
- **Source code exists?** The code roots are `layout.code_roots` from
  `project.yaml`; when that is empty, the conventional directories that exist on
  disk (`backend/`, `web/`, `site/`, `mobile/`, `desktop/`, `contracts/`) — the same
  detection `resolve_code_root` performs in `.claude/hooks/yaml-helper.sh`. Glob
  each for source files (`*.go`, `*.kt`, `*.kts`, `*.ts`, `*.tsx`, `*.swift`,
  `*.astro`, `*.sql`, `*.proto`, `*.yaml` under `contracts/`). **If no code root
  resolves, say so rather than concluding there is no code** — a repository that
  keeps its code under `app/` or `services/` scanned as `backend/` returns zero
  files and reads as greenfield. It is a reason to ask in Path C, not a finding.
- **Prototypes exist?** Check for subdirectories in `prototypes/`.
- **Architecture / production artifacts?** Count `docs/architecture/adr-*.md`,
  and files in `production/epics/` and `production/sprints/`.
- **Still wired to the template repo?** Read `.git/config` if it is a file. If
  its `[remote "origin"]` url ends in a repository named `saas-studio`
  (compared case-insensitively, `.git` suffix ignored), `origin` may still point
  at the studio template, so `git push` and `gh pr create` would target it, not
  the user's product. Note it: it is reported on every path, the returning
  user's included. It can be a false positive when this repository is the
  user's own copy of the studio; word the note as a question. Read only; never
  run git.

Store these findings internally to validate the user's self-assessment and
tailor recommendations.

---

## Phase 2: Ask Where the User Is

This is the first thing the user sees — unless Phase 1 found a returning user
(stack configured, and a product brief present): then ask nothing here and answer
as the **User is returning** edge case below. Otherwise, use `AskUserQuestion`
with these exact options so the user can click rather than type:

- **Prompt**: "Welcome to SaaS Studio! Before I suggest anything, I'd like to understand where you're starting from. Where are you at right now?"
- **Options**:
  - `A) New product, idea still forming` — I have no concept yet, or only a theme, a market or a pain point in mind. I want to explore and figure out what to build.
  - `B) New product, clear concept` — I know who it is for and what it does, maybe the pricing model, but haven't written it down yet.
  - `C) Existing codebase or docs` — I already have code, specs, ADRs, prototypes or planning in a repository. I want the studio to adopt it.
  - `D) Just exploring` — I want to see how the studio works before committing to anything.

Wait for the user's selection. Do not proceed until they respond.

---

## Phase 3: Route Based on Answer

#### If A: New product, idea still forming

The user needs exploration before anything else.

1. Acknowledge that starting from a loose idea is completely fine.
2. Ask for the idea in plain text — even a few words ("invoicing for clinics", "something for freelancers who chase payments") is enough; an empty answer is fine too. Do not use `AskUserQuestion` (it is an open response).
3. Recommend running `/brainstorm open` (fully open exploration), or `/brainstorm [their hint]` if they gave one. Briefly explain that it turns a loose idea into a written product brief — customer, problem, pricing model, MVP — that the next step can build from.

   > **Describe it tier-neutrally here.** Phase 3d has not run, so you do not yet
   > know how much process this project wants — and `/brainstorm` changes shape
   > completely on that answer. At `minimal` it runs a short flow and stops,
   > producing a one-page `design/product-brief.md`; at `standard`/`full` it runs
   > the fuller product-discovery walk. Naming the full walk here, then having
   > Phase 4 describe the same skill as "produce the one-page brief", gives the
   > user two contradicting accounts of one skill inside a single `/start` run.
   > Phase 4 is where the tier-specific description belongs.
4. Name the **immediate next step only**. Do not list the full pipeline here.
   Say: "I'll lay out the full path once I know how much process you want — two
   quick questions away."

#### If B: New product, clear concept

1. Ask them to describe the product in one sentence — who it is for and the job it does. Plain text, not `AskUserQuestion`.
2. Acknowledge the concept, then use `AskUserQuestion` to offer two paths:
   - **Prompt**: "How would you like to proceed?"
   - **Options**:
     - `Formalize it first` — Run `/brainstorm [concept]` to write it down: a one-page brief at `rigor: minimal` (the default), a fuller product brief above it
     - `Jump straight in` — Go to `/setup-stack` now and write the brief afterward
3. Name the **immediate next step only** — their pick from step 2. Say: "I'll lay
   out the full path once I know how much process you want — two quick questions
   away."

#### If C: Existing codebase or docs

1. Share what you found in Phase 1:
   - "I can see [X source files across Y code roots / Z specs / N prototypes]..." (or "I could not resolve a code root — where does your code live?" when none resolved)
   - "Your stack is [configured as X / not yet configured]..."
2. **Sub-case C1 — Code only, or early docs** (no specs, ADRs or stories in studio format):
   - Recommend `/project-stage-detect` for a gap inventory, then `/setup-stack` to record the stack the code already uses (it reads the manifests; it does not invent one).
   **Sub-case C2 — Specs, ADRs, epics or stories already exist:**
   - Explain: "Having files isn't the same as the studio's skills being able to use them. Specs may be missing required sections and ADRs may lack a Status. `/adopt` checks this specifically."
   - Recommend, in order: `/project-stage-detect` (what phase, what is missing entirely), then `/adopt` (are the existing artifacts in the right internal format).
3. Name the **immediate next step only** — `/project-stage-detect`. The rest of the
   path depends on rigor, which Phase 3d has not asked yet, so Phase 4 prints it.
   Say: "I'll lay out the full path once I know how much process you want — two
   quick questions away."

#### If D: Just exploring

1. Tell them, in a few lines, what the studio is: coordinated specialist agents
   for building a SaaS product (hosted and self-hosted), one entry point
   (`/studio <goal in plain words>`), a research-first, eight-gate Definition of
   Done for every story, and `/help` at any time for the next step.
2. Offer a look around without committing: `/help` (what comes next from where
   you are), `/project-stage-detect` (an audit of whatever is in this repo).
3. **Write nothing.** No stage, no rigor, no automation — there is nothing yet to
   anchor them to. Say so in one line: "I haven't saved any settings; run `/start`
   again when you want to set up a product."
4. Skip Phases 3c–4. Verdict: **COMPLETE** — user oriented, no config written.

---

## Phase 3c: Write Initial Stage

**Compare before asking.** Take `[stage]` from the Stage mapping below and
compare it with the `project.stage` already resolved above. A value that is
already set to the same value is neither asked about nor re-written: say
"`project.stage` is already `[stage]` — unchanged." and ask only about the
values that change (the stage if it differs; the Phase 3d and 3e answers once
given). If nothing changes, write nothing and skip the ask.

**Ask before the `project.yaml` write**, for the values that change only: "May I
write `project.stage: [stage]` to `project.yaml`?" (list each changing key in
the same sentence; if `production/stage.txt` already exists, add "and update the
existing legacy `production/stage.txt`"). Say the file will be created when
there is none, and that the Phase 3d and 3e answers will go there too when those
questions are still to be asked. That one approval covers this write and the
Phase 3d and 3e writes. If the user declines, write nothing, keep the stage and
those answers for this run only, and say they were not saved.

After the approval, write the changed stage to `project.yaml`. **Never create
`production/stage.txt`.** Only if that file already exists, write the same
single-line stage name to it too in the same write, so the two never disagree.

In `project.yaml`, ensure a `project:` block exists with `stage: [value]`.
- **If `project.yaml` already exists** (it ships with the studio): Read it first
  (the Edit tool requires the file to have been read in this session), then use
  the Edit tool to update the `stage:` line under `project:` — or add the block
  immediately after the `framework:` block when it is missing. Leave every other
  key, comment and empty `stack:` placeholder as it is.
- **If `project.yaml` does not exist** at the repo root: create it with the Write
  tool using this minimal template (replace `[value]`):
  ```yaml
  # SaaS Studio project configuration — single source of truth for project settings.
  # Skills read it through resolve_config (.claude/hooks/yaml-helper.sh).

  schema_version: 1

  framework:
    name: saas-studio
    version: 0.1.0

  project:
    name: ""
    stage: [value]
  ```
  **Do not seed `modes.review_mode` here.** It is a rigor-fronted knob —
  `modes.rigor` supplies its value, so an explicit value here would shadow the
  rigor expansion and pin the review mode regardless of the rigor the user picks
  in Phase 3d. `modes.rigor` itself is omitted for a related reason: Phase 3d
  skips its question when the key is already set, so seeding it would suppress
  that question. Do not seed `stack:` either — `/setup-stack` writes it after
  verifying every value.

If `production/stage.txt` already exists, write the same single-line stage name
to it too (no trailing newline); if it does not exist, leave it absent.

Stage mapping (the valid values are the `project.stage` enum in
`.claude/hooks/yaml-helper.sh`):
- **Path A or B (new product)**: write `Discovery`
- **Path C, no product brief yet**: write `Discovery`
- **Path C, brief exists but no domain map or specs**: write `Product Design`
- **Path C, specs exist but no architecture doc or ADRs**: write `Architecture`
- **Path C, architecture documented, little or no code**: write `Pre-Production`
- **Path C, architecture documented and substantial code across the code roots**: write `Production`

`Hardening`, `Release` and `Live` are never set here — they are explicit, written
by `/gate-check` at the matching gate. A path-C project that is already shipping
gets `Production` and a note that `/gate-check` moves it later.

An existing `production/stage.txt` is covered by the same ask: it is a one-line
legacy mirror of the stage approved for `project.yaml`, updated only so the two
never disagree.

Say: "I've set `project.stage` to `[stage]` — this anchors your status line and
stage detection." (append "and updated the existing `production/stage.txt`" when
that file was updated; when the value was already `[stage]`, say "already
`[stage]` — unchanged" instead and write nothing for the stage.)

---

## Phase 3d: Set Rigor

Check whether `modes.rigor` is already set in `project.yaml`. **If it is**, show
it — "Rigor is set to `[current]`." — and proceed to **Phase 3e**. Do not ask
again. Either way, **carry the resolved value forward** — Phase 4 branches its
recommended path on it.

**If it is not set**: first pick a recommendation, then ask.

**Seed the recommendation** from what the user described in Phase 2:
- Map their product to an archetype: a validate-fast tool, an internal tool or a
  solo first version → `minimal`; a product with paying customers, several
  bounded contexts that affect each other (billing, tenancy, roles) → `standard`;
  enterprise or self-hosted customers, regulated data, several engineers or a
  firm contractual date → `full`.
- If the user has **no concept at all** (Path A with nothing described), recommend
  the validate-fast option (`minimal`) and add: "You can raise this after
  `/brainstorm` once the product is clearer — `/settings` changes it anytime."
- **A vague hint still counts as a description.** "Still forming" is about having
  no signal, not about which path the user picked. If the hint trips a heavier
  signal — "invoicing for hospitals with an on-premise install" hits regulated
  data and self-hosted — seed from the signal, not from the path, and say why in
  the user's own terms. Recommending `minimal` for a described enterprise product
  is the mismatch Phase 4 would then have to flag, caused here.
- If nothing in the description points either way, recommend `minimal`, the
  documented default, and add: "`/settings` raises it once the product shows it
  needs more."

Then use `AskUserQuestion`. Order the options so the **recommended** archetype is
first and append ` (Recommended)` to its label (per the AskUserQuestion
convention); the other two follow in any order.

- **Prompt**: "What best describes what you're building? This sets how much documentation the project carries — you can change it anytime with `/settings`."
- **Options** (base labels — the recommended one also gets ` (Recommended)`):
  - `Validate fast / internal tool / first version` — A one-page product brief, coarse stories, light review. **About 4 steps to your first line of code instead of about 18.** Design lives in the brief and its decision log. The trade: no per-feature specs or ADR files, so design problems surface in code rather than before it.
  - `Product with customers and interacting parts` — Balanced docs: product brief, domain map, a spec per feature, an architecture doc, ADRs for the foundation decisions, threat models for sensitive features. **Expect a day or more of design work before your first line of code.** Worth paying when contexts interact (billing, tenancy, roles) and a design mistake is expensive to unpick once data exists. **Intending to finish is not the test** — most first versions ship faster on the lightweight path and can move up later with `/settings`.
  - `Enterprise, self-hosted, regulated, or a team` — Thorough docs, fine-grained stories, evidence required everywhere, a UX spec per screen and SLOs. Enterprise or self-hosted customers, regulated data, a firm date, or shared ownership by several engineers.

Value mapping (ignore any ` (Recommended)` suffix on the first option):
`Validate fast / internal tool / first version` → `minimal`,
`Product with customers and interacting parts` → `standard`,
`Enterprise, self-hosted, regulated, or a team` → `full`.

Write `modes.rigor` to `project.yaml` immediately after the user selects — no
separate "May I write?" needed, as the write is a direct consequence of the
selection. Use the Edit tool. The Phase 3c template has no `modes:` block: if
`project.yaml` has none, add one with `rigor:` under it; if it has one, add
`rigor:` under it. Never add a second `modes:` line — YAML allows one block per
key. There is **no legacy mirror file** for this setting, so this is a single
write, not a dual-write.
If the Phase 3c `project.yaml` write was declined, do not write this one either —
carry the answer forward and say it was not saved.

Then say: "Set `modes.rigor` to `[choice]`. That drives six settings —
`modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`,
`modes.review_mode` (director-review depth), and `team.size` (how many agents are
active on team tasks) — a lighter rigor means fewer reviews, a smaller active
team, and fewer tokens. **It changes documents, not engineering:** the eight
Definition of Done gates (research, clean architecture, tests, observability,
caching, performance, security, decision record) apply at every level. Run
`/settings` to see the exact value each knob takes, or set any of them
explicitly to override just that one."

**Why this is asked here.** These six knobs each change what skills produce, and
asking once, at onboarding, is the only point where the answer is cheap;
skipping this question leaves every project silently running at defaults the
user has never seen.

---

## Phase 3e: Set Automation Mode

Check whether `modes.automation` is already set in `project.yaml`. **If it is**,
show it — "Automation is set to `[current]`." — and proceed to Phase 4. Do not
ask again.

**If it is not set**: Use `AskUserQuestion`:

- **Prompt**: "Last one: how much should I confirm with you as we work?"
- **Options**:
  - `Collaborative` — I ask before each significant step and show drafts before writing. Most control; best while you are learning the workflow and want to see everything.
  - `Guided (recommended)` — I decide the small stuff and proceed, but still stop for the big calls (scope changes, file deletions, schema changes). Far fewer interruptions than collaborative, without giving up control of the decisions that matter.
  - `Autonomous` — I proceed and log decisions rather than asking, except for the always-ask categories. Fastest to run, but it makes every call itself and costs more tokens; best for trusted, well-scoped runs.

Value mapping: `Collaborative` → `collaborative`, `Guided (recommended)` →
`guided`, `Autonomous` → `autonomous`.

Write `modes.automation` to `project.yaml` immediately after the user selects —
no separate "May I write?" needed, as the write is a direct consequence of the
selection. Use the Edit tool to add `automation:` under the `modes:` block
(Phase 3d creates it); if `project.yaml` has none, add one. Never add a second
`modes:` line. There is **no legacy mirror file** for this setting. If the
Phase 3c `project.yaml` write was declined, do not write this one either — say it
was not saved.

Then say: "Set `modes.automation` to `[choice]`. See
`.claude/docs/automation-modes.md` for exactly what each mode asks vs. proceeds
on. `guided` and `autonomous` still always stop for the `automation_always_ask`
categories (scope changes, file deletions, schema changes)."

**Why this is asked here.** `modes.automation` controls how often every skill
stops to confirm. A project that wants to move fast should not have to discover
the knob after fifty approval prompts. Do **not** seed `modes.automation` into
the Phase 3c template: Phase 3e skips when the key is already set, so seeding it
would suppress its own question.

---

## Phase 4: Show the Path, Then Confirm

**Now** present the recommended path — after Phase 3d, so it can match the rigor
the user actually chose. Print **one** of the three below, using the
`modes.rigor` value resolved or written in Phase 3d; if it is somehow still
unset, use `minimal` (its documented default) rather than skipping the path.
(Paths A/B; a Path C user gets the retrofit path below instead.)

Before printing, Glob `.claude/skills/<name>/SKILL.md` for each skill you are
about to name. A skill with no file is **not installed yet** — print it with
"(not installed yet)" beside it rather than presenting a command that will fail.
`/studio` in particular is a later addition to the studio: if its file is absent,
say that outright in the hand-off.

Say first: "Here's your path at `rigor: [chosen]`. Every skill still runs at any
level — rigor changes what's *required*, not what's allowed. So at `minimal` you
can still call `/ux-design`, `/threat-model`, `/qa-plan` or anything else the
moment you want it — nothing is locked, it simply is not demanded up front. And
if one feature alone deserves more care (billing, say), raise just that one with
`workflow_overrides.system_overrides.<feature>` rather than the whole project."

**If `minimal` (default) — 4 steps to running code:**
- `/setup-stack` — configure the stack, deployment, distribution and tenancy; verify the stack reference
- `/brainstorm` — produce the one-page `design/product-brief.md` (the lean-tier design artifact; it replaces the domain map and per-feature specs)
- `/create-stories` — turn the brief's MVP list into implementable stories (the epic is implicit — no separate `/create-epics` or `/sprint-plan`; the brief's build order is the plan)
- `/dev-story` — **first line of product code** (a research note for the feature comes first: gate 1 of the Definition of Done)

**If `standard` — the full pipeline:**
- **Discovery:** `/setup-stack` → `/brainstorm` → `/prototype` (optional) → `/map-domains` → `/design-spec` (×N features) → `/review-all-specs` → `/gate-check`
- **Architecture:** `/create-architecture` → `/architecture-decision` (×N) → `/create-control-manifest` → `/architecture-review`
- **Pre-Production:** `/ux-design` → `/create-epics` → `/create-stories` → `/sprint-plan`
- **Production:** `/dev-story`

**If `full` — the full pipeline plus validation builds:**
- Everything in `standard`, plus `/vertical-slice` and `/usability-report` (×1+)
  in Pre-Production, `/spec-review` after each feature spec, and a threat model
  for every sensitive feature (auth, billing, uploads, PII).

**For a Path C user, print this retrofit path in place of the three above.**
At `minimal` it stops after `/adopt` and `/setup-stack`: the minimal path needs
only `design/product-brief.md` (`/brainstorm`) and stories (`/create-stories`),
so do not send the user through the spec, ADR and registry retrofit below. At
`standard` and `full`:
- `/project-stage-detect` — phase detection + existence gaps
- `/adopt` — format compliance audit + migration plan
- `/setup-stack` — record the stack the code uses; verify the stack reference
- `/design-spec retrofit [path]` — fill missing feature-spec sections
- `/architecture-decision retrofit [path]` — add missing ADR sections
- `/architecture-review` — bootstrap the TR requirement registry
- `/gate-check` — validate readiness for the next phase

> **Do not present the minimal path as lesser.** It is the tier's documented
> floor (`.claude/docs/workflow-modes.md` — a filled `design/product-brief.md`,
> a configured stack and a research note per feature are required before code;
> everything else can be skipped), not a degraded mode. Equally, do not oversell
> it: at `minimal` there are no feature specs to catch design problems before
> they reach code, which is the trade being made. And the eight Definition of
> Done gates do not shrink with it.

If the user picked a rigor that contradicts what they described in Phase 2 —
overriding the seeded recommendation, e.g. choosing `minimal` after describing a
self-hosted product for regulated customers, or `full` for a weekend tool — say
so once, in one sentence, and offer `/settings` to change it. Do not re-ask.
Conversely, suggest a **lower** tier when the user sounds overwhelmed by process,
and a **higher** one when the product has outgrown its tier (many contexts, a
second engineer, enterprise customers, or `Production` stage on `minimal`).

If Phase 1 found `origin` possibly pointing at the studio template, add once,
after the path: "Your `origin` remote looks like the studio template repository.
If this is your own product repo, ignore this; otherwise a push or pull request
would go to the template, not your product. To repoint it:
`git remote rename origin studio`, then `git remote add origin <your repo URL>`."
Suggest it; do not run it.

Then use `AskUserQuestion` to ask which step they'd like to take first. Never
auto-run the next skill.

- **Prompt**: "Would you like to start with [recommended first step]?"
- **Options**:
  - `Yes, let's start with [recommended first step]`
  - `I'd like to do something else first`

---

## Phase 5: Hand Off

**Checkpoint.** Before the final message, update
`production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`:
Current task `/start — <verdict>`, Next step = the skill command the user
confirmed (`/setup-stack` unless the stack is already configured), plus Blocked
on / Files in progress (`project.yaml` and any stage file written) / Open
questions; append the Notes line. Still updated when the user exits early or
declined a write (record that nothing was written).

When the user confirms their next step, respond briefly:

- "Type `[skill command]` to begin." Nothing else about that skill — do not
  re-explain it or add encouragement.
- "From here on, `/studio <goal in plain words>` is the main entry point: it
  reads your config and session state, classifies the goal and drives the
  matching flow. `/help` tells you the next step at any time." If
  `.claude/skills/studio/SKILL.md` does not exist, say instead: "`/studio` is the
  intended main entry point but is not installed yet; until it is, run the skills
  above directly and use `/help`."
- Unless the stack is already configured, remind them that **`/setup-stack`** is
  the step that fixes the stack, and nothing that writes code should run before
  it.

Verdict: **COMPLETE** — user oriented and handed off to next step.

---

## Edge Cases

- **User picks C but the repository is empty**: Gently redirect — "It looks like the project is a fresh studio copy with no artifacts yet. Would Path A or B be a better fit?"
- **User picks A or B but the project has code**: Mention what you found — "I noticed there's already code in `[code root]`. Did you mean to pick C (existing codebase)?"
- **User is returning (stack configured, product brief exists)**: Skip onboarding entirely — "It looks like you're already set up! Your stack is [layers] and you have a product brief at `design/product-brief.md`. Review mode: `[the resolved review_mode from the config block]`. Want to pick up where you left off? Try `/help` — it reads your tier and progress and names the next step — or just tell me what you'd like to work on." If Phase 1 found `origin` possibly pointing at the template repo, add the Phase 4 note about repointing `origin` here too.
- **User doesn't fit any option**: Let them describe their situation in their own words and adapt.
- **`project.yaml` is unreadable or malformed**: Say so and stop before writing — do not overwrite a file you could not parse.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **Ask first** — never assume the user's state or intent
2. **Present options** — give clear paths, not mandates
3. **User decides** — they pick the direction
4. **No auto-execution** — recommend the next skill, don't run it without asking
5. **Adapt** — if the user's situation doesn't fit a template, listen and adjust
