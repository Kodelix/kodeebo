---
name: consistency-check
description: "Scan feature specs against the entity registry and domain map for cross-document conflicts (plans, roles, quotas, events). Grep-first, targets conflicting sections."
argument-hint: "[full | since-last-review | entity:<name> | item:<name>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(git log *), AskUserQuestion, Bash(bash "*/.claude/skills/consistency-check/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,system_overrides`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

# Consistency Check

Detects cross-document inconsistencies by comparing all feature specs against
the entity registry (`design/registry/entities.yaml`) and the domain map
(`design/specs/domain-map.md`). Uses a grep-first approach: reads the registry
once, then targets only the spec sections that mention registered names — no
full document reads unless a conflict needs investigation.

**This skill is the write-time safety net.** It catches what `/design-spec`'s
per-section checks may have missed and what `/review-all-specs`'s holistic review
catches too late. A plan limit stated as 25 seats in one spec and 20 in another
is a billing bug that nobody notices until a customer does.

**What the registry holds** (SaaS entities that more than one spec talks about):

| Kind | Examples | Typical attributes |
|---|---|---|
| `entities` | Tenant, Workspace, Invoice, Appointment | owning context, tenant-scoped (yes/no), retention |
| `plans` | Free, Starter, Team | entitlement keys granted |
| `roles` | owner, admin, member, viewer | permissions held |
| `permissions` | `invoice.refund`, `member.invite` | roles allowed, plan required |
| `quotas` | `max_seats`, `api_requests_month` | value per plan, unit, period, hard/soft |
| `events` | `subscription.cancelled` | producer context, payload fields, consumers |
| `constants` | `trial_days`, `invite_ttl_days` | value, unit |

Values live in the registry as the cross-spec fact; prices are **never**
registered here (they live in the pricing model).

**When to run:**
- After writing each new spec (before moving to the next feature)
- Before `/review-all-specs` (so that skill starts with a clean baseline)
- Before `/create-architecture` (inconsistencies poison downstream ADRs)
- After `/propagate-spec-change` lists downstream specs to re-check
- On demand: `/consistency-check entity:[name]` to check one entry specifically

**Output:** Conflict report + optional registry corrections

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt). Appending facts to the
registry is `minor`; changing a template or `project.yaml` structure is not.

**`workflow`** (see `.claude/docs/workflow-modes.md`), applied per spec at its
**effective** tier — the `system_overrides` row for that spec's feature (its
filename stem) when the block lists one, else the project value:
- `full` — full registry cross-check against all spec sections.
- `standard` — cross-check against the required sections only. The report's
  Scope line says so, and each value stated for a registered name outside those
  sections is listed as not checked at this tier (Phase 3 applies this).
- `minimal` — not meaningful (no specs to check). If every in-scope feature is
  `minimal`, the verdict is NOT ASSESSED (Phase 2), not PASS.

## Phase 1: Parse Arguments and Load Registry

**Modes:**
- No argument / `full` — check all registered entries against all specs
- `since-last-review` — check only specs modified since the last review report
- `entity:<name>` — check one specific entry (any kind) across all specs
- `item:<name>` — alias of `entity:<name>`, kept for muscle memory

**Load the registry:**

```
Read path="design/registry/entities.yaml"
```

If the file does not exist or has no entries:
> "Entity registry is empty. `/design-spec` appends to it after each spec is
> completed. Nothing to check yet."

Verdict: **NOT ASSESSED — entity registry empty**. Stop: nothing was compared,
so there is no PASS to give and nothing to write. (The domain-map check in
Phase 3e does not need the registry — if `design/specs/domain-map.md` exists,
run Phase 3e alone and report the registry portion as NOT ASSESSED.)

Build lookup tables from the registry, one per kind present: **entity_map**,
**plan_map**, **role_map**, **permission_map**, **quota_map**, **event_map**,
**constant_map** — each `{ name → { source, attributes/value, referenced_by } }`.

Count total registered entries. Report:
```
Registry loaded: [N] entities, [N] plans, [N] roles, [N] permissions, [N] quotas, [N] events, [N] constants
Scope: [full | since-last-review | entity:name]
```

For `entity:<name>`, if the registry has no entry by that name the verdict is
**NOT ASSESSED — `<name>` is not in the registry**: list the closest registered
names and stop. Checking an unregistered name compares nothing, and that is not
a PASS.

---

## Phase 2: Locate In-Scope Specs

```
Glob pattern="design/specs/*.md"
```

Exclude the docs that live in `design/specs/` but are not feature specs:
`domain-map.md`, `review-*.md` and any `spec-cross-review-*.md` (the report
`/review-all-specs` writes here).

For `since-last-review` mode:
```bash
git log --name-only --pretty=format: -- design/specs/
```
(No pipe: from the output keep the `.md` paths and de-duplicate them yourself.)
Limit to specs modified since the most recent `design/specs/spec-cross-review-*.md`
file's creation date.

Report the in-scope spec list before scanning. **If the list is empty** — no
feature specs exist, only `minimal`-tier features are in scope, or
`since-last-review` found none changed — the verdict is
**NOT ASSESSED — no specs in scope**: say which filter produced zero, and stop.
A scan of nothing finds no conflicts, and that is not a PASS.

---

## Phase 3: Grep-First Conflict Scan

For each registered entry, grep every in-scope spec for the entry's name. Do NOT
do full reads — extract only the matching lines and their immediate context
(-C 3 lines).

This is the core optimization: instead of reading 15 specs × 300 lines each,
you grep 60 registered names × 15 specs (targeted searches, each returning ~10
lines on a hit).

**In a spec whose effective tier is `standard`, compare only hits under a
required section.** The effective tier is per spec: `system_overrides.<stem>`
replaces the project tier for that spec in either direction (a `full` row makes
every section compared). Grep each such spec once for `^## ` to get its headings
and line numbers, and file every name hit under the nearest heading above it:
only hits under Detailed Behaviour, Data & Contracts, Non-Functional
Requirements and Acceptance Criteria — plus Overview, and Edge Cases & Failure
Modes when that spec's tier requires it (it sends email, calls a provider, moves
money, changes entitlements or runs asynchronously) — are compared. Any other
hit (User Value, Dependencies, the optional sections) raises no finding and is
not logged; list each one that states a value (name, spec, section) on the
report's `Not checked at this tier` line.

