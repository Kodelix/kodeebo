# /cache-design - Phase 4: Tests, Verdict, Write

> Phase 4 of `SKILL.md`. A check that did not run is `not run - reason`, never
> passed.

## 1. The test list (testing-standards.md "Every cache adapter")

Record these in Section 5 of the record, each with the layer's test location
(`.claude/docs/directory-structure.md` "Code roots") and the naming convention
(`testing-standards.md` "Naming"). Integration tests use Testcontainers with the
real engine, never a mocked client.

| Test | Proves |
|---|---|
| Hit | a cached value is returned without touching the source |
| Miss | the source is loaded and the cache populated, with a TTL |
| Invalidation on write | after each writer in the entry's list runs, the next read is fresh |
| TTL expiry | the key expires; jitter keeps TTLs within +/- the stated spread (assert the range, not a random value: inject the random source) |
| **Cache down -> still correct** | with the engine stopped or unreachable, reads return the source's data, writes still succeed, a metric increments, the request does not fail |
| Tenant isolation | tenant A cannot read tenant B's entry; no cross-tenant aggregate under a shared key |
| Stampede | concurrent misses cause one source load |
| Schema bump | a `v` change does not read an old-shaped value |
| Large or oversized value | a value over the size smell (100 KB) is rejected or projected, per the entry |
| Script (if any) | runs on every engine; undeclared key access fails closed |
| **Engine run** | the suite passes on every engine in scope: the hosted engine (Redis 8.2 or Dragonfly) and Valkey when the product is self-hosted or hybrid (Phase 3 sections 0 and 4) |

Add per entry: authorization-data entries test invalidation on role change; rate
limit entries test atomicity under concurrency and window rollover; idempotency
entries test replay and key reuse with a different body.

These are a **plan**. This skill ran none of them; the report says `tests: planned,
not run`. A runnable command is the stack lead's to define in the story.

## 2. Review checklist (template Section 6)

Mark each; an unmet item is listed with an owner:

- [ ] Every key has a TTL with jitter; no eternal key (or an ADR)
- [ ] Invalidate on write; TTL as backstop; no race-written stale values
- [ ] Bounded size; separate instance/database from durable-ish data
- [ ] Failure of the cache never fails the request
- [ ] The decision is recorded (here, and in the spec NFR)
- [ ] The tenant ID is in every key; no secret, OTP in clear, or full PII
- [ ] Observability: hit/miss counters, latency histogram, errors per adapter,
      evictions per instance; an alert below the expected hit ratio with a runbook
      (`/observability-plan`); metric labels exclude tenant and user IDs
      (`observability-standard.md` cardinality budget)

## 3. Verdict (first match wins)

| Verdict | When |
|---|---|
| `BLOCKED` | a key without the tenant; a key without a TTL and no ADR; a secret, OTP in clear or full PII cached; a failure mode that fails the request; an engine-specific item in shared code with no ADR; a declined write (`BLOCKED — write declined by user`); cache and durable data on one instance under a `volatile-*` policy |
| `NOT ASSESSED` | evidence level `none` for the worth-it claim; the portability check could not be performed for an in-scope engine (reference unreadable, commands never listed, engines in scope unknown); the draft was not returned |
| `COMPLETE WITH GAPS` | evidence is `estimated`; non-blocking checklist items open with owners; `performance-engineer` concerns; a `NOT SOURCEABLE` portability cell for an in-scope engine, named `verify with /research` with an owner (Valkey cells are expected); `Valkey CI run: not verified` |
| `COMPLETE` | measured evidence (or a justified "no cache" with numbers), all checklist items met, portability grounded for every engine in scope (no `verify with /research` gap left), tests planned including cache-down and the engine run for each in-scope engine |

`NOT ASSESSED` ranks above `COMPLETE` and below `BLOCKED`. A "No cache" decision
with the numbers that justify it is `COMPLETE`; a "No cache" with no numbers is
`COMPLETE WITH GAPS`.

## 4. Review by performance-engineer (`full` review mode)

Spawn `performance-engineer` with: the record, the budget row, the evidence
paths. Ask it to check the "worth it" claim, the expected hit ratio and TTL
against the access pattern, and the instance memory estimate (keys x size
against `maxmemory`). Its output is findings to add to the record, with owners.
`lean` / `solo`: record `performance-engineer review skipped - [mode] mode`.

## 5. Ask and write

Present the draft record, the portability table and the verdict. Then ask: "May I
write the cache design to `docs/architecture/cache-designs/<feature>.md`?" Write
only after approval, from `.claude/docs/templates/cache-design.md` with its
section headings unchanged (an update keeps existing entries and adds or
changes the named one; show the changed fields first). Verify the file exists
before reporting it written. Give the user the one-line summary for the spec's
NFR "Caching Decision", for example `Cache: tenant entitlements, cache-aside, TTL
10 min +/- 10%, delete on PlanChanged, design: docs/architecture/cache-designs/<feature>.md`.
This skill does not edit the spec.

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/cache-design <feature> —
<verdict>`, Next step = the first Recommended Next Step in `SKILL.md` that
applies (the spec NFR line then `/create-stories` for the adapter; for `BLOCKED`
/ `NOT ASSESSED` the step that clears the cause), plus Blocked on / Files in
progress / Open questions; append the Notes line. Still updated when the user
declines the write (record nothing written and why).

## 6. Report

```text
Cache design: <feature>   Verdict: COMPLETE | COMPLETE WITH GAPS | NOT ASSESSED | BLOCKED
Entries: N (cache N, no cache N)   Designed by: cache-specialist | this session (reason)
Evidence: <entry: measured|estimated|none; path>
Portability: Redis 8.2 <...>  Dragonfly <...>  Valkey <...>   NOT SOURCEABLE: <list> -> /research
Redis-only/engine-specific items: <none | list with ADR status>
Tests planned: N (cache-down: yes; engine run: yes/no per in-scope engine)   Run by this skill: none
performance-engineer: reviewed | skipped - <mode> mode
Checklist: met N / open N (owners)
NOT ASSESSED / BLOCKED causes: <each, with what closes it>
Written: <path | not written>
Spec NFR line: <one-line summary>
```
