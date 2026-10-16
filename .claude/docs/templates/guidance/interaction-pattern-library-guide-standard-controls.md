> Authoring guidance for interaction-pattern-library.md. Load only the part covering the section currently being authored — not the whole file at once.

> Covers: **Standard Control Patterns** — full reference specifications for Button (Primary/Secondary/Destructive), Toggle, Slider, Select / Combobox, List Item, Data Table, Modal Dialog, Confirmation Dialog, Toast / Notification, Tooltip, Progress Bar / Meter, Input Field, Tab Bar, Scroll Container / Pagination.

> Conventions: Colours, radii and type come from `DESIGN.md`; this file defines behaviour. Durations match the Animation Standards table in the template. "Focus ring" means a visible indicator with at least 3:1 contrast against adjacent colours, never obscured by sticky UI. Touch targets: 24x24 CSS px absolute minimum on web (WCAG 2.2), 44x44 px target; 48 dp Android; 44 pt iOS.

## Standard Control Patterns

---

#### Button (Primary)

**Category**: Input
**Status**: Draft
**When to Use**: The single most important action on a screen — "Save changes," "Send invite," "Pay now," "Continue." At most one Primary button is visible at a time. It answers "what does the user most likely want to do here?"
**When NOT to Use**: Alternative or secondary actions; destructive actions that need confirmation; any action that is not the screen's primary intent.

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| Default | Filled with the primary token; label centred; icon optional and decorative | — | — | — |
| Hovered (pointer) | Slightly elevated fill token; pointer cursor | Pointer over element | Transition from Default | 80 ms ease-out |
| Focused (keyboard/switch) | Focus ring (2 px, offset 2 px, 3:1 contrast); same fill as Hovered | Tab / Shift+Tab | Transition from Default | 80 ms ease-out |
| Pressed | Pressed fill token; scale 0.98 (no scale under reduced motion) | Click / tap / Enter / Space | Action fires on release (up-event) so it can be aborted by moving away | 60 ms ease-in press; 80 ms ease-out release |
| Disabled | Disabled tokens (contrast kept >= 3:1 for legibility); no hover; the reason is available as visible text nearby, not only a tooltip | — | No response; use `aria-disabled` if it must stay focusable to expose the reason | — |
| Busy (submitting) | Label replaced or accompanied by a spinner; width stays fixed; `aria-busy` | — | Further activation ignored (double-submit protection); idempotency key reused if retried | Duration of the async operation |

**Accessibility**:
- Keyboard: Tab to focus, Enter or Space to activate. Native `<button>` (web); never a `div` with a click handler.
- Screen reader: accessible name matches the visible label; icon-only buttons have a name; busy state announced ("Sending…") via status region.
- Colour: Primary vs. Secondary differ by weight (fill vs. outline) as well as colour.
- Target size: 44x44 target; never below the platform minimum.
- Reduced motion: no scale; colour change only.

**Implementation Notes**:
- Web: one `Button` component with variants from the design system; `type="button"` unless submitting; do not disable on submit before the request starts.
- Android: Compose `Button` with `semantics`; ensure minimum interactive size (`minimumInteractiveComponentSize`).
- iOS: SwiftUI `Button` with `.buttonStyle`; support Dynamic Type; hit area padding.
- Place Primary at the end edge of an action row (right in LTR, left in RTL), or full width on compact mobile.

---

#### Button (Secondary)

**Category**: Input
**Status**: Draft
**When to Use**: Alternative or cancel actions, lower visual weight than Primary ("Cancel," "Back," "Export").
**When NOT to Use**: Destructive actions; the screen's most important action.

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| Default | Outline or tonal fill; same size and shape as Primary | — | — | — |
| Hovered | Background tint | Pointer over | Transition | 80 ms ease-out |
| Focused | Focus ring | Tab | Transition | 80 ms ease-out |
| Pressed | Pressed tint | Click / tap / Enter / Space | Fires on release | 60 ms |
| Disabled | Disabled tokens | — | None | — |
| Busy | Spinner; disabled | — | Ignored | Async duration |

**Accessibility**: Same baseline as Primary. In dialogs, Cancel maps to Esc.

