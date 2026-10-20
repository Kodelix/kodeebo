# /cache-design - Phase 3: Portability

> Hosted may run **Redis 8.2** (`redis:8.2`, Extended support to 2030-09-01) or
> **Dragonfly** (`v2.0.2`); the customer bundle runs **Valkey 9.1.x**
> (`valkey/valkey:9.1.2`, BSD-3). Dragonfly is hosted-only and Redis >= 7.4 never
> ships in a bundle (`.claude/docs/standing-decisions.md` L1-L2; `.claude/rules/deploy.md`). Pins:
> `docs/stack-reference/pins.yaml`. Everything below is checked against the stack
> reference; nothing is recalled.

## 0. Engines in scope (decides what must be grounded)

Portability is assessed for the engines this product actually runs, from
`distribution.model` and `deploy/hosted/` / `deploy/self-hosted/`:

| `distribution.model` | In scope |
|---|---|
| `hosted` | the hosted engine only (Redis 8.2 or Dragonfly, whichever `deploy/hosted/` uses; both while undecided) |
| `self-hosted` | Valkey only (the customer-bundle engine) |
| `hybrid` | the hosted engine **and** Valkey |
| unset / unreadable | all three, and the unset value is a named gap |

An engine out of scope is written `not in scope - <distribution.model>` in the
table below, not `NOT SOURCEABLE`, and never blocks the verdict.

## 1. What to read

| Source | Use |
|---|---|
| `docs/stack-reference/redis/best-practices.md` section 10 | portable-code rules: Lua, Functions, cluster, unsupported commands, modules, test rule |
| `docs/stack-reference/redis/deprecated-apis.md` ("Redis-only commands and options" and the deprecated table) | commands never to use in shared code |
| `docs/stack-reference/dragonfly/best-practices.md` sections 2, 5, 7, 10 | eviction flags, scripts, ACL/network, differences |
| `docs/stack-reference/dragonfly/breaking-changes.md` | v2.0.0 behaviour changes the code must not depend on |
| `docs/stack-reference/redis/VERSION.md` "Valkey" | what is sourced about Valkey (versions, licence, 9.0 notes) |

## 2. The checks, per entry

For each entry list every command, script, option and configuration it uses, then
fill this table. Status: `portable` (stack reference supports it on the engine),
`engine-specific` (needs an ADR), `NOT SOURCEABLE` (the reference does not cover
it for that engine).

| Item | Redis 8.2 | Dragonfly 2.0.2 | Valkey 9.1 |
|---|---|---|---|
| Each command used (`SET ... EX/PX/NX`, `GET`, `MGET`, `DEL`, `INCR`, `EXPIRE`, ...) | read command pages as cited in the reference | the reference says `COMMAND INFO <name>` on the running version is the check; command-by-command coverage is **not** in the reference | **NOT SOURCEABLE** except the statement that Redis 8-only features are absent (`redis/VERSION.md`) |
| Redis-only commands / options (`DELEX`, `DIGEST`, `MSETEX`, `INCREX`, `HOTKEYS`, `BACKUP*`, `XADD ... IDMP`, `SET ... IFEQ`, `LMOVEM`, `*-lrm` eviction, `FT.*`, `TS.*`, `JSON.*`, modules) | available | treat as absent | absent |
| Deprecated Redis commands (`GETSET`, `RPOPLPUSH`, `HMSET`, `ZRANGEBYSCORE`, `SLAVEOF`, ...) | works, deprecated | n/a | n/a - use the replacement in the reference |
| Lua scripts (`EVAL`) | Lua 5.1; keys only via `KEYS`; no globals | Lua 5.4; undeclared keys fail; do not enable `allow-undeclared-keys` | Lua version and sandbox: **NOT SOURCEABLE** |
| Functions (`FUNCTION LOAD`, `FCALL`) | exists | not supported (maintainer statement, re-verify) | **NOT SOURCEABLE** - do not use; **EVAL only** |
| Script flags (`#!lua flags=...`, `--!df flags=`) | engine-specific | engine-specific | engine-specific: **no flags in shared scripts** |
| Hash tags / multi-key atomicity | hash tags co-locate slots | "follow the Valkey Cluster spec" - verify co-location with a test | the spec Dragonfly follows; behaviour on Valkey **NOT SOURCEABLE** here |
| Eviction | `maxmemory` + `maxmemory-policy` (`allkeys-lru` for a cache-only instance; do not mix cache and durable data under a `volatile-*` policy) | no `maxmemory-policy`; `--maxmemory` explicit, `--cache_mode=true` for a cache-only instance; which keys are chosen is **NOT SOURCEABLE** | **NOT SOURCEABLE** in the reference |
| Persistence | cache instance: none; durable instance: RDB and/or AOF | `--snapshot_cron`, `dir`; no auto-pruning of snapshots | **NOT SOURCEABLE** |
| ACL and network | named user per service, `-@dangerous` (it also removes `INFO` and `CLIENT`; give the monitoring user `+info` / `+client\|list`), `-flushall -flushdb -swapdb`; bind and do not publish 6379 | default user open; set `--bind` and a password; admin port off the network; `--rename_command` retired, use ACL | **NOT SOURCEABLE** |
| TTL edge cases | `SET` options, `KEEPTTL` | v2.0.0: past-expiry `SET` honours `NX/XX/GET` (do not use it to delete); `EXPIRE` with several flags needs all to hold (one flag per call) | **NOT SOURCEABLE** |
| Telemetry / licence | licence choice RSALv2/SSPLv1/AGPLv3 | BSL 1.1, hosted only; v2.0.2 daily version check (can it be disabled: **NOT SOURCEABLE**) | BSD-3; support/EOL policy **NOT SOURCEABLE** |

