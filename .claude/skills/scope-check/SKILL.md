---
name: scope-check
description: "Scope creep check — current scope versus the original plan. Flags additions, quantifies bloat, recommends cuts. 'Any scope creep?'"
argument-hint: "[feature-name or sprint-N or milestone-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git log *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(date *), Bash(bash "*/.claude/skills/scope-check/../../hooks/yaml-helper.sh" resolve_config *)
model: haiku
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,system_overrides`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

# Scope Check

This skill is read-only — it reports findings but writes no files.

Compares original planned scope against current state to detect, quantify, and triage
scope creep.

**Argument:** `$ARGUMENTS` — the whole string: a feature name (it may be several words), sprint number, or milestone name.

---

## Phase 1: Find the Original Plan

Locate the baseline scope document for the given argument:

- **Feature name** → first resolve that feature's **effective tier**: the `system_overrides` entry for the feature in the resolved block if it lists one, else `workflow`. At an effective `minimal` the baseline is the feature's row in `design/product-brief.md`; at `standard`/`full` it is the spec. Then read `design/specs/[feature].md` (the filename stem is the feature key), else `design/quick-specs/[feature].md`, else the feature's row in `design/product-brief.md` (its build-order field is the baseline at `workflow: minimal`, where there are no per-feature specs)
- **Sprint number** (e.g., `sprint-3`) → read `production/sprints/sprint-003.md` (the name `/sprint-plan` writes) or similar
- **Milestone** → read `production/milestones/[name].md`

If the document is not found, report the missing file and stop with
**Scope Verdict: NOT ASSESSED — baseline not found** (name the file looked for). Do not proceed
without a baseline to compare against.

---

## Phase 2: Read the Current State

Check what has actually been implemented or is in progress:

- Scan the code roots (`resolve_code_root`; `.claude/docs/directory-structure.md` → Code roots) for files related to the feature/sprint. **An empty root list means the scan did not run** — say so; it is not "no changes"
- Read git log for commits related to this work (`git log --oneline --since=[start-date]`)
- Check for TODO/FIXME comments that indicate unfinished scope additions
- Read the sprint plan and `production/sprint-status.yaml` if the feature is mid-sprint — stories present there but absent from the baseline are additions
- Read `contracts/` operations touched since the baseline date: a new endpoint, event or field nobody planned is an addition

---

## Phase 3: Compare Original vs Current Scope

Produce the comparison report:

```markdown
## Scope Check: [Feature/Sprint Name]
Generated: [Date]

### Original Scope
[List of items from the original plan]

### Current Scope
[List of items currently implemented or in progress]

> **If Phase 4 will return NOT ASSESSED, do not render the numeric block below.**
> Replace the counts and the Bloat Score with
> `[Baseline | Current state] unusable — see verdict` (whichever side could not
> be read) and give the reason. A rendered
> `Original items: 0 / Net scope change: 0%` one section above a NOT ASSESSED
> verdict re-creates the exact "0% reads as on track" hazard Phase 4 exists to
> kill, one phase earlier — and readers trust a number over a caveat.

### Scope Additions (not in original plan)
| Addition | Source | When | Justified? | Effort | Lane(s) | Risk flags |
|----------|--------|------|------------|--------|---------|------------|
| [item] | [commit/person] | [date] | [Yes/No/Unclear] | [S/M/L] | [backend/web/mobile/contracts] | [see below] |

**Risk flags** — mark an addition when it: touches a security-baseline threat-model trigger (auth, authorization model, billing, licensing, file upload, webhooks, PII export/delete, admin/impersonation, new external integration — `.claude/docs/security-baseline.md`); adds a lane, a provider or a data store; changes a plan, entitlement or quota; changes a public contract; or affects the self-hosted upgrade path. Such additions carry hidden DoD work (research note, threat model, security negatives) — count it in Effort.

