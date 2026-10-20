---
name: create-control-manifest
description: "Flat must/never rules per layer (backend, web, mobile, data, contracts, deploy) and per bounded context, extracted from Accepted ADRs and the standards. ADRs explain why; this is actionable."
argument-hint: "[update — regenerate from current ADRs] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(date *), Bash(bash "*/.claude/skills/create-control-manifest/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,stack`

Resolved above — use as-is; `--review` overrides `review_mode` for this run. No
block → defaults in `.claude/docs/config-resolution.md`.

# Create Control Manifest

The Control Manifest is a flat, actionable rules sheet for engineers and stack
leads. It answers "what do I do?" and "what must I never do?" — organized by
technical layer (backend, web, mobile, data, contracts, deploy) and by bounded
context, extracted from all Accepted ADRs, the studio standards, and the
stack-reference deprecation lists. Where ADRs explain *why*, the manifest tells
you *what*.

**Output:** `docs/architecture/control-manifest.md`

**When to run:** After `/architecture-review` passes and ADRs are in Accepted
status. Re-run whenever new ADRs are accepted or existing ADRs are revised, and
after any pin change in `docs/stack-reference/pins.yaml`.

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` / `standard` — requires Accepted ADRs (at `standard`, the critical ones). No ADRs → stop.
- `minimal` — ADR files are not required; rules come from the standards and the
  decision log in `design/product-brief.md`. Say in the manifest header that it
  is built from standards and the decision log, with no ADRs.

## 1. Load All Inputs

### ADRs
**Establish the denominator first.** Glob `docs/architecture/adr-*.md`. Call the
count **N**. If N is 0 and `workflow` is not `minimal`: "No ADRs found — run
`/architecture-decision` before building a control manifest." Stop with `Verdict: BLOCKED — no ADRs` (prerequisite missing).

**Resolve status without reading the ADRs** — the filter must precede the read,
not follow it:
```
Grep pattern="^## Status" glob="docs/architecture/adr-*.md" output_mode="content" -A 3
```
Interpret against N:

| Result | Meaning | Action |
|---|---|---|
| **N matches, some read `Accepted`** | Normal. | The Accepted set is **A**; proceed with A. Name every ADR left out, with its status, in the Phase 4 preview — the user approves a manifest knowing what it does not cover. |
| **N matches, none `Accepted`** | Genuinely no Accepted ADRs. | "[N] ADRs found, none Accepted. A manifest built from Proposed ADRs would encode decisions that may still change." Ask whether to proceed with Proposed (every such rule marked `PROPOSED — may change`) or stop (`Verdict: BLOCKED — no Accepted ADRs`). **Do not silently emit an empty manifest.** |
| **0 matches, N > 0** | **Malformed ADRs — not an empty Accepted set.** `## Status` is BLOCKING-if-missing. | "[N] ADRs found, none has a `## Status` section — acceptance cannot be determined. Run `/architecture-decision retrofit [file]` on each." **Stop** with `Verdict: NOT ASSESSED — ADR status unreadable`. Do not treat all ADRs as Accepted; do not emit a manifest. |

- Note the ADR number and title for every rule sourced.

### Context and project config
- `design/specs/domain-map.md` — the bounded contexts, to organise the per-context section. Absent → per-context section is reported `NOT ASSESSED — no domain map`; do not invent contexts.
- `project.yaml`: `stack`, `tenancy.model`, `deploy.target`, `distribution.model`, `core.*`, `layout.code_roots`, `performance.enforce`, `accessibility.target`.

### Standards (rule sources)
Read in full, once: `.claude/docs/clean-architecture.md`, `.claude/docs/api-standards.md`,
`.claude/docs/security-baseline.md`, `.claude/docs/caching-standard.md`,
`.claude/docs/observability-standard.md`, `.claude/docs/performance-standard.md`,
`.claude/docs/testing-standards.md`, `.claude/docs/coding-standards.md`, and — when
`distribution.model` is `hybrid` or `self-hosted` — `.claude/rules/deploy.md`.
Do not read `.claude/rules/*` files for layers the stack does not use.

