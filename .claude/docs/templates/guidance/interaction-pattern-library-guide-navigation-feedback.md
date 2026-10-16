> Authoring guidance for interaction-pattern-library.md. Load only the part covering the section currently being authored — not the whole file at once.

> Covers: **Navigation Patterns** (Screen Push / Pop / Replace, Focus Management, Escape / Cancel) and **Feedback and Loading Patterns** (Loading State, Empty State, Error State, Success Confirmation, Optimistic UI, Offline / Degraded) — full reference specifications.

## Navigation Patterns

---

#### Screen Push / Pop / Replace

**Category**: Navigation
**Status**: Draft

These three patterns define how routes and screens enter and leave history.

| Pattern | Trigger | Animation | History Behaviour | Focus Behaviour |
|---------|---------|-----------|------------------|-----------------|
| Push | Navigate deeper (open a detail page, open a settings section) | Content cross-fades (web); platform push transition (Android/iOS). Previous screen state is preserved. | New entry added to history; scroll and filter state of the previous screen kept | Focus moves to the new page's `h1` (web) / first accessibility element (mobile); the change is announced and the document title updates |
| Pop (Back) | Browser Back, in-app Back, system back gesture, Esc in a dialog | Reverse of the push transition | Entry removed; previous screen restored with its scroll and filters | Focus returns to the element that triggered the Push; if gone, to the nearest preceding interactive element |
| Replace | Navigate to a peer (switching top-level sections, tenant switch, post-login redirect, wizard completion) | Cross-fade, no directional bias | Current entry replaced; no way back to a transient step (e.g. login) | Focus moves to the new page `h1`; announced |

**Animation durations**: Push/Pop 150 ms ease-in-out on web, platform-native on mobile. Replace 150 ms cross-fade.

**Motion reduction**: All transitions become instant or cross-fade at 50% duration.

**Implementation Notes**:
- Web: use the pinned router; every route has a unique, descriptive `<title>`; restore scroll on back; avoid trapping users with redirects (replace, don't push, for auto-redirects); guard unsaved changes with the router's blocker and a confirmation dialog; deep links must work for every route that can be bookmarked or emailed.
- Android: navigation component/back stack, predictive back supported, state saved across process death.
- iOS: `NavigationStack`, swipe-back preserved, state restored.
- Tenant switch is a Replace to the tenant's home and **clears every client cache keyed by tenant**.

---

#### Focus Management

**Category**: Navigation
**Status**: Draft

> Focus management is the most common keyboard and screen-reader failure in web
> and mobile apps. These rules must be implemented consistently. A user should
> never be in a state where they cannot see which element is focused, or where
> Tab or a screen-reader swipe produces no visible or audible result.

| Rule | Description |
|------|-------------|
| Route open | Focus is placed on the page heading (programmatic, `tabindex="-1"`) so screen readers announce the new page and keyboard users start at the top of the content; skip link remains the first tab stop. On mobile, accessibility focus moves to the screen title. |
| Route close / back | Focus returns to the element that triggered the navigation (the link or row). If that element no longer exists, focus goes to the nearest preceding interactive element or the page heading. |
| Dialog / sheet open | Focus is trapped inside; initial focus goes to the first field or, for confirmations, the safe action (Cancel). Background is inert. See Modal Dialog. |
| Dialog / sheet close | Focus returns to the trigger. |
| Inline content added | When new content appears (error summary, expanded section), move focus only if the user must act on it (error summary); otherwise announce with a live region. |
| Element disabled | If the focused element becomes disabled, focus moves to the next available interactive element; never to `body`. |
| Element removed | If the focused element is removed (row deleted), focus moves to the next row, else the previous one, else the list heading or empty-state action. |
| Tab order | Follows reading order (mirrored in RTL). No positive `tabindex`. Composite widgets (menus, tabs, grids, listboxes) use one tab stop and roving focus with arrow keys. |
| Focus is always visible | A focus indicator with at least 3:1 contrast is always visible for keyboard and switch users. Never suppress outlines. Focus must not be obscured by sticky headers, cookie banners or chat widgets (WCAG 2.2 Focus Not Obscured). Use `scroll-padding`/`scroll-margin` for sticky UI. |
| Mobile screen readers | Group related elements, set a logical traversal order, avoid focus traps in bottom sheets, restore focus to the invoking control. |

---

#### Escape / Cancel

**Category**: Navigation
**Status**: Draft

> The "go back / cancel" action is the most-used navigation input. It must be
> consistent across every screen with no exceptions.

| Surface | Input | Behaviour |
|---------|-------|-----------|
| Web (keyboard) | Esc | Close the top-most dialog, popover, menu or combobox list; otherwise nothing (Esc does not navigate away from a page) |
| Web (browser) | Back | Previous history entry; unsaved-changes guard applies |
| Android | System back / predictive back | Close top-most sheet or dialog, else pop the back stack; at the root, standard system behaviour |
| iOS | Swipe-back, Cancel/Close button, `Esc` with hardware keyboard | Same as above |
| Touch (any) | Tap outside a dismissible overlay | Dismiss if no unsaved input; otherwise confirm |

**Rules**: This input must never be overridden to do something other than "go
back / cancel." If a state genuinely cannot be dismissed (a blocking billing
error, a required acceptance), say so in the UI and do not silently ignore the
input. Every screen defines its Escape behaviour explicitly in its UX spec, and
every cancel path preserves or confirms discarding user input.

