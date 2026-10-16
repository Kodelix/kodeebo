---
paths:
  - "**/adapters/mongo/**"
  - "**/mongo/**"
---

# MongoDB Rules

- Use Mongo where the data is document-shaped (flexible per-tenant schemas, event payloads, content); relational, transactional data stays in Postgres. The choice per collection is in an ADR.
- Every document carries `tenant_id`; every query filter includes it — enforced in the repository, never left to callers.
- Schema validation (`$jsonSchema`) on every collection; schema version field (`_v`) for lazy migration.
- Indexes declared in code/migrations and reviewed; every query in a hot path is covered (check `explain("executionStats")`); compound indexes lead with `tenant_id`.
- No user input becomes a query operator: build filters from typed values only; reject keys starting with `$` or containing `.`.
- Bounded documents: no unbounded arrays (cap or split into a collection); documents well under the 16 MB limit.
- Writes use appropriate write concern (`majority` for anything that matters); multi-document transactions only when necessary and short.
- TTL indexes for expiring data (sessions, OTP attempts, temporary uploads).
- Tests with Testcontainers Mongo, including tenant isolation and index usage for hot queries.