### Stack reference
For each configured layer: `docs/stack-reference/<layer>/VERSION.md` (version),
`deprecated-apis.md` (these become forbidden entries) and `best-practices.md`
(required entries). A configured layer with no reference directory is
`NOT SOURCEABLE — <layer> is not covered by docs/stack-reference/`: its section of
the manifest carries that line instead of rules, and the Verdict line says so.

### Existing Artifacts
- Glob `docs/architecture/control-manifest.md` (present → this run is a
  regeneration; Read it before the Phase 5 write, which overwrites it) and
  `production/epics/*/EPIC.md` (present → epics exist). Phase 6 picks its next
  step from both.

Report: "Loaded [A] Accepted ADRs of [N], stack: [layers + pinned versions]."

---

## 2. Extract Rules from Each ADR

Read **only these four sections** per Accepted ADR — not the whole file. Context,
Consequences, Migration Plan and Validation Criteria explain *why* a decision was
made; the manifest records *what to do*, so they are not needed here:
```
Grep pattern="^## (Decision|Alternatives Considered|Performance Implications|Stack Compatibility)" glob="docs/architecture/adr-*.md" output_mode="content" -A 30
```
Also scan `Cross-Cutting Impact` for tenancy/self-hosted rules:
```
Grep pattern="^## Cross-Cutting Impact" glob="docs/architecture/adr-*.md" output_mode="content" -A 12
```
Filter the results to the Accepted set **A** resolved above. If a section is
absent for a given ADR, note it per ADR and continue; if a section is absent
across **all** of A, report "No Accepted ADR contains a `[section]` section — the
manifest's [category] rules will be empty. Verify this is intended." Escalate to
a full read of one ADR only when its scanned sections cross-reference material
outside them (e.g. a Decision that says "subject to the constraints in Context").

For each Accepted ADR, extract:

### Required Patterns (from the `## Decision` section)
- Every "must", "should", "required to", "always" statement in the Decision body
  — including the `### Implementation Guidelines` sub-heading when the ADR has one
  (the template emits it; older ones state mandates directly in `## Decision`).
  Never scan for `### Implementation Guidelines` alone — it is absent from many
  ADRs, and scanning for it yields an empty Required Patterns section on a
  manifest that should have been full.
- Every specific pattern or approach mandated

### Forbidden Approaches (from "Alternatives Considered" sections)
- Every alternative that was explicitly rejected — *why* it was rejected becomes
  the rule ("never use X because Y")
- Any anti-patterns explicitly called out

### Performance Guardrails (from "Performance Implications" section)
- Budget constraints: "p95 ≤ N ms for this endpoint", "≤ N queries per request"
- Memory and payload limits: "this service must stay under N MB RSS"

### Stack API Constraints (from "Stack Compatibility" section)
- Post-cutoff APIs that require verification
- Verified behaviours that differ from default model assumptions
- Behaviours that differ in the pinned version

### Classification
Tag each rule twice:
- **Technical layer**: Backend (Go/Ktor) · Web · Mobile (Android/iOS/KMP) · Data (Postgres/Mongo/cache) · Contracts · Deploy (hosted / self-hosted). A rule governing several layers is duplicated into each.
- **Bounded context**: the context the ADR's Spec Requirements table names, or `All contexts` for a Foundation decision (tenancy, identity, API style, deployment).

If an ADR's layer or context cannot be determined, list the rule under
`Unclassified` and name it in the preview — do not guess a layer.

---

## 3. Add Global Rules

Combine rules that apply to all layers. Each carries its source into the manifest, as a layer rule does — the ADR, the standard file, or the stack-reference file:

