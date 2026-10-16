# Interaction Pattern Library: [Product Title]

> Authoring guidance: .claude/docs/templates/guidance/interaction-pattern-library-guide.md (load per-section as you author — do not read entirely).

> **Status**: Draft | Stable | Under Revision
> **Author**: [ux-designer]
> **Last Updated**: [Date]
> **Version**: [1.0]
> **Surfaces**: [Web (Vite + React) / Android (Compose) / iOS (SwiftUI) / KMP shared]
> **UI Framework / Component Library**: [Pinned in `docs/stack-reference/` — e.g. the web component library, Compose Material, SwiftUI]
> **Related Documents**:
> - `DESIGN.md` — visual standards (tokens: colour, type, spacing, motion; component styling) maintained with impeccable
> - `PRODUCT.md` — product register and tone
> - `design/accessibility-requirements.md` — accessibility commitments per feature
> - `design/ux/app-shell.md` — persistent frame; `design/ux/[screen].md` — screen specs that reference patterns
>
> **Template**: Interaction Pattern Library

> **Why this document exists**: Every UX spec should be able to say "uses
> Button (Primary) pattern" rather than re-specifying hover states, press
> feedback, focus behaviour, keyboard handling and screen reader announcements
> from scratch. This library is the single source of truth for reusable
> interaction behaviours. When a spec references a pattern name, the engineer
> looks it up here. When the behaviour changes, it changes here and applies
> everywhere. Visual styling (colours, radii, shadows, typography) is NOT defined
> here — it lives in `DESIGN.md`; this library defines behaviour, states,
> semantics and accessibility.
>
> This is a living document. Patterns are added as new screens are designed — do
> not design a new interaction without checking here first. If a new pattern is
> needed, add it here (or propose it to the ux-designer) before writing the first
> spec that uses it.
>
> **Status definitions**:
> - **Draft**: Interaction specified but not yet implemented or validated
> - **Stable**: Implemented, tested and validated in at least one shipped screen on every target surface
> - **Deprecated**: Being phased out — existing uses will be migrated, do not use in new screens

---

## How to Use This Library

**If you are designing a screen**: Browse the Pattern Catalog Index before
inventing new interactions. When a standard pattern fits, reference it by name in
the UX spec (e.g. "The confirm button uses Button (Primary) pattern"). When none
fits, propose a new one — document it here alongside or before the spec that
introduces it.

**If you are implementing a screen**: When a spec says "use [PatternName]
pattern," find it here for the complete specification. Implementation Notes carry
stack-specific guidance (web, Android, iOS). The Accessibility line holds
requirements that are non-negotiable.

**If you are reviewing a screen spec**: Verify that all interactive elements
reference a pattern from this library or include their own full interaction
specification. "Standard button" or "the usual way" is not a valid reference.

**If you are updating a pattern**: Changing a Stable pattern affects every screen
that uses it. Before changing, audit all usages (search UX specs for the pattern
name), determine the impact, get approval from the ux-designer, and update this
document before or simultaneously with any implementation change.

**Cross-surface rule**: A pattern behaves the same on web, Android and iOS in
intent; platform conventions (back gesture, sheets, native pickers) win over
visual sameness. Record platform differences in the pattern's Implementation Notes.

---

## Pattern Catalog Index

> Add a row every time a new pattern is added. The "Used In" column is the usages
> audit trail — update it when new screens adopt the pattern.

