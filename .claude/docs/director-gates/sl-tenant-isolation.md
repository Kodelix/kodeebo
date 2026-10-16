> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# SL-TENANT-ISOLATION — Tenant Isolation Review

Agent: `security-lead` | Model tier: session (inherit) | Domain: Security baseline, tenant isolation, access control

**Trigger**: `/tenant-check` on a feature or the whole product; `/story-done`
for any story that reads or writes tenant-owned data (a new table, collection,
cache key family, queue, file prefix, search index or endpoint); `/security-audit`
and `/team-hardening` for a full sweep. A query that can return another
tenant's row is a security bug (`coding-standards.md`).

**Context to pass**:
- Story file and feature spec path (`design/specs/<feature>.md`)
- Code paths for the repositories / adapters, use cases and HTTP handlers touched, per code root (`resolve_code_root`)
- Migration paths that create or alter tenant-owned tables (RLS policies, schema or database provisioning)
- Test paths and `production/qa/evidence/<story-id>/` negative-test results
- `tenancy.model` from `project.yaml` (`shared-schema-rls`, `schema-per-tenant`, `db-per-tenant`, `single-tenant`)
- Threat model path, if one exists

**Checks**:
1. The isolation mechanism matches `tenancy.model`: for `shared-schema-rls`, every new tenant-owned table has RLS enabled with a policy keyed on the tenant, and the tenant is set for the session or transaction per request; for `schema-per-tenant` or `db-per-tenant`, provisioning and connection routing are shown; for `single-tenant`, the check is recorded as not applicable with the reason.
2. App-layer scoping as well: every query in the changed code includes the tenant predicate (or goes through a repository that adds it) — defence in depth, not RLS alone. List each query and its scope (`file:line`).
3. MongoDB queries are filtered by `tenant_id` through the repository, never ad hoc; no `$where` or operator injection from user input.
4. The tenant comes from the authenticated context, never from the request body, path or a client header; object-level authorization follows load → check tenant and ownership/role → act on every resource access.
5. Negative tests exist and pass against real dependencies (Testcontainers, not mocks): tenant A cannot read, list, update, delete or guess the ID of tenant B's data; the repository round-trip proves a row of tenant A is invisible to tenant B; each endpoint has an authz test for anonymous, wrong role and wrong tenant.
6. Non-database paths are tenant-scoped too: cache keys and TTL invalidation include the tenant; queue messages and outbox events carry the tenant and consumers restore it; background jobs run in a tenant context; file/object keys are tenant-prefixed and signed URLs are scoped; search indexes and exports filter by tenant.
7. Telemetry carries `tenant_id` as a span/log attribute where known and does not leak other tenants' data; no tenant label on high-cardinality metrics (`observability-standard.md`).
8. Noisy-neighbour controls exist: rate limits and quotas per tenant, bounded pagination and timeouts on the new endpoints.
9. Admin and impersonation paths require step-up, are time-boxed and are written to the append-only audit log with actor, target and reason.
10. Cross-tenant-by-design operations (platform admin, aggregate reports) are listed, authorised separately and tested.

**Prompt**:
> "Review this change for tenant isolation. Does the isolation mechanism match
> the product's tenancy model? Is every query scoped by the authenticated
> tenant at the application layer as well as the database layer? Do negative
> tests prove that one tenant cannot read or modify another's data through the
> API, caches, queues, files and jobs? Return APPROVE, CONCERNS [specific
> gaps], or REJECT [a path exists by which one tenant can reach another tenant's
> data, or the proof is missing]."

**Verdicts**: APPROVE / CONCERNS / REJECT

**NOT ASSESSED when**: `tenancy.model` is unset (the stack was not configured),
or the code, migration or test paths cannot be read. Negative tests that were
not run are reported as not run and, for a story touching tenant data, are a
finding (REJECT) rather than a missing input once the skill says no run exists.

**Output**: the standard block, with a query/path table (location — mechanism — scoped? — negative test).
