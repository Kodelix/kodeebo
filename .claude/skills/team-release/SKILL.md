---
name: team-release
description: "Orchestrate the release team — release-manager, qa-lead, platform-lead, producer, customer-success — to execute a release from candidate to deployment across hosted, self-hosted bundle and mobile stores."
argument-hint: "[version number or 'next'] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Skill, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/hooks/yaml-helper.sh is_always_ask_category *), Bash(bash "*/.claude/skills/team-release/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
# Team Release

**Argument check:** If no version number is provided:
1. Read `production/session-state/active.md` and the most recent file in `production/milestones/` (if they exist) to infer the target version.
2. If a version is found: report "No version argument provided — inferred [version] from milestone data. Proceeding." Then confirm with `AskUserQuestion`: "Releasing [version]. Is this correct?"
3. If no version is discoverable: use `AskUserQuestion` to ask "What version number should be released? (e.g., v1.0.0)" and wait for user input before proceeding. Do NOT default to a hardcoded version string.

When this skill is invoked, orchestrate the release team through a structured pipeline.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

## Phase 0: Resolve Config

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,workflow,qa.level,project.stage,stack,distribution,deploy`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**Stage check — before anything is spawned.** This skill ships a release, and
`/gate-check release` is the readiness gate that must pass first; only its PASS
sets `project.stage` to `Release`. If the resolved `project.stage` is anything
else — `Hardening`, an earlier stage, or not set — stop before Phase 1 and spawn
nothing:

> "The release readiness gate has not passed (project.stage: [stage]) — run
> `/gate-check release` first."

Then ask with `AskUserQuestion`, in every `automation` mode — an override is never
taken on the user's behalf: `[A] Stop — I'll run /gate-check release (recommended)`
/ `[B] Proceed anyway — override the stage check`. On `[A]`, end the run: Verdict
**BLOCKED** — release gate not passed. On `[B]`, ask (plain text) why, then record
the override as `Stage override: project.stage was [stage] — release gate not
passed; the user chose to proceed: [reason]` in the Phase 1 brief, in the go/no-go
record (`go-no-go-[version].md`) and in the final report. An override never
changes the stage itself.

**Editions in play.** Read `distribution.model`, `deploy.target` and `stack` from
the config above and the release scope. State which editions this release ships
— hosted, self-hosted bundle, Android (Play), iOS (App Store), web, marketing
site — and run only the phases that apply to them, naming each edition skipped
and why (for example `self-hosted bundle: not in this release —
distribution.model: hosted`). If the config does not say, ask; an absent value is
not "hosted only".

`review_mode` sets director-gate depth. This pipeline has no PHASE-GATE; the
release-readiness gates it spawns — `SL-RELEASE-SECURITY` (`security-lead`) and
`SRE-OPERABILITY` (`sre-lead`) — are spawned **by this skill**, so they follow
the ordinary per-skill rule (`.claude/docs/director-gates.md`, Invocation
Pattern): `solo` skips them, `lean` skips them, `full` spawns them. A skipped
gate is recorded as `[GATE-ID] skipped — [mode] mode` and **waives the
director's opinion, never the evidence**: the release checklist's security,
backup/restore, capacity and rollback items are still checked by
`release-manager` and `platform-lead` in Phase 3. A skipped gate is never
reported as passed. (`/gate-check release` runs both gates at `lean` and `full`;
this pipeline runs after it.)

