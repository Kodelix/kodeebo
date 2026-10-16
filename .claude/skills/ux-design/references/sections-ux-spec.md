> Section-authoring guidance, loaded by `/ux-design` for the ACTIVE MODE ONLY.
> Never load the other two — one mode applies per invocation.

# Section Guidance — UX Spec Mode

Section numbers match `.claude/docs/templates/ux-spec.md`. Worked examples per
section are in `.claude/docs/templates/guidance/ux-spec-guide.md` — load only the
section you are authoring.

**In this file:**

- Section 1: Purpose & User Need
- Section 2: User Context on Arrival
- Section 3: Navigation Position
- Section 4: Entry & Exit Points
- Section 5: Layout Specification
- Section 6: States & Variants
- Section 7: Interaction Map
- Section 8: Data Requirements
- Section 9: Actions & Events
- Section 10: Transitions & Animations
- Section 11: Input Method Completeness Checklist
- Section 12: Accessibility
- Section 13: Localization Considerations
- Section 14: Acceptance Criteria
- Section 15: Open Questions

#### Section 1: Purpose & User Need

This section is the foundation. Every other decision flows from it.

**Questions to ask**:
- "What job does this screen do for the user? What is the user trying to DO here?"
- "What would go wrong if this screen didn't exist or was hard to use — for the user, and for the business (activation, support load, churn, a wrong charge)?"
- "Complete this sentence: 'The user arrives at this screen wanting to ___.' "

Cross-reference the user journey context gathered in Section 2. The stated purpose
must align with the journey phase and emotional state. State the need from the
user's side, not the system function ("see why last month's invoice is higher",
not "display invoice list").

---

#### Section 2: User Context on Arrival

Fill the template's table; the SaaS-specific rows matter most.

**Questions to ask**:
- "Who arrives here — which role, on which plan, in what tenant state (trial, past due, near quota, first use)?"
- "What were they just doing immediately before? An email link, a notification, a failed action?"
- "What emotional state should the design assume? (rushed, careful, anxious about money or data loss)"
- "Do they arrive voluntarily, or were they sent here by a gate, a banner or an error?"
- "Device, connection and language: desktop or phone, slow network, Arabic or English?"

Offer to map this against the journey phases if the user journey doc exists.

---

#### Section 3: Navigation Position

Where does this screen sit in the product's navigation hierarchy? A one-paragraph
orientation map — not a full flow diagram.

**Questions to ask**:
- "Is this reached from the app shell navigation, from another screen, from an email or a deep link?"
- "Is it a top-level destination or context-dependent (only for some roles, plans or states)?"
- "Can it be reached from more than one place? Which URL / route / deep link identifies it?"
- "Does it live inside a tenant (workspace) scope, and what happens on tenant switch?"

Present as: "This screen lives at: [root] → [parent] → [this screen]" plus alternate
entry paths and the route/deep link. If it is a slide-over or dialog on top of a
list, say so (hybrids are screen specs).

---

#### Section 4: Entry & Exit Points

Map every way the user can arrive at and leave this screen.

**Questions to ask**:
- "What are all the ways a user can reach this screen?" (nav item, button, email link, notification, redirect after sign-in, direct URL)
- "What can the user do to exit? What happens when they do?" (back, save, cancel, timeout, session expiry)
- "Are there exits that lose work — unsaved changes, a half-completed wizard — and what warns the user?"
- "What happens on a direct URL visit by a user who lacks the role or belongs to another tenant?" (the answer is a Section 6 state, never a leak)

Present as two tables:

| Entry Source | Trigger | User carries this context |
|---|---|---|
| [screen/event] | [how] | [state/data they arrive with] |

| Exit Destination | Trigger | Notes |
|---|---|---|
| [screen/event] | [how] | [irreversible state changes, unsaved-work guard] |

---

#### Section 5: Layout Specification

The largest and most interactive section. Work through it in sub-sections:

**5.4 Information Hierarchy first** (establish this before any layout):
- Ask the user to list every piece of information this screen must communicate.
- Then ask them to rank the items: "What is the single most important thing the user needs to see first? What is second? What can be discovered rather than immediately visible?"
- Present the resulting hierarchy for approval before moving to zones.

