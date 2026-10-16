---
name: propagate-spec-change
description: "A feature spec changed — scan ADRs, stories, contracts, the pricing model and the threat model for now-stale decisions. Impact report, guides resolution."
argument-hint: "[path/to/changed-spec.md] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(date *), Bash(git diff *), Bash(wc -c *), Agent, AskUserQuestion, Bash(bash "*/.claude/skills/propagate-spec-change/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode` for this run. No
block → defaults in `.claude/docs/config-resolution.md`.

# Propagate Spec Change

When a feature spec changes, everything written against it may no longer be
valid: architecture decisions (ADRs), stories in flight, the API contract in
`contracts/`, the pricing model's entitlements and quotas, and the threat model.
This skill finds every affected artifact, compares what each assumed against what
the spec now says, and guides the user through resolution.

**Usage:** `/propagate-spec-change design/specs/team-invitations.md`

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt — ADR, contract and schema
impacts here fall under `schema_changes` and `architecture_decisions`).

**Workflow tier**: resolve for the **changed spec's feature** (per
`.claude/docs/workflow-modes.md`): the feature key is the spec filename stem;
use the `system_overrides` row for that key if the block lists one, else the
project value. A feature pinned `minimal` has no ADRs even on a `standard`
project, so the ADR cascade is N/A for it — but the story, contract, pricing and
threat-model checks below still run, because those artifacts exist at every
tier. The tier scopes the **ADR** cascade only: `full` cascades across all ADRs;
`standard` checks only critical (Foundation-layer) ADRs plus any ADR referencing
the changed spec; `minimal` skips the ADR cascade (the decision log in
`design/product-brief.md` is checked instead). See Step 4.

The tier scales documents, never engineering: the eight Definition of Done gates
(`.claude/docs/coding-standards.md`) apply to any story this skill sends back to
rework.

## 1. Validate Argument

A spec path argument is **required**. If missing, fail with:
> "Usage: `/propagate-spec-change design/specs/[feature].md`
> Provide the path to the spec that was changed."

Verify the file exists. If not, fail with:
> "[path] not found. Check the path and try again."

---

## 2. Diff the Spec Against Its Previous Version

**Ask git what changed — do not read two whole documents and compare them by
eye.** Two entire documents in context to find what is usually a handful of lines
is expensive, and a model comparing 400-line documents will eventually miss an
edit. Git cannot.

```bash
git diff HEAD -- design/specs/[filename].md
```

If that is empty, the change may already be committed — widen to the commit that
last touched it:

```bash
git diff HEAD~1 HEAD -- design/specs/[filename].md
```

If the file has no git history (new file), report:
> "No previous version in git — this appears to be a new spec, not a revision.
> Nothing to propagate."

If the diff is empty **and** the file has history, report that plainly — "no
uncommitted or last-commit changes to `[file]`" — and ask which revision to
propagate. An empty diff is not "no impact"; it means nothing changed *here*.

From the diff hunks:
- Identify sections that changed (new or removed rules, role/permission changes,
  endpoints or events, entities, plan or quota references, NFRs, acceptance
  criteria). The `@@` hunk headers name the enclosing section, so the
  changed-section list falls out of the diff itself.
- Read the surrounding section from the current spec **only** where a hunk is too
  small to interpret on its own. That is a targeted read of one section, not the
  document.
- Sections with no hunk are unchanged — by construction, not by inspection.

---

## 3. Produce the Change Summary

From the hunks resolved in step 2:

```
## Change Summary: [spec filename]
Date of revision: [today]

Changed sections:
- [Section name]: [what changed — new rule, removed rule, role/permission, endpoint, entity, quota, NFR…]

Unchanged sections:
- [Section name]

