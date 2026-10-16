---
name: team-hardening
description: "Orchestrate the hardening team before release — performance-engineer, appsec-engineer, accessibility-specialist, qa-tester — to measure, secure and verify a feature or area. Outputs feed SL-RELEASE-SECURITY and SRE-OPERABILITY."
argument-hint: "[feature or area to harden] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Skill, Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/hooks/yaml-helper.sh is_always_ask_category *), Bash(bash "*/.claude/skills/team-hardening/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
# Team Hardening

If no argument is provided, output usage guidance and exit without spawning any agents:
> Usage: `/team-hardening [feature or area to harden] [--review full|lean|solo]` — specify the feature or area to harden before release (e.g., `billing`, `workspace invitations`, `reports export`, `self-hosted installer`). Do not use `AskUserQuestion` here; output the guidance directly.

When this skill is invoked with an argument, orchestrate the hardening team through a structured pipeline.

Hardening is the pass between "the stories are done" and "this can ship": the
budgets are measured, the security evidence exists, the interface is accessible
in both languages, and the edge cases and regressions have been tried on a
running stack. It is the producer of the evidence that `SL-RELEASE-SECURITY` and
`SRE-OPERABILITY` read at the Hardening → Release gate. It does not issue those
verdicts.

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

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,workflow,qa.level,testing.strict,performance.enforce,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

`review_mode` sets director-gate depth, and this pipeline has no director gate:
no phase below spawns a PD-, CTO-, PR- or DD-PHASE-GATE, and it does not spawn
`SL-RELEASE-SECURITY` or `SRE-OPERABILITY` — those run from `/gate-check`,
`/release-checklist` and `/team-release` and **consume** this pipeline's outputs.
Its phase gates are the pipeline's own decision points (defined under
`team.size` below), and the agents that work at them are team members, not
director gates. A skipped or lean-mode gate elsewhere waives the director's
opinion, never this evidence.

`automation` drives the Decision Points note above. See the Decision Points note
above and `.claude/docs/automation-modes.md` for how each mode changes pipeline
behaviour.

`performance.enforce` (above: `warn` | `block` | `off`) decides whether a missed
budget blocks the sign-off or is reported as a warning (DoD gate 6).
`testing.strict.*` decides the same for the security, performance and UI evidence
gates; `unset` means each story type's default in `coding-standards.md`.

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`** (default): `performance-engineer` + `appsec-engineer`. Other agents consulted via these two, not spawned separately. No stack lead is active, so the findings list's implementation items outside these two agents' remit are not implemented in this run — the report names the list as handed to `/dev-story` (Phase 2).
- **`small`**: + `accessibility-specialist` + `qa-tester` + the stack lead(s) for the layer(s) a finding lands in (`go-lead`, `ktor-lead`, `web-lead`, `android-lead`, `ios-lead`, routed by `principal-engineer`). A penetration test is never spawned here (below).
- **`studio`**: the `small` set + an adversarial review pass: Phase 5's `qa-tester` is told "your job is not to confirm this holds — find how it breaks", and the report says the pass ran.

**Penetration test.** This skill **never spawns `penetration-tester`** and `security-lead`
cannot spawn it either. A pentest runs only through the user-typed `/pentest`, which
refuses without an approved written scope, a named approver the user confirms in chat, a host
allowlist and a window. Ask the user whether a pentest is wanted for this release; if yes,
tell them to run `/pentest <scope>` themselves (a staging or isolated stack, never production)
and to bring the report back (`production/qa/evidence/pentest-*/pentest-report.md`), which this
run then reads as an input. No report: record `Penetration test: not run - /pentest not
executed` in the report. That is not clean.

A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists** — a transition under Decision Points above, or a **Gate** step written into the pipeline below — **whatever the `automation` mode.** `guided` and `autonomous` change how a gate is passed (it auto-advances, or is recorded with `log_decision`), not whether it is one, so bounded-exception condition (3) below holds at it in every mode. An agent restricted to "phase gates only" is spawned at those points and no others. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

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
is two agents. **The collapse is correct**: `team.size` is rigor-fronted and the
narrow default is the token lever. Without saying so, a reader cannot distinguish
a correctly-collapsed run from a broken pipeline, and the per-agent "routes
through the nearest core agent with an informational note" rule fires at routing
time and never states the shape of the run as a whole.

This is the same rule as the skipped-check reporting elsewhere in this file: **a
constraint that is enforced but never surfaced is indistinguishable, to the
person reading the output, from one that was never enforced.**

## Team Composition
- **performance-engineer** — Profiling, load tests (k6) against budgets, query and allocation optimisation, capacity headroom, and the optimisation list
- **appsec-engineer** — Secure code review of the area, dependency/SAST/secret scans, negative tests (authz bypass, cross-tenant, injection), ASVS/MASVS control mapping, vulnerability triage
- **accessibility-specialist** — WCAG conformance, screen readers (web, TalkBack, VoiceOver), keyboard, contrast, motion, Arabic/RTL accessibility
- **qa-tester** — Edge cases, regression, soak and stress verification; Arabic and English passes; evidence capture
- **stack lead** — `go-lead` / `ktor-lead` / `web-lead` / `android-lead` / `ios-lead`: implements findings in code outside the performance-engineer's and appsec-engineer's own remit

## How to Delegate

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: performance-engineer` — Profiling, load tests, optimisation list and fixes
- `subagent_type: appsec-engineer` — Security review, scans, negative tests, control mapping
- `subagent_type: accessibility-specialist` — Accessibility audit
- `subagent_type: qa-tester` — Edge case, regression and soak verification
- `subagent_type: go-lead` / `ktor-lead` / `web-lead` / `android-lead` / `ios-lead` — Fixes in the owning layer

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session. **Implementation files are the exception:** an agent writing code or assets first returns the files it will create or change, and its return contract names them only after you have asked once for the set and the user said yes (File Write Protocol) — that answer, not the bounded exception, authorises those writes.

