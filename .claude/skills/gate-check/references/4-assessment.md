# /gate-check — Sections 4 and 4b: Assessment and Director Panel

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 4. Collaborative Assessment

**In this file:**

- 4. Collaborative Assessment: unverifiable items are never PASS
- 4b. Director Panel Assessment: `review_mode` decides whether directors spawn, `workflow` decides the panel width
- Gate IDs and the release-readiness gates
- Naming the omissions, and applying the panel to the verdict

For items that can't be automatically verified, **ask the user**:

- "I can't automatically verify that a real user has completed the core journey unguided. Has a usability session been run?"
- "No usability report found. Has informal testing been done with someone from the ICP?"
- "No load-test results are on disk. Would you like to run `/load-test`?"
- "I can't see whether the restore drill ran. When was the last one, and where is the record?"

**Never assume PASS for unverifiable items.** Mark them as MANUAL CHECK NEEDED.
An answer resolves the item: "no" or "not yet" is a checked, failed item
(CONCERNS or FAIL, naming the skill that closes it — `/spec-review [doc]` for
an unreviewed spec) — except a usability question at the Pre-Production →
Production gate (a human has used the vertical slice unguided; at `minimal`, the
core journey delivers its value on the current build), where "not yet" means
nobody has used it: NOT ASSESSED (`gate-production.md`). Only an unanswered item
or "I don't know" stays MANUAL CHECK NEEDED, which Section 5 turns into
NOT ASSESSED.

This applies to questions about the product's state. Declining an offer to
produce missing data (e.g. `/load-test`, `/perf-profile`) leaves the item NOT
ASSESSED; at `performance.enforce: off` it stays out of the verdict.

**Never ask the user to run something against production, to paste a secret, or
to make a real payment.** Where a gate needs production evidence (Release →
Live), ask for the retained record of what *they* did, and mark the item NOT
ASSESSED if there is none.

---

## 4b. Director Panel Assessment

The panel is set by **two independent axes**, both resolved in Section 1: `review_mode`
decides *whether* the panel runs, `workflow` decides *how wide* it is.

**Axis 1 — `review_mode` decides whether any director spawns:**
- `solo` → skip the panel entirely. Note in output: "Director Panel skipped — Solo mode. Gate verdict based on artifact, evidence and quality checks only." Proceed to Section 5.
- `lean` → run the panel (phase gates always run in lean mode — this is their purpose).
- `full` → run the panel.

**Axis 2 — `workflow` decides the panel width.** Directors are Opus-tier, so the
panel is sized to the product rather than fixed at four. The gate still runs at
every tier; only its breadth scales (`.claude/docs/director-gates.md`):

| `workflow` | Panel | Directors |
|---|---|---|
| `minimal` | 1 | `producer` |
| `standard` | 2 | `cto`, `producer` |
| `full` | 4 | `product-director`, `cto`, `producer`, `design-director` |

`producer` is in every panel — scope and schedule readiness is the one judgment
no tier makes optional. `cto` joins at `standard` because that is the first tier
requiring architecture artifacts. `product-director` and `design-director` join
at `full`, the only tier requiring the complete spec, UX and design-system set
for them to assess.

> **Width is not the same as strictness.** A narrower panel does not soften the
> verdict: the escalation rule in `.claude/docs/director-gates.md` is unchanged —
> the strictest verdict returned by *whoever ran* still wins. Do not infer PASS
> from a perspective that was never consulted.

Before generating the final verdict, spawn the directors for the resolved tier as **parallel subagents** via `Agent` using the parallel gate protocol from `.claude/docs/director-gates.md`. Issue all the `Agent` calls simultaneously — do not wait for one before starting the next.

**Gate IDs** (the `Agent` prompt for each tells the agent to read its gate file
FIRST — this session does not read the gate files):

1. **`product-director`** — gate **PD-PHASE-GATE** (`.claude/docs/director-gates/pd-phase-gate.md`)
2. **`cto`** — gate **CTO-PHASE-GATE** (`.claude/docs/director-gates/cto-phase-gate.md`)
3. **`producer`** — gate **PR-PHASE-GATE** (`.claude/docs/director-gates/pr-phase-gate.md`)
4. **`design-director`** — gate **DD-PHASE-GATE** (`.claude/docs/director-gates/dd-phase-gate.md`)

Pass to each the target phase name, the resolved `workflow` tier, the target
gate's required and recommended artifacts at the resolved tier (the loaded gate
file's checklist after its tier reduction — what
this gate asks for, not what a later one will), the list of artifacts present,
and its gate's own context — named here, so this session never has to read the
gate files:
- **PD-PHASE-GATE**: the product principles, ICP and core value (from
  `design/product-brief.md`), and the pricing / edition model it states.
- **CTO-PHASE-GATE**: the architecture document path, the stack reference path
  (`docs/stack-reference/`) and `pins.yaml`, and the ADR list with statuses.