### From the standards (each rule cites the file and section)
- **Architecture**: dependencies point inward; domain imports no framework/DB/HTTP; ports declared by the consumer; one composition root; no context reads another's tables (`clean-architecture.md`)
- **API**: contract-first in `contracts/`; RFC 9457 errors; cursor pagination; `Idempotency-Key` on creating/charging POST; 404 for cross-tenant (`api-standards.md`)
- **Security**: deny by default; object-level authz in the use case; tenant scoping in every query plus RLS (or the model for `tenancy.model`); parameterised queries only; no secrets in code/logs/URLs; threat model for sensitive features; ASVS/MASVS mapping per story (`security-baseline.md`)
- **Observability**: span, RED metrics, structured logs with `trace_id` on every endpoint and job; no PII in telemetry (`observability-standard.md`)
- **Caching**: a written cache decision or a "no cache" reason; tenant ID in every key; TTL + jitter (`caching-standard.md`)
- **Performance**: budgets in `docs/architecture/perf-budgets.md`; no N+1 (`performance-standard.md`)
- **Testing**: Testcontainers for integration, deterministic tests, no skipped failing tests (`testing-standards.md`)
- **Code**: no hardcoded business values; DI over singletons; errors as values; timeouts, retries (idempotent only) and breakers on external calls; migrations forward-only in production (`coding-standards.md`)
- **Shared core**: capabilities come from `saas-core` modules at the pinned `core.version`; never re-implemented in the product; never edited in place (`core.modules`, if used)

Only include a standard's rules for layers the stack actually has.

### From the stack reference
- `deprecated-apis.md` entries → Forbidden entries, **filtered for relevance to this
  product**. Do not copy a deprecation table wholesale.
  > Each entry must apply to what this product actually builds. A deprecation list
  > mixes subsystems: an entry about a mobile-only API emitted unqualified gives a
  > backend-only product a global rule about code it never writes. If you cannot
  > tell whether an entry applies — a layer or module the product does not include —
  > either scope the rule ("when using Compose Multiplatform: ...") or omit it and
  > note it as unresolved. A manifest of rules that do not apply is one nobody
  > reads, and `/create-stories` consumes this file.
- `best-practices.md` required items for the layers in use, including the
  supply-chain settings for the SPA and the portability subset for the cache.

### From `deploy/` rules (when `distribution.model` is `hybrid` or `self-hosted`)
- Customer bundle: Valkey only for cache (no Dragonfly, no Redis >= 7.4); MongoDB by reference to the official image only; OTel Collector only, exporters off by default; signed bundle, preflight, backup before upgrade, rollback; telemetry off by default (`.claude/rules/deploy.md`, `.claude/docs/standing-decisions.md`).
- If `distribution.model` is `hosted`: record `Self-hosted rules: not applicable — distribution.model: hosted`.

---

## 4. Present Rules Summary Before Writing

Before writing the manifest, present a summary to the user:

```
## Control Manifest Preview
Stack: [layers + pinned versions]
ADRs covered: [list ADR numbers]
ADRs excluded: [ADR-NNNN ([status]), … — every ADR not in the Accepted set, or "None"]
Sections with no sourced rules: [layer or context — reason (NOT SOURCEABLE / no ADR / no domain map), or "None"]
Total rules extracted:
  - Backend: [N] required, [M] forbidden, [P] guardrails
  - Web: ...
  - Mobile: ...
  - Data: ...
  - Contracts: ...
  - Deploy (hosted / self-hosted): ...
  - Per bounded context: [context]: [N] required, [M] forbidden ...
  - Global: [N] standards rules, [M] forbidden APIs, [P] approved libraries
Unclassified rules: [count and names, or "None"]
```

Use `AskUserQuestion`:
- Prompt: "Does this rule summary look complete?"
- Options:
  - `[A] Yes — looks good, run the CTO review and write the manifest`
  - `[B] Add rules — I have additional rules to include before writing`
  - `[C] Remove rules — some extracted rules should be dropped`
  - `[D] Stop here — I need to review the ADRs first`

---

## 4b. Director Gate — Technical Review

