---
name: spec-review
description: "Reviews one feature spec for completeness at its tier, internal consistency, implementability, testable acceptance criteria, permission/plan matrix and NFRs. Before handing to engineers."
argument-hint: "[path-to-spec] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/scripts/review-receipts.sh), Bash(bash .claude/scripts/review-receipts.sh *), Bash(bash .claude/scripts/spec-structure-check.sh), Bash(bash .claude/scripts/spec-structure-check.sh *), Agent, AskUserQuestion, Bash(bash "*/.claude/skills/spec-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,system_overrides,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. `--depth` is
the pre-1.1 name for the same flag: treat `--depth <mode>` exactly as
`--review <mode>`, and say once that it was renamed. Given both, `--review`
wins and `--depth` is ignored — say so. No block → defaults in
`.claude/docs/config-resolution.md`.

# Spec Review


## Phase 0: Parse Arguments

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`workflow`** for the spec under review — use the `system_overrides` row for
`<feature>` (the spec filename stem) if the block lists one, else the project
value. Validation scope follows the tier (`.claude/docs/workflow-modes.md`):
- `full` — all 8 sections validated; any missing section blocks approval.
- `standard` — the 5 required sections (Overview, Detailed Behaviour, Data &
  Contracts, Non-Functional Requirements, Acceptance Criteria) block if missing;
  Edge Cases & Failure Modes blocks when the feature calls an external provider,
  moves money, changes entitlements or runs asynchronously (or `edge_cases` is
  forced); the Formulas and Rules sub-block blocks only when the feature defines
  numeric rules (rates, proration, thresholds, quotas, costs — the category is a
  hint, not the test); User Value and Dependencies are advisory (warn, never
  block) unless `workflow_overrides` require them.
- `minimal` — no spec is expected; if one exists, validate the 5 standard
  sections advisorily.

Resolved mode controls how thorough this review is:

- **`full`**: Complete review — all phases + specialist agent delegation (Phase 3b)
- **`lean`**: All phases, no specialist agents — faster, single-session analysis
- **`solo`**: Phases 1-4 only, no delegation, no Phase 5 next-step prompt — use when called from within another skill

**Solo skips opinions, never checks.** The mechanical checks of Phases 2–3
(structure, permission matrix, negative criteria, NFR presence, price
restatement) run in every mode.

---

## Phase 1: Load Documents

**Freshness check first — a re-review of an unchanged document costs full
price and reproduces the same verdict.** Run:

```
Bash: bash .claude/scripts/review-receipts.sh check "design/specs/reviews/[doc-name]-review-log.md" "[target-doc-path]" "design/registry/entities.yaml"
```

The registry is in the check because this review consults it for
cross-document facts — an unchanged spec reviewed against a *changed*
registry can reach different conclusions, so the skip is only safe when
**every** listed line reads `UNCHANGED` (an absent registry simply doesn't
appear in the output and doesn't block the skip). If the script cannot run,
say so and proceed with a full review — the freshness check not running is
reported, never treated as `UNCHANGED`.

- **All `UNCHANGED`** and the log's latest entry carries a verdict — surface it:
  *"This document is byte-identical to its last review on [date] (verdict:
  [verdict])."* If that verdict was APPROVED, offer via `AskUserQuestion`:
  `[A] Use the prior verdict (Recommended)` / `[B] Re-review anyway` —
  `guided` proceeds with [A] and notes it; `autonomous` logs via
  `log_decision` and uses the prior verdict. If it was NEEDS REVISION or
  MAJOR REVISION NEEDED, say so plainly: the document has not changed since
  it failed review — the prior findings stand; revising the document is the
  next step, not re-reviewing it. Offer to display the prior findings from
  the log.
- **Only the registry line reads `CHANGED`** (doc `UNCHANGED`) — the prior
  verdict stands except for cross-document facts: re-verify the doc's
  registry-sourced values against the new registry and re-issue the verdict;
  escalate to a full re-review only if a conflict appears.
