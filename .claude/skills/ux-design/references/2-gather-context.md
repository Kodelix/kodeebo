# /ux-design — Sections 2 and 2b: Gather Context and Retrofit Detection

> Part of `/ux-design`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 2. Gather Context (Read Phase)

**In this file:**

- 2a: Required Reads and the PRODUCT.md precondition
- 2b: User Journey
- 2c: Feature-Spec UI Requirements
- 2d: Existing UX Specs
- 2e: Interaction Pattern Library
- 2f: Design System (DESIGN.md)
- 2g: Accessibility Requirements
- 2h: Surfaces, Roles, Plans and Locales
- 2i: Present Context Summary

Read all relevant context **before** asking the user anything. The skill's value
comes from arriving informed. Any input listed here that is absent is **named in
the context summary (2i) as absent** — a missing input is never silently treated
as "nothing to consider".

### 2a: Required Reads and the PRODUCT.md precondition

- **Product brief**: Read `design/product-brief.md`. If it does not exist, warn:
  > "No product brief found. Run `/brainstorm` first to establish the product's
  > foundation before designing UX."
  Continue anyway if the user asks — a missing brief is a **warning, not a block**
  (the brief carries the ICP and principles, which sharpen the spec, but the
  spec's register, users and tone come from `PRODUCT.md`). Record "product brief
  absent when authored" in the spec's Open Questions; it makes the closing verdict
  `COMPLETE WITH GAPS`, never `COMPLETE`.

- **PRODUCT.md (hard precondition)**: check for `PRODUCT.md` at the **repo root**
  (impeccable's location; not under `design/`). It carries the product register,
  users, tone and anti-references that every screen decision depends on.

  **If it does not exist, do not author.** Stop with:
  > "`PRODUCT.md` is missing at the repo root. UX specs feed impeccable, and
  > impeccable needs the product context first. Run `/impeccable init` (with
  > `design-director`) to write it, then re-run `/ux-design [argument]`."
  Verdict: **BLOCKED** — no `PRODUCT.md`. Do not create the skeleton, do not offer
  to proceed without it, and do not draft `PRODUCT.md` here: it is impeccable's
  artifact. (Authoring the accessibility target or the pattern library in
  isolation is the one exception the *user* may choose — ask once, record it in
  the file's Open Questions as "PRODUCT.md absent when authored", never silently.)

  If it exists, read it and extract: register (product UI vs marketing), primary
  users, tone, anti-references.

### 2b: User Journey

Read `design/user-journey.md` if it exists. For each relevant section, extract:
- Which journey phase(s) does this screen appear in (discover, sign-up and first value, set-up, habitual use, expansion/upgrade, renewal, offboarding)?
- What is the user's emotional state on arrival at this screen?
- What user need is this screen serving in the journey?
- What critical moments (from the journey map) does this screen deliver?

If the user journey file does not exist, note the gap and proceed:
> "No user journey map found at `design/user-journey.md`. Designing without it
> means we'll be making assumptions about user context. Consider authoring it from
> the template after this spec is drafted."

Also add to the UX spec's Open Questions section:
> "User journey map not yet created. Author it from the template at `.claude/docs/templates/user-journey.md` to establish user context for this screen."

> **Do not tell the user to "run `/ux-design` Phase 2b" to create it.** This step
> only *reads* the file. No skill writes `design/user-journey.md`; it is
> hand-authored from its template (owner: `product-manager` / `ux-designer`).

### 2c: Feature-Spec UI Requirements

Find the feature spec(s) this screen belongs to. Scan once rather than opening
every spec:

```
Grep pattern="[screen-name]|[feature-stem]" glob="design/specs/*.md" output_mode="files_with_matches"
```

Establish the denominator first (glob `design/specs/*.md` excluding
`domain-map.md`, `review-*.md`, `spec-cross-review-*.md`; count **N**). For each
matched spec, read the sections that carry UI requirements: **Detailed Behaviour**
(states, rules, **permissions per role**), **Data & Contracts** (endpoints, errors,
events), **Non-Functional Requirements** (accessibility, localization, caching),
**Edge Cases & Failure Modes** and **Acceptance Criteria**. These are the
**requirements input** to this spec — collect them as a list of constraints the
spec must satisfy.

If designing the app shell, the shell aggregates the navigation entries, widgets,
notifications and banners that **every** feature exposes — scan all specs:

```
Grep pattern="navigation|menu|notification|banner|dashboard|widget|badge" glob="design/specs/*.md" output_mode="content" -C 1
```

**A spec with no UI mention is not a feature with no UI** — it may predate the
section or describe UI elsewhere. List the unmatched specs and confirm with the
user which are genuinely headless before excluding them; a shell that silently
omits a feature's entry point is the exact failure this aggregation exists to
prevent.

If no spec exists for the feature (typical at `rigor: minimal`), say so, take the
requirements from the product brief / research note (`docs/research/<feature>.md`),
and record "no feature spec — requirements from [source]" in the summary.

### 2d: Existing UX Specs

Glob `design/ux/*.md` and note which screens already have specs. For screens that
will link to or from the current screen, read their Navigation Position and
Entry & Exit sections to find the entry and exit points this spec must match.

### 2e: Interaction Pattern Library

If `design/ux/interaction-patterns.md` exists, read the **Pattern Catalog Index**
(the list of pattern names and one-line descriptions). Do not read full pattern
details — just the catalog. This tells you which patterns already exist so you
can reference them by name rather than reinvent them: Button (Primary/Destructive),
Modal / Confirmation Dialog, Data Table, Form & Validation, Plan Gate / Upgrade
Prompt, Quota / Usage Meter, Permission-Denied & Not-Found, Async Job Status.

### 2f: Design System

Check for `DESIGN.md` at the repo root. If found, note the tokens/components it
defines — the spec **references** them by name. If absent, note "DESIGN.md absent
— tokens and components unnamed; the spec describes structure only" and add an
Open Question routing to `/impeccable document` (existing code) or `design-director`.
Never invent tokens in the spec.

### 2g: Accessibility Requirements

Check for `design/accessibility-requirements.md`. If found, read it. The spec
must satisfy the accessibility target committed to there (default: WCAG 2.2 AA).
If absent, the spec records the gap and uses the configured
`accessibility.target` from the resolved block as the stated baseline (default
`wcag-aa` = WCAG 2.2 AA), as an Open Question for `/ux-design accessibility`.
The config value is a default, not the commitment: `none` is recorded as a gap,
never as "no requirement"; a document target that differs from the config is
noted for the user, and the document wins. Waivers are the user's decision.

### 2h: Surfaces, Roles, Plans and Locales

- **Surfaces**: read `stack` from the resolved config: web (Vite + React SPA),
  Android (Compose), iOS (SwiftUI), KMP, self-hosted admin. The spec's *Surface
  Target* and Input Method Completeness checklist cover exactly these — keyboard,
  pointer, touch, assistive technology. Do not ask what the stack already says.
- **Roles and plans**: from the feature spec and `design/registry/entities.yaml`
  (roles, permissions, plans, quotas) if present; entitlement keys from the
  pricing model if present. Every screen variant (hidden / disabled with reason /
  upgrade prompt / read-only) is keyed to these. If roles are unknown, ask once.
- **Locales**: Arabic (RTL) and English (LTR) both ship unless
  `design/localization/` says otherwise. Check it for the locale list and glossary.

If surfaces are not configured (`stack` empty), ask once:
> "The stack isn't configured. Which surfaces does this screen target?"
> Options: "Web only", "Web + mobile web", "Android", "iOS", "Web + Android + iOS"
>
> (Run `/setup-stack` to save this permanently so you won't be asked again.)

Store the answer for the rest of this session. Do **not** ask again per section.

### 2i: Present Context Summary

Before any design work, present a brief summary to the user:

> **Designing: [Screen/Flow Name]**
> - Mode: [UX Spec / App Shell / Pattern Library / Accessibility]
> - Tier: [full / standard / minimal] — [required / voluntary for this screen]
> - PRODUCT.md: [found — register / absent → blocked]; DESIGN.md: [found / absent]
> - Journey phase(s): [from user-journey.md, or "unknown — no journey map"]
> - Feature-spec requirements feeding this spec: [count and names, or "none found — source: …"]
> - Roles / plans in play: [list, or "unknown"]
> - Related screens already specced: [list, or "none yet"]
> - Known patterns available: [count, or "no pattern library yet"]
> - Accessibility target: [from requirements doc, or "not yet defined — WCAG 2.2 AA baseline"]
> - Surfaces: [derived from `stack`, or "asked above"]; Locales: [AR/EN]

Then ask: "Anything else I should read before we start, or shall we proceed?"

---

## 2b. Retrofit Mode Detection

Before creating a skeleton, check if the target output file already exists.

Glob the resolved output path from Section 1 — `design/ux/[filename].md`, or
`design/accessibility-requirements.md` in `accessibility` mode.

**If the file exists — retrofit mode:**
- Read the file in full
- For each expected section, check whether the body has real content (more than a `[To be designed]` placeholder) or is empty/placeholder
- Present a section status summary to the user:

> "Found existing UX spec at `design/ux/[filename].md`. Here's what's already done:
>
> | Section | Status |
> |---------|--------|
> | 1 Purpose & User Need | [Complete / Empty / Placeholder] |
> | 2 User Context on Arrival | ... |
> | 3 Navigation Position | ... |
> | 4 Entry & Exit Points | ... |
> | 5 Layout Specification | ... |
> | 6 States & Variants | ... |
> | 7 Interaction Map | ... |
> | 8 Data Requirements | ... |
> | 9 Actions & Events | ... |
> | 10 Transitions & Animations | ... |
> | 11 Input Method Completeness Checklist | ... |
> | 12 Accessibility | ... |
> | 13 Localization Considerations | ... |
> | 14 Acceptance Criteria | ... |
> | 15 Open Questions | ... |
>
> (Rows are the skeleton's own `##` headings for the active mode — the list above is
> UX spec mode; app shell, patterns and accessibility modes list their skeleton's headings.)
>
> I'll work on the [N] incomplete sections only — existing content will not be overwritten."

- Skip Section 3 (skeleton creation) — the file already exists
- In Section 4 (Section Authoring), only work on sections with Status: Empty or Placeholder
- Use `Edit` to fill placeholders in-place rather than creating a new skeleton

**If the file does not exist — fresh authoring mode:**
Proceed to Section 3 (Create File Skeleton) as normal.

---