**Review mode check** — apply before spawning CTO-MANIFEST:
- `solo` → skip. Note: "CTO-MANIFEST skipped — Solo mode." Proceed to Phase 5.
- `lean` → skip. Note: "CTO-MANIFEST skipped — Lean mode." Proceed to Phase 5.
- `full` → spawn as normal.

Spawn `cto` via `Agent` using gate **CTO-MANIFEST** (`.claude/docs/director-gates/cto-manifest.md`).

Pass: the Control Manifest Preview from Phase 4 (rule counts per layer and context, full extracted rule list), the list of ADRs covered, the stack versions (`pins.yaml`), and any rules sourced from the standards or stack-reference docs.

The `cto` reviews whether:
- All mandatory ADR patterns are captured and accurately stated
- Forbidden approaches are complete and correctly attributed
- No rules were added that lack a source ADR, standard or stack-reference doc
- Performance guardrails are consistent with the ADR constraints and `perf-budgets.md`
- Tenancy and self-hosted licence rules are present where they apply

Apply the verdict:
- **APPROVE** → proceed to Phase 5
- **CONCERNS** → surface via `AskUserQuestion` with options: `Revise flagged rules` / `Accept and proceed` / `Discuss further`
- **REJECT** → do not write the manifest; fix the flagged rules and re-present the summary
- **NOT ASSESSED** [missing input] → not an approval (`.claude/docs/director-gates.md`): name what was missing, then supply it and re-run the gate — or, if the user chooses to go on without it, continue to Phase 5 and state `CTO-MANIFEST: NOT ASSESSED — [input]` in the output and the final Verdict line

---

## 5. Write the Control Manifest

Use `AskUserQuestion`:
- Prompt: "May I write the Control Manifest?"
- Options:
  - `[A] Yes — write to docs/architecture/control-manifest.md`
  - `[B] Show me the full draft first, then ask again`
  - `[C] Not yet — I want to make more changes`

**Read `references/manifest-format.md` now** for the file format and write it exactly
in that shape. Every section that has no sourced rules says so by name
(`No rules — NOT SOURCEABLE ...` / `No rules — no Accepted ADR governs this layer`);
an empty heading is never written, because it reads as "checked, nothing to say".

---

## 6. Suggest Next Steps

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/create-control-manifest —
<COMPLETE | COMPLETE WITH GAPS | BLOCKED>`, Next step = the first suggestion below
(`/create-epics`, or `/story-readiness` on open stories for a regeneration),
plus Blocked on / Files in progress (`docs/architecture/control-manifest.md`) /
Open questions; append the Notes line. Still updated when the write was declined
(`BLOCKED`: record nothing written and why).

After writing the manifest:

- If epics/stories don't exist yet: "Run `/create-epics` then `/create-stories [epic-slug]` — engineers
  can now use this manifest when writing story implementation notes."
- If this is a regeneration (manifest already existed): "Updated. Recommend
  notifying the team of changed rules — especially any new Forbidden entries — and
  run `/story-readiness` on open stories, which compares each story's embedded
  `Manifest Version` to this file."

---

## Not-Run Reporting

The final output ends with a Verdict line naming what did not run: gate skipped
by review mode, layers `NOT SOURCEABLE`, the per-context section when there is no
domain map, ADRs excluded as not Accepted, classification left `Unclassified`.
`COMPLETE — control manifest written` is claimed only when none of these leaves a
silent hole; otherwise `COMPLETE WITH GAPS — [list]`.

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **Load silently** — read all inputs before presenting anything
2. **Show the summary first** — let the user see the scope before writing
3. **Ask before writing** — always confirm before creating or overwriting the manifest. On write: Verdict: **COMPLETE** — control manifest written, or `COMPLETE WITH GAPS — [list]` when the Not-Run Reporting section above names any hole. On decline: Verdict: **BLOCKED — write declined by user**.
4. **Source every rule** — never add a rule that doesn't trace to an ADR, a
   studio standard, or a stack-reference doc
5. **No interpretation** — extract rules as stated in ADRs; do not paraphrase
   in ways that change meaning
