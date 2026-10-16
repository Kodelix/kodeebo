# Accessibility Requirements: [Product Title]

> Authoring guidance: .claude/docs/templates/guidance/accessibility-requirements-guide.md (load per-section as you author — do not read entirely).

> **Status**: Draft | Committed | Audited | Conformance statement published
> **Author**: [user + ux-designer]
> **Last Updated**: [Date]
> **Conformance Target**: [WCAG 2.2 Level A / AA / AA + named AAA criteria]
> **Surface(s)**: [Web app / Marketing site / Android / iOS / Self-hosted admin / Emails]
> **External Standards Targeted**:
> - WCAG 2.2 Level [A / AA / AAA] (W3C) — verify success-criterion numbers against the W3C text when mapping
> - Android accessibility guidance (TalkBack, large font, touch target 48 dp) [Yes / No / N/A]
> - Apple accessibility guidance (VoiceOver, Dynamic Type, Reduce Motion) [Yes / No / N/A]
> - EN 301 549 / European Accessibility Act [Yes / No / Partial — confirm applicability with legal for EU customers]
> - Section 508 / VPAT or ACR requested by enterprise customers [Yes / No]
> **Accessibility Consultant**: [Name and organisation, or "None engaged"]
> **Linked Documents**: `design/specs/domain-map.md`, `design/ux/interaction-patterns.md`, `DESIGN.md`

> **Why this document exists**: Per-screen accessibility annotations belong in UX
> specs. This document captures the product-wide commitments, the feature matrix
> across all features, the test plan, and the audit history. It is created once
> during Product Design by the UX designer with `/ux-design accessibility` — you
> pick the target against the criteria `accessibility-specialist` sets and audits
> against — then updated as features are added and audits are completed. If a
> feature conflicts with a commitment made here, this document wins — change the
> feature, not the commitment, unless the producer approves a formal revision.
>
> **When to update**: after each `/gate-check` pass, after any audit, and
> whenever a feature is added to `domain-map.md`.

---

## Conformance Target Definition

### Target Definitions

| Target | Core Commitment | Typical Effort |
|--------|----------------|----------------|
| **A** | Internal tools only, with a written reason. Content is operable by keyboard, has text alternatives, no keyboard traps, no seizure-inducing content. | Low |
| **AA** (default) | All WCAG 2.2 Level A and AA success criteria for every shipped screen, including contrast, reflow, text spacing, focus not obscured, target size, accessible authentication, consistent help, redundant entry avoidance and dragging alternatives. | Medium — design constraints plus component-library work and CI checks |
| **AA+** | AA plus named AAA criteria on critical flows (e.g. enhanced contrast 7:1, reading level and error prevention on billing and onboarding, session timeout controls). Independent audit and published conformance report / VPAT. | High — dedicated budget and specialist audit |

### This Product's Commitment

**Target**: [A / AA / AA+]

**Rationale**: [3–5 sentences: customer segments (enterprise and public-sector buyers ask for conformance reports), legal exposure, user population, team capacity, cost of dropping a level. See guide for the reasoning checklist.]

**Criteria beyond the target baseline**:
- [Criterion or feature elevated above the target + why]

**Explicitly out of scope**:
- [Surface or criterion excluded + why — must also appear in Known Intentional Limitations]

---

## Perceivable

