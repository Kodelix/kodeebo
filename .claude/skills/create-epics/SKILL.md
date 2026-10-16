---
name: create-epics
description: "Turn feature specs plus architecture into epics — one per bounded context or module, with untraced requirements surfaced. Then /create-stories [epic-slug]."
argument-hint: "[context-name | layer: foundation|core|feature|presentation | all] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(bash "*/.claude/skills/create-epics/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,story_granularity,system_overrides,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.


# Create Epics

An epic is a named, bounded body of work that maps to one bounded context (or
one cross-cutting architectural module). It defines **what** needs to be built
and **who owns it architecturally**. It does not prescribe implementation steps
— that is the job of stories.

**Run this skill once per layer** as you approach that layer in development.
Do not create Feature layer epics until Core is nearly complete — the design
will have changed.

**Output:** `production/epics/[epic-slug]/EPIC.md` + `production/epics/index.md`

**Next step after each epic:** `/create-stories [epic-slug]`

**When to run:** After `/create-control-manifest` and `/architecture-review` pass
(at `full`). At `standard`, critical ADRs suffice, and a control manifest is
read if present. At
`minimal`, this skill is **optional and not part of the path** — `/create-stories`
synthesizes the epic from `design/product-brief.md` itself (Option A). If run anyway,
it decomposes directly from the brief with no spec/ADR/manifest prerequisite.

> **At `minimal`, this skill is optional — `/create-stories` synthesizes the epic**
> (Option A). At that tier `/create-stories` reads `design/product-brief.md`
> directly, writes a lightweight implicit `production/epics/<slug>/EPIC.md`, and
> generates stories from the MVP list — so the path is `/brainstorm` →
> `/research` → `/create-stories` → `/dev-story`, with no separate `/create-epics` or
> `/sprint-plan` step. **At `standard`/`full` an epic IS required**:
> `/create-stories` reads `production/epics/[slug]/EPIC.md`, and skipping this
> skill there leaves `/dev-story` with no story to implement — a dead end, not a
> shortcut.

---

## 1. Parse Arguments


See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`workflow`** (per `.claude/docs/workflow-modes.md`):

create-epics runs project-wide: it uses the project-level tier for its
prerequisite expectations and consults
`workflow_overrides.system_overrides.<feature>` per-feature when reading each
in-scope spec (the key is the spec filename stem). See "Workflow tier
adjustment" in Step 2.

**`story_granularity`** — it sizes the
epic's story breakdown: expect **3–5** child stories per epic at `coarse` (the default, via `rigor: minimal`), **5–10**
at `balanced` (`rigor: standard`), **10–20** at `fine`. The contract-first story
for each exposed boundary (see `/create-stories`) counts toward the range.

**`docs.density`** — it controls the *depth* of each epic's written scope and
rationale, not the story count (that is `story_granularity`). `modes.rigor` sets
it alongside `workflow`; set `docs.density` explicitly to vary epic prose alone:
`terse` (the default, via `rigor: minimal`) = scope as bullets, one-line rationale; `balanced` = a scope paragraph
with light rationale (`rigor: standard`); `thorough` = full scope prose with governing-ADR
rationale and risk discussion. The EPIC.md tables (spec requirements, governing
ADRs) are structural and stay whole at every density.

**Modes:**
- `/create-epics all` — process all contexts in layer order
- `/create-epics layer: foundation` — Foundation layer only
- `/create-epics layer: core` — Core layer only
- `/create-epics layer: feature` — Feature layer only
- `/create-epics layer: presentation` — Presentation layer only
- `/create-epics [context-name]` — one specific bounded context or cross-cutting module
- No argument — ask: "Which layer or bounded context would you like to create epics for?"

---

## 2. Load Inputs

### Step 2a — Summary scan (fast, fail-open)

**At `minimal`, skip Steps 2a and 2b** — that tier decomposes from
`design/product-brief.md` and has no specs by design (see the tier note below). Read
the brief instead; if it is missing, report "No `design/product-brief.md` — run
`/start` or `/brainstorm` first" and stop with **Verdict: BLOCKED — no product brief**.

**At `standard` and `full`, establish the denominator first.** Glob `design/specs/*.md`, excluding the
non-feature docs — `domain-map.md`, `product-principles.md`, any `*-cross-review-*.md`
and any entity registry — the set `spec-structure-check.sh` skips. Call the
count **N**. If N is 0, there are no feature specs — report "No feature specs found
in `design/specs/` — run `/design-spec` first" and stop with **Verdict: BLOCKED — no feature specs**.

Scan for Overview sections (the summary of a spec):

