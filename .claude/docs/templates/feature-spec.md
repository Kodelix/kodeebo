# [Feature Name]

> **Status**: Draft | In Review | Approved | Implemented
> **Author**: [Agent or person]
> **Last Updated**: [Date]
> **Last Verified**: [Date — when this spec was last confirmed accurate against the current product]
> **Serves principle**: [Which product principle from `design/product-principles.md` this supports, if the file exists]
> **Effective tier**: [minimal | standard | full] — resolved from `modes.workflow` / `workflow_overrides.system_overrides.<feature>` (see `workflow-modes.md`)

<!--
TIER MARKERS (see workflow-modes.md). Each section header carries one:
  [R]  required at standard and full
  [C]  conditional at standard (required when the feature calls an external
       provider, moves money, changes entitlements, or runs asynchronously);
       required at full
  [O]  optional at standard; required at full
At `minimal` no spec is required — the product brief and the research note cover it.
Delete the markers when the spec is finished. Delete guidance comments freely.
Filename stem = the feature key: design/specs/team-invitations.md -> `team-invitations`.
-->

## Summary

[2–3 sentences: what this feature is, what it does for the user, and why it
exists in this product. Written for tiered context loading — a skill scanning 20
specs uses this to decide whether to read further. No jargon.]

> **Quick reference** — Layer: `[Foundation | Core | Feature | Presentation]` · Priority: `[MVP | Vertical Slice | Beta | Full Vision]` · Bounded context: `[name]` · Key deps: `[contexts / providers or "None"]` · Plan gate: `[plan / entitlement key or "all plans"]`

## 1. Overview [R]

<!-- One paragraph for someone who knows nothing about the product: what it is, who uses it, why it exists. -->

## 2. User Value [O]

<!-- Who needs it (role: tenant admin / member / end customer / self-hosted operator), the job it does for them, what happens if it is missing, and how it affects plan/pricing (which plan includes it, which entitlement or quota gates it). -->

| Role | Job to be done | Success looks like |
|------|----------------|-------------------|
| | | |

**Plan / pricing impact**: [included in plans X, Y · entitlement key `feature.x` · quota `x_per_month` · add-on? · self-hosted licence claim?]

## 3. Detailed Behaviour [R]

### Core Rules

<!-- Precise, unambiguous rules. An engineer must be able to implement this section without asking questions. Numbered rules for sequences, bullets for properties. -->

### Permissions per Role

| Action | Owner | Admin | Member | Viewer | Anonymous | Other tenant |
|--------|-------|-------|--------|--------|-----------|-------------|
| [create] | | | | | 401 | 404 |

<!-- Cross-tenant access answers 404 (api-standards.md), never 403. Every action has a row. -->

### States and Transitions

| State | Entry Condition | Exit Condition | Behaviour / visible to user |
|-------|----------------|----------------|----------------------------|

### Interactions with Other Contexts

<!-- For each interaction: data in, data out, who is responsible, sync vs event. -->

## 4. Data & Contracts [R]

### Entities

| Entity | Owner (context) | Key fields | Tenant key | Retention / deletion | PII? |
|--------|-----------------|-----------|------------|---------------------|------|

### API Endpoints

<!-- Link to contracts/openapi/<service>.yaml — the contract lands first. -->

| Method + path | Purpose | Auth / policy | Idempotent? | Success | Errors (problem `code`) |
|---------------|---------|---------------|-------------|---------|-------------------------|
| `POST /v1/...` | | | `Idempotency-Key` | 201 | `plan_limit_reached` 422 |

### Events and Webhooks

| Event | Producer | Consumers | Payload (link) | Delivery guarantee |
|-------|----------|-----------|---------------|-------------------|

### Formulas and Rules (only if the feature defines numeric rules — rates, curves, thresholds, costs)

