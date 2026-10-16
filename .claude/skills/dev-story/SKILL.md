---
name: dev-story
description: "Implement a story: research and threat-model gates, contract first, route through principal-engineer to the stack lead, tests first, eight-gate evidence plan, layer checks, run-and-observe. Then /code-review and /story-done."
argument-hint: "[story-path]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/dev-story/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(bash .claude/scripts/migration-lint.sh *), Bash(bash .claude/scripts/project-coherence.sh), Bash(bash .claude/scripts/project-coherence.sh *), Bash(wc -c *), Bash(date *), Bash(git status), Bash(git status *), Bash(git diff *), Bash(git log *), Bash(gofmt *), Bash(go vet *), Bash(go test *), Bash(go -C * vet *), Bash(go -C * test *), Bash(golangci-lint run *), Bash(govulncheck *), Bash(osv-scanner scan *), Bash(./gradlew *), Bash(pnpm install --frozen-lockfile), Bash(pnpm -C * install --frozen-lockfile), Bash(pnpm lint), Bash(pnpm -C * lint), Bash(pnpm typecheck), Bash(pnpm -C * typecheck), Bash(pnpm test), Bash(pnpm test *), Bash(pnpm -C * test), Bash(pnpm -C * test *), Bash(pnpm build), Bash(pnpm -C * build), Bash(pnpm exec playwright *), Bash(pnpm -C * exec playwright *), Bash(pnpm audit), Bash(pnpm audit *), Bash(pnpm -C * audit), Bash(pnpm -C * audit *), Bash(swift test), Bash(swift test *), Bash(xcodebuild test *), Bash(swiftlint), Bash(swiftlint *), Bash(gitleaks git *), Bash(gitleaks dir *), Bash(docker compose -f deploy/compose.dev.yaml up -d --wait), Bash(docker compose -f deploy/compose.dev.yaml ps), Bash(docker compose -f deploy/compose.dev.yaml ps *), Bash(docker compose -f deploy/compose.dev.yaml logs *), Bash(docker compose -f deploy/compose.dev.yaml down), Bash(docker compose logs *), Bash(pnpm -C * preview)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,story_granularity,qa.level,testing.strict,performance.enforce,system_overrides,stack`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`. `review_mode` only decides whether the
SL-THREAT-MODEL and CTO-STACK-RISK gates (Phase 2) are spawned — it never waives a
prerequisite check or a DoD gate.

# Dev Story

This skill bridges planning and code. It reads a story file in full, refuses to
start until the research note (DoD gate 1) and, when triggered, the threat model
exist, resolves which layer(s) the story touches from the story and the
`stack` profile, routes the work to the right stack lead through
`principal-engineer`, plans the evidence each of the eight DoD gates needs
**before** any code is written, drives implementation (tests first for Logic
stories), runs the layer's checks and reports their real output.

**The loop for every story:**
```
/qa-plan sprint           ← define test requirements before sprint begins
/story-readiness [path]   ← validate before starting
/dev-story [path]         ← implement it  (this skill)
/code-review [files]      ← review it
/story-done [path]        ← verify and close it
```

**At `workflow: minimal`** the loop is `/dev-story [path]` → `/story-done [path]`:
no QA plan, readiness check or sprint. The research note, the threat model for a
sensitive story, the eight DoD gates and run-and-observe are **not** relaxed —
`minimal` has fewer documents, not weaker engineering (`workflow-modes.md`).

**With a sprint plan, after all sprint stories are done:** run `/team-qa sprint`
for the full QA cycle and a sign-off verdict before advancing the project stage.

**Output:** source code under the code root(s) the story names (`backend/`, `web/`,
`mobile/…`, `contracts/` — resolved with `resolve_code_root`, see
`.claude/docs/directory-structure.md`) plus tests at each layer's test location,
an evidence plan, and the real output of the layer checks. A story's code is
written by the stack lead, never by this orchestrator.

