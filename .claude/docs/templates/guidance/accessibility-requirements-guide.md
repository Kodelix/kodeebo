> Authoring guidance for accessibility-requirements.md. Load only the part covering the section currently being authored — not the whole file at once.

# Accessibility Requirements Template — Authoring Guidance

Guidance is organised by template section. When authoring a section of a
product's accessibility requirements document, read only that section's
guidance below. The criteria tables themselves (Perceivable / Operable /
Understandable / Robust), the platform API table, the test plan, and the
external resources remain in the template — they are the requirement catalogue,
not guidance.

---

## Conformance Target Definition

> **Why define a target**: Accessibility is not binary. A named target (A, AA,
> AA+) gives the team a shared vocabulary, forces an explicit commitment at the
> start of product design, and prevents scope creep in both directions ("we'll
> add it later" and "we have to support everything"). Commit to a target with
> specific criteria and surfaces, not just the letters. AA is the default for
> every customer-facing product; A is acceptable only for internal tools with a
> written reason.

**Authoring the commitment rationale**:

[Write 3–5 sentences justifying the target. Do not simply state it — explain the
reasoning. Consider: Who are the customers and users, and what is the realistic
prevalence of assistive-technology use among them? Do enterprise or public-sector
buyers ask for a VPAT / conformance report? Are there legal or contractual
obligations (EU accessibility act, procurement rules)? Which surfaces ship
first? What is the team's capacity, and what would dropping one level cost in
concrete terms?

Example: "This is a B2B scheduling product for clinics in Egypt and the Gulf
used on desktop browsers and Android phones, in Arabic and English. Reception
staff use it all day, so keyboard efficiency and zoom/text-size support
matter beyond compliance. Two prospective enterprise customers have asked for a
conformance report. AA covers all of this at manageable cost with the component
library; AA+ is reserved for onboarding and billing, where errors are costly.
Dropping to A would remove contrast and reflow guarantees that the Android
low-vision users in our beta already rely on."]

**Example in-scope / out-of-scope entries**:

Criteria explicitly in scope (beyond the target baseline):
- [e.g. "Enhanced contrast (7:1) on the billing and checkout flow — AAA, because errors there cost money"]
- [e.g. "Reading-level target in Arabic and English for onboarding copy"]

Explicitly out of scope:
- [e.g. "Audio description for the marketing promo video — transcript provided instead. Documented in Known Intentional Limitations."]

---

## Perceivable

> **Why this section comes first**: Low vision, colour-vision deficiency and
> small-screen/glare conditions affect the largest share of users who benefit
> from accessibility features, and they also affect everyone on a phone outdoors.
> Contrast and text resizing failures are the most common automated findings in
> shipped products. Document every perceivable criterion before visual design is
> locked, because retrofitting colour tokens or layout reflow after components
> exist is expensive. Contrast decisions belong in the design tokens (`DESIGN.md`),
> verified on final values in both light and dark themes.

**Worked example rows — Colour-as-Only-Indicator Audit**:

| Location | Colour Signal | What It Communicates | Non-Colour Backup | Status |
|----------|--------------|---------------------|------------------|--------|
| [Invoice status chip] | [Red = overdue, green = paid] | [Payment state] | [Chip text "Overdue" / "Paid" plus icon] | [Not Started] |
| [Usage chart series] | [Blue vs. orange lines] | [Plan quota vs. actual use] | [Different line styles and direct labels; data table alternative] | [Not Started] |
| [Form field validation] | [Red border] | [Field is invalid] | [Error icon, message text associated with the field, error summary] | [Not Started] |

---

## Operable

> **Why operability matters beyond disability**: Keyboard efficiency, touch
> reach, and forgiving timing benefit power users, people on trains, and anyone
> with a temporary injury. The most common failures in SaaS products are:
> custom widgets (comboboxes, date pickers, menus, data grids) that cannot be
> operated by keyboard, focus hidden behind sticky headers, drag-only
> interactions (kanban, reordering, file upload), tiny touch targets, and session
> timeouts that discard work. WCAG 2.2 added criteria for several of these —
> focus not obscured, target size, dragging alternatives, consistent help — so
> include them explicitly in the target. Many of these cost little if planned in
> the component library and are very expensive to retrofit per screen.

---

## Understandable

> **Why this section is often under-specified**: Understandability covers
> language, predictability, forms, errors and authentication — it is where
> cognitive accessibility lives. It benefits users with ADHD, dyslexia,
> autism, anxiety, and acquired brain injury, as well as every user under
> pressure (a failed payment, an irreversible delete). The common failures are:
> errors that do not say what to do, forms that clear on error, multi-step flows
> that ask for the same data twice, authentication that requires transcribing a
> code the user cannot paste, and billing language that needs a lawyer. Plain
> language and error prevention in high-consequence flows are the highest-value
> items here; WCAG 2.2 Accessible Authentication and Redundant Entry directly
> govern sign-in, OTP and onboarding.

---

## Robust and Assistive Technology

> **Why this section exists**: Robustness means the product exposes correct
> names, roles, states and messages to assistive technology across browsers and
> mobile platforms. Native elements and platform controls get this mostly for
> free; custom components and async updates (toasts, validation, route changes,
> search results) are where it breaks. Right-to-left support is also verified here:
> an Arabic UI that is visually mirrored but has the wrong focus order or reads
> English labels in the wrong direction is not accessible.

**Platform note**: Each platform provides native accessibility APIs which, when
used, let OS-level tools (screen readers, switch access, voice control, font
scaling) work with the product. Choose per-surface verification tools in the
test plan and pin their versions in the stack reference.

---

## Per-Feature Accessibility Matrix

> **Why this matrix exists**: Accessibility is not a list of settings — it is a
> property of every feature. This matrix gives the "accessibility impact" view
> of the product: which features carry which barriers, and whether they are
> addressed. When a feature is added to `domain-map.md`, a row must be added
> here. A feature with an unaddressed concern cannot be marked Approved.

**Worked example rows**:

| Feature | Perceivable Concerns | Operable Concerns | Understandable Concerns | Robust / AT Concerns | Addressed | Notes |
|---------|---------------------|------------------|------------------------|---------------------|-----------|-------|
| [Data grid (invoices)] | [Status colours; dense text at small sizes] | [Sortable headers, row actions, keyboard navigation, sticky header covering focus] | [Many columns to track — cognitive load > 4] | [Grid semantics, sort state announced, row-selection announcements] | [Partial] | [Row-level action menu and column chooser in progress] |
| [Checkout / payment update] | [Contrast on provider-hosted fields] | [Target size; keyboard on provider iframe] | [Total, tax and renewal date must be stated before confirmation] | [Provider iframe labelling; focus return after 3-D Secure] | [Not Started] | [Verify provider widget meets target; fallback flow] |
| [Kanban board] | [Column colours] | [Drag-only reordering] | [Many items] | [Drag semantics] | [Not Started] | [Provide move-to menu alternative to dragging] |
| [Sign-in with OTP] | [None] | [Code-entry timing] | [Transcribing a code] | [Autofill and paste on split inputs; live-region for resend timer] | [Not Started] | [Single field with `autocomplete="one-time-code"`; passkey alternative] |

---

## Accessibility Test Plan

> **Why test accessibility separately from QA**: Standard QA tests whether
> features work. Accessibility testing tests whether features work for the people
> who rely on these affordances. A form can pass QA (it submits) and fail
> accessibility testing (errors are not announced, focus is lost). Plan for three
> layers: automated (axe-core, Lighthouse, platform checkers in CI — catches a
> minority of issues but prevents regressions), manual internal (keyboard-only,
> screen readers, zoom, forced colours, RTL), and user testing (people who use
> assistive technology daily). Add `/impeccable audit` to every UI story.

---

## Known Intentional Limitations

> **Why document what is NOT included**: Omissions left undocumented become
> surprises in procurement reviews or customer feedback. Documenting a
> limitation with a rationale shows it was a deliberate choice, not an oversight,
> and identifies which users are not served and what the mitigation is. Every
> entry is a risk — assess it honestly.

**Worked example rows**:

| Feature | Target Required | Why Not Included | Risk / Impact | Mitigation |
|---------|----------------|-----------------|--------------|------------|
| [Chart screen-reader parity for the usage heat-map] | AA | Chart library exposes no accessible tree for heat-map cells in the pinned version | Blind users cannot read per-day values from the map | Provide the same data as a sortable table and a CSV export; re-evaluate on library upgrade |
| [Live captions for in-app webinars] | AA | Third-party webinar tool only supports post-event captions | Deaf users miss live content | Captions added within 24 h and transcript posted; evaluate vendors at renewal |
| [Native Arabic voice control labels on iOS] | AA+ | Voice Control Arabic recognition limited for brand terms | Voice users may need alternate names | Provide alternative accessibility input labels; document in release notes |

---

## Audit History

> **Why track audit history**: Accessibility is not certified once and done.
> Standards evolve, new features introduce barriers, and components regress. An
> audit history demonstrates due diligence, supports conformance statements to
> enterprise customers, and helps identify regressions between audits.

**Worked example rows**:

| Date | Auditor | Type | Scope | Findings Summary | Status |
|------|---------|------|-------|-----------------|--------|
| [Date] | [Internal — accessibility-specialist] | Internal review | [Pre-release checklist against the committed target] | [e.g. "40 criteria verified, 5 open: focus hidden by sticky header on invoice list, error summary missing on signup, contrast on disabled buttons"] | [In Progress] |
| [Date] | [External — accessibility consultancy] | Independent audit | [Sign-up, core workflow, billing; web + Android] | [e.g. "2 critical (checkout iframe label, drag-only reorder), 7 moderate"] | [Findings addressed] |

---

## Open Questions

**Worked example questions**:

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Does the pinned component library's combobox meet ARIA Authoring Practices keyboard behaviour in RTL?] | [web-lead] | [Before Architecture gate] | [Unresolved — verify in `docs/stack-reference/`] |
| [Does the payment provider's hosted checkout meet our AA target, and what is the fallback if not?] | [pricing-billing-designer] | [Before billing spec approval] | [Unresolved] |
| [Do target enterprise customers require a VPAT or an EN 301 549 report?] | [producer] | [Before Pre-Production gate] | [Unresolved] |
