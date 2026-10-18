---
name: research
description: "DoD gate 1: research note from primary sources before any code - question, pinned versions, findings by source tier, options, decision, security/performance/observability notes, open questions. Also `refresh <layer>` to re-verify docs/stack-reference/."
argument-hint: "[feature-slug | question] | refresh <layer> [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, WebFetch, WebSearch, Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(date *), Bash(bash "*/.claude/skills/research/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/project-coherence.sh), Bash(bash .claude/scripts/project-coherence.sh *), Bash(git status *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,automation_always_ask,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt). **`refresh` mode is the
exception: it changes pinned versions every agent relies on, so its writes ask
in every mode** (it is a `version_bumps` decision).

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**`workflow`** does **not** relax this skill. A research note is required at
every tier, including `minimal` (`workflow-modes.md` "minimal floor"): tiers
scale documents, never engineering.

# Research

No feature is built from memory. This skill runs
`.claude/docs/research-protocol.md`: it turns a question into a sourced,
versioned research note that an engineer can build from and a reviewer can check
link by link, and it says plainly what could not be found. It is DoD gate 1
(`coding-standards.md`). The reading and writing is done by the `researcher`
agent; this skill frames the question, hands over the pinned versions, checks the
returned note mechanically and asks the user to decide.

**Two modes**
- **note** (default): `docs/research/<feature-slug>.md` from
  `.claude/docs/templates/research-note.md`.
- **`refresh <layer>`**: re-verify `docs/stack-reference/<layer>/` against its
  cited sources, update its **Last verified** date and `docs/stack-reference/pins.yaml`
  with approval. Procedure: `references/4-refresh.md`.

**Output (note mode):** `docs/research/<feature-slug>.md` and, when it triggers
them, a pointer to `/threat-model`, `/api-contract`, `/db-migration`,
`/cache-design`, `/observability-plan` or `/architecture-decision`.

> **Verdicts:** `COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`
> (`EXEMPT` when the protocol's table says no note is needed). Precedence:
> `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH GAPS`, then `COMPLETE`.
> `NOT ASSESSED` outranks `COMPLETE`: a source that could not be fetched, a
> researcher that returned no file, or a pin that could not be read means the
> claim was never checked, which is not the same as checked and found fine
> (`.claude/rules/skill-authoring.md`). **A note is never `Complete` while a
> load-bearing claim is `NOT SOURCEABLE`**; the gap is named in the report and
> the note's Status stays `Draft`.

---

## Phase 1: Parse, Classify, Frame

**Read `references/1-classify-and-frame.md` now and follow it.** It parses the
arguments, applies the protocol's exemption table (a bug fix inside researched
code and a copy/styling/config change need no note: cite the existing one),
looks for an existing note to reuse or update, and agrees the question, the
decision it informs and the layers it touches with the user. If the argument is
`refresh <layer>`, jump to `references/4-refresh.md` instead. Read it again if
the conversation was compacted or resumed during this phase.

## Phase 2: Versions and Constraints

Before any source is read, collect what is already pinned. This is the
researcher's starting point and it is read by you, not recalled:

1. `docs/stack-reference/pins.yaml` for every component the question touches.
2. `docs/stack-reference/<layer>/VERSION.md` (and `breaking-changes.md`,
   `deprecated-apis.md`, `best-practices.md`) for each layer. Record each file's
   **Last verified** date. A layer whose reference is absent is
   `NOT SOURCEABLE — no stack reference for <layer>` and goes into the brief as
   such; do not fill it.
3. `docs/ROADMAP.md` decisions **L1-L4 and T1** (Valkey in customer bundles,
   Dragonfly hosted only, Mongo official image only, OTel Collector only,
   gitleaks). An option that breaks one is reported as `licence-blocked`, never
   silently dropped.
4. `project.yaml` through the resolved config: `stack`, `distribution`,
   `tenancy`. An unset value that changes the answer (for example
   `distribution` for a self-hosted option) is asked, not assumed.

A Last-verified date older than the pinned version's release makes that
reference **stale**: say so in the brief and the researcher re-verifies the rows
the question uses before relying on them (`research-docs.md`).

## Phase 3: Spawn the Researcher

**Read `references/2-researcher-brief.md` now.** Spawn `researcher` via `Agent`
with the fixed brief in that file, filling only its `{...}` slots. If the
question splits into independent sub-questions (for example one provider and one
library, or two layers), spawn one `researcher` per sub-question **in parallel**
in a single message, each with its own temporary section file named in the
brief, and merge afterwards. **Split by size too:** a researcher has a turn
budget (`maxTurns` in `.claude/agents/researcher.md`), so one researcher covers
at most two decision areas (an ADR-sized choice or a named gap each). A larger
scope is grouped into sets of two or fewer, one researcher per set, even when
the sets share mechanisms — the merge is cheaper than a note that never gets
written. (Two Kodeebo runs with three areas per researcher ran out of turns in
8 of 10 parts before writing sections 4–9.) A researcher cannot see its remaining
turns, so each brief also sets a **budget** (default 20 units; up to 30 for
primary-source-heavy areas such as law and regulation). Each WebFetch, WebSearch
or spike command run spends one unit, because runs take turns too; the researcher
writes each finding before the next fetch or run, refreshes provisional sections
4–9 every 8 units and finalises them when the budget is spent. (A third run at 40
turns still ended 4 of 4 parts with sections 4–9 empty; in a fourth, a part that
ran seven spikes on a 20-fetch budget hit 40 turns with no finding written.) The
merge is done with the Write tool and checked by content (`references/2-researcher-brief.md`).