**Implementation Notes**: Consistent positioning relative to Primary on every screen (Primary at the end edge, Secondary before it). Mirrors in RTL.

---

#### Button (Destructive)

**Category**: Input
**Status**: Draft
**When to Use**: Irreversible actions that remove data or access: delete project, remove member, revoke API key, cancel subscription.
**When NOT to Use**: Actions that can be undone — use an Undo toast instead of a confirmation (less friction, same safety).

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| Default | Destructive token (outline or fill); icon plus text, never colour alone | — | — | — |
| Hovered / Focused | As Secondary with destructive tint | Pointer / Tab | Transition | 80 ms |
| Pressed | Pressed tint | Click / tap / Enter / Space | **Opens a Confirmation Dialog — never executes directly** | 60 ms |
| Disabled | Disabled tokens | — | None | — |

> **Critical rule**: A Button (Destructive) NEVER executes its action directly
> unless the action is reversible with a visible Undo. There are no other exceptions.

**Accessibility**: The accessible name states the object ("Remove Amal Hassan"), not just "Remove"; destructive nature conveyed in text.

**Implementation Notes**: Place away from Primary; avoid adjacent placement with the common action. Server also enforces authorisation and any "last owner" style invariants.

---

#### Toggle (Switch)

**Category**: Input
**Status**: Draft
**When to Use**: Binary on/off settings that take effect immediately ("Email notifications," "Dark mode"), where the state must be visible at a glance.
**When NOT to Use**: More than two options (radio group); actions that need a Save step (use a checkbox in a form); choices that need explanation before changing.

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| Off | Track and thumb at the start edge; "Off" shown by position and a text/label cue | — | — | — |
| On | Thumb at the end edge; filled track; check or "On" cue (not colour alone) | — | — | — |
| Hovered / Focused | Hover tint; focus ring | Pointer / Tab | Transition | 80 ms |
| Pressed | Thumb slightly widened | Click / tap / Space | State flips on release | 120 ms ease-out |
| Saving | Control shows a small busy indicator; remains interactive only if safe | — | Request in flight | Async |
| Failed | Reverts to previous state; inline error text | — | Announce failure; offer Retry | — |
| Disabled | Disabled tokens; reason available | — | None | — |

**Accessibility**: `role="switch"` with `aria-checked` (native checkbox with switch role is acceptable); Space toggles; label names the setting, not the action; reduced motion removes the thumb slide.

**Implementation Notes**: Optimistic update with rollback and an idempotent endpoint; direction mirrors in RTL (thumb start edge is the right in RTL). Compose `Switch` / SwiftUI `Toggle` provide the platform behaviour.

---

#### Slider

**Category**: Input
**Status**: Draft
**When to Use**: Continuous or stepped values where range and position matter (density, threshold, volume).
**When NOT to Use**: Precise numeric entry, money or quantities (use an input or stepper); short discrete lists (use radio or select); binary state.

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| Default | Track, thumb, value text visible | — | — | — |
| Focused | Focus ring on thumb | Tab | — | 80 ms |
| Dragging | Thumb enlarged; live value | Pointer drag / touch drag | Value updates continuously; commit on release | Real-time |
| Keyboard step | Thumb moves one step | Arrow keys; PageUp/PageDown large step; Home/End bounds | Value change announced | Instant |
| Disabled | Disabled tokens | — | None | — |

**Accessibility**: `role="slider"` with `aria-valuemin/max/now/text`; a numeric value is always displayed (and an input alongside for precision); a single-pointer non-drag alternative exists (WCAG 2.2 Dragging Movements); touch thumb at least 44 px.

**Implementation Notes**: Debounce persistence; RTL inverts the direction of value increase visually; use the platform slider on Android/iOS.

---

#### Select / Combobox

