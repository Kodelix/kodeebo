# /tenant-check - Dynamic Checks: Catalogue Query and Negative Tests

> Phase 3 of `SKILL.md`. Read-only against a **non-production** database the
> user names. Ask before running anything against a database. Credentials are
> loaded by the user into the environment; never print, echo or store a
> connection string or password. The skill runs no `INSERT`, `UPDATE`, `DELETE`,
> DDL, `TRUNCATE` or role change.

## 1. Choose the database

`AskUserQuestion`: (a) a Testcontainer/compose database that the project's
integration-test setup migrates from scratch, (b) a local or staging database the
user names that is already migrated, (c) none. Production is never offered.

- (c) none: T1/T2/T5-views are `NOT ASSESSED - no database to query`; migrations
  are still read and their text reported as `static only` (a statement in a
  migration file is not proof of the catalogue state).
- The database must be at the product's current migration head. If the migration
  state cannot be established, say so; the result is evidence for that database,
  not for the release.

## 2. Catalogue query (T1, T2, T5)

These queries are composed by this skill from the catalogue names the stack
reference cites (`pg_class.relrowsecurity`, `pg_class.relforcerowsecurity`,
`pg_policies`, `postgres/best-practices.md` §1/§7). Column names beyond those are
standard system-catalogue columns: confirm them against the PostgreSQL system
catalogue documentation for the pinned major (`pins.yaml` `postgres.image`) the
first time; if a query errors, the check is `not run - query error`, never a
pass. The tenant column is `tenant_id` unless the spec or ADR fixes another name.

**A. Tenant tables lacking RLS or a policy (must return no rows)**

```sql
SELECT n.nspname AS schema, c.relname AS "table",
       c.relrowsecurity AS rls_enabled, c.relforcerowsecurity AS rls_forced,
       (SELECT count(*) FROM pg_policies p
         WHERE p.schemaname = n.nspname AND p.tablename = c.relname) AS policies
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname = 'tenant_id' AND NOT a.attisdropped
WHERE c.relkind IN ('r', 'p')
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND ( NOT c.relrowsecurity OR NOT c.relforcerowsecurity
        OR (SELECT count(*) FROM pg_policies p
             WHERE p.schemaname = n.nspname AND p.tablename = c.relname) = 0 );
```

**B. Tables with no `tenant_id` column (classify each)**

```sql
SELECT n.nspname AS schema, c.relname AS "table"
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'p')
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND NOT EXISTS (SELECT 1 FROM pg_attribute a
                   WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND NOT a.attisdropped);
```
Every row is classified with the user as **global by design** (listed, with a
reason, e.g. migration bookkeeping, plan catalogue) or **tenant-owned and missing
the column** (a finding). An unclassified table is `unknown`, which keeps T2
`NOT ASSESSED` for that table - it is not assumed global.

**C. Views over tenant tables and their invoker setting**

```sql
SELECT n.nspname AS schema, c.relname AS view_name, c.reloptions
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'v' AND n.nspname NOT IN ('pg_catalog', 'information_schema');
```
Each view that reads a tenant table must show `security_invoker=true` in
`reloptions`; others are findings (a view runs with its owner's rights otherwise,
`postgres/best-practices.md` §1).

**D. Role attributes and table owners (T1)**

```sql
SELECT rolname, rolsuper, rolbypassrls, rolcanlogin FROM pg_roles
WHERE rolname NOT LIKE 'pg\_%' ESCAPE '\';

SELECT n.nspname AS schema, c.relname AS "table", pg_get_userbyid(c.relowner) AS owner
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'p') AND n.nspname NOT IN ('pg_catalog', 'information_schema');
```
Expected: the role the application connects as has `rolsuper = false`,
`rolbypassrls = false`, and owns no tenant table; only `admin_batch` (and
superuser/migrator roles outside the app path) bypass RLS. The role the app uses
comes from the deploy/connection config (T1); if it cannot be established from
config, T1 is `NOT ASSESSED - app role unknown`.

Policy shape (`USING` and `WITH CHECK` present, RESTRICTIVE hard predicate, no
`COALESCE` default) is read from the migration text and, where the user allows,
`pg_policies`; a table with a policy whose shape cannot be read is `unknown`.

Save each query's text, the database identity (name only, no host/credentials),
the migration head, the timestamp and the raw result to the evidence folder.

## 3. Negative tests (T14)

1. Locate the cross-tenant tests per layer (repository, cache adapter, endpoint,
   job) by name and path; list tests expected but absent (**absent = finding**).
2. Verify each runs as the non-owner `NOBYPASSRLS` role: read the fixture/connection
   setup. A test fixture that connects as the container superuser or owner is
   `invalid evidence` - record it, do not count it.
3. Run them. Ask: "Run the cross-tenant tests now?" The command comes from the CI
   config or the layer-checks table of the project; if neither names one, ask the
   user - do not invent flags. Needs a container runtime for Testcontainers; where
   absent the run is `NOT ASSESSED - container runtime unavailable`.
4. Record per test: name, result (`passed` / `FAILED` / `not run` / `stale`),
   command, exit code. Stale = the evidence on disk predates the last change to the
   code under test (compare timestamps/commits).
5. Required scenarios, each a named test: A cannot SELECT/UPDATE/DELETE/INSERT-as B;
   unset setting returns 0 rows; pooled connection reuse (pool size 1) does not
   leak; cache key isolation; storage prefix isolation; a job carrying tenant A
   cannot touch tenant B; cross-tenant ID guess returns 404; pagination cursor from
   A is rejected in B.

Verdict inputs: tests absent -> `REJECT`-class finding; a failing test -> a
confirmed path (CRITICAL until shown otherwise); tests present but the user
declines to run and no passing output exists -> proof missing (`REJECT`-class,
the gate's rule); tests present but the environment cannot run them ->
`NOT ASSESSED` with the cause.