| Pattern Name | Category | Description | Used In (Screens) | Status |
|-------------|----------|-------------|------------------|--------|
| Button (Primary) | Input | The single most important action on a screen — at most one visible at a time | [Screens] | Draft |
| Button (Secondary) | Input | Alternative or cancel action — lower visual weight than Primary | [Screens] | Draft |
| Button (Destructive) | Input | Irreversible actions that remove data or access (delete, remove member, revoke key, cancel subscription) | [Screens] | Draft |
| Toggle (Switch) | Input | Binary on/off settings that take effect immediately and whose state must be visible at a glance | [Screens] | Draft |
| Slider / Range | Input | Continuous or stepped value where range and relative position matter (volume, density, threshold) | [Screens] | Draft |
| Select / Combobox | Input | Selection from a discrete list | [Screens] | Draft |
| List Item | Layout / Input | A selectable or navigable row in a vertical list | [Screens] | Draft |
| Data Table | Layout / Input | Rows and columns of records with sort, filter, selection and row actions | [Screens] | Draft |
| Modal Dialog | Feedback / Layout | A decision or acknowledgment that must be resolved before continuing | [Screens] | Draft |
| Confirmation Dialog | Feedback / Layout | Confirming a destructive or costly action — triggered by Button (Destructive) or a billing change | [Screens] | Draft |
| Toast / Notification | Feedback | Brief non-blocking information requiring no decision (saved, copied, sent) | [Screens] | Draft |
| Tooltip | Feedback | Supplementary information on hover or focus for a visible label or icon | [Screens] | Draft |
| Progress Bar / Meter | Feedback / Layout | Progress to a defined endpoint (upload, import, onboarding checklist) or usage against a limit (quota meter) | [Screens] | Draft |
| Input Field | Input | Text, number, email, password, search and date entry | [Screens] | Draft |
| Tab Bar | Navigation | Dividing one screen's content into discrete sections, one visible at a time (max 5–6 tabs) | [Screens] | Draft |
| Scroll Container / Pagination | Layout | Content exceeding its container | [Screens] | Draft |
| Form & Validation | Input / Feedback | Any multi-field data entry (sign-up, settings, billing details) | [Screens] | Draft |
| Wizard / Multi-step Flow | Navigation / Input | Onboarding, imports, checkout — tasks with ordered dependent steps | [Screens] | Draft |
| Filter Bar & Search | Input | Narrowing a collection by text and facets | [Screens] | Draft |
| Bulk Selection & Actions | Input | Acting on many rows at once | [Screens] | Draft |
| Inline Edit | Input | Quick edits of a single field in place (rename, short note) | [Screens] | Draft |
| Command Palette | Navigation / Input | Keyboard-first global search and actions for power users | [Screens] | Draft |
| File Upload | Input | Attachments, imports, avatars | [Screens] | Draft |
| Plan Gate / Upgrade Prompt | Feedback | A feature or limit that depends on the plan or entitlement | [Screens] | Draft |
| Quota / Usage Meter | Feedback | Usage against a plan limit | [Screens] | Draft |
| Permission-Denied & Not-Found | Feedback | A route or action the user cannot access, or a resource that does not exist or belongs to another tenant | [Screens] | Draft |
| Async Job Status | Feedback | Exports, imports, reports, bulk operations that run in the background | [Screens] | Draft |
| Sensitive Value Reveal & Copy | Input / Feedback | API keys, webhook secrets, recovery codes shown once | [Screens] | Draft |
| Banner (Global/Inline) | Feedback | Persistent system or account state (trial ending, past due, maintenance, offline, impersonation) | [Screens] | Draft |
| Screen Push / Pop / Replace | Navigation | Forward, back and replace navigation with defined focus and history behaviour | [Screens] | Draft |
| Modal Open / Close | Navigation | Overlay that makes the background inert | [Screens] | Draft |
| Tab Switch | Navigation | Same-screen content switch between tabs | [Screens] | Draft |
| Focus Management | Navigation | Where focus goes when routes, dialogs and content change | [Screens] | Draft |
| Escape / Cancel | Navigation | Universal back/cancel behaviour across input methods | [Screens] | Draft |
| Loading State | Feedback | How screens and components indicate loading | [Screens] | Draft |
| Empty State | Feedback | How empty lists and tables are presented | [Screens] | Draft |
| Error State | Feedback | How errors are communicated and recovered from | [Screens] | Draft |
| Success Confirmation | Feedback | How completed actions are confirmed | [Screens] | Draft |
| Optimistic UI | Feedback | Showing assumed success before server confirmation, with rollback | [Screens] | Draft |
| Offline / Degraded | Feedback | Behaviour without connectivity or when dependencies fail | [Screens] | Draft |

---

## Standard Control Patterns