- **Target doc `CHANGED` or `NEW`, or `RECEIPT: NONE`** — proceed with the
  full review below. **Do not offer a partial/delta re-review that skips
  reading or re-analyzing unchanged sections.** A section-scoped re-review
  misses defects a full review finds, and saves little or nothing.
  "Unchanged since last review" only means byte-identical to what was reviewed
  then — it says nothing about whether that prior pass was itself complete.

Read the target spec in full. Read CLAUDE.md to understand project context and standards.

**For cross-document facts, prefer the registry over sibling specs.** If
`design/registry/entities.yaml` exists **and lists entries for this feature**,
grep it — these are the established facts this spec must not contradict, and they
replace reading sibling specs to rediscover them:
```
Grep pattern="source: design/specs/[feature].md" path="design/registry/entities.yaml" output_mode="content" -A 6
Grep pattern="design/specs/[feature].md" path="design/registry/entities.yaml" output_mode="content" -B 8
```
The first finds entries this feature **owns** — the `-A 6` context includes their
`referenced_by:` block. The second finds entries that **reference** this feature —
`referenced_by:` is a block sequence, so match the path with `-B 8` context to see
the owning entry.

**If `design/registry/entities.yaml` does not exist, or lists no entry for this
feature** — fall back to reading the related specs the target names in its
Dependencies and Cross-References sections. Bound the read to those, not to
everything "implied". Do not glob-read all of `design/specs/`.

**Dependency graph validation:** For every feature or context listed in the Dependencies and Cross-References sections, use Glob to check whether its spec file exists in `design/specs/`. Flag any that don't exist yet — these are broken references downstream authors will hit. For every **core module** listed, check that the module is named in `project.yaml` (`core.track`, `core.version`) context or the domain map's "Core module?" column; if the cores are not configured, say "core pin not readable" rather than treating the dependency as met.

**Product alignment:** If `design/product-brief.md` or `design/product-principles.md` exists, read it. Note any rule, default or permission in this spec that contradicts the stated principles, ICP, positioning, or the pricing model. Pass this context to `product-manager` in Phase 3b.

**Evidence inputs** (note which exist; an absent one is reported, not skipped silently):
- `docs/research/[feature].md` — research note (DoD gate 1)
- `docs/architecture/threat-models/[feature].md` — threat model
- `docs/architecture/perf-budgets.md` — performance budgets
- `contracts/` — the contract files the spec links
- `design/ux/` — UX spec for the screens it mentions

**Prior review check:** Check whether `design/specs/reviews/[doc-name]-review-log.md` exists. If it does, read the most recent entry — note what verdict was given and what blocking items were listed. This session is a re-review; track whether prior items were addressed.

---

## Phase 2: Completeness Check

**Step 2a — gather section presence deterministically (no document read):**

```
Bash: bash .claude/scripts/spec-structure-check.sh [target-doc-path]
```

It prints a `PRESENT:` list and, when applicable, an `ABSENT:` list. It reports
**presence only** and makes no REQUIRED/ADVISORY judgment — that is Step 2b's
job. It accepts the heading aliases (`Detailed Rules` for Detailed Behaviour,
`Non-Functional` for Non-Functional Requirements), so do not flag those as
missing. If the script cannot run, say so and scan the headings yourself.

**Step 2b — apply the tier.** Using the Step 2a lists, evaluate against the
checklist below. **Mark each section REQUIRED or ADVISORY per the resolved
workflow tier (Phase 0).** A missing REQUIRED section blocks approval; a missing
ADVISORY section is surfaced as a recommendation but does not block.

A section reported PRESENT can still fail review if it is an empty heading or a
`[To be designed]` placeholder — spot-read any section the verdict actually turns on.

