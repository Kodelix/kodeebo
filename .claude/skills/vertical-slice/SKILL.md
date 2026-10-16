---
name: vertical-slice
description: "Pre-production validation — a thin end-to-end slice (DB, API contract, web/mobile, compose deploy with healthchecks, telemetry) proving the architecture and the core journey. PROCEED/PIVOT/KILL/NOT ASSESSED."
argument-hint: "[--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/vertical-slice/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(docker compose -f prototypes/*/compose.yaml up -d --wait), Bash(docker compose -f prototypes/*/compose.yaml ps), Bash(docker compose -f prototypes/*/compose.yaml ps *), Bash(docker compose -f prototypes/*/compose.yaml logs *), Bash(docker compose -f prototypes/*/compose.yaml down), Bash(docker compose ps), Bash(docker compose ps *), Bash(docker compose logs *), Bash(docker compose up -d --wait), Bash(date *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,stack`

Resolved above — use as-is; `--review` overrides `review_mode` for this run. No
block → defaults in `.claude/docs/config-resolution.md`.

# Vertical Slice

## Purpose

The **vertical slice** answers a different question from the concept prototype:
*"Can a user complete the core journey on a real, deployed stack — and does the
architecture hold — at a quality and speed we can sustain?"*

**Default use** — run late in Pre-Production, after specs, architecture, UX specs
and the control manifest are complete. It is a near-production-quality, **thin
end-to-end build through every configured layer** demonstrating one complete
[start → core action → result] journey:

```
DB (schema + migration + tenancy) → API / contract → web and/or mobile
→ deploy on compose with healthchecks → telemetry visible (one trace, client to DB)
```

It validates:

1. **The architecture** — tenancy isolation, auth flow, ports/adapters layering, the billing/entitlement hook, observability, and the deploy topology all hold when wired together for real (hosted; self-hosted too when in scope)
2. **The pipeline** — the team can produce this quality (CI-shaped checks, contract-first flow, generated clients, evidence capture)
3. **Value survival** — the value seen in the concept prototype survives full design: an ICP user completes the journey unguided
4. **Velocity** — how long it took is your real production-rate estimate

**Earlier in the project?** If specs are not written and you want to know whether
the idea is worth designing, run `/prototype` instead.

**Post-pivot?** If a PIVOT verdict sent you back to revise specs and ADRs, run
this again after the revisions. It can be run until PROCEED or KILL.

**The slice is reference material, not production code**: it lives in
`prototypes/[product-name]-vertical-slice/`, follows `.claude/rules/prototype-code.md`
in spirit and *adds* the quality bar below. It is never refactored into a code
root; production is rewritten from the control manifest using the slice as a design
reference. Security still applies: no real secrets, no real customer data, nothing
exposed on a public port, nothing deployed to a public host.

> **A check that did not run is reported as `not run`.** A slice that was not
> deployed, not observed end to end, or whose cross-tenant test did not execute
> cannot report those rows as PASS — the Architecture Validation table says
> `NOT RUN — [reason]` and the verdict stays at best `NOT ASSESSED`
> (`.claude/rules/skill-authoring.md`).

---

## Phase 1: Resolve Review Mode and Load Context

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

Read the following to understand the full design intent:
- `CLAUDE.md` and the `stack` line above (`backend`, `web`, `site`, `mobile`, `deploy`, `distribution`, `tenancy`) — **an `unset` layer that the journey needs is a STOP**: `/setup-stack` first; never default it
- `design/product-brief.md` — the ICP, core value, core journey and pricing model (the one-page brief at `rigor: minimal`)
- `design/specs/domain-map.md` — the MVP features and their priorities (absent at `minimal`; the brief stands in)
- `docs/architecture/architecture.md` — contexts, ports, data stores, tenancy, deployment (hosted and self-hosted)
- `docs/architecture/control-manifest.md` — technical rules for implementation
- Key feature specs for the journey, the relevant ADRs, `docs/architecture/perf-budgets.md`
- `docs/stack-reference/<layer>/` for every layer in the slice, and `docs/stack-reference/pins.yaml`; research notes in `docs/research/` for the providers involved. **An API not in the stack reference is looked up (`/research`), never written from memory.** A layer whose reference is missing is reported `NOT ASSESSED — no stack reference` in the validation table.
- `resolve_code_root` (`bash .claude/hooks/yaml-helper.sh resolve_code_root`) — the layers that exist; the slice includes every layer the journey crosses

