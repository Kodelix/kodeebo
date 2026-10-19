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
ID block (parallel parts only): findings {F n01-F n99}, spikes {S n0-S n9}; use no
ID outside it; cite IDs from other parts or notes with a prefix (e.g. "desktop-note F117").
Budget: {20} units. Each WebFetch, WebSearch or spike command you run (Bash) spends one
unit: runs take turns too. Write each finding into the file before the next fetch or
run. Refresh provisional sections 4-9 every 8 units; when the budget is spent, stop
fetching and running and finalise sections 4-9 from the file.

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
  versions and date. Never delete a script or output you ran, even a failed or
  wrong run: label it (`wrong test — see F<n>`) and keep it; a claim whose
  evidence is gone is an unrecorded observation, not a finding. It never overrides tier 1-2. A test you could not run is
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
- Never write outside the repository: no /tmp, no home or cache paths, not even
  for a scratch file. Scratch work goes under docs/research/evidence/<slug>/
  (label scratch files as such). Tool caches (Go module and build caches, Gradle,
  npm, pip) and downloaded toolchains go under production/session-state/cache/<slug>/
  (gitignored), never into evidence, and are deleted when the note is merged.
- Downloads: list the size before fetching anything (packages, toolchains,
  images, archives). If one download, or the run's total, would exceed 100 MB,
  do not fetch it: stop and return "needs approval: <what>, <size>" so the caller
  asks the user. The user's bandwidth is limited and paid.
- Implicit downloads count: a tool that fetches on its own (Go toolchain
  auto-switch, Gradle wrapper, Maven/Gradle dependency resolution, docker pull,
  npx/pnpm dlx, pip) is a download. Run such tools in no-download mode by default
  (GOTOOLCHAIN=local, GOFLAGS=-mod=mod with GOPROXY=off once modules are present,
  gradle --offline, docker run --pull=never) and list what they would fetch
  before switching it off. Relocating a cache can trigger a fresh fetch: check
  first.
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
- You cannot see your remaining turns; the budget above is your only stop rule.
  Create the destination file within your first three turns (all nine headings,
  the Question, the pinned Versions baseline), then add each finding to it as you
  fetch or run it - never hold findings for one final write. When the budget is
  spent, mark every unread item "NOT SOURCEABLE - budget, not reached" and every
  unrun spike "PENDING - <spike id>", and complete sections 4-9 from what the
  file holds.

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
| Sections 4-9 have content | count the non-heading lines under each of sections 4-9; a section that holds only a placeholder fails, whatever word the placeholder uses. Never check by searching one marker word |
| Nothing was written elsewhere | `git status` / `Glob` for stray files under `docs/` (tier-E evidence under `docs/research/evidence/<slug>/` is expected) |

When sub-questions ran in parallel, merge the section files into the single
destination note **with the Write tool** (a script that builds the note was
declined in two products; do not offer one), by section (Versions and Findings are concatenated — the
disjoint ID blocks make the `F` and `S` numbers unique; check for duplicates
before writing; Options, Decision and the rest are written once by you from the
sections returned). Your synthesis summarises; it never replaces a part's own
text. Each part's sections 4-9 (options, decision, notes, open questions, and any
table in them such as a catalogue or a template matrix) are carried **verbatim**
into the merged note under `## Appendix: Part <n> detail (verbatim)`. Delete the
temporary files **only after** the user approved the merged note. Before asking
for that approval, check the merged file by content: its finding rows equal the
sum of the parts' rows, no ID appears twice, sections 4-9 are non-empty in the
synthesis and in every per-part copy, and **every non-blank line of each part's
sections 4-9 occurs in the merged file** (a read-only comparison, for example
`grep -Fxv -f <merged> <part-section-lines>`, which prints the lines missing).
A missing line blocks the deletion: carry it, then check again. A comparison
that could not run is reported as `not run - <reason>` and also blocks it. The
deletion question names the files and reports this check's result. (A Kodeebo merge kept
every finding row but only summarised part 3's catalogue and template tables;
the part file was deleted and the tables had to be recovered from the session
record for the ADR that needed them.)

## Brief template (`refresh` mode)

See `4-refresh.md`; the refresh brief is separate because it forbids the
researcher from editing any file.
