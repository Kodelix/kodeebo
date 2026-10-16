# App Shell Design: [Product Name]

> **Status**: Draft | In Review | Approved | Implemented
> **Author**: [Name or agent — e.g. ux-designer]
> **Last Updated**: [Date]
> **Product**: [Product name — a single document per product, not per screen]
> **Surfaces**: [Web app (desktop/tablet/mobile browser) · Android · iOS · embedded/admin console]
> **Related Specs**: [Every feature spec that exposes navigation, widgets or notifications in the shell — e.g. `design/specs/team-invitations.md`, `design/specs/billing.md`]
> **Accessibility target**: [WCAG 2.2 AA | AAA for specific flows — per `design/accessibility-requirements.md`]
> **Style Reference**: [`DESIGN.md` at the repo root (impeccable) — tokens, type, spacing, components live there, not here]
> **Template**: App Shell

> **Note — Scope boundary**: This document specifies the persistent frame around
> every screen: navigation, header, tenant/workspace switching, global search or
> command palette, notifications, dashboard region, global status banners
> (trial, past-due, maintenance, offline) and responsive behaviour. Individual
> screens, forms and flows use `ux-spec.md`. The test: if it is present on most
> screens and the user does not navigate to it, it belongs here.

---

## 1. Shell Philosophy

**What is this product's relationship with on-screen information density?**

[One-paragraph design statement: calm and sparse vs. dense power-user workspace; who the shell optimises for.]

**Visibility principle** — when in doubt, show or hide?

[Default for ambiguous cases: HIDE / SHOW / CONTEXTUAL (progressive disclosure).]

**The Rule of Necessity for this product**:

["A shell element earns its place when ______________." — e.g. "it is needed on most screens or prevents a costly mistake."]

---

## 2. Information Architecture

> Categorise EVERY piece of cross-cutting information the product exposes. This
> is the master inventory, not just what appears in the shell.

| Information Type | Always Show | Contextual (show when relevant) | On Demand (menu/command) | Hidden (settings / docs) | Reasoning |
|-----------------|-------------|--------------------------------|------------------------|--------------------------|-----------|
| [Current tenant/workspace, user identity, plan badge, notifications count, global search, help, usage vs. quota, trial days left, sync status, environment (staging/prod)] | [ ] | [ ] | [ ] | [ ] | [Why this presentation] |

---

## 3. Layout Regions

### 3.1 Region Diagram

```
[Draw the shell layout. Customise to the actual product. For RTL, state that the
 diagram mirrors horizontally — navigation moves to the right edge.]

 ┌───────────────────────────────────────────────────────────┐
 │ [HEADER]  Logo/Workspace switcher   Search / ⌘K   Notifs  Account │
 ├───────────┬───────────────────────────────────────────────┤
 │ [SIDE NAV]│ [PAGE HEADER]  Title · breadcrumb · primary action │
 │  Section  ├───────────────────────────────────────────────┤
 │  Section  │ [CONTENT REGION]                              │
 │  Settings │   (screens from ux-spec.md render here)       │
 │           │                                               │
 │ [Usage /  │ [GLOBAL BANNER SLOT: trial / past due / outage] │
 │  upgrade] │                                               │
 └───────────┴───────────────────────────────────────────────┘
 Mobile (< 768 px): bottom tab bar or drawer replaces side nav; header collapses.
```

### 3.2 Region Specification Table

| Region | Position (LTR / RTL) | Persistent? | Primary elements | Max simultaneous elements | Collapses at | Notes |
|--------|---------------------|-------------|------------------|--------------------------|--------------|-------|
| [Region] | [Position] | [Yes/No] | [Elements] | [N] | [breakpoint] | [Purpose] |

**Breakpoints and adaptation**:

| Surface | Breakpoint / size class | Layout | Navigation pattern | Notes |
|---------|------------------------|--------|-------------------|-------|
| Web | >= 1280 px | [Full side nav + content] | Side nav | |
| Web | 768–1279 px | [Collapsed icon rail] | Rail | |
| Web | < 768 px | [Single column] | Drawer or bottom tabs | |
| Android | Compact / Medium / Expanded window size class | | Bottom bar / rail / drawer | |
| iOS | Compact / Regular size class | | Tab bar / sidebar (iPad) | |

---

## 4. Shell Component Specifications

### 4.1 Component Overview Table

| Component | Region | Always Visible | Visibility Trigger | Data Source (owning feature) | Update Frequency | Permission / Entitlement gate | Accessibility Alt |
|-----------|--------|---------------|-------------------|------------------------------|-----------------|------------------------------|------------------|
| [Component] | [Region] | [Yes/No] | [Trigger or N/A] | [Feature / API] | [On load / realtime / poll] | [role, plan, flag] | [Keyboard / SR behaviour] |

### 4.2 Component Detail Blocks

> One block per component above. Typical: primary navigation, workspace/tenant
> switcher, user menu, global search / command palette, notification center,
> usage meter, upgrade prompt, help/feedback entry, global banner slot.

