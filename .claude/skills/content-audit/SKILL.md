---
name: content-audit
description: "Audit planned vs built per feature spec (endpoints, screens, entities, events, entitlements) and required vs present documents at the effective workflow tier."
argument-hint: "[feature-name | --summary | --docs | --built | (no arg = full audit)]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(date *), Bash(bash "*/.claude/skills/content-audit/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,automation,system_overrides,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

# Content Audit

Two audits in one skill, because both answer "is what we said we would have
actually there?":

- **Part A — Documents:** required vs present at each feature's effective
  workflow tier (`.claude/docs/workflow-modes.md`): brief, domain map, specs and
  their sections, ADRs, UX specs, threat models, research notes, SLOs.
- **Part B — Built:** planned vs built per feature spec: the endpoints, screens,
  entities, events and entitlements a spec declares, against `contracts/`, the
  code roots and the pricing model.

> This skill declares tier-dependent behaviour ("audit only the required
> sections"), which is unreachable unless the tier is actually resolved — without
> it the skill applies whatever tier it assumed. Resolve the effective tier per
> feature before auditing, and when a required input such as
> `design/specs/domain-map.md` is absent, report **`NOT ASSESSED — NO DATA`**
> rather than computing a gap percentage (which divides by zero when nothing is
> specified).

When this skill is invoked, parse the argument:
- No argument → full audit (Part A and Part B) across all features
- `[feature-name]` → audit that single feature only (the spec filename stem)
- `--docs` → Part A only; `--built` → Part B only
- `--summary` → summary tables only, no file write

---

**`workflow`** (see `.claude/docs/workflow-modes.md`), applied per feature at its
**effective** tier — `system_overrides.<stem>` when listed, else the project value:
- `full` — all 8 spec sections, all ADRs, UX spec per screen, threat model per
  sensitive feature, SLOs.
- `standard` — the 5 required sections (+ Edge Cases & Failure Modes when the
  feature calls a provider, moves money, changes entitlements or runs
  asynchronously), critical ADRs, threat models for sensitive features. Counts
  found only outside the required sections are listed as not audited at this tier.
- `minimal` — Part A checks only the floor: a filled `design/product-brief.md`,
  a configured stack, and `docs/research/<feature>.md` for each feature that has
  code. No specs or ADRs are *required*, so their absence is not a gap. Part B
  has no specs to read: a `minimal` feature is built-vs-brief and is reported
  `NOT ASSESSED — no spec` unless the user passes a brief section to audit.

**Tier scales documents, never engineering.** Whatever the tier, the eight
Definition of Done gates apply; this audit never reports a missing document as
acceptable on the grounds that the gate is waived by the tier.

**After a tier change** (`/settings` moved `modes.workflow`): this is the skill
`workflow-modes.md` points to for "what's now required or extra". Report extra
documents (present, no longer required) as informational — never as deletions to
make.

## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads (`project.yaml`, `design/product-brief.md`,
   `design/specs/domain-map.md`, specs, ADRs, UX specs, threat models, research
   notes, `contracts/`, the code roots, the pricing model, the entity registry).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill produces it (`/map-domains` for `design/specs/domain-map.md`,
   `/design-spec` for the specs, `/brainstorm` for the brief).

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer
when there is no data. The failure mode this prevents: a report whose verdict
enum has no "could not run" state produces **false clean passes** — a docs audit
returning COMPLETE on a project with no specs, or a built-vs-planned audit
reporting 0% gap because nothing was specified.

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which
of the two happened — a reader cannot tell from a green result.

**Code roots.** Resolve them from `layout.code_roots` in `project.yaml`, else the
conventional `backend/`, `web/`, `site/`, `mobile/`, `contracts/` that exist on
disk (the resolution `resolve_code_root` performs in `.claude/hooks/yaml-helper.sh`;
`.claude/docs/directory-structure.md`). **If none resolves, every Found count in
Part B reads `NOT ASSESSED — code roots unresolved`**, never zero — code kept under
`app/` or `services/` is invisible to the conventional scan.