Cite the file and section for every `portable` cell. A cell you cannot ground in
the reference is `NOT SOURCEABLE`. **Valkey is the engine customers run and the
reference documents little of it**: expect several `NOT SOURCEABLE` cells and
report them, do not fill them.

**A thin reference is a named gap, not a permanent `NOT ASSESSED`.** Portability is
*grounded* for an in-scope engine when every command, script and option the entry uses
is `portable` there, or sits inside the common subset the reference grounds on another
engine and the cell's remaining uncertainty is written as a gap. For each
`NOT SOURCEABLE` cell of an in-scope engine write one line in the record:
`<item> on <engine>: not in the stack reference - verify with /research` (owner,
and the story that cannot be Ready before it closes when the entry's correctness
depends on it, e.g. a script's semantics or eviction behaviour). That makes the
portability result `COMPLETE WITH GAPS`. It is `NOT ASSESSED` only when the check
could not be performed at all for an in-scope engine: the stack-reference files for it
are unreadable, the entry's commands were never listed, or the engines in scope cannot
be determined.

## 3. Rules the design applies

- Code targets the **common command subset**; an engine-specific command, script
  flag or module needs an ADR and a note in the cache adapter (`caching-standard.md`).
- **Scripts:** `EVAL` only; every key is declared in `KEYS`, values and window
  sizes in `ARGV`, key names never built inside the script; no engine flags in a
  shared script; every variable `local`; a short script, tested on every engine.
  The portable rate limiter is the single-key `INCR` + `EXPIRE` script in
  `docs/stack-reference/redis/best-practices.md` section 5.
- **Locks:** `SET lock:<name> <token> NX PX <ms>`; release with a token-checked
  script (not `DELEX`, not plain `DEL`); a single-instance lock is not safe under
  failover, so use a fencing token for work that can outlive the TTL, or prefer a
  database constraint (`caching-standard.md`).
- **Cache and durable data are separate instances** (or logical databases with an
  ADR); sessions and idempotency records need persistence and a no-eviction
  posture, the cache instance does not.
- **Config differences stay out of shared files:** `maxmemory-policy`,
  `slowlog-*` and `latency-monitor-*` are Redis settings with no documented
  Dragonfly equivalent; per-engine configuration lives under `deploy/hosted/` and
  `deploy/self-hosted/` separately.
- **Startup check (design guidance in the stack reference):** the adapter checks
  `COMMAND INFO <name>` for each command it uses and fails fast with a clear
  message if one is missing.

## 4. The engine test run (the engines in scope)

`docs/stack-reference/redis/best-practices.md` section 10 "Test rule" and the
Dragonfly equivalent: run the same integration suite against **Redis 8.2 and
Dragonfly** in CI when the hosted engine is in scope (only the hosted engine actually used, once decided); a failing Dragonfly job blocks the shared code path.

**Gap to report every time Valkey is in scope:** neither document names a **Valkey** run, yet Valkey
is the engine in every customer bundle. The design adds it: the cache and rate-limit
integration suites also run against `valkey/valkey` at the `pins.yaml` tag.
Whether CI does today is unknown to this skill: record `Valkey CI run: not
verified` and route to `dev-tooling-engineer` and `test-automation-engineer` via
`principal-engineer`. The run is part of the design's test plan whenever Valkey is in scope
(section 0), so a design that plans it is not held back; "CI does not run Valkey today"
is a named gap with an owner (`COMPLETE WITH GAPS`), and the report keeps
`Valkey CI run: not verified` until someone shows it.

## 5. Result

```text
Portability: <entry>   Redis 8.2: portable | engine-specific | NOT SOURCEABLE (items)
Dragonfly: ...   Valkey: ...
Redis-only commands used: none | <list> (blocks: ADR required)
Scripts: <N>, KEYS declared: yes/no, flags: none
Engines in scope: <list>   Engine run planned: Redis yes/no/not in scope, Dragonfly yes/no/not in scope, Valkey yes/no/not in scope
NOT SOURCEABLE items sent to /research: <list>
```

Any `engine-specific` item without an ADR = `BLOCKED`. A `NOT SOURCEABLE` item for an
in-scope engine = a `verify with /research` gap (`COMPLETE WITH GAPS`), as section 2
says; the check not being performable for an in-scope engine = `NOT ASSESSED`.