| Feature | Target | Scope | Status | Implementation Notes |
|---------|--------|-------|--------|---------------------|
| Text alternatives | A | All non-text content (icons, charts, images) | Not Started | Informative images have alt text; decorative images are empty-alt / hidden; icon-only buttons have accessible names; charts have a data-table or text summary alternative. |
| Text contrast | AA | All text and images of text | Not Started | 4.5:1 body text, 3:1 large text (>= 24 px or >= 18.66 px bold). Test final token values in light and dark themes; do not rely on design-tool previews. |
| Non-text contrast | AA | UI component boundaries, focus indicators, chart marks, icons that convey meaning | Not Started | 3:1 against adjacent colours, including input borders and selected states. |
| Use of colour | A | Status chips, validation, charts, plan badges | Not Started | List every colour-only signal in the audit below; each has a non-colour backup (icon, text, pattern). |
| Reflow | AA | All screens | Not Started | No horizontal scroll at 320 CSS px width (1280 px at 400% zoom) except for data tables / maps that need two dimensions; those have an alternative view. |
| Resize text / text spacing | AA | All screens | Not Started | Usable at 200% text size; user-set line height 1.5, paragraph spacing 2x, letter 0.12em, word 0.16em causes no loss of content or function. |
| Content on hover or focus | AA | Tooltips, popovers, menus | Not Started | Dismissible (Esc), hoverable, persistent until dismissed or invalid. |
| Orientation and input purpose | AA | Mobile layouts, forms | Not Started | No forced orientation; form fields declare autocomplete tokens for personal data. |
| Dark mode / forced colours | AA+ | Web | Not Started | Honour `prefers-color-scheme` and Windows forced-colors; no information lost in forced-colors mode. |
| Captions and transcripts | A/AA | Product tour videos, training videos, webinars | Not Started | Captions in Arabic and English; audio description or transcript for visual-only content. |
| Auto-playing media | A | Marketing site, onboarding | Not Started | No autoplay with audio; pause/stop control for motion longer than 5 s. |
| Flashing content | A | Animations, loaders, charts | Not Started | No more than 3 flashes per second; avoid large flashing areas. |
| Reduced motion | AA | All animation, parallax, skeleton shimmer | Not Started | Honour `prefers-reduced-motion` / platform "Reduce Motion"; replace motion with instant or cross-fade. |

### Colour-as-Only-Indicator Audit

> Fill in every element where colour is the sole differentiator. Resolve each
> before shipping. See guide for example rows.

| Location | Colour Signal | What It Communicates | Non-Colour Backup | Status |
|----------|--------------|---------------------|------------------|--------|
| [Add row for each colour-coded element] | | | | |

---

## Operable

| Feature | Target | Scope | Status | Implementation Notes |
|---------|--------|-------|--------|---------------------|
| Keyboard operation | A | All functionality, all web surfaces; Android/iOS with external keyboard and switch access | Not Started | Every action reachable without a pointer; logical focus order (mirrored in RTL); no keyboard traps; custom widgets follow the ARIA Authoring Practices keyboard models. |
| Focus visible and not obscured | AA | All focusable elements; sticky headers, cookie banners, chat widgets | Not Started | Focus indicator 3:1 contrast with 2 px minimum perimeter equivalent; focused element is never fully hidden behind sticky UI (WCAG 2.2 Focus Not Obscured). |
| Bypass blocks and page titles | A | Every page / route | Not Started | Skip link first in tab order; unique, descriptive `<title>` updated on route change; headings and landmarks. |
| Pointer target size | AA | All interactive elements | Not Started | At least 24x24 CSS px (WCAG 2.2 minimum); design target 44x44. Android 48 dp, iOS 44 pt. Inline text links exempt. |
| Pointer gestures and dragging | A/AA | Drag-and-drop, sliders, maps, swipe actions, multi-finger gestures | Not Started | Every path-based or multi-point gesture and every drag has a single-pointer, non-dragging alternative. |
| Pointer cancellation | A | Buttons and links | Not Started | Actions fire on up-event; abort by moving off the target. |
| Character key shortcuts | A | Single-key shortcuts (command palette, list navigation) | Not Started | Can be turned off, remapped, or only active on focus. |
| Time limits | A | Session timeouts, OTP/verification codes, checkout holds | Not Started | Warn before session expiry and allow extension; preserve drafts on expiry; document unavoidable limits (OTP) and offer resend. |
| Moving / auto-updating content | A | Toasts, live dashboards, carousels | Not Started | Pause/stop/hide for anything auto-updating beyond 5 s; toasts with actions persist until dismissed. |
| Consistent help | A | Help, contact support, chat entry points | Not Started | Same relative location on every page where offered (WCAG 2.2 Consistent Help). |
| Motion actuation | A | Shake / tilt gestures on mobile | Not Started | Provide UI alternative and a way to disable. |
| Mobile switch / voice / external keyboard | AA+ | Android and iOS | Not Started | Switch Access / Switch Control, Voice Control / Voice Access can reach every control by visible name (label-in-name). |

---

## Understandable

