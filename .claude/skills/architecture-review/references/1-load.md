# /architecture-review — Phase 1: Load Everything

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 1: Load Everything

**In this file:**

- Phase 1a — L0: Summary Scan (fast, low tokens)
- Phase 1b — L1/L2: Targeted Section Load
- Feature Specs
- Architecture Documents
- Stack Reference
- Project Standards

### Phase 1a — L0: Summary Scan (fast, low tokens)

**Freshness check before any scan.** Locate the latest prior report — Glob
`docs/architecture/architecture-review-*.md` and take the newest — then:

```
Bash: bash .claude/scripts/review-receipts.sh check "[latest-report]" docs/architecture/adr-*.md design/specs/*.md
```

- **Any `UNRESOLVED`** — check this FIRST; it disqualifies every option
  below. One of the two globs matched no file, so that whole document class
  was never examined and the comparison covered less than it appears to.
  Say which pattern came back unresolved and stop: an ADR or spec directory
  that is empty, renamed or misspelled is a finding about the project, not a
  reason to stand on a prior report. Never read a set of `UNCHANGED` lines as
  "everything is current" while an `UNRESOLVED` line is present — the set
  compared was not the set requested.
- **Everything `UNCHANGED`** (and no `UNRESOLVED`) — nothing this review
  reads has changed since that report; re-running reproduces it. Surface the
  prior report's date and verdict and offer via `AskUserQuestion`: `[A] Stand
  on the prior report (Recommended)` / `[B] Re-run the full review anyway` —
  `guided` proceeds with [A] and notes it; `autonomous` logs via
  `log_decision` and stands on the prior report. The stack reference and
  `pins.yaml` are not in the receipt set: if either changed since the report
  (compare its date to their last change), choose [B] — a pin bump alone can
  invalidate an ADR.
- **Some `CHANGED`/`NEW`** — name them, then scope instead of re-running
  everything: recommend `/architecture-review single-spec [path]` for just the
  changed features. A full re-run stays available on request, and structural
  changes (a `NEW` ADR, a deleted file) warrant one.
- **`RECEIPT: NONE`** — no prior report, or one written before receipts
  existed. Proceed with the full review; this run's report will carry the
  first stamps.

Before reading any full document, use Grep to extract `## Summary` sections
from all ADRs and the `## Overview` of specs:

```
Grep pattern="## Summary" glob="docs/architecture/adr-*.md" output_mode="content" -A 3
Grep pattern="^## Overview" glob="design/specs/*.md" output_mode="content" -A 4
```

**Fail open on a missing Summary.** Establish the denominator: glob
`design/specs/*.md` (excluding `domain-map.md`) and count **N**. A scan matching
fewer than N means those specs lack the section — never treat an absent Summary
as a feature out of scope. A zero-match scan means "no spec carries it yet", not
"nothing to review": full-read the unmatched set.

For `single-spec [path]` mode: use the target spec's overview to identify which
ADRs reference the same feature or bounded context (Grep ADRs for the feature
name and TR-IDs), then load only those ADRs' sections per Phase 1b. Skip
unrelated specs entirely.

For `stack` mode: load ADR sections only — specs are not needed for stack checks.
In practice this is the `## Stack Compatibility` scan alone, plus `deploy/self-hosted/`
if it exists (for the licence check).

For `coverage` or `full` mode: proceed to Phase 1b for the full in-scope set.
**This is a section load, not a full-file load** — see below for why, and for the
narrow cases that still justify escalating to a whole document.

### Phase 1b — L1/L2: Targeted Section Load

Load the sections the later phases actually consume — **not whole files**. This
skill reads the two largest document sets in the project (every spec *and* every
ADR); at realistic sizes a full load of both exhausts the context window before
Phase 2 starts, and most of what it loads is narrative this skill never uses.