### 3a: Entities

For each entity in entity_map, grep the specs for the name and compare:
owning context, tenant-scoped yes/no, retention, lifecycle states, identifiers.
A spec that says an entity is global where the registry says tenant-scoped is a
**CONFLICT** with security consequences — mark it `severity: security`.

### 3b: Plans, roles, permissions

For each plan, role and permission, compare: which entitlements a plan grants,
which permissions a role holds, which roles/plans a permission requires.
- Spec A: "admins can refund"; registry: `invoice.refund` → owner only. → **CONFLICT** (`severity: security`)
- Spec says a role or plan name the registry does not know (typo, rename, new
  plan) → **UNREGISTERED NAME**, listed separately.

### 3c: Quotas and constants

For each quota and constant, extract any number mentioned near the name and
compare value, **unit**, **period** and **hard/soft** behaviour:
- Different number, different unit (GB vs GiB, per month vs per day), different
  period, or a hard limit in one spec that is soft in another → **CONFLICT**.
- A number in a spec with no registry entry that looks like a limit or timeout
  ("up to 5 projects", "expires after 7 days") → **UNREGISTERED CONSTANT**
  candidate (Phase 6 offers to register it if it appears in two or more specs).

### 3d: Events

For each event, compare producer context, payload fields and consumers across the
specs that emit or subscribe to it. Different payload fields, or two specs that
both claim to emit it, → **CONFLICT**. A consumer spec for an event nobody emits
→ **ORPHAN EVENT**.

### 3e: Domain map alignment

Read `design/specs/domain-map.md` (the feature table is small). For each
in-scope spec:
- the feature appears in the domain map, with this spec as its `Spec`;
- the bounded context named in the spec matches the map's `Context`;
- every dependency the spec lists appears in the map's `Depends On`, and the
  reverse (a map dependency the spec never mentions is a **NOTE**);
- the map's `Owns` column does not give the same data to two contexts.

Mismatches are **CONFLICT** (context or ownership) or **NOTE** (dependency not
mentioned). If the domain map does not exist, this step is **not run** — the
report says "domain map absent — Phase 3e not run", never a silent skip.

---

## Phase 4: Deep Investigation (Conflicts Only)