---

## Phase 1 — Context Gathering

1. **Read `design/specs/domain-map.md`** for the full list of bounded contexts
   and features, their category, priority (MVP / later) and dependencies. This is
   the denominator for both parts. Absent → `NOT ASSESSED — NO DATA` for
   everything feature-scoped; Part A's global-document rows can still run.

2. **Resolve the effective tier per feature** (stem of the spec filename, or the
   feature's name in the domain map when no spec exists yet).

3. **Registry-first count (Part B)**: if `design/registry/entities.yaml` exists,
   read it first. Its `entities`, `events`, `quotas`, `plans` and `permissions`
   sections are the cross-spec named content the audit counts, already distilled
   with a `source:` spec per entry:
   ```
   Grep pattern="^  - name:" path="design/registry/entities.yaml" output_mode="content" -A 2
   ```
   Keep the names whose `-A 2` context shows the section. Use them as the
   **planned** named-content set without full-reading the specs that own them.
   If the registry does not exist or has no entries, skip this step and rely on the
   spec scan below — behaviour is unchanged, only more expensive.

4. **L0 pre-scan**: before full-reading any spec, run **two** greps — they answer
   different questions and must not share a pattern:

   a. Which specs carry an `## Overview` (the denominator / fail-open check):
   ```
   Grep pattern="^## Overview" glob="design/specs/*.md" output_mode="files_with_matches"
   ```

   b. Which specs actually declare countable content:
   ```
   Grep pattern="[0-9]+[[:space:]]+(endpoints|operations|screens|pages|views|entities|tables|events|roles|permissions|plans|entitlements|quotas|jobs|webhooks|notifications|reports)|operationId|(POST|GET|PUT|PATCH|DELETE)[[:space:]]+/" glob="design/specs/*.md" output_mode="files_with_matches"
   ```

   > **Keep the two scans separate.** `## Overview` matches every compliant spec,
   > so a union with it narrows nothing, and a literal placeholder such as
   > `N endpoints` matches no real spec. Pattern (b) matches digits followed by the
   > content nouns step 6 extracts, or an HTTP route.

   **Fail open on a missing Overview.** Glob `design/specs/*.md` (excluding
   `domain-map.md`, `review-*.md`, `spec-cross-review-*.md`) and count **N**. Scan
   (a) matching fewer than N means those specs are malformed or predate the
   template — never treat that as a feature out of scope; full-read the unmatched
   in-scope specs.

   For a single-feature audit: skip this step and go straight to full-read. For a
   full audit: full-read the specs scan (b) matched **and** that the registry does
   not fully cover, plus every spec scan (a) missed — **the fail-open rule wins
   over this narrowing**. A spec with an Overview and no countable content is
   noted "No auditable content counts" without a full read.

5. **Full-read in-scope specs** (or the single feature's spec).

6. **For each spec, extract planned content**, noting the `##` section each sits
   under — at `standard`, a count outside the required sections goes on the "Not
   audited at this tier" list, never into the inventory:
   - Endpoints / operations (HTTP routes, `operationId`s), webhooks, jobs
   - Screens / views / flows (named in Detailed Behaviour or the UX spec)
   - Entities / tables, events emitted and consumed
   - Roles and permissions; entitlements and quotas it references
   - Acceptance criteria (count, and how many are negative cases: wrong role,
     other tenant, over quota, provider down)
   - Any explicit enumerated list of named content pieces

7. **Build a planned-content inventory table**:

   | Feature | Content type | Specified count/list | Source spec |
   |---|---|---|---|

   If a spec describes content qualitatively with no count, record "Unspecified"
   and flag it — unspecified counts are a spec gap worth noting.

---

## Phase 2 — Document Scan (Part A)

For each feature at its effective tier, check **required vs present**. Presence
is a file-and-section test, not a quality judgement (quality is `/spec-review`,
`/architecture-review`, `/ux-review`).

| Artifact | Where | Required at |
|---|---|---|
| Product brief (filled, not template placeholders) | `design/product-brief.md` | every tier |
| Stack configured | `project.yaml` `stack` | every tier |
| Research note | `docs/research/<feature>.md` | every tier, for each feature with code |
| Domain map | `design/specs/domain-map.md` | `standard`, `full` |
| Spec, required sections for the tier | `design/specs/<feature>.md` | `standard` (5 + conditional), `full` (8) |
| Architecture doc | `docs/architecture/architecture.md` | `standard`, `full` |
| ADRs | `docs/architecture/adr-*.md` | critical only at `standard`; all at `full` |
| Threat model | `docs/architecture/threat-models/<feature>.md` | sensitive features (auth, billing, file upload, PII) at `standard`, `full` |
| UX spec per screen | `design/ux/` | `full` |
| Pricing model | `design/specs/pricing-model.md` (canonical; else `Glob design/**/pricing-model*.md`) | when the brief names a paid plan, at `standard`, `full` |
| Perf budgets / SLOs | `docs/architecture/perf-budgets.md`, `slos.md` | budgets `standard`+; SLOs `full` |
| `PRODUCT.md` (impeccable context) | repo root | before any UI work |

Method: one Glob per row family, then a `Grep pattern="^## "` per spec for its
section headings. Count a section present only if its heading exists **and** it is
not template placeholder text (a heading followed only by `[...]` is `PLACEHOLDER`,
reported as such). A feature is "sensitive" when its spec or the brief names auth,
billing/payments, file upload or personal data — if sensitivity cannot be judged
for a feature, list it under "sensitivity not assessed", never as non-sensitive.

Per feature produce a row:

`Feature | Tier | Spec sections present/required | ADR | UX | Threat model | Research note | Status`

Status: `COMPLETE` (all required present), `PARTIAL`, `MISSING` (none), or
`EXTRA` (present, not required at this tier). Missing *required* items are gaps;
missing *optional* ones are informational.

---

## Phase 3 — Implementation Scan (Part B)

For each content type in Phase 1, count what is built. Use Glob and Grep.

**Endpoints / operations**
- Planned: spec routes / `operationId`s. Declared: `Grep` them in `contracts/openapi/*.yaml`.
- Built: `Grep` the `operationId` or route in the backend root (`backend/`
  `internal/**/adapters/**` or `src/main/kotlin/**/adapters/**`). Declared-in-contract
  but absent from the backend is `CONTRACT ONLY`; present in code but absent from the
  spec is `UNSPECIFIED` (informational — surface it).

**Screens / flows**
- Planned: screens named in the spec and in `design/ux/*.md`.
- Built: routes/features in `web/src/features/<feature>/`, Compose screens in
  `mobile/android/**`, SwiftUI views in `mobile/ios/**`, only for the layers the
  stack config lists. A layer not in `stack` is `N/A`, not `NOT STARTED`.

**Entities / tables**
- Built: migration files under the backend (`**/migrations/**`) and domain types
  in `**/domain/**`. Count tables named in the spec.

**Events / jobs / webhooks**
- Built: producers and consumers by event name in the backend root; jobs by name.

**Entitlements and quotas**
- Planned: entitlement keys and quota names in the spec. Declared: the pricing
  model. Built: `Grep` the key in the backend (`can(`/entitlement check) — a key
  declared and never checked is `UNENFORCED` (feeds `/pricing-check`).

**Acceptance criteria**
- Do not claim criteria are met by file counting. Count only criteria that name a
  test; for the rest report "not verifiable by this audit" — `/story-done` and
  `/test-evidence-review` own that.

**Caveats to acknowledge in the report:** counts are approximations by name match;
the scan cannot perfectly distinguish generated code, fixtures or test doubles
from shipped behaviour.

---

## Phase 4 — Gap Report

Produce the gap table:

```
| Feature | Content type | Specified | Found | Gap | Status |
|---------|--------------|-----------|-------|-----|--------|
```

**Status categories:**
- `COMPLETE` — Found ≥ Specified (100%+)
- `IN PROGRESS` — Found is 50–99% of Specified
- `EARLY` — Found is 1–49% of Specified
- `NOT STARTED` — Found is 0
- `NOT ASSESSED` — Found could not be taken (code roots unresolved, layer not
  inspectable); no Gap, never `NOT STARTED`, outside both totals; the summary names it

**Priority flags:** mark `HIGH PRIORITY` when status is `NOT STARTED` or `EARLY`
**and** the feature is MVP in the domain map, or the domain map shows it blocks a
downstream feature.

**Summary line:** total items specified; total found; overall gap
`(Specified - Found) / Specified * 100`; plus Part A: features with all required
documents / total features.

---

## Phase 5 — Output

### Full audit and single-feature modes

Present the tables and summary. Ask: "May I write the full report to `docs/content-audit-[YYYY-MM-DD].md`?"

If yes, write:

```markdown
# Content Audit — [Date]

## Summary
- **Features audited**: [M] ([tiers: full N / standard N / minimal N])
- **Documents**: [X] of [Y] features have every required document
- **Built**: specified [N], found [N], gap [N] items ([X%])
- **Scope**: [Full | Feature: name | --docs | --built] — [all spec sections | required sections only (workflow: standard) | per feature]
- **Not audited at this tier**: [counts found only outside the required sections — or "none"; omit at `full`]
- **Not assessed**: [every row or layer that could not run, with the reason — or "none"]

> Note: Counts are approximations based on name matching. The audit cannot
> distinguish shipped behaviour from fixtures or generated code. Manual
> verification is recommended for any HIGH PRIORITY gaps.

## Part A — Documents (required vs present)

| Feature | Tier | Spec sections | ADR | UX | Threat model | Research | Status |

### Missing required documents
[with the skill that produces each]

### Extra documents (not required at the current tier)
[informational]

## Part B — Built (planned vs built)

| Feature | Content type | Specified | Found | Gap | Status |

## HIGH PRIORITY Gaps
[feature, rationale]

## Contract-only / Unspecified / Unenforced
[declared but not built; built but not specified; entitlements never checked]

## Unspecified Content Counts
[specs that describe content without counts]

## Recommendation
Focus effort on: 1. … 2. … 3. …
```

After writing, ask: "Would you like to create backlog stories for any of the gaps?"
If yes, for each selected feature suggest a story title and point to
`/create-stories [epic-slug]` or `/quick-spec` depending on the size of the gap.

### --summary mode

Print the tables and summary to the conversation. Do not write a file. End with:
"Run `/content-audit` without `--summary` to write the full report to `docs/`."

---

## Phase 6 — Next Steps

- A required document missing → name the producer: `/design-spec [feature]`,
  `/architecture-decision`, `/ux-design`, `/threat-model [feature]`, `/research`.
- A feature `NOT STARTED` and MVP → "Run `/design-spec [feature]` to add the
  missing counts, then `/create-stories`."
- `UNENFORCED` entitlement or quota → "Run `/pricing-check`."
- Total gap > 50% → "Run `/sprint-plan` to allocate work across upcoming sprints."
- `--summary` used → "Run `/content-audit` (no flag) to write the full report."

**Checkpoint.** Unless the run was `--summary` (read and report only), update
`production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`:
Current task `/content-audit <scope> — <verdict>`, Next step = the first step
above that applies (a concrete command), plus Blocked on / Files in progress (the
report under `docs/`) / Open questions; append the Notes line. Still updated on
`NOT ASSESSED — NO DATA` or a declined write (record nothing written and why).

Close with the verdict that matches the run:
- Verdict: **COMPLETE** — content audit finished, every row assessed.
- Verdict: **GAPS FOUND** — required documents missing or content planned and not
  built; list them. Outranks NOT ASSESSED: a known gap is more actionable than an unknown.
- Verdict: **NOT ASSESSED — NO DATA** — a required input was absent (see the note
  at the top), nothing in scope gives a count, or a Found count could not be taken
  (`NOT ASSESSED — code roots unresolved`); name which, and for missing counts name
  `/design-spec`. Never print COMPLETE for a run that could not compute a gap.
