# /create-stories — Step 2: Load Everything for This Epic

> Part of `/create-stories`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 2. Load Everything for This Epic

> **`minimal` tier — synthesize the epic from the brief** (Option A). At
> `minimal` there is no `/create-epics` step and usually no `EPIC.md`. Instead:
> 0. **No `design/product-brief.md`?** Stop: "There is no brief to build stories
>    from yet — run `/brainstorm` first; it writes the one-page brief."
>    **An `EPIC.md` already at `production/epics/<slug>/`** — the named epic, or
>    the brief-title slug (`/create-epics` run anyway, or an earlier run of this
>    skill) — is the epic: use its scope, still traced to the brief, and never
>    rewrite it; Step 6 only appends its Stories table, and the Step 5 ask says
>    *update* `EPIC.md`.
>    **Stories already in `production/epics/<slug>/`?** This is a return visit —
>    `/help` sends a finished build order back here. Never rewrite an existing
>    `story-*.md` or the `EPIC.md`: read them, add stories only for brief items
>    they do not yet cover (or the new ones the user names), and number on from
>    the highest existing `story-NNN`. The one change `EPIC.md` gets is Step 6's:
>    a row per new story appended to its Stories table — existing rows and the
>    rest of the file stay as they are.
> 1. Read `design/product-brief.md` in full (it is one page).
> 2. Synthesize an implicit epic (first run only — a return visit keeps the
>    existing one): draft a lightweight
>    `production/epics/<slug>/EPIC.md`, where `<slug>` is the brief's slugified
>    working title (`mvp` if untitled) — goal = the brief's one-sentence pitch,
>    scope = its MVP feature list, ordering = its **Build order**. Keep it terse;
>    this is the container `/dev-story` and `/sprint-status` expect. It is written
>    in Step 6, with the stories, after the Step 5 ask names it — never before.
> 3. Generate **one coarse story per MVP feature per code root** (Step 3+), in
>    Build-order sequence, each traced to the brief (not a spec/TR-ID). Leave
>    stories unblocked on ADR grounds — none exist at this tier. The research note
>    (`docs/research/<feature>.md`) and the eight DoD gates still apply at this tier:
>    the story's evidence table states them.
> Skip the spec, control-manifest, TR-registry, and ADR reads below (none exist at
> `minimal`), then continue to Step 3 with the synthesized epic.

For `standard`/`full` (a `/create-epics` epic exists), read in full (these are small):

- `production/epics/[epic-slug]/EPIC.md` — epic overview, governing ADRs, spec requirements table, code roots, owner agents, threat-model and contract table
- The epic's spec(s) (`design/specs/[filename].md`) — at `full` read all 8 sections; at `standard` the 5 required sections (+ conditional Edge Cases); at `minimal` the spec may not exist — work from the epic brief + acceptance criteria. Always prioritise Acceptance Criteria, Data & Contracts, Edge Cases & Failure Modes and Non-Functional Requirements where present. For a cross-cutting epic derived from `architecture.md`, read the named section instead.
- `docs/architecture/control-manifest.md` — grep only this epic's sections (`Grep pattern="^## (Global Rules|Backend Rules|Web Rules|Mobile Rules|Data Rules|Contract Rules|Deploy Rules|Bounded Context Rules)" path="docs/architecture/control-manifest.md" output_mode="content" -A 40`, narrowed to the layers and context the epic's code roots touch) plus the header Manifest Version date, not a full read of every section
- `docs/architecture/tr-registry.yaml` — grep only this feature's entries (`Grep pattern="feature: <slug>\s*$" path="docs/architecture/tr-registry.yaml" output_mode="content" -B1 -A5`, or `id: TR-<slug>-[0-9]`; the anchors keep `billing` from matching `billing-reports`), not the whole cross-feature registry
- `docs/research/<feature>.md` — Glob only, to record present or MISSING in each story (gate 1). Read it only when a story's acceptance criteria need its findings; the story links it, it does not copy it.
- `docs/architecture/threat-models/<feature>.md` — Glob only, same purpose, for sensitive features
- `contracts/` — Glob the files the epic's boundaries name, to decide in Step 4 whether a Contract story is needed (new or changed boundary) or the contract already exists unchanged
- `docs/architecture/perf-budgets.md` — grep the rows for this epic's hot paths (if the file exists) so Performance stories name the budget

