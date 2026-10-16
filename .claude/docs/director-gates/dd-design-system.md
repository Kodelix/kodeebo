> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# DD-DESIGN-SYSTEM — Design System Sign-Off

Agent: `design-director` | Model tier: session (inherit) | Domain: Visual identity, design system, UI production readiness

**Trigger**: After `PRODUCT.md` and `DESIGN.md` are written or revised through
impeccable (`/impeccable init`, `/impeccable document`, `/impeccable extract`),
before UI production begins (first UI story in `/team-ui` or `/dev-story`).

**Context to pass**:
- `PRODUCT.md` and `DESIGN.md` at the repository root (impeccable's location), and `design/ux/` specs if any
- Product principles and ICP (`design/product-brief.md`)
- Platforms: `stack.web`, `stack.site`, `stack.mobile` and `accessibility.target` from `project.yaml`
- Performance budgets for the UI surfaces (`docs/architecture/perf-budgets.md`; defaults in `performance-standard.md`: web LCP / INP / CLS, initial JS, mobile cold start)
- Visual identity anchor chosen at DD-CONCEPT-VISUAL (recorded in `PRODUCT.md` or the brief)
- Output of `impeccable context` (confirms which files it resolved)

**Checks**:
1. `PRODUCT.md` exists at the repository root and records users, purpose, brand personality, anti-references (at least two) and platform (`web`, `ios`, `android` or `adaptive`); each field is user-confirmed or labelled inferred.
2. `DESIGN.md` defines the token set — colour roles, type scale and pairing, spacing, radius, elevation, motion — with concrete values (at least three decisions per axis), and states the surface mode (Persuade, Operate, Read) per surface.
3. The colour system meets the `accessibility.target` contrast level for every text/background role pair: cite the computed ratios or the audit result.
4. The type system covers Arabic and Latin, with RTL mirroring rules and numeral policy stated (coordinated with `localization-lead`).
5. Tokens are exportable to every platform in `stack.*`: web CSS variables, Compose theme, SwiftUI assets; no platform needs a value the document does not define.
6. The system is achievable within the platform and performance budgets: font payload, icon strategy, and motion respect the web JS/LCP budgets and mobile cold-start budget.
7. `PRODUCT.md` and `DESIGN.md` do not contradict each other or the product principles; the identity is not the generic-SaaS default the anti-references rule out.
8. Component and state coverage is specified for the app shell, forms, tables, empty, loading and error states, and destructive-action patterns.
9. An outside designer or engineer could build a screen from these two documents without additional briefing; name anything they would have to invent.

**Prompt**:
> "Review this design system for completeness and internal consistency. Does the
> colour system meet the accessibility target and match the brand personality?
> Does the type system work for Arabic and English including RTL? Are tokens
> complete enough to be exported to every platform in the stack? Are the
> standards achievable within the platform's performance budgets? Are there
> contradictions between PRODUCT.md and DESIGN.md? Would an outside team be able
> to produce screens from these documents without additional briefing? Return
> APPROVE (design system is production-ready), CONCERNS [specific sections
> needing clarification], or REJECT [fundamental inconsistencies that must be
> resolved before UI production begins]."

**Verdicts**: APPROVE / CONCERNS / REJECT

**NOT ASSESSED when**: `PRODUCT.md` or `DESIGN.md` cannot be read, or the
platform list is not passed. A `DESIGN.md` the skill reports as not yet written
is a finding (REJECT for UI production that is about to start), not a missing input.

**Output**: the standard block, with contrast ratios (pair — ratio — target) under Check 3.