**Category**: Input
**Status**: Draft
**When to Use**: Choosing from a discrete list — a Select for 3–15 options, a searchable Combobox for longer or async lists (users, projects, countries).
**When NOT to Use**: Binary choices (toggle) or fewer than 3 options (radio group); lists where users need to compare options side by side.

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| Closed | Shows the selected value or placeholder; chevron | — | — | — |
| Focused | Focus ring | Tab | — | 80 ms |
| Open | Listbox below (or above if no room), width >= trigger; selected option marked with check and text | Enter / Space / Down arrow / click | Opens; focus on selected option or first | 120 ms ease-out |
| Filtering (combobox) | Options narrowed; match highlighted | Typing | Result count announced | Debounced 150–300 ms for async |
| Option focused | Highlight | Arrow keys; Home/End; type-ahead | Moves | Instant |
| Selected | List closes; value shown | Enter / click | Value set; focus returns to trigger | 80 ms |
| Empty results | "No matches" text | — | — | — |
| Loading options | Inline spinner | — | — | — |
| Disabled | Disabled tokens | — | None | — |

**Accessibility**: ARIA combobox/listbox pattern (`aria-expanded`, `aria-controls`, `aria-activedescendant`); Esc closes and returns focus; the selected option and its position ("3 of 12") are announced; option labels are text, not colour; do not clip the listbox behind containers (portal).

**Implementation Notes**: Prefer the native `<select>` on mobile web where it satisfies the design; async sources use cursor pagination and only return options the user may see (tenant-scoped). Android `ExposedDropdownMenu`, iOS `Picker`/`Menu`. RTL aligns the list to the start edge.

---

#### List Item

**Category**: Layout / Input
**Status**: Draft
**When to Use**: A selectable or navigable row in a vertical list (notifications, projects, conversations).
**When NOT to Use**: Tabular data with several comparable fields (use Data Table); non-interactive rows.

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| Default | Row with leading icon/avatar, primary text, secondary text, trailing meta/actions | — | — | — |
| Hovered | Background tint | Pointer | — | 80 ms |
| Focused | Focus ring around the row | Tab or arrows (roving, if a listbox) | — | 80 ms |
| Selected | Selected tint plus check/outline (not colour alone) | Click / tap / Enter / Space | Selection set | 80 ms |
| Pressed | Pressed tint | Pointer down | — | 60 ms |
| Loading | Skeleton row | — | — | — |
| Disabled | Disabled tokens with reason | — | None | — |

**Accessibility**: Use `ul/li` or `listitem` semantics; the whole row is one primary target; secondary actions are separate controls with names including the item; minimum row height 44 px; position ("2 of 10") exposed in listbox patterns; truncated text has an accessible full name.

**Implementation Notes**: Virtualise long lists with stable keys; keep focus when the list updates; scroll the focused row into view; Android `LazyColumn` with `key`, iOS `List` with stable IDs.

---

#### Data Table

**Category**: Layout / Input
**Status**: Draft
**When to Use**: Records with several comparable fields where users sort, filter, select and act (invoices, members, audit log).
**When NOT to Use**: Fewer than ~3 fields (use List Item); narrow mobile screens (present as cards with the same actions); purely presentational layout.

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| Loading | Skeleton rows matching column widths | — | — | — |
| Empty | Empty State pattern in the body; header remains | — | — | — |
| Populated | Header row, body rows, optional footer with count and pagination | — | — | — |
| Row hovered | Background tint; row actions visible | Pointer | — | 80 ms |
| Row focused | Focus ring on the row's primary link/cell; row actions menu reachable by Tab | Tab / arrows (if grid pattern) | — | 80 ms |
| Row selected (bulk) | Selected tint plus checked checkbox; selection count in a toolbar | Space / click on checkbox | Bulk actions toolbar appears | 100 ms |
| Sorted | Header shows direction icon and `aria-sort` | Enter on header button | Server-side sort; announce | Per request |
| Partial/Error | Inline error row or banner with Retry; keep rows already loaded | — | — | — |

**Accessibility**: Native `<table>`, `<th scope>`, caption or `aria-label`; sortable headers are buttons; selection checkboxes labelled with the row name; "select all" tri-state; sticky header must not obscure focus (scroll-padding); no horizontal scroll at 320 px — switch to cards; totals and filters announced via a status region; status chips include text.