**Substitute a real path for `[path]` — this skill's destination is
`production/hardening/`.** Name it per agent, one file each:

| Agent | Writes to |
|---|---|
| performance-engineer | `production/hardening/[area]-performance-[date].md` |
| appsec-engineer | `production/hardening/[area]-security-[date].md` |
| accessibility-specialist | `production/hardening/[area]-accessibility-[date].md` |
| stack lead(s) | `production/hardening/[area]-fixes-[layer]-[date].md` |
| qa-tester | `production/hardening/[area]-verification-[date].md` |

Raw artefacts (load-test output, scanner output with secrets redacted, screenshots,
request/response transcripts) go to `production/qa/evidence/hardening-[area]-[date]/`
— the same place `/security-audit`, `/load-test` and `/story-done` read. Never
write a secret value into any file.

> **Why `production/` and not `docs/`.** These are date-stamped measurements of
> one run, the same shape as `production/qa/smoke-[date].md` — not durable
> specifications like `docs/architecture/`. Keeping them beside the other
> point-in-time process artefacts is what makes a later comparison possible.
> The `[path]` contract above has a precondition: the path is one *you* named, so
> a concrete destination must be stated here or every run invents one.
> **No gate reads `production/hardening/` automatically** — `SL-RELEASE-SECURITY`
> and `SRE-OPERABILITY` receive these files because the skill that spawns them
> (`/gate-check`, `/release-checklist`, `/team-release`) passes them as context.
> Say so when reporting, so the user knows the report is an input to be handed on,
> not something a gate finds by itself.

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or a test directory, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.

Launch independent agents in parallel where the pipeline allows it (e.g., Phases 1, 3 and 4 inputs can be gathered simultaneously) — issue every independent `Agent` call before waiting for any result, collect all results, and surface any BLOCKED agent immediately (`.claude/docs/coordination-rules.md`, Parallel Task Protocol).

**Environment boundary.** Everything runs on the local dev stack with seeded test
tenants, or an isolated staging stack the user names
(`.claude/docs/run-and-observe.md`). Never production, never real customer data,
and never a command that deletes volumes (`down -v`, volume rm, prune).

## Pipeline

### Phase 1: Assessment (parallel)
Delegate in parallel:

