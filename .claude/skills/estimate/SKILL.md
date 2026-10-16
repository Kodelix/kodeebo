---
name: estimate
description: "Estimate task effort across backend, web and mobile lanes from complexity, dependencies, velocity, risk and Definition of Done work. Structured estimate with confidence levels."
argument-hint: "[task-description | story-path]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(date *), Bash(bash "*/.claude/skills/estimate/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys stack,qa.level,testing.strict,performance.enforce,workflow`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

# Estimate

Produces a ranged effort estimate per lane (backend, web, mobile, contracts,
data, platform). **Definition of Done work is inside the estimate, never an
afterthought**: the research note, tests by story type, observability, caching
decision, security negatives and run-and-observe evidence are line items with
their own days. An estimate that covers only "write the code" is an estimate
of 40–60% of the story.

This skill is read-only — it writes no files.

---

## Phase 1: Understand the Task

Read the task description from the argument (free text, or a story path — read
the story file). If the description is too vague to estimate meaningfully, ask
for clarification before proceeding.

Read `CLAUDE.md`, `.claude/docs/coding-standards.md` (the eight DoD gates and the
evidence table) and `.claude/docs/testing-standards.md`. Read the feature spec
(`design/specs/<feature>.md`) if the task belongs to a documented feature; at
`workflow: minimal` read `design/product-brief.md` instead and do not treat the
absent spec as missing work.

Determine, and state at the top of the estimate:

- **Story type** — Logic / Integration / Contract / Security / Performance / UI / Config (`coding-standards.md`). A task spanning types is split by lane below, each lane typed.
- **Lanes touched** — from `stack` in the resolved block: `backend` (Go or Ktor), `web`, `site`, `mobile` (Compose / KMP / SwiftUI), `contracts`, `deploy`. A lane the stack does not include is "not applicable", not zero.

---

## Phase 2: Scan Affected Code and Artifacts

Resolve the code roots with `resolve_code_root` (`.claude/docs/directory-structure.md` → Code roots). **An empty result means the scan did not run** — say so in Notes and Assumptions; never report "no files affected".

Per lane, identify:

- Files and modules that change; whether the work follows an existing pattern or needs a new one
- Integration points: other bounded contexts, `saas-core` modules, external providers, `contracts/` operations
- Existing test coverage in the affected area
- Sprint history in `production/sprints/` and retrospectives in `production/retrospectives/` for similar completed work and actual velocity.
  **If there is none**, say so under Notes and Assumptions — "No sprint history found;
  this estimate is not calibrated to the team's velocity" — and treat that as a
  risk in the confidence level, not as a silent padding of the figures.
- Whether `docs/research/<feature>.md` exists (DoD gate 1). Absent → research is a line item and implementation is not startable before it.
- Whether a threat model is required (`.claude/docs/security-baseline.md` → Threat modelling: auth, authorization model, billing, licensing, file upload, webhooks, PII export/delete, admin/impersonation, new external integration). Required and absent → `/threat-model` is a line item.
- Accepted ADRs covering the decisions this task needs. A decision with no ADR is a dependency, not a free assumption.

---

## Phase 3: Analyze Complexity Factors

Read `references/dod-effort.md` for the DoD effort table (what each gate and
story type adds). Then assess:

**Code complexity:** size and coupling of affected files; core/shared (`saas-core`) code vs leaf feature code; new patterns vs existing; concurrency or transactional subtleties.

**Scope:** lanes and bounded contexts touched; new code vs modification; schema or data migration (forward-only in production — expand, migrate, contract adds steps, `.claude/rules/migrations.md`); self-hosted upgrade path implications; Arabic/English and RTL for UI.

**Risk:** unfamiliar library or API beyond `docs/stack-reference/` (research needed); ambiguous requirements; dependency on unfinished work; provider sandbox/approval lead time; store review lead time for mobile; performance sensitivity (hot path); tenant-isolation exposure.

**Contract-first ordering:** if backend and any client consume a new or changed API, the contract story (`contracts/` OpenAPI/proto + contract test) comes first and is estimated separately. Client lanes depend on it; they are not parallel with it unless the contract is already merged.

---

## Phase 4: Generate the Estimate

```markdown
## Task Estimate: [Task Name]
Generated: [Date]

### Task Description
[Restate the task clearly in 1-2 sentences]

### Complexity Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Story type(s) | [Logic / Integration / Contract / Security / Performance / UI / Config] | |
| Lanes affected | [backend / web / mobile / contracts / data / platform] | |
| Bounded contexts / core modules | [List] | |
| Files likely modified | [Count per lane] | [Key files listed below] |
| New code vs modification | [Ratio] | |
| Integration points | [Count] | [contexts, providers, contracts] |
| Existing patterns available | [Yes / Partial / No] | |
| Threat model required | [Yes — exists / Yes — missing / No] | [trigger from security-baseline.md] |
| Research note | [Exists / Missing / Exempt — reason] | |

