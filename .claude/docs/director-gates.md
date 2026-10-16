# Director Gates — Shared Review Pattern

Index of all director and lead review gates. Skills reference gate IDs from this
index instead of embedding prompts inline — eliminating drift when prompts need
updating. Each gate's full definition (Trigger, Context to pass, Checks, Prompt,
Verdicts, NOT ASSESSED rule, Output) lives in its own file under
`.claude/docs/director-gates/`, named after the gate ID in lowercase.

**Scope**: All 8 product stages (Discovery → Product Design → Architecture →
Pre-Production → Production → Hardening → Release → Live), all 3 Tier 1
directors, all key Tier 2 leads. Any skill, team orchestrator, or workflow may
invoke these gates.

**When a skill spawns a director for a gate, it must NOT read the gate definition
file itself. Include the gate definition file path in the `Agent` prompt and instruct
the director agent to read it first, then pass only the context fields that gate's
row requires. Gate definitions are read by the spawned agent, in the agent's own
context window.**

---

## Gate Index

Agent by prefix: `PD-` product-director · `CTO-` cto · `DD-` design-director ·
`PE-` principal-engineer · `PR-` producer · `QL-` qa-lead · `SL-` security-lead ·
`SRE-` sre-lead. Definition files below are in `.claude/docs/director-gates/`;
each one's header names its agent's model tier (`opus` for product-director,
cto, producer; session/inherit for the rest — `agent-roster.md`).