**5.2 Layout Zones**:
- Based on the hierarchy, propose rough zones (page header, filter bar, content area, side panel, action bar, footer). Reference the app shell regions so the spec does not redraw the shell.
- Offer 2-3 zone arrangements with rationale for each. Account for desktop, tablet and phone (390 px), and for RTL mirroring.
- Use `AskUserQuestion` to capture the choice:
  - "Which zone arrangement fits best?"
  - Options: [the 2-3 named arrangements you just presented] + "None — build a custom arrangement"

**5.3 Component Inventory**:
- For each zone, list the components it contains. For each note: component type (button, table, form field, card, chart, tabs…), content it displays, whether interactive, **which pattern from the library it uses (by name)**, and which `DESIGN.md` component or token it maps to (by name only — never define values here). A component that introduces a new pattern is flagged for the library.

**5.1 ASCII Wireframe**:
- Offer an ASCII wireframe based on the zones and components.
- Use `AskUserQuestion`: "Want an ASCII wireframe as part of this spec?" — Options: "Yes, include one", "No, I'll attach a separate file"
- If yes, produce it in conversation first; ask for feedback before writing it to file.

---

#### Section 6: States & Variants

Guide the user to think beyond the happy path. **This table is the QA test
matrix.** Work through these one at a time:

- "What does this screen look like the very first time, with no data? (empty — first use; what is the one next action?)"
- "What if filters or search return nothing? (empty — no results; different from first use)"
- "What is shown while loading? (skeleton, no layout shift) and partially loaded?"
- "What happens when something goes wrong? (validation error, server error with problem `code`, offline, stale/conflict)"
- "**Permission**: what does each role see? A role that lacks access — hidden, disabled with a reason, or a forbidden page? And a user of another tenant (not found, never a hint the record exists)?"
- "**Plan**: what if the feature is not in the plan (upgrade prompt), or the quota is reached (plan-limit state, at 80% warning and at 100%)? Cite the entitlement key from the pricing model."
- "**Tenant/billing state**: trial ended, past due, suspended — read-only variant and the banner that explains it."
- "Does it behave differently on any supported surface (web, Android, iOS)?"

Present the collected states as a table for approval:

| State Name | Trigger | What Changes Visually | What Changes Behaviourally | Notes (copy key, retry) |
|---|---|---|---|---|
| Populated | Normal load | — | — | |
| Empty (first use) | No records | [description] | [primary action] | |
| Forbidden | Role lacks `permission.key` | [hidden / disabled + reason] | | |
| Plan-limit reached | `max_x` reached | [meter + upgrade prompt] | create blocked | |

State **roles by name** from the feature spec / registry, not by assumption. If
the role list is unknown, that is an Open Question, not a guess.

---

#### Section 7: Interaction Map

For each interactive component identified in Section 5, define:
- The action (click, tap, press, hold, scroll, drag, type, paste)
- The input(s) that trigger it per surface (mouse click, touch tap, keyboard Enter/Space, shortcut)
- The immediate feedback (visual, announced, haptic on mobile)
- The outcome (navigation target, state change, data write)

Use the surfaces resolved in Section 2h — do not ask again. State them upfront:
"Mapping interactions for: [surfaces]." Work through components one at a time.
For navigation actions, verify the target matches an existing UX spec or note a
spec dependency. Fill 7.1 Navigation Inputs, 7.2 Action Inputs and 7.3
State-Specific Behaviours as the template lays them out; sensitive operations
(delete, role change, billing change, revealing a secret) state their
confirmation pattern by name.

---

#### Section 8: Data Requirements

Cross-reference the feature-spec Data & Contracts section gathered in Section 2.

For each piece of information the screen displays, ask:
- "Where does this data come from? Which bounded context owns it, and which `contracts/` operation returns it?"
- "Does this screen write data back, or is it read-only?"
- "Is any of it time-sensitive or real-time? How stale may it be, and how does it refresh (poll, refetch on focus, push)?"
- "Is any of it sensitive (PII, secrets, money) — what is masked, and who may reveal it?"