```
result = base_value * (1 + modifier_sum) * scaling_factor
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| base_value | int (minor units) | 0–1,000,000 | plan config | |

**Expected output range**: [min] to [max]
**Rounding**: [half-even in minor units / floor / ...]
**Edge case**: [clamping or zero behaviour]

## 5. Edge Cases & Failure Modes [C]

<!-- Required at standard when the feature calls an external provider, moves money, changes entitlements, or runs asynchronously. Each row has a clear resolution. -->

| Scenario | Expected Behaviour | Rationale |
|----------|-------------------|-----------|
| Invalid / oversized input | | |
| Concurrent or repeated request (double submit, webhook replay) | | |
| Provider outage / timeout / partial failure | | |
| Cache or queue down | | |
| Quota exceeded / plan downgraded mid-flow | | |
| User deleted / tenant suspended / trial expired | | |
| Abuse (enumeration, scraping, coupon stacking, seat inflation) | | |
| Clock skew / time zone / DST | | |

## 6. Dependencies [O]

| Depends on | Kind (context / core module / provider / flag) | Direction | Nature |
|------------|-----------------------------------------------|-----------|--------|
| | | This depends on X / X depends on this | |

**Feature flags**: [`flag.key` — default, rollout plan, removal date]

## 7. Non-Functional Requirements [R]

### Security
- **Sensitive area?** [auth · authz · billing · licensing · file upload · webhooks · PII export/delete · admin/impersonation · new integration — if yes a threat model is required]
- **Threat model**: [`docs/architecture/threat-models/<feature>.md` or "not required: <reason>"]
- **Standards mapping**: OWASP ASVS [chapter/requirement IDs, looked up in the official ASVS 5.0 document] · MASVS [IDs, mobile only] · API Top 10 [relevant items]
- **Tenant isolation**: [app-layer scoping + RLS / per-tenant store; how it is tested]
- **Data classification**: [public · internal · confidential · PII] · **Logging**: no PII/secrets in telemetry
- **Abuse limits**: [rate limits per tenant/actor/route; quotas]

### Performance Budget
| Surface | Budget (from `perf-budgets.md`) | This feature |
|---------|-------------------------------|--------------|
| Endpoint p95 | [150 ms read / 300 ms write] | |
| Queries per request | [<= 5, no N+1] | |
| Payload | [list <= 100 items, <= 200 KB] | |
| Background job max runtime | | |
| Web LCP/INP/CLS · mobile cold start | | |

### Caching Decision
<!-- Fields from caching-standard.md. "No cache" is valid — write the reason. -->
- **Decision**: [cache / no cache + reason]
- **What · pattern · key schema · TTL (+jitter) · invalidation · stampede protection · failure mode · expected hit ratio**: [or link to `cache-design.md` entry]

### Observability
- **Spans**: [use case + external calls]
- **Metrics**: [RED on endpoints; business metrics, e.g. invitations_sent, invitations_accepted]
- **Logs**: [outcome events, no PII]
- **Alerts / SLO**: [burn-rate alert on journey `x`; cause alerts] · **Runbook**: [`docs/runbooks/<name>.md`]

### Accessibility
- **Target**: [WCAG 2.2 AA — per `accessibility-requirements.md`] · keyboard path, focus order, labels, contrast, reduced motion, screen reader announcements for dynamic content
- **UX spec**: [`design/ux/<screen>.md`]

### Localization
- **Locales**: Arabic (RTL) and English · all user-visible strings externalised (no hardcoded copy) · plural/gender forms · number, date, currency formatting per locale · mirrored layout and icons · emails and error messages translated · **Strings added/changed**: [keys or count]

### Configuration (add when `workflow_overrides.tuning_knobs` is on, or the feature has tunable values)

<!-- Every value that must be adjustable without a deploy. No hardcoded business values (coding-standards.md). -->

| Parameter | Default | Safe range | Where configured (env / DB / plan data) | Effect of increase | Effect of decrease |
|-----------|---------|-----------|----------------------------------------|-------------------|-------------------|

## 8. Acceptance Criteria [R]

<!-- Testable. Include negative and cross-tenant cases. Each criterion states the story type that proves it. -->

**Functional**
- [ ] [Criterion 1: specific, measurable, testable] — *Logic / Integration / Contract*
- [ ] [Criterion 2]

**Negative / authorization**
- [ ] Anonymous request to each endpoint returns 401
- [ ] A role without permission receives 403 and nothing changes
- [ ] A user in tenant B requesting tenant A's resource receives 404 (no existence leak)
- [ ] Invalid input returns 422 with problem `code`; malformed returns 400
- [ ] Repeating the request with the same `Idempotency-Key` has no second effect

**Non-functional**
- [ ] Meets the performance budget above (load-test evidence)
- [ ] Emits spans, RED metrics and outcome logs; no PII in telemetry
- [ ] Security mapping complete; dependency scan clean
- [ ] Arabic (RTL) and English screens verified; accessibility target met
- [ ] No hardcoded business values; configuration values documented above

## Cross-References

<!-- Declare every explicit dependency on another spec's behaviour, value or rule.
     Machine-checked by /review-all-specs; replaces implicit prose references. -->

| This Document References | Target Spec | Specific Element Referenced | Nature |
|--------------------------|------------|----------------------------|--------|
| [e.g. "seat limit comes from the plan"] | `design/specs/pricing.md` | `max_seats` entitlement | Data dependency |
| [e.g. "cancellation triggers data export"] | `design/specs/data-export.md` | Cancellation state transition | State trigger |

> **Nature**: `Data dependency` (we consume their output) · `State trigger` (their
> state change triggers our behaviour) · `Rule dependency` (our rule assumes
> theirs is also true) · `Ownership handoff` (we hand ownership of a value to them).

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
