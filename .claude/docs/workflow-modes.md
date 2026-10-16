# Workflow Modes — Shared Skill Pattern

This document defines `modes.workflow` and `workflow_overrides` — how much
**product documentation** is required before code begins — for every skill that
authors, reviews, gates or plans against project artifacts. Skills reference
this document instead of embedding the tier tables inline.

> **Workflow tiers scale documents, never engineering.** The eight Definition
> of Done gates in `coding-standards.md` — research, clean architecture, tests,
> observability, caching, performance, security, decision record — apply at
> **every** tier. `minimal` means fewer documents, not weaker code. The only
> gate a tier changes is *where* decisions are recorded (ADR files vs. the
> decision log in the product brief).

**Related shared docs**: `automation-modes.md` (how skills prompt),
`director-gates.md` (which reviewers spawn — Wave 6). `workflow` is orthogonal
to both.

---

## Resolution (per skill)

```
1. If the resolution is for a named feature AND
   `workflow_overrides.system_overrides.<feature>` is set → use that tier
2. Else read `modes.workflow` from `project.yaml` → use that value
3. Else → use the tier implied by `modes.rigor`
   (`minimal`→`minimal`, `standard`→`standard`, `full`→`full`;
    `rigor` itself defaults to `minimal`)
```

Read it with **`resolve_config --keys workflow`** (or `resolve_setting
modes.workflow`), which applies the whole chain including the rigor expansion.
Do **not** use `get_effective_yaml_key modes.workflow`: it returns empty on a
project that sets only `modes.rigor`. `modes.workflow` is locked to
`project.yaml` (not locally overridable).

### What `<feature>` is

**The spec filename stem**: `design/specs/team-invitations.md` →
`team-invitations`. That is the key under
`workflow_overrides.system_overrides` (the key name is inherited and kept for
config compatibility). A story's `TR-[feature]-NNN` segment is an alias,
accepted only as a fallback when the stem yields nothing.

**A key that matches no spec is an error, not a no-op** — reported by
`/gate-check` at a phase boundary, naming the unmatched key and the stems
available. Authoring skills that *create* the spec must not report it, since
before their first run the key matches nothing by definition.

> **"Critical ADR"**: an ADR governing a foundation concern — tenancy model,
> identity/auth, data store choice, messaging, API style, deployment topology,
> licensing. At `standard` only critical ADRs are required; when in doubt,
> treat an ADR as critical.

---

## The Three Tiers

| Tier | Required before code | Best for |
|---|---|---|
| `full` | Product brief, domain map, all 8 spec sections per feature, architecture doc, all ADRs, UX spec per screen, threat model per sensitive feature, SLOs | Products with enterprise/self-hosted customers, regulated data, or several engineers |
| `standard` | Product brief, domain map, 5 spec sections per feature (+ conditionals), architecture doc, critical ADRs, threat models for sensitive features | Most products once past the first version |
| `minimal` | One-page `design/product-brief.md` (its build-order field is the plan) + stack configured + a research note per feature | **Default.** New products, internal tools, validated-fast ideas |

> **`minimal` floor.** Even at minimal: a filled `design/product-brief.md`, a
> configured stack (`/setup-stack`), and `docs/research/<feature>.md` before
> each feature's code. Decisions go in the brief's decision log instead of ADR files.

> **Permissive, not restrictive.** `workflow` controls what is REQUIRED, not
> what is ALLOWED. Any skill can run at any tier.

---

## Feature Spec Sections

The 8 spec sections (`design/specs/<feature>.md`, template in Wave 6):

1. **Overview** — what it is, in one paragraph
2. **User Value** — who needs it, the job it does for them, how it affects plan/pricing
3. **Detailed Behaviour** — unambiguous rules, states, permissions per role
4. **Data & Contracts** — entities, API endpoints (link to `contracts/`), events, retention
5. **Edge Cases & Failure Modes** — invalid input, concurrency, provider outage, partial failure, abuse
6. **Dependencies** — bounded contexts, core modules, external providers, feature flags
7. **Non-Functional Requirements** — security (ASVS/MASVS refs, threat model link), performance budget, caching decision, observability (spans/metrics/alerts), accessibility, localization (AR/EN, RTL)
8. **Acceptance Criteria** — testable, including negative and cross-tenant cases