> Full reference specifications for every pattern in this section (state tables
> with timing values, accessibility requirements, implementation notes) are in
> `.claude/docs/templates/guidance/interaction-pattern-library-guide-standard-controls.md` —
> load only the pattern(s) currently being specified.

---

#### Button (Primary)

**Category**: Input
**Status**: Draft
**When to Use**: [The single most important action on a screen — at most one visible at a time]
**When NOT to Use**: [Alternative/secondary actions; destructive actions; anything not the screen's primary intent]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Default / Hovered / Focused / Pressed / Disabled / Busy (submitting)] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Keyboard (Enter/Space), visible focus ring, accessible name, 24 px minimum (44 px target), busy state announced and double-submit blocked, disabled reason available as text]

**Implementation Notes**: [Component from `DESIGN.md`; native `<button>`/Compose/SwiftUI control; pointer, keyboard and touch parity]

---

#### Button (Secondary)

**Category**: Input
**Status**: Draft
**When to Use**: [Alternative or cancel action — lower visual weight than Primary]
**When NOT to Use**: [Destructive actions; the screen's most important action]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Default / Hovered / Focused / Pressed / Disabled / Busy] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Same baseline as Primary; Cancel maps to Esc in dialogs]

**Implementation Notes**: [Consistent Primary/Secondary positioning; mirrored in RTL (primary at the end edge)]

---

#### Button (Destructive)

**Category**: Input
**Status**: Draft
**When to Use**: [Irreversible actions that remove data or access (delete, remove member, revoke key, cancel subscription)]
**When NOT to Use**: [Actions that can be undone (use Undo toast instead)]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Default / Hovered / Focused / Pressed / Disabled / Busy] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Accessible name states the object being affected; destructive nature conveyed by text, not colour alone]

**Implementation Notes**: [Never executes directly — always opens a Confirmation Dialog unless an Undo window is provided]

---

#### Toggle (Switch)

**Category**: Input
**Status**: Draft
**When to Use**: [Binary on/off settings that take effect immediately and whose state must be visible at a glance]
**When NOT to Use**: [More than two options; actions needing a Save step; choices needing explanation]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Off / On / Hovered / Focused / Pressed / Disabled / Saving / Failed] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [`role="switch"` with `aria-checked`; label states the setting not the action; state shown by text/position, not colour alone; save failure rolls back and announces]

**Implementation Notes**: [Optimistic update with rollback; persisted server-side per user or tenant]

---

#### Slider / Range

**Category**: Input
**Status**: Draft
**When to Use**: [Continuous or stepped value where range and relative position matter (volume, density, threshold)]
**When NOT to Use**: [Precise numeric entry; short discrete lists; binary state]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Default / Focused / Dragging / Keyboard step / Disabled] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Arrow keys step, PageUp/PageDown large step, Home/End bounds; value text exposed; numeric display or input alongside; drag has a non-drag alternative]

**Implementation Notes**: [Prefer a stepper or input for money and quantities]

---

#### Select / Combobox

**Category**: Input
**Status**: Draft
**When to Use**: [Selection from a discrete list; select for 3–15 options, combobox with search for more]
**When NOT to Use**: [Binary choices; fewer than 3 options (use radio group)]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Closed / Open / Focused / Filtering / Option focused / Selected / Empty results / Disabled / Loading options] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [ARIA combobox/listbox pattern, `aria-expanded`, `aria-activedescendant`, type-ahead, Esc closes and returns focus, option count announced for filtered lists]

**Implementation Notes**: [Async options use debounce and cursor pagination; native select on mobile where appropriate; RTL alignment]

---

#### List Item

**Category**: Layout / Input
**Status**: Draft
**When to Use**: [A selectable or navigable row in a vertical list]
**When NOT to Use**: [Tabular data with sortable columns (use Data Table)]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Default / Hovered / Focused / Selected / Pressed / Disabled / Loading] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Semantics `listitem` with position, minimum row height 44 px touch, entire row target with one primary action]

**Implementation Notes**: [Virtualised lists keep stable keys; scroll-into-view on focus]

