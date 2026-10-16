# /gate-check — Section 2b: Workflow Tier Adjustment

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 2b. Workflow Tier Adjustment

**In this file:**

- How to apply a gate file's tier reductions
- `qa.level` and the test items; the required tests, the smoke check, security evidence and run-and-observe evidence are the floor
- A gate with no required artifacts left is NOT ASSESSED, with one exception
- `performance.enforce`
- Per-feature overrides (`workflow_overrides.system_overrides`), the unmatched-key error, and the additive overrides

Each gate file carries its own tier reductions (see Section 2). Rules that apply
across all of them:

> **How to apply:** run the loaded gate's checklist, then apply that file's tier
> reduction for the tier resolved in Section 1. **drop** = not checked at this
> tier; **→ recommended** = absent surfaces as CONCERNS, never a Blocker; items
> not named keep their baseline status. Reductions only ever *relax* a
> requirement — the only thing that adds one is `workflow_overrides` (below).
>
> **Tiers scale documents, never engineering.** The eight Definition of Done
> gates (`.claude/docs/coding-standards.md`) apply at every tier. A gate file's
> reduction may drop a *document* (an ADR, a spec section, a UX spec); it never
> drops a *floor* the file marks as one — and the floors are listed by name in
> each gate file under "Floors at every tier". Where a reduction and a floor
> seem to collide, the floor wins.
>
> **`qa.level` (Section 1) never relaxes the required tests.** Logic,
> Integration, Contract and Security tests must exist and pass at every
> `qa.level` and every workflow tier (`.claude/docs/coding-standards.md` gate 3);
> the Section 3 `testing.strict` check runs at every level. `qa.level` changes only
> the *extra* evidence a gate asks for (coverage signal, manual cases, regression
> suite, UAT): those items are required at `standard` / `full` and recommended at
> `minimal`.
>
> **The evidence that the product was run is never relaxed either.** The
> following are required at every `qa.level` wherever a gate file asks for
> story evidence (`.claude/docs/coding-standards.md`: "A compile is not a run";
> `.claude/docs/workflow-modes.md`: security and run-and-observe evidence are
> required at every level):
> - a UI story's retained screenshots (desktop and mobile; Arabic RTL and
>   English) and `/impeccable audit` result in `production/qa/evidence/`;
> - a Security story's negative tests (authz bypass, cross-tenant, injection) and
>   ASVS/MASVS mapping;
> - the run-and-observe record for any story that changes something a user can
>   see or call (`.claude/docs/run-and-observe.md`).
>
> **The smoke check is a floor too.** A smoke check is **build health**, not
> story evidence, and the two are held apart in
> `.claude/docs/coding-standards.md`. A gate file that requires a smoke report
> keeps requiring it at every `qa.level`.
>
> Without these floors the Production → Hardening gate had **zero required
> artifacts at `rigor: minimal`** and could not fail on artifacts by
> construction; the required tests and the smoke check keep it falsifiable.

> **A gate with no required artifacts left must say so, and may not return
> PASS.** After applying the tier reduction, count
> what remains required. If the count is zero, report
> **NOT ASSESSED** naming the reducer and the gate — *"<gate> at
> `workflow: minimal` leaves no required artifact; this gate verified nothing"* — rather than a PASS earned by having nothing to check.
> Per `.claude/rules/skill-authoring.md` obligation 1, a run that could not
> assess its scope has not established that the scope is good, and obligation 3
> requires the emptiness to be visible in the output rather than inferable from
> a silent green.
>
> **The one exception: a gate its tier reference file marks "not applicable" at
> this tier** (Product Design → Architecture at `workflow: minimal`, see
> `gate-architecture.md`). That is not a gate with nothing left to check but a
> transition the tier does not have: it PASSes with that file's note, printed in
> the report. The director panel does not run for it — note "Director Panel
> skipped — gate not applicable at `workflow: [tier]`" — and the Section 6
> stage write still asks first. A per-feature override that pins a feature
> *above* the project tier removes the exception for that feature (below).
>
> **`performance.enforce` is likewise independent of the tier, and a tier
> reduction never suppresses it.** The performance check in Section 3 runs at
> every workflow tier from Production → Hardening on, and `block` makes a breach
> a Blocker at every tier. Do **not** read a gate file's *"everything else
> drops"* as dropping it: `off` is the only thing that makes budgets
> informational, and it is a deliberate choice the user makes on the same key.
>
> Without this, `performance.enforce: block` is **inert on every `rigor: minimal`
> project** — the Hardening gate's `minimal` reduction drops everything outside its
> floor, and "Performance is within budget" sits in the dropped remainder. A
> setting that works only when a rule is disregarded is not wired.

