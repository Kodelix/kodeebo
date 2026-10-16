---
name: quick-spec
description: "Lightweight spec for small changes — config and limit adjustments, minor behaviour tweaks, small additions. Embeds in the story; skips the full feature spec but keeps the NFR one-liners."
argument-hint: "[brief description of the change] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(date *), Bash(bash "*/.claude/skills/quick-spec/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

# Quick Spec

This is the **lightweight specification path** for changes that don't need a full
feature spec. Full spec authoring via `/design-spec` is the heavyweight path. Use
this skill for work under about one week of implementation — configuration and
limit adjustments, minor behavioural tweaks, small additions to existing
features, or standalone features too small to warrant a full document. Most
tweaks are hours; the one-week ceiling is the limit for a New Small Feature (see
the categories below).

**Output:** `design/quick-specs/[name]-[date].md`, **embedded in the story**: the
story's Spec Reference field points at it, and the story's acceptance criteria
copy its criteria (Phase 5).

**When to run:** Anytime a change is too small for `/design-spec` but too
meaningful to implement without a written rationale.

**What "quick" does not skip.** The spec still carries the Non-Functional
one-liners (Phase 3): security and tenancy, performance, caching, observability,
accessibility, AR/EN. The eight Definition of Done gates
(`.claude/docs/coding-standards.md`) apply to the story that implements it at
every size. "Small" shortens the document, never the engineering.

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt). Gates follow
`.claude/docs/director-gates.md`; the spawned agent reads its own gate file — do
not read it in the parent session.

## 1. Classify the Change

First, read the argument and determine which category this change falls into:

- **Config** — changing limits, quotas, defaults, flags, TTLs or plan data in an
  existing feature with no behavioural change (the most minimal path). Example:
  "raise the free-plan invite limit from 3 to 5", "shorten the OTP TTL to 5
  minutes", "turn the new export flag on for Team".
- **Tweak** — a small behavioural change to an existing feature that introduces
  no new states, endpoints, branches, or contexts. Example: "show the plan name
  in the invoice email", "let admins resend an invitation after 24 hours".
- **Addition** — adding a small capability to an existing feature that may
  introduce 1-2 new states, one endpoint, or one event. Example: "add CSV export
  to the members list", "add a bulk-revoke action to invitations".
- **New Small Feature** — a standalone feature small enough that it has no
  existing spec and is under approximately one week of implementation work.
  Example: "a read-only audit log viewer page", "a status banner for planned
  maintenance".

**Redirect to `/design-spec` instead** (Verdict: **REDIRECTED**) when the change:
- introduces a new bounded context or significant cross-context dependencies;
- needs more than one week of implementation, or fundamentally alters an existing
  feature's core rules;
- changes the **permission model** (new role, changed role semantics) or the
  **plan/entitlement structure** (new plan, repriced model, new metered unit);
- touches a **threat-model trigger** from `.claude/docs/security-baseline.md`:
  authentication, the authorization model, billing, licensing, file upload,
  webhooks, PII export/delete, admin/impersonation, or a new external
  integration. Such a change needs `/design-spec` and `/threat-model`, not a
  quick spec. (A Config change to an existing, already-modelled value in one of
  these areas — for example a lower OTP attempt limit — may stay here; say that
  it does and why.)

If there is no argument, ask the user to describe the change (plain text prompt), then classify it using the criteria above.

Present the inferred classification using `AskUserQuestion`:
- Prompt: "I've classified this as **[inferred type]** — [brief reason]. Is that correct?"
- Options (four — the tool's limit):
  - `[A] Yes — [inferred type] is correct` (Recommended)
  - `[B]` and `[C]` — the two small types closest to the inferred one, from:
    `Config — changing limits, defaults or flags only` ·
    `Tweak — small behavioural change to an existing feature` ·
    `Addition — adding a small capability to an existing feature` ·
    `New Small Feature — standalone, under one week of work`
  - `[D] This is too large or sensitive — redirect me to /design-spec`

The fourth small type is reached through the automatic **Other** field; name
all four types in the prompt so the user knows it exists.

If [D]: stop. Verdict: **REDIRECTED** — use `/design-spec` for this change.
Otherwise: proceed with the selected type.

---

## 2. Context Scan

Before drafting anything, read the relevant context:

- Search `design/specs/` for the feature spec most relevant to this change. Read
  the sections this change would affect. If no spec covers this feature — usually
  the case at `workflow: minimal`, where `design/product-brief.md` and the stories
  are the design record — read the brief's lines for it and the story the change
  touches instead, report "No spec for [feature] — using the brief and [story
  path]", and give the brief as the spec's Spec Reference.