**Key files likely affected:**
- `[path/to/file1]` -- [what changes here]

### Effort Estimate (all lanes, DoD included)

| Scenario | Days | Assumption |
|----------|------|------------|
| Optimistic | [X] | Everything goes right, no surprises |
| Expected | [Y] | Normal pace, minor issues, one round of review |
| Pessimistic | [Z] | Significant unknowns surface, blocked for a day |

**Recommended budget: [Y days]**

### Effort by Lane

| Lane | Owner (agent) | Build | DoD evidence | Total (expected) |
|------|---------------|-------|--------------|------------------|
| Contracts | `api-designer` | [d] | contract test [d] | [d] |
| Backend | [`go-lead` / `ktor-lead`] | [d] | tests, observability, cache, perf, security [d] | [d] |
| Data / migration | `data-lead` | [d] | migration test + rollback note [d] | [d] |
| Web | `web-lead` | [d] | component/E2E, a11y, RTL screenshots [d] | [d] |
| Mobile | [`android-lead` / `ios-lead` / `kmp-specialist`] | [d] | tests, screenshots, store-readiness [d] | [d] |
| Platform / deploy | `platform-lead` | [d] | self-hosted bundle check [d] | [d] |

*(Omit lanes the stack does not include; name them "not applicable — [stack]".)*

### Confidence: [High / Medium / Low]

[Explain which factors drive the confidence level for this specific task.]

### Risk Factors

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|

### Dependencies

| Dependency | Status | Impact if Delayed |
|-----------|--------|-------------------|
| [Contract merged in `contracts/`] | | Client lanes blocked |
| [Research note / threat model / ADR] | | Implementation not startable |
| [`saas-core` module release] | | |
| [Provider sandbox / store review lead time] | | |

### Suggested Breakdown

| # | Sub-task | Lane | Estimate | Notes |
|---|----------|------|----------|-------|
| 1 | Research note (`docs/research/<feature>.md`) | cross | [X days] | Skip only if research-exempt (`research-protocol.md`) |
| 2 | Threat model (if triggered) | security | [X days] | `/threat-model`; SL-THREAT-MODEL |
| 3 | Contract + contract test | contracts | [X days] | Merged before dependent stories |
| 4 | Core implementation | per lane | [X days] | |
| 5 | Tests by story type (unit / Testcontainers / contract) | per lane | [X days] | |
| 6 | Observability + cache decision + perf evidence | backend | [X days] | |
| 7 | Security negatives (authz, cross-tenant, injection, rate limit) | per lane | [X days] | |
| 8 | Run-and-observe evidence | per lane | [X days] | `run-and-observe.md`; includes RTL screenshots for UI |
| 9 | Review + fixes | cross | [X days] | One round assumed in Expected |
| | **Total** | | **[Y days]** | |

### Notes and Assumptions
- [Key assumption that affects the estimate]
- [Any caveats about scope boundaries; checks that did not run (e.g. empty code roots, no sprint history)]
```

Output the estimate with a brief summary: recommended budget, confidence level, and the single biggest risk factor.

This skill is read-only — no files are written. Verdict: **COMPLETE** — estimate generated; **COMPLETE WITH GAPS** when a scan did not run (empty code roots, no sprint history, research or ADR missing) and the estimate names it; **NOT ASSESSED** when the task is too vague to estimate and the user did not clarify it (Phase 1).

---

## Phase 5: Next Steps

- If confidence is Low: recommend a time-boxed spike (`/prototype`) before committing, or `/research` when the unknown is a fact rather than a design.
- If the task is > 10 days: recommend breaking it into smaller stories via `/create-stories`, contract story first.
- To schedule the task: run `/sprint-plan update` to add it to the next sprint (if the project has no sprint plan, as on the default minimal workflow, add it to the brief's build order instead).

### Guidelines

- Always give a range (optimistic / expected / pessimistic), never a single number
- The recommended budget should be the expected estimate, not the optimistic one
- Round to half-day increments — estimating in hours implies false precision for tasks longer than a day
- Do not pad estimates silently — call out risk explicitly so the team can decide
- DoD evidence work is itemised, never hidden inside "implementation". Tests are never scaled down by `qa.level` (Logic, Integration, Contract and Security tests exist and pass at every tier, `coding-standards.md`): budget them in full at every tier. `qa.level` only changes how much *extra* evidence is budgeted (manual cases, coverage signal, UAT). The research note, security negatives on a security-sensitive story and run-and-observe evidence are never dropped
- Confidence is Low whenever the approach is undecided, the core requirements are still TBD, or the contract is not yet designed — a range built on an unmade decision is a guess
- Provider approval and store review are calendar time, not effort days: list them under Dependencies with their lead time