| Feature | Target | Scope | Status | Implementation Notes |
|---------|--------|-------|--------|---------------------|
| Language of page and parts | A/AA | All pages; mixed-language content | Not Started | `lang` and `dir` on the document and on inline foreign-language or opposite-direction phrases; correct on route/locale change. |
| Predictable navigation | A/AA | App shell, menus, forms | Not Started | Consistent navigation order and identification across screens; no context change on focus or input without warning. |
| Form labels and instructions | A | All forms | Not Started | Visible, persistent labels; required fields indicated by more than colour; hints associated programmatically; placeholder is never the label. |
| Error identification and suggestion | A/AA | All validation | Not Started | Errors identified in text, associated with the field, with a fix suggestion; error summary on submit failure moves focus to it. |
| Error prevention | AA | Payments, deletions, legal commitments, data submissions | Not Started | Reversible, checked, or confirmed with consequences stated (what will be deleted, what will be charged and when). |
| Accessible authentication | AA | Sign-in, MFA, OTP, password reset | Not Started | No cognitive function test (memorising, transcribing, puzzles) without an alternative; paste and password-manager autofill allowed; WebAuthn/passkeys as an alternative; OTP can be pasted/auto-filled. |
| Redundant entry | A | Multi-step flows (onboarding, checkout) | Not Started | Information already entered is auto-populated or selectable; exceptions only for security or validity. |
| Plain language and reading level | AA+ | Onboarding, billing, error messages, legal summaries | Not Started | Short sentences, defined terms, consistent vocabulary; reading level target [grade/level] in each locale; unusual words explained. |
| Orientation and progress | AA | Wizards, long forms, imports | Not Started | Step indicators with text; save-and-resume; no data loss on back/refresh; clear success states. |
| Cognitive load documentation | AA+ | Per feature | Not Started | For each feature in `domain-map.md`, document the maximum simultaneous items the user must track; flag any above 4 as a review trigger. See Per-Feature Matrix below. |
| Help and documentation | AA | Complex features | Not Started | Contextual help and documentation reachable in 2 interactions; examples in both languages. |

---

## Robust and Assistive Technology

| Feature | Target | Scope | Status | Implementation Notes |
|---------|--------|-------|--------|---------------------|
| Name, role, value | A | All controls, custom widgets | Not Started | Native elements first; ARIA only to fill gaps; states (`aria-expanded`, `aria-selected`, `aria-invalid`, `aria-busy`) kept in sync. |
| Status messages | AA | Toasts, validation, async results, route changes, search results | Not Started | `role="status"` / `aria-live="polite"` for passive updates; `role="alert"` for errors; never move focus unexpectedly. |
| Dialogs, menus, tabs, comboboxes | A/AA | Component library | Not Started | Conform to ARIA Authoring Practices; focus trap, Esc, return focus; accessible names; tested with screen readers. |
| Data tables and charts | A/AA | Reports, lists | Not Started | Proper `<th scope>` and captions; sortable header state announced; sticky headers do not obscure focus; charts have text/table alternative and non-colour encodings. |
| Right-to-left support | AA | Arabic locale | Not Started | `dir="rtl"`, logical CSS properties, mirrored icons and focus order, bidi isolation for mixed content; screen reader pronunciation checked in Arabic. |
| Large text and Dynamic Type | AA | Android / iOS | Not Started | Respect system font scale (up to 200%); no truncation of essential content; layouts reflow, not clip. |
| Emails | A/AA | Transactional and lifecycle emails | Not Started | Semantic HTML, sufficient contrast, alt text, `lang`/`dir`, plain-text alternative, links with descriptive text. |
| Documents and exports | A/AA | PDF invoices, CSV/Excel exports | Not Started | Tagged PDFs with reading order and language; CSV with header row; not the only way to obtain data shown on screen. |

### Platform Accessibility API Integration

| Platform | API / Standard | Features Planned | Status | Notes |
|----------|---------------|-----------------|--------|-------|
| Web | WAI-ARIA 1.2 / ARIA Authoring Practices, HTML semantics | [Landmarks, live regions, composite widget patterns] | Not Started | Verify against the pinned React and component-library versions in `docs/stack-reference/`. |
| Android (Compose) | TalkBack, `semantics {}` modifiers, Switch Access, Voice Access | [Content descriptions, traversal order, heading and live-region semantics] | Not Started | Android accessibility checks in CI plus manual TalkBack pass. |
| iOS (SwiftUI) | VoiceOver, Dynamic Type, Voice Control, Switch Control | [Accessibility labels/traits, rotor, focus] | Not Started | Accessibility Inspector audit plus manual VoiceOver pass. |
| KMP shared UI (if any) | Platform bridging | [Semantic parity between platforms] | Not Started | Shared components must expose equivalent semantics on both targets. |
| Desktop screen readers | NVDA, JAWS, Narrator, VoiceOver (macOS) | [Smoke tests on key flows] | Not Started | At least NVDA + Firefox/Chrome and VoiceOver + Safari. |

