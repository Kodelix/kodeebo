> Section-authoring guidance, loaded by `/ux-design` for the ACTIVE MODE ONLY.
> Never load the other two — one mode applies per invocation.

# Section Guidance — App Shell Mode

Section numbers match `.claude/docs/templates/app-shell.md`; the template carries
the prompts for each section. The shell is the persistent frame — navigation,
header, tenant/workspace switcher, global search or command palette,
notifications, global banners, responsive behaviour. The test for membership:
present on most screens and the user does not navigate to it.

Shell design follows a different order from screen specs. Begin with philosophy;
do not touch layout until the information architecture is complete.

#### Section 1: Shell Philosophy

Ask the user to describe the product's relationship with on-screen information in
1-2 sentences, anchored in `PRODUCT.md`'s register and users.

Offer framing examples:
- "Calm and sparse — a few tasks done well; the shell stays out of the way"
- "Dense power-user workspace — everything decision-relevant one click away"
- "Adaptive — density responds to role and task (admin console vs member view)"

Capture the **visibility principle** (show / hide / contextual when in doubt) and
the product's "Rule of Necessity". If a proposed element conflicts with the stated
philosophy, surface that conflict.

---

#### Section 2: Information Architecture

Complete this before any layout work. Do not skip it.

**Step 1 — Full inventory**: pull every navigation entry, widget, notification
type and banner from the feature specs gathered in Section 2c. Present the list:
"These are all the things your features say they need in the shell." Also
include shell-owned items: tenant switcher, user menu, help/support, billing
status, notifications.

**Step 2 — Categorization**, per item:

| Category | Description |
|----------|-------------|
| **Always visible** | Primary navigation, tenant context, user menu |
| **Contextual** | Visible only when relevant (trial banner, near-quota meter, role-specific entries) |
| **On demand** | User must open it (notifications panel, command palette, help) |
| **Hidden** | Not in the shell (reached from within a feature) |

Step through items in groups of 3-4 with `AskUserQuestion`; this is the most
consequential shell decision. **Role and plan awareness**: for each entry state
which roles see it and which plan or entitlement gates it (cite the key; hidden vs
disabled-with-reason). **Conflict check**: if the philosophy says "sparse" but
Always visible keeps growing, surface it with options (reduce, revise philosophy,
move entries behind a hub).

---

#### Section 3: Layout Regions

Only after the information architecture is approved. Base layout on which items
are Always visible, the surfaces and breakpoints targeted, and RTL mirroring.
Offer 2-3 region arrangements (e.g. left sidebar + top bar; top bar only; bottom
tab bar on mobile) with rationale. Fill the Region Diagram and the Region
Specification Table.

---

#### Section 4: Shell Component Specifications

For each element, specify: name and category, content, form (nav item, avatar
menu, badge, banner, drawer), update behaviour (real-time, event-driven,
on-demand), contextual trigger, and its pattern by name from the library
(Banner, Toast, Command Palette, Quota / Usage Meter, Plan Gate). Styling lives in
`DESIGN.md`; reference, do not define.

#### Sections 5-14: States, Hierarchy, Budget, Feedback, Adaptation, Accessibility, Localization, Configuration, Criteria, Questions

**5. Shell States by Context** — at least: first-use/onboarding, normal, trial,
past due / suspended, near-quota, maintenance, offline, impersonation/support
mode if applicable, and per-role variants. `/ux-review` checks these.

**6. Information Hierarchy** — priority tier per element (MUST KEEP, SHOULD KEEP,
CAN COLLAPSE, CAN HIDE) with what carries the information when hidden; this is the
order the shell drops elements on small screens.

**7. Visual & Performance Budget** — maximum simultaneous shell elements and screen
share, per surface; shell JS/CSS payload and time-to-interactive contribution
against `docs/architecture/perf-budgets.md` (the shell loads on every route).

**8. Feedback & Notification Systems** — one row per transient and persistent
notification type: trigger, location, duration, max simultaneous, priority and
**queue behaviour** (two at once, which are held, which are never queued; global
banner precedence: security > billing > maintenance > promotional).

**9. Surface Adaptation** — per-surface overrides: breakpoints, navigation form on
phone, safe-area insets on iOS/Android, touch target sizes, what moves or is
dropped.

**10. Accessibility** — landmarks, skip links, focus management on route change,
contrast, text scaling to 200%, motion sensitivity, user preferences. Cross-
reference `design/accessibility-requirements.md`; note the gap if there is none.

**11. Localization & Direction** — Arabic (RTL) mirroring of the whole shell,
tenant/user names of mixed direction, notification text expansion.

**12. Configuration** — admin- or user-adjustable shell settings with range and
default (density, sidebar collapsed, notification channels). Values are named
config, not literals.

**13. Acceptance Criteria** — at least 5 binary criteria: landmarks and skip link
present, correct elements per role and plan, tenant switch changes scope and
never leaks the previous tenant's data, banner precedence, RTL mirror,
performance contribution, and one accessibility criterion for the committed target.

**14. Open Questions** — owner and deadline each.