---

## Phase 2: Define the Slice Scope and Validation Question

Before building, define the **falsifiable validation question**:

> *"Can a new tenant admin, starting from nothing, complete [core journey from the brief] within [N] minutes, unguided — and does the architecture (tenancy, auth, billing hook, deploy) hold at representative quality, buildable in [X] days?"*

Both parts matter: the **user outcome** and **build feasibility**.

**Scope discipline:**
- Include every layer the core journey crosses (minimum): schema + migration, the contract operation(s) and generated client, the backend context (domain/app/adapters), the web and/or mobile screens, auth, the entitlement/billing check if the journey touches a paid feature, and the compose deploy.
- **Target scope: one core journey completable in 3–5 minutes.** Long enough to exercise the architecture, short enough to build at representative quality. Cut features, not quality.
- **Cut scope before cutting quality.** A slice that ignores tenancy, observability or the deploy cannot validate the architecture.
- If the scope feels too large for 1–3 weeks, the slice is trying to prove too much at once.

**Scope creep warning:** the slice is the highest-risk moment for scope creep in
Pre-Production. "Just one more screen" is how a 2-week slice becomes 6. Cut, do not extend.

Present scope to the user before building and get confirmation.

---

## Phase 3: Plan the Build

Define in bullet points:
- Features/contexts implemented (which spec sections are exercised) and the ports/adapters each adds
- The journey cycle exactly ([start] → [core action] → [result])
- The layers included, in contract-first order: contract → data → backend → clients → deploy
- Quality level (Placeholder / Representative / Near-shipping) per layer
- **Architecture checks to run** (each becomes a row of the validation table, with the command or procedure that produces its evidence):
  1. Cross-tenant negative test (tenant A cannot read/list/update tenant B's data) against the real database
  2. Auth/session flow works across web and mobile (if both are in scope)
  3. One trace spans client → API → DB/cache, `trace_id` in the structured log line, no PII in attributes
  4. Performance of the slice's endpoints against `perf-budgets.md` rows (or `budget not yet set`)
  5. Clean-architecture rules respected (domain imports grep)
  6. Fresh `docker compose up -d --wait` from a clean volume reaches a working journey, all healthchecks green
  7. Self-hosted topology viable (when `distribution.model` is `self-hosted` or `hybrid`): the bundle runs on the licence-clean engine set of `.claude/rules/deploy.md` (Valkey, OTel Collector only), preflight and backup/restore steps are real
- Specific, measurable success criteria for the validation question (journey time, tester count)
- Hard time limit: [X] days. If exceeded, scope was wrong — stop and reassess.

Ask the user to confirm the plan before building. Name the checkpoint file in that
confirmation: "May I record this plan in `production/session-state/active.md`?"
If the user declines the plan, nothing is built: stop with
`NOT ASSESSED — slice plan not approved` and the reason they give.

Once confirmed, write a session checkpoint to `production/session-state/active.md`
(create `production/session-state/` if it does not exist) in the `<!-- CHECKPOINT -->`
format of `.claude/docs/templates/session-state.md` — overwrite the block, never
append. Include: product name, validation question, layers in scope, quality level,
and current phase ("Phase 4 — Implement"). Update it at the end of each build day with
what was completed. This is the primary recovery mechanism if the session ends
mid-slice — multi-week builds span many sessions.

---

## Phase 4: Implement

Ask: "May I create the vertical slice directory at
`prototypes/[product-name]-vertical-slice/` and begin implementation?"

If the user declines, create nothing and stop with
`NOT ASSESSED — slice directory declined by user`: nothing was built, so
nothing was validated.

If yes, create the directory and its `README.md` first (what is being validated,
how to bring it up, status, findings when done — required by `prototype-code.md`).
Every code file must begin with:

```
[comment] VERTICAL SLICE - NOT FOR PRODUCTION
[comment] Validation Question: [What this build is proving]
[comment] Date: [Current date]
```

Write `[comment]` in each file's own comment syntax — `//` in Go, Kotlin, Swift and
JavaScript/TypeScript, `#` in Python, shell, YAML and Dockerfiles, `--` in SQL,
`<!-- … -->` in HTML and Markdown. A header in another language's syntax is a
parse error, not a label. Files that cannot hold a comment (JSON, lockfiles,
generated files) are exempt.

**Route the build through the owners** — spawn `principal-engineer` via `Agent`
(or, for a single-lane slice, the lead directly) and have it delegate per lane,
exactly as `/dev-story` routes (its Phase 3 lane table): `api-designer` (contract first — nothing downstream starts before it
exists), `data-lead` (schema, migration with `tenant_id` + RLS per `tenancy.model`),
`go-lead` or `ktor-lead` (backend), `web-lead`, `android-lead`/`ios-lead`/
`kmp-specialist` (mobile), `platform-lead` with `infra-engineer` (compose, healthchecks,
OTel collector), `ui-designer` through `/impeccable` for screens. Brief with file
paths, the control manifest, the stack reference paths and the quality bar below.

**Quality standards** — higher than a concept prototype, not full production:
- Follow the architecture layers and the control manifest: `domain`/`app`/`adapters`, ports declared by the consumer, wiring only in the composition root
- Contract first: operations in `contracts/`-shaped OpenAPI inside the slice; clients **generated** from it, not hand-written
- Every query tenant-scoped, tenant from the authenticated context; RLS (or the chosen `tenancy.model` mechanism) on new tables
- **No hardcoded business values** — plan limits, prices, TTLs from config or catalogue (seeded)
- Errors as RFC 9457 problem details at the HTTP edge; basic error handling on critical paths
- Spans on handler/use case/DB, RED metrics, structured logs with `trace_id`; `/livez` and `/readyz`
- Fakes allowed for what the journey does not depend on (the payment provider → its **sandbox** or a stub behind the real port; email → mock SMTP); seeded data from a `seed` script with a dedicated test tenant — never real customer data
- Compose: every service has a `healthcheck`, restart policy, explicit networks, databases not published on host ports, migrations as a one-shot service before the API; `.env.example` with no values; secrets outside the repo (`.claude/rules/deploy.md`)
- Placeholder visual design acceptable; representative preferred. Screens must still be keyboard-usable and handle loading/empty/error states, and the journey must be exercised in **English and Arabic (RTL)** if both ship

**Multi-turn loop:** after writing the initial files, ask the user to bring the
stack up and run the journey; iterate on errors and observations until the whole
cycle is demonstrable on `docker compose up -d --wait`. Each round: user runs →
reports errors or observations → agent fixes → repeat.

```bash
docker compose -f prototypes/[product-name]-vertical-slice/compose.yaml up -d --wait
```
`--wait` blocks until every healthcheck passes; a service that never becomes healthy
**is the finding** — capture `docker compose logs <svc>`. Never `down -v` unless the
user asks for a clean slate. If no container runtime is available the deploy row is
`NOT RUN — container runtime unavailable` and the slice cannot be PROCEED.

**Sunk-cost checkpoint (day 3 of the planned timeline):** if the journey is not yet
demonstrable end to end, stop and reassess — either the scope is too large or an
architectural assumption is wrong. Surface the blocker rather than continuing to iterate.

**Run the architecture checks** (Phase 3 list) as soon as the journey works — the test runs, `curl` calls, k6 and screenshot steps are executed by the lane leads (`go-lead`/`ktor-lead`, `web-lead`, `qa-tester`) spawned via `Agent`, or by the user; this skill holds only the compose grants above (`up -d --wait`, `ps`, `logs`, `down` without `-v`) — and keep
the **raw output** with the slice: test output, `curl` request/response as each actor
(owner, member, other tenant, anonymous), the trace screenshot or span export, k6 or
timing numbers with data volume, `docker compose ps` showing healthy. Evidence goes
in `prototypes/[product-name]-vertical-slice/evidence/` — a check described but not
saved is not evidence. A check that could not run is recorded `NOT RUN — [reason]`.

Conduct at least 1 usability session once the journey is demonstrable.

**Usability session tips:** watch an ICP member who has not seen the product, silently,
without explaining anything — their confusion reveals what the product is not
communicating. Ask them to think aloud for richer data. No external testers? Rotate
inside the team (the builder of screen X is a naive tester for screen Y); solo → step
away 2–3 days, then do a silent walkthrough logging every hesitation. A recorded
screen-share (Loom/OBS) gives async first-impression data across time zones.
**Wizard of Oz:** for behaviour not yet implemented (matching, recommendations,
automation), one person simulates it by hand behind the real UI — say so in the report.

---

## Phase 5: Usability Debrief

The journey is demonstrable. Before writing the report, collect structured
observations. Do NOT skip to report generation — the report is only as good as the
observations captured here.

Say exactly this:
> "Complete the whole [start → core action → result] journey from a fresh tenant, as
> a new user with no knowledge of how it was built. Don't skip ahead or use developer
> shortcuts. Come back when you've finished — or when something stopped you."

Once the user returns, ask these questions **one at a time**:

1. **Journey completion:**
   > "Did you complete the whole journey on your own, without guidance from me or prior knowledge of the build?"

2. **Time to first value:**
   > "How long did it take to reach the first moment of real value — the first time it did something useful for you?"

3. **Core value:**
   > "The product is supposed to give the ICP [core value from the brief]. Did it? Be specific about what you saw and when — not 'kind of'."

4. **Blockers:**
   > "What stopped you, confused you, or broke? Any moment you weren't sure what to do?"

5. **Architecture and pipeline check (as the builder):**
   > "Did the architecture hold — tenancy, auth, the deploy, the telemetry? What surprised you about how long things took to build? Does this look achievable at this quality for the full product?"

6. **Verdict:**
   > "PROCEED, PIVOT, or KILL — and the specific reason."

If any answer is vague, ask: "Can you give me the specific moment where that happened?"

**PROCEED is not available when a validation item is NO.** `/gate-check` FAILs a
built slice with a NO in its validation: a user finished the journey without
developer guidance (question 1), reached first value within the target time
(question 2), the core value landed (question 3), no critical blocker (question 4),
**and no Architecture Validation row is FAIL**. Any NO or FAIL means the verdict is
PIVOT or KILL — the user chooses — and the report names it.

**NOT ASSESSED is the fourth verdict.** It applies when:
- nobody from the ICP has used the journey unguided (the user cannot run a session this time, or stopped early), **or**
- any Architecture Validation row is `NOT RUN` (the stack was not deployed, the cross-tenant test did not execute, no trace was captured) — the architecture was not validated.

The reason is named. It ranks above PROCEED and below PIVOT and KILL: an unvalidated
slice has not earned PROCEED, and a slice known to fail is more actionable than one
nobody ran. It is never recorded as PROCEED.

---

## Phase 6: Generate Vertical Slice Report

Track velocity throughout the build. Log, per day, what was built. This is the most
honest data you will ever have about your production rate; it feeds sprint planning
(at `workflow: minimal`, which has no sprints, the brief's build order).

Read `.claude/docs/templates/vertical-slice-report.md` to get the report structure.
Fill in every section based on what was observed and built. If the template file
is not found, use this fallback structure: Validation Question · Scope Built ·
Build Velocity Log · Architecture Validation (table with evidence path or
`NOT RUN — reason`) · Usability Results · Observations · Metrics · Recommendation
(PROCEED / PIVOT / KILL / NOT ASSESSED) · If Proceeding / Pivoting / Killing ·
Lessons Learned.

The Architecture Validation table must carry, per row, **PASS / FAIL / NOT RUN** and
the evidence file; a PASS without an evidence path is written `NOT RUN`. The
velocity log must reflect actual day-by-day progress, not estimates. The
recommendation carries the Phase 5 verdict, NOT ASSESSED included, with its reason.

Ask: "May I write this report to
`prototypes/[product-name]-vertical-slice/REPORT.md` and add its row to
`prototypes/index.md`?"

If yes, write the file. Then update `prototypes/index.md` (create if it does not
exist) — append one row to the vertical slice table: product name, date, verdict,
and a link to the REPORT.md. Note whether this was a first-run slice or a re-run
after a PIVOT. If the user declines the write, the Phase 5 verdict (PROCEED / PIVOT / KILL / NOT ASSESSED) stands in conversation as given, stated with `report not written — write declined by user`, and the slice is not offered to `/gate-check` on the strength of an unwritten report.

---

## Phase 7: Product Director and CTO Review

**Review mode check:**
- `solo` → skip both. Note: "PD-USABILITY skipped — Solo mode." / "CTO-ARCHITECTURE skipped — Solo mode."
- `lean` → skip (not PHASE-GATEs). Note the same with "Lean mode."
- `full` → spawn both **in parallel** (issue both `Agent` calls before waiting):
  - `product-director` via gate **PD-USABILITY** (`.claude/docs/director-gates/pd-usability.md`) — unless the slice's verdict is NOT ASSESSED for want of any user session: with no session there is nothing to review; note "PD-USABILITY skipped — no unguided session yet." Pass the full REPORT.md, the validation question, the principles and core value from the brief, the participant profile versus the ICP.
  - `cto` via gate **CTO-ARCHITECTURE** (`.claude/docs/director-gates/cto-architecture.md`) — pass REPORT.md's Architecture Validation table and evidence paths, `docs/architecture/architecture.md`, the ADRs, `tenancy.model` and `distribution.model`. A NOT RUN row stays NOT RUN in what the director is told.

Each returns APPROVE, CONCERNS or REJECT (or NOT ASSESSED). Apply them to the
recommendation by the strictest-wins rule in `director-gates.md`:

- **APPROVE** → the recommendation stands.
- **CONCERNS** → show the concerns alongside the recommendation, then use `AskUserQuestion`: `Revise the recommendation` / `Accept with noted concerns` / `Discuss further`. The user decides; the directors do not.
- **REJECT** (core value not present, or the architecture does not hold) → a PROCEED recommendation cannot stand. Ask the user to choose `PIVOT` or `KILL` and run Phase 8 for that choice. A PIVOT or KILL recommendation stands.
- **NOT ASSESSED [missing input]** → the director made no judgement, so it neither backs nor overturns the recommendation: name what was missing, then supply it and re-run the gate, or record `[GATE-ID]: NOT ASSESSED — [input]` in the report.

When a director returned CONCERNS, REJECT or NOT ASSESSED, ask "May I update
`prototypes/[product-name]-vertical-slice/REPORT.md` and its `prototypes/index.md`
row?", then record each verdict and reason in REPORT.md, and the final
recommendation in both if it changed.

---

## Phase 8: Summary and Next Steps

Output a summary: the validation question, velocity data, the Architecture
Validation table (PASS / FAIL / NOT RUN counts) and the final recommendation. Link to
`prototypes/[product-name]-vertical-slice/REPORT.md`.

**Checkpoint.** Before the final message, update
`production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`:
Current task `/vertical-slice <product> — <PROCEED / PIVOT / KILL / NOT ASSESSED>`,
Next step = the first recommended next step of the branch below (for NOT ASSESSED,
the session or architecture check to finish), plus Blocked on / Files in progress
(the slice, `REPORT.md`, the index row) / Open questions; append the Notes line.
Still updated when the run ends early (plan not approved, write declined).

**If PROCEED:**
The slice validated the journey and the architecture. The project is ready for Production.

At `workflow: minimal`: `/create-stories` (from the brief), then `/dev-story` on the
first story — the rest of this list is the `standard`/`full` path. Research notes,
threat models for sensitive features, and the eight DoD gates apply at every tier.

Recommended next steps (`standard`/`full`):
- `/create-epics` — plan epics per context and layer (foundation first)
- `/create-stories [epic-slug]` — break each epic into implementable stories
- `/sprint-plan` — plan the first sprint using velocity data from the slice
- `/gate-check` — formally advance the stage to Production

**Production requirements** the report lists (what must change from slice to
production — real provider integration, rate limits, audit log, backups with a
restore drill, SLOs and alerts) become stories, not footnotes. **Usability note:**
`/gate-check` looks for documented evidence — at minimum 1 documented unguided
session with a REPORT.md showing PROCEED; 3+ is recommended before committing the
team to Production but is not a hard gate.

**If PIVOT:**

Before routing back to spec revision, capture the carry-forward note. Ask these two
questions (plain text, one at a time):

1. "What features or architecture choices worked at this quality level and should be preserved in the revised design?"
2. "What specifically failed — the core journey, the architecture, the pipeline, or the value?"

Ask: "May I write this to `prototypes/[product-name]-vertical-slice/PIVOT-NOTE.md`?"

If yes, write the file with: what worked, what failed, the specs or ADRs needing
revision, and what the next slice should prove differently. When `/vertical-slice` is
next run after a PIVOT, check `prototypes/` for a `PIVOT-NOTE.md` and use it to frame
the new validation question.

- Revise affected specs with `/design-spec [feature]`
- Address architecture issues via `/architecture-decision`
- Then re-run `/vertical-slice` to validate the revised direction

**If KILL:**

Before abandoning the concept, confirm the verdict is sound:

- [ ] The core journey takes more than 5 minutes even for a guided user?
- [ ] No "aha" moment observed in any session?
- [ ] 50%+ of testers confused or stuck at the same point after 2+ slice attempts?
- [ ] Architecture issues would require rebuilding more than 50% of what was built?
- [ ] This is the 3rd vertical slice attempt on the same concept?

If 2+ boxes apply → KILL is sound. If 0–1 apply → one targeted PIVOT may recover the concept.

**Document the kill in `prototypes/GRAVEYARD.md`** (create if it doesn't exist).
Ask: "May I append this to `prototypes/GRAVEYARD.md`?" If yes, add one entry:

```
## [Product Name] Vertical Slice — YYYY-MM-DD
- **Kill reason:** [what specifically prevented the user from reaching the core value, or what the architecture could not support]
- **What worked at slice quality:** [features or architecture choices that held up]
- **What failed:** [journey issue, architecture decision, or pipeline blocker]
- **Next time:** [one specific change for the next similar attempt]
```

- Return to `/brainstorm` with what you learned
- Or run `/prototype [new-concept]` to test a new direction cheaply first

**If NOT ASSESSED:**

The slice is built but not validated. Say which reason applied — no unguided session,
or which Architecture Validation rows are NOT RUN and why. Finish the Phase 5
session and/or the missing architecture checks (the `production/session-state/active.md`
checkpoint is where to resume), then after asking update REPORT.md and its
`prototypes/index.md` row with the verdict. Do not take the slice to `/gate-check` as
if it had passed: NOT ASSESSED is not a PROCEED.

---

### Important Constraints

- Vertical slice code must NEVER be refactored into production — it is reference only
- Production code must NEVER import from `prototypes/`; the slice never edits files outside `prototypes/` (the checkpoint and the index row are the named exceptions)
- If the recommendation is PROCEED, production implementation is written from scratch using the slice as a design reference only
- Scope cuts are acceptable; quality cuts are not — a low-quality slice proves nothing about the architecture
- Total effort: 1–3 weeks. If longer, scope is too large — cut the slice, not the quality
- Day-3 sunk-cost rule: if the journey is not demonstrable by then, stop and surface the blocker
- Never present a slice-level number as a production guarantee: latency measured on seeded data of slice volume carries that volume in the report, and a performance row without data volume and environment is `NOT RUN`
- Real third-party providers are touched in **sandbox mode only**, with credentials from environment variables that are never committed; a real customer's data never enters the slice
- **Hybrid / self-hosted:** a hosted-only slice cannot validate the customer bundle. The report says which topology was run; the self-hosted row is `NOT RUN — hosted only` otherwise, and the licence rules of `.claude/rules/deploy.md` (Valkey, official Mongo image, OTel Collector only) apply to any bundle the slice ships
- **Mobile:** an Android emulator run does not validate iOS; iOS builds need macOS with Xcode — otherwise the iOS rows are `NOT RUN — requires macOS with Xcode`, not inferred from the Android result