| Tier | Required spec sections |
|---|---|
| `full` | All 8 |
| `standard` | **5 required**: Overview, Detailed Behaviour, Data & Contracts, Non-Functional Requirements, Acceptance Criteria. **Conditional**: Edge Cases & Failure Modes — required when the feature calls an external provider, moves money, changes entitlements, or runs asynchronously. **Optional**: User Value, Dependencies. |
| `minimal` | None — the product brief and the research note cover it. A spec may still be written voluntarily. |

---

## `workflow_overrides`

```yaml
workflow_overrides:
  # --- boolean FLAGS: additive, stricter-only ---
  edge_cases: false          # force Edge Cases required at every tier
  tuning_knobs: false        # force a "Configuration" subsection (limits, quotas, flags) in Non-Functional

  # --- system_overrides: replaces a tier, BOTH directions ---
  system_overrides: {}       # per-feature tier overrides
```

**Flags only ever add requirements.** **`system_overrides` replaces the tier
for one feature in either direction**: on a `standard` project,
`system_overrides.billing: full` makes billing require all 8 sections, and
`system_overrides.changelog-page: minimal` drops that feature's spec
requirement. A loosening override genuinely loosens — never leave one in place
assuming it is harmless.

### Worked example

`modes.workflow: standard`, `system_overrides.billing: full`:

- `/design-spec billing` → **full** → all 8 sections
- `/design-spec team-invitations` → **standard** → 5 sections + Edge Cases (it sends email)
- `/gate-check` (Product Design → Architecture) → billing at 8 sections AND every other MVP spec at its standard set

---

## Per-Skill Behaviour (runtime summary)

**Authoring** — branch on the effective tier: `brainstorm` (brief at `minimal`,
full concept at `standard`/`full`), `design-spec`, `map-domains`,
`create-architecture`, `ux-design`, `architecture-decision`, `threat-model`.

**Review/validation** — missing *required* sections block, missing *optional*
warn: `spec-review`, `review-all-specs`, `architecture-review`,
`consistency-check`, `content-audit`.

**Gate enforcement** — `gate-check` loads only the gate it runs from
`.claude/skills/gate-check/references/gate-<phase>.md`.

**Planning/implementation** — adjust artifact prerequisites: `create-epics`,
`create-stories`, `dev-story`, `story-readiness`, `story-done`, `qa-plan`,
`regression-suite`. The DoD gates themselves do not change.

**Support** — adjust "what's missing" expectations: `project-stage-detect`,
`adopt`, `reverse-document`, `propagate-design-change`, `help`, `studio`.

**`/studio` and the orchestrator** plan by tier: `studio/references/3-flows.md`
(section 0 and the per-tier tables) is the one place the step list per tier lives,
and `claude --agent studio-orchestrator` reads it rather than keeping a copy. A
step a tier drops is reported as `skipped — tier`, distinct from `skipped —
trigger absent`; the engineering gates never appear in a tier-dropped list.

---

## Workflow Change Mid-Project

When `workflow` changes via `/settings`: "Workflow changed from [old] to [new].
Run `/content-audit` to see what's now required or extra. No automatic
migration — existing files stay in place."

---

## Companion Settings (all fronted by `modes.rigor`)

- **`docs.density`** (`terse` | `balanced` | `thorough`) — how deep each section goes.
- **`modes.story_granularity`** (`coarse` | `balanced` | `fine`) — story size.
- **`qa.level`** (`minimal` | `standard` | `full`) — what test evidence is required to close a story; composes with `testing.strict` (does a failure block). Security and run-and-observe evidence are required at every level.
- **`team.size`** (`individual` | `small` | `studio`) — which agents are active by default.