---

#### Data Table

**Category**: Layout / Input
**Status**: Draft
**When to Use**: [Rows and columns of records with sort, filter, selection and row actions]
**When NOT to Use**: [Fewer than ~5 fields per record on mobile (use cards); non-tabular content]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Loading / Empty / Populated / Row hovered / Row focused / Row selected / Sorted / Bulk-selected / Error / Partially loaded] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Native `<table>` with `<th scope>`; sort state announced; keyboard row actions via menu button; sticky header must not obscure focus; no horizontal scroll at 320 px (card layout instead)]

**Implementation Notes**: [Cursor pagination or "Load more"; server-side sort/filter on allowlisted fields; column visibility persisted per user; money and dates formatted per locale]

---

#### Modal Dialog

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: [A decision or acknowledgment that must be resolved before continuing]
**When NOT to Use**: [Non-blocking notifications; information that can wait; large multi-step tasks (use a page or wizard)]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Opening / Active / Dismissing (confirmed) / Dismissing (cancelled) / Cannot dismiss / Busy] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [`role="dialog"` with accessible name, focus trap, Esc closes, focus returns to the trigger, background inert, scroll lock; unsaved-input guard]

**Implementation Notes**: [Use native `<dialog>` or the pinned component library; bottom sheet on mobile; reduced-motion overrides]

---

#### Confirmation Dialog

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: [Confirming a destructive or costly action — triggered by Button (Destructive) or a billing change]
**When NOT to Use**: [Non-destructive confirmations; dialogs with more than two actions]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Opening / Active / Confirming (busy) / Failed / Cancelled] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Inherits Modal Dialog; `role="alertdialog"`; default focus on Cancel; confirm label names the action ("Remove Amal", not "OK"); consequence stated incl. billing effect]

**Implementation Notes**: [For irreversible deletes of important data require typing the object's name]

---

#### Toast / Notification

**Category**: Feedback
**Status**: Draft
**When to Use**: [Brief non-blocking information requiring no decision (saved, copied, sent)]
**When NOT to Use**: [Errors needing action; critical information; anything the user must not miss]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Entering / Displayed / Auto-dismiss / Manual dismiss / Queued / Merged] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [`role="status"` (or `alert` for errors) with no focus steal; minimum 5 s unless action-free and short; pausable on hover/focus; never the only channel for actionable information; reduced-motion fallback]

**Implementation Notes**: [Max simultaneous toasts; merge identical; persist important ones in the notification inbox]

---

#### Tooltip

**Category**: Feedback
**Status**: Draft
**When to Use**: [Supplementary information on hover or focus for a visible label or icon]
**When NOT to Use**: [Information required to complete an action; touch-only surfaces]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Hidden / Hover trigger / Focus trigger / Displayed / Dismissed] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Reachable via keyboard focus; dismissible with Esc; hoverable; persistent while hovered; `aria-describedby`; contrast per tokens]

**Implementation Notes**: [Delay ~300–400 ms; reposition near viewport edges; never put interactive content in a tooltip (use a popover)]

---

#### Progress Bar / Meter

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: [Progress to a defined endpoint (upload, import, onboarding checklist) or usage against a limit (quota meter)]
**When NOT to Use**: [Values without an endpoint (use a spinner); rapidly fluctuating values]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Default / Increasing / Complete / Error / Indeterminate / Near limit / At limit] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [`role="progressbar"` or `meter` with value/min/max, text value always shown, announced at milestones not every tick; near-limit state not colour-only]

**Implementation Notes**: [Long jobs report via polling/stream and survive reload (job ID); show cancel when safe]

---

#### Input Field

**Category**: Input
**Status**: Draft
**When to Use**: [Text, number, email, password, search and date entry]
**When NOT to Use**: [Selecting from known options; long free text where a rich editor is needed]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Default / Hovered / Focused / Typing / Filled / Limit reached / Validation error / Validated / Disabled / Read-only] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Visible label (placeholder is not a label), hint and error associated via `aria-describedby`, correct `type`/`inputmode`/`autocomplete`, paste allowed, error identified in text and summary, IME-safe, bidi isolation for emails/URLs/IDs]