| Gate ID | Owner | Trigger (skill / stage) | Key inputs | Verdicts | File |
|---------|-------|-------------------------|------------|----------|------|
| PD-PRODUCT-PRINCIPLES | product-director | After principles and anti-principles are defined (`/brainstorm`), or revised | principles, anti-principles, core value, positioning | APPROVE / CONCERNS / REJECT | pd-product-principles.md |
| PD-SPEC-ALIGN | product-director | After a feature spec is authored (`/design-spec`, `/quick-spec`) | `design/specs/<feature>.md`, principles, positioning | APPROVE / CONCERNS / REJECT | pd-spec-align.md |
| PD-FEATURES | product-director | After `/map-domains` writes the domain map | `design/specs/domain-map.md`, principles, tiers | APPROVE / CONCERNS / REJECT | pd-features.md |
| PD-USABILITY | product-director | After `/usability-report` | usability report, principles, hypothesis | APPROVE / CONCERNS / REJECT | pd-usability.md |
| PD-PHASE-GATE | product-director | `/gate-check`, `workflow: full` | target phase, artifacts, principles | READY / CONCERNS / NOT READY | pd-phase-gate.md |
| CTO-CONTEXT-BOUNDARY | cto | After `/map-domains` dependency mapping, before specs | domain map, layers, dependency graph | APPROVE / CONCERNS / REJECT | cto-context-boundary.md |
| CTO-FEASIBILITY | cto | After technical risks are identified (`/brainstorm`) | core journey, distribution, stack, risks | VIABLE / CONCERNS / HIGH RISK | cto-feasibility.md |
| CTO-ARCHITECTURE | cto | After `/create-architecture` drafts, and on major revision | `docs/architecture/architecture.md`, TR-IDs, ADRs | APPROVE / CONCERNS / REJECT | cto-architecture.md |
| CTO-ADR | cto | After `/architecture-decision`, before Accepted | ADR, stack pins, related ADRs | APPROVE / CONCERNS / REJECT | cto-adr.md |
| CTO-STACK-RISK | cto | Decision touches APIs beyond the stack reference or LLM cutoff | API/feature, `docs/stack-reference/` | APPROVE / CONCERNS / REJECT | cto-stack-risk.md |
| CTO-MANIFEST | cto | After `/create-control-manifest` preview, before write | manifest preview, ADRs covered | APPROVE / CONCERNS / REJECT | cto-manifest.md |
| CTO-CHANGE-IMPACT | cto | After `/propagate-spec-change` impact report | impact report | APPROVE / CONCERNS / REJECT | cto-change-impact.md |
| CTO-PHASE-GATE | cto | `/gate-check`, `workflow: standard` or `full` | target phase, artifacts, architecture, ADRs | READY / CONCERNS / NOT READY | cto-phase-gate.md |
| DD-CONCEPT-VISUAL | design-director | After principles lock (`/brainstorm`), parallel with PD-PRODUCT-PRINCIPLES | concept, principles, platforms, references | CONCEPTS / STRONG / CONCERNS | dd-concept-visual.md |
| DD-DESIGN-SYSTEM | design-director | After `PRODUCT.md` / `DESIGN.md` are written or revised via `/impeccable`, before UI production | `PRODUCT.md`, `DESIGN.md`, platforms, budgets | APPROVE / CONCERNS / REJECT | dd-design-system.md |
| DD-VISUAL | design-director | New surface type, token or style decision (`/team-ui`) | `DESIGN.md`, the decision, audit result | APPROVE / CONCERNS / REJECT | dd-visual.md |
| DD-PHASE-GATE | design-director | `/gate-check`, `workflow: full` | target phase, design artifacts | READY / CONCERNS / NOT READY | dd-phase-gate.md |
| PE-FEASIBILITY | principal-engineer | After `/create-architecture`, or a new pattern is proposed | architecture doc, TR baseline, ADRs | FEASIBLE / CONCERNS / INFEASIBLE | pe-feasibility.md |
| PE-CODE-REVIEW | principal-engineer | After a story is implemented (`/dev-story`, `/code-review`) | implementation paths, story, spec, ADRs | APPROVE / CONCERNS / REJECT | pe-code-review.md |
| PE-DOD | principal-engineer | `/story-done`, per story | story file, evidence directory, research note, ADRs | APPROVE / CONCERNS / REJECT | pe-dod.md |
| PR-SCOPE | producer | After scope tiers are defined (`/brainstorm`, `/map-domains`) | vision scope, MVP, timeline, team size | REALISTIC / OPTIMISTIC / UNREALISTIC | pr-scope.md |
| PR-EPIC | producer | After `/create-epics`, before `/create-stories` | epic structure, milestones, capacity | REALISTIC / CONCERNS / UNREALISTIC | pr-epic.md |
| PR-SPRINT | producer | Before `/sprint-plan` finalises; after mid-sprint scope change | sprint story list, capacity, milestone | REALISTIC / CONCERNS / UNREALISTIC | pr-sprint.md |
| PR-MILESTONE | producer | `/milestone-review`, or a scope change hitting a milestone | milestone, completion, blocked count, velocity | ON TRACK / AT RISK / OFF TRACK | pr-milestone.md |
| PR-PHASE-GATE | producer | Every `/gate-check` panel (all workflow tiers) | target phase, artifacts, sprint/milestone, capacity | READY / CONCERNS / NOT READY | pr-phase-gate.md |
| QL-STORY-READY | qa-lead | `/create-stories`, `/story-readiness` | story, type, criteria, TR-ID, research note | ADEQUATE / GAPS / INADEQUATE | ql-story-ready.md |
| QL-TEST-COVERAGE | qa-lead | `/story-done`, per story | stories + types, test paths, spec criteria, evidence | ADEQUATE / GAPS / INADEQUATE | ql-test-coverage.md |
| SL-THREAT-MODEL | security-lead | After `/threat-model`; `/story-readiness` and `/dev-story` for sensitive stories | threat model, spec, architecture data flow | APPROVE / CONCERNS / REJECT | sl-threat-model.md |
| SL-TENANT-ISOLATION | security-lead | `/tenant-check`; `/story-done` for stories touching tenant data; `/security-audit` | scoping code, RLS migrations, negative tests | APPROVE / CONCERNS / REJECT | sl-tenant-isolation.md |
| SL-RELEASE-SECURITY | security-lead | `/gate-check` Hardening → Release; `/release-checklist`, `/team-release` | control mapping, scan results, vulnerabilities, secrets | READY / CONCERNS / NOT READY | sl-release-security.md |
| SRE-SLO | sre-lead | `/gate-check` Hardening → Release (`workflow: full`); `/observability-plan` | `docs/architecture/slos.md`, alert rules, runbooks | READY / CONCERNS / NOT READY | sre-slo.md |
| SRE-OPERABILITY | sre-lead | `/gate-check` Hardening → Release; `/release-checklist`, `/team-release`, `/launch-checklist` | observability, backups + restore drill, capacity, rollback plan | READY / CONCERNS / NOT READY | sre-operability.md |

