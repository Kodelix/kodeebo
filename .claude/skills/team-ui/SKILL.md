---
name: team-ui
description: "Orchestrate the UI team through the UX pipeline — design-director direction, ux-designer and ui-designer via /impeccable, stack lead implementation (web, Android, iOS), accessibility-specialist review, polish with retained evidence. Uses /ux-design, /ux-review, studio templates."
argument-hint: "[UI feature description] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Skill, Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/hooks/yaml-helper.sh is_always_ask_category *), Bash(bash "*/.claude/skills/team-ui/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
# Team UI

If no argument is provided, output usage guidance and exit without spawning any agents or reading any design files:
> Usage: `/team-ui [UI feature description] [--review full|lean|solo]` — describe the screen or UI feature to build (e.g., `billing settings page`, `app shell navigation`, `onboarding checklist`). Do not use `AskUserQuestion` here; output the guidance directly.

When this skill is invoked, orchestrate the UI team through a structured pipeline.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

## Phase 0: Resolve Config

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,workflow,testing.strict,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**Which layers.** From `stack` above, work out which UI layers this feature
touches: web app (`web/`, `stack.web`), Android (`mobile/android/`), iOS
(`mobile/ios/`), marketing site (`site/`). The stack lead for each layer is
`web-lead`, `android-lead`, `ios-lead` (the site is `web-lead` too). If `stack`
is unset for a layer the feature needs, that layer is **not implemented by this
run** — say so, and recommend `/setup-stack`. Never choose a framework yourself.

`review_mode` sets director-gate depth. This pipeline's director gates are
**`DD-VISUAL`** (design-director) — spawned in Phase 2 only when the feature
introduces a new surface type, token or style decision — and **`DD-DESIGN-SYSTEM`**
when `PRODUCT.md`/`DESIGN.md` are written or revised during the run. Both are
per-skill gates: they run at `review_mode: full` and are skipped at `lean` and
`solo` (`.claude/docs/director-gates.md`, Invocation Pattern), recorded as
`[GATE-ID] skipped — [mode] mode`. A skipped gate waives the director's opinion,
never the evidence: the `/ux-review` verdict, the accessibility review and the
retained screenshots in Phases 1c, 4 and 5 are required at every mode. The
pipeline's other phase gates are its own decision points (defined under
`team.size` below).