`automation` drives the Decision Points note above. See
`.claude/docs/automation-modes.md` for how each mode changes pipeline behaviour.

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`** (default): `release-manager` only. Other agents consulted via the release-manager, not spawned separately.
- **`small`**: + `producer` + `platform-lead` + `qa-lead` + `customer-success`.
- **`studio`**: + `localization-lead` + `performance-engineer` + `product-analytics-engineer` + `technical-writer` (self-hosted upgrade guide), and `security-lead` / `sre-lead` for their gates when `review_mode` is `full` (the full pipeline as documented).
A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists** — a transition under Decision Points above, the stage check, or the Phase 6 deploy question — **whatever the `automation` mode.** `guided` and `autonomous` change how a gate is passed (it auto-advances, or is recorded with `log_decision`), not whether it is one, so bounded-exception condition (3) below holds at it in every mode. An agent restricted to "phase gates only" is spawned at those points and no others. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

**Announce the active set before Phase 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example.

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is one agent. **The collapse is correct**: `team.size` is rigor-fronted and the
narrow default is the token lever. Without saying so, a reader cannot distinguish
a correctly-collapsed run from a broken pipeline, and the per-agent "routes
through the nearest core agent with an informational note" rule fires at routing
time and never states the shape of the run as a whole.

This is the same rule as the skipped-check reporting elsewhere in this file: **a
constraint that is enforced but never surfaced is indistinguishable, to the
person reading the output, from one that was never enforced.**

## Team Composition
- **release-manager** — Versioning, release tag, changelog, release notes, store submissions, self-hosted release channel, release report
- **qa-lead** — Test sign-off (consumes the `/team-qa release` verdict), regression suite, release quality gate
- **platform-lead** — Build pipeline, artifacts, signed bundle, SBOM, image scans, deploy automation, rollback rehearsal
- **customer-success** — Release notes review and publication, in-app/email/status communication, known issues, support readiness
- **producer** — Go/no-go decision, stakeholder communication, scheduling
- *Studio size only:* **localization-lead** (Arabic/English sign-off), **performance-engineer** (budgets), **product-analytics-engineer** (events and dashboards), **technical-writer** (self-hosted install/upgrade guide)
- *Gates (spawned per `review_mode`, Phase 3):* **security-lead** (`SL-RELEASE-SECURITY`), **sre-lead** (`SRE-OPERABILITY`)

## How to Delegate

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: release-manager` — Release tag, versioning, changelog, release notes, deployment coordination
- `subagent_type: qa-lead` — Test sign-off, regression suite, release quality gate
- `subagent_type: platform-lead` — Build pipeline, artifacts, deployment automation (routes to `infra-engineer` as needed)
- `subagent_type: customer-success` — Release communication, support readiness
- `subagent_type: producer` — Go/no-go decision, stakeholder communication
- `subagent_type: localization-lead` — Arabic/English completeness sign-off (Phase 4)
- `subagent_type: performance-engineer` — Budget benchmarks on the release build (Phase 4)
- `subagent_type: product-analytics-engineer` — Event and dashboard verification (Phase 4)
- `subagent_type: technical-writer` — Self-hosted install/upgrade guide (Phase 4)
- `subagent_type: security-lead` — `SL-RELEASE-SECURITY` (Phase 3, `review_mode: full`)
- `subagent_type: sre-lead` — `SRE-OPERABILITY` (Phase 3, `review_mode: full`)

When spawning `security-lead` or `sre-lead` for a gate, the `Agent` prompt gives
the path of the gate definition (`.claude/docs/director-gates/sl-release-security.md`
or `sre-operability.md`) and instructs the agent to read it first; do not read
the gate file yourself. Pass only the fields under that gate's **Context to
pass**.

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session.

**Substitute a real path for `[path]`.** One file per agent under
`production/releases/`, except the ones whose homes are fixed elsewhere. An
active agent standing in for one outside the active set writes that agent's file:

