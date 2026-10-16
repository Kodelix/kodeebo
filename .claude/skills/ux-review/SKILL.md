---
name: ux-review
description: "Validate a UX spec, app shell or pattern library — accessibility target, RTL, states, spec alignment, pattern compliance, readiness. APPROVED / NOT ASSESSED / NEEDS REVISION / MAJOR REVISION NEEDED."
argument-hint: "[file-path or 'all' or 'shell' or 'patterns']"
user-invocable: true
allowed-tools: Read, Glob, Grep, AskUserQuestion, Bash(date *), Bash(bash "*/.claude/skills/ux-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,system_overrides,stack,accessibility.target`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

# UX Review

## Overview

Validates UX design documents before they enter the implementation pipeline.
Acts as the quality gate between UX Design and Visual Design/Implementation in
the `/team-ui` pipeline: after this, the spec goes to `/impeccable` (against
`PRODUCT.md` and `DESIGN.md`) and to the stack lead who builds it.

**Run this skill:**
- After completing a UX spec with `/ux-design`
- Before handing off to `web-lead`, `android-lead`, `ios-lead` or `ui-designer`
- Before a phase gate that requires key screens to have reviewed UX specs
- After major revisions to a UX spec

**Verdict levels:**
- **APPROVED** — spec is complete, consistent, and implementation-ready
- **NOT ASSESSED** — one or more review dimensions had no criterion to check
  against, or the spec could not be read; name which
- **NEEDS REVISION** — specific gaps found; fix before handoff but not a full redesign
- **MAJOR REVISION NEEDED** — fundamental issues with scope, user need, or
  completeness; needs significant rework

**`NOT ASSESSED` ranks above APPROVED and below the two revision verdicts.** A
review that could not evaluate a dimension has not shown the spec is
implementation-ready; but a gap somebody found is more actionable than one nobody
could look for, so it must not displace them. Emit it when the spec file cannot
be read, when a checklist dimension has no source of truth to compare against, or
when the accessibility target is uncommitted (below). A review dimension that did
not run is named in the output — never silently omitted.

**Workflow tier** (`.claude/docs/workflow-modes.md`): UX specs are required per
screen at `full`, for core screens at `standard`, and voluntary at `minimal`. The
tier decides what is *expected to exist*, not how strictly an existing spec is
judged — a spec that exists is reviewed in full. The tier scales documents,
never engineering: accessibility and tenant isolation are checked at every tier.

---

## Phase 1: Parse Arguments

- **Specific file path** (e.g., `/ux-review design/ux/invoice-list.md`): validate
  that one document
- **`all`**: find all files in `design/ux/` and validate each
- **`shell`**: validate `design/ux/app-shell.md` specifically
- **`patterns`**: validate `design/ux/interaction-patterns.md` specifically
- **No argument**: ask which spec to validate with `AskUserQuestion` (options: the
  files found under `design/ux/`, `all`, `shell`, `patterns`). If the user does not
  answer, stop with the verdict **NOT ASSESSED — no spec chosen**

For `all`, output a summary table first (file | verdict | primary issue) then
full detail for each. If `design/ux/` is empty or absent the verdict is
**NOT ASSESSED — no UX specs to review**; say so rather than reporting an empty
pass.

**Which checklist a file gets** (a file path, or each file under `all`): its
`> **Template**:` header line, which `/ux-design` writes — `UX Spec` → Phase 3A,
`App Shell` → 3B, `Interaction Pattern Library` → 3C. A file without that line
is classified by name — `app-shell.md` → 3B, `interaction-patterns.md` → 3C,
anything else → 3A — and the report says which checklist it assumed, and why.

---

## Phase 2: Load Cross-Reference Context

Before validating any spec, load, and record each as FOUND or ABSENT:

1. **Surfaces**: `stack` from the resolved config (web, Android, iOS, KMP, self-hosted
   admin) — the authoritative source for the Input Method and Surface checks in
   Phase 3A, not the spec's own header. If `stack` is empty, fall back to the spec
   header and say so.
2. The accessibility target committed to in `design/accessibility-requirements.md`
   (if it exists): A, AA (default) or AA+, with any elevated criteria. Also read
   the resolved `accessibility.target` (`none|wcag-a|wcag-aa|wcag-aaa`) from the
   config block: it is the project's *default*, not the commitment. Where both
   exist and disagree (for example the document commits to A while the setting is
   `wcag-aa`), list the mismatch under Quality Issues as ADVISORY. `none` is
   reported as a gap, never silently accepted
3. The interaction pattern library at `design/ux/interaction-patterns.md` (if it exists)
4. The feature specs referenced in the UX spec's `Related Specs` header (read
   their Detailed Behaviour, Data & Contracts, NFR and Acceptance Criteria)