For each conflict found in Phase 3, do a targeted section read of the
conflicting spec to get precise context:

```
Read path="design/specs/[conflicting_spec].md"
```
(Or use Grep with wider context if the file is large.)

Confirm the conflict with full context. Determine:
1. **Which spec is correct?** Check the `source:` field in the registry — the
   source spec is the authoritative owner. Any other spec that contradicts it is
   the one that needs updating. A pricing/plan value is authoritative only in
   the pricing model: if the conflict is about a plan's quota, the pricing model
   wins over both specs.
2. **Is the registry itself out of date?** If the source spec was updated after
   the registry entry was written (check git log), the registry may be stale.
3. **Is this a genuine product change?** If the conflict represents an
   intentional decision, the resolution is: update the source spec, update the
   registry, then fix all other specs (`/propagate-spec-change` for the cascade
   into ADRs, stories and contracts).

For each conflict, classify:
- **CONFLICT** — same named entry with different values in different specs. Must
  resolve before architecture begins. Tag `severity: security` when it concerns
  tenant scoping, roles or permissions; `severity: billing` for plans and quotas.
- **STALE REGISTRY** — source spec value changed but registry not updated.
  Registry needs updating; other specs may be correct already.
- **UNVERIFIABLE** — entry mentioned but no comparable attribute stated. Not a
  conflict; just noting the reference.

---

## Phase 5: Output Report

```
## Consistency Check Report
Date: [date]
Registry entries checked: [N entities, N plans, N roles, N permissions, N quotas, N events, N constants]
Specs scanned: [N] ([list names])
Domain map: [checked | absent — Phase 3e not run]
Scope: [all spec sections | required sections only — workflow: standard | per spec — name each spec whose effective tier differs, and its tier]
Not checked at this tier: [each value stated outside the required sections (name, spec, section) — or "none"; omit when every spec is at `full`]
Skipped: [every kind, phase or spec that did not run, with the reason — or "none"]

---

### Conflicts Found (must resolve before architecture)

CONFLICT [severity] [Entry Name]
   Registry (source: [spec]): [attribute] = [value]
   Conflict in [other_spec].md (line N): [attribute] = [different_value]
   -> Resolution needed: [which doc to change and to what]

---

### Stale Registry Entries (registry behind the spec)

STALE [Entry Name]
   Registry says: [value] (written [date])
   Source spec now says: [new value]
   -> Update registry entry to match source spec, then check referenced_by docs.

---

### Unregistered names / orphan events (informational, may need registering)

### Unverifiable References (no conflict, informational)

NOTE [spec].md mentions [entry] but states no comparable attributes.

---

### Clean Entries (no issues found)

[N] registry entries verified across all specs with no conflicts.

---

Verdict: PASS | STALE REGISTRY | CONFLICTS FOUND | NOT ASSESSED
```

**Verdict** (printed at the end of Phase 5; Phase 6 adds a separate *closing
status* — `COMPLETE` or `BLOCKED` — for what the writes achieved, and never
replaces this verdict):
- **CONFLICTS FOUND** — one or more conflicts detected. List resolution steps.
  Outranks NOT ASSESSED: a known problem is more actionable than an unknown.
- **STALE REGISTRY** — no CONFLICT, but at least one registry entry is behind its
  source spec (and nothing else is wrong). Outranks NOT ASSESSED and PASS, ranks
  below CONFLICTS FOUND; Phase 6 offers the correction.
- **NOT ASSESSED** — nothing was compared (the entity registry is empty or the
  named entry is not in it — Phase 1; or no specs were in scope — Phase 2), **or**
  part of the scope could not be compared (a spec could not be read, the domain
  map was absent). Say which. A run that skipped part of its scope cannot be PASS.
- **PASS** — no conflicts, nothing skipped. Registry, domain map and specs agree
  on all checked values, across at least one spec.

---

## Phase 6: Registry Corrections

**Re-read before you write.** Phase 1 read the registry before the scans, and
another skill or session may have changed it since. Before each Edit, read the
current `design/registry/entities.yaml`, find the entry in its section, and
anchor the Edit on the entry's current text, never on what Phase 1 saw. Append a
new entry after the last existing entry of its section.

If stale registry entries were found, ask:
> "May I update `design/registry/entities.yaml` to fix the [N] stale entries?"