- [ ] Has Overview section (one-paragraph summary) — REQUIRED at all tiers
- [ ] Has User Value section (role, job, plan/pricing impact) — REQUIRED at `full`; ADVISORY at `standard`
- [ ] Has Detailed Behaviour section (unambiguous rules, permissions per role, states) — REQUIRED at `full`/`standard`
- [ ] Has Data & Contracts section (entities, endpoints, events) — REQUIRED at `full`/`standard`. Its Formulas and Rules sub-block: REQUIRED at `full`; at `standard` REQUIRED whenever the feature defines numeric rules, else ADVISORY
- [ ] Has Edge Cases & Failure Modes section — REQUIRED at `full`; at `standard` REQUIRED when the feature calls an external provider, moves money, changes entitlements or runs asynchronously (or `workflow_overrides.edge_cases`), else ADVISORY
- [ ] Has Dependencies section (contexts, core modules, providers, flags) — REQUIRED at `full`; ADVISORY at `standard`
- [ ] Has Non-Functional Requirements section — REQUIRED at `full`/`standard`; its Configuration subsection REQUIRED when `workflow_overrides.tuning_knobs` or the feature has tunable values
- [ ] Has Acceptance Criteria section (testable success conditions) — REQUIRED at `full`/`standard`
- [ ] Has `## Summary` and a populated Quick reference — REQUIRED at every tier

---

## Phase 3: Consistency, Implementability and the SaaS Bar

**Internal consistency:**
- Do the formulas produce values that match the described behaviour (money in integer minor units, rounding stated)?
- Do edge cases contradict the main rules?
- Are dependencies bidirectional (does the other spec know about this one)?
- Do entities named in Detailed Behaviour appear in Data & Contracts with an owner and a tenant key?

**Implementability:**
- Are the rules precise enough for an engineer to implement without guessing? Every "should" must be a "must" or removed.
- Are there any "hand-wave" sections where details are missing?
- Does each endpoint have a policy, success status, error codes (problem `code`) and idempotency stated, and does it link a `contracts/` file (or say the contract is still to be written)?
- Is every acceptance criterion independently testable? Flag each one that is
  not, quoting it — "works correctly", "is fast", "is secure" are not criteria —
  with a measurable rewrite. In `full` mode `qa-lead` also checks them (Phase 3b);
  in `lean` and `solo` no specialist runs, so this main-review check is the only one.

**Testable criteria incl. negative and cross-tenant (check each, quote the evidence or mark MISSING):**
- Anonymous request → 401 on every endpoint
- Role without permission → 403 and nothing changes
- **Other-tenant access → 404** (no existence leak) — a spec that has no cross-tenant criterion is a BLOCKER for any feature with tenant data
- Invalid input → 422 with problem `code`; malformed → 400
- Repeating a request with the same `Idempotency-Key` has no second effect (for repeatable writes)
- Over-quota / plan-downgrade / provider-down behaviour (where relevant)
- Each criterion tagged with the story type that proves it (Logic / Integration / Contract / Security / Performance / UI / Config)

**Plan / permission matrix:**
- Permissions are stated per role for every action (Owner / Admin / Member / Viewer / Anonymous / Other tenant), with no empty cells.
- Where plans differ, the plan effect is stated per plan, links to the pricing model's entitlement key or quota name, and **restates no price or quota number** (`.claude/rules/specs.md`).
- The matrix agrees with the permission model of the identity context and with the entitlement keys in the registry. Flag any role the spec uses that the identity context does not define.

**NFRs present and specific** (all six NFR sub-headings must be answered or marked `n/a — <reason>` at every tier; a bare heading is MISSING):
- Security: threat-model trigger test answered; if a trigger applies (authentication, authorization model, billing, licensing, file upload, webhooks, PII export/delete, admin/impersonation, new external integration) a threat model exists or is linked as required; ASVS/MASVS mapping present — IDs that look recalled rather than looked up, or unreadable standards text, are noted as `unverified`; tenant isolation and its test named; abuse limits named as configuration.
- Performance budget stated per surface and consistent with `perf-budgets.md` (or reported "no project budget exists").
- Caching decision written (cache design, or a reason for no cache).
- Observability: spans, RED + business metrics, outcome logs without PII, alert/SLO or reason none.
- Accessibility: target and keyboard/label/contrast/motion notes, or `n/a — no surface`.
- Localization: Arabic (RTL) and English, strings externalised, formatting per locale.

**Dependencies on core modules:**
- Every capability that belongs to `saas-core` (identity, OTP, notify, storage, billing, licensing, tenancy, audit, ratelimit, observability) is consumed through the module, not re-specified as product behaviour. Flag a spec that defines its own sign-in, email delivery, file storage, subscription lifecycle or licence check.
- Each core dependency states whether the module covers the need as-is, needs an extension, or is `pending core`.