5. The user journey map at `design/user-journey.md` (if it exists), for
   context-arrival validation
6. `PRODUCT.md` and `DESIGN.md` at the repo root (existence only, plus the names
   of the tokens/components the spec references)
7. The roles, plans and entitlement keys: `design/registry/entities.yaml` and the
   pricing model, to confirm that the role and plan names and entitlement keys the
   spec cites exist
8. `contracts/` (operation names and problem `code`s) for the actions in Section 9
9. `design/localization/` (locale list) for the RTL/locale checks

---

## Phase 3A: UX Spec Validation Checklist

Run all checks against a `ux-spec.md`-based document.

### Completeness (required sections)

- [ ] Document header present with Status, Author, Surface Target, Related Specs, Accessibility target
- [ ] 1 Purpose & User Need — has a user-perspective need statement (not
  developer-perspective)
- [ ] 2 User Context on Arrival — describes the user's role, plan, tenant state and prior activity
- [ ] 3 Navigation Position — shows where the screen sits in the hierarchy, with route/deep link
- [ ] 4 Entry & Exit Points — all entry sources and exit destinations documented, including direct URL by an unauthorized user
- [ ] 5 Layout Specification — zones defined, component inventory table present
- [ ] 6 States & Variants — at minimum: loading, empty (first use), empty (no results), populated and error; plus the permission and plan variants
- [ ] 7 Interaction Map — covers all target surfaces/inputs (check Surface Target and `stack`)
- [ ] 8 Data Requirements — every displayed data element has an owning context/operation and a read/write marker
- [ ] 9 Actions & Events — every state-changing action has an API call, error handling per problem `code`, idempotency and an analytics event or null explanation
- [ ] 10 Transitions & Animations — at least enter/exit transitions and a reduced-motion behaviour
- [ ] 11 Input Method Completeness Checklist — a block for each input method on the Surface Target; any unticked item is listed under Open Questions
- [ ] 12 Accessibility — screen-level requirements present (contrast table, focus order, announcements)
- [ ] 13 Localization Considerations — max character counts for text elements, RTL behaviour per element
- [ ] 14 Acceptance Criteria — at least 5 specific testable criteria
- [ ] 15 Open Questions — owners and deadlines; an Approved spec has none unresolved

### Quality Checks

**User Need Clarity**
- [ ] Purpose is written from the user's perspective, not system/developer perspective
- [ ] User goal on arrival is unambiguous ("The user arrives wanting to ___")
- [ ] The arrival context is specific (role, plan, state), not just "they opened the page"

**Completeness of States**
- [ ] Error state is documented (not just happy path), with the problem `code` -> message mapping
- [ ] Empty states are documented (first use *and* no results — they differ)
- [ ] Loading state is documented if the screen fetches async data, without layout shift
- [ ] **Forbidden** state documented (role lacks permission) and **not-found** state that does not reveal other tenants' records
- [ ] **Plan states** documented where the screen is gated: feature not in plan (upgrade prompt), quota reached, at-80% warning
- [ ] **Billing/tenant states** documented: trial ended / past due / suspended read-only variants
- [ ] Offline or stale/conflict (412) handling documented where the screen writes
- [ ] Any state with a timer or auto-dismiss is documented with duration

**Roles, Plans and Tenancy**
- [ ] Every role cited exists in the feature spec / registry; each role's view is stated (visible, hidden, disabled with reason)
- [ ] Every plan gate cites an entitlement key from the pricing model — no literal limit, price or plan name hardcoded in the spec
- [ ] No data element or action crosses tenants; the cross-tenant acceptance criterion is present for tenant data
- [ ] Sensitive actions (delete, role change, billing change, secret reveal, export) name their confirmation pattern; a sensitive screen links its threat model

