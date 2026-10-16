> Section-authoring guidance, loaded by `/ux-design` for the ACTIVE MODE ONLY.
> Never load the other two — one mode applies per invocation.

# Section Guidance — Interaction Pattern Library Mode

Pattern library authoring is additive and catalog-driven, not linear. The
template (`.claude/docs/templates/interaction-pattern-library.md`) ships the
standard control, SaaS-specific (form & validation, wizard, filter bar, bulk
actions, inline edit, command palette, file upload, plan gate / upgrade prompt,
quota / usage meter, permission-denied & not-found, async job status, sensitive
value reveal, banner), navigation and feedback patterns. Guidance on each is in
`.claude/docs/templates/guidance/interaction-pattern-library-guide.md`, which
routes to topic files — load only the topic you are authoring.

The library defines **behaviour, states, semantics and accessibility**. Visual
styling (colour, radius, shadow, type) is in `DESIGN.md` and is never defined
here.

#### Phase 1: Catalog Existing Patterns

Glob `design/ux/*.md` (excluding `interaction-patterns.md`) and read the Component
Inventory and Interaction Map of each spec. Extract every interaction pattern used.

Present the extracted list: "Based on existing UX specs, these patterns are already
in use in the product:"
- [Pattern name]: used in [screen], [screen]
- [etc.]

Ask: "Are there patterns you know exist but aren't in existing specs yet? List any
additional ones now."

If no UX spec exists yet, say so and start from the template's standard and
SaaS-specific sets, keeping only the patterns the product's first screens need.

---

#### Phase 2: Formalize Each Pattern

For each pattern (existing or new), document using the template's pattern block.
At minimum:

```markdown
#### [Pattern Name]

**Category**: Navigation / Input / Feedback / Data Display / Modal / Overlay / Gating / [other]
**Used In**: [list of screens]
**Status**: Draft / Stable / Deprecated

**Description**: [One paragraph — what this pattern is and when to use it]

**Specification**:
- States (default, hover, focus, active, disabled, loading, error)
- Inputs per surface (pointer, keyboard, touch) and focus behaviour
- Feedback (visual, announced, haptic)
- Accessibility: role/semantics, name, announcements, target size
- Direction: what mirrors in RTL
- Roles / plan variants, if it is a gating pattern (cite entitlement keys)

**When to Use / When NOT to Use**: [conditions]
```

Work through patterns in groups. Use `AskUserQuestion`:
- "How do you want to work through these patterns?"
- Options: "Draft the first batch from existing specs (faster)", "Define them one by one (more control)", "Start with the most-used pattern first"

Sensitive patterns (destructive confirmation, secret reveal and copy, file upload,
permission-denied) are reviewed against `.claude/docs/security-baseline.md`: a
destructive pattern names the confirmation; a not-found pattern never reveals
whether another tenant's record exists.

---

#### Phase 3: Identify Gaps

After cataloging known patterns, ask:
- "Are there screens or interactions planned that would need patterns not yet in this library?"
- "Are there patterns in existing specs that feel inconsistent with each other and should be consolidated?"

Document gaps in the Gaps section for follow-up. A pattern marked **Stable** has
been implemented and validated on every target surface — do not mark it so
otherwise.