### Scope Removals (in original but dropped)
| Removed Item | Reason | Impact |
|-------------|--------|--------|
| [item] | [why removed] | [what's affected] |

### Bloat Score
- Original items: [N]
- Current items: [N]
- Items added: [N] (+[X]%)
- Items removed: [N]
- Net scope change: [+/-N] ([X]%)

### Risk Assessment
- **Schedule Risk**: [Low/Medium/High] — [explanation]
- **Quality Risk**: [Low/Medium/High] — [explanation]
- **Integration Risk**: [Low/Medium/High] — [explanation]
- **Security / Tenancy Risk**: [Low/Medium/High] — [explanation; any risk-flagged addition without a research note or threat model]

### Recommendations
1. **Cut**: [Items that should be removed to stay on schedule]
2. **Defer**: [Items that can move to a future sprint/version]
3. **Keep**: [Additions that are genuinely necessary]
4. **Flag**: [Items that need a decision from producer / product-director]
```

---

## Phase 4: Verdict

Assign a canonical verdict based on net scope change:

| Net Change | Verdict | Meaning |
|-----------|---------|---------|
| ≤10% (or net shrink under 10%) | **PASS** | On Track — within acceptable variance |
| >10–25% | **CONCERNS** | Minor Creep — manageable with targeted cuts |
| >25–50% | **FAIL** | Significant Creep — must cut or formally extend timeline |
| >50% | **FAIL** | Out of Control — stop, re-plan, escalate to producer |

**Net shrink (a negative net change).** Apply the table to the absolute value, and call it a
**scope cut**, not creep. A cut is only on track if every removed item has a recorded reason in
the Phase 3 "Scope Removals" table (a decision someone made); removals with no recorded reason
raise the verdict to at least **CONCERNS**, and a cut of more than 25% is never **PASS** — say
what the product loses and who decided. Never report a large negative number as "On Track".

**Before applying that table, check that the percentage means something.** Emit
**NOT ASSESSED** instead — never a computed percentage — when any of:

- The **baseline document exists but enumerates no scope items** (all headings,
  placeholders, or `[TO BE CONFIGURED]`). Phase 1 stops when the file is *absent*;
  this is the case where it is present and empty, and it is the more dangerous
  one, because zero items yields a 0% net change that renders as **PASS — On
  Track**. Nothing was compared. Nothing was on track.
- The **current state cannot be determined** — no related source files, no commits
  in the window, nothing in progress to read. Comparing a real baseline against an
  unreadable present is not a 0% change, and not the −100% that zero current
  items computes — the table reads both as PASS.
- The denominator would be zero for any other reason. A percentage computed from
  no baseline items is not a small number; it is not a number.

`NOT ASSESSED` **outranks PASS** (a comparison that never happened has not shown
scope is on track) and **ranks below CONCERNS and FAIL** (measured creep is more
actionable than an unmeasurable baseline).

**Security floor:** a risk-flagged addition (Phase 3) that landed with no research note and, where a trigger applies, no threat model is reported under Risk Assessment and raises the verdict to at least **CONCERNS** even when the percentage is within 10%. Creep in the security-sensitive surface is not measured by item count alone.

Output the verdict prominently:

```
**Scope Verdict: [PASS / CONCERNS / NOT ASSESSED / FAIL]**
Net change: [+X% or -X%] — [On Track / Minor Creep / Significant Creep / Out of Control / Scope Cut (decided | unaccounted)]
           [or: NOT ASSESSED — [which side could not be read, and why]]
```

---

## Phase 5: Next Steps

After presenting the report, offer concrete follow-up:

- **PASS** → no action required. Suggest re-running before next milestone.
- **NOT ASSESSED** → say which side was unreadable and what would fix it (populate
  the baseline document, or point the skill at where the work actually lives).
  Do not offer a re-run against the same inputs — it will produce the same
  non-answer.
- **CONCERNS** → offer to identify the 2–3 additions with best cut ratio. Reference `/sprint-plan update` to formally re-scope (if the project has no sprint plan, as on the default minimal workflow, re-scope by editing the brief's build order).
- **FAIL** → recommend escalating to producer. Reference `/sprint-plan update` for re-planning (if the project has no sprint plan, as on the default minimal workflow, edit the brief's build order) or `/estimate` to re-baseline timeline.

End every verdict except NOT ASSESSED with:
> "Run `/scope-check [name]` again after cuts are made to verify the verdict improves."

(NOT ASSESSED ends with what would make it assessable, above — a re-run against
the same inputs would repeat the non-answer.)

---

### Rules

- Scope creep is additions without corresponding cuts or timeline extensions
- Not all additions are bad — some are discovered requirements. But they must be acknowledged and accounted for
- When recommending cuts, prioritize preserving the core user value and the security floor (tenant isolation, authz, billing correctness) over nice-to-haves; never recommend cutting a DoD gate to recover schedule — cut features instead
- Always quantify scope changes — "it feels bigger" is not actionable, "+35% items" is