---

## Feedback and Loading Patterns

---

#### Loading State

**Category**: Feedback
**Status**: Draft

| Scope | Pattern | Notes |
|-------|---------|-------|
| Initial route load | App shell renders immediately; content region shows a skeleton that matches the final layout | Never a blank white screen. Static assets are cached; shell JS stays within the performance budget. |
| Route transition | Keep the previous content visible until the next is ready (or show a thin top progress bar after 200 ms) | Avoid flashing skeletons for fast transitions. |
| Component / inline | Skeleton placeholder or small spinner replaces only the loading component; layout does not shift when content arrives | Reserve space for images and charts to keep CLS within budget. |
| Background / async | No indicator under ~1 s; after 1–2 s show a subtle in-place indicator or toast; for long jobs use the Async Job Status pattern | Do not flash indicators for fast operations. |
| Mutations | The triggering control shows a busy state and is protected from double submit | The rest of the form stays readable. |

**Accessibility**: Use `aria-busy` on regions that are updating and a polite live-region message such as "Loading members" and "Members loaded" (localised) for significant loads; skeletons are hidden from assistive technology; timeouts surface an error state with Retry. Respect reduced motion for shimmer.

---

#### Empty State

**Category**: Feedback
**Status**: Draft

> Empty states are consistently the least-designed part of SaaS interfaces — and
> the first thing every new customer sees. Every empty list and table must have a
> designed empty state. The empty state is not an error — it is a starting point.

| Location | Empty State Content | Notes |
|----------|--------------------|----|
| Project list (first use) | Illustration or icon. Message: "No projects yet." Sub-message: "Create your first project to start tracking work." Primary action: "Create project" | Explains value and gives the next action; offers a sample project if it fits the product. |
| Members (only the owner) | Icon. Message: "It's just you for now." Sub-message: "Invite colleagues and choose what each can do." Primary action: "Invite" | Link to role descriptions. |
| Search / filters with no matches | Message: "No results for “[term]”." Sub-message: "Try a different search or clear the filters." Action: "Clear filters" | Mirror the term back (escaped); do not use the first-use copy. |
| Section the user may not see | Message: states that the section needs a role or plan; action: "Ask your admin" or "See plans" | Do not reveal data; see Permission-Denied. |
| Report with no data yet | Message explaining when data appears ("Data appears after the first day of activity") | Avoid empty charts with axes and no explanation. |

