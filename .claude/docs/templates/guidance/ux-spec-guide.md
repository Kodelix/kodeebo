> Authoring guidance for ux-spec.md. Load only the part covering the section currently being authored — not the whole file at once.

# UX Specification Template — Authoring Guidance

Guidance is organised by template section number. When authoring a section of a
product's UX spec, read only that section's guidance below. The worked examples
use a "Team members" settings screen with an invite dialog, on web and mobile,
in Arabic and English.

---

## Section 1 — Purpose & User Need

> **Why this section exists**: Every screen must justify its existence from the
> user's perspective. Screens designed from a developer perspective ("display the
> members table") produce cluttered, confusing interfaces. Screens designed from
> the user's perspective ("let the admin add a colleague confidently without
> wondering what they will be charged") produce purposeful, calm interfaces.
> Write this section before touching any layout decision — it is the filter
> through which every later choice is evaluated.

**Authoring the user need**:

[One paragraph. Name the real human need, not the system function. Consider:
what would a user say they want when they open this screen? What would frustrate
them if it did not work? That frustration describes the need.

Example — bad: "Displays the list of members and a button to invite."
Example — good: "Lets an admin see who has access to the workspace and bring a
new colleague in within a minute, with certainty about their role and the effect
on the bill. The page is the admin's access-control and seat-planning tool."]

**Authoring the user goal**:

[One sentence. Specific enough that you could write an acceptance criterion for it.
Example: "Invite a colleague by email with a role in under 30 seconds and see
their pending status immediately."]

**Authoring the product goal**:

[One sentence. What the system needs from this interaction. Example: "Capture a
valid email and role, create a tenant-scoped invitation within the plan's seat
limit, and record the activation-funnel event."]

---

## Section 2 — User Context on Arrival

> **Why this section exists**: Screens do not exist in isolation. An admin opening
> Team members after a failed-payment banner is in a different state from one
> opening it on day one of a trial. The same information architecture can feel
> oppressively complex in one context and trivially simple in another. Document
> the context so design decisions — what to show first, what to hide, what to
> warn about, what to simplify — are calibrated to the actual person arriving.

**Worked example answers for the context table**:

| Question | Answer |
|----------|--------|
| Who is the user (role, plan, tenant state)? | [e.g. Admin on Team plan, 4 of 5 seats used, trial ended] |
| What were they just doing? | [e.g. Clicked "Invite" in the onboarding checklist / followed a seat-limit banner / opened Settings] |
| What is their emotional state? | [e.g. Focused, slightly anxious about cost and mistakes] |
| What cognitive load are they carrying? | [e.g. Low — a single task; or high — mid-setup with several open tasks] |
| What information do they already have? | [e.g. Knows the colleague's email; may not know the seat limit or role differences] |
| What are they most likely trying to do? | [e.g. Invite one person; occasionally remove a leaver; rarely change a role] |
| What are they likely afraid of? | [e.g. Granting too much access, an unexpected charge, inviting the wrong address] |
| Device, connection and language? | [e.g. Desktop Chrome, Arabic UI, office Wi-Fi; or phone on mobile data] |

**Authoring the emotional design target**:

[One sentence describing the feeling the user should have. Example: "Confident and
in control — the admin knows exactly who has access, what each role can do, and
what the change will cost before they confirm."]

---

## Section 3 — Navigation Position

> **Why this section exists**: A screen that does not know where it sits in the
> navigation hierarchy cannot define its entry/exit transitions, its back
> behaviour, deep-link handling, or its access-control states. Navigation
> position also reveals architectural problems early — if this screen is
> reachable from eight places, that is a complexity flag to resolve in design.

**Worked example — reachability table**:

| Entry Point | Triggered By | Notes |
|-------------|-------------|-------|
| [Side nav → Settings → Team] | [Admin selects "Team"] | [Primary entry point] |
| [Onboarding checklist → "Invite your team"] | [Click on checklist item] | [Systemic entry — pre-opens the invite dialog; must not break if dismissed] |
| [Seat-limit banner → "Manage seats"] | [Click in app-shell banner] | [Lands with seat usage focused] |
| [Invitation email → "Review request" link] | [Link with signed state] | [Requires sign-in; if the user lacks the role, shows forbidden state — not 404 for same-tenant users, 404 for other tenants] |

**Access control example**: Owner and Admin see the full screen. Member and Viewer
do not see the "Team" nav item; opening the URL directly shows a localised
"You don't have access" state with a link back. A user from another tenant who
guesses a member ID receives the not-found state.

---

## Section 4 — Entry & Exit Points

> **Why this section exists**: Entry and exit define the screen's contract with
> the rest of the navigation system. Every entry point must have a corresponding
> exit point. Transitions left undefined become bugs: the user is stuck, loses a
> draft, or lands on the wrong tenant. Fill this table completely before
> implementation. Empty cells mean unfinished design work.

**Worked example — entry table**:

| Trigger | Source Screen / State | Transition Type | Data Passed In | Notes |
|---------|----------------------|-----------------|----------------|-------|
| [Selects Team in settings nav] | [Settings] | [Route push, preserves scroll of previous] | [Tenant ID from session; none in URL] | [Persist filter/sort in query params] |
| [Clicks "Invite" in onboarding] | [Dashboard] | [Route push + dialog open] | [`?invite=1`] | [Dialog opens focused on the email field] |
| [Opens deep link `/settings/team/{member_id}`] | [Email / bookmark] | [Direct load] | [Member ID] | [Not-found state for IDs outside the tenant] |

**Worked example — exit table**:

| Exit Action | Destination | Transition Type | Data Returned / Saved | Notes |
|-------------|------------|-----------------|----------------------|-------|
| [Closes invite dialog with unsaved input] | [Team list, same scroll] | [Dialog close] | [Draft discarded after confirmation] | [Confirm only if the email field is non-empty] |
| [Sends invite] | [Team list, pending row highlighted] | [Dialog close + list refresh] | [Invitation created server-side] | [Announce "Invitation sent to …" via status region] |
| [Selects "Manage billing" link] | [Billing] | [Route push] | [None] | [Team page state is preserved on back] |

---

## Section 5 — Layout Specification

> **Why this section exists**: The layout specification is the handoff artefact
> between UX design and frontend/mobile engineering. It does not need to be
> pixel-perfect — it must communicate hierarchy (what is important), proximity
> (what belongs together) and proportion (what is big vs. small). ASCII
> wireframes achieve this without design software; visual design then follows
> `DESIGN.md` via impeccable. Draw the primary breakpoint, then sketch the
> mobile layout and note RTL mirroring.

**Worked example — wireframe (5.1), desktop**:

```
┌──────────────────────────────────────────────────────────────┐
│ [App shell header — see app-shell.md]                        │
├───────────┬──────────────────────────────────────────────────┤
│ Settings  │  Team members                     [+ Invite]     │ ← PAGE HEADER
│  General  │  4 of 5 seats used  ▓▓▓▓▓▓▓▓░░                   │ ← SEAT METER
│ ● Team    ├──────────────────────────────────────────────────┤
│  Billing  │ [Search…]            [Role ▾]  [Status ▾]        │ ← FILTER BAR
│           ├──────────────────────────────────────────────────┤
│           │ Name / Email        Role      Status     [⋯]     │ ← TABLE
│           │ Amal Hassan         Admin     Active     [⋯]     │
│           │ ali@example.com     Member    Pending    [⋯]     │
│           │ …                                                │
│           │ [Load more]                                       │
└───────────┴──────────────────────────────────────────────────┘
Mobile (390 px): table becomes a list of cards; Invite is a sticky bottom action;
filters collapse into a sheet. In RTL the whole layout mirrors horizontally.
```

**Worked example — layout zones table (5.2)**:

| Zone Name | Description | Approximate Size | Scrollable? | Overflow Behaviour |
|-----------|-------------|-----------------|-------------|-------------------|
| [Page header] | [Title, seat meter, primary action] | [Full content width, ~12% height] | [No] | [Title truncates with tooltip; meter text wraps] |
| [Filter bar] | [Search, role and status filters] | [Full content width, ~8% height] | [No] | [Collapses to a "Filters" button below 768 px] |
| [Members table] | [Rows of members and pending invitations] | [Full width, remaining height] | [Yes — vertical with sticky header] | [Cursor pagination "Load more"; horizontal scroll never at 320 px — cards instead] |

**Worked example — component inventory table (5.3)**:

| Component Name | Type | Zone | Purpose | Required? | Reuses Existing Component? |
|----------------|------|------|---------|-----------|---------------------------|
| [Page title] | [Heading h1] | [Page header] | [Names the screen] | [Yes] | [Yes — PageHeader] |
| [Seat meter] | [Progress + text] | [Page header] | [Shows seats used vs. plan limit with text, not colour alone] | [Yes] | [No — new, uses Progress pattern] |
| [Invite button] | [Primary button] | [Page header] | [Opens invite dialog] | [Yes] | [Yes — Button (Primary)] |
| [Filters] | [Search input + selects] | [Filter bar] | [Narrow the list] | [Yes] | [Yes — Input Field, Dropdown] |
| [Members table] | [Data table] | [Members table] | [List members and invitations] | [Yes] | [Yes — DataTable] |
| [Row actions] | [Menu button] | [Members table] | [Change role, resend invite, remove] | [Yes] | [Yes — Menu] |
| [Empty state] | [Illustration + text + action] | [Members table] | [First-use and no-results states] | [Yes] | [Yes — Empty State pattern] |

**Worked example — primary focus element on open**: the page `h1` receives focus
after a route change (announced); if opened with `?invite=1`, focus lands on the
email field of the invite dialog; if the table is empty, the primary Invite
button is the first interactive element.

---

## Section 6 — States & Variants

> **Why this section exists**: A screen is not a single picture — it is a set of
> states, each of which must look and behave correctly. Screens designed only for
> the happy path ship with broken empty states, invisible loading indicators and
> unhandled errors. Document every state before implementation. The states
> table is also the test matrix for QA and the list of screenshots required as
> evidence.

**Worked example table**:

| State Name | Trigger | What Changes Visually | What Changes Behaviourally | Notes |
|------------|---------|----------------------|---------------------------|-------|
| [Loading] | [Route opened, members not yet loaded] | [Table skeleton rows; Invite button enabled] | [Filters disabled until loaded] | [Skeleton only after 200 ms to avoid flashing; if > 2 s show "Still loading…" status] |
| [Empty — first use] | [Workspace has only the owner] | [Illustration + "Invite your first colleague" + primary action] | [Search and filters hidden] | [Explain what each role can do] |
| [Empty — no results] | [Filters match nothing] | ["No members match" + "Clear filters"] | [Filters stay active] | [Announce result count in a live region] |
| [Populated] | [At least one other member] | [Rows with role, status and actions] | [All permitted actions available] | [Default state] |
| [Seat limit reached] | [Seats used = plan limit] | [Meter full with text; Invite shows "Upgrade to add more"] | [Invite opens an upgrade dialog instead of the form] | [Server also enforces: `plan_limit_reached` 422] |
| [Submitting invite] | [Form submitted] | [Button shows progress; fields read-only] | [Second submit blocked; idempotency key sent] | [Esc cancels the dialog but not the in-flight request] |
| [Validation error] | [Invalid or duplicate email] | [Field error text with icon; error summary at top of dialog] | [Focus moves to the summary / first invalid field] | [Never clear the typed value] |
| [Server error / offline] | [5xx or no connection] | [Inline error with Retry, trace ID for support] | [Draft preserved] | [Use problem `code` to select copy; no internals] |
| [Forbidden] | [Role lacks permission] | ["You don't have access" with contact-admin hint] | [No data requested] | [Same-tenant users get 403 copy; other-tenant IDs show not-found] |
| [Read-only — past due] | [Billing past due] | [Banner explaining; Invite disabled with reason] | [Removing members still allowed] | [Disabled controls explain why via text, not only a tooltip] |

---

## Section 7 — Interaction Map

> **Why this section exists**: This section is the source of truth for what every
> input does on this screen. It forces the designer to think through every input
> method (pointer, keyboard, touch, assistive technology) and every interactive
> state (hover, focus, pressed, disabled, busy). Gaps in this table are bugs
> waiting to happen, and it is the input for the accessibility audit — if an
> action is reachable only by mouse, it fails keyboard and touch columns.

**Worked example — navigation inputs (7.1)**:

| Input | Surface | Action | Visual Response | Notes |
|-------|---------|--------|-----------------|-------|
| [Tab / Shift+Tab] | [Web] | [Move focus through filters, table, row actions] | [Visible focus ring, never hidden behind the sticky header] | [Logical order; mirrored in RTL] |
| [Arrow keys] | [Web] | [Move between rows when the grid pattern is used; within menus and tabs] | [Roving focus indicator] | [Only for composite widgets; follow ARIA Authoring Practices] |
| [Mouse hover] | [Web] | [Show hover state; reveal row-action affordance] | [Subtle background change] | [Hover never hides required actions — row actions are always visible on touch and focus] |
| [Touch tap] | [Mobile] | [Open card details / activate control] | [Pressed state] | [Targets >= 44 pt / 48 dp] |
| [Swipe back] | [iOS / Android] | [Navigate back] | [System animation] | [Do not override system back; unsaved dialog draft confirms] |

**Worked example — action inputs (7.2)**:

| Input | Surface | Context (what must be focused) | Action | Response | Animation | Notes |
|-------|---------|-------------------------------|--------|----------|-----------|-------|
| [Enter / click / tap] | [All] | [Invite button] | [Open invite dialog] | [Dialog opens; focus to email field] | [Fade + scale 150 ms] | [Reduced motion: instant] |
| [Enter] | [Web] | [Email field in dialog] | [Submit when form valid] | [Same as clicking Send] | [None] | [Prevent double submit] |
| [Esc] | [Web] | [Dialog open] | [Cancel] | [Close; confirm if input present] | [Fade 100 ms] | [Focus returns to Invite button] |
| [Enter / click] | [All] | [Row action → Remove] | [Open confirmation] | [Dialog states who is removed, what they lose, and the billing effect] | [Fade 150 ms] | [Destructive style; Cancel is the default focus] |
| [`/` shortcut] | [Web] | [Anywhere on page, focus not in input] | [Focus the search field] | [Search focused] | [None] | [Can be disabled; not active in inputs] |

**Worked example — state-specific behaviours (7.3)**:

| State | Input Restriction | Reason |
|-------|------------------|--------|
| [Loading] | [Filters and row actions disabled] | [No data to act on] |
| [Submitting invite] | [Send disabled; fields read-only] | [Prevent duplicate invitation] |
| [Read-only — past due] | [Invite, role change disabled; remove allowed] | [Billing policy] |

---

## Section 8 — Data Requirements

> **Why this section exists**: The separation between UI and domain state is the
> most important architectural boundary in the client. The UI reads data through
> the API and caches it for experience; it does not own it and it does not
> decide authorisation (the server does). This section defines exactly what data
> the screen needs, where it comes from, and how fresh it must be. Filling this
> table before implementation prevents two failure modes: (1) clients computing
> money, permissions or limits themselves and drifting from the server, and (2)
> backends not knowing they must expose a field until the screen is half-built.

**Worked example table**:

| Data Element | Source (endpoint / contract) | Refresh policy | Owner (context) | Format | Null / Missing Handling |
|--------------|-----------------------------|----------------|-----------------|--------|------------------------|
| [Members + pending invitations] | [`GET /v1/members?cursor&limit`] | [`staleTime` 30 s; invalidated by invite/remove/role-change mutations] | [Identity & Access] | [Array of {id, name, email, role, status, invited_at}] | [Empty array → empty state; never null] |
| [Seat usage and limit] | [`GET /v1/entitlements` (`max_seats`, `seats_used`)] | [`staleTime` 60 s; invalidated on invite and plan change] | [Billing] | [Integers] | [If entitlements fail to load, hide the meter and keep Invite enabled — server enforces] |
| [Roles list] | [Static from contract enum + localised labels] | [Build time] | [Identity & Access] | [Enum strings; unknown values shown as raw label] | [Unknown role displays "Custom"] |
| [Current user's permissions] | [Session / `GET /v1/me`] | [Session lifetime; refreshed on role change event] | [Identity & Access] | [Permission keys] | [If missing, behave as no access] |

---

## Section 9 — Actions & Events

> **Why this section exists**: This is the other half of the UI/server boundary.
> Where Section 8 defines what the UI reads, this section defines what it
> sends and how every outcome is handled. Specifying actions at design time
> prevents UI engineers from inventing business logic and backend engineers from
> being surprised by what the UI does. Every destructive or state-changing
> action appears here, together with the analytics event it emits.

**Worked example table**:

| User Action | API Call / Command | Success handling | Failure handling (problem `code` → message) | Analytics event | Idempotent? |
|-------------|--------------------|------------------|---------------------------------------------|-----------------|-------------|
| [Send invite] | [`POST /v1/invitations` {email, role}] | [Close dialog; row appears as Pending; status announcement] | [`plan_limit_reached` → upgrade dialog; `email_invalid` → field error; `already_member` → field error; 429 → "Try again in N s"] | [`invite_sent` {role}] | [Yes — `Idempotency-Key`] |
| [Resend invite] | [`POST /v1/invitations/{id}/resend`] | [Toast "Invitation resent"] | [429 rate-limit message] | [`invite_resent`] | [Yes] |
| [Change role] | [`PATCH /v1/members/{id}` {role}, `If-Match`] | [Row updates; announce] | [412 → reload row and explain; 403 → forbidden] | [`member_role_changed`] | [Yes — natural key] |
| [Remove member] | [`DELETE /v1/members/{id}`] | [Row removed; announce; seat meter updates] | [409 last-owner → explanation] | [`member_removed`] | [Yes] |

> Analytics events carry no PII (no email addresses); consent is respected —
> see `tracking-plan.md`.

---

## Section 10 — Transitions & Animations

> **Why this section exists**: Transitions are not decoration — they communicate
> hierarchy and causality. A page that slides in from the end side implies
> forward movement; a cross-fade implies a context change. Inconsistent
> transitions make navigation feel broken even when it is technically correct.
> This section ensures transitions are specified, performance-safe, and have a
> reduced-motion fallback from the start. In RTL, "forward" directions mirror.

**Worked example table**:

| Transition | Trigger | Direction / Type | Duration (ms) | Easing | Interruptible? | Reduced Motion Fallback |
|------------|---------|-----------------|--------------|--------|----------------|------------------------|
| [Route enter] | [Navigation] | [Content fade; no layout-shifting slide] | [150] | [Ease out] | [Yes] | [Instant] |
| [Dialog open] | [Invite clicked] | [Backdrop fade to 40%; panel scale 96% → 100%] | [150] | [Ease out] | [No] | [Instant appear] |
| [Dialog close] | [Esc / Cancel / Send] | [Reverse of open] | [100] | [Ease in] | [No] | [Instant] |
| [Skeleton → content] | [Data arrives] | [Cross-fade] | [150] | [Linear] | [Yes] | [Instant swap] |
| [Row insert / remove] | [Invite sent / member removed] | [Height + fade] | [200] | [Ease out] | [Yes] | [Instant; highlight remains for 2 s without animation] |
| [Button press] | [Pointer down] | [Scale 98%] | [60] | [Ease out] | [Yes] | [No scale; colour state change only] |

---

## Section 11 — Input Method Completeness Checklist

> **Why this section exists**: Input completeness is not optional — it is part of
> WCAG 2.2 (keyboard, target size, dragging alternatives) and of store review
> expectations on mobile. Fill the checklist before marking the spec as Approved.
> Any unchecked item blocks implementation start. Mark items that do not apply
> to this screen "N/A — reason" rather than deleting them.

---

## Section 12 — Accessibility

> **Why this section exists**: Accessibility requirements must be specified at
> design time because retrofitting them is expensive and often architecturally
> impractical. This section documents requirements specific to this screen.
> Product-wide standards live in `design/accessibility-requirements.md` — consult
> it before filling this section so you do not duplicate or contradict
> product-level commitments. Run `/impeccable audit` on the implementation and
> attach the result to the story's evidence.

**Worked example — text contrast table**:

| Element | Background Context | Required Ratio | Current Ratio | Pass? |
|---------|-------------------|---------------|---------------|-------|
| [Member name and email] | [Table surface, light and dark theme] | [4.5:1] | [TBD — verify on final tokens] | [ ] |
| [Status chip text "Pending"] | [Chip background] | [4.5:1] | [TBD] | [ ] |
| [Disabled Invite button label] | [Disabled button background] | [Not required for disabled controls, but keep >= 3:1 and add reason text] | [TBD] | [ ] |
| [Focus ring] | [Adjacent surfaces] | [3:1 (non-text contrast)] | [TBD] | [ ] |
| [Seat meter fill vs. track] | [Page background] | [3:1] | [TBD] | [ ] |

**Worked example — colour-only mitigations table**:

| Element | Risk | Mitigation |
|---------|------|------------|
| [Status chip (green Active / amber Pending)] | [Colour is the only differentiator] | [Chip includes text and an icon; colours are supplemental] |
| [Seat meter nearing limit (turns red)] | [Colour-only warning] | [Adds text "4 of 5 seats used" and a warning icon at 80%] |
| [Field error red border] | [Colour-only error] | [Error icon + message associated with the field + summary] |

**Worked example — focus order**:

[e.g.,
1. Skip link (app shell)
2. App shell header and nav (see `app-shell.md`)
3. Page `h1` (programmatic focus target after route change)
4. Invite button
5. Search field
6. Role filter, Status filter
7. Table: first row's primary link; then each row's actions menu button (one tab stop per row; arrows move within the menu)
8. "Load more" button
→ Dialog (when open): focus trapped — email field, role select, Cancel, Send; Esc closes; focus returns to the Invite button.]

**Worked example — screen reader announcements table**:

| State Change | Mechanism | Announcement Text (localised) | Timing |
|--------------|-----------|-------------------------------|--------|
| [Route opens] | [Focus moves to `h1`; document title updates] | ["Team members"] | [After route settles] |
| [Filter applied] | [`role="status"`] | ["3 members shown"] | [After results render] |
| [Invite sent] | [`role="status"`] | ["Invitation sent to ali@example.com"] | [After server confirms] |
| [Validation error] | [`role="alert"` summary + focus to first invalid field] | ["Invitation not sent. Enter a valid email address."] | [On failed submit] |
| [Member removed] | [`role="status"`] | ["Amal Hassan removed. 3 of 5 seats used."] | [After server confirms] |

**Authoring the cognitive load assessment**:

[Estimate the information streams and decisions the user tracks at once. For this
screen: (1) who has access, (2) each person's role, (3) pending vs. active,
(4) seats used vs. limit, (5) billing effect of the change. That is 5 streams —
within the 7±2 guideline but at the high end. Mitigation: the seat meter and
billing effect are shown inside the invite dialog at the moment of decision;
roles have one-line plain-language descriptions; defaults are pre-selected.]

---

## Section 13 — Localization Considerations

> **Why this section exists**: UI built without localisation in mind breaks on
> first translation. Arabic requires right-to-left layout mirroring, different
> line-height and numeral choices; German-style compound words and longer
> phrases can run 30–40% longer than English; some languages are shorter,
> leaving awkward whitespace. These issues are cheap to plan for and expensive to
> fix after layouts ship. Every text element should have an explicit maximum
> length and a plan for overflow, and every string must live in a locale file
> with ICU plural forms where counts appear.

**Worked example table**:

| Text Element | English Baseline Length | Max Characters | Expansion Budget | RTL Behaviour | Overflow Behaviour | Risk |
|--------------|------------------------|----------------|-----------------|---------------|--------------------|------|
| [Page title "Team members"] | [12 chars] | [28 chars] | [133%] | [Aligns to the start (right) edge] | [Truncate with ellipsis and tooltip; title is not critical] | [Low] |
| [Seat meter text "4 of 5 seats used"] | [18 chars] | [40 chars] | [122%] | [Numerals localised per locale policy; sentence order may change] | [Wrap to two lines] | [Medium — plural and numeral forms] |
| [Button "Invite"] | [6 chars] | [16 chars] | [167%] | [Mirrored position; icon after label in RTL] | [Shrink font to 90%, then wrap] | [Medium] |
| [Member name / email] | [~20 chars avg] | [60 chars] | [200%] | [Email shown LTR-isolated within an RTL row] | [Truncate in middle for emails, tooltip with full value] | [Medium — bidi mixing] |
| [Role description] | [~60 chars] | [120 chars] | [100%] | [Start-aligned] | [Wrap; row height grows] | [Low] |

---

## Section 14 — Acceptance Criteria

> **Why this section exists**: Acceptance criteria are the contractual definition
> of "done." Without them, implementation is complete when the developer says it
> is. With them, it is complete when a QA tester can verify every item. Write
> criteria a tester can verify independently, without asking the designer what
> they meant. Every criterion is binary — pass or fail. Include negative and
> cross-tenant cases.

**Worked example criteria (Team members screen)** — note how each is
screen-specific and independently verifiable:

- [ ] Inviting an address already in the workspace shows the `already_member` field error without clearing the field
- [ ] When seats used equals the plan limit, Invite opens the upgrade dialog and no invitation is created (server returns `plan_limit_reached` if forced)
- [ ] A Member-role user who opens `/settings/team` sees the forbidden state and no member data is requested
- [ ] A request for a member ID from another tenant renders the not-found state and leaks no data
- [ ] Removing the last Owner is blocked with an explanation
- [ ] Submitting the invite twice quickly creates exactly one invitation
- [ ] The table is fully operable by keyboard and the focus ring is never hidden behind the sticky header
- [ ] Screen reader announces results count after filtering and confirmation after invite/remove
- [ ] Layout is correct at 390 px in Arabic (RTL) with the longest role label

---

## Section 15 — Open Questions

**Worked example questions**:

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Should a pending invitation count against the seat limit?] | [pricing-billing-designer] | [Before spec approval] | [Pending — affects `pricing-model.md` entitlement rules] |
| [Do we need bulk invite (CSV) in the first release?] | [product-manager] | [Sprint 4, Day 3] | [Pending — scope decision] |
| [Should the table use the ARIA grid pattern or a plain table with row-level menus?] | [web-lead + ux-designer] | [Sprint 4, Day 3] | [Pending — decide with accessibility-specialist] |
| [What is the invitation expiry default?] | [product-manager] | [Spec] | [Pending — configuration value, not hardcoded] |