**Implementation Notes**: Cursor pagination (`next_cursor`) with a server-capped `limit`; sort and filter fields allowlisted by the API; column visibility and density persisted per user; money as `amount_minor` + `currency` formatted per locale; avoid per-row API calls (N+1 on the client); bulk operations send IDs or a server-side query, idempotently. RTL mirrors column order and alignment; numeric columns stay right-aligned in LTR and left-aligned in RTL where locale convention requires.

---

#### Modal Dialog

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: A decision or acknowledgment that must be resolved before continuing — short forms (invite member), confirmations, blocking errors.
**When NOT to Use**: Non-blocking notifications (Toast); information that can wait; long multi-step tasks (use a page or Wizard); content users need to reference while typing elsewhere (use a non-modal panel).

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| Opening | Backdrop fades to ~40%; panel scales 96% to 100% and fades in; on compact mobile becomes a bottom sheet | Triggered by a user action | Focus moves to the first field, or the safest action for confirmations | 150 ms ease-out |
| Active | Background inert (`inert`/`aria-hidden`), page scroll locked | Keyboard navigates within the dialog only | — | — |
| Dismissing (confirmed) | Reverse of open | Primary button | Action executes; focus returns to trigger (or to a sensible target if the trigger is gone) | 100 ms |
| Dismissing (cancelled) | Reverse of open | Cancel / Esc / close button / tap outside (if no unsaved input) | No action; focus returns to trigger | 100 ms |
| Busy | Primary shows busy; fields read-only; Esc cancels UI but not the in-flight request | — | — | — |
| Cannot dismiss | Only for blocking errors or required acceptance; no close affordance; resolution actions only | — | — | — |

> **Focus trap rule**: While a modal dialog is open, Tab and Shift+Tab cycle
> within it only, and focus returns to the trigger when it closes. (WCAG 2.1.2
> No Keyboard Trap is satisfied because Esc or a visible Close always exits.)

**Accessibility**: `role="dialog"` (or `alertdialog`) with `aria-modal`, an accessible name from the title (every dialog has a title, visually hidden if necessary), a description for non-trivial content; announce on open; Enter submits only when focus is not in a multi-line field; reduced motion removes the scale; ensure the dialog is reachable and scrollable at 200% zoom and on small screens.

**Implementation Notes**: Prefer native `<dialog>` with `showModal()` or the pinned component library's dialog; stack at most one modal; compose forms inside with the Form pattern; Android `ModalBottomSheet`/`AlertDialog`, iOS `.sheet`/`.alert`/`.confirmationDialog`; dialog content must remain usable with the software keyboard open.

---

#### Confirmation Dialog

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: Confirming a destructive or costly action — always triggered by Button (Destructive) or a billing change (upgrade, downgrade, cancel).
**When NOT to Use**: Non-destructive confirmations (they train users to click through); dialogs with more than two actions.

> **Label rule**: The confirm button is labelled with the specific action ("Remove Amal", "Cancel subscription"), not a generic "OK" or "Yes."

**Structure**:
- Title: brief, describes the action ("Remove Amal Hassan?")
- Body: one or two sentences stating the consequence, including billing effect ("They lose access immediately. Your bill drops by EGP 99 from the next cycle.")
- Confirm button: Button (Destructive) styling when destructive, Primary when merely costly; labelled with the action
- Cancel button: Button (Secondary) — "Cancel"
- Default focus: Cancel (the safer default)
- For irreversible deletion of significant data: require typing the object's name to enable the confirm button

**Accessibility**: Inherits Modal Dialog; `role="alertdialog"` announces title and body on open; default focus on Cancel is required; confirm is never the default on destructive actions; consequences are text, not icon-only.

**Implementation Notes**: One reusable component taking `title`, `consequence`, `confirmLabel`, `onConfirm`; the confirm call uses an idempotency key; show the result with Success Confirmation and, where reversible, an Undo.

---

#### Toast / Notification

