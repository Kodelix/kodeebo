# /design-spec — Phase 1: Parse Arguments & Validate

> Part of `/design-spec`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 1. Parse Arguments & Validate

**In this file:**

- `docs.density`
- No feature name given: the domain map picks the next one
- Detect retrofit mode
- `workflow` for this feature, and `## Summary` at every tier

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`docs.density`** — it controls per-section *depth*, where `workflow`
controls which sections exist. `modes.rigor` sets both together; set
`docs.density` explicitly to vary depth alone: `terse` (the default, via `rigor: minimal`) = bullet points, 2–5 lines per section,
skip rationale and preambles; `balanced` = paragraphs with light rationale
(`rigor: standard`); `thorough` = full prose with rationale, examples, and alternatives
considered. Apply it to every section you author. Mandated structures (the
permissions matrix, the Formulas variable table, Given-When-Then acceptance
criteria, the NFR sub-headings) are correctness requirements at every
density — `terse` trims the surrounding prose, never the required structure itself.

A feature name or retrofit path is **required**. If missing:

1. Check if `design/specs/domain-map.md` exists.
2. If it exists: read it, find the highest-priority feature with status "Not Started" or equivalent, and use `AskUserQuestion`:
   - Prompt: "The next feature in your specification order is **[feature-name]** ([priority] | [layer]). Start specifying it?"
   - Options: `[A] Yes — specify [feature-name]` / `[B] Pick a different feature` / `[C] Stop here`
   - If [A]: proceed with that feature name. If [B]: ask which feature to specify (plain text). If [C]: exit.
3. If no domain map exists, fail with:
   > "Usage: `/design-spec <feature-name>` — e.g., `/design-spec team-invitations`
   > Or to fill gaps in an existing spec: `/design-spec retrofit design/specs/[feature-name].md`
   > No domain map found. Run `/map-domains` first to map your contexts and get the specification order."

   At `minimal` with no domain map, a feature name given explicitly is accepted (see §2a).

**Detect retrofit mode:**
If the argument starts with `retrofit` or the argument is a file path to an
existing `.md` file in `design/specs/`, enter **retrofit mode**:

1. Read the existing spec file.
2. Identify which of the 8 **possible** sections are present (scan for section
   headings): Overview, User Value, Detailed Behaviour, Data & Contracts,
   Edge Cases & Failure Modes, Dependencies, Non-Functional Requirements,
   Acceptance Criteria. Run `bash .claude/scripts/spec-structure-check.sh <path>`
   for a deterministic presence list; if the script cannot run, say so and scan
   the headings yourself.
   **Which of them are *required* depends on the effective tier** (§1) — at
   `standard` only 5 are, plus Edge Cases & Failure Modes when the feature
   triggers it, and User Value and Dependencies are optional **by design**.
   Report an absent section as a gap only when the tier requires it; otherwise
   list it as available-to-add.
3. Identify which sections contain only placeholder text (`[To be designed]` or
   equivalent — blank, a single line, or obviously incomplete).
4. Present to the user before doing anything:
   ```
   ## Retrofit: [Feature Name]
   File: design/specs/[filename].md

   Sections already written (will not be touched):
   ✓ [section name]
   ✓ [section name]

   Missing or incomplete sections (will be authored):
   ✗ [section name] — missing
   ✗ [section name] — placeholder only
   ```
5. Ask: "Shall I fill the [N] missing sections? I will not modify any existing content."
6. If yes: proceed to **Phase 2 (Gather Context)** as normal, but in **Phase 3**
   skip creating the skeleton (file already exists) and in **Phase 4** skip
   sections that are already complete. Only run the section cycle for missing/
   incomplete sections.
7. **Never overwrite existing section content.** Use Edit tool to replace only
   `[To be designed]` placeholders or empty section bodies.

If NOT in retrofit mode, normalize the feature name to kebab-case for the
filename (e.g., "team invitations" becomes `team-invitations`). **The filename
stem is the feature key** used by `workflow_overrides.system_overrides` and by
story TR-IDs — do not rename it later.

**`workflow`** for this feature (per `.claude/docs/workflow-modes.md`) — use the
`system_overrides` row for this feature if the block lists one, else the project
value. (Do not report an unmatched override key here: before this skill's first
run for a feature, its key matches nothing by definition.)

The resolved tier determines which spec sections are **required** (applied in §4).
**`## Summary` is required at every tier and is not one of the 8** — §5-pre
authors it unconditionally, but it appears in none of the per-tier lists below,
and these lists are what other skills and gates apply. A spec checked against a
tier list alone would pass with no Summary, the one section `/review-all-specs`
and the tiered-loading readers depend on. Read every list below as
"`## Summary`, plus:".
- `full` — all 8 sections
- `standard` — Overview, Detailed Behaviour, Data & Contracts, Non-Functional
  Requirements, Acceptance Criteria (5 required); **Edge Cases & Failure Modes
  conditional** — required when the feature calls an external provider, moves
  money, changes entitlements, or runs asynchronously (a job, queue, webhook or
  scheduled task). **User Value and Dependencies optional.** The
  **Formulas and Rules** sub-block of Data & Contracts is required when the
  feature **defines numeric rules**: rates, proration, thresholds, quotas,
  costs, retention periods, or any value a pricing or limits pass would tune.
  **The `Category` in `domain-map.md` is a hint, not the test** — `Billing &
  Licensing` features almost always qualify, and a `Platform` or `Growth`
  feature that defines a numeric rule qualifies too. If Detailed Behaviour states
  a quantity that is not a fixed protocol constant, the Formulas sub-block is
  required.

  > **Do not gate this on a category token.** A rule of the form "required when
  > the category is billing" does not work: a rate limit in a `Platform`
  > feature or a trial length in a `Growth` feature carries the same obligation
  > and matches no such token.
- `minimal` — a spec is not required (the product brief and the research note
  replace it). If invoked voluntarily at minimal, author exactly the 5 standard
  sections (Overview, Detailed Behaviour, Data & Contracts, Non-Functional
  Requirements, Acceptance Criteria) — the conditional Edge Cases and Formulas
  rules do NOT re-apply at minimal — and tell the user the spec is optional at
  this workflow level.

`workflow_overrides.edge_cases: true` forces Edge Cases & Failure Modes required
at every tier; `workflow_overrides.tuning_knobs: true` forces the
**Configuration** subsection of Non-Functional Requirements (§4 Section G).

Retrofit mode is unaffected — it fills whatever sections are missing regardless
of tier.

---