**Cross-feature consistency:**
- Does this conflict with any existing feature?
- Does this create unintended interactions with other features (shared quota, shared entity, conflicting state machine)?
- Is this consistent with the product's principles and ICP?

**Evidence inputs:** the research note (DoD gate 1) is not a spec section, but report whether it exists; a spec for a provider-dependent feature whose provider has no research note gets a RECOMMENDED finding to run `/research`.

---

## Phase 3b: Adversarial Specialist Review (full mode only)

**Skip this phase in `lean` or `solo` mode.**

**This phase is MANDATORY in full mode.** Do not skip it.

**Before spawning any agents**, print this notice:
> "Full review: spawning specialist agents in parallel. This typically takes 8–15 minutes. Use `--review lean` for faster single-session analysis."

### Step 1 — Identify all domains the spec touches

Using the spec **already loaded in Phase 1** — do not re-read it — identify every domain present. A spec can touch multiple domains simultaneously — be thorough. Common signals:

| If the spec contains... | Spawn these agents |
|------------------------|-------------------|
| Sign-in, sessions, roles, MFA, SSO, invitations | `auth-identity-specialist`, `security-lead` |
| Tenant model, workspaces, membership, isolation | `multitenancy-specialist` |
| Plans, prices, entitlements, quotas, proration, trials, dunning | `pricing-billing-designer` |
| Licence keys, activation, offline grace, self-hosted | `licensing-specialist` |
| Entities, ownership, invariants, cross-context flows | `domain-architect` |
| Endpoints, pagination, errors, idempotency, webhooks | `api-designer` |
| Data stores, retention, migrations | `data-lead` |
| External providers (payments, email/SMS, storage, push) | `integrations-engineer` |
| PII, export/delete, retention, consent | `privacy-compliance-specialist` |
| Upload, SSRF, abuse, rate limits | `appsec-engineer` |
| Hot paths, lists, jobs, budgets | `performance-engineer` |
| Cache proposals | `cache-specialist` |
| Spans, metrics, alerts, SLOs | `observability-engineer` |
| Screens, flows, forms, app shell | `ux-designer`, `accessibility-specialist` |
| Strings, emails, locale formatting | `localization-lead` |
| Events, funnels, activation metrics | `product-analytics-engineer` |
| Acceptance criteria, test coverage | `qa-lead` |
| Any feature | `product-manager` (always) |

Spawn `product-manager` for every spec. Spawn `domain-architect` for every spec with entities or cross-context flows. Spawn `security-lead` for any spec where the threat-model trigger test (Phase 3) found a sensitive area. Use the table above for the rest; spawn only the relevant specialists.

### Step 2 — Spawn all relevant specialists in parallel

**CRITICAL: `Agent` in this skill spawns a SUBAGENT — a separate independent Claude session
with its own context window. It is NOT task tracking. Do NOT simulate specialist
perspectives internally. Do NOT reason through domain views yourself. You MUST issue
actual `Agent` calls. A simulated review is not a specialist review.**

Issue all `Agent` calls simultaneously. Do NOT spawn one at a time.

**Prompt each specialist adversarially:**
> "Here is the feature spec for [feature] and the main review's structural findings so far.
> Your job is NOT to validate this design — your job is to find problems.
> Challenge the choices from your domain expertise. What is wrong,
> underspecified, likely to cause problems in production, or missing entirely?
> Cite section and line. Be specific and critical. Disagreement with the main review is welcome."

**Additional instructions per agent type:**

- **`product-manager`**: Anchor your review to the User Value stated in Section 2 (or the Overview when absent). Does this design deliver the job for the stated role? Would the ICP pay for it, and does the plan gating match? Flag any rules that serve implementability but undermine the stated value.

- **`domain-architect`**: For every entity, check ownership (exactly one context), tenant key, and invariants; for every state machine, try the illegal transitions. Report cross-context writes that bypass the owner's port.

