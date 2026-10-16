# /create-stories — Step 4: Decompose the Spec into Stories

> Part of `/create-stories`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 4. Decompose the Spec into Stories

For each spec acceptance criterion:

1. Group related criteria that require the same core implementation **in the same code root**
2. Each group = one story
3. Order stories: **contract first**, then data/backend foundations, then backend behaviour, then clients (web, mobile), edge cases and hardening last, UI last

**Story sizing rule:** size each story to the resolved `modes.story_granularity`
target. The "~2-4 hours / one focused session" heuristic is the
`balanced` target (`rigor: standard`) — at `coarse`, the default, a story spans a whole feature slice (5–10 ACs,
multi-day), at `fine` a story is a single AC. Split or group criteria to hit the
resolved target, not a fixed session length.

### 4a. Contract-first ordering (hard rule)

For every boundary in the epic that a client (web, Android, iOS, KMP, public API
consumer) or another context calls:

1. Check `contracts/` (loaded in Step 2). If the contract already contains the endpoints/events and no change is needed, record `Contract: existing — contracts/openapi/<service>.yaml, unchanged` and write no Contract story.
2. Otherwise write **one Contract story first** in the epic: author/update the OpenAPI (or proto) file, error model (RFC 9457 `code`s), pagination, idempotency, versioning, run breaking-change detection, generate client SDKs, add consumer contract tests. Owner `api-designer`. Number it before every backend and client story for that boundary.
3. **Every backend story for the boundary has `Depends on: <contract story>`**, and every client story (web/Android/iOS/KMP) has `Depends on: <contract story>`. A client story's run-and-observe additionally needs the backend story DONE — say so in Dependencies; the client can be built against generated mocks before then.
4. No backend or client story may define or change the HTTP shape. If implementation reveals a contract change, it goes back through a Contract story, not into the backend story.

A boundary with no contract and no Contract story is a decomposition error; stop and say so.

### 4b. Layer splitting and owner agent

- One story = one code root (`backend/`, `web/`, `mobile/shared`, `mobile/android`, `mobile/ios`, `contracts/`, `deploy/`). A feature that spans roots yields a story per root, ordered contract → data/backend → clients.
- Record the **owner agent** from the Step 3 table, resolving `go-lead` vs `ktor-lead` from `stack.backend` (a `go+ktor` product uses the lead of the service the story's code root belongs to; if that is ambiguous, ask — never guess).
- A schema change is its own Integration story owned with `data-lead` (`migration-specialist`), ordered before the backend stories that use it. Migrations are forward-only in production and reversible in development; a migration touching a hot table states its lock plan in the story.
- A story on `deploy/self-hosted/` states the licence rules that bind it (`.claude/rules/deploy.md`) in Implementation Notes.

### 4c. Acceptance criteria: sourced, with negative and cross-tenant cases

Acceptance criteria are copied from the spec's Acceptance Criteria (and Edge Cases & Failure Modes). Where the story
touches tenant data, an endpoint, a provider or a sensitive area, the studio standards
make further criteria mandatory. Add them, each labelled with its source so they are
not read as invented:

| Condition | Mandatory criterion | Label |
|---|---|---|
| Story reads or writes tenant data | A resource owned by another tenant returns 404 (never 403) and leaks no data; repository test shows tenant A's rows invisible to tenant B | `[standard: security-baseline.md / api-standards.md]` |
| Story adds or changes an endpoint | Anonymous → 401, wrong role → 403, with a test per case; response matches `contracts/` | `[standard: testing-standards.md]` |
| Story writes that a client or webhook can repeat | A repeated request with the same idempotency key does not duplicate the effect | `[standard: api-standards.md]` |
| Story calls an external provider | Provider 5xx/timeout retried per policy and breaker behaviour; duplicate webhook is idempotent; invalid signature rejected | `[standard: testing-standards.md]` |
| Story adds a cache | Hit, miss, invalidation on write, TTL, behaviour when the cache is down, tenant ID in key | `[standard: caching-standard.md]` |
| Story is Security type | Injection/rate-limit/replay cases as applicable, with ASVS or MASVS requirement IDs looked up in the official documents (never from memory) | `[standard: security-baseline.md]` |
| Story adds a list/search endpoint | Cursor pagination with server-capped limit; no N+1 (query-count assertion) | `[standard: performance-standard.md]` |
| Story is UI | Every state (loading, empty, error, over-quota) and Arabic/RTL + English; accessibility target from `accessibility.target` | `[standard: run-and-observe.md]` |

Spec-sourced criteria keep their spec wording and are not relabelled. If a mandatory
criterion cannot be made concrete from the spec (for example the spec names no role
model), do not invent it: write the criterion as `OPEN — spec does not say [what]`, list it in the
Step 5 presentation, and let QL-STORY-READY and the user resolve it.

### 4d. Per-story traceability, ADR and evidence determination

For each story, determine:
- **Spec requirement**: which acceptance criterion(ia) does this satisfy?
- **TR-ID**: look up in `tr-registry.yaml`. Use the stable ID. If no match, use `TR-[feature]-???` and warn.
- **Governing ADR**: which ADR governs how to implement this?
  - `Status: Accepted` → embed normally
  - `Status: Proposed` → set story `Status: Blocked` with note: "BLOCKED: ADR-NNNN is Proposed — accept it with `/architecture-decision accept ADR-NNNN` once decided"
  - `Deprecated` or `Superseded by ADR-XXXX` → set story `Status: Blocked` with note: "BLOCKED: ADR-NNNN is [status] — point the story at [successor] (edit its ADR field — `/create-stories` never rewrites an existing story) before implementing"
  - **Multiple ADRs apply**: List all governing ADRs in the story's `Governing ADRs:` field. Designate the one most directly controlling the implementation pattern as primary (first in the list). Others are listed as secondary references.
  - **No ADR applies at all**: Write `ADR: N/A — [brief reason, e.g. "pure configuration, no architectural pattern required"]` in the story's ADR field. Do NOT leave the field blank — a blank ADR field means "not checked", not "not applicable".
- **Story Type** and **owner agent**: from Step 3
- **Stack risk**: from the ADR's Knowledge Risk field, else from `docs/stack-reference/<layer>/VERSION.md`; `NOT ASSESSED (no stack-reference risk rating)` when neither assigns one
- **Research note**: `docs/research/<feature>.md` present or MISSING (gate 1). MISSING is recorded, shown in Step 5, and left for `/story-readiness` to return NEEDS WORK — never invented or substituted
- **Threat model** (Security type, or any story in an auth, billing, licensing, upload, webhook, PII, admin or new-integration area): `docs/architecture/threat-models/<feature>.md` present or MISSING. MISSING is shown in Step 5; a Security story with a missing threat model carries a Dependencies line "Needs `/threat-model <feature>` before it enters a sprint"
- **Definition of Done evidence** (the eight gates): decide each row of the story's DoD table now (Step 6 format) — research link, architecture layer/port notes, tests by type, spans/metrics/logs to emit, the cache decision or a "no cache" reason (if the spec/research note has none, write `OPEN — decide in the research note`), the perf budget row from `perf-budgets.md` (or `budget not yet set`), ASVS/MASVS refs (or `n/a — [reason]`), ADR needed by the story itself (gate 8)

### 4e. Requirements left over

After decomposition, every TR-ID in the epic's Spec Requirements table is covered by at least one story, or is
listed in the Step 5 presentation under "Dropped / not decomposed" with the reason. A requirement is never dropped silently.

---