| Phase / agent | Writes to | Destination fixed by |
|---|---|---|
| 1 producer | `production/releases/release-plan-[version].md` | this skill |
| 2 release-manager | `production/releases/release-checklist-[version].md` | `/release-checklist` |
| 3 qa-lead | `production/releases/qa-gate-[version].md` | this skill |
| 3 platform-lead | `production/releases/build-[version].md` | this skill |
| 3 security-lead | `production/releases/security-signoff-[version].md` | this skill |
| 3 sre-lead | `production/releases/operability-signoff-[version].md` | this skill |
| 3 platform-lead (rollout plan) | `production/releases/rollout-[version].md` | this skill |
| 4 localization-lead | `production/releases/localization-signoff-[version].md` | this skill |
| 4 performance-engineer | `production/releases/performance-signoff-[version].md` | this skill |
| 4 product-analytics-engineer | `production/releases/analytics-signoff-[version].md` | this skill |
| 4 technical-writer | `production/releases/selfhosted-guide-[version].md` | this skill |
| 5 go/no-go (written by the orchestrator from the producer's decision) | `production/releases/go-no-go-[version].md` | this skill |
| 6 release-manager | `docs/release-notes/[version].en.md` and `.ar.md` | `/release-notes` |
| 6 customer-success | `production/releases/announcement-[version].md` | this skill |
| 6 platform-lead (post-deploy verification) | `production/releases/post-deploy-[version].md` | this skill |
| 7 release-manager | `production/releases/release-report-[version].md` | this skill |

> **Every one of those outputs needs a stated destination.**
> `production/releases/` is where `/release-checklist` already writes, and
> `docs/release-notes/` is where `/release-notes` already writes, so the release
> record lands in one place regardless of which skill produced it.
>
> **A separate file per agent, not one appended record.** Phase 3 and Phase 4
> spawn agents in parallel; two agents appending to one file race, and the loser's
> section vanishes silently.

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or a test directory, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.

Launch independent agents in parallel where the pipeline allows it (e.g. Phase 3 agents run simultaneously) — issue every independent `Agent` call before waiting for any result, collect all results, surface any BLOCKED agent immediately (`.claude/docs/coordination-rules.md`, Parallel Task Protocol).

## Pipeline

### Phase 1: Release Planning
Delegate to **producer**:
- Confirm all milestone acceptance criteria are met
- Identify any scope items deferred from this release
- Set the target release date and rollout order across editions; communicate to the team. Avoid windows with no support cover (weekend/holiday cover in the markets served, such as Eid periods in Egypt and the GCC)
- Output: release authorization with scope confirmation and the edition list

### Phase 2: Release Candidate
Delegate to **release-manager**:
- Bump version numbers in all relevant places on `main` per product layer (backend, web, mobile build numbers, bundle, contract version); the commit carrying the bump is the release candidate. Development is trunk-based — a release is a tag on `main` (applied in Phase 6), not a branch
- Confirm the release checklist (`/release-checklist`, run before `/gate-check release`) is complete for this candidate; run it now only if none exists. It covers hosted deploy, self-hosted bundle, Play, App Store, web and site targets as the editions require
- For the self-hosted bundle: the upgrade-from matrix, migration and downtime notes, licence/update-eligibility implications, signed artefacts and SBOM, and the cache/Mongo/observability components respecting the licence decisions in `docs/ROADMAP.md` (L1–L4)
- For mobile: store build numbers, the target API/SDK requirements and the privacy declarations as sourced in `docs/stack-reference/` (anything not sourced is `NOT SOURCEABLE`, flagged — never filled from memory)
- Cut a `release/[version]` branch from the candidate only if this release needs stabilising — bug fixes only there, and every fix lands on `main` as well
- Output: release candidate commit (plus the `release/*` branch, if one was cut) and checklist

### Phase 3: Quality Gate (parallel)
Delegate in parallel:
- **qa-lead**: Run `/team-qa release` (or read its latest sign-off for this candidate) and execute the full regression suite on the running stack. Test all critical journeys, including the Arabic (RTL) pass. Verify no open bugs at the severities `/gate-check release` blocks for this `workflow`: S1 at every tier, S2 and S3 too at `full`. **A QA sign-off that is NOT ASSESSED is not a sign-off** — report it as such.
- **platform-lead**: Build release artifacts for every edition in scope; verify builds are clean and reproducible from the tagged commit; images tagged by digest and scanned; SBOM generated; self-hosted bundle signed and its install and upgrade verified on a clean host; run automated tests in CI; rehearse the rollback (previous digests retained, migration compatible with the previous app version, zero-downtime procedure per `.claude/rules/deploy.md`); **write the rollout plan** (`rollout-[version].md`, see "Rollout plan" below) — the canary steps, hold times, rollback triggers with numeric thresholds, the rollback owner, and the post-deploy verification script — before any deploy is asked for
- **release-manager** *(feature-flag gate)*: list every user-visible change in the scope that is risky — a new or changed pricing, plan or entitlement behaviour, a changed core journey, an auth or data-visible change, anything whose rollback is not a pure redeploy. Each must ship **behind a feature flag that is off by default**, read from config or the database (never a deploy-time constant), with a named owner and removal date, a tested flag-off path, and a way to switch it off **without a deploy**. A risky change with no flag is a CONCERNS item for the go/no-go with the reason written down (for example, a schema change that cannot be gated); a hosted-only flag service is not available to a self-hosted customer, so for the bundle the flag lives in the product's own config.
- **security-lead** *(gate `SL-RELEASE-SECURITY`, when `review_mode` is `full`)*: release security readiness — control mapping, scans on the release commit, vulnerabilities, secrets, tenant isolation. If the gate is skipped by mode, record `SL-RELEASE-SECURITY skipped — [mode] mode` **and** have `release-manager` confirm the checklist's security section by evidence.
- **sre-lead** *(gate `SRE-OPERABILITY`, when `review_mode` is `full`)*: observability, backups with a tested restore, capacity, rollback plan, self-hosted upgrade path. If skipped by mode, record it the same way and have `platform-lead` confirm the checklist's reliability section by evidence.

### Rollout plan (written in Phase 3, approved at Phase 5, executed in Phase 6)

`platform-lead` writes `production/releases/rollout-[version].md` for each edition
in scope. **A release with no written rollout plan has no go/no-go to give** —
the producer treats a missing plan as NOT ASSESSED for that edition.

- **Hosted (Docker Compose on a VPS).** Canary first, then promote in steps:
  after the staging smoke passes and the one-shot migration job has run, start the
  new version **beside** the old one and send it a small share — reverse-proxy
  weighting where the proxy supports it, a single instance or one internal/design-
  partner tenant cohort selected by feature flag, or the least-risky region/tenant
  group. State the steps (for example `internal → 5 % → 25 % → 100 %`), the
  **minimum hold time at each step**, and the traffic or tenant count needed for
  the signals below to mean anything (a 5 % step on a quiet product proves
  nothing — say so and lengthen the hold instead).
- **Rollback triggers — numeric, written before the deploy, not decided in the
  moment.** At least these, with thresholds taken from `docs/architecture/slos.md`
  and `perf-budgets.md` (an absent SLO or budget is written as `NOT SOURCEABLE —
  threshold not set` and the trigger falls back to the previous release's measured
  baseline plus an explicit margin):
  1. **Error rate** — 5xx / failed-job rate above `[x]` (or above the previous
     release's baseline by `[y]`) for `[z]` minutes at the current step.
  2. **Latency / SLO burn** — p95 above the budget by `[y]` %, or a fast-burn
     SLO alert firing (the multi-window burn-rate alert in `slos.md`).
  3. **Failed health checks** — `/readyz` failing or a service restart-looping,
     or the post-deploy smoke journey failing, at any step.
  4. **Business/guard signals** — payment-failure or login-failure rate above
     `[x]`, a cross-tenant error, any new S1.
  Tripping any trigger means **stop promotion and roll back to the retained
  previous digests** (flags off first when a flag is involved). The rollback owner
  (name) and the time-box are in the plan. Data-side: migrations are forward-only
  in production, so "roll back" for data is the written forward-fix or restore
  procedure, stated plainly — never implied.
- **Self-hosted bundle (update channel).** Customers cannot be hot-fixed and the
  product does not phone home by default, so the canary is a **channel**: publish
  to the early/beta channel first (our own install and design-partner installs
  that opted in), hold for `[n]` days, then promote to stable. Triggers: a failed
  clean-host install or upgrade in the matrix, a failed migration report, a
  signature or checksum failure, or a support-confirmed regression. Rollback =
  withdraw the bundle from the channel and publish the advisory with the
  restore-from-pre-upgrade-backup steps (migrations are forward-only).
- **Mobile.** Use the store's staged rollout; halt it if crash-free sessions fall
  below `[x]` % or the ANR / startup budget is breached.
- **Post-deploy verification (scripted, against production).** `/livez` and
  `/readyz`; the smoke journey run as a synthetic tenant; one retained trace for
  each critical journey; the error tracker clean for the new version; error rate
  and latency compared with the previous release over the hold window. Its result
  is written to `post-deploy-[version].md` as `PASSED` / `FAILED` / `not run —
  [reason]`.

A gate verdict of **NOT READY** is a blocker. **CONCERNS** are surfaced to the user (`Revise` / `Accept and proceed` / `Discuss`). **NOT ASSESSED** is never counted as READY.

### Phase 4: Localization, Performance, Analytics and Docs
Delegate (can run in parallel with Phase 3 if resources available):
- **localization-lead** (if available): confirm every shipped string is translated and approved in Arabic and English, using `/localize qa`; locales with no executed QA are NOT ASSESSED
- **performance-engineer** (if available): run the release build against `docs/architecture/perf-budgets.md` (load test for hot paths; web bundle size; mobile start-up and size budgets) — `performance.enforce` decides whether a miss blocks
- **product-analytics-engineer** (if available): verify the events in the tracking plan fire on the release build, dashboards are receiving data, funnels are instrumented, and no PII is in the telemetry
- **technical-writer** (if self-hosted is in the release): install and upgrade guide covers this version's migration, config and licence changes
- Output: one sign-off file per agent (table above); an agent not in the active set is named as not run, not as passed

### Phase 5: Go/No-Go
Before delegating, get the **cto** release sign-off. The producer cannot spawn
agents, so the orchestrator does: spawn `cto` at `review_mode: full` only — this
is a director review, not a PHASE-GATE, so `lean` and `solo` skip it. Ask for GO,
CONCERNS or NO-GO on the release candidate's technical state, or NOT ASSESSED
naming what it could not read. When it is not spawned, the go/no-go record says
`cto sign-off: not run (review_mode: <mode>)` instead of listing it as given; a
NOT ASSESSED answer is recorded as such and never counted as a sign-off.

Delegate to **producer**, passing every sign-off collected so far:
- Collect sign-off from: qa-lead, release-manager, platform-lead, the security and operability gates (or their recorded skips), localization/performance/analytics (if spawned), and cto (if spawned above)
- Check the **rollout plan** (`rollout-[version].md`) exists per edition with numeric rollback triggers, a named rollback owner and a scripted post-deploy verification, and that the feature-flag gate has no unaccepted unflagged risky change; a missing plan or an unflagged risky change with no written acceptance is a CONCERNS item at least, and a missing plan is NOT ASSESSED for that edition
- Carry a stage-check override, if there was one, into the go/no-go record as its `Stage override:` line
- Evaluate any open issues — are they blocking or can they ship? Known issues that ship are listed for the release notes
- Make the go/no-go call per edition (one edition can be GO while another is held). **`producer` owns the call**; the orchestrator writes it down — see "Go/no-go record" below
- Output: release decision with rationale

**Go/no-go record.** The orchestrator writes `production/releases/go-no-go-[version].md` from the producer's returned decision (per edition: GO / NO-GO / NOT ASSESSED with rationale), the sign-offs collected, the `cto sign-off` line, and any `Stage override:` line — asking first ("May I write the go/no-go record to `production/releases/go-no-go-[version].md`?"). An Override Justification is appended to this file with `Edit`. Declined write: Verdict **BLOCKED — write declined by user**; Phase 6 does not start.

**If producer declares NO-GO:**
- Surface the decision immediately: "PRODUCER: NO-GO — [rationale, e.g., S1 bug found in Phase 3]."
- Use `AskUserQuestion` with options:
  - Fix the blocker and re-run the affected phase
  - Defer the release to a later date
  - Override NO-GO with documented rationale (user must provide written justification)
- **Skip Phase 6 entirely** — do not tag, publish, deploy to staging, deploy to production, submit to a store or spawn `customer-success` for announcements.
- Produce a partial report summarizing Phases 1–5 and what was skipped (Phase 6) and why.
- Verdict: **BLOCKED** — release not deployed.

After the user selects "Override NO-GO with documented rationale":
- Ask (plain text, not widget): "Please describe the justification for overriding the NO-GO verdict. This will be embedded in the release record."
- Wait for the user's written justification.
- Embed the justification text in the partial approval record before Phase 6: append an "Override Justification: [user's text]" field.
- Only then proceed to Phase 6.

### Phase 6: Deployment (if GO)

**This phase always requires explicit user approval regardless of
`modes.automation` — including `autonomous` mode.** Production deployment,
publishing a signed bundle and submitting to a store are irreversible and
high-stakes; they are NOT covered by the configurable `automation_always_ask`
categories, so this skill guards them unconditionally. Before tagging or
deploying, use `AskUserQuestion`:
- Prompt: "Producer verdict is GO. Execute Phase 6 for [editions] — tag, deploy to staging, deploy to production, publish self-hosted bundle, submit to stores?"
- Options: `[A] Yes, deploy` / `[B] Staging only — hold production and publication` / `[C] Select editions — I'll choose which` / `[D] Stop here`

Each edition's publication is its own decision: approval for hosted is not
approval to publish the self-hosted bundle or submit to a store.

Only after explicit approval, delegate to **release-manager** + **platform-lead**:
- Tag the release in version control
- Finalize the changelog drafted during Hardening (`/changelog`), adding what changed since the gate
- **Hosted**: deploy to staging for a final smoke test (`/smoke-check`), then to production using the zero-downtime procedure (migration job → start new → health → switch → stop old) **executed as the staged rollout in `rollout-[version].md`**: canary step, observe for the hold time, compare against the rollback triggers, then promote. Show the user the trigger readings at each step and ask before promoting to the next one (a promotion is a decision; in `autonomous` mode it is recorded with `log_decision` only if every trigger is within threshold, and never past the first customer-visible step without the user). **A tripped trigger is not held for approval**: the named owner stops promotion and rolls back to the retained digests (flags off first), and the user is told at once. Keep the previous digests ready for rollback until the verification below has passed
- **Post-deploy production verification (hosted)**: after 100 %, `platform-lead` runs the scripted verification from the rollout plan and writes `post-deploy-[version].md`. A `FAILED` or `not run` result means the hosted edition is **not** reported as shipped-and-healthy; it is PARTIAL until it passes
- **Self-hosted**: publish the signed bundle and its checksums to the **early/beta channel** only after the staging install and upgrade check passes; promote to stable only after the hold time in the rollout plan with no tripped trigger. Each channel publication is its own decision
- **Android / iOS**: submit the build; use staged rollout where the store allows and halt it on the plan's crash-free / ANR trigger; record review status. A store review that is pending is reported as pending, never as shipped
- **Web / marketing site**: publish the static bundle with cache invalidation
- Post-release watch (48 hours): the **rollback owner named in `rollout-[version].md`** monitors dashboards, SLO burn and error rates. This skill creates a task with `TaskCreate` — owner, start and end time, the triggers it watches — and lists it in the report; the follow-up `/retrospective` at the 48-hour mark is a second task owned by the user. A task with no named owner is not created: Phase 6 asks for the owner first.

In parallel with deployment, delegate to **release-manager**:
- Finalize the customer-facing notes with `/release-notes [version]` — English and Arabic, hosted and self-hosted editions, Upgrade Notes, security wording held until the fix is available to every affected edition

Then hand those notes to **customer-success**:
- Review the notes for clarity and tone; prepare the announcement (in-app, email, status page, store "What's new", help-centre updates) in English and Arabic
- Draft the known-issues post if any S3+ issues shipped
- Prepare support readiness: macros/FAQs for the changes, the escalation path, and who is on cover during rollout
- Output: all customer-facing release communication, ready to publish **on deploy confirmation** — never before the artifact exists for that edition

### Phase 7: Post-Release
- **release-manager**: Generate release report (what shipped per edition, what was deferred, store review status, metrics)
- **producer**: Update milestone tracking, communicate to stakeholders
- **qa-lead**: Monitor incoming bug reports for regressions; a regression found here is a `/hotfix` candidate
- **customer-success**: Publish all customer communication on confirmation, triage support volume, synthesise feedback
- **platform-lead** / `sre-lead`: confirm dashboards, alerts and SLO burn are healthy; alert if a critical signal is missing
- **product-analytics-engineer**: Confirm live dashboards are healthy; alert if any critical event is missing
- Keep the rollout plan's rollback triggers armed for the whole 48-hour window — they do not expire when promotion reaches 100 %; a trigger tripped inside the window is a rollback decision for the named owner, not a retrospective item
- Keep the 48-hour monitoring window from Phase 6 (the release-manager's own watch runs to its 72h report)
- Schedule a post-release retrospective if issues occurred; if S1/S2 issues occurred, use `.claude/docs/templates/incident-response.md`

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is usually still
there.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** Full procedure: `.claude/docs/error-recovery-protocol.md`.

Common blockers:
- Input file missing (story not found, spec absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; accept it with `/architecture-decision accept ADR-NNNN` once decided
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess
- Signing key, store credentials or deploy credentials unavailable → stop; those are the user's to provide, never entered or invented by an agent

## File Write Protocol

All file writes (release checklists, changelogs, release notes, deployment scripts) are
delegated to sub-agents and sub-skills. The two follow **different** rules, and the
distinction matters here more than anywhere else in the pipeline:

- **Sub-agents spawned via `Agent`** follow the **bounded exception** documented above
  under "Why this does not violate the Collaboration Protocol" — the path is one you
  named, the artifact is new under `production/`, `docs/` or a test directory, and the phase
  is gated by an `AskUserQuestion`. A sub-agent does **not** prompt per write inside
  those bounds; outside them it must ask.
- **Sub-skills** are not sub-agents and the exception does not reach them. They
  follow the normal Collaboration Protocol and ask before writing.

This orchestrator writes only the go/no-go record (and appends an override justification to it with `Edit`) and its monitoring tasks; every other file is written by a sub-agent or sub-skill. Tags, deploys, bundle publication and store submissions are run by `release-manager` and `platform-lead` with their own tools after the Phase 6 yes; this skill's `allowed-tools` grant no tag, push, deploy or publish command. Nothing here authorises an
outward-facing or irreversible action — tags, pushes, builds, bundle publication,
store submissions, customer emails and status-page posts require explicit
confirmation regardless of which rule above applies.

## Output

A summary report covering: release version, scope, editions shipped and held, the feature-flag gate (flagged changes and any unflagged risky change accepted), the rollout steps taken with each trigger reading, the post-deploy verification result, quality gate results (with gates skipped by mode named), go/no-go decision, deployment status per edition, customer communication status, and monitoring plan.

Verdict: **COMPLETE** — release executed and deployed for every edition in scope, each with its rollout completed without a tripped trigger and its post-deploy verification `PASSED`.
Verdict: **PARTIAL** — some editions deployed, others held or pending store review, or an edition is deployed but its post-deploy verification is `FAILED` or `not run`; list each.
Verdict: **BLOCKED** — release halted; the stage check stopped it, go/no-go was NO, the user chose `[D] Stop here`, or a hard blocker is unresolved.
Verdict: **BLOCKED — write declined by user** — the go/no-go record write was declined; nothing is reported as COMPLETE.

## Next Steps

**Checkpoint.** Before the final message, update `production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`: Current task `/team-release <version> — <verdict>`, Next step = the first item below that applies, plus Blocked on (the unresolved blocker or held edition) / Files in progress (the release report and go/no-go record) / Open questions; append the Notes line; leave the `Flow:` line and other blocks alone. Still updated for PARTIAL, BLOCKED and a declined write.

- Monitor post-release dashboards for 48 hours.
- Run `/retrospective` if significant issues occurred during the release.
- A defect found after release: `/hotfix` for an emergency, `/post-release-fix` for a planned small fix batch.
- `project.stage` reads `Release` unless the stage check was overridden: `/gate-check release` is the Hardening → Release readiness gate, run before this skill. Only `/gate-check` changes `project.stage`, so this skill never writes it or `production/stage.txt`. Record live/post-launch status in the release report.