**Category**: Feedback
**Status**: Draft
**When to Use**: Brief, non-blocking information that requires no decision — "Saved," "Link copied," "Invitation sent."
**When NOT to Use**: Decisions; errors that require action; critical or money-related information the user must not miss (use a banner or dialog); anything the user may need to find again (use the notification inbox).

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| Entering | Slides/fades from the bottom-start edge (mirrored in RTL) | Triggered by an event | Announced via live region; focus unchanged | 200 ms ease-out |
| Displayed | Message, optional single action (Undo/View), close button | Pointer hover or keyboard focus pauses the timer | — | 5–8 s (longer for longer text; at least 5 s if it has an action) |
| Auto-dismiss | Fades out | Timer | Removed | 200 ms ease-in |
| Manual dismiss | Fades out | Click close / Esc when focused | Removed | 150 ms |
| Queue overflow | Older toasts collapse; identical messages merge with a count | — | Max 3 visible | — |

**Accessibility**: `role="status"` (polite) for success and info; `role="alert"` for errors; never move focus automatically; an action in a toast must also be reachable another way; honour reduced motion; do not use a toast as the only record of an important event.

**Implementation Notes**: One provider at the app shell (`app-shell.md`); position avoids covering primary actions and mobile bottom navigation; Android `Snackbar`, iOS custom banner (avoid for critical info).

---

#### Tooltip

**Category**: Feedback
**Status**: Draft
**When to Use**: Supplementary information for a visible label or icon — what an icon-only button does, why something is disabled (in addition to visible text).
**When NOT to Use**: Information required to complete an action; touch-only surfaces (no hover); interactive content (use a popover).

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| Hidden | Not rendered | — | — | — |
| Hover trigger | Appears after a delay | Pointer rests on the trigger | Shows | 300–400 ms delay, 120 ms ease-out |
| Focus trigger | Appears immediately on keyboard focus | Tab | Shows | 120 ms |
| Displayed | Small, dismissible, hoverable (pointer can move onto it without it vanishing) | — | — | — |
| Dismissed | Fades out | Esc, blur, pointer leaves | Hides | 80 ms ease-in |

**Accessibility**: Linked with `aria-describedby`; reachable by keyboard focus; dismissible with Esc without moving focus; persistent while hovered or focused (WCAG Content on Hover or Focus); text contrast per tokens; on touch, expose the same information in a long-press or inline text.

**Implementation Notes**: Reposition near viewport edges and in RTL; never the sole accessible name of a control.

---

#### Progress Bar / Meter

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: Linear progress toward a defined endpoint (upload, import, checklist completion) or consumption against a limit (storage, seats, API calls).
**When NOT to Use**: Values with no endpoint (use a spinner); rapidly fluctuating values; radial charts (use a chart pattern).

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| Default | Track plus fill; numeric label and unit always visible | — | — | — |
| Increasing | Fill animates to the new value | Server event / poll | Announce at milestones (25/50/75/100%), not every tick | 300 ms ease-out |
| Complete | Fill complete; check icon plus text "Done" | — | Optional status announcement | — |
| Near limit (meter) | Warning icon and text at >= 80% | — | Optional upgrade action | — |
| At limit | Critical icon and text | — | Blocked-state copy per Plan Gate | — |
| Error | Error icon and message; Retry | — | — | — |
| Indeterminate | Subtle motion or static "working" text | — | — | Static under reduced motion |

**Accessibility**: `role="progressbar"` (or `meter` for quotas) with `aria-valuenow/min/max` and `aria-valuetext` ("4 of 5 seats used"); the text value is on screen; thresholds are not colour-only; reduced motion removes fill animation.

**Implementation Notes**: Long-running progress comes from a job resource (ID persisted so reload resumes); usage meters cache with a short `staleTime` and show "updated at" for metered data; the server enforces limits regardless of the meter.

---

#### Input Field

**Category**: Input
**Status**: Draft
**When to Use**: Text, email, password, number, search, date, and short free-text entry.
**When NOT to Use**: Choosing from known options (Select/Radio); long rich content (use an editor component with its own pattern).

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| Default | Visible label above, hint below, border token | — | — | — |
| Hovered | Border tint | Pointer | — | 80 ms |
| Focused | Focus ring; label stays visible | Tab / click | Caret placed; on mobile the correct keyboard shows | 80 ms |
| Typing | Value shown; character counter near the limit | Keystrokes | No validation noise mid-typing | — |
| Filled | Value present; clear button for search fields | — | — | — |
| Limit reached | Counter turns to warning text; input stops or truncates per rule | — | Announce when the limit is reached | — |
| Validation error | Error icon, error text associated, border token (with icon, not colour alone) | Blur or submit | Error shown; summary on submit; focus handling per Form pattern | 100 ms |
| Validated | Optional subtle success icon (only where useful, e.g. username availability) | — | — | — |
| Read-only / Disabled | Distinct tokens; read-only remains focusable and selectable | — | — | — |

