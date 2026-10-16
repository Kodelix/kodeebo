# /design-spec — Phase 5: Post-Design Validation

> Part of `/design-spec`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 5. Post-Design Validation

**In this file:**

- 5-pre: Author the Summary
- 5a: Self-Check
- 5a-bis: Product Director Alignment Review
- 5b: Update Entity Registry
- 5c: Hand Off to Spec Review
- 5d: Update Domain Map
- 5e: Update Session State
- 5f: Suggest Next Steps

After all sections are written:

### 5-pre: Author the Summary

Write `## Summary` and its `> **Quick reference**` line now — after the spec
exists, so the summary distils real content rather than intentions. This runs
**at every tier**, including `standard` and a voluntary `minimal` spec: the
Summary is what lets a later skill scan 20 specs and decide which to read in full
(`/create-epics`, `/architecture-review`, `/review-all-specs` all grep it), so a
spec without it silently forces those consumers back to full reads.

- **Summary body**: 2–3 sentences — what this feature is, what it does for the
  user, why it exists in this product. No jargon; a reader who has not seen the
  spec should learn whether it is relevant to their task.
- **Quick reference**: `Layer`, `Priority` and `Bounded context` from the domain
  map (`design/specs/domain-map.md`); `Key deps` from the Dependencies section
  just written (contexts/providers, or `None`); `Plan gate` from Section B or the
  pricing model (plan/entitlement key, or `all plans`).
- **Carry the gaps**: if a stack reference, research note or perf budget was
  absent in Phase 2, or an ASVS ID is `NOT SOURCEABLE`, repeat each once under
  Open Questions with its owner. A gap that only lives in the conversation is
  gone by the next session.

Replace the `[To be designed]` Summary placeholder in the skeleton. Then apply
the section cycle's Write step as for any other section.

### 5a: Self-Check

Read back the complete spec from file (not from conversation memory — the file is
the source of truth). Verify:
- The `## Summary` and its Quick reference are populated (not the placeholder)
- Every section **required at this feature's effective tier** has real content
  (not placeholders) — §1: 8 at `full`, 5 + conditional Edge Cases at `standard`,
  5 at a voluntary `minimal`. Do not verify against a fixed count of 8: below
  `full` that reports a correctly-authored spec as incomplete
- Run `bash .claude/scripts/spec-structure-check.sh design/specs/[feature-name].md`
  and compare its PRESENT/ABSENT lines to the tier. The script reports presence
  only; you apply the tier. If it could not run, say so and rely on your own scan.
- Every NFR sub-heading (Security, Performance Budget, Caching Decision,
  Observability, Accessibility, Localization) is answered or states `n/a — <reason>`
- The permissions matrix has a row per action and the cross-tenant cell is `404`
- Formulas reference defined variables; money is integer minor units
- Edge cases have resolutions
- Dependencies are listed with interfaces; core modules named
- Acceptance criteria are testable, include the negative and cross-tenant cases, and carry a story type
- No price or quota number is restated — plan effects link to the pricing model

### 5a-bis: Product Director Alignment Review

**Review mode check** — apply before spawning PD-SPEC-ALIGN:
- `solo` → skip. Note: "PD-SPEC-ALIGN skipped — Solo mode." Proceed to Step 5b.
- `lean` → skip (not a PHASE-GATE). Note: "PD-SPEC-ALIGN skipped — Lean mode." Proceed to Step 5b.
- `full` → spawn as normal.

Before finalizing the spec, spawn `product-director` via `Agent` using gate **PD-SPEC-ALIGN** (`.claude/docs/director-gates/pd-spec-align.md`).

Pass: completed spec file path, product principles (from `design/product-principles.md`; if there is none, the pitch and ICP of `design/product-brief.md` and say so), the brief's positioning and ICP, the spec's User Value section (or the Overview, saying so, when this tier did not author one), and the feature's effective tier.

Handle verdict per the standard rules in `director-gates.md`.
On `Revise flagged items`, or to resolve a REJECT, each flagged section runs its
section cycle again — its specialist consulted as that section's review-mode
check says — and is re-approved through its "Approve the [Section Name]
section?" widget before the Edit that writes it; then record `REVISED [date]`.
A `NOT ASSESSED` answer is never an approval: name the missing input, then
supply it and re-run the gate, or record `NOT ASSESSED`.
After resolution, record the verdict in the spec Status header:
`> **Product Director Review (PD-SPEC-ALIGN)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date] / NOT ASSESSED [date] — [missing input]`

---

### 5b: Update Entity Registry

Scan the completed spec for cross-feature facts that should be registered:
- Named entities with their owning context and tenant key
- Entitlement keys and quota names (with their config source, never the number)
- Event and webhook names with producer and consumers
- Permission/role names introduced
- Named formulas with defined variables and output ranges