**Input Method Coverage**
- [ ] Web: keyboard-only navigation fully specified (Tab order mirrored for RTL, Esc, focus trap and return in dialogs)
- [ ] Mobile surfaces: touch target sizes (48 dp / 44 pt), gesture alternatives, software keyboard and IME composition for Arabic
- [ ] No interaction requires hover-only or drag-only access without an alternative
- [ ] Focus order is defined (numbered, covering every interactive element)

**Data Architecture**
- [ ] No data element has "UI" listed as the owner of server state; money displayed comes from server `amount_minor` + `currency`, never recomputed
- [ ] Update/refresh behaviour is specified for time-sensitive data (what triggers refetch?)
- [ ] Null handling is specified for all data elements (what shows when data is unavailable?)
- [ ] Every action names a `contracts/` operation or is flagged "contract needed"

**Accessibility** (see also the Accessibility dimension below)
- [ ] The target from `accessibility-requirements.md` is matched or exceeded
- [ ] At every target: no colour-only information indicators; keyboard operable without traps; text alternatives
- [ ] At AA and AA+: contrast ratios specified (4.5:1 text, 3:1 large text and UI components), focus not obscured, target size at least 24x24 CSS px, reflow at 320 px and 200% zoom, accessible authentication and redundant-entry avoidance on forms
- [ ] At AA+: named AAA criteria addressed for the named flows (e.g. enhanced contrast, reading level on billing and onboarding)
- [ ] Screen reader announcements for key state changes (saved, error, results loaded, route changed) with mechanism and localized text
- [ ] Reduced-motion alternative for every animation

**Localization and RTL**
- [ ] Arabic (RTL) and English (LTR) both specified; mirroring stated element by element, including direction-implying icons
- [ ] Character limits and 40% expansion accommodation for layout-critical text
- [ ] Dates, numbers, currency formatted per locale; mixed-direction content (emails, URLs, IDs) isolated
- [ ] No text in images; server errors localized from `code`, not `detail`

**Feature-Spec Alignment**
- [ ] Every UI-relevant requirement in the referenced feature spec(s) is addressed in this spec
- [ ] No UI element displays or modifies data without a corresponding feature-spec requirement
- [ ] Negative cases from the spec (wrong role, other tenant, over quota, provider down) each have a state

**Pattern Library Consistency**
- [ ] All interactive components reference the pattern library by name (or note they are new patterns)
- [ ] No pattern behaviour is re-specified from scratch if it already exists in the library
- [ ] Any new patterns invented in this spec are flagged for addition to the library

**Design-System Boundary** (impeccable)
- [ ] Styling is referenced from `DESIGN.md` by token/component name — the spec defines no colours, type scales, radii or motion values of its own
- [ ] `PRODUCT.md` exists at the repo root (if absent: BLOCKING — route to `/impeccable init` with `design-director`)

**Acceptance Criteria Quality**
- [ ] Criteria are specific enough for a QA tester who hasn't seen the design docs
- [ ] Performance criterion present (first meaningful content / interaction latency)
- [ ] Layout criterion present at 1440, 768 and 390 px and in RTL
- [ ] Cross-tenant and role/plan criteria present where applicable
- [ ] The UI evidence criterion is present: retained screenshot of each screen and a `/impeccable audit` result
- [ ] No criterion requires reading another document to evaluate

---

## Phase 3B: App Shell Validation Checklist

Run all checks against an `app-shell.md`-based document.

### Completeness

