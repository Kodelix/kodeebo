# /cache-design - Phase 1 and Phase 2: Inputs, Evidence, Brief

> Phases 1-2 of `SKILL.md`. Read it again if the conversation was compacted.

## 1. Parse the argument

| Argument | Meaning |
|---|---|
| `<feature-slug>` | Design mode for the feature (`design/specs/<slug>.md`, `docs/research/<slug>.md`) |
| `--entry <name>` | One entry of the feature (several entries share one file) |
| `check <feature-or-path>` | Check mode: `references/4-check-mode.md` |
| no argument | Ask which feature and which data is read or written hot (`AskUserQuestion`) |

## 2. Record every input as FOUND or ABSENT

| Input | Path | Why |
|---|---|---|
| Feature spec | `design/specs/<slug>.md` (Detailed Behaviour, NFR) | access pattern, roles, mutation events |
| Research note | `docs/research/<slug>.md` section 7 (Performance & Caching Notes) | candidates, load estimates |
| Performance budget | `docs/architecture/perf-budgets.md` row for the surface | what the source must meet without a cache |
| Source measurement | query plan, `pg_stat_statements` output, trace, load-test result under `production/qa/evidence/` | the evidence for "worth it" |
| Tenancy and distribution | `tenancy.model`, `distribution.model` and `stack.data` from the resolved config | key design; Valkey in the bundle; is a Redis-protocol store even present |
| Existing cache designs and adapters | `docs/architecture/cache-designs/*.md`; code roots from `bash .claude/hooks/yaml-helper.sh resolve_code_root` (adapter paths in `.claude/rules/cache-code.md`) | reuse a key builder and instance; avoid a second scheme |
| Instances | `deploy/hosted/`, `deploy/self-hosted/` compose files | cache vs durable-ish instance separation; engine and `maxmemory` |
| Threat model | `docs/architecture/threat-models/<slug>.md` | sessions, OTP, authorization data |
| Stack reference | `docs/stack-reference/redis/`, `dragonfly/`, `pins.yaml` | portability (Phase 3) |

`stack.data` without `redis` or `dragonfly` and no cache instance in `deploy/`:
a Redis-protocol cache needs an instance; say so. The decision may still be
"cache in process" or "no cache"; an in-process cache is a different design
(per-instance staleness, no cross-instance invalidation), recorded in the
Pattern field with that consequence, and not covered by the portability phase.

## 3. Establish "worth it"

A cache must be worth its second copy. For each candidate record **one** of:

| Evidence level | What it is | Effect |
|---|---|---|
| **measured** | a retained plan, metric or trace: source p95 and call rate, with the file path | supports `COMPLETE` |
| **estimated** | reasoned from the access pattern, no measurement | `COMPLETE WITH GAPS`: measure after implementation (`/perf-profile`); the hit-ratio alert is the backstop |
| **none** | "it is read a lot" | `NOT ASSESSED` for the worth-it claim; offer `/perf-profile` first or a "no cache for now" decision |

Also state the budget the source must meet (`perf-budgets.md`; starting defaults
are in `performance-standard.md`: read endpoint p95 <= 150 ms, single SQL query
<= 20 ms) and whether it already does. **If the source already meets the budget
with headroom and the data changes often, "no cache" is the recommended answer**
and the skill says so.

## 4. Decide with the user

For each candidate: cache / no cache (major decision, `AskUserQuestion` with the
evidence beside each option; in `autonomous` mode choose the recommended and log
it). A "no cache" fills Section 1 of the template only, including the numbers
that justify it.

Also ask for the facts only the user has: the **staleness the product can
accept** (seconds? minutes?), which events change the data, and whether the data
is tenant-specific, per-user or global. These drive TTL and invalidation.

## 5. Design brief (`cache-specialist`)

Fill only the `{...}` slots. Add nothing else: no preferred pattern, no
expected hit ratio.

```text
Draft the cache design entry for /cache-design. Return the filled template
section as text; write no file.

Feature: {slug}   Entry: {name}   Template: .claude/docs/templates/cache-design.md
Standard: .claude/docs/caching-standard.md and .claude/rules/cache-code.md
Decision so far: {cache - user approved | No cache}
Evidence level: {measured: path | estimated: reasoning | none}
Budget: {perf-budgets row | none}   Acceptable staleness: {value from the user}
Events that change the data: {list}   Data scope: {per-tenant | per-user | global}
Tenancy: {tenancy.model | unset}   Editions: {hosted | self-hosted | hybrid}
Engines the entry must run on (the engines in scope, `2-portability.md` section 0): {hosted engine: Redis 8.2 | Dragonfly | both until decided} when Editions is hosted or hybrid; Valkey 9.1 when Editions is self-hosted or hybrid
Existing key builder / instance / precedent: {paths | none}
Inputs (read each): {paths with FOUND/ABSENT}

Fill every field of Section 2 (What, Why, Pattern, Key schema, Value format,
TTL, Invalidation, Stampede protection, Failure mode, Expected hit ratio, Tenant
isolation, Sensitivity, Instance & memory, Access pattern, HTTP/client caching,
Self-hosted) and Section 3 for any rate limit, lock, session, idempotency key or
queue the feature needs. Rules: every key has a TTL with jitter; key schema
{env}:{service}:{entity}:v{schema}:{tenant_id}:{id}; invalidate on write with the
TTL as backstop; no cross-tenant aggregate under a shared key; no secret, OTP in
clear or full PII; cache down -> read the source, emit a metric, do not fail the
request; multi-key reads by MGET or pipeline; no KEYS and no unbounded
SMEMBERS/HGETALL. Use only commands in the common subset (read
docs/stack-reference/redis/best-practices.md section 10 and the "Redis-only"
table in docs/stack-reference/redis/deprecated-apis.md). Do not write an
engine-specific setting or behaviour from memory: write NOT SOURCEABLE and what
you searched.
Return also: the commands each operation uses; the scripts (declared KEYS only);
the metrics to emit; what you could not verify.
```

## 6. Review the draft

Compare each field with `caching-standard.md`:

- **What / Why:** specific, with evidence level and file path, not "hot data".
- **Key schema:** contains `{env}`, service, entity, `v{n}` and the **tenant ID**.
  `{...}` in the standard's example are placeholders; a literal `{...}` in a key
  is a *hash tag* (co-location in cluster mode), used only where a multi-key
  command or script needs one slot, and the entry says so.
- **TTL:** a number with jitter (the standard says +/- 10 %), no eternal key.
- **Invalidation:** every writer listed; delete on write, not update on write.
- **Stampede:** named mechanism; a lock uses `SET ... NX PX` with a token-checked
  release (a script with declared keys; `DELEX` is Redis-only).
- **Failure mode:** cache down never fails the request.
- **Sensitivity:** what is excluded, and for authorization data the invalidation
  on role change and the staleness accepted.
- **Instance:** cache and durable-ish data (sessions, idempotency, rate limits) on
  separate instances; `maxmemory` set; eviction per engine (Phase 3).

Return gaps to the agent once before filling them yourself.