**Implementation Notes**: [Validate on blur and submit (not each keystroke); preserve value on error; server is the source of truth; no PII in analytics]

---

#### Tab Bar

**Category**: Navigation
**Status**: Draft
**When to Use**: [Dividing one screen's content into discrete sections, one visible at a time (max 5–6 tabs)]
**When NOT to Use**: [More than 6 tabs; content needing simultaneous visibility; navigation between routes (use nav)]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Inactive / Active / Hovered / Focused / Disabled / Overflow] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [ARIA tabs pattern (tablist/tab/tabpanel), arrow-key navigation, active tab distinguished beyond colour, URL reflects the active tab where deep-linking matters]

**Implementation Notes**: [Mobile uses bottom navigation only for top-level destinations; mirrors in RTL]

---

#### Scroll Container / Pagination

**Category**: Layout
**Status**: Draft
**When to Use**: [Content exceeding its container; long collections]
**When NOT to Use**: [Content better paginated; infinite scroll without loading/end states]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Content fits / Scrollable / Scrolling / Loading more / End reached / Error loading more] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Focused element stays in view, scroll region is keyboard focusable when it scrolls, "Load more" button available as an alternative to infinite scroll, scroll position restored on back]

**Implementation Notes**: [Cursor pagination with server-capped limit; virtualise long lists; never nest scroll regions on mobile]

---

## SaaS-Specific Patterns

> These patterns recur across subscription and tenant-based products. Each is
> specified here directly (no separate guidance file); extend the table rows as
> you adopt them. Rules about entitlements, tenancy and security are repeated
> where they change UI behaviour — the server always makes the final decision.

---

#### Form & Validation

**Category**: Input / Feedback
**Status**: Draft
**When to Use**: [Any multi-field data entry (sign-up, settings, billing details)]
**When NOT to Use**: [Single-field actions (use inline edit); long wizards without save (use Wizard)]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Pristine / Dirty / Validating / Submitting / Success / Field error / Form error / Server error / Conflict (412)] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Labels, grouping with fieldset/legend, error summary linking to fields and receiving focus, required marked beyond colour, autocomplete tokens, accessible authentication, redundant entry avoided, unsaved-changes guard]

**Implementation Notes**: [One idempotent submit; map problem `code`s to messages; keep user input; disable only after submit starts]

---

#### Wizard / Multi-step Flow

**Category**: Navigation / Input
**Status**: Draft
**When to Use**: [Onboarding, imports, checkout — tasks with ordered dependent steps]
**When NOT to Use**: [Tasks that fit on one screen]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Step current / complete / upcoming / error / saving / resumed] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Step list with text status, focus to step heading on change, back preserves data, save-and-resume, progress announced]

**Implementation Notes**: [Server-side draft state; URL per step; analytics per step]

---

#### Filter Bar & Search

**Category**: Input
**Status**: Draft
**When to Use**: [Narrowing a collection by text and facets]
**When NOT to Use**: [Collections under ~10 items]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Empty / Typing / Applied / Loading / No results / Error] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Result count announced, filters keyboard operable, clear-all, filters in URL, search is a labelled search landmark]

**Implementation Notes**: [Debounce; allowlisted filter fields; server-side; saved views optional]

---

#### Bulk Selection & Actions

**Category**: Input
**Status**: Draft
**When to Use**: [Acting on many rows at once]
**When NOT to Use**: [When only single-row actions exist]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [None / Some / All on page / All matching / Acting / Partial failure] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Selection count announced, select-all checkbox tri-state, action result reports successes and failures separately, undo where possible]

**Implementation Notes**: [Bulk operations are idempotent and chunked; "all matching" requires server-side query, not client ID lists]

---

#### Inline Edit

**Category**: Input
**Status**: Draft
**When to Use**: [Quick edits of a single field in place (rename, short note)]
**When NOT to Use**: [Fields with complex validation or dependencies]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Read / Hover / Editing / Saving / Error / Saved] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Enter saves, Esc cancels, focus returns to the display element, errors associated, announced result]

