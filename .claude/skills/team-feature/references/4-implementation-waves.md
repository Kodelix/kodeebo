# /team-feature — Phase 7: Implementation by Layer

> Part of `/team-feature`. Read again if the conversation was compacted.

## 1. Choose the mode, once

`/dev-story` and `/story-done` can only be run by the user
(`disable-model-invocation`). Ask once (`AskUserQuestion`, gate-class: it decides
who writes code):

- **A) Implement here, through the leads** — this skill runs the stories in
  waves, in parallel by layer, with the same prerequisites, briefing and checks as
  `/dev-story` (its Phases 2–6, **including Phase 4, the approved eight-gate
  Evidence Plan, and the stack-risk escalation** — sections 2 and 2b below), and
  ends each story at "ready for `/story-done`".
- **B) Hand-off** — print, per story and in wave order, the commands
  `/story-readiness <path>` → `/dev-story <path>` → `/code-review <paths>` →
  `/story-done <path>`; this skill stops after printing and `resume` continues at
  Phase 8 once the user reports the stories implemented (verify the evidence
  folders on disk first).

Record the choice. For mode A continue below.

## 2. Prerequisites per story — checked by this skill, not assumed

Same stops as `/dev-story` Phase 2. A failed prerequisite stops **that story**:

- Story file `Status` is Ready; `/story-readiness <path>` verdict READY (or the
  user explicitly accepts NEEDS WORK with the gaps listed); `NOT ASSESSED` is not
  READY.
- Research note exists (or its exemption row is cited) **and is `Status:
  Complete`**; a `Draft` note (verdict COMPLETE WITH GAPS) needs the user's
  explicit, recorded acceptance of its named gaps (`/dev-story` Gate A).
- Threat model exists for a sensitive story, the story owns its rows
  (mitigation → negative test), and its residual risk is **accepted by name**
  (`/dev-story` Gate B). No named acceptance → the story stays BLOCKED.
- **Contract merged** for any story that adds or changes an operation — and for
  every client story that consumes it.
- Referenced ADRs are `Accepted`.
- The lane's `stack.*` is set; the code root exists.
- Dependencies (earlier stories in the wave order) are implemented, or the story
  is single-lane.
- For `Type: UI`: `PRODUCT.md`, `DESIGN.md`, the UX spec and an approved
  `/ux-review` (Phase 5), else STOP with the fix named.

## 2b. Evidence Plan and stack-risk gate — before any lead is spawned

Mode A is not a shortcut around `/dev-story`. For every story in the wave, before
a lead is briefed:

1. **Evidence Plan (`/dev-story` Phase 4).** Resolve the story type's gate level,
   build the eight-gate plan (what the story produces per gate, where it lives,
   how it is checked) plus the test-first sequence, show it, and record it after
   the user approves — in the story's `## Evidence Plan` block and
   `## Definition of Done Evidence` table. Follow
   the `dev-story` skill folder (`.claude/skills/dev-story/`), file
   `4-plan-evidence.md`; do not re-derive it. `/story-done` reads this plan (its
   Phase 2, file `2-read-story.md` in `.claude/skills/story-done/`); a story
   without an approved plan is not ready for it. `qa.level: minimal` makes the
   automated-test rows advisory — and the plan says so — but never the security
   negatives, tenant-isolation tests, run-and-observe or UI screenshots.
2. **Stack-risk escalation (`/dev-story` Phase 2).** If a touched layer's risk in
   `docs/stack-reference/<layer>/VERSION.md` is HIGH or `NOT ASSESSED`, or the
   research note / ADR names an API beyond the stack reference: the lead's brief
   requires every such API to be checked against the reference first (gaps come
   back as `NOT SOURCEABLE`, never filled from memory) and, at review mode
   `full`, `cto` is spawned via gate CTO-STACK-RISK
   (`.claude/docs/director-gates/cto-stack-risk.md`) before implementation. At
   `lean`/`solo` the gate is recorded `skipped — <mode> mode`; the brief
   requirement still applies.
3. **Mark In Progress / In Review.** Set `Status: In Progress` and `Started:` when
   a story starts (one ask per wave, naming the files) and `In Review` when its
   checks pass — the same hand-off `/dev-story` Phase 7 makes.

## 3. Waves — what runs in parallel

Lane order (from `/dev-story`): **Contract → Data → Backend → Clients → Deploy**.