No separate gate covers written content. Documentation tone and
microcopy are reviewed by PD-SPEC-ALIGN and DD-VISUAL, not by a separate gate.

---

## Review Modes

Review intensity controls whether gates run.

**Global config**: `modes.review_mode` in `project.yaml` — one word: `full`,
`lean`, or `solo`. Legacy fallback: `production/review-mode.txt` (single line,
same values); `project.yaml` wins when both are present. `/start` never writes
it: left unset, it follows `modes.rigor` (`minimal` → `solo`, `standard` →
`lean`, `full` → `full`). Set it explicitly only with
`/settings modes.review_mode=<value>`.

**Per-run override**: any gate-using skill accepts `--review [full|lean|solo]`,
overriding the global config for that run only.

| Mode | What runs |
|------|-----------|
| `full` | All gates active — every workflow step reviewed |
| `lean` | PHASE-GATEs only (`/gate-check`) — per-skill gates skipped. The `rigor: standard` value |
| `solo` | No director gates anywhere (prototypes, spikes, max speed). **Default** — the `rigor: minimal` value |

**One exception (release readiness):** at the Hardening → Release transition
`/gate-check` also spawns SL-RELEASE-SECURITY, SRE-OPERABILITY and (at
`workflow: full`) SRE-SLO. Spawned by `/gate-check` they are PHASE-GATE-class:
they run in `lean` and `full`, and are skipped only in `solo`. Spawned by any
other skill (`/release-checklist`, `/team-release`, `/launch-checklist`,
`/observability-plan`) they follow the ordinary per-skill rule.

**Solo skips review, never evidence.** A skipped gate waives the *director's
opinion*, not the Definition of Done. The eight DoD gates in
`coding-standards.md` apply at every review mode and every workflow tier;
`/story-done` still checks each one mechanically even when PE-DOD,
QL-TEST-COVERAGE or SL-TENANT-ISOLATION are skipped. A skipped gate is recorded
as skipped, never as passed.

---

## Invocation Pattern (copy into any skill)

**MANDATORY: apply the review mode before every gate spawn.**

The value is already resolved — skills call
`` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode` ``
(with the matching `allowed-tools` grant — see `config-resolution.md`)
and read `review_mode` from the emitted block. Do **not** re-derive it here. The
full chain (`project.local.yaml` → `project.yaml` → `production/review-mode.txt`
→ `modes.rigor` expansion, `standard`→`lean`), its defaults and its failure modes are specified in
`.claude/docs/config-resolution.md`.

An inline `--review [mode]` argument, if the skill accepts one, overrides the
resolved value for that run.

Apply the resolved mode:
- `solo` → **skip all gates**. Note: `[GATE-ID] skipped — Solo mode`
- `lean` → **skip unless this is a PHASE-GATE** (PD-PHASE-GATE, CTO-PHASE-GATE, PR-PHASE-GATE, DD-PHASE-GATE) **or a release-readiness gate spawned by `/gate-check`** (see the exception above). Note: `[GATE-ID] skipped — Lean mode`
- `full` → spawn as normal

> **PHASE-GATE panel width is a second, independent axis.** `review_mode` decides
> whether the four PHASE-GATEs run at all; `modes.workflow` decides how many of
> them run — `minimal` → PR only, `standard` → CTO + PR, `full` → all four
> (PD, CTO, PR, DD). The rule and its rationale live in `/gate-check`, the only
> skill that spawns PHASE-GATEs. Every other gate in this index is single-owner
> and unaffected. Width never softens a verdict: the escalation rule below
> applies unchanged to whoever ran.
>
> The Hardening → Release release-readiness gates have their own width, because
> they check engineering floors, not documents: SL-RELEASE-SECURITY and
> SRE-OPERABILITY run at every tier; SRE-SLO runs at `full` only (the SLO
> document is not required below `full` — `workflow-modes.md` — so below `full`
> `/gate-check` records `SRE-SLO skipped — not required at workflow: [tier]`).
> A product with `distribution.model: self-hosted` and no hosted edition records
> `SRE-SLO skipped — self-hosted only`; SRE-OPERABILITY still runs against the
> customer bundle.

```
# Apply mode check, then:
Spawn `[agent-name]` via `Agent`:
- Gate: [GATE-ID] — `Agent` prompt instructs the agent to read
  `.claude/docs/director-gates/[gate-id].md` FIRST (parent must not read it)