---

## Per-Feature Accessibility Matrix

> When a feature is added to `domain-map.md`, a row must be added here. A feature
> with an unaddressed accessibility concern cannot be marked Approved. See guide
> for example rows.

| Feature | Perceivable Concerns | Operable Concerns | Understandable Concerns | Robust / AT Concerns | Addressed | Notes |
|---------|---------------------|------------------|------------------------|---------------------|-----------|-------|
| [Add feature from domain-map.md] | | | | | | |

---

## Accessibility Test Plan

| Check | Test Method | Test Cases | Pass Criteria | Responsible | Status |
|-------|------------|------------|--------------|-------------|--------|
| Automated rules | axe-core (Playwright), Lighthouse CI, Android Accessibility Test Framework / Compose checks, iOS Accessibility Inspector audit | Every route and state in CI | Zero serious/critical violations; no regression vs. baseline | web-lead / qa-tester | Not Started |
| Contrast | Contrast analyser on final tokens, light and dark | All text/background and UI component pairs | Text >= 4.5:1 (large >= 3:1); UI components >= 3:1 | ux-designer | Not Started |
| Keyboard-only | Manual — complete each critical journey with keyboard only | Sign-up, sign-in, core action, billing, invite, settings, delete | All completed without a pointer; focus visible and never obscured; no traps | qa-tester | Not Started |
| Screen reader | Manual — NVDA/Chrome, VoiceOver/Safari, TalkBack, VoiceOver iOS | Same journeys | Names, roles, states, announcements correct; headings and landmarks usable | accessibility-specialist | Not Started |
| Zoom, reflow and text spacing | Manual at 200% / 400% zoom, 320 px width, text-spacing bookmarklet, OS font scale 200% | All screens | No loss of content or function; no horizontal scroll | qa-tester | Not Started |
| Reduced motion and forced colours | Manual with OS settings on | App shell, dialogs, charts | Motion removed or reduced; information preserved | ux-designer | Not Started |
| RTL and Arabic | Manual in Arabic with RTL | All screens | Mirrored layout, correct focus order, correct bidi, screen reader reads Arabic correctly | localization-lead / ux-designer | Not Started |
| Forms and authentication | Manual — errors, autofill, paste, password manager, passkey, OTP | All forms | Errors identified and associated; accessible authentication alternatives work | qa-tester | Not Started |
| `/impeccable audit` | Run on every UI story | Touched screens | Findings fixed or waived with reason | web-lead / ui-designer | Not Started |
| User testing | Sessions with participants using screen readers, magnification, switch/voice input, or motor/cognitive disabilities | Core journeys | Participants complete core journeys unaided within tolerance of the baseline time | producer | Not Started |

---

## Known Intentional Limitations

> Every entry is a risk — assess it honestly. See guide for example rows.

| Feature | Target Required | Why Not Included | Risk / Impact | Mitigation |
|---------|----------------|-----------------|--------------|------------|
| [Add any intentionally excluded criterion or surface] | | | | |

---

## Audit History

> See guide for example rows.

| Date | Auditor | Type | Scope | Findings Summary | Status |
|------|---------|------|-------|-----------------|--------|
| [Add row for each audit] | | | | | |

---

## External Resources

| Resource | URL | Relevance |
|----------|-----|-----------|
| WCAG 2.2 (W3C Recommendation) | https://www.w3.org/TR/WCAG22/ | Normative success criteria; verify criterion numbers here when mapping |
| WAI-ARIA Authoring Practices Guide | https://www.w3.org/WAI/ARIA/apg/ | Keyboard and ARIA patterns for custom widgets |
| W3C WCAG-EM | https://www.w3.org/WAI/test-evaluate/conformance/wcag-em/ | Evaluation methodology for conformance claims |
| Android accessibility | https://developer.android.com/guide/topics/ui/accessibility | TalkBack, semantics, testing |
| Apple accessibility | https://developer.apple.com/accessibility/ | VoiceOver, Dynamic Type, Voice Control |
| EN 301 549 | https://www.etsi.org/ | EU public-procurement and accessibility-act reference |
| Colour contrast checkers and colour-blindness simulators | (tool of choice, pinned in the design system) | Contrast and colour-vision checks |

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Add question] | [Owner] | [Deadline] | [Resolution] |