**Accessibility**: A visible, persistent `<label>` (placeholder is never the label); hint and error linked via `aria-describedby`; `aria-invalid` set on error; correct `type`, `inputmode`, `autocomplete` tokens (`one-time-code`, `current-password`, `email`) so password managers and OTP autofill work; paste is never blocked; IME composition is respected (Arabic input); mixed-direction values use `dir="auto"` and bidi isolation.

**Implementation Notes**: Validate on blur and on submit, not on every keystroke; the server is the authority (map `errors[]` field codes); never log field values for sensitive inputs; mask secrets; Android `OutlinedTextField` with `KeyboardOptions`, iOS `TextField`/`SecureField` with content types.

---

#### Tab Bar

**Category**: Navigation
**Status**: Draft
**When to Use**: Dividing one screen's content into discrete sections, one visible at a time (max 5–6 tabs).
**When NOT to Use**: More than 6 tabs; content that must be visible simultaneously; navigation between routes with distinct URLs and lifecycles (use navigation, though tabs may be route-backed).

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| Inactive | Label with muted token | — | — | — |
| Active | Label with strong token plus indicator bar/underline (not colour alone) | — | — | — |
| Hovered / Focused | Hover tint; focus ring | Pointer / Tab (one tab stop for the list) | — | 80 ms |
| Activated | Panel content switches | Click / tap; Left/Right arrows move focus; Enter/Space or automatic activation | Panel updates; URL updates when deep-linking matters | 150 ms cross-fade |
| Disabled | Disabled tokens with reason | — | None | — |
| Overflow | Scrollable list or "More" menu | — | — | — |

**Accessibility**: ARIA tabs pattern (`tablist`, `tab`, `tabpanel`, `aria-selected`, `aria-controls`); arrow keys move among tabs, Home/End jump; automatic vs. manual activation is chosen per cost of switching; direction mirrors in RTL (arrow keys follow visual order).

**Implementation Notes**: Mobile top-level destinations use bottom navigation rather than a tab bar inside a screen; keep panel state when switching where cheap; lazy-load heavy panels.

---

#### Scroll Container / Pagination

**Category**: Layout
**Status**: Draft
**When to Use**: Content exceeding its container; long collections loaded incrementally.
**When NOT to Use**: Content better split into pages or sections; infinite scroll without loading/end/error states; nested scroll regions on mobile.

**Interaction Specification**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|----------|
| Content fits | No scrollbar or indicator | — | — | — |
| Scrollable | Scrollbar or fade edge indicates more content | — | — | — |
| Scrolling | Position updates; sticky headers remain | Wheel / touch / keys (Arrow, PageUp/PageDown, Space) | Smooth scroll (instant under reduced motion) | — |
| Loading more | Footer spinner or skeleton rows | Reaching the end or pressing "Load more" | Next cursor requested | — |
| End reached | "You've reached the end" or nothing | — | — | — |
| Error loading more | Inline Retry at the end of the list | — | — | — |
| Focus follows | Focused element is scrolled into view with scroll padding for sticky UI | Tab / arrows | Smooth scroll | 120 ms |

**Accessibility**: A scrollable region is keyboard focusable (`tabindex="0"`) with a label when it has no focusable children; offer a "Load more" button as an alternative to automatic infinite scroll; announce newly loaded counts politely; ensure focus is not lost when items are appended or removed; preserve scroll on back navigation.

**Implementation Notes**: Cursor pagination with `limit` capped by the server; virtualisation for very long lists with accessible position info; avoid layout shift when rows load; Android `LazyColumn` + paging, iOS `List` with pagination triggers.
