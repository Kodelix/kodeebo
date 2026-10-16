---
name: ux-design
description: "Section-by-section UX spec authoring for a screen, flow or the app shell, written to design/ux/ and feeding impeccable. Reads the user journey for context; also patterns and project-wide accessibility."
argument-hint: "[screen/flow name] or 'shell' or 'patterns' or 'accessibility'"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Agent, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash "*/.claude/skills/ux-design/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,system_overrides,docs.density,accessibility,stack`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

# UX Design

When this skill is invoked:

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**What this skill produces and what it feeds.** The UX spec defines *what a
screen must do*: purpose, navigation, zones, every state, roles and plans,
interactions, data, events, accessibility, RTL. It does **not** define how it
looks — colour, type, spacing, motion and component styling live in `DESIGN.md`,
and product register and tone in `PRODUCT.md`, both at the repo root and owned by
impeccable (`design-director`, `ui-designer`). The spec feeds
`/impeccable` (shape, craft, audit) and the stack lead who builds the screen;
tokens and components are *referenced* from `DESIGN.md`, never redefined here.

**Authoring guidance**: the skeletons in `references/3-file-skeleton.md`
are self-contained — author from them directly. When a section needs depth
(worked examples, pattern catalogs, accessibility criteria), the matching guide
has it:

| Producing | Guide |
|---|---|
| UX spec | `.claude/docs/templates/guidance/ux-spec-guide.md` |
| App shell | `.claude/docs/templates/app-shell.md` (the template carries its own guidance in each section) |
| Interaction patterns | `.claude/docs/templates/guidance/interaction-pattern-library-guide.md` (routes to topic files for standard controls and navigation/feedback) |
| Accessibility requirements | `.claude/docs/templates/guidance/accessibility-requirements-guide.md` |

**Load a guide per-section, never whole** — each is organised by section and the
pointers in the templates name the exact section to read.

**`workflow`** (see `.claude/docs/workflow-modes.md`), applied to the screen's
feature at its effective tier (`system_overrides.<feature-stem>` when listed):
- `full` — a UX spec is required per screen.
- `standard` — core screens only: sign-up/onboarding, the primary workflow and
  dashboard, billing and plan management, team/settings — plus any screen that
  moves money, changes access or deletes data.
- `minimal` — not required; the research note and `/impeccable` cover it. Can
  still be run voluntarily.

The tier scales documents, never engineering: accessibility, tenant isolation and
run-and-observe evidence (`.claude/docs/coding-standards.md`) apply at every tier.

**`docs.density`** — it controls per-section *depth*, where `workflow` controls
which screens are specced. `modes.rigor` sets both together; set `docs.density`
explicitly to vary depth alone: `terse` (the default, via `rigor: minimal`) =
wireframe + state table + interaction bullets; `balanced` = wireframes +
paragraph descriptions of flows (`rigor: standard`); `thorough` = full prose
including user-research summaries and alternative flow considerations. Apply it
to every section you author.

## 1. Parse Arguments & Determine Mode

Four authoring modes exist based on the argument:

| Argument | Mode | Output file |
|----------|------|-------------|
| `shell` | App shell (navigation, header, tenant switcher, notifications, global banners) | `design/ux/app-shell.md` |
| `patterns` | Interaction pattern library | `design/ux/interaction-patterns.md` |
| `accessibility` | Project-wide accessibility requirements | `design/accessibility-requirements.md` |
| Any other value (e.g., `invoice-list`, `invite-member`) | UX spec for a screen or flow | `design/ux/[argument].md` |
| No argument | Ask the user | (see below) |

> **`accessibility` is the only mode that writes outside `design/ux/`.** Its
> output is a project-wide standard the per-screen specs consult, not a spec for
> one screen — `/ux-review`, `/gate-check` and `/architecture-review` check
> `design/accessibility-requirements.md` at that exact path. Do not "tidy" it
> under `design/ux/`: every one of those checks would stop matching.

**If no argument is provided**, do not fail — ask instead. Use `AskUserQuestion`:
- "What are we designing today?"
  - Options: "A specific screen or flow (I'll name it)", "The app shell", "The interaction pattern library", "The project-wide accessibility requirements", "I'm not sure — help me figure it out"

If the user selects "I'll name it" or types a screen name, normalize it to kebab-case
for the filename (e.g., "Invoice List" becomes `invoice-list`).

---

## 2. Gather Context (Read Phase)

**Read `references/2-gather-context.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase. It includes the **PRODUCT.md precondition**: without `PRODUCT.md` at the repo root this skill does not author, it routes to `/impeccable init`.

## 3. Create File Skeleton

**Read `references/3-file-skeleton.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 4. Section-by-Section Authoring

