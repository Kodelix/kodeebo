# /db-migration - Phase 1: Inputs and Classification

> Phase 1 of `SKILL.md`. Read it again if the conversation was compacted.

## 1. Parse the argument

| Argument | Meaning |
|---|---|
| `<feature-slug>` | The spec filename stem; the plan is `docs/architecture/migration-plans/<slug>.md` |
| a free-text change ("rename `plan` to `plan_code` on subscriptions") | Derive a slug and confirm it |
| no argument | Ask what changes and for which feature (`AskUserQuestion`) |

## 2. Derive the stores

`stack.data` from the resolved config lists the stores (any of `postgres`,
`mongo`, `redis`, `dragonfly`). The migration touches **postgres** and/or
**mongo**. Redis-protocol data is cache or durable-ish state, not a migration
target: a key-shape change there is a `v` bump in the key schema
(`caching-standard.md`), routed to `/cache-design`. An unset `stack.data` is
asked ("which store holds this data?"), never assumed.

`tenancy.model` shapes the work: `shared-schema-rls` (default; RLS policy per
tenant table), `schema-per-tenant` / `db-per-tenant` (the change must roll out
to every tenant schema or database, resumably; the mechanics are **NOT
SOURCEABLE** in `docs/stack-reference/postgres/best-practices.md`, which calls
it an ADR decision: route to `/research` and the tenancy ADR), `single-tenant`
(tenant columns marked n/a with the reason). Unset: ask; if unanswered, treat as
`shared-schema-rls` and say it is assumed.

## 3. Record every input as FOUND or ABSENT

| Input | Path / source | Why |
|---|---|---|
| Feature spec, research note | `design/specs/<slug>.md`, `docs/research/<slug>.md` | what data changes and why |
| Migration tool and layout | an ADR (`docs/architecture/adr-*.md`) naming it, else the existing files under `**/migrations/` | file naming and up/down convention (`rules/migrations.md`: `NNNN_<verb>_<object>.sql` or the tool's convention) |
| Existing migrations | `**/migrations/` per code root (`bash .claude/hooks/yaml-helper.sh resolve_code_root`) | next sequence number, current schema, precedent |
| Schema now | the latest migrations + any schema dump | what exists |
| Pinned engines, hosted and bundle | `docs/stack-reference/pins.yaml` (`postgres.image`; `mongo.image` and `mongo.image_self_hosted`), `docs/stack-reference/{postgres,mongo}/VERSION.md` | version-qualified features must hold on both |
| Stack reference | `docs/stack-reference/postgres/best-practices.md` section 3 (safe migrations), section 1 (RLS); `docs/stack-reference/mongo/best-practices.md` | lock-safe forms; no recall |
| Supported upgrade-from versions | the product's stated policy / release records under `production/` | the self-hosted path |
| Table size and write rate | the user (row counts, growth, peak write rate), `docs/architecture/perf-budgets.md` | hot or not |
| Threat model / tenant model | `docs/architecture/threat-models/<slug>.md` | sensitive columns, RLS requirements |
| Deploy bundle | `deploy/hosted/`, `deploy/self-hosted/` | how migrations run (one-shot job) |

**Absent rules**
- **Migration tool undecided** (no ADR, no existing migrations): the plan can be
  written, but no migration file is: file layout, up/down convention and the
  apply command are the tool's. Verdict is at best `NOT ASSESSED`; route to
  `/research` (tool choice) and `/architecture-decision`.
- **Table size unknown:** treat the table as **hot and large** (online forms
  only, no table rewrite) and ask the user for an estimate. The plan states
  "size unknown - treated as hot".
- **Supported upgrade-from range unknown:** ask the user which released versions
  customers may upgrade from. Unanswered -> the self-hosted path is `NOT
  ASSESSED` and the contract step is not scheduled.
- **Engine pin unreadable:** version-qualified syntax is `NOT SOURCEABLE`.

## 4. Classify the change

Classify each atomic change. Hot = large or high write rate or unknown size.

| Change | Pattern |
|---|---|
| New table / collection | One step. New tables are empty and unseen by the running version. Tenant-owned: `tenant_id NOT NULL`, tenant-leading index, RLS (`ENABLE` + `FORCE`) with the policies in the **same transaction**; money `bigint` minor units + currency; `timestamptz`; `uuid` (v7) ids |
| Add nullable column; add column with a non-volatile default | Expand only (no rewrite for a non-volatile default, per the stack reference); volatile defaults, generated or identity columns rewrite the table |
| Add `NOT NULL` | `CHECK (col IS NOT NULL) NOT VALID` -> backfill -> `VALIDATE` -> `SET NOT NULL` -> drop the check (stack reference section 3 item 4) |
| Add foreign key / CHECK | `NOT VALID`, then `VALIDATE CONSTRAINT` in a later step |
| Add index on an existing table | `CREATE INDEX CONCURRENTLY`, outside a transaction; verify the index is valid afterwards |
| Rename a column, table or enum value | Expand (new name) + dual-write + backfill + switch reads + contract (drop old) across releases. A bare `RENAME` breaks the running version and mid-upgrade installs |
| Change a column type | New column, dual-write, backfill, switch reads, contract. `ALTER COLUMN TYPE` rewrites unless binary-coercible |
| Split / merge tables, move data between stores | Expand -> migrate -> contract with dual-write; an ADR when it changes a data-store decision |
| Add RLS to an existing table | `ENABLE` + `FORCE` + policies in one transaction (an enabled table with no policy is default-deny and blacks out the app) |
| Drop column / table / index | Contract only, after no supported version reads it; destructive: user approval + backup step |
| Mongo: add field | Additive; documents carry `_v`; readers upgrade lazily; writers write the latest shape |
| Mongo: tighten a validator | Only after writers emit the new shape and existing documents are audited; validation level/action choices are in `docs/stack-reference/mongo/best-practices.md` section 1; `constraint` is new in 9.0 and is **not** on the 8.0 self-hosted bundle image |
| Mongo: add/alter an index | Declared in code/migrations, leading with `tenant_id`; online-build behaviour is **NOT SOURCEABLE** in the stack reference: `/research` before relying on it for a large collection |
| Major engine upgrade (`pg_upgrade`, engine major) | Not this skill: a runbook owned by `infra-engineer`; see `docs/stack-reference/postgres/best-practices.md` section 4 |

State the classification and the **number of releases** it needs. Any change
that needs expand/contract and is planned as a single step is a finding: stop
and re-plan.

## 5. Report the plan

"Migrating [feature]: stores [postgres, mongo]; tenancy [model, assumed?];
changes [list with pattern]; tool [name | undecided]; baseline [latest
migration]; supported upgrade-from [versions | unknown]; table sizes [list |
unknown - treated as hot]; engine pins hosted [x] / bundle [y]; review mode
[mode]."