```
Grep pattern="^## (Summary|Overview)" glob="design/specs/*.md" output_mode="content" -A 5
```

Interpret the **M** matches against N. These are three different outcomes, and
a zero-match scan is **never** the same as "nothing in scope":

| Result | Meaning | Action |
|---|---|---|
| **M = N** | Every spec has an Overview. | For `layer:`/`[context-name]` modes, use `domain-map.md` (Context, Priority, Layer) to pick the in-scope set; skip full-reading the rest. |
| **0 < M < N** | Partial adoption — older specs predate the template. | Scope the M by their Overviews; determine the scope of the **N − M** unmatched from `domain-map.md` (context/priority) and full-read those. |
| **0 matches, N > 0** | Expected for specs authored before the template. | Determine scope for **all N** from `domain-map.md` and full-read the in-scope set. Correct, only more expensive. Note once: "No Overview sections found across [N] specs — scoping from `domain-map.md` instead." |

**Never treat an absent Overview as an absent feature.** The scan narrows the
*read* set when it succeeds; it never shrinks the *in-scope* set. In `all` mode
every context is in scope regardless of Overview, so the scan is a convenience
only — never a filter.

### Step 2b — Full document load (in-scope contexts only)

Using the Step 2a grep results, identify which contexts are in scope. Read full documents **only for in-scope contexts** — do not read specs or ADRs for out-of-scope contexts or layers.

Read for in-scope contexts:

- `design/specs/domain-map.md` — authoritative context list, features per context, layers, priority, core-module flags
- In-scope specs only (Approved or Designed status, filtered by Step 2a results)
- `docs/architecture/architecture.md` — context cards, ports, data stores, tenancy, topology and API boundaries
- Accepted ADRs **whose domains cover in-scope contexts only** — skip ADRs for
  unrelated domains entirely. For each in-scope ADR, load only the "Spec
  Requirements Addressed", "Decision" and "Stack Compatibility" sections —
  never an unbounded full read:
  ```
  Grep pattern="^## (Spec Requirements Addressed|Decision|Stack Compatibility)" path="docs/architecture/[adr-file].md" output_mode="content" -n
  ```
  then `Read(offset, limit)` bounded to each match through the next `## `
  heading (or to end of file for the last match). This matters most on a
  large ADR.
- `docs/architecture/control-manifest.md` — manifest version date from header
- `docs/architecture/tr-registry.yaml` — for tracing requirements to ADR coverage
- `docs/architecture/threat-models/` — Glob only, to mark which sensitive features already have a threat model
- `docs/stack-reference/pins.yaml` and the `VERSION.md` of the layers in scope — stack versions and risk levels

Report: "Loaded [N] specs, [M] ADRs, stack: [layers + pinned versions]."

> **Workflow tier adjustment** (resolved in Step 1; per-feature via
> `system_overrides`). The inputs above are the `full` baseline:
> - **`full`** — every in-scope spec must be Approved with all 8 sections; TR
>   registry + control manifest are required inputs; untraced requirements
>   (Step 4) are flagged before proceeding.
> - **`standard`** — specs need the 5 required sections (+ conditional Edge Cases)
>   approved; only **critical (Foundation-layer) ADRs** are expected; the control
>   manifest is read if present, not required. A feature pinned higher via
>   `system_overrides` must still meet its higher bar.
> - **`minimal`** — decompose against `design/product-brief.md` +
>   acceptance criteria. Do not require specs, ADRs, the TR registry, or the
>   manifest; skip the untraced-requirement gate. If run, the epic is still
>   produced — but note `/create-stories` also synthesizes one from the brief when
>   this skill is skipped (the default `minimal` path).

---

## 3. Processing Order

