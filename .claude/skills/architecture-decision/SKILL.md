---
name: architecture-decision
description: "Write an ADR (docs/architecture/adr-NNNN-slug.md): problem, alternatives with cost/risk/performance/operability, consequences, links to the research note and specs. Gate CTO-ADR. Also retrofit and accept modes."
argument-hint: "[title | retrofit <path> | accept <ADR-id>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(wc -c *), Bash(date *), Bash(bash "*/.claude/skills/architecture-decision/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,team.size,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

# Architecture Decision

When this skill is invoked:

## 0. Parse Arguments — Detect Retrofit / Acceptance Mode

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`team.size`**: which agents validate this ADR (orthogonal to review_mode/workflow).
- **`individual`** (default): `cto` (CTO-ADR) + the stack lead for the ADR's layer,
  routed by `principal-engineer` (`go-lead`, `ktor-lead`, `web-lead`,
  `android-lead`, `ios-lead`, `kmp-specialist`, or `data-lead` for a store/messaging decision).
- **`small`** and **`studio`**: the same two. This skill spawns no stack
  sub-specialist and no adversarial reviewer at any size.

**`docs.density`** — it controls the *depth* of the ADR's prose sections, not
which sections the skeleton emits (that is fixed). `modes.rigor` sets it
alongside `workflow`; set `docs.density` explicitly to vary ADR verbosity alone:
`terse` (the default, via `rigor: minimal`) = decision + alternatives as bullets, one line of rationale each;
`balanced` = paragraph per section with light rationale (`rigor: standard`); `thorough` =
full prose with trade-offs and worked rationale in Decision, Alternatives, and
Consequences. Apply it to the prose sections; the Stack Compatibility, ADR
Dependencies, Cross-Cutting Impact and Spec Requirements tables are structural
and stay whole at every density.

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` — all ADRs on the required ADR list must be completed.
- `standard` — critical ADRs only (tenancy, identity/auth, data store, messaging, API style, deployment topology, licensing).
- `minimal` — not required: decisions go in the product brief's decision log. Can still be run voluntarily.

**If the argument starts with `retrofit` followed by a file path**

**Read `references/0-retrofit.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

**If the argument starts with `accept` followed by an ADR id**

**Read `references/0-accept.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

If NOT in retrofit or acceptance mode, proceed to Step 1 below (normal ADR authoring).

**No-argument guard**: If no argument was provided (title is empty), ask before
running Phase 0:

> "What technical decision are you documenting? Please provide a short title
> (e.g., `tenancy-model`, `cache-engine-for-self-hosted`, `outbox-vs-broker`)."

Use the user's response as the title, then proceed to Step 1.

---

## 1. Load Stack Context (ALWAYS FIRST)

**Read `references/1-stack-context.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 2. Determine the next ADR number

Scan `docs/architecture/` for existing ADRs (`adr-NNNN-*.md`, top level only) to find the next number.
Never reuse a number, and never renumber an existing ADR.

---

## 3. Gather context

**Read `references/3-gather-context.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 4. Guide the decision collaboratively

**Read `references/4-decide.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 5. Generate the ADR

**Read `references/5-generate.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 6. Closing Next Steps

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/architecture-decision
<title> — ADR-NNNN written (Proposed)` (accept and retrofit modes run this same
step at their end: `accepted ADR-NNNN` / `retrofitted ADR-NNNN`), Next step =
the first option below (the next priority ADR, or
`/architecture-decision accept ADR-NNNN` when settled), plus Blocked on (the
stories waiting on acceptance) / Files in progress / Open questions; append the
Notes line. Still updated when the user declines the write: record nothing
written and why.

After the ADR is written (and registry optionally updated), close with `AskUserQuestion`.

Before generating the widget:
1. Read the Required ADRs list in `docs/architecture/architecture.md` (and `docs/architecture/requirements-traceability.md` if present) — check which priority ADRs are still unwritten.
2. Check if all prerequisite ADRs are now written. If yes, include a "Create the control manifest / epics" option once they are Accepted.
3. List ALL remaining priority ADRs as individual options — not just the next one or two.

Widget format:
```
ADR-[NNNN] written (Proposed). What would you like to do next?
[1] Write [next-priority-adr-name] — [brief description from the Required ADRs list]
[2] Write [another-priority-adr] — [brief description]  (include ALL remaining ones)
[N] Accept ADR-[NNNN] — run `/architecture-decision accept ADR-[NNNN]` (only if the decision is settled)
[N+1] Stop here for this session
```

If there are no remaining priority ADRs, offer only "Accept" and "Stop here" and suggest running `/architecture-review` in a fresh session.

**Always include this fixed notice in the closing output (do NOT omit it):**

> To validate ADR coverage against your feature specs, open a **fresh Claude Code session**
> and run `/architecture-review`.
>
> **Never run `/architecture-review` in the same session as `/architecture-decision`.**
> The reviewing agent must be independent of the authoring context to give an unbiased
> assessment. Running it here would invalidate the review.

**Do NOT unblock stories here.** This ADR is `Proposed` — Step 5 guarantees it,
and a story blocked *pending this decision* is still pending it. Unblocking on
authoring is how the deadlock stayed invisible: it defeated the guard at the
moment the guard became relevant, so the pipeline appeared to flow while running
on decisions nobody had accepted.

Instead, tell the user what is now waiting on acceptance:

> "ADR-NNNN is written and `Proposed`. [N] stories remain `Blocked` pending it.
> Run `/architecture-decision accept ADR-NNNN` when the decision is settled —
> that is what moves them to `Ready`."

List the blocked stories by path so the cost of leaving it Proposed is visible.
(Acceptance has consequences enforced across many skills and an authority
recorded in only a few, so the route between them must stay explicit.)

## Not-Run Reporting

Checks inside the run report `NOT ASSESSED` with the reason rather than passing
silently: **stack validation** when a layer has no reference under
`docs/stack-reference/` (`NOT SOURCEABLE`), the **research-note link** when
`docs/research/<feature>.md` is absent, **spec sync** when the referenced specs
cannot be read, and each gate skipped by review mode. A skipped check that says
nothing is indistinguishable from a check that passed.