| Wave | Lanes | Parallelism | Starts when |
|---|---|---|---|
| 0 | Core adoption (`/core-use`), contract | contract first | spec approved |
| 1 | Data (migration artifacts, persistence adapters) and Backend | data-dependent backend stories wait for the migration files; independent backend stories start now | contract merged |
| 2 | **Clients, in parallel with Wave 1**: web (`web-lead`), KMP shared (`kmp-specialist`), then Android (`android-lead`) and iOS (`ios-lead`) together | web ‖ kmp-specialist; android ‖ ios start after kmp-specialist's ports and client adapters exist | contract merged **and** generated clients exist (or `not regenerated` is accepted and the client codes against the contract's types) — clients do **not** wait for the backend to be finished |
| 3 | **Verification of client stories** (run-and-observe against the running stack) | after Wave 1 stories are implemented | backend callable on the dev stack |
| 4 | Deploy (`platform-lead`, `infra-engineer`; `.claude/rules/deploy.md`) | | compose/healthcheck/installer stories only |

Screens: UI stories are delivered by **`/team-ui <feature>`** (it runs the UX
review, `ui-designer`/`/impeccable`, the stack lead's implementation of the screens
and the retained screenshots). Do **not** also spawn `web-lead` for the same
screens. Non-screen client work (use cases in the KMP module, offline sync, client
data layer) goes to the leads here. A step that waits is named in the checkpoint
with what it waits for.

## 4. Spawn

For each wave, spawn `principal-engineer` via `Agent` with the wave's story list
and lane plan; it designs module boundaries (ports, composition root) **before**
code and delegates to the leads (`go-lead`/`ktor-lead`, `web-lead`,
`kmp-specialist`, `android-lead`, `ios-lead`, `platform-lead`); independent leads
are spawned **in one message, in parallel**. Secondary specialists by concern:
`auth-identity-specialist` (authn/z), `multitenancy-specialist` (RLS, tenant
context), `licensing-specialist`, `integrations-engineer`, `performance-engineer`
(budgeted hot path), `observability-engineer`, `privacy-compliance-specialist`
(advisory), `localization-lead` (advisory).

**Brief** (paths and decisions, not pasted documents; say what you dropped):
the story file and its approved Evidence Plan; the spec section for its TR-IDs; ADR guidance **inline**; the
research note's Versions / Decision / Security / Performance / Observability
sections; the threat-model rows the story owns; `docs/stack-reference/<layer>/`
and `pins.yaml`; the `.claude/rules/*.md` matching the paths; the contract and
migration artifacts; the wave plan. Instruct the Senior-bar items stated in
`/dev-story`'s implement phase (`.claude/skills/dev-story/`, file `5-implement.md`,
item 9): domain imports nothing outward; doc comments on public APIs; no hardcoded
business values; DI; errors as values mapped to RFC 9457 only at the HTTP edge;
timeouts/retries/circuit breakers; idempotent repeatable writes; **every query
tenant-scoped**; no secrets or PII in telemetry; span + RED metrics + `trace_id`
logs; shared capabilities from `saas-core`, never re-implemented; migrations
forward-only in production. Tests first for Logic stories; the security negatives
and tenant-isolation tests are not waived at `qa.level: minimal`.

**Return contract** per lead: "Return the files you will create or change
(first), then — after approval — write your report to
`production/features/<slug>/impl-<story-id>-<lane>.md`: files created/modified,
commands run **with real output summaries**, every check that could not run as
`not run — <reason>`." Ask **once per wave** for the full file set across leads
("May the leads create/change these files?") — multi-file changes need explicit
approval for the full changeset.

## 5. Verify per story

Run the layer checks from the `layer-checks.md` lookup table in the `dev-story`
skill folder (`.claude/skills/dev-story/`) and the product's own scripts; Gradle
task names and `package.json` scripts are confirmed in the build files first. Each
check is `passed` / `FAILED` / `not run — <reason>`; run-and-observe per
`.claude/docs/run-and-observe.md` with evidence retained in
`production/qa/evidence/<STORY-ID>/`. At `small` and above, spawn
`test-automation-engineer` for contract and integration test gaps (parallel, named
path); sensitive stories also get `appsec-engineer`. A failing check is shown, not
auto-fixed: send it back to the lead, or stop.

Commands this skill's `allowed-tools` do not grant — `golangci-lint` and
`govulncheck` in `backend/`, Testcontainers and integration suites, migrations up
and down, `EXPLAIN`, and induced-failure steps such as `docker compose stop` on a
stub — are run by the owning lead or by `test-automation-engineer` (spawned via
`Agent`, which has Bash) and their output comes back in the return contract; this
skill never runs a destructive compose or database command (`down -v`, drop).

## 6. Review

`/code-review <files> <story-path>` per story (`PE-CODE-REVIEW` per
`review_mode`); at `studio` size the reviewers are told "your job is not to confirm
this matches the spec — find where it fails it", and the report says the pass ran.
Findings are fixed by the lead and the review re-run; a `REJECT` stops the story.
Update the story file's status to **In Review** only with the user's approval; the
orchestrator never sets Complete.