**performance-engineer**:
- Profile the target area using `/perf-profile` against `docs/architecture/perf-budgets.md`; load-test hot paths with `/load-test` (ramp, steady, spike) on a stack with realistic data volume
- Identify budget violations: p95 latency, queries per request (no N+1), payload size, job runtime, web bundle size / Web Vitals, mobile start-up and jank
- Measure memory and connection-pool behaviour, headroom (30% memory), and the first resource to saturate
- Output: performance report with the prioritised **optimisation list** — for each item, the change, its expected gain against the budget, and its owner (the stack lead for the layer; `data-lead` / `postgres-specialist` for query and index changes)

**appsec-engineer**:
- Review the area's code against ASVS (backend/web) and MASVS (mobile) controls; map each control to a story, a test and an evidence path — requirement IDs looked up in the standards pinned in `.claude/docs/security-baseline.md`, never recalled
- Run the scans the baseline names on this commit — dependency scan, container image scan, secret scan, SAST — with tool, version and scope recorded. **A scan that did not run is reported as not run, never as clean.** An absent tool is `NOT RUN — [tool] not available`; the verdict follows
- Write and run the negative tests: authz bypass (object-level and function-level), **cross-tenant read/write**, injection, rate-limit and abuse paths, webhook/SSRF, upload handling, licence bypass for self-hosted code
- Check that threat models exist for sensitive features in scope (auth, billing, uploads, PII) and that every mitigation has a passing negative test
- Output: security report with the control-mapping table, scan table, findings `[CRITICAL|HIGH|MEDIUM|LOW] path:line — problem → fix (control ID)` and a vulnerability-register proposal (owner, SLA by severity per the baseline). Never print a secret value

A penetration test is the user's `/pentest <scope>`, run outside this pipeline (see the Penetration test paragraph above). If a `/pentest` report already exists for this area, read it as an input to the findings list; this pipeline does not start one.

### Phase 2: Fixes
Neither assessor edits product code outside its own remit without the owner, so Phase 2 implements the Phase 1 lists through the owners in the active set:
- **performance-engineer** — query, allocation and caching fixes within its remit (with `data-lead`/`cache-specialist` consulted for schema and cache decisions; a cache change carries a written cache decision, DoD gate 5)
- **appsec-engineer** — security fixes within its remit (validation, headers, rate limits, secret handling)
- **stack lead(s)** — spawned only when a finding lands in a layer outside those remits (domain logic, UI, contract changes): implement the items, with a regression test per finding that fails before and passes after

Every implementing agent in Phases 2–4 first returns the files it will create or change, and you ask once for the whole Phase 2–4 set before any is edited (File Write Protocol).

**An item whose owner is not in the active set is not implemented in this run.** At `team.size: individual` that is every item owned by a stack lead; at any size it includes an item owned by a specialist this pipeline does not name. The report lists those items with their owners under "Findings list handed to `/dev-story`: `production/hardening/[area]-…-[date].md`". A finding that is over budget or CRITICAL/HIGH stays a known problem at Phase 6.

Fixes stay minimal and inside the area. Schema changes follow `.claude/rules/migrations.md` (expand → migrate → contract) and are reviewed by `migration-specialist`; contract changes go through `api-designer`. A fix for a vulnerability in released code is a `/hotfix` candidate, not a Phase 2 item — say so.

### Phase 3: Accessibility and Localization Audit (parallel with Phase 2)
Delegate to **accessibility-specialist**:
- Verify compliance against the committed target in `design/accessibility-requirements.md`. **If that file is absent there is no committed target, so this check has no criterion: report `Accessibility: NOT ASSESSED — no committed target (design/accessibility-requirements.md absent)` and do NOT report it as passed.**
- Keyboard-only operation and focus order (web, in RTL too), screen readers (web, TalkBack, VoiceOver as applicable), contrast, touch targets, reduced motion, text scaling / Dynamic Type, error and status announcements
- Arabic/RTL accessibility: reading order, mirrored layouts, mixed-direction text, Arabic labels for assistive tech
- Run `/impeccable audit` on the web surfaces and read its result; native audits per impeccable's references
- Output: findings with WCAG success-criterion references (looked up against the W3C text) and severities. At `individual` size the accessibility-specialist is not spawned: record `Accessibility review: not run (team.size: individual)` and report accessibility as NOT ASSESSED