**Read `references/4-authoring.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

### Section guidance — read the ONE file for the active mode

Per-section authoring guidance lives in its own file per mode. **When you reach
Phase 4, read only the file matching the mode resolved in Section 1; never load
the other two.**

| Mode | Guidance file |
|------|---------------|
| UX Spec (screen or flow) | `references/sections-ux-spec.md` |
| App shell | `references/sections-shell.md` |
| Interaction Pattern Library | `references/sections-patterns.md` |
| Accessibility Requirements | `.claude/docs/templates/guidance/accessibility-requirements-guide.md` |

> The accessibility guidance lives under `templates/guidance/` rather than this
> skill's `references/` because the template it documents
> (`.claude/docs/templates/accessibility-requirements.md`) is consumed by
> `/ux-review` and the gate files too. Same rule applies: load only the part
> covering the section you are authoring, never the whole file.

Apply `docs.density` (Section 1) to whatever that file tells you to author — it
controls the depth of each section, not which sections exist.

## 5. Cross-Reference Check and Handoff

**Read `references/5-crossref-handoff.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 6. Recovery & Resume

If the session is interrupted (compaction, crash, new session):

1. Read `production/session-state/active.md` — it records the current screen
   and which sections are complete.
2. Read `design/ux/[filename].md` — sections with real content are done;
   sections with `[To be designed]` still need work.
3. Resume from the next incomplete section — no need to re-discuss completed ones.

This is why incremental writing matters: every approved section survives any
disruption.

---

## 7. Specialist Agent Routing

This skill uses `ux-designer` as the primary agent. For specific sub-topics,
additional context or coordination may be needed:

| Topic | Coordinate with |
|-------|----------------|
| Visual aesthetics, tokens, colour, type — and `PRODUCT.md`/`DESIGN.md` | `design-director` — the UX spec defines zones and states; impeccable defines how they look |
| Component styling and implementation of visual decisions | `ui-designer` |
| Implementation feasibility (framework constraints) | the layer's lead — `web-lead`, `android-lead` or `ios-lead` — before finalizing the component inventory |
| Data ownership, endpoints a screen calls | `product-manager` for ownership; `api-designer` for the contract |
| Plan gates, upgrade prompts, quota meters, trial/past-due states | `pricing-billing-designer` — never invent a limit or price in the spec |
| Sensitive screens (auth, billing, file upload, PII, destructive actions) | `security-lead` — threat model link and confirmation requirements |
| Microcopy, error messages, empty-state text | `ux-designer` (this session) with `technical-writer` for help text |
| Arabic/English, RTL, string length | `localization-lead` |
| Accessibility target decisions | Recorded by this session (`/ux-design accessibility`; the user picks the target) against the criteria `accessibility-specialist` defines and audits — consult it when a requirement's criterion is unclear |

When delegating to another agent via the `Agent` tool:
- Provide: screen name, product-brief summary, the specific question needing expert input
- The agent returns analysis to this session
- This session presents the agent's output to the user
- The user decides; this session writes to file
- Agents do NOT write to files directly — this session owns all file writes

---

## Collaborative Protocol

**In `collaborative` mode (the default).** For `guided` and `autonomous` modes,
see the per-mode rules in `.claude/docs/automation-modes.md` — the steps below
describe what collaborative mode requires, not what applies universally.

This skill follows the collaborative design principle at every step:

1. **Question -> Options -> Decision -> Draft -> Approval** for every section
2. **AskUserQuestion** at every decision point (Explain -> Capture pattern):
   - Phase 2: "Ready to start, or need more context?"
   - Phase 3: "May I create the skeleton?"
   - Phase 4 (each section): design questions, approach options, draft approval
   - Phase 5: "Run cross-reference check? What's next?"
3. **"May I write to [filepath]?"** before the skeleton and before each section write
4. **Incremental writing**: Each section is written to file immediately after approval
5. **Session state updates**: After every section write

**Aesthetic deference**: When layout or visual choices come down to personal taste,
present the options and ask. Do not select a layout because it is "standard" —
always confirm. The user is the final design authority; `design-director` holds
visual identity.

**Conflict surfacing**: When a feature-spec requirement and the available screen
real estate (or a pattern, or a plan rule) conflict, surface the conflict and
present resolution options. Never silently drop a requirement. Never silently
expand the layout without flagging it.

**Never** auto-generate the full spec and present it as a fait accompli.
**Never** write a section without user approval.
**Never** contradict an existing approved UX spec without flagging the conflict.
**Never** state a price, quota or plan limit as a literal — cite the entitlement key from the pricing model.
**Always** show where decisions come from (feature-spec requirements, user journey, user choices).

Close with exactly one verdict:

- Verdict: **COMPLETE** — UX spec written and approved section by section, and the
  cross-reference check ran with no open gap.
- Verdict: **COMPLETE WITH GAPS** — every section is written and approved, but a named
  gap remains: a cross-reference check item that is gap or *not run (reason)*, a
  missing input recorded in Open Questions (no product brief, no user journey, no
  `DESIGN.md`, no feature spec), or a provisional assumption. List each gap.
- Verdict: **BLOCKED** — a precondition failed (no `PRODUCT.md`) or the user declined
  a write (`BLOCKED — write declined by user`); name it. Nothing is reported as
  COMPLETE after a declined write.

---

## Recommended Next Steps

- Run `/ux-review [filename]` to validate this spec before it enters the implementation pipeline
- Run `/ux-design [next-screen]` to continue designing remaining screens or flows
- Run `/impeccable shape [screen]` to take the approved spec into visual design, and `/impeccable audit` on the built screen (UI story evidence)
- Run `/gate-check` once all key screens have approved UX specs