---

**[Component Name]**

- Visual description: [Shape, states, density; reference tokens in `DESIGN.md`]
- Data displayed: [Fields; truncation; localisation of numbers/dates]
- Update behaviour: [Optimistic / realtime / manual refresh; caching, `staleTime`]
- States: [default · hover · focus · active · disabled · loading · error · empty]
- Interaction: [Click, keyboard shortcut, gestures; focus management on open/close]
- Permissions: [Which roles see it; what a restricted user sees instead]
- Customisation: [Collapse, pin, reorder — persisted per user, not per device only]

---

**[Repeat this block for every component in 4.1]**

---

## 5. Shell States by Context

> Define how the shell transforms in every context — at minimum: normal,
> loading, empty workspace, offline/degraded, read-only (suspended/past due/
> trial expired), maintenance, impersonation (support), and forbidden.

| Context | Elements Shown | Elements Hidden | Elements Modified | Transition Into This State |
|---------|---------------|-----------------|------------------|---------------------------|
| [Normal / First-run empty / Loading / Offline / Read-only (billing) / Trial ending / Maintenance / Admin impersonation / Session expired] | [Shown] | [Hidden] | [Modified] | [Trigger + timing; banner copy key] |

---

## 6. Information Hierarchy

> Assign every shell element a priority tier (MUST KEEP / SHOULD KEEP / CAN
> HIDE / ALWAYS HIDE) — this is what survives on small screens and in
> constrained contexts.

| Element | Priority Tier | Reasoning | What Replaces It If Hidden |
|---------|--------------|-----------|---------------------------|
| [Element] | [MUST KEEP / SHOULD KEEP / CAN HIDE / ALWAYS HIDE] | [Why] | [Overflow menu, command palette, or N/A] |

---

## 7. Visual & Performance Budget

> Hard limits, not guidelines. An addition that breaches a limit must displace
> or shrink an existing element and needs explicit approval.

| Budget Constraint | Limit | Measurement Method | Current Estimate | Status |
|------------------|-------|--------------------|-----------------|--------|
| Primary navigation items (top level) | [<= 7] | Count | [TBD] | [To verify] |
| Maximum simultaneous banners | [1 blocking + 1 informational] | Count | [TBD] | [To verify] |
| Header height / nav width | [56 px / 240 px, 64 px rail] | Measure | [TBD] | [To verify] |
| Authenticated shell initial JS | [<= 170 KB gzipped, routes code-split] | Bundle analyzer | [TBD] | [To verify] |
| Shell LCP / INP / CLS | [<= 2.5 s / <= 200 ms / <= 0.1 (p75)] | Lighthouse CI + RUM | [TBD] | [To verify] |
| Minimum contrast — text / UI components | [4.5:1 / 3:1] | Contrast checker, light and dark | [TBD] | [To verify] |
| Minimum touch target | [44x44 pt iOS / 48x48 dp Android / 24x24 px web (target 44)] | Measure | [TBD] | [To verify] |
| Shell API calls on load | [<= 2, batched; cached with defined staleTime] | Network panel | [TBD] | [To verify] |

---

## 8. Feedback & Notification Systems

> One row per notification type. Every type defines queue/priority behaviour.

| Notification Type | Trigger | Channel (toast / banner / badge / inbox / email / push) | Position | Duration (ms) | Max Simultaneous | Priority | Queue / merge behaviour | Dismissible? | Persisted? |
|------------------|---------|--------------------------------------------------------|----------|--------------|-----------------|----------|-------------------------|-------------|------------|
| [Save success] | [Feature] | [Toast] | [Bottom-start] | [4000] | [3] | [Low] | [Merge identical] | [Yes] | [No] |
| [Payment failed] | [Billing] | [Banner + email] | [Top] | [Until resolved] | [1] | [Critical] | [Never merged] | [No] | [Yes] |

**Notification rules**:
1. [Announced to assistive tech: `role="status"` for passive, `role="alert"` for errors; never steal focus]
2. [Merge rule — identical events within N ms collapse into one]
3. [Critical bypass — billing, security and data-loss notices are never queued or auto-dismissed]
4. [Respect user preferences: per-channel opt-out, quiet hours; consent for marketing]

---

## 9. Surface Adaptation

| Surface | Input method | Shell-specific notes |
|---------|-------------|----------------------|
| Web desktop | Mouse + keyboard | Shortcuts documented; command palette; focus ring always visible |
| Web mobile | Touch | Safe-area insets; no hover-only controls |
| Android | Touch, gesture nav | Edge-to-edge insets; back-gesture behaviour; window size classes |
| iOS | Touch | Safe areas; Dynamic Type; swipe-back |
| Self-hosted admin | Mouse + keyboard | Same shell; instance/licence banner slot; no external calls without opt-in |

**Persistence**: [Collapsed state, last workspace, locale and theme are saved per user (server) and mirrored locally.]

---

## 10. Accessibility

