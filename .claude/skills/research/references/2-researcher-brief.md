# /research - Phase 3: The Researcher Brief

> Phase 3 of `SKILL.md`. Fill only the `{...}` slots. Add nothing else: no view
> on the answer, no preferred option, no opinion on a source. A sentence of your
> own is where a pre-decided conclusion gets in.

## Brief template (note mode)

```text
Write a research note for /research.

Charter: read .claude/docs/research-protocol.md and .claude/rules/research-docs.md
first; the note follows .claude/docs/templates/research-note.md exactly (nine
sections, same headings). Do not invent a parallel format.

Destination (create this one new file, plus tier-E evidence under
docs/research/evidence/<slug>/ if you run anything; nothing else): {docs/research/<slug>.md,
or the temporary section path when sub-questions run in parallel}
Mode: {new | re-verify | extend}   Existing note to build on: {path | none}

Decision this informs: {one paragraph from Phase 1}
Feature / story: {design/specs/<slug>.md | story ID | none}
Distribution scope: {hosted | hosted + self-hosted}   Tenancy: {tenancy.model | unset}
Triggers: {new feature | new integration/provider | new library or major bump | auth | billing | licensing | crypto | file upload | PII}

Pinned versions already read (use these as the Versions table baseline; verify
only what the question needs):
{component - pins.yaml value - stack-reference file - Last verified date; one per line}
Stale references (older than their pin): {list | none}
Layers with NO stack reference: {list | none} - write NOT SOURCEABLE, do not fill.
Licence decisions in force (docs/ROADMAP.md L1-L4, T1): {the ones that apply}
Existing notes to reuse by link: {paths | none}
Known constraints and ruled-out options: {list | none}

Rules you must follow:
- Source tiers 1-5 per the protocol; cite the highest tier available. Tier 5 is a
  lead, never the basis for a decision.
- Every finding: claim, link actually fetched, tier. Quote at most one short line
  per source.
- A test or query you run yourself is tier E: save the script and its output
  under docs/research/evidence/<slug>/ and cite that path with the command,
  versions and date. It never overrides tier 1-2. A test you could not run is
  "PENDING - <spike id>", not a finding.
- Unsourceable is a valid finding: "NOT SOURCEABLE - <what was searched>".
  Never fill a version, flag, API name, regulation or requirement ID from memory.
- ASVS 5.0.0 / MASVS 2.1.0 / API Top 10 2023 requirement IDs: look them up in
  the official document and cite the URL fetched, or write NOT SOURCEABLE.
- Security advisories: search GHSA and OSV for each chosen version and record the
  date searched, or write that the search could not run.
- At least two options for any non-trivial choice, each with cost, risk,
  performance and operability (including the self-hosted bundle). An option that
  breaks a licence decision L1-L4 is listed as "licence-blocked", not dropped.
- Never paste secrets, customer data or internal URLs into a search query or the
  note.
- Recommend, do not decide: the Decision section holds your recommendation marked
  "Recommended - pending user decision"; the caller records the final choice.
- Fill Security (6), Performance & Caching (7) and Observability (8) from the
  standards (.claude/docs/security-baseline.md, caching-standard.md,
  observability-standard.md); name which spans, metrics and log events the feature
  must emit and which cache decision it will need.
- Open Questions: each with an owner and what it blocks.
- Set the note's `Status:` to `Draft`. Only the caller sets `Complete`, after its
  checks and the user's approved write.
- You have a limited turn budget. Create the destination file within your first
  three turns (all nine headings, the Question, the pinned Versions baseline),
  then add each finding to it as you fetch it - never hold findings for one
  final write. When about five turns remain, stop fetching: mark every unread
  item "NOT SOURCEABLE - turn budget, not reached", and complete Options,
  Decision and Open questions from what the file holds.

Return (text, under 200 words): the written path; the count of findings by tier;
the list of NOT SOURCEABLE items; the licence-blocked options; the open
questions that block implementation; anything you could not do and why. If you
could not write the file, say so - a reply without the file is a failed phase.
```

## Return contract

| Item | Check |
|---|---|
| The named file exists | `Read` it; a reply with no file is a FAILED PHASE (error-recovery Trigger 0) |
| The summary matches the file | counts and the NOT SOURCEABLE list agree with the note |
| Nothing was written elsewhere | `git status` / `Glob` for stray files under `docs/` (tier-E evidence under `docs/research/evidence/<slug>/` is expected) |

When sub-questions ran in parallel, merge the section files into the single
destination note by section (Versions and Findings are concatenated with unique
`F` numbers; Options, Decision and the rest are written once by you from the
sections returned), then delete the temporary files **only after** the user
approved the merged note.

## Brief template (`refresh` mode)

See `4-refresh.md`; the refresh brief is separate because it forbids the
researcher from editing any file.
