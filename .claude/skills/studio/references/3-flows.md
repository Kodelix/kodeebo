# /studio — Phase 3: Plan the Flow

> Part of `/studio`.

Show the plan before running it: the steps, which are skipped and why, and
where the user will be asked to decide. Ask "Run this plan?" (collaborative)
before step 1.

Skip a step only when its trigger is absent **or the tier makes its document
optional**, and name which of the two it is
(`skipped — tier: /design-spec is not required at workflow: minimal` versus
`skipped — trigger absent: no screens change`). A silent skip and a step that ran
look the same in the output; the plan and the checkpoint's `Skipped:` line must
tell them apart. Steps marked **gate** stop for the user (see `4-run.md`).

## 0. Resolve the tier first — documents scale, engineering never does

Read `workflow` from the resolved block (`.claude/docs/workflow-modes.md`:
`system_overrides.<feature>` → `modes.workflow` → the tier implied by `modes.rigor`).
For a flow about one named feature, resolve **that feature's** tier: the key is the
spec filename stem, and `system_overrides` replaces the tier in both directions.
Print one line: `Tier: <minimal|standard|full> (source: override for <feature> | modes.workflow | rigor)`.

| Scales with the tier (documents) | Never scales (engineering — every tier) |
|---|---|
| product brief vs full concept; domain map; spec sections (none / 5 + conditional / 8); architecture document; ADR files (none / critical / all); UX specs; control manifest; sprint plan and epics; the readiness check; director-gate depth | the research note before code (gate 1) with `Status: Complete`; clean architecture; **tests exist and pass** for Logic, Integration, Contract and Security stories; observability; a written cache decision; the performance budget *checked* when one exists; security (a threat model for a sensitive feature with residual risk accepted by name, dependency and secret scans, tenant-isolation tests); a decision record (an ADR, or the brief's decision log at `minimal`); run-and-observe evidence; contract-first ordering; forward-only migrations |

`qa.level` is a separate axis: it changes how much *extra* test evidence is
asked for, never whether the required tests exist and pass.

A step a lower tier drops is **optional, not forbidden**: the user may still ask
for it, and `/studio` offers it once when it would clearly help (for example
`/design-spec` for a feature a `system_overrides` entry pins higher).

## feature (the backbone)

Common to every tier, in this order (a step that does not apply is named):

1. `/research` → `docs/research/<feature>.md` — **gate** (research conclusion). Needs `Status: Complete`; a `Draft` note (verdict COMPLETE WITH GAPS) goes back to the user to finish or to accept in writing. Skipped only if the research-protocol exemption table applies; say which row.
2. `/threat-model` — when the feature touches a trigger in `security-baseline.md` — **gate** (residual risk accepted by a named person). Required at **every** tier for a sensitive feature.
3. `/ux-design` + `/team-ui` — when screens change; requires `PRODUCT.md` (else `/impeccable init`).
4. `/api-contract` — when an endpoint changes; contract merges first.
5. `/db-migration`, `/cache-design` — when schema or a hot read path changes (the cache decision, or a written "no cache", is gate 5 at every tier).
6. Per story: see "Per story" below.
7. Close: `/team-qa` scope check, `/release-notes` if user-visible.

What differs by tier:

| Step | `minimal` | `standard` | `full` |
|---|---|---|---|
| Spec | none required — the brief and the research note are the spec; `/quick-spec` for a small change | `/design-spec`: 5 sections (+ Edge Cases when it calls a provider, moves money, changes entitlements or runs async) — **gate** (spec approval) | `/design-spec`: all 8 sections, then `/spec-review` — **gate** |
| Cross-spec | — | `/review-all-specs` at a phase boundary | `/review-all-specs` after each batch |
| Decisions | the brief's decision log (not an ADR file) | `/architecture-decision` for **critical** decisions only — **gate** (ADR) | `/architecture-decision` for every architectural decision — **gate** |
| Architecture foundation | none | once per product: see "Foundation" | once per product: see "Foundation" |
| Stories | `/create-stories` — the epic is implicit; the brief's build order is the plan | `/create-epics` (if the context has none) → `/create-stories` — **gate** (story list) | as `standard`, control manifest required |
| Per-story readiness | none (`/story-readiness` is off the minimal path) | `/story-readiness` | `/story-readiness` |
| Sprint | none | `/sprint-plan` | `/sprint-plan` |

### Per story

`minimal`: `/dev-story` → `/code-review` (optional) → `/story-done`.
`standard` and `full`: `/story-readiness` → `/dev-story` → `/code-review` → `/story-done`.
`/dev-story` and `/story-done` are user-typed (see `4-run.md`). **Gate**: each
story's Done. A story `/dev-story` left `In Review` is next for `/story-done`;
one left `In Progress` still needs `/dev-story`.

### Foundation (`standard` and `full`, once per product, before the first epic)

The Architecture-phase documents that `/create-epics`, `/create-stories` and
`/dev-story` read. **Check what exists first** (the `artifact-check.sh` rows for
`create-architecture`, `architecture-decision`, `architecture-review`,
`control-manifest`, `perf-budgets`, `test-setup`) and run only the ABSENT ones, in
this order, each with its own gate where listed:

1. `/create-architecture` → `docs/architecture/architecture.md`
2. `/architecture-decision` × the Required ADR list (critical ones at `standard`) — **gate** (ADR)
3. `/architecture-review` → traceability and `docs/architecture/tr-registry.yaml` (without the registry `/dev-story` stops at `full` and TR-ID checks elsewhere are `not checked`)
4. `/create-control-manifest` — required at `full`, recommended at `standard`
5. `/perf-profile` (budgets) → `docs/architecture/perf-budgets.md`
6. `/observability-plan slos` — required at `full`
7. `/test-setup` — test frameworks and CI per configured layer
8. `/gate-check pre-production` — **gate** (stage advance; only `/gate-check` writes `project.stage`)

At `minimal` only `/test-setup` carries over (tests must exist and pass): run it
once before the first story of a layer that has no test framework. The rest of
this list is skipped by tier, and the plan says so.

## Other flows (reuse the backbone)

Every flow below is resolved against the tier table in section 0 before it is shown.

| Flow | Steps |
|---|---|
| new-product | see "new-product by tier" |
| bug | `/bug-report` → `/debug` (root cause proven) → fix story → `/dev-story` → `/code-review` → `/story-done`; S1 → offer `/hotfix` |
| performance | `/perf-profile` (budgets) → `/load-test` → fix stories → `/story-done` with before/after evidence |
| security | `/security-audit` and/or `/threat-model` → `/pentest` when dynamic testing is needed → fix stories → SL-RELEASE-SECURITY |
| integration | `/integration <provider>` (research → integration spec → threat model → adapter story → contract tests) |
| data-change | `/db-migration` → `/tenant-check` when tenant-owned tables change → story → done |
| api-change | `/api-contract` → backend and client stories (`/team-api`) |
| ui | `/ux-design` → `/team-ui` → `/ux-review` → stories |
| test | `/test` (run) · `/manual-test` (explore) · `/automate-test` (convert) · `/uat` (sign-off) · `/pentest` (authorised) |
| release | `/gate-check hardening` then `/gate-check release` → `/release-checklist` → `/team-release` (canary, rollback triggers, post-deploy verification) → `/release-notes` |
| incident | `/incident` → `/postmortem` → follow-up stories |
| core | `/core-use` (adopt) or `/core-extract` (promote) → `/core-release` in the core repo → `/core-upgrade` in products |
| business | `/business` (routes to the business team; may chain `/market-research`, `/competitor-analysis`, `/pricing-strategy`, `/offer-design`, `/gtm-plan`, `/business-case`) |

### new-product by tier

The order is fixed: **`/setup-stack` before `/brainstorm`** — stack, delivery model
and tenancy are decided first and the brief is written against them (the same
order `/start` and the minimal path in `workflow-catalog.yaml` use).

- **`minimal`**: `/start` → `/setup-stack` → `/brainstorm` (the one-page brief; its build order is the plan) → `/test-setup` → the feature flow (minimal column) per MVP feature in build order → `/gate-check hardening` → `/gate-check release` when shipping. No domain map, specs, architecture document, ADR files or sprint plan.
- **`standard`**: `/start` → `/business` (optional) → `/setup-stack` → `/brainstorm` → `/prototype` (optional) → `/map-domains` → `/design-spec` per MVP feature → `/review-all-specs` → `/gate-check product-design` → `/gate-check architecture` → Foundation → `/gate-check pre-production` → `/create-epics` → `/create-stories` → `/sprint-plan` → the feature flow per story → `/gate-check production`.
- **`full`**: as `standard`, plus `/spec-review` after each spec, a threat model per sensitive feature, UX specs per screen, all ADRs, the control manifest, SLOs, `/vertical-slice` (with `/usability-report`) before `/gate-check production`, then `/gate-check hardening` → `/gate-check release` before shipping.

Call `/gate-check <next stage>` at each boundary listed, so `project.stage`
advances through the gate and not by assumption; a gate that does not apply at
the tier returns its own "not applicable" PASS and the plan says so. A boundary
the user chooses to skip is recorded under `Skipped:`.