**Implementation Notes**: [Optimistic with rollback; `If-Match` for contended resources]

---

#### Command Palette

**Category**: Navigation / Input
**Status**: Draft
**When to Use**: [Keyboard-first global search and actions for power users]
**When NOT to Use**: [Primary discovery for novices (it complements the nav)]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Closed / Open / Typing / Results / No results / Executing] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Dialog with combobox semantics, shortcut documented and not conflicting with browser/AT keys, results announced, usable in RTL]

**Implementation Notes**: [Search only what the user may access; no tenant leakage; telemetry without query text]

---

#### File Upload

**Category**: Input
**Status**: Draft
**When to Use**: [Attachments, imports, avatars]
**When NOT to Use**: [Large media pipelines (separate design)]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Idle / Drag over / Selected / Uploading / Scanning / Complete / Rejected / Failed / Cancelled] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Button alternative to drag-and-drop, progress text, accessible errors with reason (type/size), no reliance on colour]

**Implementation Notes**: [Client checks are advisory; server validates type by content, size, quota; resumable for large files; never trusts file names]

---

#### Plan Gate / Upgrade Prompt

**Category**: Feedback
**Status**: Draft
**When to Use**: [A feature or limit that depends on the plan or entitlement]
**When NOT to Use**: [Hiding features without explanation when discovery matters]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Allowed / Near limit / Blocked by plan / Blocked by role / Past due (read-only) / Trial ending] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [States the reason in text, names the plan or action that unblocks, never traps data, links to billing for admins and to "ask your admin" for others, no dark patterns]

**Implementation Notes**: [Decision is made by the server (entitlement check); the UI mirrors it; analytics for gate views]

---

#### Quota / Usage Meter

**Category**: Feedback
**Status**: Draft
**When to Use**: [Usage against a plan limit]
**When NOT to Use**: [Metrics without a limit (use a stat)]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Normal / 80% / 100% / Over (soft limit) / Unknown] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Text value with units, thresholds not colour-only, `meter` semantics, reset date shown]

**Implementation Notes**: [Cached with a short `staleTime`; the server enforces; show last-updated time for metered data]

---

#### Permission-Denied & Not-Found

**Category**: Feedback
**Status**: Draft
**When to Use**: [A route or action the user cannot access, or a resource that does not exist or belongs to another tenant]
**When NOT to Use**: [Using 403 copy for other-tenant resources (leaks existence)]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Forbidden / Not found / Session expired / Tenant suspended] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Heading and message explain what happened and the next step, focus moves to the heading, no data in the page title]

**Implementation Notes**: [Same-tenant forbidden shows 403 copy; other-tenant ID shows Not-found copy (404); no resource details in either]

---

#### Async Job Status

**Category**: Feedback
**Status**: Draft
**When to Use**: [Exports, imports, reports, bulk operations that run in the background]
**When NOT to Use**: [Operations that finish within ~1 s]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Queued / Running / Succeeded / Failed / Cancelled / Expired] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Status text and progress announced at milestones, completion delivered in-app and optionally by email, result link has an expiry and authorisation check]

**Implementation Notes**: [Job ID persisted so refresh does not lose it; retry for failed jobs; 202 + status URL]

---

#### Sensitive Value Reveal & Copy

**Category**: Input / Feedback
**Status**: Draft
**When to Use**: [API keys, webhook secrets, recovery codes shown once]
**When NOT to Use**: [Values that can be retrieved later (never store secrets recoverable)]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Hidden / Revealed once / Copied / Acknowledged] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [Copy button announces result, value is selectable text, explicit "I have stored it" acknowledgement, masked when idle, never logged or sent to analytics]

**Implementation Notes**: [Shown once on creation; rotation flow documented; screenshots in evidence must use fake secrets]

---

#### Banner (Global/Inline)

**Category**: Feedback
**Status**: Draft
**When to Use**: [Persistent system or account state (trial ending, past due, maintenance, offline, impersonation)]
**When NOT to Use**: [Transient success messages (use Toast)]

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| [Info / Warning / Critical / Dismissed / Resolved] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] |