Key changes affecting architecture, contracts, data or pricing:
- [Change 1 — likely to affect ADRs / contracts / entitlements]
- [Change 2]
```

**Downstream spec impact via the registry.** If `design/registry/entities.yaml`
exists (the entity registry — plans, roles, permissions, quotas, events,
entities; see `/consistency-check`), it already records which other specs depend
on this feature's facts — compute the affected set from it rather than re-reading
every spec:
```
Grep pattern="source: design/specs/[filename]" path="design/registry/entities.yaml" output_mode="content" -A 6
```
For each registered fact this spec **owns** whose value the diff changed, its
`referenced_by:` list is the set of downstream specs that may now be inconsistent
— report them under "Downstream specs to re-check". **If the registry does not
exist or has no entries**, say so ("entity registry absent — downstream specs not
computed from it; run `/consistency-check`") and continue; the cascade below
still runs. That line is part of the report, not a silent skip.

---

## 4. Load Impact Inputs

Five artifact families can be stale — ADRs (4a), stories (4b), contracts, the
pricing model and the threat model (4c). Together with the entity-registry check
from step 3 that makes six Coverage lines. Check each family and record whether it
was **checked**, **not applicable (reason)** or **not checked (reason)** — the
report must show all six lines.

### 4a. ADRs (scoped by tier)

Read ADRs in `docs/architecture/` **per the resolved tier**:
- **`full`** — read **all** ADRs.
- **`standard`** — read only **critical (Foundation-layer) ADRs** plus any ADR
  that references the changed spec. An ADR is critical when the `**Layer**` row of
  its `## Stack Compatibility` table says `Foundation`, or when it has no
  `**Layer**` row — when in doubt, treat it as critical
  (`.claude/docs/workflow-modes.md`). Read every row in one call:
  `Grep pattern="\*\*Layer\*\*" glob="docs/architecture/adr-*.md" output_mode="content"`,
  and count an ADR that Grep does not list as critical.
- **`minimal`** — **no ADR cascade**: there are no ADR files to cascade. Report
  "No ADR cascade at minimal workflow" and instead grep the decision log in
  `design/product-brief.md` for decisions that cite the changed feature.

**Establish the denominator first.** Glob the in-scope ADRs (per the tier). Call
the count **N**. If N is 0 at `standard`/`full`: "No ADRs found in
`docs/architecture/` — ADR cascade did not run." Record it as **not checked** and
continue with 4b–4d.

**Scan the requirement tables — do not full-read the ADRs at this step:**
```
Grep pattern="## Spec Requirements Addressed" glob="docs/architecture/adr-*.md" output_mode="content" -A 15
```
**Recall net — an ADR may cite the changed spec in prose without tabling it:**
```
Grep pattern="[changed-spec-basename]" glob="docs/architecture/adr-*.md" output_mode="files_with_matches"
```
Take the **union** of the two results as the affected set **M**. This turns
N × ~200 lines into N × ~15 lines; §5 full-reads only the M.

Interpret the result — a zero-match scan is **never** "no impact" by default:

| Result | Meaning | Action |
|---|---|---|
| **M ≥ 1** | Normal. | Proceed. The N − M non-matching ADRs are *out of scope for this cascade* — do not describe them as verified unaffected. |
| **Both scans 0, N > 0** | Ambiguous — either no ADR references this spec, or the ADRs lack requirement tables. | Run `Grep pattern="## Spec Requirements Addressed" glob="docs/architecture/adr-*.md" output_mode="files_with_matches"`. If that is **also** empty: "[N] ADRs found, none contains a 'Spec Requirements Addressed' section — traceability cannot be computed. Run `/architecture-decision retrofit [adr]`." and mark the ADR cascade **NOT ASSESSED**. If it is **non-empty**: the tables exist and genuinely none reference this spec — "No ADR references [spec] — no architecture impact." |

Read `docs/architecture/architecture-traceability.md` if it exists.

Report: "Loaded [N] ADRs by scan. [M] reference [spec filename] ([X] via
requirements table, [Y] via prose reference only)."

### 4b. Stories

Stories embed the spec requirement as a TR-ID and carry acceptance criteria
copied from the spec. Find them:
```
Grep pattern="[changed-spec-basename]|TR-[feature]-" path="production" glob="**/story-*.md" output_mode="files_with_matches"
```
For each story note its status (Draft / Ready / In Progress / In Review / Done /
Blocked). A story **In Progress** or **Done** against a changed requirement is the
costliest finding: Done means shipped behaviour that no longer matches the spec.
If `production/` has no stories, record "stories: none exist yet — not
applicable".

### 4c. Contracts, pricing, threat model

- **Contracts**: if the diff touched endpoints, request/response fields, error
  cases, events, roles or pagination, locate the operations in `contracts/`
  (`Grep` for the path or `operationId`). Classify each change **breaking** or
  **non-breaking** per `.claude/rules/contracts.md`, separately for hosted clients
  and for deployed self-hosted versions. If `contracts/` is empty, say so.
- **Pricing model**: if the diff touched anything gated by plan, role, quota,
  trial or metering, check `design/specs/pricing-model.md` (the canonical path; if absent,
  `Glob design/**/pricing-model*.md` and note a non-canonical location) for the entitlement key or
  quota that the spec names. Prices are never restated in specs; flag a changed
  entitlement/quota reference, a new gated behaviour with no entitlement row, or a
  removed behaviour whose entitlement is now orphaned. Hand findings to
  `pricing-billing-designer`; this skill does not edit the pricing model.