- **`pricing-billing-designer`**: For every limit, quota and formula, plug in boundary values (zero, at-limit, over-limit, downgrade mid-period, refund). Report whether any plan/permission combination is a loophole (a path to a gated capability without the entitlement) or whether outputs go degenerate (negative amounts, rounding drift).

- **`security-lead` / `appsec-engineer`**: Attempt IDOR, privilege escalation, replay, enumeration and abuse on each endpoint and flow. Confirm the threat-model trigger answer. Report missing controls with the standard section they fall under, without citing requirement numbers you cannot look up.

- **`qa-lead`**: Review every acceptance criterion. Flag any that are not independently testable — "works correctly", "is fast", "is secure" are not criteria. Confirm the negative, cross-tenant and over-quota cases are present, and suggest concrete rewrites for any that fail.

### Step 3 — Senior lead review

After all specialists respond, spawn `product-director` as the **senior reviewer**:
- Provide: the spec, all specialist findings, any disagreements between them
- Ask: "Synthesise these findings. What are the most important issues? Do you agree with the specialists? What is your overall verdict on this spec — APPROVED, NEEDS REVISION or MAJOR REVISION NEEDED?"
- The product-director's synthesis becomes the **final verdict** in Phase 4, in this skill's verdict words — never a director-gate word such as READY or REJECT.

### Step 4 — Surface disagreements

If specialists disagree with each other or with the product-director, do NOT silently pick one view. Present the disagreement explicitly in Phase 4 so the user can adjudicate.

Mark every finding with its source: `[product-manager]`, `[domain-architect]`, `[product-director]` etc.

---

## Phase 4: Output Review

```
## Spec Review: [Document Title]
Specialists consulted: [list agents spawned, or "none — Lean/Solo mode"]
Re-review: [Yes — prior verdict was X on YYYY-MM-DD / No — first review]
Effective tier: [minimal | standard | full] (source: [project value | system_overrides])

### Completeness: [X/N sections present, where N is the count REQUIRED at this feature's effective tier]
[List only sections missing that are REQUIRED at this tier. Mark ADVISORY gaps
separately as "advisory at `standard`" — do not list them as missing.]

> **N is not 8 unless `workflow: full`.** The tier table earlier in this skill is
> authoritative: 8 required at `full`, 5 at `standard` (+ Edge Cases & Failure
> Modes when triggered, + Formulas when numeric rules), 0 at `minimal`. Hardcoding
> `/8` reports a `standard` project as missing sections its own configuration
> says it does not need, which trains the reader to ignore the review.

### SaaS Bar Checks
| Check | Result (met / not met / not checked) | Evidence (section / quote) |
|---|---|---|
| Negative + cross-tenant acceptance criteria | | |
| Permission matrix complete, per role | | |
| Plan effect per plan, no price restated | | |
| NFR: Security (threat-model trigger answered; link if required) | | |
| NFR: Performance budget | | |
| NFR: Caching decision | | |
| NFR: Observability | | |
| NFR: Accessibility | | |
| NFR: Localization (AR/EN) | | |
| Core-module dependencies consumed, not re-specified | | |
| Research note exists (DoD gate 1) | | |
[A check that could not run — missing input, unreadable standards text — is
`not checked` with the reason. It is never counted as met.]

### Dependency Graph
[List each declared dependency and whether its spec file exists on disk]
- ✓ team-invitations.md — exists
- ✗ data-export.md — NOT FOUND (file does not exist yet)
- ⚠ core: identity — pin not readable (`core.version` unset)

### Required Before Implementation
[Numbered list — blocking issues only. Each item tagged with source agent.]

### Recommended Revisions
[Numbered list — important but not blocking. Source-tagged.]

### Specialist Disagreements
[Any cases where agents disagreed with each other or with the main review.
Present both sides — do not silently resolve.]

### Nice-to-Have
[Minor improvements, low priority.]

### Senior Verdict [product-director]
[Product director's synthesis and overall assessment. "not run — Lean/Solo mode" otherwise.]

### Scope Signal
Estimate implementation scope based on: dependency count, endpoint count,
formula count, contexts touched, and whether new ADRs or a threat model are required.
- **S** — single context, no formulas, no new ADRs, <3 dependencies
- **M** — moderate complexity, 1-2 formulas, 3-6 dependencies
- **L** — multi-context integration, 3+ formulas, a provider or sensitive area, may require a new ADR (at `modes.workflow: minimal`, a decision-log entry in the brief)
- **XL** — cross-cutting concern, 5+ dependencies, multiple new ADRs likely
Label clearly: "Rough scope signal: M (producer should verify before sprint planning)"

### Verdict: [APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED / NOT ASSESSED]

> **`NOT ASSESSED` when the review could not actually be performed.**
> The other three verdicts are all claims about the design's quality, so each one
> asserts that the document was read and judged. Use `NOT ASSESSED` instead when
> the target document is absent, unreadable, or empty of the sections being
> reviewed, or when a document it depends on is missing so the criteria cannot be
> applied. **Name what was unavailable and which skill produces it.**
>
> `APPROVED` is the dangerous default here: a review that could not find its
> input has not approved anything, and this verdict is consumed downstream as a
> sign-off. `NOT ASSESSED` outranks `APPROVED` in any aggregate — it does not
> outrank the two revision verdicts, because a known problem is more actionable
> than an unknown one. A SaaS-bar check marked `not checked` keeps the verdict
> from being `APPROVED` unless the user accepts it explicitly.
```