### Per-feature overrides (`workflow_overrides.system_overrides`)

Independent of the project-level tier above, and applied **only** on the gates
that validate feature specs (Product Design → Architecture, and the
spec-completeness checks at Architecture → Pre-Production and Pre-Production →
Production). The key name `system_overrides` is inherited and kept for config
compatibility; each key is a **feature**. For each feature, resolve its
effective tier:

1. If the block's `system_overrides` lists `<feature>` → that tier
2. Else the project-level `workflow`

**Before applying any of them, check the block the other way round: does every
KEY match a feature?** `<feature>` is the spec filename stem
(`.claude/docs/workflow-modes.md`), so for each key in `system_overrides`, look
for `design/specs/<key>.md`. Any key with no matching stem is reported, naming
the key and listing the stems that do exist:

> `system_overrides key 'no-such-feature' matches no spec in design/specs/. Available stems: billing, team-invitations, audit-log. This override is doing nothing.`

If `design/specs/` does not exist or holds no feature specs, the list reads
`Available stems: none` — an override with nothing to match is still an orphan
(an authoring skill that *creates* the spec does not report it, but this gate
runs at a phase boundary, where it should have matched). The one gate that skips
this check is Discovery → Product Design: no spec exists yet by definition.

Surface an orphan key as a **CONCERNS**-level finding, not a Blocker — the
project is still gateable, but an override the user believes is in force and is
not is exactly how a documented escape hatch silently stops working. Where a
Quick Spec (`design/quick-specs/`) holds the feature's spec instead, the key
matches on that stem too; say which directory matched.

This is the rule in `.claude/docs/workflow-modes.md`: a key that matches no
feature is an error, not a no-op. The story skills resolve only in the
feature → override direction, so an orphan key is invisible to them;
`/gate-check`, which resolves the whole block, is where it is caught.

Validate each feature spec against its own effective tier's section set:

- A feature pinned **higher** than the project (e.g. `system_overrides.billing:
  full` on a `standard` project) **blocks the gate** until that feature's spec
  meets the higher bar (billing → all 8 sections). This is the one case where a
  per-feature setting makes the gate *stricter* than the project tier — and at
  `workflow: minimal` it also lifts the "not applicable" exemption for that one
  feature: its spec is checked at the pinned tier, every other feature stays
  unchecked, and the gate is no longer a bare auto-PASS.
- A feature pinned **lower** (e.g. `changelog-page: minimal`) relaxes only that
  feature — its spec is checked at the lower tier; every other feature stays at
  the project level. A feature pinned **`minimal` imposes no spec section
  requirement at all** (`minimal` = "product brief replaces specs" —
  `.claude/docs/workflow-modes.md`): it never blocks the gate on a missing or
  incomplete spec. Do not invent an "acceptance-criteria-only" floor for it —
  there is none. (Its research note, threat model if sensitive, and the eight
  DoD gates are untouched by the override: those are floors, not documents.)

> **Additive overrides (the only things that make the gate stricter).**
> - `workflow_overrides.edge_cases: true` and `workflow_overrides.tuning_knobs:
>   true` force those spec sections required when validating spec completeness,
>   additive on top of the resolved tier (e.g. at `standard`, `edge_cases: true`
>   makes the otherwise-conditional Edge Cases & Failure Modes section blocking;
>   `tuning_knobs: true` requires a "Configuration" subsection — limits, quotas,
>   flags — under Non-Functional Requirements). These never relax — a `false`
>   value is the default/no-op, never a way to drop a section the tier already
>   requires.

---