`automation` drives the Decision Points note above. See the Decision Points note
above and `.claude/docs/automation-modes.md` for how each mode changes pipeline
behaviour.

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`** (default): `ux-designer` + the stack lead(s) for the layer(s) in scope. Other agents consulted via these, not spawned separately; visual design runs through `/impeccable` invoked in this session.
- **`small`**: + `ui-designer` (drives `/impeccable`) + `accessibility-specialist`.
- **`studio`**: + `design-director` + the layer's framework specialist (`react-specialist`, `compose-ui-specialist` or `swiftui-specialist`) + an adversarial review pass: Phase 4's reviewers are told "your job is not to confirm this matches the spec — find where it fails it", and the report says the pass ran.
A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists** — a transition under Decision Points above, or a **Gate** step written into the pipeline below — **whatever the `automation` mode.** `guided` and `autonomous` change how a gate is passed (it auto-advances, or is recorded with `log_decision`), not whether it is one, so bounded-exception condition (3) below holds at it in every mode. An agent restricted to "phase gates only" is spawned at those points and no others. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

**Announce the active set before Phase 1a — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example.

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is two agents. **The collapse is correct**: `team.size` is rigor-fronted and the
narrow default is the token lever. Without saying so, a reader cannot distinguish
a correctly-collapsed run from a broken pipeline, and the per-agent "routes
through the nearest core agent with an informational note" rule fires at routing
time and never states the shape of the run as a whole.

This is the same rule as the skipped-check reporting elsewhere in this file: **a
constraint that is enforced but never surfaced is indistinguishable, to the
person reading the output, from one that was never enforced.**

## Team Composition
- **design-director** — Owns the impeccable workflow and `PRODUCT.md` / `DESIGN.md` at the repo root; visual direction and consistency
- **ux-designer** — User flows, information architecture, states, accessibility, input handling, Arabic/English copy intent
- **ui-designer** — Screens through `/impeccable` (`shape`, new-work, `audit`, `polish`), design tokens, component specs
- **stack lead** — `web-lead`, `android-lead` or `ios-lead`: implements the UI against the UX and visual specs, routed to its specialist when present (`react-specialist`, `compose-ui-specialist`, `swiftui-specialist`)
- **accessibility-specialist** — Audits accessibility compliance at Phase 4

**Templates used by this pipeline:**
- `ux-spec.md` — Standard screen/flow UX specification
- `app-shell.md` — App shell (navigation, header, tenant switcher, notifications, banners) specification
- `interaction-pattern-library.md` — Reusable interaction patterns
- `accessibility-requirements.md` — Committed accessibility target and requirements
- `test-evidence.md` — Retained evidence for UI stories

## How to Delegate

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: design-director` — Visual direction, impeccable workflow ownership, `DD-VISUAL`
- `subagent_type: ux-designer` — User flows, states, accessibility and input handling
- `subagent_type: ui-designer` — Visual design through `/impeccable`
- `subagent_type: web-lead` / `android-lead` / `ios-lead` — Implementation per layer
- `subagent_type: react-specialist` / `compose-ui-specialist` / `swiftui-specialist` — Layer pattern validation (studio)
- `subagent_type: accessibility-specialist` — Accessibility compliance audit

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session. **Implementation files are the exception:** an agent writing code or assets first returns the files it will create or change, and its return contract names them only after you have asked once for the set and the user said yes (File Write Protocol) — that answer, not the bounded exception, authorises those writes.

**Substitute a real path for `[path]`.** Working artifacts go under
`production/ui/[feature-name]/`, the slug Phase 1b's `design/ux/[feature-name].md`
uses. One file per agent, so the parallel Phase 4 reviews never share one:

| Phase / agent | Writes to |
|---|---|
| 2 ui-designer | `production/ui/[feature-name]/visual-design.md` |
| 3 framework specialist | `production/ui/[feature-name]/stack-notes.md` |
| 3 stack lead | the code roots — the files the one implementation ask lists (File Write Protocol), outside the bounded exception |
| 4 ux-designer, ui-designer / design-director, accessibility-specialist | `production/ui/[feature-name]/review-[agent].md`, one each |
| 5 evidence | `production/qa/evidence/[story-id]/` (screenshots) and `[story-id]-evidence.md` from `test-evidence.md` |

The UX spec itself (Phase 1b), `PRODUCT.md`/`DESIGN.md` changes and any pattern-library update are under `design/` or the repo root, outside the bounded exception: `/ux-design`, `/impeccable` or the agent asks before writing them.

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or a test directory, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.

Launch independent agents in parallel where the pipeline allows it (e.g., Phase 4 review agents run simultaneously) — issue every independent `Agent` call before waiting for any result.

## Pipeline

### Phase 1a: Context Gathering

Before designing anything, read and synthesize:
- **`PRODUCT.md` at the repo root** — register, users, tone; the owner is `design-director`
- **`DESIGN.md` at the repo root** — tokens, components, visual rules (may legitimately be absent for a new product; `/impeccable document` produces it from code)
- `design/product-brief.md` — audience, platforms, pricing model, distribution (hosted and/or self-hosted)
- `design/specs/<feature>.md` — the relevant UI Requirements and acceptance criteria
- `design/user-journey.md` or the journey sections of the spec — the user's state and context when they reach this screen
- `design/ux/interaction-patterns.md` — existing patterns to reuse (not reinvent)
- `design/accessibility-requirements.md` — the committed accessibility target
- `design/localization/` — locale list, glossary, numerals policy (Arabic and English; RTL is a requirement, not an option)
- `design/ux/app-shell.md` — when the feature lives inside the shell