### Phase 4: Operability Inputs (parallel with Phase 2)
`performance-engineer` (or, at `individual`, the same agent in a second brief) compiles the operability evidence that `SRE-OPERABILITY` reads, **for the area in scope only**:
- Load-test results against budgets with environment and data volume; capacity notes; resource limits and pool settings observed
- Retained trace screenshot per critical journey (handler → use case → DB/cache), RED metrics present, `trace_id` in logs, no PII in telemetry — verified on the running stack
- Anything it could not verify (backups and restore drill, rollback rehearsal, alert/runbook coverage, self-hosted upgrade path) is listed as **not covered by this pass** — those belong to `platform-lead`/`sre-lead` and the release checklist, and are never implied clean by silence
- Output: operability inputs section appended to the performance report

### Phase 5: Verification
Delegate to **qa-tester**:
- Test all edge cases: boundary values, empty/large inputs, concurrent edits, retries and duplicate submissions (idempotency), expired sessions and tokens, plan limits and quota boundaries
- **Negative paths**: wrong role, other tenant, invalid input — exercised on the running stack, not only in tests
- Soak test: run the area under sustained load for extended periods checking for degradation (leaks, queue growth, pool exhaustion); use `/load-test`'s protocol
- Regression test: verify the Phase 2 changes haven't broken existing behaviour — each change by name
- Arabic (RTL) and English passes on every user-visible change; desktop and mobile widths; relevant devices/emulators
- Self-hosted: if the area ships in the bundle, a clean-host install and upgrade check (`/smoke-check --surface self-hosted`)
- Output: test results with any remaining issues, evidence retained under `production/qa/evidence/hardening-[area]-[date]/`

### Phase 6: Sign-off
- Collect results from all team members
- Compare performance metrics against `docs/architecture/perf-budgets.md`; compare security evidence to the DoD gate 7 floor
- Report: READY FOR RELEASE / NOT ASSESSED / NEEDS MORE WORK
- List every remaining issue with its severity (S1–S4 or CRITICAL–LOW for security findings), the measured gap where there is one (e.g. "p95 480 ms against a 300 ms budget — 180 ms over"), and a recommendation; a regression also names the broken behaviour and the change that caused it
- **Hand-off block** — state exactly what this run contributes to each release-readiness gate, so the person running `/gate-check` or `/release-checklist` can pass it as context:
  - **For `SL-RELEASE-SECURITY`**: path of the security report (control mapping, scan table with tool/version/scope/result or "not run", findings, register proposal), the pentest report if one ran, the negative-test evidence folder. Controls with no evidence and scans that did not run are listed by name
  - **For `SRE-OPERABILITY`**: path of the performance report's operability inputs, the load-test and trace evidence, and the explicit list of checks this run did **not** cover
  Nothing in this block is a gate verdict.

**NOT ASSESSED ranks above READY FOR RELEASE and below NEEDS MORE WORK.** A known
problem — a CRITICAL or HIGH security finding open, a metric over budget with `performance.enforce: block`, a CRITICAL/HIGH vulnerability not formally accepted, an unresolved regression, a cross-tenant exposure — makes it NEEDS MORE WORK whatever else went unchecked. (A metric over budget at `performance.enforce: warn` is reported as a warning and named in the report.) Otherwise, if any part of the scope could not be checked, the result is NOT ASSESSED, never READY FOR RELEASE, and the report names each gap:
- A metric with no committed budget (`docs/architecture/perf-budgets.md` absent or its product-budget column unfilled): nothing was compared, so no budget was met. `/perf-profile` reports it as NOT ASSESSED
- A scan, test suite or tool that could not run; a control with no evidence path
- A phase that did not run: BLOCKED, skipped, or its agent outside the active set. At `team.size: individual`, accessibility review and the qa-tester verification are only consulted through the active agents, not run, and stack-lead items are handed to `/dev-story` rather than implemented
- A pentest wanted for this release that has no `/pentest` report
- `design/accessibility-requirements.md` absent

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
partial report.** A skipped agent's section stays a named gap — never fill it with content of your own. Full procedure: `.claude/docs/error-recovery-protocol.md`.