This skill is read-only — no files are written during Phase 4.

---

## Phase 5: Next Steps

Use `AskUserQuestion` for ALL closing interactions. Never plain text.

**First widget — what to do next:**

If APPROVED (first-pass, no revision needed), proceed directly to the domain-map widget, review-log widget, then the final closing widget. Do not show a separate "what to do" widget — the final closing widget covers next steps.

If NOT ASSESSED, nothing was reviewed: offer no tracking update and go straight
to the final closing widget, leading with the skill that produces the missing
input (e.g. `/design-spec [feature]` for a spec that does not exist).

If NEEDS REVISION or MAJOR REVISION NEEDED, build the options from the findings:
- `[A] Revise the spec now — address blocking items together`
- `[B] Stop here — revise in a separate session`
- `[C] Accept as-is and move on` — include only when every finding is advisory
  (Required Before Implementation is empty). With any blocking item, offer [A]
  and [B] only.

**If user selects [A] — Revise now:**

Work through all blocking items, asking for decisions only where you cannot resolve the issue from the spec and existing docs alone. Group all questions into a single multi-tab `AskUserQuestion` before making any edits — do not interrupt mid-revision for each blocker individually.

Editing the spec is an edit to an existing file, which no `CLAUDE.md` exemption covers — its folder is not one. Follow the automation mode: in `collaborative`, show the planned changes and ask "May I write these revisions to `[doc-path]`?" before the first edit; in `guided` and `autonomous` the edits proceed, and the stated reason is the mode, never an exemption.

After all revisions are complete, show a summary table (blocker → fix applied) and use `AskUserQuestion` for a **post-revision closing widget**:

- Prompt: "Revisions complete — [N] blockers resolved. What next?"
- Note current context usage: if context is above ~50%, add: "(Recommended: /clear before re-review — this session has used X% context. A full re-review runs several agents and needs clean context.)"
- Options:
  - `[A] Re-review in a new session — run /spec-review [doc-path] after /clear`
  - `[B] Accept revisions for now — mark In Review in the domain map; a re-review decides Approved`
  - `[C] Move to next feature — /design-spec [next-feature] (#N in specification order)`
  - `[D] Stop here`

In collaborative and guided modes, never end the revision flow with plain text —
always close with this widget. In autonomous mode, summarize the outcome and
record via `log_decision`.

**Second widget — tracking records (combined, for APPROVED path):**

When the verdict is APPROVED, use a single `AskUserQuestion` with `multiSelect: true` to batch the two tracking updates:
- Prompt: "Verdict: APPROVED. I can update the tracking records now. Select any you'd like me to complete:"
- Options:
  - `Update domain-map.md status to 'Approved' for [feature]`
  - `Append approval entry to design/specs/reviews/[doc-name]-review-log.md`

If the review-log option is selected, append the same format as below. Execute both selected actions before showing the final closing widget.