**Report the status of every document above before designing anything**, each as
present or ABSENT.

**`PRODUCT.md` is a precondition.** If it is absent, this pipeline does not
author UI: stop and route to `/impeccable init` (design-director owns it) — then
re-run. Verdict: **BLOCKED** — no `PRODUCT.md`.

**`design/accessibility-requirements.md` is the one that must not pass
silently.** It carries the committed accessibility target, which **Phase 3
implements against** and **Phase 4 gates on** ("verify compliance against the
committed target … flag any violations as blockers"). If the file is missing
there is no committed target, so that gate has no criterion and would pass while
checking nothing — a gate made of an absent standard, the same shape as an
assertion that can never fail. (`project.yaml` `accessibility.target` is a
default setting, not the committed document, and does not replace it.) When it
is absent:
- Say so here, and carry it forward: **Phase 4 must report
  `Accessibility: NOT ASSESSED — no committed target (design/accessibility-requirements.md absent)`
  and must NOT report the accessibility gate as passed.**
- The ux-designer states which target they designed against as an explicit
  assumption, so a later reader can see it was assumed rather than committed.
- Recommend `/ux-design accessibility` to establish the target.

Absence of `design/localization/`, the journey document, `DESIGN.md` or
`design/ux/app-shell.md` is not blocking, but name each missing one in the brief
you pass to the ux-designer so they design knowing what context they lack,
rather than inferring it. A missing `design/localization/` means Arabic copy and
numerals are provisional — carry that into Phase 4.

**If `design/ux/interaction-patterns.md` does not exist**, surface the gap immediately:
> "interaction-patterns.md does not exist — no existing patterns to reuse."

Then use `AskUserQuestion` with options:
- (a) Run `/ux-design patterns` first to establish the pattern library, then continue
- (b) Proceed without the pattern library — the stack lead will treat all patterns created as new and add each to a new `design/ux/interaction-patterns.md` at completion

Do NOT invent or assume patterns from the feature name or spec alone. If the user chooses (b), explicitly instruct the stack lead in Phase 3 to treat all patterns as new and document them in `design/ux/interaction-patterns.md` when implementation is complete. Note the pattern library status (created / absent / updated) in the final summary report.

Summarize the context in a brief for the ux-designer: what the user is doing, what they need, what constraints apply (roles, plans, tenant context, offline, locale), and which existing patterns are relevant.

### Phase 1b: UX Spec Authoring

Invoke `/ux-design [feature name]` skill OR delegate directly to `ux-designer` to produce `design/ux/[feature-name].md` following the `ux-spec.md` template. Every spec states, for each screen: the states (loading, empty, error, forbidden, offline, partial), roles and plan gating (what a user without permission or entitlement sees), Arabic/RTL behaviour and the English/Arabic copy intent.

If designing the app shell, use `app-shell.md` instead of `ux-spec.md`.

> **Notes on special cases:**
> - For the app shell specifically, invoke `/ux-design` with `argument: shell`.
> - For the interaction pattern library, run `/ux-design patterns` once at project start and update it whenever new patterns are introduced during later phases.

Output: `design/ux/[feature-name].md` with all required spec sections filled.

### Phase 1c: UX Review

After the spec is complete, invoke `/ux-review design/ux/[feature-name].md`.

**Gate**: Do not proceed to Phase 2 until the verdict is APPROVED. If the verdict is NEEDS REVISION, the ux-designer must address the flagged issues in the same spec — it is kept and revised, never discarded — and re-run the review. The user may explicitly accept a NEEDS REVISION risk and proceed, but this must be a conscious decision — present the specific concerns via `AskUserQuestion` before asking whether to proceed.

A **NOT ASSESSED** verdict blocks the same way, and the user may override it the same way. Its fix is an input, not a revision: present the dimensions `/ux-review` could not assess and the missing input for each (e.g. `/ux-design accessibility` for an uncommitted target). Re-running the review without that input returns the same verdict, so offer to produce the input first.

When the user proceeds past NEEDS REVISION or NOT ASSESSED, the final report records the override: the verdict, the concerns or unassessed dimensions left open, and that the user chose to proceed.

### Phase 2: Visual Design

Delegate to **ui-designer** (at `individual`, run `/impeccable` yourself in this session with the same inputs):
- Review the full UX spec (flows, states, interaction patterns, accessibility and RTL notes) — not just the wireframes
- Run `/impeccable shape [feature]` to plan the UX/UI, then the new-work flow for the surface, applying `PRODUCT.md` and `DESIGN.md`. Mode follows the surface (app UI is *Operate*; marketing pages are *Persuade*). The brief wins: pinned aesthetics in `PRODUCT.md`/`DESIGN.md` are honoured
- Apply the design tokens already in `DESIGN.md`; a **new token, component family or surface style** is a design-system decision: flag it for `design-director`, and when `review_mode` is `full` spawn `design-director` for **`DD-VISUAL`** (pass the gate file path `.claude/docs/director-gates/dd-visual.md`, instruct the agent to read it first, and pass the decision, `DESIGN.md` and the audit result). If `PRODUCT.md`/`DESIGN.md` were written or revised, spawn **`DD-DESIGN-SYSTEM`** the same way before production proceeds. Record skips as `[GATE-ID] skipped — [mode] mode`
- Check that the visual design preserves accessibility compliance: contrast ratios, colour never the only indicator of state (shape, text or icon reinforces it), focus visibility, touch/target sizes
- Design **both directions**: Arabic RTL layout, mirrored directional icons, Arabic type with line height and weight that read well, numerals per the locale policy; plus light/dark if the product supports it
- Specify asset needs (icons, illustrations, fonts) with dimensions and formats; produce through impeccable's asset flow where applicable
- Ensure consistency with existing implemented screens
- Output: visual design spec with style notes and asset manifest

### Phase 3: Implementation

Before implementation begins, at `studio` size spawn the layer's **framework specialist** (`react-specialist` for web, `compose-ui-specialist` for Android, `swiftui-specialist` for iOS) to review the UX and visual specs for implementation guidance:
- Component structure and state placement for this layer; routing/navigation implications
- Gotchas for the proposed layout, RTL mirroring and interaction patterns in this layer's framework
- Anything the specs assume that the stack reference does not support — `NOT SOURCEABLE — [what] is not covered by docs/stack-reference/[layer]/` — never filled from memory
- Output: implementation notes to hand off to the stack lead before they begin

If `stack` is unset for the layer, skip this step and the layer. **Record ``Stack validation: NOT ASSESSED — no stack configured for [layer] (`stack` unset in `project.yaml`)`` in this run's output.** A skipped check that says nothing is indistinguishable from a check that passed; the reader cannot tell stack guidance was never sought. Below `studio` size the specialist is not spawned: record `Framework specialist: not spawned (team.size: [size])` and consult the layer's stack reference directly.

Delegate to the **stack lead** (`web-lead`, `android-lead`, `ios-lead`):
- Implement the UI following the UX spec and visual design spec, against the layer's stack reference (`docs/stack-reference/<layer>/` and `pins.yaml`) — no API, component or config key from memory
- **Use patterns from `design/ux/interaction-patterns.md`** — do not reinvent patterns already specified. If a pattern almost fits but needs modification, note the deviation and flag it for ux-designer review
- **The UI holds no business rules and never trusts itself for authorisation.** Display and emit actions; permission- and plan-gated UI is a convenience — the server enforces. Data comes through the generated client from `contracts/`, never hand-built requests
- **All user-facing text goes through the i18n mechanism** (ADR per layer) — no hardcoded strings, Arabic and English keys added together with translator notes; logical CSS properties / `start`-`end` / `leading`-`trailing`; numbers, dates and money through locale formatters
- Every screen implements its states: loading, empty, error (problem-details mapped to messages), forbidden, offline/partial where applicable; no stack traces or internal IDs shown
- Implement accessibility features per the committed target in `design/accessibility-requirements.md`: semantics, keyboard-only operation (web), screen reader labels (TalkBack, VoiceOver, ARIA), focus order in RTL, reduced motion, text scaling/Dynamic Type
- Touch only what is in scope; secrets never in the client bundle; telemetry carries no PII
- **If any new interaction pattern is created during implementation**, add it to `design/ux/interaction-patterns.md` before marking implementation complete
- On the web, run `/impeccable audit [target]` and fix its findings, then `/impeccable polish [target]` (`.claude/docs/run-and-observe.md` §3); on Android/iOS use impeccable's native references. Attach the audit summary to the evidence folder
- Output: implemented UI feature, unit/component tests per the layer's standard, and the files list

### Phase 4: Review (parallel)

Delegate in parallel:
- **ux-designer**: Verify the implementation matches the wireframes, states and interaction spec on the running stack. Test keyboard-only navigation (web), and the full flow in English and Arabic. Check that the roles/plan gating behaves (forbidden and upsell states).
- **ui-designer** (or **design-director** at `studio`): Verify visual consistency with `DESIGN.md` and `PRODUCT.md`. Check desktop (1440 px) and mobile (390 px) on the web, small and large devices on Android/iOS, light/dark where supported, and Arabic RTL mirroring.
- **accessibility-specialist**: Verify compliance against the committed target documented in `design/accessibility-requirements.md`; screen reader pass (web screen reader, TalkBack, VoiceOver as applicable), contrast, focus, motion, text scaling. Flag any violations as blockers. **If that file is absent there is no committed target, so this gate has no criterion: report `Accessibility: NOT ASSESSED — no committed target (design/accessibility-requirements.md absent)` and do NOT report the gate as passed**. Carry forward whatever target Phase 1a recorded as assumed, and say plainly that it was assumed. At `individual` size the accessibility-specialist is not spawned: report `Accessibility review: not run (team.size: individual)` and `Accessibility: NOT ASSESSED` — never as passed.

At `studio` size, instruct each reviewer: "Your job is not to confirm this matches the spec — find where it fails it," and state in the report that the adversarial pass ran.

All review streams must report before proceeding to Phase 5.

### Phase 5: Polish and Evidence

- Address all review feedback
- Verify animations are skippable and respect the user's reduced-motion preference
- Test at all supported breakpoints/device classes and in both languages (Arabic RTL, English); confirm text expansion and truncation behave
- **Evidence owner.** The **stack lead** runs the app and captures the screenshots at every `team.size` (it is the one agent that is always active and has the tools); `ui-designer`/`/impeccable` supplies the audit summary — at `individual` this session runs `/impeccable audit` and attaches it. The orchestrator confirms each file is on disk, then asks "May I write the evidence for [story titles] to `production/qa/evidence/`?" before the `-evidence.md` document is written
- **Capture and retain evidence in `production/qa/evidence/[story-id]/`** (`.claude/docs/run-and-observe.md`): full-page screenshots of every screen touched — web desktop (1440 px) and mobile (390 px), light and dark if supported, **Arabic (RTL) and English**; native: each touched screen, plus RTL and (iOS) Dynamic Type large — plus the `/impeccable audit` summary and the negative-path screenshot (forbidden/error state). Write `production/qa/evidence/[story-id]-evidence.md` from `.claude/docs/templates/test-evidence.md`, sign-off rows left **unchecked** unless the sign-off happened in this session. A screenshot that was captured and discarded is an assertion, not evidence; a UI story with no retained screenshots is reported as **missing evidence**, not done
- **Verify `design/ux/interaction-patterns.md` is up to date** — any new pattern introduced during this feature is added
- **Confirm the app shell conventions** (navigation, tenant switcher, notifications, banners) are respected where the feature lives in the shell
- Component/unit tests pass; UI tests (Playwright, Compose UI, XCUITest as the stack uses) cover the critical journey where the story requires it — commands from the product's own scripts, never from memory

## Quick Reference — When to Use Which Skill

- `/ux-design` — Author a new UX spec for a screen, flow, or app shell from scratch
- `/ux-review` — Validate a completed UX spec before implementation
- `/team-ui [feature]` — Full pipeline from context through polish (calls `/ux-design` and `/ux-review` internally)
- `/quick-spec` — Small UI changes that don't need a full new UX spec
- `/impeccable` — Direct design commands (`audit`, `polish`, `critique`, `harden`, ...) on an existing surface

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is usually still
there.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** A skipped agent's section stays a named gap — never fill it with content of your own. Full procedure: `.claude/docs/error-recovery-protocol.md`.

Common blockers:
- Input file missing (story not found, spec absent, `PRODUCT.md` absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; once it is decided, accept it with `/architecture-decision accept ADR-NNNN`
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess
- Dev stack will not come up for run-and-observe → that is the finding; capture the logs and stop Phase 5

## File Write Protocol

All file writes (UX specs, interaction pattern library updates, implementation files) are
delegated to sub-agents and sub-skills. The two follow **different** rules:

- **Sub-agents spawned via `Agent`** (e.g. the stack lead) follow the **bounded
  exception** documented above under "Why this does not violate the Collaboration
  Protocol" — the path is one you named, the artifact is new under `production/`,
  `docs/` or a test directory, and the phase is gated by an `AskUserQuestion`. A
  sub-agent does **not** prompt per write inside those bounds; outside them it must ask.
  **Implementation files** (the stack lead's code under the code roots) are outside
  those bounds: the stack lead returns the files it will create or change, you ask
  once for the set, and it writes after a yes.
- **Sub-skills** (`/ux-design`, `/impeccable`) are not sub-agents and the exception does not reach
  them. They follow the normal Collaboration Protocol and ask before writing.

This orchestrator writes only its evidence record and checkpoint block, after asking. Commands for builds, tests and the dev stack are run by the stack lead with its own tools; `/impeccable audit` and `/ux-design` are sub-skills run through `Skill`.

## Output

A summary report covering: UX spec status, UX review verdict, visual design status, gates run or skipped by mode, implementation status per layer, accessibility compliance, Arabic/RTL and English coverage, evidence retained, interaction pattern library update status, and any outstanding issues.

Verdict: **COMPLETE** — UI feature delivered through full pipeline (UX spec → visual → implementation → review → polish with retained evidence).

If the accessibility gate (no committed target) or the stack validation (no stack configured for a layer) was NOT ASSESSED, the verdict names each one — never a plain COMPLETE. If a UI story has no retained screenshots the verdict is `BLOCKED — retained evidence missing for [story]` when `testing.strict.ui` is true or unset (UI evidence blocks by default), and `COMPLETE — retained evidence NOT ASSESSED ([story])` only when `testing.strict.ui` is explicitly false:

Verdict: **COMPLETE — [accessibility | stack validation] NOT ASSESSED ([reason])** — UI feature delivered; the named check could not run.

Verdict: **BLOCKED** — pipeline halted (no `PRODUCT.md`, unresolved blocker); surface the blocker and its phase before stopping.

Verdict: **BLOCKED — write declined by user** — the user declined the implementation file set or the evidence write; nothing is reported as COMPLETE.

## Next Steps

**Checkpoint.** Before the final message, update `production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`: Current task `/team-ui <screen> — <verdict>`, Next step = the first item below that applies (`/ux-review` if the spec is not yet approved), plus Blocked on / Files in progress / Open questions; append the Notes line; leave the `Flow:` line and other blocks alone. Still updated for BLOCKED and a declined write.

- Run `/ux-review` on the final spec if not yet approved.
- Run `/code-review` on the UI implementation, then `/story-done` (UI stories close on the retained screenshots and audit).
- Run `/localize qa` for the Arabic pass if translations were delivered during this run.
- Run `/team-hardening` if a pre-release hardening pass is needed.