> **A check that did not run is reported as `not run`.** Never "passed". This
> applies to every command in Phase 6: a missing toolchain (`govulncheck` not
> installed, Swift tests on a Linux host), an unreachable container runtime or
> an unset `stack.*` layer produces `not run — [reason]` in the summary, and a
> blocking gate with a `not run` check keeps the story out of `Done`
> (`.claude/rules/skill-authoring.md`).

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Workflow tier**: resolved per the story's feature (per
`.claude/docs/workflow-modes.md`) — **the spec filename stem** of the story's
`Spec:` path (`design/specs/<stem>.md` → `<stem>`), with the `[feature]` segment of
its `TR-[feature]-NNN` ID accepted only as a fallback alias: use the
`system_overrides` row for that feature if the block lists one, else the project
value. Resolve it at the start of Phase 2 and apply it to the prerequisite gates.

**`story_granularity`** sets the expected implementation cycle: **multi-day** at
`coarse` (the default via `rigor: minimal`; give the lead longer working
context), **1–2 days** at `balanced`, **hours** at `fine` (tighter context). It
does not change any prerequisite gate.

**`qa.level`**: changes only how much *extra* test evidence the plan asks for; it never
lowers the tests themselves. Logic, Integration, Contract and Security tests exist and pass
at every tier (`coding-standards.md`), alongside the research note, the threat model,
security negative tests, tenant-isolation tests, run-and-observe and a UI story's retained
screenshots. `standard` adds the per-type extra evidence; `full` also passes the coverage
target in `testing-standards.md` (domain + app packages ≥ 85 %). Distinct from
`workflow: minimal`.

**`stack`** (from the block above) is the **only** source for routing. A layer
printed `unset` is **not defaulted** — routing a Ktor product to Go agents
because a key was missing is the failure this line exists to prevent. If the
story's layer is `unset`, stop: `Layer [x] is unset in project.yaml — run /setup-stack`.

## Phase 1: Find the Story

**If a path is provided**: read that file directly.

**If no argument**: check `production/session-state/active.md` for the active
story. If found, confirm: "Continuing work on [story title] — is that correct?"
If not found, ask: "Which story are we implementing?" Glob
`production/epics/**/*.md` (excluding `EPIC.md`) and list stories with Status: Ready (compared case-insensitively; `Not Started` and `Draft` stories are not listed, but named once as "needs `/story-readiness` first" so they are not lost; an `In Progress` story is listed under "resume").

---

## Phase 2: Load Context and Pass the Prerequisite Gates

**Read `references/2-load-context.md` now and follow it** — this phase's steps are in that file, not here. It carries the gates that stop a story before any agent is spawned: **research note (DoD gate 1)**, **threat model for sensitive stories**, **contract-first ordering**, Accepted ADRs, dependencies, manifest version, and the stack reference. Read it again if the conversation was compacted or resumed during this phase.

## Phase 3: Resolve Layers and Route

**Read `references/3-route.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 4: Plan the Evidence (before any code)

**Read `references/4-plan-evidence.md` now and follow it** — this phase's steps are in that file, not here. It produces the eight-gate evidence plan the user approves and the test-first sequence. Read it again if the conversation was compacted or resumed during this phase.

## Phase 5: Implement

**Read `references/5-implement.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 6: Verify — Layer Checks and Run-and-Observe

**Read `references/6-verify.md` now and follow it** — this phase's steps are in that file, not here. The per-layer command table is in `references/layer-checks.md`; read it from there. Read it again if the conversation was compacted or resumed during this phase.

## Phase 7: Collect and Summarise

**Read `references/7-collect.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 8: Update Session State

**Read `references/8-session-state.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** Full procedure: `.claude/docs/error-recovery-protocol.md`.

Common blockers:
- Input file missing (story not found, spec absent) → redirect to the skill that creates it
- Research note missing and the story is not exempt → `/research [feature]` (DoD gate 1); do not spawn any lead
- Sensitive story with no threat model, or SL-THREAT-MODEL `REJECT` → `/threat-model [feature]`; do not spawn any lead
- Contract story the work depends on not Complete → finish it first (`api-designer`, `/api-contract`)
- A *referenced* ADR's status is Proposed → do not implement; accept it with `/architecture-decision accept ADR-NNNN` once decided (a story that references no ADR is not blocked on this — see Phase 2)
- Stack layer `unset`, or `docs/stack-reference/<layer>/` missing → `/setup-stack`; an API not in the reference is `NOT SOURCEABLE` → `/research`
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess
- Manifest version mismatch → show diff to user, ask whether to proceed with old rules or update story first
- Toolchain or container runtime missing → the affected check is `not run`; the story cannot reach `Done` on that gate until it runs elsewhere (CI, another host)

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