When the verdict is NEEDS REVISION or MAJOR REVISION NEEDED, use separate widgets:

Use a second `AskUserQuestion`:
- Prompt: "May I update `design/specs/domain-map.md` to mark [feature] as [Needs Revision / In Review]?" — `Needs Revision` (that exact string) while the revisions are outstanding, `In Review` once they are applied and await re-review. This prompt never offers `Approved`: a revision verdict is not an approval.
- Options: `[A] Yes — update it` / `[B] No — leave it as-is`

If `domain-map.md` does not exist (project tier `minimal`), say so and skip this
widget — do not create one; `/map-domains` owns that file.

Use a third `AskUserQuestion`:
- Prompt: "May I append this review summary to `design/specs/reviews/[doc-name]-review-log.md`? This creates a revision history so future re-reviews can track what changed."
- Options: `[A] Yes — append to review log` / `[B] No — skip`

If yes, append an entry in this format:
```
## Review — [YYYY-MM-DD] — Verdict: [APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED / NOT ASSESSED]
Scope signal: [S/M/L/XL]
Specialists: [list]
Blocking items: [count] | Recommended: [count]
Not checked: [SaaS-bar checks that could not run, or "none"]
Summary: [2-3 sentence summary of key findings from the senior verdict]
Prior verdict resolved: [Yes / No / First review]
Findings:
- [BLOCKING] [section]: [one-line finding]
- [RECOMMENDED] [section]: [one-line finding]
[output of: Bash: bash .claude/scripts/review-receipts.sh hash "[target-doc-path]" — plus "design/registry/entities.yaml" if the registry file exists]
```

Findings rules: one line per finding, named by the section it lives in;
write `- none` when the verdict carried no findings. This is documentation
for a human reader of the revision history, not a mechanism the skill reads
back — a delta re-review that skipped re-analyzing unchanged sections misses
defects (see Phase 1).

The hash line is the receipt Phase 1 reads on the next run to detect a
byte-identical re-review — the one form of skip that's actually safe,
because the input is provably the same. Always include it, whatever the verdict — an
unchanged document that previously FAILED review is exactly the case where
skipping a redundant re-review saves the most (the prior findings stand
verbatim).

---

**Checkpoint.** Before the final closing widget, update
`production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`:
Current task `/spec-review <doc> — <verdict>`, Next step = the first option the
closing widget will mark `(recommended)` (e.g. `/design-spec <next-feature>`, or
the revision of the first blocking item), plus Blocked on (open blocking items)
/ Files in progress (the domain map and review log, if written) / Open
questions; append the Notes line. Still updated for NOT ASSESSED or when the
user declined the tracking writes (record that nothing was written).

**Final closing widget — always show after all file writes complete:**

Once the domain-map and review-log widgets are answered, check project state and show one final `AskUserQuestion`:

Before building options, read:
- `design/specs/domain-map.md` (if it exists) — find any feature with Status: In Review or Needs Revision (other than the one just reviewed)
- Count `.md` files in `design/specs/` (excluding `domain-map.md`, `spec-cross-review-*.md`) to determine if `/review-all-specs` is worth offering (≥2 specs)
- Find the next feature with Status: Not Started in specification order

Build the option list dynamically — only include options that are genuinely next:
- `[_] Run /spec-review [other-spec-path] — [feature name] is still [In Review / Needs Revision]` (include if another spec needs review)
- `[_] Run /threat-model [feature] — the spec flagged a sensitive area and no threat model exists` (include when Phase 3 found that)
- `[_] Run /consistency-check — verify this spec's names and values don't conflict with existing specs` (always include if ≥1 other spec exists)
- `[_] Run /review-all-specs — cross-spec review across all specified features` (include if ≥2 specs exist)
- `[_] Run /design-spec [next-feature] — next in specification order` (always include, name the actual feature)
- `[_] Stop here`

Assign letters A, B, C… only to included options. Mark the most pipeline-advancing option as `(recommended)`.

In collaborative and guided modes, never end the skill with plain text after
file writes — always close with this widget. In autonomous mode, print the next
step and record via `log_decision`.