**Accessibility**: [`role="status"`/`alert` by severity, not colour-only, actionable link text, dismissal remembered only where safe, critical banners not dismissible]

**Implementation Notes**: [Priority and stacking rules live in `app-shell.md`]

---

## Navigation Patterns

> Full reference specifications for this section and the next are in
> `.claude/docs/templates/guidance/interaction-pattern-library-guide-navigation-feedback.md` —
> load only the pattern(s) currently being specified.

---

#### Screen Push / Pop / Replace

**Category**: Navigation
**Status**: Draft

These patterns define how routes and screens enter and exit history.

| Pattern | Trigger | Animation | History Behaviour | Focus Behaviour |
|---------|---------|-----------|------------------|-----------------|
| [Push / Pop / Replace] | [Trigger] | [Animation] | [Stack/history behaviour] | [Focus behaviour] |

**Animation durations**: [Push/Pop and Replace durations + easing — see Animation Standards]
**Motion reduction**: [Fallback behaviour]
**Implementation Notes**: [Router configuration, scroll restoration, back-stack on Android/iOS, deep-link handling, return-focus storage]

---

#### Focus Management

**Category**: Navigation
**Status**: Draft

> Focus management is the most common keyboard and screen-reader failure in web
> and mobile apps. These rules must be implemented consistently.

| Rule | Description |
|------|-------------|
| [Route change, dialog open/close, element removed, tab order, composite-widget roving focus, focus visibility, focus not obscured] | [Rule description] |

---

#### Escape / Cancel

**Category**: Navigation
**Status**: Draft

> "Go back / cancel" is the most-used navigation input. It must be consistent
> across every screen with no exceptions.

| Surface | Input | Behaviour |
|---------|-------|-----------|
| [Web] | [Esc, browser Back] | [Behaviour] |
| [Android] | [System back / predictive back] | [Behaviour] |
| [iOS] | [Swipe-back, Close/Cancel button] | [Behaviour] |

**Rules**: [Never override system back without a visible, accessible alternative; every screen defines its Escape behaviour in its UX spec; unsaved-changes guard rules]

---

## Feedback and Loading Patterns

---

#### Loading State

**Category**: Feedback
**Status**: Draft

| Scope | Pattern | Notes |
|-------|---------|-------|
| [Initial route load / Route transition / Component inline / Background async / Long-running job] | [Skeleton / spinner / progress / status text] | [Delay before showing (avoid flashes), timeout copy, perceived-performance rules] |

**Accessibility**: [Loading and loaded announcements via live region; `aria-busy`; skeletons hidden from assistive tech]

---

#### Empty State

**Category**: Feedback
**Status**: Draft

> Every empty list and table must have a designed empty state. The empty state is
> not an error — it is a starting point.

| Location | Empty State Content | Notes |
|----------|--------------------|----|
| [First-use / No results / Filtered / No permission to see data] | [Illustration or icon + message + primary action] | [Notes] |

**Rule**: Every empty state includes a message and either a next action or an explanation of why it is empty. Distinguish "nothing yet" from "no results for these filters".

---

#### Error State

**Category**: Feedback
**Status**: Draft

| Error Type | Pattern | Tone |
|-----------|---------|------|
| [Field validation / Operation failed / Network offline / Server error (trace ID) / Rate limited / Plan limit / Forbidden / Not found / Session expired] | [Inline / banner / toast / full-screen] | [Tone guidance] |

**Principle**: Error messages are never the user's fault. They say what happened and what to do next; they never expose internals. Copy comes from the stable problem `code`, localised, with the `trace_id` available for support.

---

#### Success Confirmation

**Category**: Feedback
**Status**: Draft

| Action Type | Confirmation | Notes |
|-------------|--------------|-------|
| [Save, send, delete, purchase, invite] | [Toast / inline message / page change + status announcement] | [What the user sees and hears; Undo where reversible] |

---

#### Optimistic UI

**Category**: Feedback
**Status**: Draft

