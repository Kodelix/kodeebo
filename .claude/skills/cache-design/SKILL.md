---
name: cache-design
description: "Cache decision record per caching-standard.md (what, why, pattern, key schema, TTL, invalidation, stampede, failure mode, hit ratio, tenant isolation), portable across Redis 8.2, Valkey 9.1 (customer bundles) and Dragonfly, with the test list including cache-down. Also `check` for an implemented adapter. 'No cache' is a valid decision."
argument-hint: "[feature-slug] [--entry <name>] | check <feature-or-path> [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Write, Edit, Agent, AskUserQuestion, Bash(date *), Bash(bash "*/.claude/skills/cache-design/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,automation_always_ask,testing.strict,performance.enforce,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt). A **decision to cache** and a
**decision not to** are both the user's.

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**`workflow`** does **not** relax this skill. DoD gate 5 applies at every tier:
a written cache decision, or a written reason for none (`workflow-modes.md`:
tiers scale documents, never engineering).

# Cache Design

A cache is a second copy of the truth that can be wrong. Every cache must say
how it stays correct, how it fails, and that it is worth it
(`.claude/docs/caching-standard.md`, DoD gate 5). This skill writes that
decision for one feature, one entry at a time, from
`.claude/docs/templates/cache-design.md`, and makes it **portable**: hosted may
run Redis 8.2 or Dragonfly, while the **customer bundle runs Valkey**
(`docs/ROADMAP.md` decisions L1-L2; `.claude/rules/deploy.md`). The code
therefore targets the common command subset, and the design is checked against
the engines in scope.

**"No cache" is a valid decision.** Fill only Section 1 of the template with the
reason (data changes per request; the source already meets the budget, with the
numbers). A cache added without evidence that it is worth it is the failure this
skill exists to prevent.

**Modes**
- **design** (default, `[feature-slug]`): produce or update the decision record.
- **`check <feature|path>`**: review an *implemented* cache adapter against its
  decision and `.claude/rules/cache-code.md` (`references/4-check-mode.md`).

**Output:** `docs/architecture/cache-designs/<feature>.md` (from the template),
and the one-line decision to record in the feature spec's Non-Functional
Requirements "Caching Decision" (this skill does not edit specs).

> **Verdicts:** `COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`.
> Precedence: `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH GAPS`, then
> `COMPLETE`. `BLOCKED`: a key without the tenant, a key with no TTL (and no
> ADR), a secret, OTP in clear or full PII cached, a failure mode that fails the
> request, a Redis-only command in shared code. `NOT ASSESSED`: nothing measured
> supports "worth it", the portability check could not be performed for an engine
> in scope, or the cache-down / portability tests have no plan. `COMPLETE WITH
> GAPS`: a portability cell the stack reference does not ground for an engine in
> scope (the hosted engine, plus Valkey when the product is self-hosted or hybrid)
> is named "verify with /research" with an owner; it is not a permanent
> `NOT ASSESSED`. A declined write is `BLOCKED — write declined by user`. Each
> cause is named.

---

## Phase 1: Inputs and the Decision to Cache

**Read `references/1-inputs-and-draft.md` now and follow it.** It parses the
argument, records every input as FOUND or ABSENT, establishes the **evidence
for "worth it"** (the source's measured p95 and the budget it must meet),
and decides, with the user, cache or no cache for each candidate entry. Read it
again if the conversation was compacted or resumed.

## Phase 2: Draft (cache-specialist)

For each entry decided "cache", spawn `cache-specialist` via `Agent` with the
fixed brief in `references/1-inputs-and-draft.md` ("Design brief"). Independent
entries run **in parallel in one message**. It returns the filled template
section as text; it writes nothing. If it cannot be spawned, say why, draft
here against the same references, and let the record's **Designed by** line say
so.

You review the draft against `caching-standard.md` field by field; a fluent
table is not evidence.

## Phase 3: Portability

**Read `references/2-portability.md` now and follow it.** Every command, script
and configuration the entry needs is checked, for the engines in scope (hosted
engine; Valkey 9.1 when self-hosted or hybrid), using only the stack reference.
What the reference does not cover for an engine is `NOT SOURCEABLE`, is named
"verify with /research" in the record and makes the portability result
`COMPLETE WITH GAPS`, never "portable".

## Phase 4: Tests, Verdict, Write

**Read `references/3-tests-and-record.md` now and follow it.** It fixes the
test list (hit, miss, invalidation on write, TTL expiry, **cache down**, tenant
isolation, stampede, schema bump, plus the engine run for every engine in scope), applies the review
checklist, derives the verdict, asks before writing and hands the stories to
`/create-stories`. In `full` review mode it also spawns `performance-engineer`
to review the "worth it" evidence against `perf-budgets.md` (an agent review,
not a director gate; `lean` and `solo` record `performance-engineer review
skipped - [mode] mode`).

---

## Error Recovery Protocol

**First, verify the artifact.** A `cache-specialist` told to return text must
return a filled template section, not a preamble. If any agent returns BLOCKED,
errors or cannot complete: surface it immediately, do not proceed past a
dependency it blocks, offer skip / retry narrower / stop via `AskUserQuestion`,
and always produce a partial report. A skip does not clear a block. Full
procedure: `.claude/docs/error-recovery-protocol.md`.

## Collaborative Protocol

- **Decision records follow the tier.** "An ADR" in this skill means an ADR (at
  `modes.workflow: minimal`, an entry in the brief's decision log, `design/product-brief.md`).
- **Question -> Options -> Decision -> Draft -> Approval.** Cache or no cache,
  the pattern, the TTL and the invalidation events are the user's.
- **Evidence before a cache.** "It will be faster" is a hypothesis; the record
  states what was measured, what was estimated, or that nothing was.
- **Never write a command's behaviour, a config key, an eviction setting or a
  version for an engine from memory.** Use `docs/stack-reference/redis/`,
  `dragonfly/` and the Valkey notes in `redis/VERSION.md`; the rest is `NOT
  SOURCEABLE` and goes to `/research`.
- **Stay in the common command subset.** Anything engine-specific needs an ADR
  and a note in the adapter (`caching-standard.md`); the skill reports it, it
  does not approve it.
- **Never cache secrets, OTP codes in clear or full PII records;** never cache an
  authorization decision longer than the permission-change latency the user
  accepts.
- **No application code is written here.** The adapter is a story for the stack
  lead via `data-lead`; this skill designs it and reviews it in `check` mode.
- **A check that did not run is reported as `not run`, never as passed.**
- A skipped, dismissed or empty answer is not an answer: act on nothing, ask
  again in plain text and wait.

---

## Recommended Next Steps

- Record the decision in the spec's NFR "Caching Decision" (paste the one-line summary from the report), then `/create-stories` for the adapter and its tests (Integration stories, Testcontainers; the cache-down test is mandatory)
- Adapter implemented: `/cache-design check <feature>` before `/code-review`
- Evidence missing for "worth it": `/perf-profile` on the source query or endpoint, then `/cache-design [feature]` again
- Hit-ratio, latency, error and eviction metrics and the alert: `/observability-plan plan [feature]`
- Tenant-keyed entries or authorization data cached: `/tenant-check [feature]`; sessions, OTP or rate-limit counters on the Redis protocol: `/threat-model [feature]`
- An engine item `NOT SOURCEABLE` (especially Valkey): `/research`; a Valkey run missing in CI: `dev-tooling-engineer` and `test-automation-engineer` via `principal-engineer`
- An engine-specific command or script: `/architecture-decision`
