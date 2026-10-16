> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other six — one gate applies per invocation.


# Gate: Architecture → Pre-Production


**Required Artifacts:**
- [ ] Stack configured (`/setup-stack` ran): `project.yaml` has the `stack` layers the brief names, `deploy.target`, `distribution.model` and `tenancy.model` set; `layout.code_roots` set or detectable
- [ ] Stack reference exists: `docs/stack-reference/pins.yaml` and `docs/stack-reference/<layer>/VERSION.md` for every layer in `stack`
- [ ] Master architecture document exists at `docs/architecture/architecture.md`: bounded contexts with `{domain, app, adapters}` layering, ports, data stores per context, tenancy, deployment for hosted **and** self-hosted when `distribution.model` includes it, sensitive data flows and trust boundaries
- [ ] At least 3 Architecture Decision Records in `docs/architecture/` covering the Foundation-layer decisions: **tenancy model, identity/authentication, data store(s), API style and contracts, deployment topology**, and **licensing** when `distribution.model` is `self-hosted` or `hybrid` (messaging too, when the product uses it)
- [ ] Architecture traceability index exists at `docs/architecture/requirements-traceability.md` (and `docs/architecture/tr-registry.yaml`)
- [ ] `/architecture-review` has been run (a review report file exists in `docs/architecture/`)
- [ ] A threat model exists for **every security-sensitive feature** (`docs/architecture/threat-models/<feature>.md`; sensitive = authentication, authorization model, billing, licensing, file upload, webhooks, PII export/delete, admin/impersonation, a new external integration), each with SL-THREAT-MODEL recorded and every mitigation mapped to a story and a negative test
- [ ] For `distribution.model` `self-hosted` or `hybrid`: the technical licence model exists (`docs/architecture/licence-model.md`) with its licensing ADR and threat model, and the architecture names the self-hosted bundle's engines within the licence rules (`.claude/rules/deploy.md`)
- [ ] Performance budgets exist at `docs/architecture/perf-budgets.md` (template `.claude/docs/templates/perf-budgets.md`)
- [ ] SLOs drafted at `docs/architecture/slos.md` (template `.claude/docs/templates/slos.md`)
- [ ] Design system: `PRODUCT.md` and `DESIGN.md` exist at the repository root (impeccable) with DD-DESIGN-SYSTEM recorded
- [ ] `design/accessibility-requirements.md` exists with the accessibility target committed (matches `accessibility.target` in `project.yaml`)
- [ ] `design/ux/interaction-patterns.md` exists (pattern library initialized, even if minimal)
- [ ] At least one UX spec started in `design/ux/` (often the app shell or the first-run flow)
- [ ] Test framework initialized for every layer in scope: its test location exists (`.claude/docs/directory-structure.md` "Code roots"), with Testcontainers wiring for integration tests on the data layers
- [ ] CI workflow exists that runs the test suites on push and pull request (`.github/workflows/` or equivalent)
- [ ] At least one example test file per layer in scope exists to confirm the framework is functional
- [ ] `docs/registry/architecture.yaml` (architectural stances registry) exists — recommended, not blocking
- [ ] A runnable local dev stack definition exists (`deploy/compose.dev.yaml` or equivalent) for run-and-observe — recommended, not blocking; the vertical slice needs it

**Quality Checks:**
- [ ] The Foundation decisions agree with `project.yaml`: `tenancy.model` and `distribution.model` and `deploy.target` match the architecture doc and the ADRs, and `contracts/` is the stated source of truth between clients and backend
- [ ] Architecture decisions cover the core concerns: tenant isolation mechanism (RLS / schema / database per tenant) with how tenant context propagates, identity and sessions, authorization model, data ownership per context, idempotency and outbox where async, caching decision, observability (spans, metrics, structured logs with `trace_id`), error model (RFC 9457 at the HTTP edge)
- [ ] No Foundation concern is "decided later" without a named owner and date
- [ ] All ADRs have a **Stack Compatibility section** with the pinned version stamped, an **ADR Dependencies section** (even if "None"), and a **Spec Requirements Addressed section** with explicit linkage to spec requirements
- [ ] No ADR references an API listed in `docs/stack-reference/<layer>/deprecated-apis.md`, and every pinned version in the ADRs agrees with `pins.yaml` (no stale version references)
- [ ] ADRs that touch APIs beyond the stack reference or the model's training data are flagged and have CTO-STACK-RISK recorded; all HIGH-risk stack domains (per the layer's `VERSION.md` / `breaking-changes.md`) are addressed in the architecture doc or listed as open questions
- [ ] Architecture traceability matrix has **zero Foundation-layer gaps** (every Foundation requirement has ADR coverage before Pre-Production)
- [ ] Threat-model mitigations are traceable: each names the story that will implement it and the negative test that will prove it (nothing "to be decided")
- [ ] CTO-ARCHITECTURE and PE-FEASIBILITY recorded for the architecture doc; CTO-ADR recorded per ADR; CTO-MANIFEST is checked at the next gate
- [ ] Shared capabilities (identity, OTP, notifications, storage, billing, licensing, tenancy, audit, observability) are planned to come from the `saas-core` track the product pins (`core.track`, `core.version`) — the architecture doesn't re-implement one; a gap is listed as a `/core-extract` candidate
- [ ] At least one screen's UX spec started; the accessibility target is addressed in it
- [ ] Self-hosted/hybrid only: no ADR or architecture text selects an engine the bundle may not ship — cache other than Valkey, Dragonfly, Redis ≥ 7.4, a MongoDB binary or self-built image, or an observability backend other than the OTel Collector (`.claude/rules/deploy.md`)

