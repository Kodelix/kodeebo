# UX Specification: [Screen / Flow Name]

> Authoring guidance: .claude/docs/templates/guidance/ux-spec-guide.md (load per-section as you author — do not read entirely).

> **Status**: Draft | In Review | Approved | Implemented
> **Author**: [Name or agent — e.g. ux-designer]
> **Last Updated**: [Date]
> **Screen / Flow Name**: [Short identifier used in code and tickets — e.g. `InvoiceListScreen`, `InviteMemberFlow`]
> **Surface Target**: [Web (desktop / mobile browser) | Android | iOS | Self-hosted admin — list all this spec covers]
> **Related Specs**: [Feature spec sections that generated this UI requirement — e.g. `design/specs/team-invitations.md § 3`]
> **Related ADRs**: [Architectural decisions that constrain this screen — e.g. `ADR-0012: Client state and caching`]
> **Related UX Specs**: [Sibling and parent screens — e.g. `team-settings.md`, `app-shell.md`]
> **Accessibility target**: [WCAG 2.2 AA | AA + AAA for named flows — per `design/accessibility-requirements.md`]
> **Design system**: [`DESIGN.md` at the repo root (impeccable) — tokens and components are referenced, not redefined]
> **Template**: UX Spec

> **Note — Scope boundary**: This template covers discrete screens and flows
> (lists, detail pages, forms, wizards, dialogs, settings, checkout, onboarding,
> emails with in-app landing). For the persistent frame around every screen
> (navigation, header, tenant switcher, notifications, global banners) use
> `app-shell.md`. A hybrid (e.g. a slide-over panel on top of a list) is a
> screen spec; note the relationship in Navigation Position.

---

## 1. Purpose & User Need

**What user need does this screen serve?**