- **Decision records follow the tier.** "An ADR" in this skill means an ADR (at
  `modes.workflow: minimal`, an entry in the brief's decision log, `design/product-brief.md`).
- **File writes are delegated** — all source code, test files and evidence docs are written by agents spawned via `Agent` (`principal-engineer` and the leads it routes to). Each enforces the "May I write to [path]?" protocol individually. This orchestrator writes only the following, each after an ask that names it:
  - the story's `Status:` / `Last Updated:` / `Started:` and its `production/sprint-status.yaml` entry — the one "May I mark this story In Progress?" ask (Phase 2); and, on `Implementation Complete` only, `Status: In Review` (Phase 7) — its own one ask
  - the story's `ADR Version`, `**ADR Decision Summary**` and `## Implementation Notes` (ADR mismatch option [A]), and its `Manifest Version:` / `Manifest-Note:` (manifest option [A] or [B]) — each option names that edit, so choosing it is the ask
  - a dependency story's `Status: Complete` (dependency option [C], then "May I update [dependency path] Status to Complete?")
  - a Config story's data file ("May I write to [path]?")
  - the story's `## Definition of Done Evidence` rows and `Evidence plan:` block (Phase 4), after the user approves the plan
  - `production/qa/evidence/[STORY-ID]/` check output files (Phase 6) — **new files under a path this skill names**, written without a second prompt

  The session-state checkpoint in `production/session-state/active.md` is the one write made without an ask.
- **Load before implementing** — do not start coding until all context is loaded
  (story, TR-ID, ADR, manifest, research note, threat model, stack reference).
  Incomplete context produces code that drifts from the design.
- **The research note and the threat model are gates, not suggestions** — no lead is spawned without them (or the documented exemption). Never "research it quickly inline".
- **The ADR is the law** — implementation must follow the ADR's Implementation
  Guidelines. If the guidelines conflict with what seems "better," flag it in the
  summary rather than silently deviating. An architectural decision the story
  must make that no ADR covers is raised to the user and recorded as an ADR
  (`/architecture-decision`), not decided silently in code.
- **Contract first** — a client (web, mobile) never codes against an operation the contract does not yet contain.
- **Stay in scope** — the Out of Scope section is a contract. If implementing
  the story requires touching an out-of-scope file, stop and surface it:
  "Implementing [criterion] requires modifying [file], which is out of scope.
  Shall I proceed or create a separate story?"
- **Tests first for Logic stories** — the failing test is shown failing before the code that makes it pass. Never weaken, skip or delete a test to get green.
- **Tests never scale down with `qa.level`** (Logic, Integration, Contract and Security tests exist and pass at every tier); `qa.level` adds extra evidence only. Security negatives, tenant-isolation tests, run-and-observe and UI screenshots are never waived either.
- **Ask before large structural decisions** — if the story requires an
  architectural pattern not covered by the ADR, surface it before implementing:
  "The ADR doesn't specify how to handle [case]. My plan is [X]. Proceed?"
- **No commits** unless the user asks. When asked, Conventional Commits with `Story: [STORY-ID]` in the body.

---

## Recommended Next Steps

- Run `/code-review [file1] [file2]` to review the implementation against the eight DoD gates before closing the story (at `minimal` and `solo` review mode it is optional, `/story-done` still checks every gate — but a story on a security-sensitive path, a migration or a billing/licensing/tenancy change should not close on the author's own review alone)
- A risky user-visible change (new pricing or entitlement behaviour, a changed core journey, an irreversible-looking migration) ships behind a feature flag read from config, default off, so `/team-release` can roll it out gradually and switch it off without a deploy
- Run `/story-done [story-path]` to verify acceptance criteria and evidence and mark the story complete
- With a sprint plan, after all sprint stories are done: run `/team-qa sprint` for the full QA cycle before advancing the project stage. At `minimal`, `/story-done` names the next story instead
