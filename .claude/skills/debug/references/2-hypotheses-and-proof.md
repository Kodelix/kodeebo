# /debug — Hypotheses, Bisect and Root-Cause Proof

> Part of `/debug`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its headings still apply here.

## 1. Ranked hypotheses

When the cause is not obvious keep **at least three** entries, ranked by prior
likelihood. Each names the check that would **confirm** it and the check that
would **kill** it, and records the outcome — so the next reader sees what was
ruled out and why.

```markdown
| # | Hypothesis | Likelihood | Confirm by | Kill by | Outcome |
|---|---|---|---|---|---|
| 1 | [cause stated as a mechanism, not a symptom] | high | [observable that must be present] | [observable that cannot coexist] | CONFIRMED / KILLED (evidence ref) / OPEN |
```

- A hypothesis is a **mechanism** ("the cache entry is written before the
  commit, so a rollback leaves a stale entry"), not a restatement of the symptom.
- Test the cheapest killing check first. **One change per experiment**; revert
  what did not help.
- Do not guess from the top frame of a stack trace — follow the causal chain to
  where the bad state was created.

## 2. Localise — bisect

Whenever "it worked in version X" is known, `debugger` (it holds the Bash grants this skill does not) bisects and records the good commit,
the bad commit, the test command passed to `git bisect run` (a script that reports good/bad
on the repro; its exit-code contract, including how to skip an unbuildable
commit, is read from `git bisect --help` on this host, not recalled), and the
first-bad commit. Bisect on a
**scratch worktree** (`git worktree add`) so the working tree and any uncommitted
work are untouched; remove the worktree afterwards. Other axes when there is no
good commit: by feature flag, by config, by data, by dependency version, by tenant.
Not applicable → "not applicable" with the reason.

## 3. Tools per layer — from the stack reference, not memory

Pick the tool for the layer under diagnosis and take its invocation from
`docs/stack-reference/<layer>/` and `docs/stack-reference/tooling/`:

| Layer | Tools to reach for |
|---|---|
| Go | `pprof` (CPU, heap, goroutine, mutex), `delve`, `-race`, execution traces |
| Ktor / JVM | JFR, `jstack`/thread dumps, heap-dump analysis, coroutine debug probes |
| Database | `EXPLAIN (ANALYZE, BUFFERS)`, `pg_stat_statements`, slow-query log |
| Cache | command stats, key inspection |
| Web | browser devtools, source maps, Playwright traces |
| Android | `adb logcat`, Layout Inspector, Perfetto/Profiler |
| iOS | Instruments, `lldb` (macOS host) |

A flag or option not in the stack reference or the tool's own help on this host
is `NOT SOURCEABLE` — ask for `/research`, do not recall it. A profiler capture
on a sustained slowness is `performance-engineer`'s area: hand over the
reproduction and stop at "which budget is missed".

## 4. Prove the root cause

State it as a **falsifiable sentence**: "X happens because Y when Z."

A proof has all three:

1. **The chain** — from the trigger to the bad state to the symptom, each link
   backed by a trace span, a log line with `trace_id`, a plan, or a test.
2. **The reproduction hits it** — a test or trace that fails because of Y and
   only when Z holds (vary Z; the failure follows).
3. **Removing the cause removes the symptom** — shown on a throwaway change in a
   scratch worktree (not kept), or by the regression test going green after the
   real fix.

If (3) cannot be shown yet, the conclusion is `LIKELY` with the evidence listed.
A fix that cannot be explained is a **workaround** and is labelled one.

## 5. Siblings and scope

- Grep the repository for the faulty pattern; list **every** other instance with
  `file:line` — fixed, or ticketed with an owner. Fixing one endpoint and
  stopping is the failure this step exists to prevent.
- Determine the impact scope: which tenants, which versions (hosted release or
  self-hosted number), which data, since when — and whether any **cross-tenant
  read or write** occurred (then `security-lead` is notified immediately).
- For a self-hosted report, say what the customer can and cannot send and what
  was inferred.

## 6. State what was not examined

Layers, tenants, versions, signals and environments not looked at, and the
confidence word for the conclusion: `PROVEN`, `LIKELY` (evidence listed), or
`UNKNOWN` (next probes listed), per the rules in `SKILL.md`.