Flag any case where the UI would need to own or compute server state (money
shown must come from the server's `amount_minor` + `currency`, never recomputed).
UX specs define what the UI needs; they do not dictate how it is delivered — that
is an architecture decision (`api-designer`, `/api-contract`).

| Data | Owning context / operation | Read / Write | Freshness | Sensitive? | Notes |
|------|---------------------------|--------------|-----------|------------|-------|

---

#### Section 9: Actions & Events

Every user action that changes state appears here with its API call and analytics
event. Questions: "For each action, what is the operation, what does success do,
and how is each error `code` shown?" Cover `plan_limit_reached`, forbidden,
validation, conflict (412) and network failure. Mark each action idempotent or
not (Idempotency-Key for creating/charging). Analytics events come from the
tracking plan (`docs/analytics/tracking-plan.md`, `product-analytics-engineer`);
an action with no event states "no event" and why. Events never carry PII.

---

#### Section 10: Transitions & Animations

Specify how the screen enters and exits, and how it responds to state changes.

**Questions to ask**:
- "How does it appear and dismiss? (route change, slide-over, dialog, instant)"
- "Which in-screen transitions need motion? (skeleton → content, optimistic update, success, error)"
- "What is the reduced-motion behaviour?" (instant or cross-fade — mandatory)

Minimum: enter, exit, and one state-change transition if there are several states.
Motion values (duration, easing) come from `DESIGN.md`; reference them by name.

---

#### Section 11: Input Method Completeness Checklist

Use the template's checklist blocks (keyboard, pointer, touch, assistive
technology), keeping only the blocks for the surfaces in the spec's Surface Target
and saying which were dropped. Tick an item only when the Interaction Map already
specifies it; an unticked item is an open implementation question — list it under
Open Questions rather than ticking it. Any unchecked item blocks Approved.

---

#### Section 12: Accessibility

Cross-reference `design/accessibility-requirements.md` if it exists — the target
there (A / AA / AA+) is the bar.

Walk through for this screen:
- Contrast table for text, icons, borders and focus ring in light and dark
- Colour-only information and its mitigation (status chips, chart series, field errors)
- Numbered focus order covering every interactive element, dialog trap and return
- Screen reader announcements for state changes (saved, error, results loaded, route changed): mechanism, localized text, timing
- Forms: visible labels, errors associated and summarized, no placeholder-as-label, accessible authentication, redundant entry avoided
- Reduced-motion alternative for any animation
- Cognitive load: concurrent streams and decisions, mitigations

If no accessibility target has been defined for the product, note the gap in Open
Questions: "Accessibility target not yet defined — WCAG 2.2 AA used as the
baseline. Run `/ux-design accessibility`." Then continue without stopping.

---

#### Section 13: Localization Considerations

Arabic (RTL) and English (LTR) both ship. Document constraints:

**Questions to ask**:
- "Which text elements are longest? What maximum character count fits the layout?"
- "Where is text length layout-critical — a button label on one line, a table column, a toast?"
- "Which elements mirror in RTL and which do not (brand marks, media controls, numerals with units, chart time axes)? Which icons imply direction?"
- "Which values need locale formatting — dates, numbers, currency, units — and where is mixed-direction content (emails, URLs, IDs, product names) shown?"

Flag any element where a 40% expansion would break the layout as HIGH priority
for `localization-lead`. Server messages are localized from the problem `code`,
not shown from `detail`.

---

#### Section 14: Acceptance Criteria

Write specific, testable criteria that a QA tester can verify without reading any
other design document. These become pass/fail conditions for `/story-done`
(UI story type: retained screenshot of every screen touched plus a
`/impeccable audit` result in `production/qa/evidence/`).

**Format**: checkboxes, each binary and verifiable by a human tester.

**Minimum required**:
- 1 performance criterion (first meaningful content / interaction latency / API calls on load)
- 1 navigation criterion (an entry or exit path verified)
- 1 error/empty state criterion
- 1 accessibility criterion (per the committed target)
- 1 localization criterion (Arabic RTL layout and no overflow)
- 1 **cross-tenant** criterion (user of tenant B cannot see tenant A's data via this screen, verified by route/ID tampering) when the screen shows tenant data
- 1 **role/plan** criterion (each variant in Section 6 shows the specified behaviour)
- 1 criterion specific to this screen's core purpose

Use `AskUserQuestion` to confirm: "Do these acceptance criteria cover what would
make this screen 'done' for your QA process?" Options: "Yes — these are solid",
"Add one more criterion", "Remove or rephrase one".

---

#### Section 15: Open Questions

Each question has an owner and a deadline. An Approved spec has zero open
questions — resolve each or document the deferral rationale. Carry forward every
"not run" or "absent" item flagged during Sections 2 and 5 (no journey map, no
`DESIGN.md`, no accessibility target, roles unknown, contract needed).