**ADR Circular Dependency Check**: run the deterministic graph builder rather than
reading every ADR to trace the graph by hand — a manual trace across a dozen ADRs
eventually misses an edge; the script cannot:
```
Bash: bash .claude/scripts/adr-dep-graph.sh
```
It prints `ADRS`, `EDGES` (one `adr-A -> adr-B` per Depends-On reference),
`NO_DEPS_SECTION` (ADRs with no Depends On), and a `CYCLE:` line per node in any
dependency cycle.
- **Any `CYCLE:` lines → FAIL**: "Circular ADR dependency: [the nodes on the
  `CYCLE:` lines]. Neither can reach Accepted while the cycle exists. Remove one
  'Depends On' edge to break the cycle."
- No `CYCLE:` lines → this check passes. But the acyclic result is only as
  trustworthy as the dependency sections are complete: if `NO_DEPS_SECTION` lists
  many ADRs, surface that as a CONCERNS note rather than a clean pass. If the
  script printed nothing or could not run, the check did not run: report it by
  name, never as acyclic.

**Stack Coherence** (run `bash .claude/scripts/project-coherence.sh` — Section 3):
- [ ] No `LICENCE` line (self-hosted/hybrid): an engine in `deploy/self-hosted/` that breaks the licence rules is a **Blocker** the moment it exists, even this early
- [ ] `BEHIND` and `FLOATING` lines are listed as CONCERNS with the layer and file; `ABSENT` for a layer the stack names means no manifest yet (expected before the vertical slice) and is noted, not a finding
- [ ] A `SKIPPED` line, or no output, means the comparison did not run: **NOT ASSESSED — stack coherence: [reason]**, never counted as MATCH

## Floors at every tier

- A configured stack, and the Foundation decisions recorded somewhere (ADRs, or the brief's decision log at `minimal`) — DoD gate 8 applies at every tier.
- Research notes are written per feature before its code (DoD gate 1); this gate does not check them, the next one does for the first features.

## Workflow tier reductions

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier; items not named keep their status above.
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

- **`full`** — stack + architecture doc + all ADRs + traceability index + `/architecture-review` + threat models for every sensitive feature + perf budgets + SLOs + design system (PRODUCT.md/DESIGN.md) + accessibility doc + UX specs started + test framework + CI all required
- **`standard`** — ADRs reduced to **critical (Foundation-layer) only**; design system required **only if the product has a user-facing surface** (`stack.web`, `stack.site` or `stack.mobile` set), otherwise recommended; perf budgets, SLOs, UX-specs-started, accessibility doc, interaction patterns, traceability index → recommended; threat models for sensitive features stay **required**; stack, architecture doc and test framework stay required
- **`minimal`** — only the **stack configured** and the **Foundation decisions recorded in the brief's decision log** required (ADR files are not required — the log replaces them); threat models, architecture doc, traceability, `/architecture-review`, budgets, SLOs, design system, UX items, test-framework and CI items **drop** (test items are also governed by `qa.level`). A sensitive story still needs SL-THREAT-MODEL at story time (`/story-readiness`), and the research note carries the threat analysis until then.

## Director gates at this transition

The PHASE-GATE panel (Section 4b) runs at the width `workflow` sets. Recorded,
not re-spawned: CTO-ARCHITECTURE, PE-FEASIBILITY, CTO-ADR (per ADR),
SL-THREAT-MODEL (per sensitive feature), DD-DESIGN-SYSTEM, CTO-STACK-RISK (where
the decision went beyond the stack reference). Absence is recorded as
"skipped — [mode]" or is a CONCERNS finding (Section 3, "Recorded director
verdicts").