**When to Use**: [Low-risk, highly likely to succeed actions (toggle, reorder, rename)]
**When NOT to Use**: [Payments, deletes without Undo, permission changes, anything with server-side validation likely to fail]
**Rollback rule**: [On failure, revert the UI, announce the failure, keep the user's input]

---

#### Offline / Degraded

**Category**: Feedback
**Status**: Draft

| Situation | Behaviour | Notes |
|-----------|-----------|-------|
| [Offline / API 503 / Provider outage / Read-only mode] | [Banner + cached read-only + queued writes where safe] | [Mobile offline queue, conflict handling, retry/backoff, user-visible state] |

---

## Animation Standards

> These timing values apply to ALL patterns in this library. Easing functions are
> defined here (and implemented as tokens in `DESIGN.md`). Consistency makes the
> UI feel like one designed system. Animate transform and opacity only.

| Animation Type | Duration (ms) | Easing Function | Notes |
|---------------|--------------|----------------|-------|
| Button hover / focus enter | 80 | ease-out | Fast — snappy, not sluggish |
| Button hover / focus exit | 60 | ease-in | Slightly faster exit |
| Button press | 60 | ease-in | Immediate feedback |
| Route enter / exit | 150 | ease-in-out | Content fade; avoid layout-shifting slides |
| Modal open | 150 | ease-out | Scale from 96% + fade |
| Modal close | 100 | ease-in | Faster than open |
| Sheet / drawer | 200 | ease-out | Slides from the start/end edge (mirrors in RTL) |
| Toast enter / exit | 200 | ease-out / ease-in | |
| Tab switch | 150 | ease-in-out | Cross-fade |
| Tooltip appear | 120 | ease-out | After 300–400 ms delay |
| Tooltip disappear | 80 | ease-in | |
| Progress fill | 300 | ease-out | |
| Skeleton shimmer | 1200 loop | linear | Replaced by static placeholder under reduced motion |
| List item insert / remove | 200 | ease-out | Height + fade |

**Motion reduction overrides**: When `prefers-reduced-motion` (web) or the platform "Reduce Motion" setting is on, all slide and scale animations are replaced with instant changes or cross-fades at 50% duration, looping animations are replaced by static equivalents, and no information is conveyed by motion alone (see `accessibility-requirements.md`).

---

## Feedback Channels Beyond Visuals

> Products are mostly silent; audio is opt-in. Define only what is needed.

| Interaction Event | Channel | Notes |
|------------------|---------|-------|
| Success / error / warning | Visual + live-region announcement | Never colour or sound alone |
| Mobile confirmation of an important action | Haptic (light) | Respects system haptics setting |
| Incoming notification | Push / email per user preferences | Opt-in; quiet hours honoured |
| Sound | None by default | If a product adds sounds (call, alerts), they are opt-in, volume-controlled and have visual equivalents |

---

## Direction and Locale Standards

| Rule | Description |
|------|-------------|
| Logical properties | Use start/end, never left/right |
| Mirroring | Mirror layout, chevrons, progress, back arrows; do not mirror media controls, brand marks, or numeric charts' axes unless the locale convention says so |
| Bidi isolation | Isolate emails, URLs, IDs and mixed-script strings |
| Formatting | Dates, numbers, currency and units via platform locale formatters; money from `amount_minor` + `currency` |
| Plurals | ICU plural/select forms for every counted string |

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Which combobox/date-picker implementation in the pinned component library passes the ARIA keyboard model in RTL?] | [web-lead, accessibility-specialist] | [Before first form implementation] | [Unresolved] |
| [Should the data table use the ARIA grid pattern or a plain table with row menus?] | [ux-designer, web-lead] | [Before the first list screen] | [Unresolved] |
| [What is the platform-correct back and sheet behaviour on Android predictive back vs. iOS swipe-back for dialogs and wizards?] | [android-lead, ios-lead] | [Before mobile navigation implementation] | [Unresolved] |
| [Maximum simultaneous toasts before the queue becomes overwhelming? Needs usability testing.] | [ux-designer] | [First usability session] | [Unresolved] |
| [Add question] | [Owner] | [Deadline] | [Resolution] |