**Load each governing ADR by section — never with an unbounded full read.** A
substantial ADR exceeds the 25k-token `Read` cap, and a capped read's only
recovery is paging through the remainder — the most expensive possible way to
read a file. Per ADR:

1. **Map the headings** (cheap — line numbers only):
   ```
   Grep pattern="^## |^### Implementation Guidelines" path="docs/architecture/[adr-file].md" output_mode="content" -n
   ```
2. **Bounded-read exactly the sections this skill consumes**, using the line
   numbers from the map to set `Read(offset, limit)` spans that end where the
   next section begins:
   - `## Summary` and `## Decision` (including its `### Implementation
     Guidelines` subsection) — these feed the story's ADR Decision Summary
     and Implementation Notes.
   - `## Stack Compatibility` — feeds the story's Stack, Risk and Stack Notes
     fields. (Stack Notes is a *story* field derived from this section — it is
     not an ADR section name; do not search for one.)
   - `## Cross-Cutting Impact` — feeds the tenancy, caching, observability and
     self-hosted lines of the story's Definition of Done table.
3. **Capture the `## Status` and the `## Last Verified` date** in one call:
   ```
   Grep pattern="^## (Status|Last Verified|Date)" path="docs/architecture/[adr-file].md" output_mode="content" -A 2
   ```
   The Status (Accepted / Proposed / …) is what Step 4 decides `Ready` vs
   `Blocked` on — never assume it. For the version, use `Last Verified`,
   falling back to `Date`, then to `unversioned` if both are absent. This becomes the story's `ADR Version` stamp — `/dev-story`
   uses it to decide whether it can trust this story's distilled summary
   instead of re-opening the ADR.

Skip Context, Alternatives Considered, Consequences, Risks, and any
Amendments Log unless a section you loaded explicitly cross-references one of
their entries — then take only the referenced entry with one more bounded
read. If the heading map comes back empty (a nonstandard ADR predating the
template), fall back to one full `Read` — and if that read truncates at the
cap, do **not** page through the remainder; grep for the story-relevant
content directly and flag the ADR for
`/architecture-decision retrofit [file]`.

**ADR existence validation** (tier-gated — resolved in Step 1): After reading the governing ADRs list from the epic, confirm each referenced ADR file exists on disk.

- **`full`** — if **any** referenced ADR file cannot be found, **stop immediately** before decomposing any story.
- **`standard`** — stop only if a **critical ADR** (tenancy, identity/auth, data store, messaging, API style, deployment topology, licensing — Foundation layer) is missing; for a missing non-critical ADR, **warn and continue** (the story embeds the ADR reference and is set `Status: Blocked` until the ADR exists).
- **`minimal`** — no ADR requirement; do **not** stop. Embed any ADR references that do exist; otherwise decompose against the brief + acceptance criteria and leave stories unblocked on ADR grounds.

When stopping (full / standard-critical):

> "Epic references [ADR-NNNN: title] but `docs/architecture/[adr-file].md` was not found.
> Check the filename in the epic's Governing ADRs list, or run `/architecture-decision`
> to create it. Cannot create stories until all referenced ADR files are present."

At `full`, do not proceed to Step 3 until all referenced ADR files are confirmed present.

Report: "Loaded epic [name], spec [filename], [N] governing ADRs [ADR status], [manifest status], research note [present | MISSING], threat models [present | MISSING | not required]." State the **actual** situation for the resolved tier — e.g. "all confirmed present, control manifest v[date]" at full; "M present, K missing non-critical (embedded + Blocked)" at standard; "no ADRs / manifest required" at minimal. Do not assert "all confirmed present" if any referenced ADR was missing, or name a manifest version when none exists.

---
