---
paths:
  - "design/**"
---

# Product Design Document Rules

Tiers and required sections: `.claude/docs/workflow-modes.md`.

- One spec per feature at `design/specs/<feature>.md`; the filename stem is the feature key everywhere.
- Rules are unambiguous and testable; every "should" becomes a "must" or is removed.
- Permissions are stated per role and per plan; limits and quotas are named configuration, not inline numbers.
- Non-Functional Requirements always cover security, performance budget, caching decision, observability, accessibility and AR/EN localization — even at `minimal` the research note carries them.
- Acceptance criteria include negative cases (wrong role, other tenant, provider down, over quota).
- Pricing and plan effects link to the pricing model, never restate prices.
- UX specs live in `design/ux/`; product context for impeccable lives in `PRODUCT.md` (project root — impeccable's location).
