# /ux-design — Section 3: Create File Skeleton

> Part of `/ux-design`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 3. Create File Skeleton

**In this file:**

- Skeleton for UX Spec (screen or flow)
- Skeleton for App Shell
- Skeleton for Interaction Pattern Library
- Skeleton for Accessibility Requirements

Once the user confirms, **immediately** create the output file with empty section
headers. This ensures incremental writes have a target and work survives interruptions.

Ask: "May I create the skeleton file at `design/ux/[filename].md`?" — except in
`accessibility` mode, where the path is `design/accessibility-requirements.md`
(see the mode table in Section 1; it is deliberately not under `design/ux/`),
and in `shell` mode, where it is `design/ux/app-shell.md`.

Each skeleton mirrors the section list of its template in
`.claude/docs/templates/` — if the template gains or loses a section, the skeleton
follows the template, not the reverse. Do not copy the template's example prose
into the skeleton; the placeholders stay `[To be designed]` until a section is
approved.

---

### Skeleton for UX Spec (screen or flow)

```markdown
# UX Specification: [Screen/Flow Name]

> **Status**: In Design
> **Author**: [user + ux-designer]
> **Last Updated**: [today's date]
> **Screen / Flow Name**: [identifier used in code and tickets]
> **Surface Target**: [surfaces from 2h]
> **Related Specs**: [feature spec sections feeding this screen]
> **Related ADRs**: [or none]
> **Related UX Specs**: [sibling and parent screens, app-shell.md]
> **Accessibility target**: [from design/accessibility-requirements.md, or WCAG 2.2 AA baseline]
> **Design system**: `DESIGN.md` at the repo root (referenced, not redefined)
> **Journey Phase(s)**: [from context]
> **Template**: UX Spec

---

## 1. Purpose & User Need

[To be designed]

---

## 2. User Context on Arrival

[To be designed]

---

## 3. Navigation Position

[To be designed]

---

## 4. Entry & Exit Points

[To be designed]

---

## 5. Layout Specification

[To be designed]

### 5.1 ASCII Wireframe

[To be designed]

### 5.2 Layout Zones

[To be designed]

### 5.3 Component Inventory

[To be designed]

### 5.4 Information Hierarchy

[To be designed]

---

## 6. States & Variants

[To be designed]

---

## 7. Interaction Map

[To be designed]

---

## 8. Data Requirements

[To be designed]

---

## 9. Actions & Events

[To be designed]

---

## 10. Transitions & Animations

[To be designed]

---

## 11. Input Method Completeness Checklist

[To be designed]

---

## 12. Accessibility

[To be designed]

---

## 13. Localization Considerations

[To be designed]

---

## 14. Acceptance Criteria

[To be designed]

---

## 15. Open Questions

[To be designed]
```

---

### Skeleton for App Shell

```markdown
# App Shell Design: [Product Name]

> **Status**: In Design
> **Author**: [user + ux-designer]
> **Last Updated**: [today's date]
> **Product**: [product name — one document per product]
> **Surfaces**: [from 2h]
> **Related Specs**: [every feature spec exposing navigation, widgets or notifications]
> **Accessibility target**: [from design/accessibility-requirements.md]
> **Style Reference**: `DESIGN.md` at the repo root
> **Template**: App Shell

---

## 1. Shell Philosophy

[To be designed]

---

## 2. Information Architecture

[To be designed]

---

## 3. Layout Regions

[To be designed]

### 3.1 Region Diagram

[To be designed]

### 3.2 Region Specification Table

[To be designed]

---

## 4. Shell Component Specifications

[To be designed]

### 4.1 Component Overview Table

[To be designed]

### 4.2 Component Detail Blocks

[To be designed]

---

## 5. Shell States by Context

[To be designed]

---

## 6. Information Hierarchy

[To be designed]

---

## 7. Visual & Performance Budget

[To be designed]

---

## 8. Feedback & Notification Systems

[To be designed]

---

## 9. Surface Adaptation

[To be designed]

---

## 10. Accessibility

[To be designed]

### 10.1 Landmarks, Skip Links and Focus

[To be designed]

### 10.2 Colour and Contrast

[To be designed]

### 10.3 Text Scaling and Zoom

[To be designed]

### 10.4 Motion Sensitivity

[To be designed]

### 10.5 User Preferences

[To be designed]

---

## 11. Localization & Direction

[To be designed]

---

## 12. Configuration

[To be designed]

---

## 13. Acceptance Criteria

[To be designed]

---

## 14. Open Questions

[To be designed]
```

---

### Skeleton for Interaction Pattern Library

```markdown
# Interaction Pattern Library: [Product Title]

> **Status**: In Design
> **Author**: [user + ux-designer]
> **Last Updated**: [today's date]
> **Version**: 1.0
> **Surfaces**: [from 2h]
> **UI Framework / Component Library**: [pinned in docs/stack-reference/]
> **Template**: Interaction Pattern Library

---

## How to Use This Library

[To be designed]

---

## Pattern Catalog Index

[To be designed]

---

## Standard Control Patterns

[To be designed]

---

## SaaS-Specific Patterns

[To be designed]

---

## Navigation Patterns

[To be designed]

---

## Feedback and Loading Patterns

[To be designed]

---

## Animation Standards

[To be designed]

---

## Feedback Channels Beyond Visuals

[To be designed]

---

## Direction and Locale Standards

[To be designed]

---

## Gaps & Patterns Needed

[To be designed]

---

## Open Questions

[To be designed]
```

---

### Skeleton for Accessibility Requirements

```markdown
# Accessibility Requirements: [Product Title]

> **Status**: In Design
> **Author**: [user + ux-designer]
> **Last Updated**: [today's date]
> **Conformance Target**: [A / AA / AA+ — to be committed first]
> **Surface(s)**: [from 2h]
> **Template**: Accessibility Requirements

---

## Conformance Target Definition

[To be designed]

---

## Perceivable

[To be designed]

---

## Operable

[To be designed]

---

## Understandable

[To be designed]

---

## Robust and Assistive Technology

[To be designed]

### Platform Accessibility API Integration

[To be designed]

---

## Per-Feature Accessibility Matrix

[To be designed]

---

## Accessibility Test Plan

[To be designed]

---

## Known Intentional Limitations

[To be designed]

---

## Audit History

[To be designed]

---

## External Resources

[To be designed]

---

## Open Questions

[To be designed]
```

> **The target commitment is the gated part.** Phase gates require
> `design/accessibility-requirements.md` to exist *with a conformance target
> committed*, and `/ux-review` checks every key screen spec against that target.
> A skeleton whose Conformance Target Definition is still `[To be designed]`
> satisfies the glob but not the gate — author that section first.

---

After writing the skeleton, update `production/session-state/active.md` with:
- Task: Designing [screen/flow name] UX spec
- Current section: Starting (skeleton created)
- File: design/ux/[filename].md (or `design/accessibility-requirements.md` in `accessibility` mode)

---