- Context: [fields under that gate's **Context to pass**]
- Await the verdict before proceeding.
```

For parallel spawning (multiple directors at one gate point): apply the mode
check per gate, then spawn all surviving agents simultaneously — issue all `Agent`
calls before waiting for any result; collect all verdicts before proceeding.

---

## Standard Verdict Format

Every gate returns one of its three verdicts — or NOT ASSESSED when it could not
judge. Skills must handle all four. The three judgement words are each gate's
own — its definition file's **Verdicts** line is the authority — and the rows
below are their meanings (CTO-FEASIBILITY's VIABLE / CONCERNS / HIGH RISK,
PR-MILESTONE's ON TRACK / AT RISK / OFF TRACK, SRE-OPERABILITY's READY /
CONCERNS / NOT READY). NOT ASSESSED is the same word at every gate, so no
Verdicts line lists it:

| Verdict | Meaning | Default action |
|---------|---------|----------------|
| **APPROVE / READY** | No issues. Proceed. | Continue the workflow |
| **CONCERNS [list]** | Issues present but not blocking. | Surface to user via `AskUserQuestion` — options: `Revise flagged items` / `Accept and proceed` / `Discuss further`. Revise flagged items: the specialist who drafted the section re-drafts it; the revision goes through the skill's normal approve-then-write step, and the header records `REVISED [date]`. |
| **REJECT / NOT READY [blockers]** | Blocking issues. Do not proceed. | Surface blockers to user. Do not write files or advance stage until resolved. |
| **NOT ASSESSED [what was missing]** | An input the gate names was missing or unreadable, so no judgement was made. | Name what was missing. Never treat it as APPROVE/READY: supply the input and re-run the gate, or record NOT ASSESSED and let the skill's own verdict reflect it. |

Each gate's three words map onto the first three rows in order (best / middle /
worst): `FEASIBLE`, `ADEQUATE`, `REALISTIC`, `ON TRACK`, `VIABLE`, `STRONG` sit
with APPROVE / READY; `GAPS`, `OPTIMISTIC`, `AT RISK` sit with CONCERNS;
`INFEASIBLE`, `INADEQUATE`, `UNREALISTIC`, `OFF TRACK`, `HIGH RISK` sit with
REJECT / NOT READY. DD-CONCEPT-VISUAL's `CONCEPTS` (several valid options, the
user selects) is an APPROVE-class outcome that needs a choice before proceeding.

**Rank**: NOT ASSESSED sits below REJECT / NOT READY and CONCERNS, and above
APPROVE / READY — a known problem is more actionable than an unknown, and a gate
that could not look has approved nothing. A director that found a problem and
also lacked an input answers with the problem's word and names the missing
input in its rationale. An artifact the skill reports as absent is information,
not a missing input. At a phase gate,
a missing artifact the target phase requires is a finding (NOT READY or
CONCERNS); one `/gate-check` passes as "not expected before [phase]" or "not
required at `workflow: [tier]`" is not a finding — a phase gate judges
readiness for the phase being entered, not a later one.

**Escalation rule**: When multiple directors are spawned in parallel, apply the
strictest verdict by that rank — one NOT READY overrides all READY verdicts, and
one NOT ASSESSED keeps the result from being READY.

### How a gate cites evidence

The agent returns only the verdict words its gate lists, or NOT ASSESSED naming
the missing input. Every check is answered with a `file:line` reference or a
number — a count, a measured value, a budget and the gap to it — never an
impression ("looks fine", "seems robust"). A check the agent could not perform
is reported as `not checked` with the reason; it is never counted as met. A
scan, test run or restore drill that was not run is reported as not run, and
that is a finding or a NOT ASSESSED, never a pass.

### Standard output block

Every gate returns this block (a gate file adds rows, never removes them):

```
## [GATE-ID] — Verdict: <the gate's verdict word> | NOT ASSESSED
## Checks
| # | Check | Result (met / not met / not checked) | Evidence (file:line or number) |
## Findings (CONCERNS or blockers only)
- [BLOCKER|MAJOR|MINOR] location — problem → fix (standard or rule cited)
## Missing inputs (NOT ASSESSED, or any check that could not run)
- input — why it was needed
```

---

## Recording Gate Outcomes

After a gate resolves, record the verdict in the relevant document's status header:

```markdown
> **[Director] Review ([GATE-ID])**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date] / NOT ASSESSED [date] — [missing input]
```

For phase gates, record in `docs/architecture/architecture.md` or
`production/session-state/active.md` as appropriate. For story-level gates
(PE-CODE-REVIEW, PE-DOD, QL-*, SL-TENANT-ISOLATION), record in the story file's
status header. A DoD waiver is never a gate verdict: it is a written reason in
the story file, approved by the user, and PE-DOD reports it as `waived`.

---

## Parallel Gate Protocol

At checkpoints needing multiple directors (most common at `/gate-check`):

```
Spawn in parallel (issue all `Agent` calls before waiting for any result):
product-director → PD-PHASE-GATE, cto → CTO-PHASE-GATE,
producer → PR-PHASE-GATE, design-director → DD-PHASE-GATE
(at Hardening → Release, also: security-lead → SL-RELEASE-SECURITY,
 sre-lead → SRE-OPERABILITY, and at `full` sre-lead → SRE-SLO)