- **Threat model**: if the diff touched auth, billing, file upload, PII, roles,
  tenancy or an external provider, check `docs/architecture/threat-models/[feature].md`
  for a model that predates the change. A sensitive change with a stale or absent
  threat model is flagged for `/threat-model` and `security-lead`.

Also glance at data impact: a changed entity or retention rule implies a
migration shape (expand → migrate → contract) and an effect on existing tenant
data and multi-version self-hosted upgrades — name it, do not design it.

---

## 5. Impact Analysis

Now read each ADR in the affected set **M** for its reasoning, not just its
table — judging whether a decision is still valid needs the ADR's `## Context`
and `## Decision` (and `## Consequences` where present), not scan output. **Do
not attempt the judgement below from scan output.**

Check size first (`Bash: wc -c "docs/architecture/[adr-file].md"`):
- **Under ~50KB** — one full `Read`.
- **~50KB or larger** — map headings first
  (`Grep pattern="^## " path="docs/architecture/[adr-file].md" output_mode="content" -n`),
  then bounded-`Read` only `## Context`, `## Decision`, and `## Consequences`.

For each ADR that references the changed spec, compare its "Spec Requirements
Addressed" entries against the changed sections:

1. **Locate the requirement** in the current spec — does it still exist?
2. **Compare**: what did the spec say when the ADR was written vs. now?
3. **Assess the ADR decision**: is it still valid? Trace cascades — decisions that
   depend on a flagged ADR (data store, tenancy, API style, licensing/entitlement).

Classify each affected ADR:

| Status | Meaning |
|--------|---------|
| **Still Valid** | The spec change doesn't affect what this ADR decided. Name the ADR assumption the change would have had to contradict, and confirm it does not. |
| **Needs Review** | The change may affect this ADR — human judgment needed |
| **Likely Superseded** | The change directly contradicts what this ADR assumed |

For each affected ADR, produce an impact entry:

```
### ADR-NNNN: [title]
Status: [Still Valid / Needs Review / Likely Superseded]

What the ADR assumed about this spec:
  "[quote from the ADR's Spec Requirements Addressed section]"  (ADR line N)

What the spec now says:
  "[quote from the current spec]"  (spec line N)

Assessment:
  [Whether the ADR decision is still valid, and why. Cascades to other ADRs.]

Recommended action:
  [Keep as-is | Review and update | Mark Superseded and write new ADR] — owner: [agent]
```

For each affected **story**, **contract operation**, **entitlement/quota** and
**threat model** from step 4, produce a one-line entry: artifact — what it
assumed — what the spec now says — action — owner (`product-manager` for specs
and stories, `api-designer` for contracts, `pricing-billing-designer` for
pricing, `security-lead` for threat models, `domain-architect` for ADRs).

---

## 6. Present Impact Report

Present the full impact report to the user before asking for any action:

```
## Spec Change Impact Report
Spec: [filename]
Date: [today]
Changes detected: [N sections changed]
Tier applied: [full / standard / minimal] ([source: override or project])

Coverage (every line required — a family that did not run says so):
- ADRs: [checked N, M reference the spec] | NOT ASSESSED ([reason]) | skipped at minimal
- Stories: [K found, J in progress/done] | none exist
- Contracts: [P operations affected, B breaking] | not applicable | not checked ([reason])
- Pricing model: [entitlements/quotas affected] | not applicable | not checked ([reason])
- Threat model: [stale / current / absent] | not applicable | not checked ([reason])
- Entity registry (downstream specs): [R specs to re-check] | registry absent

### Not Affected
[Artifacts referencing this spec whose assumptions remain valid]

### Needs Review ([count])
[ADRs / stories / contracts / entitlements that may need updating]

### Likely Superseded / Invalidated ([count])
[Artifacts whose assumptions are now contradicted]
```

---

## 6b. Director Gate — Technical Impact Review

**Review mode check** — apply before spawning CTO-CHANGE-IMPACT:
- `solo` → skip. Note: "CTO-CHANGE-IMPACT skipped — Solo mode." Proceed to Step 7.
- `lean` → skip. Note: "CTO-CHANGE-IMPACT skipped — Lean mode." Proceed to Step 7.
- `full` → spawn as normal.

Spawn `cto` via `Agent` using gate **CTO-CHANGE-IMPACT**
(`.claude/docs/director-gates/cto-change-impact.md`). The `Agent` prompt tells the
agent to read the gate file first; do not read it here.

Pass: the full Spec Change Impact Report from Step 6, the changed spec path and
the git ref of its previous version, and `docs/architecture/architecture.md`.