- [ ] Shell Philosophy defined, consistent with `PRODUCT.md`
- [ ] Information Architecture covers ALL navigation entries, widgets, notifications and banners that the feature specs expose (cross-check each feature spec's UI mentions and `design/specs/domain-map.md`), or states a justified absence
- [ ] Layout Regions defined with a responsive description for each target surface and breakpoint
- [ ] Every shell component has a full specification (region, visibility trigger, data source, priority, roles/plans that see it)
- [ ] Shell States by Context covers at minimum: first use, normal, trial, past due / suspended, near-quota, maintenance, offline — and per-role variants
- [ ] Information Hierarchy gives every shell element a priority tier (MUST KEEP / SHOULD KEEP / CAN COLLAPSE / CAN HIDE)
- [ ] Visual & Performance Budget defined (max elements, screen share, payload contribution against the perf budget)
- [ ] Surface Adaptation covers all target surfaces
- [ ] Accessibility: landmarks, skip links, focus on route change, 200% text scaling, motion, preferences
- [ ] Localization & Direction: full RTL mirroring of the shell
- [ ] Configuration lists adjustable shell settings with ranges and defaults
- [ ] Acceptance Criteria — at least 5 specific testable criteria

### Quality Checks

- [ ] The tenant/workspace switcher changes scope without leaking the previous tenant's data (criterion present)
- [ ] Every entry gated by role or plan cites the permission or entitlement key
- [ ] Global banners have precedence and queue/priority behaviour defined (security > billing > maintenance > promotional, or the product's stated order)
- [ ] Notifications in the Feedback section have queue/priority behaviour defined
- [ ] No shell element is colour-only; every status has a non-colour cue
- [ ] Shell budget compliance: total simultaneous elements is within budget

### Feature Alignment

- [ ] Every feature in `design/specs/domain-map.md` with a UI entry point has representation in the shell (or justified absence)

---

## Phase 3C: Pattern Library Validation Checklist

- [ ] Pattern catalog index is current (matches actual patterns in the document)
- [ ] All standard control patterns are specified: button variants (primary, secondary, destructive), toggle, slider, select/combobox, list item, data table, modal, confirmation dialog, toast, tooltip, progress, input field, tab bar, scroll/pagination
- [ ] All SaaS-specific patterns needed by current UX specs are present: form & validation, wizard, filter bar, bulk actions, inline edit, plan gate / upgrade prompt, quota / usage meter, permission-denied & not-found, async job status, sensitive value reveal, banner
- [ ] Each pattern has: When to Use, When NOT to Use, full state specification, accessibility spec (role, name, announcements, target size), RTL behaviour, and implementation notes
- [ ] Destructive and sensitive patterns name their confirmation; the not-found pattern does not reveal the existence of other tenants' records
- [ ] Animation Standards present, with reduced-motion behaviour
- [ ] Feedback Channels Beyond Visuals (announcements, haptics where applicable) present
- [ ] Direction and Locale Standards present
- [ ] No conflicting behaviours between patterns (e.g., "Back"/Esc/cancel behaviour consistent across all navigation and dialog patterns)
- [ ] No visual styling (colour, radius, type) defined here — it belongs in `DESIGN.md`

---

## Phase 4: Output the Verdict

```markdown
## UX Review: [Document Name]
**Date**: [date]
**Reviewer**: ux-review skill
**Document**: [file path]
**Checklist**: [3A / 3B / 3C — from its Template line, or assumed from the file name]
**Surface Target**: [from header, checked against `stack`]
**Accessibility Target**: [from accessibility-requirements.md, or "assumed from header" / "none"]
**Inputs**: [each Phase 2 input: FOUND / ABSENT]

### Completeness: [X/Y sections present]
- [x] 1 Purpose & User Need
- [ ] 6 States & Variants — MISSING: forbidden and plan-limit states not documented

### Quality Issues: [N found]
1. **[Issue title]** [BLOCKING / ADVISORY]
   - What's wrong: [specific description]
   - Where: [section name]
   - Fix: [specific action to take]

### Spec Alignment: [ALIGNED / GAPS FOUND / NOT ASSESSED / N/A]
- Feature spec [name] UI requirements — [X/Y requirements covered]
- Missing: [list any uncovered requirements]

### Accessibility: [COMPLIANT / GAPS / NON-COMPLIANT / NOT ASSESSED]
- Target: [A / AA / AA+]
- [list specific accessibility findings]

### Pattern Library: [CONSISTENT / INCONSISTENCIES FOUND / NOT ASSESSED / N/A]
- [findings]

### RTL / Localization: [COMPLETE / GAPS]
- [findings]

### Verdict: APPROVED / NOT ASSESSED / NEEDS REVISION / MAJOR REVISION NEEDED
**Blocking issues**: [N] — must be resolved before implementation
**Advisory issues**: [N] — recommended but not blocking
**Dimensions not assessed**: [N] — [name each, and what would make it checkable]

[For APPROVED]: This spec is ready for handoff to `/team-ui` (visual design in
impeccable, then the stack lead).

[For NOT ASSESSED]: [N] of the review dimensions could not be evaluated:
[name them]. The spec may well be sound — this review cannot say either way for
those dimensions. [For each: the one input that would make it checkable.]
Handoff to `/team-ui` is not recommended on this result.

[For NEEDS REVISION]: Address the [N] blocking issues above, then re-run
`/ux-review`.

[For MAJOR REVISION NEEDED]: The spec has fundamental gaps in [areas].
Recommend returning to `/ux-design` to rework [sections].
```

### Dimension rules (what NOT ASSESSED and N/A mean here)

**Accessibility.** If `design/accessibility-requirements.md` is absent there is no
committed target, so this dimension has no criterion. Report
`Accessibility: NOT ASSESSED — no committed target (design/accessibility-requirements.md absent)`
and do NOT report it as COMPLIANT — a check compared against an absent standard
passes the way an assertion that can never fail passes. If the spec's own header
states a target, carry it forward as an **assumption** and say plainly that it was
assumed rather than committed. The resolved `accessibility.target` is quoted as the
configured default (`configured default wcag-aa, not committed`) and likewise
never turns the dimension into a pass. Recommend `/ux-design accessibility`.

**Spec Alignment.** Needs a feature spec to compare against. If the spec's
`Related Specs` names none and no `design/specs/<feature>.md` matches: at
`minimal` (specs not required) report `N/A — no feature spec required at this tier`
and check against the research note or product brief if the header cites one;
at `standard`/`full` report `NOT ASSESSED — no feature spec to align against`. If the
named spec file is unreadable, `NOT ASSESSED` too.

**Pattern Library.** For a UX spec or app shell, this dimension is checked against
`design/ux/interaction-patterns.md`. If that file is absent: `N/A` only where the
workflow tier does not require the library (`minimal`) — report
`Pattern Library: N/A — interaction pattern library not required at this tier`. At
any tier that requires or recommends it (`standard`, `full`), report
`Pattern Library: NOT ASSESSED — design/ux/interaction-patterns.md not found`
instead: the library is missing, not out of scope, and NOT ASSESSED counts it
against the verdict as the unresolved item it is. For a pattern library file
itself, this dimension is the 3C checklist and is never N/A.

**Dimension count.** The review has four dimensions — Completeness/Quality,
Spec Alignment, Accessibility, Pattern Library. N/A dimensions are excluded from
the count; NOT ASSESSED dimensions are listed under "Dimensions not assessed".

**Verdict selection (first match wins):**
1. Any blocking issue of the fundamental kind (user need absent or wrong, most
   required sections missing, no states beyond the happy path, a cross-tenant leak
   in the design) → **MAJOR REVISION NEEDED**
2. Any other blocking issue → **NEEDS REVISION**
3. No blocking issue, but any dimension NOT ASSESSED or the spec unreadable →
   **NOT ASSESSED**
4. Otherwise → **APPROVED**

---

## Phase 5: Collaborative Protocol

This skill is READ-ONLY — it never edits or writes files. It reports findings only.

After delivering the verdict:
- For **APPROVED**: suggest running `/team-ui` to begin implementation coordination
- For **NOT ASSESSED**: name the missing input per dimension and offer to help
  produce it (`/ux-design accessibility` for an uncommitted target,
  `/ux-design patterns` for an absent library, `/design-spec` for an absent feature
  spec). Do not re-run the review against the same missing inputs and report a
  different verdict — only new inputs change this one
- For **NEEDS REVISION**: offer to help fix specific gaps ("Would you like me to
  help draft the missing forbidden state?") — but do not auto-fix; wait for user
  instruction
- For **MAJOR REVISION NEEDED**: suggest returning to `/ux-design` with the
  specific sections to rework

Never block the user from proceeding — the verdict is advisory. Document risks,
present findings, let the user decide whether to proceed despite concerns. A user
who chooses to proceed with a NEEDS REVISION spec takes on the documented risk.