Collect every verdict from the directors that ran, then apply escalation rules:
- Any NOT READY / REJECT → overall verdict minimum FAIL
- Any CONCERNS → overall verdict minimum CONCERNS
- Any NOT ASSESSED (and no NOT READY / REJECT or CONCERNS) → overall verdict at best NOT ASSESSED
- All READY / APPROVE → eligible for PASS (still subject to artifact checks)
```

---

## Gate Coverage by Stage

| Stage | Required Gates | Optional Gates |
|-------|---------------|----------------|
| **Discovery** | PD-PRODUCT-PRINCIPLES, DD-CONCEPT-VISUAL | CTO-FEASIBILITY, PR-SCOPE |
| **Product Design** | CTO-CONTEXT-BOUNDARY, PD-FEATURES, PR-SCOPE, PD-SPEC-ALIGN (per spec) | DD-VISUAL, CTO-CHANGE-IMPACT (on spec revision) |
| **Architecture** | CTO-ARCHITECTURE, CTO-ADR (per ADR), CTO-MANIFEST, PE-FEASIBILITY, DD-DESIGN-SYSTEM, SL-THREAT-MODEL (per sensitive feature) | CTO-STACK-RISK |
| **Pre-Production** | PR-EPIC, QL-STORY-READY (per story), PR-SPRINT, SL-THREAT-MODEL (per sensitive story), the PHASE-GATE panel (via gate-check — PR at `minimal`, CTO + PR at `standard`, all four at `full`) | PD-USABILITY |
| **Production** | PE-CODE-REVIEW (per story), QL-STORY-READY, PR-SPRINT (per sprint), QL-TEST-COVERAGE and PE-DOD (per story, via `/story-done`), SL-TENANT-ISOLATION (per story touching tenant data) | PR-MILESTONE, DD-VISUAL, CTO-CHANGE-IMPACT (on spec revision) |
| **Hardening** | PD-USABILITY, PR-MILESTONE | DD-VISUAL, SL-TENANT-ISOLATION (full sweep) |
| **Release** | The PHASE-GATE panel (via gate-check — PR at `minimal`, CTO + PR at `standard`, all four at `full`), SL-RELEASE-SECURITY, SRE-OPERABILITY, SRE-SLO (at `full`) | — |
| **Live** | PR-MILESTONE (per milestone) | CTO-CHANGE-IMPACT (on spec revision), PD-USABILITY |
