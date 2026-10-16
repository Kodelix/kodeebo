# /cache-design - `check <feature|path>`

> Review an **implemented** cache adapter against its decision record and
> `.claude/rules/cache-code.md`. Read-only: it reports, it does not fix. It is a
> review by reading and `Grep`, not a linter, and says so.

## 1. Locate

- Feature given: read `docs/architecture/cache-designs/<feature>.md`. Absent =
  `NOT ASSESSED - no decision record` (the gate-5 evidence is missing; route to
  `/cache-design <feature>`), but the code checks below still run.
- Code: the adapter paths from `.claude/rules/cache-code.md`
  (`**/adapters/redis/**`, `**/adapters/cache/**`, `**/adapters/dragonfly/**`,
  `**/*cache*.go`, `**/*Cache*.kt`) under each code root from
  `bash .claude/hooks/yaml-helper.sh resolve_code_root`. **An empty result means
  the check did not run**: report `NOT ASSESSED - no source under <root>`, never
  "clean".

## 2. Checks (cite `file:line`)

| # | Check | Method |
|---|---|---|
| H1 | Adapters are decorators around a repository port; use cases do not import a cache | read imports in the use-case package |
| H2 | One key-builder function per context; no key built by concatenation elsewhere | `Grep` string literals containing the key prefix pattern; compare with the builder |
| H3 | The key matches the record's schema and contains the tenant ID and `v{n}` | read builder vs record |
| H4 | Every write sets a TTL with jitter; no eternal key | `Grep` set calls; read each |
| H5 | Cache error -> log once, metric, fall through to the source; a cache error never fails the request | read error handling at each call |
| H6 | Stampede protection present as recorded | read |
| H7 | Forbidden commands absent: `KEYS`, `FLUSHALL`, `FLUSHDB`, unbounded `SMEMBERS` / `HGETALL` / `LRANGE 0 -1` | `Grep` (report matches with `file:line`; zero matches in files scanned is not proof about code the grep could not see - name what was scanned) |
| H8 | Redis-only commands absent from shared code: `DELEX`, `DIGEST`, `MSETEX`, `INCREX`, `HOTKEYS`, `BACKUP`, `XADD ... IDMP`, `SET ... IFEQ`, `FT.`, `TS.`, `JSON.`, `FUNCTION`/`FCALL` | `Grep` (list from `docs/stack-reference/redis/deprecated-apis.md`; re-read it, it may have grown) |
| H9 | Deprecated commands absent (`GETSET`, `RPOPLPUSH`, `BRPOPLPUSH`, `HMSET`, `ZRANGEBYSCORE`, `GEORADIUS*`, `SLAVEOF`) | `Grep`, same note |
| H10 | Multi-key reads use `MGET` / pipeline, not a loop of round trips | read loops around cache calls |
| H11 | Scripts declare every key in `KEYS`, no engine flags, locals only; short | read each script |
| H12 | No secret, raw OTP or full PII record stored | read values written |
| H13 | Hit/miss/latency/error metrics emitted per cache; no tenant or user ID as a metric label | read instrumentation |
| H14 | The tests of `3-tests-and-record.md` exist, including cache-down and tenant isolation; run on which engines | `Glob`/`Grep` test files; **existence only - this skill does not run them** |

Report each `met` / `not met` / `not assessed` with `file:line`. Verdict
precedence as in `SKILL.md`: a `not met` on H3, H4, H5, H8, H12 = `BLOCKED`; test
files missing or not run = `NOT ASSESSED` for H14. Ask before writing any
report file (`production/qa/cache-check-<feature>-<date>.md`); otherwise the
report is conversation-only, and says so.

**Checkpoint.** When a report file was written, or the verdict is `BLOCKED` /
`NOT ASSESSED`, update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/cache-design check
<feature> — <verdict>`, Next step = the fix for the first `not met` check (or
`/code-review` when clean), plus Blocked on / Files in progress / Open questions;
append the Notes line. A conversation-only report that changed nothing may skip it.