- **PR-PHASE-GATE**: the sprint and milestone artifacts present, `team.size` as
  resolved above (with the current sprint plan's capacity, if a plan exists), and
  the number of stories under `production/epics/` whose status is `Blocked`. At
  `workflow: minimal`, pass the Build order in `design/product-brief.md` as the plan — that
  tier has no sprint plan.
- **DD-PHASE-GATE**: the design artifacts present — `PRODUCT.md` and `DESIGN.md`
  at the repository root, `design/ux/` specs, `/impeccable audit` results and
  screenshots in `production/qa/evidence/` — the visual identity anchor (from
  `PRODUCT.md`, else the brief), and `accessibility.target` from `project.yaml`.

Pass each context item as one of three things, so no director has to guess:
- **Present** — its path or value (`0` blocked stories is a value).
- **"none"** — the target gate (or an earlier one) requires or recommends it at
  this tier and it does not exist (no architecture document at
  `/gate-check pre-production`). For the director that is a fact about the
  product to judge, not a missing input.
- **"not expected before [phase]"** — the target gate does not ask for it yet;
  name the phase whose gate first does (the architecture document and ADRs
  before Pre-Production, the sprint plan before Production). One this tier never
  requires is "not required at `workflow: [tier]`" (any sprint plan at
  `minimal`). Neither is ever passed as "none", and neither is a finding — a
  director judges readiness for the phase being entered, not a later one.

### Release-readiness gates (Hardening → Release only)

At `/gate-check release`, three more reviewers join the PHASE-GATE panel. They
check engineering floors, not documents, so their width is their own
(`.claude/docs/director-gates.md` "Review Modes" and "Invocation Pattern"):

| Gate | Agent | Runs at | Recorded as skipped when |
|---|---|---|---|
| **SL-RELEASE-SECURITY** | `security-lead` | every `workflow` tier | `solo` only |
| **SRE-OPERABILITY** | `sre-lead` | every `workflow` tier | `solo` only |
| **SRE-SLO** | `sre-lead` | `workflow: full` only | `solo`; `SRE-SLO skipped — not required at workflow: [tier]` below `full`; `SRE-SLO skipped — self-hosted only` when `distribution.model: self-hosted` with no hosted edition |

Spawned by `/gate-check` they are PHASE-GATE-class: they run in `lean` and
`full`, and are skipped only in `solo` (where their *evidence* is still checked
mechanically by the gate file). Spawn them in the same parallel batch as the
panel. Pass each only what its gate lists, as Present / "none" / "not expected":
- **SL-RELEASE-SECURITY**: the release identifier and commit range; the editions
  shipping (hosted, self-hosted bundle, Android, iOS); the control mapping
  (latest `/security-audit` report in `production/qa/` and the per-story
  security evidence in `production/qa/evidence/`); the threat models under
  `docs/architecture/threat-models/` and their SL-THREAT-MODEL verdicts; scan
  results for the release commit (tool, version, scope, result — or "not run");
  the open vulnerability register; the SL-TENANT-ISOLATION verdict for the
  release; the standards pinned in `.claude/docs/security-baseline.md`.
- **SRE-OPERABILITY**: `distribution.model` and `deploy.target`; observability
  evidence; backup configuration, documented RPO/RTO and the latest restore-drill
  record; capacity evidence (load-test results against the budget); the
  rollback plan and migration plan; `docs/runbooks/` and alert rules.
- **SRE-SLO**: `docs/architecture/slos.md`; the critical journeys; alert rule
  files and dashboards; `docs/runbooks/`; budgets and load-test results.

**Name the omissions in the output.** Below the Director Panel summary, when the
panel ran narrower than four, state which perspectives did not run and how to get
them — e.g. "Panel: 2 of 4 (`workflow: standard`). Product and Design
perspectives not consulted. Raise `modes.rigor` to `full` (or set
`modes.workflow: full`) for the complete panel." Name the setting the config block
shows as `workflow`'s source: when `modes.workflow` is set on its own, raising
`modes.rigor` does not change it. Never point to `--review full` for this —
`--review` decides whether the panel runs, not how wide it is. A silently narrow
panel reads as a clean bill of health from reviewers who never looked. The same
rule applies to each release-readiness gate that was skipped: name it and the
reason.

**Collect every response from the directors that ran, then present the Director Panel summary** (one row per director that ran; name the ones `workflow` left out):

```
## Director Panel Assessment

Product Director:   [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]

CTO:                [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]

Producer:           [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]

Design Director:    [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]

Release readiness (Hardening → Release only):
Security Lead   (SL-RELEASE-SECURITY): [READY / CONCERNS / NOT READY / NOT ASSESSED / skipped — reason]
SRE Lead        (SRE-OPERABILITY):     [READY / CONCERNS / NOT READY / NOT ASSESSED / skipped — reason]
SRE Lead        (SRE-SLO):             [READY / CONCERNS / NOT READY / NOT ASSESSED / skipped — reason]
```

**Apply to the verdict:**
- Any director returns NOT READY → verdict is minimum FAIL (no override turns a FAIL into a stage change — Section 6)
- Any director returns CONCERNS → verdict is minimum CONCERNS
- Any director returns NOT ASSESSED (and none returned NOT READY or CONCERNS) → verdict at best NOT ASSESSED; name the input that director said was missing — it never counts as READY
- Every director that ran returns READY → eligible for PASS (still subject to artifact and quality checks from Section 3)

---