Apply the verdict:
- **APPROVE** → proceed to Step 7
- **CONCERNS** → surface the specific items flagged; `AskUserQuestion` with options: `Revise the impact assessment` / `Accept with noted concerns` / `Discuss further`
- **REJECT** → do not proceed to resolution; re-analyse the impact before continuing
- **NOT ASSESSED** [missing input] → not an approval (`.claude/docs/director-gates.md`): name what was missing, then supply it and re-run the gate — or, if the user chooses to go on without it, proceed to Step 7 and state `CTO-CHANGE-IMPACT: NOT ASSESSED — [input]` in the impact report and the final Verdict line

---

## 7. Resolution Workflow

For each ADR marked "Needs Review" or "Likely Superseded", ask the user:

> "ADR-NNNN ([title]) — [status]. What would you like to do?"
> Options:
> - "Mark Superseded (I'll write a new ADR)" — updates the ADR status line to `Superseded by ADR-[next number] (pending — see change-impact-[date]-[feature].md)`
> - "Update in place (minor revision)" — opens the ADR for editing; note what to revise
> - "Keep as-is (the change doesn't actually affect this decision)"
> - "Skip for now (revisit later)"

For ADRs marked **Superseded**:
- Update the ADR's Status field: `Superseded by ADR-[next number] (pending — see change-impact-[date]-[feature].md)`
- Ask: "May I update the status in [ADR filename]?"
- Only the user (or `cto` on the user's explicit confirmation) moves an ADR to
  `Accepted`; this skill never does.

For affected **stories**: ask per story — `Update acceptance criteria` / `Mark Blocked pending decision` / `Reopen (was Done)` / `Keep`. Do not edit a story without the answer. A Done story whose requirement changed is reopened or gets a follow-up story, never silently left Done.

Contracts, pricing and threat-model findings are **routed, not edited here**:
list the owner and the skill to run (`/api-contract`, `/threat-model`, the
`pricing-billing-designer`, then `/pricing-check`).

---

## 8. Update Traceability Index

If `docs/architecture/architecture-traceability.md` exists, add the changed
requirements to its "Superseded Requirements" table:

```markdown
| Req ID | Spec | Change | Affected ADR | Status |
|--------|------|--------|--------------|--------|
| TR-[id] | [spec] | [old → new requirement] | ADR-NNNN | [Superseded / Updated / Valid] |
```

Ask: "May I update the traceability index?"

If it does not exist, say "traceability index absent — not updated" in the report.

---

## 9. Output Change Impact Document

Ask: "May I write the change impact report to `docs/architecture/change-impact-[date]-[feature].md`?"

The document contains:
- The change summary from step 3
- The coverage lines and full impact analysis from steps 5–6
- Resolution decisions made in step 7
- ADRs, stories, contracts, entitlements and threat models that need to be written or updated, each with an owner

If user approved: Verdict: **COMPLETE** — change impact report saved (add `; CTO-CHANGE-IMPACT: NOT ASSESSED — [input]` if applicable, and name any coverage line that read NOT ASSESSED or not checked).
If user declined: Verdict: **BLOCKED — write declined by user**.
If an ADR cascade or other family could not run: Verdict: **NOT ASSESSED** for that family, named in the verdict line; a report that ran everything it could still states what it could not.

---

## 10. Follow-Up Actions

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/propagate-spec-change
<spec> — <verdict>`, Next step = the first follow-up below, plus Blocked on /
Files in progress / Open questions; append the Notes line. NOT ASSESSED, BLOCKED
or a declined write still updates the checkpoint with the blocker.

Based on the resolution decisions, suggest:

- **ADRs marked Superseded**: "Run `/architecture-decision [title]` to write the
  replacement ADR. Then re-run `/propagate-spec-change` to verify coverage."
- **ADRs to update in place**: list the specific fields to update in each ADR
- **Contract changes**: `/api-contract` — contract lands before handler code
- **Entitlement/quota changes**: `pricing-billing-designer`, then `/pricing-check`
- **Sensitive-feature changes**: `/threat-model [feature]`
- **Stories reworked**: `/story-readiness` before they resume
- **If many ADRs affected**: "Run `/architecture-review` after all ADRs are updated
  to verify the full traceability matrix is still coherent."

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **Read silently** — compute the full impact before presenting anything
2. **Show the full report first** — let the user see the scope before asking for action
3. **Ask per artifact** — don't batch decisions; each affected ADR or story may need different treatment
4. **Ask before writing** — always confirm before modifying any file
5. **Non-destructive** — never delete ADR content; only add "Superseded by" notes
6. **A family that did not run says so** — the report never lets an unchecked family read as "no impact"
