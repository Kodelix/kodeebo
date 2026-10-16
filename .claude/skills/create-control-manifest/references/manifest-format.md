# /create-control-manifest — Manifest File Format

> Part of `/create-control-manifest`. Read at Phase 5 when writing the file.

```markdown
# Control Manifest

> **Stack**: [layers + pinned versions, from pins.yaml]
> **Tenancy / Deploy / Distribution**: [from project.yaml]
> **Last Updated**: [date]
> **Manifest Version**: [date]
> **ADRs Covered**: [ADR-NNNN, ADR-MMMM, ...]   (or "none — built from standards and the decision log (workflow: minimal)")
> **ADRs Excluded (not Accepted)**: [ADR-NNNN ([status]), ... or "None"]
> **Not covered**: [sections with no sourced rules and why, or "None"]
> **Status**: [Active — regenerate with `/create-control-manifest update` when ADRs change]

`Manifest Version` is the date this manifest was generated. Story files embed
this date when created. `/story-readiness` compares a story's embedded version
to this field to detect stories written against stale rules. Always matches
`Last Updated` — they are the same date, serving different consumers.

This manifest is a quick-reference extracted from all Accepted ADRs, the studio
standards, and the stack-reference deprecation lists. For the reasoning behind
each rule, see the referenced ADR or standard.

---

## Global Rules (All Layers)

### Architecture and Code
- **Must [rule]** — source: [ADR-NNNN | clean-architecture.md §…]
- **Never [anti-pattern]** — [brief reason] — source: [...]

### Security and Tenancy
- **Must ...** — source: [...]
- **Never ...** — source: [...]

### Observability, Caching, Performance, Testing
- **Must ...** — source: [...]

### Cross-Cutting Constraints
- [constraint that applies everywhere, regardless of layer] — source: [ADR-NNNN, standard or stack-reference file]

### Approved Libraries / Shared Core
- [library or `saas-core` module @ version] — approved for [purpose] — source: [ADR / pins.yaml / core.modules]

### Forbidden APIs ([layer] [pinned version])
These APIs are deprecated or unverified for the pinned stack:
- `[api name]` — deprecated since [version] / unverified post-cutoff
- Source: `docs/stack-reference/[layer]/deprecated-apis.md`

---

## Backend Rules ([go | ktor])

*Applies to: `backend/` — `internal/<context>/{domain,app,adapters}/` (Go) or `<pkg>/<context>/{domain,app,adapters}/` (Ktor)*

### Required Patterns
- **[rule]** — source: [ADR-NNNN]

### Forbidden Approaches
- **Never [anti-pattern]** — [brief reason] — source: [ADR-NNNN]

### Performance Guardrails
- **[endpoint or job]**: p95 ≤ [N] ms, ≤ [N] queries — source: [ADR-NNNN | perf-budgets.md]

---

## Web Rules (Vite + React SPA)

*Applies to: `web/` (and `site/` for Astro)*

### Required Patterns
...
### Forbidden Approaches
...

---

## Mobile Rules ([compose | kmp | swiftui])

*Applies to: `mobile/`*

### Required Patterns
...
### Forbidden Approaches
...

---

## Data Rules ([postgres | mongo | redis/valkey/dragonfly])

*Applies to: schemas, migrations, repositories, cache adapters*

### Required Patterns
...
### Forbidden Approaches
...

---

## Contract Rules

*Applies to: `contracts/` and every generated client*

### Required Patterns
...
### Forbidden Approaches
...

---

## Deploy Rules

### Hosted (`deploy/hosted/`)
...

### Self-Hosted Bundle (`deploy/self-hosted/`)
...(or `Not applicable — distribution.model: hosted`)

---

## Bounded Context Rules

*One subsection per context in `design/specs/domain-map.md`; rules are those whose
ADR names the context, restated here so a story for the context finds them in one place.*

### [Context name] — owner: [agent]
- **Must [rule]** — layer: [Backend | Data | ...] — source: [ADR-NNNN]
- **Never [anti-pattern]** — layer: [...] — source: [ADR-NNNN]
- Tenancy: [how tenant scope is enforced here — source]
- Shared core: [module @ version, or "none"]

(Contexts with no Accepted ADR: `No rules — no Accepted ADR governs this context.`)

---

## Unclassified Rules

[Rules whose layer or context could not be determined — with source — or "None"]
```