**First check the registry exists** — §2a reads it *"if it exists"*, and this
step must carry the same guard. At `standard` and below the file is often
absent, and a grep against a missing path returns nothing, which is
indistinguishable from "no candidate is registered yet":

- **Absent** — say so, and ask whether to create it:
  *"`design/registry/entities.yaml` does not exist. May I create it with these
  [N] entries?"* If the user declines, skip 5b and say the registry was not
  written — do not treat the skip as a clean pass.
- **Present but empty** — every list is `[]`, or the only matches are inside
  comment blocks. Treat it as present, register the candidates, but say which
  state you found: *"registry exists and is empty — all [N] entries are new."*
  Match entries under a live key, never a commented example — otherwise §2d
  presents invented values as *"locked"*.
- **Present** — for each candidate, check whether it is already registered:

```
Grep pattern="  - name: [candidate_name]" path="design/registry/entities.yaml"
```

Present a summary:
```
Registry candidates from this spec:
  NEW (not yet registered):
    - [entity_name] [entity]: owner=[context], tenant_key=[field]
    - [key] [entitlement]: source=[plan data / config]
    - [event_name] [event]: producer=[context], consumers=[list]
  ALREADY REGISTERED (referenced_by will be updated):
    - [quota_name] [quota]: source matches registry ✅
```

Ask: "May I update `design/registry/entities.yaml` with these [N] new entries
and update `referenced_by` for the existing entries?" (If the file was absent
and the user approved creating it, the wording is *create*, not *update*.)

If yes: append new entries and update `referenced_by` arrays. Never modify
existing owner / source fields without surfacing it as a conflict first.

### 5c: Hand Off to Spec Review

Present a completion summary:

> **Spec Complete: [Feature Name]**
> - Sections written: [list]
> - Provisional assumptions: [list any assumptions about unspecified dependencies]
> - Cross-feature conflicts found: [list or "none"]
> - Threat model required: [yes — `/threat-model` not yet run / no — reason]
> - Gaps carried (stack reference, research note, perf budget, ASVS IDs): [list or "none"]
> - Gates: [PD-SPEC-ALIGN verdict, or skipped — mode]

> **To validate this spec, open a fresh Claude Code session and run:**
> `/spec-review design/specs/[feature-name].md`
>
> **Never run `/spec-review` in the same session as `/design-spec`.** The reviewing
> agent must be independent of the authoring context. Running it here would inherit
> the full design history, making independent critique impossible.

**NEVER offer to run `/spec-review` inline.** Always direct the user to a fresh window.

### 5d: Update Domain Map

After the spec is complete (review is a separate, later session):

**First check the domain map exists.** §2a skips it at `minimal` because it is
never written at that tier.

- **Absent** — say so in one line (*"no `design/specs/domain-map.md` at this
  workflow tier; nothing to update"*) and skip to §5e. Do **not** offer to create
  one: `/map-domains` owns that file, and a stub written here would be a map
  listing exactly one feature.
- **Present** — continue:

- Read the domain map
- Update the target feature's row:
  - Status → "Designed" (pending review). `/spec-review` is never run in this
    session (§5c), so no review verdict exists yet; the independent `/spec-review`
    in a fresh session sets "Approved" or "Needs Revision" itself.
  - Spec: link to `design/specs/[feature-name].md`
- Update the Progress Tracker counts (specs started/reviewed/approved, features needing a threat model)

Ask: "May I update the domain map at `design/specs/domain-map.md`?"

### 5e: Update Session State

Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`, leaving the `Flow` line and any `/studio`
or team block alone, and append the Notes line:
- Current task: `/design-spec [feature-name] — spec complete, review pending`
  (`/spec-review` runs in a fresh session)
- Files in progress: design/specs/[feature-name].md
- Sections (in the Notes line): [list the sections actually authored, by name] —
  **never a fixed count**; below `full` a correctly-authored spec has fewer than
  8 sections, and writing "All 8 written" makes the next reader believe a
  complete spec is incomplete
- Next step: `/spec-review design/specs/[feature-name].md` in a fresh session, or
  the next feature from the specification order — the first item of §5f's
  recommendation
- Blocked on / Open questions: the blocker and the open questions this run left,
  or `nothing` / `none`

A run that ends early (skeleton declined, `BLOCKED`, `NOT ASSESSED`) updates the
checkpoint with the blocker at that point.

### 5f: Suggest Next Steps

Use `AskUserQuestion`:
- "What's next?"
  - Options:
    - "Run `/threat-model [feature-name]` — the spec flagged a sensitive area (offer only when G1 said yes)"
    - "Run `/consistency-check` — verify this spec's names and values don't conflict with existing specs (recommended before specifying the next feature)"
    - "Specify next feature ([next-in-order])" — if unspecified features remain
    - "Stop here for this session"
    - "Run `/gate-check`" — if enough MVP features are specified

---