**Establish the denominator first.** Glob `design/specs/*.md` and count
**N_spec**; glob `docs/architecture/adr-*.md` and count **N_adr**. Report both. A
section scan matching fewer than the denominator means those documents lack the
section — **never treat an absent section as an absent document.** The scan
narrows the *read* set; it never shrinks the *in-scope* set.

### Feature Specs

Phase 2 extracts *technical requirements* — entities and ownership, tenancy and
permissions, performance, cross-context communication, providers, persistence,
async work, security-sensitive areas, distribution constraints. Those live in a
known set of sections; Overview and User Value are narrative and yield little.

```
Grep pattern="^## (Detailed Behaviour|Data & Contracts|Edge Cases|Dependencies|Non-Functional|Acceptance Criteria)" glob="design/specs/*.md" output_mode="content" -A 40
```

Full-read a single spec only when a scanned section cross-references material
outside itself, or when a spec matched zero sections (it predates the template —
read it whole and say so).

- `design/specs/domain-map.md` — the authoritative list of bounded contexts and features; read whole (small, and it is an index)
- At `minimal`/no specs: `design/product-brief.md` for the requirement source

### Architecture Documents

Phases 3–5 need the traceability table, the decision itself, stack claims, the
cross-cutting table and the dependency edges — not Context, Alternatives,
Migration Plan or Validation Criteria, which explain *why* a decision was made.

```
Grep pattern="^## (Status|Decision|Spec Requirements Addressed|Stack Compatibility|ADR Dependencies|Cross-Cutting Impact|Performance Implications)" glob="docs/architecture/adr-*.md" output_mode="content" -A 30
```

Interpret against **N_adr**, and distinguish the two zero-match cases — they are
not the same finding:

| Result | Meaning | Action |
|---|---|---|
| N_adr matches | Normal. | Proceed on the scanned sections. |
| Some ADRs match, some do not | Those ADRs are missing sections. | Record each as a **structural gap** in the Phase 7 report — a missing `## Spec Requirements Addressed` is itself a traceability finding. |
| **0 matches, N_adr > 0** | **Malformed ADRs**, not "no architecture". | "[N_adr] ADRs found, none carries a scannable section — run `/architecture-decision retrofit [file]` on each." Do **not** report zero coverage; that would read as a design failure when it is a format failure. |

Escalate to a full read of one ADR only when judging a conflict needs its
reasoning (Phase 4) — that is a per-ADR decision, not a blanket load.

- `docs/architecture/architecture.md` if it exists
- `docs/architecture/threat-models/*.md` — list only (Glob) plus the sensitive-area header of each, for the security coverage table
- `docs/registry/architecture.yaml` if it exists — the binding stances Phase 4 checks ADRs against

### Stack Reference

- `docs/stack-reference/pins.yaml`
- For each layer an ADR names: `docs/stack-reference/<layer>/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`
- **Only the `best-practices.md` sections the in-scope ADRs actually name** — take the union of
  each ADR's `References Consulted` and `Post-Cutoff APIs Used` fields (already
  captured by the `## Stack Compatibility` scan above) and read those files.
  If no ADR names any, read none and note it: Phase 5 cannot cross-check stack
  claims that were never made.
- If `distribution.model` is `hybrid` or `self-hosted`: `.claude/rules/deploy.md` and, if present, the compose files and image references under `deploy/self-hosted/` for the licence check.

A layer that appears in an ADR but has no directory under `docs/stack-reference/`
is `NOT SOURCEABLE — <layer> is not covered by docs/stack-reference/`; carry it
into Phase 5 and the verdict. Never audit it against training data.

### Project Standards
- `project.yaml` — `stack`, `tenancy`, `deploy`, `distribution`, `core`, `performance.enforce`

Report a count: "Loaded [N] specs, [M] ADRs, stack: [layers + pinned versions]."

**Also read `docs/consistency-failures.md`** if it exists. Extract entries with
Domain matching the contexts under review (Architecture, Stack, or any spec domain
being covered). Surface recurring patterns as a "Known conflict-prone areas" note
at the top of the Phase 4 conflict detection output.

---