[One paragraph — the real human need from the user's perspective, not the system function. See guide Section 1 for good/bad examples.]

**The user goal** (what the user wants to accomplish):

[One sentence, specific enough to write an acceptance criterion for.]

**The product goal** (what the product needs to communicate or capture):

[One sentence — what the system needs from this interaction, e.g. a valid email and role to create an invitation.]

---

## 2. User Context on Arrival

| Question | Answer |
|----------|--------|
| Who is the user (role, plan, tenant state)? | [e.g. admin on Team plan, 3 of 5 seats used] |
| What were they just doing? | [Prior activity / triggering state / email link] |
| What is their emotional state? | [Rushed / careful / anxious (money, data loss)] |
| What cognitive load are they carrying? | [High / low + what they are tracking] |
| What information do they already have? | [Known context on arrival] |
| What are they most likely trying to do? | [Primary use case] |
| What are they likely afraid of? | [Irreversible action, wrong charge, data exposure, losing work] |
| Device, connection and language? | [Desktop / phone; slow network; Arabic or English] |

**Emotional design target for this screen**:

[One sentence describing the feeling the user should have while using this screen.]

---

## 3. Navigation Position

**Screen hierarchy** (indentation shows parent-child relationships):

```
[Root — e.g. Dashboard]
  └── [Parent — e.g. Settings]
        └── [This Screen — e.g. Team members]
              ├── [Child — e.g. Invite member (dialog)]
              └── [Child — e.g. Member detail]
```

**Route(s)**: [`/settings/team` · deep-linkable? · query-param state (filters, page, selected id)]

**Modal behaviour**: [Page (full) | Modal (blocks behind, explicit dismiss) | Non-modal panel | Slide-over | Bottom sheet]

> If modal: document dismiss behaviour. Back button? Esc? Click outside? Can it be
> dismissed with unsaved changes? Undismissable modals are high-friction — justify them.

**Reachability — all entry points**:

| Entry Point | Triggered By | Notes |
|-------------|-------------|-------|
| [Entry point] | [Trigger: nav item, deep link, email, push notification, command palette] | [Notes] |

**Access control**: [Roles/plan/entitlement that can open this screen; what others see — hidden, disabled with reason, upgrade prompt, or 404 for other tenants]

---

## 4. Entry & Exit Points

> Every entry point must have a corresponding exit point. Empty cells mean unfinished design work.

**Entry table**:

| Trigger | Source Screen / State | Transition Type | Data Passed In | Notes |
|---------|----------------------|-----------------|----------------|-------|
| [Trigger] | [Source] | [push / replace / modal] | [route params, prefilled values] | [Notes] |

**Exit table**:

| Exit Action | Destination | Transition Type | Data Returned / Saved | Notes |
|-------------|------------|-----------------|----------------------|-------|
| [Exit action] | [Destination] | [Transition] | [committed / discarded / draft kept] | [Unsaved-changes guard?] |

---

## 5. Layout Specification

### 5.1 ASCII Wireframe

```
[Draw the layout in ASCII for the primary breakpoint, then a second sketch for
 mobile. Characters:
 ┌ ┐ └ ┘ │ ─    borders
 [ ]              interactive elements (buttons, inputs)
 { }              content areas (tables, lists, cards)
 ...              scrollable content
 ●                element focused on open
 Note where RTL mirrors.]
```

### 5.2 Layout Zones

| Zone Name | Description | Approximate Size | Scrollable? | Overflow Behaviour |
|-----------|-------------|-----------------|-------------|-------------------|
| [Zone] | [Contents and purpose] | [grid columns / % width] | [Yes/No] | [Overflow handling] |

**Responsive behaviour**:

| Breakpoint / size class | Layout change | Components that move, collapse or become sheets |
|-------------------------|---------------|-----------------------------------------------|
| >= 1280 px | | |
| 768–1279 px | | |
| < 768 px / compact | | |

### 5.3 Component Inventory

> Every discrete UI component on this screen. Each row becomes a component to build or reuse (from `DESIGN.md` / the pattern library).

| Component Name | Type | Zone | Purpose | Required? | Reuses Existing Component? |
|----------------|------|------|---------|-----------|---------------------------|
| [Component] | [Type] | [Zone] | [Purpose] | [Yes/No] | [Yes — pattern/component name, or No — new] |

**Primary focus element on open**: [Element that receives focus on open, including deep-link and empty-state cases]

### 5.4 Information Hierarchy

[What the user must see first, second, and what can wait behind a tab, a scroll or a button — with the reason for each.]

---

## 6. States & Variants

> Document every state before implementation — at minimum: loading, empty,
> populated, error, and the permission/plan variants. This table is the QA test matrix.

| State Name | Trigger | What Changes Visually | What Changes Behaviourally | Notes |
|------------|---------|----------------------|---------------------------|-------|
| [Loading (skeleton) · Empty (first-use) · Empty (filtered, no results) · Populated · Partially loaded · Validating · Submitting · Success · Validation error · Server error · Offline · Forbidden · Not found · Plan-limit reached · Read-only (past due / trial ended) · Stale/conflict (412)] | [Trigger] | [Visual changes] | [Behavioural changes] | [Copy key, retry affordance] |

---

## 7. Interaction Map

> Cover every input method for the surface targets (mouse, keyboard, touch,
> screen reader). Gaps are bugs waiting to happen.

### 7.1 Navigation Inputs

| Input | Surface | Action | Visual Response | Notes |
|-------|---------|--------|-----------------|-------|
| [Tab / Shift+Tab / arrow keys / swipe / back gesture] | [Surface] | [Action] | [Focus ring, highlight] | [Notes] |

### 7.2 Action Inputs

| Input | Surface | Context (what must be focused) | Action | Response | Animation | Notes |
|-------|---------|-------------------------------|--------|----------|-----------|-------|
| [Click / Enter / tap / long-press / shortcut] | [Surface] | [Focus context] | [Action] | [Optimistic update? confirm? toast?] | [Animation + timing] | [Debounce, double-submit protection] |

### 7.3 State-Specific Behaviours

| State | Input Restriction | Reason |
|-------|------------------|--------|
| [Submitting] | [Submit disabled; fields read-only; Esc still cancels] | [Prevent double submit] |

---

## 8. Data Requirements

> UI reads data; it does not own it. The UI sends commands through the API; it
> does not decide authorization or business rules (the server does — the UI only
> mirrors them for usability). Every displayed element needs a source and an owner.

| Data Element | Source (endpoint / contract) | Refresh policy (`staleTime`, invalidation, push) | Owner (context) | Format | Null / Missing Handling |
|--------------|-----------------------------|--------------------------------------------------|-----------------|--------|------------------------|
| [Data element] | [`GET /v1/...`] | [When it updates — specific trigger, not "realtime"] | [Owning context — never the UI] | [Type/shape; locale formatting] | [What shows when unavailable] |

> **Rule**: This screen never writes domain state locally as truth. Client caches
> are UX only; mutations invalidate affected queries; money is shown from server
> `amount_minor` + `currency`, never recomputed.

---

## 9. Actions & Events

> Every destructive or state-changing user action appears here with its API call
> and analytics event.

| User Action | API Call / Command | Success handling | Failure handling (problem `code` -> message) | Analytics event (`tracking-plan.md`) | Idempotent? |
|-------------|--------------------|------------------|----------------------------------------------|--------------------------------------|-------------|
| [Action] | [`POST /v1/...`] | [Toast, redirect, optimistic rollback] | [`plan_limit_reached` -> upgrade dialog] | [`invite_sent`] | [Idempotency-Key] |

---

## 10. Transitions & Animations

> Specify screen enter/exit and in-screen transitions, plus reduced-motion behaviour for each.

| Transition | Trigger | Direction / Type | Duration (ms) | Easing | Interruptible? | Reduced Motion Fallback |
|------------|---------|-----------------|--------------|--------|----------------|------------------------|
| [Route change / dialog open / list item add / skeleton to content] | [Trigger] | [Type] | [ms] | [Easing] | [Yes/No] | [Instant / cross-fade] |

---

## 11. Input Method Completeness Checklist

> Fill before marking Approved. Any unchecked item blocks implementation.

**Keyboard (web, tablet, desktop)**
- [ ] All interactive elements reachable with Tab/Shift+Tab; arrow keys for composite widgets (menus, tabs, grids)
- [ ] Tab order follows visual reading order, mirrored for RTL
- [ ] Every pointer action has a keyboard equivalent; no keyboard traps
- [ ] Focus is always visible (focus ring meets 3:1 contrast, not obscured by sticky headers)
- [ ] Dialogs trap focus, close on Esc, return focus to the trigger
- [ ] Shortcuts documented and non-conflicting with browser/AT shortcuts; single-key shortcuts can be turned off/remapped

**Pointer / Mouse**
- [ ] Hover and active states defined for all interactive elements; hover-only content has a keyboard/touch equivalent
- [ ] Hit targets at least 24x24 CSS px (WCAG 2.2 minimum); 44x44 preferred
- [ ] Right-click / long-press behaviour defined (context menu or native default)
- [ ] Drag-and-drop has a non-dragging alternative (WCAG 2.2 Dragging Movements)

**Touch (mobile web, Android, iOS)**
- [ ] Touch targets at least 48 dp (Android) / 44 pt (iOS)
- [ ] Gestures do not conflict with system back/edge gestures; every gesture has a visible alternative
- [ ] Key actions reachable one-handed in portrait
- [ ] Software keyboard: correct input type, autocomplete tokens, IME composition for Arabic; form scrolls so the focused field stays visible

**Assistive technology**
- [ ] Semantics: native elements first; ARIA only where needed; names, roles, values exposed
- [ ] Tested with a screen reader per surface (VoiceOver, TalkBack, one desktop reader)

---

## 12. Accessibility

> Project-wide standards live in `design/accessibility-requirements.md` — consult
> it first so you do not duplicate or contradict project commitments.
>
> Targets in this studio (the product picks one in its accessibility document):
> - AA: WCAG 2.2 Level AA across the product — the default target
> - AA+: AA plus AAA criteria for named flows (e.g. enhanced contrast, reading level on onboarding and billing)
> - A: only for internal tools, with a written reason

**Text contrast requirements for this screen**:

| Element | Background Context | Required Ratio | Current Ratio | Pass? |
|---------|-------------------|---------------|---------------|-------|
| [Text / icon / border / focus ring] | [Surface, light and dark] | [4.5:1 text, 3:1 large text and UI components] | [TBD] | [ ] |

**Colour-only information and mitigations**:

| Element | Risk | Mitigation |
|---------|------|------------|
| [Status chip, chart series, error field] | [Colour is the only differentiator] | [Icon, text, pattern] |

**Focus order** (numbered, covering every interactive element, including dialogs and cycle behaviour):

[Numbered sequence — see guide Section 12 for an example]

**Screen reader announcements for key state changes**:

| State Change | Mechanism (`role="status"` / `alert` / focus move / live region) | Announcement Text (localised) | Timing |
|--------------|------------------------------------------------------------------|-------------------------------|--------|
| [Saved / error / results loaded / route changed] | [Mechanism] | ["Announcement"] | [When it fires] |

**Forms** (if any): visible labels; instructions and errors programmatically associated; error summary with links to fields; do not rely on placeholder as label; accessible authentication (no cognitive-function test without an alternative); redundant entry avoided.

**Cognitive load assessment**:

[Count concurrent information streams and decisions; mitigations: progressive disclosure, defaults, plain language, confirmation with consequences — see guide Section 12]

---

## 13. Localization Considerations

**General rules for this screen**:
- Arabic (RTL) and English (LTR) both ship; layouts use logical properties and mirror — document which elements mirror and which do not (media controls, brand marks, numerals with units, charts' time axis per locale convention)
- Allow at least 40% expansion from the English baseline; Arabic needs more line-height and may run shorter or longer — verify
- No text in images; all copy from locale strings with ICU plural/select forms
- Dates, numbers, currency and units formatted per locale (`Intl` / platform formatters); store UTC, render in the user's time zone
- Mixed-direction content (emails, URLs, IDs, product names) isolated with bidi controls
- Server error messages are localised from `code`, not from `detail`

| Text Element | English Baseline Length | Max Characters | Expansion Budget | RTL Behaviour | Overflow Behaviour | Risk |
|--------------|------------------------|----------------|-----------------|---------------|--------------------|------|
| [Text element] | [chars] | [max chars] | [%] | [Mirror/align] | [Truncate with tooltip / wrap / scroll] | [Low/Medium/High] |

---

## 14. Acceptance Criteria

> Write criteria a QA tester can verify independently. Every criterion is binary.

**Performance**
- [ ] Route renders first meaningful content within [1.5] s on a mid-range device over fast 3G (LCP <= 2.5 s p75 in the field)
- [ ] Interaction latency (INP) <= 200 ms; no layout shift beyond CLS 0.1
- [ ] Screen issues <= [N] API calls on load, batched; lists paginate with cursors

**Layout & Rendering**
- [ ] Displays correctly (no overlap, cutoff, overflow) at 1440, 768 and 390 px
- [ ] Displays correctly in RTL (mirrored) and LTR; light and dark if supported
- [ ] All states documented in Section 6 render correctly
- [ ] No horizontal scroll at 320 CSS px; content remains usable at 200% zoom / largest system text size

**Input**
- [ ] Every interactive element reachable by keyboard alone; focus visible; no traps
- [ ] Every interactive element usable by touch with targets meeting Section 11
- [ ] Double-submit is prevented and idempotent on the server

**Actions & Data**
- [ ] All actions in Section 9 call the documented endpoint and handle each listed error `code`
- [ ] Changes persist after close and reopen; stale data is refreshed per Section 8
- [ ] A user of tenant B cannot see tenant A's data via this screen (verified with route/ID tampering)
- [ ] Role/plan variants show the specified behaviour (hidden, disabled with reason, upgrade prompt)
- [ ] Analytics events fire once per action with no PII

**Accessibility**
- [ ] All text and UI components meet Section 12 contrast ratios
- [ ] No information relies on colour alone
- [ ] Screen reader announces the documented state changes (verified on each target surface)
- [ ] Reduced-motion setting results in instant or cross-fade transitions
- [ ] `/impeccable audit` run on the implementation; findings fixed or waived with reason

**Localization**
- [ ] No text overflows its container in Arabic or English
- [ ] RTL layout correct; icons that imply direction are mirrored
- [ ] All displayed text comes from locale strings; plural forms correct

---

## 15. Open Questions

> Each question has an owner and a deadline. An Approved spec has zero open
> questions — resolve them or document the deferral rationale.

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Add question] | [Owner] | [Deadline] | [Resolution] |