For each stale entry:
- Update the `value` / attribute field
- Set `revised:` to today's date
- Add a YAML comment with the old value: `# was: [old_value] before [date]`

If unregistered names or constants were found in specs, ask:
> "Found [N] plans/roles/quotas/events mentioned in specs that aren't in the
> registry yet. May I add them to `design/registry/entities.yaml`?"

Only add entries that appear in more than one spec (true cross-feature facts).

**Never delete registry entries.** Set `status: deprecated` if an entry is removed
from all specs.

Closing status, printed after the Phase 5 verdict (restate that verdict in the same line):
- Writes done (or none needed) and no conflicts remain: **COMPLETE** — consistency check finished.
- Conflicts remain unresolved: **BLOCKED** — [N] conflicts need manual resolution before architecture begins.
- The user declined a registry or failure-log write: **BLOCKED — write declined by user**; nothing is reported as COMPLETE, and the stale entries or unlogged conflicts are named.

### 6b: Append to the Failure Log

If any CONFLICT entries were found (regardless of whether they were resolved),
ask: "May I append [N] entries to `docs/consistency-failures.md` (creating it if
absent)?" On yes, append an entry for each conflict; on no, say the conflicts
were not logged.

```markdown
### [YYYY-MM-DD] — /consistency-check — CONFLICT
**Domain**: [bounded context(s) involved]
**Documents involved**: [source spec] vs [conflicting spec]
**What happened**: [specific conflict — entry name, attribute, differing values]
**Resolution**: [how it was fixed, or "Unresolved — manual action needed"]
**Pattern**: [generalised lesson, e.g. "Seat limits restated in the invitations
spec instead of referencing the pricing model — always cite the entitlement key"]
```

If `docs/consistency-failures.md` does not exist, create it with this header before appending:

```markdown
# Consistency Failure Log

<!-- Auto-maintained by /consistency-check. Do not edit manually. -->
<!-- One `###` entry per detected conflict, in chronological order, in the format above. -->
```

Then append the new conflict entries. Never skip logging on your own — a missing file is not a reason to lose conflict history; only the user's "no" is.

---

## Phase 7: Session State and Closing

Silently append to `production/session-state/active.md` (create the file if it does not exist):

```
<!-- CONSISTENCY-CHECK: [date] | Specs checked: [N] | Conflicts found: [N] | Log: docs/consistency-failures.md -->
```

> **Point at `docs/consistency-failures.md` — the file Phase 6 actually appends
> to.** A breadcrumb is a pointer left for a future session to follow. One that
> names a file nothing writes sends that session looking for conflict history it
> will never find. Never invent a report filename here.

**Checkpoint.** In the same step, update the CHECKPOINT region of
`production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`
(this step already owns the file, so no second pass): Current task
`/consistency-check <scope> — <PASS | CONFLICTS FOUND | STALE REGISTRY | NOT
ASSESSED>`, Next step = the first matching line under Recovery / Reference (fix
the flagged specs, then re-run), plus Blocked on / Files in progress (the
registry and `docs/consistency-failures.md`, or `none`) / Open questions; append
the Notes line. Leave the `Flow` line and any `/studio` or team block alone.

Then close with an `AskUserQuestion` widget:

- **Prompt**: "Consistency check complete — [N] conflicts found. What next?"
- **Options**:
  - `[A] Fix the highest-priority conflict now`
  - `[B] Run /spec-review on the most conflicted spec`
  - `[C] Stop here`

In collaborative and guided modes, never end the skill with plain text — always
close with this widget. In autonomous mode, print the findings and recommended
next step, then record via `log_decision` (no widget).

---

## Recovery / Reference

- **If PASS**: Run `/review-all-specs` for the holistic review, or
  `/create-architecture` if all MVP specs are complete.
- **If CONFLICTS FOUND**: Fix the flagged specs, then re-run
  `/consistency-check` to confirm resolution. Plan/quota conflicts also go to
  `pricing-billing-designer` and then `/pricing-check`.
- **If STALE REGISTRY**: Update the registry (Phase 6), then re-run to verify.
- **If NOT ASSESSED**: supply the missing input (write specs, register entries,
  run `/map-domains`) — it needs work done or access granted, not a re-run.
- Run `/consistency-check` after writing each new spec to catch issues early,
  not at architecture time.