> Shell-specific requirements only — refer to `design/accessibility-requirements.md`
> for the full standard.

### 10.1 Landmarks, Skip Links and Focus
- Landmarks: `header`, `nav` (labelled), `main`, `aside`; one `h1` per screen.
- Skip-to-content link is the first focusable element.
- Focus order follows reading order in both LTR and RTL; focus is moved to the page heading after route changes and announced.
- Menus/popovers/dialogs: focus trapped while open, `Esc` closes, focus returns to the trigger.

### 10.2 Colour and Contrast
| Element | Colour-only information risk | Non-colour alternative |
|---------|------------------------------|------------------------|
| [Plan badge, status dots, quota meter] | [Where colour alone carries meaning] | [Text label, icon, pattern] |

### 10.3 Text Scaling and Zoom
[What happens at 200% browser zoom / OS font scale 200% / Dynamic Type largest: which regions reflow, truncate or collapse. No clipping; no horizontal scroll at 320 CSS px.]

| Component | 100% | 150% | 200% | Overflow behaviour |
|-----------|------|------|------|--------------------|
| [Component] | [Pass/Fail/TBD] | [Pass/Fail/TBD] | [Pass/Fail/TBD] | [What happens] |

### 10.4 Motion Sensitivity
| Animation / motion element | Severity | Disabled by reduced-motion? | Replacement |
|---------------------------|----------|----------------------------|-------------|
| [Drawer slide, skeleton shimmer, toast] | [Mild/Moderate/High] | [Yes/No] | [Instant state change] |

### 10.5 User Preferences
| Setting | Range | Default | Effect |
|---------|-------|---------|--------|
| Theme | Light / Dark / System | System | |
| Density | Comfortable / Compact | Comfortable | |
| Reduced motion | System / On / Off | System | |
| Notification verbosity | All / Important only | All | |
| Language | العربية / English | Browser/OS | Direction flips, layout mirrors |

---

## 11. Localization & Direction

- Arabic (RTL) and English (LTR) are first-class: the shell mirrors (navigation, chevrons, progress, back arrows); icons with direction mirror, brand marks and media controls do not.
- Logical CSS properties / start-end alignment only; no hardcoded left/right.
- Numerals, dates and currency formatted per locale; mixed-direction text (emails, URLs, IDs) isolated with bidi controls.
- All shell strings externalised; string length budget +40% (German-style expansion) and Arabic line-height checked.
- Screenshots in both directions are required evidence for shell changes.

---

## 12. Configuration

> Values that must be adjustable without redeploy, so engineers externalise them.

| Parameter | Current Value | Range | Effect of Increase | Effect of Decrease | User Adjustable? | Notes |
|-----------|-------------|-------|-------------------|-------------------|------------------|-------|
| [Toast duration] | [4000 ms] | [2000–10000] | [Longer visibility] | [Missed messages] | [No] | |
| [Trial banner threshold] | [7 days] | [1–30] | | | [No] | [Plan data] |
| [Quota warning threshold] | [80%] | [50–95] | | | [No] | [Plan data] |

---

## 13. Acceptance Criteria

> The certification checklist for the shell. Every item must pass before it is
> marked Approved. QA verifies each independently.

**Layout & Behaviour**
- [ ] Shell renders correctly at 1440, 768 and 390 px in LTR and RTL with no clipping or overlap
- [ ] Navigation shows only items the user's role and plan permit; direct URL to a hidden item returns the correct forbidden/upgrade state
- [ ] Workspace switch changes tenant context everywhere with no stale data from the previous tenant (cache keys include tenant)
- [ ] Global banners appear for trial ending, past due, maintenance and offline per Section 5 and never stack beyond the limit

**Per-Context Correctness**
- [ ] Each context in Section 5 shows exactly the specified elements
- [ ] Read-only (past due/suspended) mode disables writes but keeps export and billing reachable
- [ ] Session expiry preserves the user's draft and returns them to the same place after sign-in

**Accessibility**
- [ ] Full keyboard operation of every shell component; visible focus; skip link works
- [ ] Screen reader announces route changes, notifications and banners correctly (tested with TalkBack, VoiceOver and one desktop reader)
- [ ] Contrast ratios meet Section 7 in light and dark
- [ ] 200% zoom / largest text size causes no loss of content or function
- [ ] Reduced-motion setting disables all animations listed in 10.4

**Notifications**
- [ ] Identical notifications within the merge window collapse into one
- [ ] Critical notices are never auto-dismissed or queued
- [ ] No more than [3] toasts are visible simultaneously

**Performance & Observability**
- [ ] Shell meets the bundle and web-vitals budget in Section 7
- [ ] Client emits app-start and route-change spans with `traceparent`; no PII in client telemetry

**Surfaces**
- [ ] Android and iOS adapt to size classes, safe areas and system font scale
- [ ] Self-hosted build makes no external network calls unless the operator opted in

---

## 14. Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Add question] | [Owner] | [Deadline] | [Resolution] |