- Check whether `design/specs/domain-map.md` exists. If it does, read it to
  understand the feature's bounded context, dependencies and tier. If it does not
  exist, note "No domain map found — skipping dependency check." and continue.
- Check `design/quick-specs/` for any prior quick specs that touched this
  feature — avoid contradicting them.
- Glob `docs/research/` for a note on the feature or provider; if the change calls
  a provider API, an absent note is reported by name (DoD gate 1 applies to the
  implementing story).
- If this is a Config change, locate where the value lives (environment, database
  or plan data, per the feature spec's Configuration table) and any **pricing
  model** entry it affects. Plan and pricing effects link to the pricing model;
  never restate a price.

Report what was found: "Found spec at [path]. Relevant section: [section name].
Prior quick specs for this feature: [each path, and whether it agrees or
conflicts with this change — or "none"]." Name a prior spec even when it
agrees — "no conflicts" alone reads the same as "no prior specs".

---

## 3. Draft the Quick Spec

Use the appropriate format for the change category. **Every format ends with the
same `## Non-Functional (one-liners)` block** — fill each line or write
`n/a — <reason>`; an empty line is not an answer.

### The Non-Functional one-liners (all types)

```markdown
## Non-Functional (one-liners)

- **Security & tenancy**: [authz/role affected · tenant-scoped? how cross-tenant access is blocked · threat-model trigger touched? no / yes → redirect]
- **Performance**: [expected effect on the endpoint's p95 / queries per request vs `docs/architecture/perf-budgets.md`, or "no hot-path change"]
- **Caching**: [cache affected and invalidation on this change, or "no cache involved — <reason>"]
- **Observability**: [span/metric/log added or changed, or "unchanged — existing instrumentation covers it"; no PII in telemetry]
- **Accessibility**: [UI touched → keyboard/label/contrast note, or "n/a — no user-facing surface"]
- **Localization**: [new/changed strings externalised in Arabic (RTL) and English, or "no strings change"]
```

### For Config changes

Produce a single table:

```markdown
# Quick Spec: [Title]

**Type**: Config
**Feature**: [Feature name]
**Spec Reference**: `design/specs/[filename].md` — Configuration / Non-Functional section
**Date**: [today]

## Change

| Parameter | Old Value | New Value | Where configured | Rationale |
|-----------|-----------|-----------|------------------|-----------|
| [param]   | [old]     | [new]     | [env / DB / plan data] | [why] |

## Configuration Mapping

Maps to the spec's Configuration entry: [parameter and its documented safe range].
New value is [within / at the edge of / outside] the documented range.
[If outside: explain why the range should be extended.]
Plan/pricing effect: [none / links to the `design/specs/pricing-model.md` entry — no price restated]

## Acceptance Criteria

- [ ] [Parameter] reads [new value] from [config location], not from code
- [ ] Behaviour difference is observable in [specific context]
- [ ] No regression in [related behaviour]
- [ ] Rollback: previous value restorable without a deploy

[Non-Functional one-liners]
```

### For Tweak and Addition changes

```markdown
# Quick Spec: [Title]

**Type**: [Tweak / Addition]
**Feature**: [Feature name]
**Spec Reference**: `design/specs/[filename].md`
**Date**: [today]

## Change Summary

[1-2 sentences describing what changes and why.]

## Motivation

[Why is this change needed? What user problem does it solve? Reference the
relevant job-to-be-done, support ticket or usability finding if applicable.]

## Spec Delta

Current spec says (quoting `design/specs/[filename].md`, [section]):

> [exact quote of the relevant rule or description]

This spec changes that to:

[New rule or description, written with the same precision as a feature spec's
Detailed Behaviour section. An engineer should be able to implement from this
text alone.]

## New Rules / Values

[Full unambiguous statement of the replacement content. If this introduces new
states, list them. If it introduces new parameters, define their ranges and
where they are configured.]

## Permissions

| Action | Owner | Admin | Member | Viewer | Anonymous | Other tenant |
|--------|-------|-------|--------|--------|-----------|--------------|
| [action] | | | | | 401 | 404 |

[Plan effect, if any: which plan includes this; link to the pricing model.]

## Affected Contexts and Contracts

| Context / contract | Impact | Action Required |
|--------------------|--------|-----------------|
| [context or `contracts/` file] | [how it is affected] | [update spec / update contract / no action] |

## Acceptance Criteria

- [ ] [Specific, testable criterion 1] — *[story type]*
- [ ] [Specific, testable criterion 2] — *[story type]*
- [ ] **Negative**: [wrong role → 403 / other tenant → 404 / over quota → 422 problem code, as applicable]
- [ ] No regression: [the original behaviour this must not break]

## Spec Update Required?

[Yes / No]
[If yes: which file, which section, and what the update should say.]

[Non-Functional one-liners]
```

### For New Small Feature changes

Use a trimmed feature-spec structure. Include only the sections that are directly
necessary — skip User Value prose, full Formulas and Dependencies unless the
feature specifically requires them.

```markdown
# Quick Spec: [Title]

**Type**: New Small Feature
**Scope**: [1-2 sentence description of what this feature does and doesn't do]
**Bounded context**: [context] · **Plan gate**: [entitlement key / all plans]
**Date**: [today]
**Estimated Implementation**: [hours]

## Overview

[One paragraph a new team member could understand. What does this feature do,
who uses it, and what does it produce?]

## Core Rules

[Unambiguous rules. Numbered lists for sequential behaviour, bullets for
conditions. Precise enough that an engineer can implement without asking.]

## Permissions

[Role × action matrix as above, with 401 / 403 / 404 cells and plan effect.]

## Data & Contracts

[Entities with owner and tenant key; endpoints (method + path, policy, idempotent?,
errors) or "none"; events. Link the `contracts/` file — the contract lands first.]

## Configuration

| Parameter | Default | Safe range | Where configured | Rationale |
|-----------|---------|-----------|------------------|-----------|
| [name] | [value] | [min–max] | [env / DB / plan data] | [why this default] |

All values live in configuration, not in code.

## Acceptance Criteria

- [ ] [Functional criterion: does the right thing] — *[story type]*
- [ ] [Functional criterion: handles the edge case]
- [ ] **Negative / cross-tenant**: anonymous → 401; unauthorised role → 403 and no change; other tenant → 404
- [ ] [Regression criterion: does not break the adjacent feature]

## Domain Map

This feature is not currently in `design/specs/domain-map.md`.
[If it should be added: suggest which context, layer and priority tier.]
[If it is too small to track: state "This feature is below domain-map
tracking threshold — quick spec is sufficient."]

[Non-Functional one-liners]
```

---

## 4. Approval and Filing

Present the draft to the user in full. Then use `AskUserQuestion`:
- Prompt: "Here's the Quick Spec draft. How do you want to proceed?"
- Options:
  - `[A] Approve — write it as shown`
  - `[B] Revise — I'll describe what to change`
  - `[C] This grew too large or sensitive — redirect to /design-spec instead`

If [B]: collect the requested changes, revise the draft, and re-present this widget.
If [C]: stop. Verdict: **REDIRECTED** — use `/design-spec` for this change.

If [A]: ask "May I write this Quick Spec to
`design/quick-specs/[kebab-case-title]-[YYYY-MM-DD].md`?"

Use today's date in the filename. The title should be a kebab-case description
of the change (e.g., `free-plan-invite-limit-config-2026-03-10`,
`csv-export-members-addition-2026-03-10`).

If yes, create the `design/quick-specs/` directory if it does not exist, then
write the file. If the user declines this write, write nothing and stop with
`Verdict: **BLOCKED** — write declined by user`; the handoff block below is not
produced and nothing is reported as COMPLETE.

If a spec update is required (flagged in the quick spec), ask separately after
writing the quick spec:

"This quick spec modifies rules in [Feature Name]. May I update
`design/specs/[filename].md` — specifically the [section name] section?"

Show the exact text that would be changed (old vs. new) before asking. Do not
make spec edits without explicit approval.

**Review mode check** — apply before spawning PD-SPEC-ALIGN (Tweak, Addition and
New Small Feature only; a Config change that touches no plan, permission or
default a user sees skips it):
- `solo` → skip. Note: "PD-SPEC-ALIGN skipped — Solo mode."
- `lean` → skip (not a PHASE-GATE). Note: "PD-SPEC-ALIGN skipped — Lean mode."
- `full` → spawn `product-director` via `Agent` using gate PD-SPEC-ALIGN (`.claude/docs/director-gates/pd-spec-align.md`). Pass the quick spec path, the principles (`design/product-principles.md`, else the brief's pitch and ICP, saying so), positioning and ICP, the Overview/Change Summary in place of User Value (saying so), and the effective tier. Handle the verdict per `director-gates.md`; a `NOT ASSESSED` is recorded as such, never as approved. Record the outcome in the quick spec's header: `> **Product Director Review (PD-SPEC-ALIGN)**: APPROVED / CONCERNS (accepted) / NOT ASSESSED / skipped — [mode] [date]`.

---

## 5. Handoff — embed in the story

After writing the file, offer to embed it in the story that will implement the
change. If a story path was given or is obvious (`production/epics/`), use
`AskUserQuestion`: "May I add a Quick Spec section to the story?"
- On yes: add a `Spec Reference` line pointing at the quick spec file and copy its
  Acceptance Criteria and Non-Functional one-liners into the story's criteria
  (the story stays self-contained; the quick spec remains the rationale record).
  Show the edit before applying.
- At `workflow: minimal` with no story yet: say the spec is ready to be pasted into
  the first story when `/create-stories` writes it.

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/quick-spec <title> —
<verdict>`, Next step = the handoff's next step (`/story-readiness`, or
`/dev-story` at `workflow: minimal`), plus Blocked on / Files in progress / Open
questions; append the Notes line. REDIRECTED (next step `/design-spec`) and
BLOCKED (write declined) from section 4 still update the checkpoint.

Then output:

```
Quick Spec written to: design/quick-specs/[filename].md
Type: [Config / Tweak / Addition / New Small Feature]
Feature: [feature name]
Spec update: [Required — pending approval / Applied / Not required]
Story: [embedded in <path> / not embedded]
PD-SPEC-ALIGN: [verdict / skipped — mode]

Next step: This spec is ready for `/story-readiness` validation before
implementation (at `workflow: minimal`, go straight to `/dev-story`). The
implementing story still owes the research note (DoD gate 1) and the eight
Definition of Done gates.
```

### Pipeline Notes

Verdict: **COMPLETE** — quick spec written and ready for implementation. (If the
spec-update or story-embed writes were declined, the spec file itself still counts
as written: say `Spec update: Required — pending approval` / `Story: not embedded` in
the block above and keep COMPLETE; only a declined write of the quick-spec file is
BLOCKED.)

Quick Specs **bypass** `/spec-review` and `/review-all-specs` by design. They
are for small, low-risk, well-scoped changes where the cost of the full review
pipeline exceeds the risk of the change itself. `/consistency-check` still reads
`design/quick-specs/`.

Redirect to the full pipeline if any of the following are true:
- The change adds a feature that belongs in the domain map
- The change significantly alters cross-context behaviour or a context's contracts
- The change touches the permission model, the plan/entitlement structure, or a threat-model trigger
- Implementation is likely to exceed one week of work

In those cases: "This change has grown beyond quick-spec scope. I recommend
using `/design-spec` to author a full spec for this."

A skipped gate, an unread input (no domain map, no perf budget) or a prior quick
spec that could not be read is reported by name in the handoff output — not
omitted.

---

## Collaborative Protocol

1. **Question -> Options -> Decision -> Draft -> Approval**: classification is confirmed, the full draft is shown, and nothing is written before "May I write…?" is answered.
2. **No unilateral spec edits**: a change to an existing spec is shown old-vs-new and asked separately.
3. **A skipped or dismissed question is not an answer**: re-ask in plain text and wait.

## Recommended Next Steps

- Run `/story-readiness [story-path]` to validate the story before implementation begins (skip at `rigor: minimal` — `/dev-story` directly) — reference this spec in the story's Spec Reference field
- Run `/dev-story [story-path]` to implement once the story passes readiness checks
- If the change is larger than expected, run `/design-spec [feature-name]` to author a full spec instead