Process in dependency-safe layer order:
1. **Foundation** (no dependencies — tenancy, identity, data stores, API conventions, observability pipeline, CI and deployment skeleton, shared-core wiring)
2. **Core** (depends on Foundation — the product's core domain contexts)
3. **Feature** (depends on Core)
4. **Presentation** (depends on Feature + Core — web app shell, mobile screens, marketing site, emails)

Within each layer, use the order from `domain-map.md`.

> **At `minimal` there is no `domain-map.md`** — `/map-domains` is not required
> at that tier, so nothing has produced one. Derive the layer split and ordering
> from `design/product-brief.md` instead: its **Build order** field names what must
> exist first. Do not stop, and do not send the user to `/map-domains` to satisfy
> an ordering hint — the tier deliberately skips it.

---

## 4. Define Each Epic

An epic is **one per bounded context** in `domain-map.md`, plus **cross-cutting
epics derived from the architecture** (not from a single spec) where
`architecture.md` has Foundation work no context owns:

| Cross-cutting epic | When | Source |
|---|---|---|
| Tenancy and request context | `tenancy.model` is set | architecture: Ownership, Data Stores and Tenancy |
| Contracts and client generation | any client consumes the API | architecture: API Style and Contract Boundaries |
| Observability pipeline | always | architecture: Data Flow, Messaging, Caching and Observability |
| CI, test infrastructure and deployment skeleton (hosted) | always | architecture: Deployment Topology |
| Self-hosted bundle, installer and upgrade path | `distribution.model` is `hybrid` or `self-hosted` | architecture: Deployment Topology (self-hosted) |

Cross-cutting epics carry `Spec: none — derived from architecture.md §[section]`
and are never invented when the architecture has no such section.

**Announce every cross-cutting epic that is not created, with its reason** — in this step,
before the per-epic questions, and again under "Not run" in the closing report. In particular
a **skipped tenancy epic** (`tenancy.model` unset, or `architecture.md` has no tenancy section)
is stated as: "No tenancy epic: `tenancy.model` is unset — every tenant-scoped context below
has no governing tenancy epic; decide the model (ADR) and re-run `/create-epics`." It is a
named gap (`COMPLETE WITH GAPS`), never a silent omission; the same wording applies to the
self-hosted epic when `distribution.model` is `hosted` (reason: hosted only).

For each context, map it to an architectural module from `architecture.md`.

Check ADR coverage against the TR registry **per the resolved tier** (Step 1):
- **`full`** — trace every TR-ID; warn on each untraced requirement (below).
- **`standard`** — only **critical (Foundation-layer) ADRs** are expected; trace
  those. Treat untraced non-critical requirements as informational (list them, do
  not block or emit the untraced-requirements warning).
- **`minimal`** — skip this check entirely (no TR registry / ADR expected).

- **Traced requirements**: TR-IDs that have an Accepted ADR covering them
- **Untraced requirements**: TR-IDs with no ADR — warn before proceeding (full only)

Also surface, per context (never silently drop):
- **Features in `domain-map.md` with no spec**, or a spec not assigned to any epic
- **TR-IDs in the registry assigned to no epic** (orphans) — list at the end of the run
- **Sensitive requirements with no threat model** (`docs/architecture/threat-models/<feature>.md` absent): the epic is created, the gap is listed, and `/create-stories` will give the mitigation story a blocking dependency
- **Stack risk**: HIGH-risk stack layers the context depends on, or `NOT SOURCEABLE` layers

Present to user before writing anything:

```
## Epic: [Context Name]

**Layer**: [Foundation / Core / Feature / Presentation]
**Specs**: design/specs/[filename].md [, ...]   (or "none — derived from architecture.md §[section]")
**Architecture Module**: [module name from architecture.md]
**Code roots**: [backend/ · web/ · mobile/ · contracts/ · deploy/ — from resolve_code_root]
**Owner agents**: [stack leads per layer, routed by principal-engineer]
**Governing ADRs**: [ADR-NNNN, ADR-MMMM]
**Stack Risk**: [LOW / MEDIUM / HIGH — highest risk among governing ADRs]
**Spec Requirements Covered by ADRs**: [N / total]
**Untraced Requirements**: [list TR-IDs with no ADR, or "None"]
**Threat Models Needed**: [features, with present/missing, or "None"]
**Editions**: [hosted | hosted + self-hosted]
**Shared-core modules**: [module @ version, or "none"]
```

If there are untraced requirements:
> "⚠️ [N] requirements in [context] have no ADR. The epic can be created, but
> `/create-stories` will write their stories with no governing ADR (`ADR: N/A`)
> and `Status: Ready` — nothing downstream blocks them, so they would be
> implemented without architectural guidance. Run `/architecture-decision` first
> if they need a decision, or proceed and accept the gap."

Use `AskUserQuestion`:
- Prompt: "Shall I create Epic: [name]?"
- Options:
  - `[A] Yes, create it`
  - `[B] Skip this epic`
  - `[C] Pause — I need to write ADRs first`

---

## 4b. Producer Epic Structure Gate

**Review mode check** — apply before spawning PR-EPIC:
- `solo` → skip. Note: "PR-EPIC skipped — Solo mode." Proceed to Step 5 (write epic files).
- `lean` → skip (not a PHASE-GATE). Note: "PR-EPIC skipped — Lean mode." Proceed to Step 5 (write epic files).
- `full` → spawn as normal.

After all epics for the current layer are defined (Step 4 completed for all in-scope contexts), and before writing any files, spawn `producer` via `Agent` using gate **PR-EPIC** (`.claude/docs/director-gates/pr-epic.md`).

Pass: the full epic structure summary (all epics, their scope summaries, governing ADR counts), the layer being processed, milestone timeline and team capacity.

Present the producer's assessment.

If UNREALISTIC: offer to revise epic boundaries (split overscoped or merge underscoped epics). Revise, present the revised epics again, and re-run the gate before writing.

If CONCERNS, use `AskUserQuestion`:
- Prompt: "Producer raised concerns about the epic structure. How do you want to proceed?"
- Options:
  - `[A] Proceed as planned — I accept the producer's concerns`
  - `[B] Revise epic boundaries — split or merge as recommended`
  - `[C] Stop — I want to reconsider the scope`

If [A]: proceed to Step 5.
If [B]: revise epic definitions from Step 4, present the revised epics to the user again, then re-run the producer gate.
If [C]: stop. Verdict: **BLOCKED** — user wants to reconsider epic scope.

If NOT ASSESSED [missing input] — e.g. no milestone timeline or team capacity — it
is not a REALISTIC (`.claude/docs/director-gates.md`): name what was missing, then
supply it and re-run the gate, or, if the user chooses to go on without it,
proceed to Step 5 and state `PR-EPIC: NOT ASSESSED — [input]` in the output and
the final Verdict line.

Do not write epic files until the producer gate resolves.

---

## 5. Write Epic Files

**If `production/epics/[epic-slug]/EPIC.md` already exists, never overwrite it.**
Ask instead: "An EPIC.md already exists for [name]. Update it in place, or skip
it?" — `[A] Update in place — keep its Stories table, and update its index.md row` / `[B] Skip this epic`. An
update rewrites only what this skill owns — the header fields other than
`Stories`, `## Overview`, `## Governing ADRs`, `## Spec Requirements`,
`## Threat Models and Contracts` and `## Definition of Done` — and leaves the
`**Stories**` header line and any `## Stories` table exactly as they are:
`/create-stories` wrote them, and resetting them to "Not yet created" orphans
every story already in the directory.

For a new epic, after approval, ask: "May I write `production/epics/[epic-slug]/EPIC.md` and add its row to `production/epics/index.md` (creating it if absent)?"

After user confirms, **read `references/epic-format.md` now** and write the EPIC.md and
the index row exactly in that shape.

---

## 6. Closing Report and Gate-Check Reminder

**Checkpoint.** First, update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/create-epics <scope> —
<verdict>`, Next step = `/create-stories [first-epic-slug]` (Foundation epic
first), plus Blocked on / Files in progress (the EPIC.md files, `index.md`) /
Open questions (orphans, missing threat models); append the Notes line. Still
updated on `BLOCKED` / `NOT ASSESSED` (no eligible contexts, writes declined):
record the blocker and that nothing was written.

After writing all epics for the requested scope, report in the output (not only in the files):

- **Orphans**: TR-IDs assigned to no epic, and features in `domain-map.md` with no epic, or "None"
- **Untraced requirements** per epic (full tier), or `not checked — workflow: [tier]`
- **Threat models missing** per sensitive feature, or "None"
- **Not run**: PR-EPIC skipped by review mode / NOT ASSESSED, specs excluded as not Approved, steps skipped by tier

Then:

- **Foundation + Core complete**: These are required for the Pre-Production →
  Production gate. Run `/gate-check production` to check readiness.
- **Reminder**: Epics define scope. Stories define implementation steps. Run
  `/create-stories [epic-slug]` for each epic before engineers can pick up work.
  Foundation epics first; within an epic, the contract story comes before backend and client stories.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **One epic at a time** — present each epic definition before asking to create it
2. **Warn on gaps** — flag untraced requirements before proceeding
3. **Ask before writing** — per-epic approval before writing any file
4. **No invention** — all content comes from specs, ADRs, and architecture docs
5. **Never create stories** — this skill stops at the epic level

After all requested epics are processed:

- **Verdict: COMPLETE** — [N] epic(s) written. Run `/create-stories [epic-slug]` per epic.
- **Verdict: COMPLETE WITH GAPS** — [N] epic(s) written, with named gaps (a cross-cutting epic not created and why, PR-EPIC `NOT ASSESSED` or skipped by mode, untraced requirements, orphans, missing threat models, a skipped epic). List each.
- **Verdict: NOT ASSESSED** — nothing could be assessed (inputs missing or unreadable); name what is missing.
- **Verdict: BLOCKED** — user declined all epics (`BLOCKED — write declined by user` when the write itself was declined), or no eligible contexts found.
