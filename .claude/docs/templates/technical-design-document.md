# Technical Design: [Feature or Bounded Context Name]

## Document Status
- **Version**: 1.0
- **Last Updated**: [Date]
- **Author**: [Agent/Person]
- **Reviewer**: principal-engineer
- **Related ADR**: [ADR-XXXX if applicable]
- **Related Spec**: [Link to the feature spec this implements — `design/specs/<feature>.md`]
- **Research note**: [`docs/research/<feature>.md` — required before this is Accepted]

## Stack API Surface

| Field | Value |
|-------|-------|
| **Stack layer(s)** | [Go backend / Ktor backend / Web / Android / iOS / KMP] |
| **Versions pinned** | [library/service @ version — from `docs/stack-reference/pins.yaml`] |
| **APIs Depended On** | [Specific packages/classes/functions/endpoints used, version-pinned — e.g. `pgx v5 CopyFrom`] |
| **References Consulted** | [stack-reference docs read before writing this — e.g. `docs/stack-reference/postgres/best-practices.md`] |
| **`saas-core` modules used** | [module @ version, or "None"] |
| **Post-Cutoff Features Used** | [Features beyond the model's training cutoff, or "None"] |
| **Unverified Assumptions** | [Behaviours assumed but not yet tested against the pinned version, or "None"] |
| **Upgrade Risk** | [LOW / MEDIUM / HIGH — how fragile is this design if a pinned version changes?] |

> **Rule**: If any **Unverified Assumptions** are listed, this document cannot be
> marked Accepted until those assumptions are validated against the pinned versions.

## Overview
[2-3 sentence summary of what this design does and why it exists]

## Requirements
### Functional Requirements
- [FR-1]: [Description — trace to a spec requirement `TR-<feature>-NNN`]
- [FR-2]: [Description]

### Non-Functional Requirements
- **Performance**: [Budget from `perf-budgets.md` — e.g. "read endpoint p95 <= 150 ms, <= 5 queries"]
- **Scalability**: [Limits — e.g. "10k tenants, 5M rows per tenant-largest table"]
- **Availability / SLO**: [Journey and target, if affected]
- **Security & tenancy**: [ASVS/MASVS refs; threat model link; tenant isolation approach]
- **Concurrency & consistency**: [Transactions, idempotency, ordering, locking]
- **Observability**: [Spans, metrics, log events, alerts]
- **Caching**: [Decision or "no cache" with reason]

## Architecture

### System Diagram
```
[Diagram-as-code (Mermaid) or ASCII showing components, data flow, trust boundaries]
```

### Component Breakdown
| Component | Layer (domain / app / adapters) | Responsibility | Owns (data) |
| --------- | ------------------------------- | -------------- | ----------- |
| [Name] | [layer] | [What it does] | [What data it owns] |

### Public API
```
[Port interfaces and/or API definition. Link to contracts/ for HTTP.]
```

### Data Model
```
[Tables/collections/keys with fields, tenant key, indexes, retention, migration notes]
```

### Data Flow
[Step by step: how a typical request / job / event moves through the system, including auth check, tenant scoping, DB, cache, outbound calls]

## Implementation Plan

### Phase 1: [Core Functionality]
- [ ] [Task 1]
- [ ] [Task 2]

### Phase 2: [Extended Features]
- [ ] [Task 3]

### Phase 3: [Hardening — load test, security tests, runbook]
- [ ] [Task 4]

## Dependencies
| Depends On | For What |
| ---------- | -------- |
| [Context / core module / provider] | [Reason] |

| Depended On By | For What |
| -------------- | -------- |
| [Context / client] | [Reason] |

## Testing Strategy
- **Unit Tests**: [Domain rules and use cases with fakes]
- **Integration Tests**: [Testcontainers: PG/Mongo/Redis/Dragonfly cases]
- **Contract Tests**: [API shape vs `contracts/`]
- **Security Tests**: [Authz bypass, cross-tenant, injection, rate limit]
- **Performance Tests**: [k6 scenario; query-count assertion]
- **Edge Cases**: [Specific scenarios to test]

## Operations
- **Rollout**: [flag, migration order, backward compatibility]
- **Runbook**: [`docs/runbooks/<name>.md`]
- **Self-hosted impact**: [Extra services, config, upgrade path, or "None"]

## Known Limitations
[What this design intentionally does NOT support and why]

## Future Considerations
[What might change if requirements evolve — but do NOT build for this now]