Common blockers:
- Input file missing (story not found, spec absent, no budgets, no threat model) → redirect to the skill that creates it (`/perf-profile` creates `perf-budgets.md` if missing; `/threat-model`)
- ADR status is Proposed → do not implement; once it is decided, accept it with `/architecture-decision accept ADR-NNNN`
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess
- The user wants a pentest → this skill does not run it: tell them to run `/pentest <scope>`; report it as not run until a report exists
- A suspected cross-tenant exposure or exposed secret → tell the user immediately in conversation (S1), do not wait for the end-of-run report; a live exposure is `/hotfix` territory

## File Write Protocol

All file writes (performance reports, security reports, test results, evidence docs) are delegated to
sub-agents spawned via `Agent`. Those writes follow the **bounded exception**
documented above under "Why this does not violate the Collaboration Protocol" —
the path is one you named, the artifact is new under `production/`, `docs/` or a
test directory, and the phase is gated by an `AskUserQuestion`. A sub-agent does
**not** prompt per write inside those bounds; outside them it must ask. The fixes
of Phase 2 edit existing code, configuration or assets, so they are outside those
bounds: each implementing agent returns the files it will create or change, you
ask once for the whole Phase 2–4 set ("May I have [agents] change these [N]
files?"), and each edits only after a yes — one ask for the set, not one per
phase. This orchestrator does not write files directly.

## Output

A summary report covering: performance before/after metrics against budgets, security evidence (control mapping coverage, scans run and not run, findings by severity, pentest status), accessibility and Arabic/English results, test results, any findings list handed to `/dev-story`, the hand-off block for `SL-RELEASE-SECURITY` and `SRE-OPERABILITY`, and the release readiness assessment.

The **assessment** (READY FOR RELEASE / NOT ASSESSED / NEEDS MORE WORK) is the hardening result; the pipeline ends in one of these orchestrator verdicts:

Verdict: **COMPLETE** — every phase in the active set ran; the assessment above is the result.
Verdict: **COMPLETE WITH GAPS** — the pipeline ran to Phase 6 but a phase, scan or agent outside the active set did not run; each gap is named and the assessment cannot be READY FOR RELEASE.
Verdict: **BLOCKED** — the pipeline halted (an agent BLOCKED, a missing prerequisite, a stop condition such as a live exposure sent to `/hotfix`); the partial report lists the phases that ran and the one that stopped.
Verdict: **BLOCKED — write declined by user** — the user declined the Phase 2–4 file-change set or a report write; nothing is reported as COMPLETE.

## Next Steps

**Checkpoint.** Before the final message, update `production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`: Current task `/team-hardening <scope> — <verdict>`, Next step = the first item below that matches the verdict, plus Blocked on (what NOT ASSESSED or NEEDS MORE WORK is waiting for) / Files in progress / Open questions; append the Notes line; leave the `Flow:` line and other blocks alone. Still updated for BLOCKED and a declined write.

- If READY FOR RELEASE: run `/release-checklist` and `/gate-check release` for the formal Hardening → Release verdicts; pass them the hand-off block's paths.
- If NEEDS MORE WORK: schedule the remaining issues in `/sprint-plan update` (at `workflow: minimal`, which has no sprints, add them to the product brief's build order) and re-run `/team-hardening` after fixes.
- If NOT ASSESSED: supply what was missing — commit the product budgets in `docs/architecture/perf-budgets.md`, commit `design/accessibility-requirements.md` (`/ux-design accessibility`), install or run the missing scan, or run the phases that did not run (raise `team.size`) — then re-run `/team-hardening`. Do not treat the area as release-ready.
- If the report handed a findings list to `/dev-story`: implement those items there, then re-run `/team-hardening` to measure the gain.
- A live exposure or an exploited vulnerability found here: stop and use `/hotfix`.