**Rule**: Every empty state includes an icon or illustration, a message, and either a sub-message or an action. Distinguish "nothing yet" from "no results for these filters" from "you can't see this". A blank container with no explanation is never acceptable. Empty-state copy is localised in Arabic and English and reviewed for tone.

---

#### Error State

**Category**: Feedback
**Status**: Draft

| Error Type | Pattern | Tone |
|-----------|---------|------|
| Field validation | Inline message below the field, error icon, `aria-describedby`; error summary at the top of the form on submit with links to fields; red border only as a supplement | Specific and neutral — "Enter an email address like name@example.com." Not "Invalid input." |
| Operation failed (4xx business error) | Toast for non-critical, inline banner or dialog for blocking; message chosen from the stable problem `code` | Calm and actionable — "You've reached the 5-project limit on your plan." with an action |
| Network offline / timeout | Banner "You're offline" or inline Retry; drafts kept; queued writes where safe | Reassuring — nothing is lost |
| Server error (5xx) | Inline or full-page error with a Retry action and the `trace_id` the user can quote to support | Acknowledge, give an action, never expose internals or stack traces |
| Rate limited (429) | Message with when to retry (`Retry-After`) | Neutral; do not blame |
| Forbidden / Not found | Permission-Denied & Not-Found pattern | Same-tenant forbidden vs. other-tenant not-found (no existence leak) |
| Session expired (401) | Preserve the draft, re-authenticate, return to the same place | Brief, no data loss |

**Principle**: Error messages are never the user's fault. They say what happened
and what to do next. Remove the word "invalid" from messages — replace it with a
specific explanation. Messages are localised from the problem `code`; the server's
`detail` is never shown verbatim if it is not localised or may contain internals.

---

#### Success Confirmation

**Category**: Feedback
**Status**: Draft

| Action Type | Confirmation | Notes |
|-------------|--------------|-------|
| Save settings | Inline "Saved" status near the control, announced politely | Do not use a toast for every autosave |
| Create / invite / send | Toast with the object name and, where useful, a link to it; list updates in place | Announce via live region |
| Delete | Toast with Undo for a limited window (soft delete) or confirmation page after a hard delete | Undo must really restore |
| Purchase / plan change | Dedicated confirmation screen with plan, amount, next billing date, and a receipt link; email sent | Never rely on a toast alone for money |
| Long job complete | In-app notification and optional email with a link | Link authorised and expiring |

---

#### Optimistic UI

**Category**: Feedback
**Status**: Draft

**When to Use**: Low-risk, highly likely to succeed actions (toggle, rename, reorder, mark as read) where perceived speed matters.
**When NOT to Use**: Payments, destructive actions without Undo, permission or role changes, anything with server-side validation that is likely to fail, anything affecting another user's view immediately.

**Behaviour**: Apply the change locally, send the mutation with an idempotency key, reconcile with the response. On failure revert the change, announce the failure, keep the user's input, and offer Retry. Client caches are a UX layer: invalidate related queries after the mutation settles, never treat optimistic data as truth.

**Implementation Notes**: Web — TanStack Query mutation with `onMutate`/rollback; Android/iOS — repository with pending-state flag; never optimistic across tenant switches.

---

#### Offline / Degraded

**Category**: Feedback
**Status**: Draft

| Situation | Behaviour | Notes |
|-----------|-----------|-------|
| Web offline | Banner; cached views read-only; writes disabled with an explanation or queued if the feature supports it | Service-worker caching only for static assets unless an ADR decides otherwise |
| Mobile offline | Cached data shown with a "last updated" time; writes queued with visible pending state; conflict resolution rule documented (last-write-wins vs. merge) | Queue is bounded and survives restart |
| API 503 / dependency outage | Banner "Some features are temporarily unavailable"; affected sections show an inline error; unaffected sections keep working | Link to the status page |
| Provider outage (payments, email) | Feature-specific message and retry later; never lose the user's intent | |
| Read-only mode (past due, suspended, maintenance) | Banner explains why and what to do; read and export remain available | See `app-shell.md` |