**Disjoint IDs per part.** Give each parallel researcher its own ID block in the
brief — part *n* (from 1) owns findings `F{n}01–F{n}99` and spikes
`S{n}0–S{n}9` — and tell it to cite another part's or note's ID only with a
prefix (`desktop-note F117`). The merge then concatenates without renumbering;
an ID used twice is a merge defect to fix before Phase 4, never silently.

The brief names the destination path so the researcher's new file is the
sanctioned subagent write. The user has approved that path in Phase 1. Collect
every response before continuing. **Verify the artifact before reading the
response** (`.claude/docs/error-recovery-protocol.md` Trigger 0): if the named
file is not on disk, the phase failed, however fluent the reply. Resume the
agent once naming the unmet return contract; a second miss is `BLOCKED`. A reply
"needs approval: <what>, <size>" is not a failure: ask the user (size and
source), then resume the agent with the answer; never approve a download over
100 MB on the user's behalf.

If `researcher` cannot be spawned, say why and write nothing yourself from
memory: the verdict is `NOT ASSESSED - researcher unavailable`.

## Phase 4: Check the Note, Decide, Route

**Read `references/3-note-checks.md` now and follow it.** It runs the
mechanical checks on the returned note (nine sections, every finding has a link
and a tier, versions match the pins, tier-5 sources never carry a decision,
licence-blocked options named, no secrets, quotes short), presents the options
and the researcher's recommendation, and has the **user** make the decision
(a major decision: `AskUserQuestion`, never inferred). It then routes follow-ups
by what the note found.

The decision section is the user's. If the decision is architectural, offer
`/architecture-decision` (at `workflow: minimal` the decision goes in the
product brief's decision log). In `full` review mode, when the decision rests on
an API or behaviour beyond the stack reference, spawn `cto` for
**CTO-STACK-RISK**: the prompt tells it to read
`.claude/docs/director-gates/cto-stack-risk.md` first (you do not read it) and
passes the API/library and layer, the pinned version and the note path. In
`lean` or `solo`, record `CTO-STACK-RISK skipped - [mode] mode`. A skipped gate
is recorded as skipped, never as passed.

## Phase 5: Write and Hand Off

Present the verdict, the checks table (each check `ran` / `not run - reason`),
the `NOT SOURCEABLE` list and the open questions with owners. The note already
exists on disk from the researcher; ask before changing it:

Ask: "May I apply these corrections and the recorded decision to `docs/research/<feature-slug>.md` (Status
set to [Draft | Complete])?" Name the path. Write only after approval: the decision
and the Status are written together, here, and not earlier. If the user declines, the
note keeps `Status: Draft`, nothing is written, and the verdict is `BLOCKED — write
declined by user`; `Complete` is never claimed. If the file is unchanged by this
skill, say that.

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/research <feature-slug> —
<verdict>`, Next step = the first Recommended Next Step for the finding class,
plus Blocked on / Files in progress (the note path) / Open questions (the note's
open questions with owners); append the Notes line. BLOCKED, NOT SOURCEABLE gaps
or a declined write still update the checkpoint with the blocker.

Then name the next step by finding class (see Recommended Next Steps). Record the
path where the story will cite it: the story's `Research note:` line, which
`/story-readiness`, `/dev-story` and `/story-done` check.

---

## Error Recovery Protocol

**First, verify the artifact.** If a spawned `researcher` was told to write a
path, check that the path exists before treating the phase as done. If any
agent returns BLOCKED, errors or cannot complete: surface it immediately, do not
proceed past a dependency it blocks, offer skip / retry narrower / stop via
`AskUserQuestion`, and always produce a partial report. A skip does not clear a
block: the final verdict names the skipped agent and its gap. Full procedure:
`.claude/docs/error-recovery-protocol.md`.

## Collaborative Protocol

- **Question -> Options -> Decision -> Draft -> Approval.** The choice among
  options is the user's; this skill and the researcher recommend, never decide.
- **Never write a version, API, flag or regulation from memory.** Unsourceable is
  a valid finding: `NOT SOURCEABLE - <what was searched>`.
- **Never put a secret, customer data or an internal hostname in a search
  query, a brief or a note** (`research-docs.md`). If the question contains one,
  ask the user to rephrase before anything is sent out.
- **A lower tier never overrides a higher one**, and a tier-5 source is a lead,
  never the basis for a decision.
- **At most one short quote per source**; summarise in your own words.
- **If implementation contradicts the note, the note is updated first**, then the
  code. This skill does that update on request.
- **`refresh` writes always ask**, in every automation mode.
- A skipped, dismissed or empty answer is not an answer: act on nothing, ask
  again in plain text and wait.

---

## Recommended Next Steps

- Sensitive topic (auth, billing, licensing, crypto, file upload, PII, webhooks, admin, new provider): run `/threat-model [feature]` - the note's Security Notes are its input
- Architectural decision: run `/architecture-decision` (or log it in `design/product-brief.md` at `minimal`)
- The note names an HTTP surface: run `/api-contract [feature]`; a schema change: `/db-migration [feature]`; a cacheable read: `/cache-design [feature]`; new endpoints, jobs or provider calls: `/observability-plan plan [feature]`
- External provider: run `/integration [provider]`
- Open questions that block implementation: resolve them (owner and due date are in the note) before `/dev-story`
- Stale or partially verified stack reference: `/research refresh <layer>`, then `/dependency-audit`
