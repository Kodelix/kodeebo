# /review-all-specs — Phase 1: Load Everything

> Part of `/review-all-specs`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 1: Load Everything

**In this file:**

- Phase 1a — L0: Summary Scan (fast, low tokens)
- Phase 1b — Registry Pre-Load (fast baseline)
- Phase 1c — L1/L2: Section Load and structure check

### Phase 1a — L0: Summary Scan (fast, low tokens)

Before reading any full document, use Grep to extract `## Summary` sections
from all spec files:

```
Grep pattern="## Summary" glob="design/specs/*.md" output_mode="content" -A 5
```

**Fail open on a missing Summary.** Establish the denominator: glob
`design/specs/*.md` (excluding `domain-map.md`, `spec-cross-review-*.md` and
`README.md`) and count **N**. A scan matching fewer than N means those specs
predate `## Summary` — never treat an absent Summary as a feature out of scope.
A zero-match scan means "no spec carries a Summary yet", not "nothing to review".
This review is holistic and loads its in-scope specs regardless (see Phase 1c);
the Summary scan only builds the manifest and narrows `since-last-review`, it
never shrinks the review set.

Display a manifest to the user:
```
Found [N] specs. Summaries:
  • team-invitations.md — [summary text]
  • billing.md — [summary text]
  ...
```

For `since-last-review` mode, compute the scope deterministically instead of
reasoning through git history:

```
Bash: bash .claude/scripts/review-scope.sh
```

It prints `PRIOR_REVIEW:`, a `CHANGED:` list, and a `DEPS ...:` list of each
changed spec's declared dependencies. Use those lists as the scope — the
dependency lines are already the "Key deps" expansion, so no second pass is
needed. If `PRIOR_REVIEW: NONE`, a full review is required; fall back to `full`
mode. If the script cannot run, say so and fall back to `full` — a scope that
could not be computed is never treated as "nothing changed".

Show the user which specs are in scope based on summaries before doing any full
reads. Only proceed to L1 for the `CHANGED` set plus the specs named on the
`DEPS` lines.

### Phase 1b — Registry Pre-Load (fast baseline)

Before full-reading any spec, check for the entity registry:

```
Read path="design/registry/entities.yaml"
```

If the registry exists and has entries, use it as a **pre-built conflict
baseline**: known entities, entitlement keys, quotas, events and permissions with
their owning contexts and source specs. In Phase 2, grep specs for registered
names first — this is faster than reading all specs in full before knowing
what to look for.

If the registry is empty or absent: proceed without it. Note in the report:
"Entity registry is empty — consistency checks rely on full spec reads only.
Run `/consistency-check` after this review to populate the registry."

### Phase 1c — L1/L2: Section Load and structure check

Read whole (small, and every part is used):

1. `design/product-brief.md` — pitch, ICP, pricing model, distribution, MVP list
2. `design/product-principles.md` if it exists — principles and anti-principles
3. `design/specs/domain-map.md` — authoritative context and feature list, layers, dependencies, ownership table, status
4. The pricing model (`design/specs/pricing-model.md` — the canonical path; else `Glob design/**/pricing-model*.md` and say the hit is at a non-canonical path; or the document the brief links) if it exists — plans, entitlement keys, quota names
5. `project.yaml` keys `tenancy.model`, `distribution.model`, `core.track`, `core.version` (via the resolved config; "not configured" if absent)

Then **run the structure check once for every in-scope spec** so section presence
is observed, not inferred:

```
Bash: bash .claude/scripts/spec-structure-check.sh design/specs/a.md design/specs/b.md ...
```

(Or with no arguments for every spec.) It reports presence only; apply the tier
yourself. If it cannot run, say so and treat section presence as `not checked`
for every spec rather than assuming it.

Then, for **every in-scope feature spec**, load the sections this review actually
consumes — **not the whole file**:

```
Grep pattern="^## ([0-9]+\. )?(Dependencies|Detailed (Behaviou?r|Rules)|Data (&|and) Contracts|Non-Functional|User Value|Acceptance Criteria|Cross-References)" glob="design/specs/*.md" output_mode="content" -A 60
```

That list is the union the Parallel Execution contract enumerates: Phase 2 needs
Dependencies, Detailed Behaviour (Permissions per Role, States), Data & Contracts,
Non-Functional Requirements, Acceptance Criteria and Cross-References; Phase 3
needs User Value and the plan/pricing impact. Edge Cases feed no checklist item
here (`/spec-review` owns per-spec completeness) except Phase 4 scenarios, which
read them on demand.

Accept the heading aliases `spec-structure-check.sh` accepts (`Detailed Rules` for
Detailed Behaviour, `Non-Functional` for Non-Functional Requirements).

**Escalate to a full read of one spec** when a scanned section cross-references
material outside itself, or when a spec matched **zero** sections — that spec
predates the template, and a zero-match there means "unstructured", not "empty".
Never let a zero-match silently drop a feature: the scan narrows the *read*, it
never shrinks the *review set*.

Report: "Loaded [N] feature specs covering [M] bounded contexts. Principles: [list, or none defined]. Pricing model: [found / not found]. Tenancy model: [value / not configured]. Core pin: [value / not configured]."

If fewer than 2 feature specs exist (count the files present; an empty one is handled under NOT ASSESSED in Phase 5, not here), stop with the verdict
**NOT ASSESSED** — nothing was compared, so this is neither PASS nor FAIL:
> "NOT ASSESSED — cross-spec review requires at least 2 feature specs ([N] found).
> Write more specs first, then re-run `/review-all-specs`."

Write no report in this case (there is nothing to record beyond the verdict) and
do not offer a downstream skill that needs a PASS.

---
