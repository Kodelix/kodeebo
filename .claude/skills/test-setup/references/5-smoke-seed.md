# /test-setup — Phase 5: Create Smoke Test Seed

> Part of `/test-setup`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 5: Create Smoke Test Seed

Create `production/qa/smoke-tests.md` (the file `/smoke-check` reads). Skip rows
for layers that are not configured, and say which were skipped:

```markdown
# Smoke Test: Critical Paths

**Purpose**: Run these checks in under 15 minutes before any QA hand-off.
**Run via**: `/smoke-check` (which reads this file)
**Environment**: the dev compose stack (`docker compose -f deploy/compose.dev.yaml up -d --wait`)
and the seeded test tenant (`tools/seed/`) only — never staging or production, never real customer data.
**Update**: Add new entries when a new core journey is implemented.

## Core Stability (always run)

1. The stack starts and every healthcheck passes; migrations are applied
2. The readiness endpoint answers 200
3. Sign-in as the seeded owner works; a token refresh returns a new access token

## Core Journey (update per sprint)

<!-- Add the primary journey for each sprint here as it is implemented -->
<!-- Example: "Owner invites a member; the member accepts and sees only their tenant's data" -->
4. [Primary journey — update when the first core feature is implemented]

## Access Control and Tenancy

5. An anonymous request to a protected endpoint returns 401 with a problem-details body
6. Tenant A's token requesting a tenant B resource ID returns 404 and no tenant B data
7. A member-level token on an owner-only endpoint returns 403

## Money and Licences (only when the product takes payments or ships self-hosted)

8. Provider-sandbox payment completes and the entitlement changes exactly once (repeat is idempotent)
9. Licence activation succeeds with a valid licence and fails with an expired or forged one

## Data Integrity

10. A migration applied to a seeded database leaves existing tenant data intact

## Performance

11. A hot endpoint answers within its `docs/architecture/perf-budgets.md` budget on the dev stack
    (skipped until a budget row exists — the report says so)
```

Create the file only if it does not exist; never overwrite a smoke list a team has edited.

---
