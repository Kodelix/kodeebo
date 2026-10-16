# /design-spec — Phase 3: Create File Skeleton

> Part of `/design-spec`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 3. Create File Skeleton

**In this file:**

- Which sections to scaffold at the resolved tier
- The spec skeleton
- Writing the file, then the session state update

Once the user confirms, **immediately** create the spec file with empty section
headers. This ensures incremental writes have a target.

**Scaffold only the sections required at the resolved tier** (§1): at
`standard`, scaffold Overview, Detailed Behaviour, Data & Contracts,
Non-Functional Requirements and Acceptance Criteria; scaffold Edge Cases &
Failure Modes when the feature triggers the conditional (provider call, money,
entitlement change, async) or `edge_cases` is forced; **omit User Value and
Dependencies** unless the user asks for them. At `full`, scaffold all 8.
**Only the sections §1 named as omitted are skipped** — do not leave empty
`[To be designed]` placeholders for those. Every other section in the template
is scaffolded with its placeholder, including the ones §4 has not decided yet.
This sentence governs the tier omissions above and nothing else: it is not a
licence to strip a section because it looks optional, and §4 cannot fill a
section §3 never created.

Use the template structure from `.claude/docs/templates/feature-spec.md`:

```markdown
# [Feature Name]

> **Status**: In Design
> **Author**: [user + agents]
> **Last Updated**: [today's date]
> **Last Verified**: [today's date]
> **Serves principle**: [from context]
> **Effective tier**: [minimal | standard | full] — [source: project value | system_overrides]

## Summary

[To be designed]

> **Quick reference** — Layer: `[Foundation | Core | Feature | Presentation]` · Priority: `[MVP | Vertical Slice | Beta | Full Vision]` · Bounded context: `[name]` · Key deps: `[contexts / providers or "None"]` · Plan gate: `[plan / entitlement key or "all plans"]`

## 1. Overview

[To be designed]

## 2. User Value

[To be designed]

## 3. Detailed Behaviour

### Core Rules

[To be designed]

### Permissions per Role

[To be designed]

### States and Transitions

[To be designed]

### Interactions with Other Contexts

[To be designed]

## 4. Data & Contracts

### Entities

[To be designed]

### API Endpoints

[To be designed]

### Events and Webhooks

[To be designed]

### Formulas and Rules

[To be designed]

## 5. Edge Cases & Failure Modes

[To be designed]

## 6. Dependencies

[To be designed]

## 7. Non-Functional Requirements

### Security

[To be designed]

### Performance Budget

[To be designed]

### Caching Decision

[To be designed]

### Observability

[To be designed]

### Accessibility

[To be designed]

### Localization

[To be designed]

### Configuration

[To be designed]

## 8. Acceptance Criteria

[To be designed]

## Cross-References

[To be designed]

## Open Questions

[To be designed]
```

> **This skeleton and the template must stay identical in section set and
> order.** If you add a section to one file, add it to the other in the same
> commit. Tier markers (`[R]`, `[C]`, `[O]`) from the template are dropped in the
> skeleton; the tier is recorded in the header's `Effective tier` line instead.

Ask: "May I create the skeleton file at `design/specs/[feature-name].md`?"

If the user declines: Stop with the following message:
> "Verdict: **BLOCKED** — skeleton creation declined. The specification session cannot proceed without the skeleton file, as all subsequent phases use it as the base. Re-run `/design-spec [feature]` when ready to create the file."
Do not proceed to Section A. Record the blocker in the checkpoint (`production/session-state/active.md`, per `.claude/docs/checkpoint-handoff.md`).

After writing, update `production/session-state/active.md`:
- Use Glob to check if the file exists.
- If it **does not exist**: use the **Write** tool to create it. Never attempt Edit on a file that may not exist.
- If it **already exists**: use the **Edit** tool to update the relevant fields.

File content:
- Task: Specifying [feature-name]
- Current section: Starting (skeleton created)
- File: design/specs/[feature-name].md

---
