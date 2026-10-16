# /story-done — Phase 2: Read the Story

> Part of `/story-done`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 2: Read the Story

Read the full story file. Extract and hold in context:

- **Story name and ID** (`Story ID` — it names the evidence directory `production/qa/evidence/<STORY-ID>/`)
- **Spec requirement TR-ID(s)** referenced (e.g., `TR-billing-001`)
- **Manifest Version** embedded in the story header (e.g., `2026-10-10`)
- **ADR reference(s)** referenced
- **Acceptance Criteria** — the complete list (every checkbox item, including negative / cross-tenant ones)
- **Implementation files** — files listed under "files to create/modify" / Implementation Notes, and the code root(s) the story names
- **Story Type** — the `Type:` field from the story header (Logic / Integration / Contract / Security / Performance / UI / Config)
- **Research note** and **Threat model** lines (path, `exempt — [row]`, `not required — [reason]`, MISSING)
- **Contract** line and **Editions** line
- **`## Definition of Done Evidence`** table (the eight gates plus run-and-observe) with its statuses, and the `## Evidence Plan` section if `/dev-story` recorded one
- **`## Test Evidence`** paths and **`## QA Test Cases`**
- **Stack notes** — post-cutoff APIs, deprecated-apis entries the story must avoid
- **Waivers** already written in the story file (reason + who approved + date) and any **Manifest-Note:**
- **Verdict lines** already recorded in the story header for PE-CODE-REVIEW, QL-TEST-COVERAGE, SL-TENANT-ISOLATION, SL-THREAT-MODEL
- **Estimated vs actual scope** — if an estimate was noted

Also read:
- `docs/architecture/tr-registry.yaml` — grep the story's TR-IDs
  (`Grep pattern="id: <each TR-ID>\s*$" path="docs/architecture/tr-registry.yaml" output_mode="content" -A 6`),
  not a full read of the registry. Read the *current* `requirement` text from each
  matched entry. This is the source of truth for what the spec required — do not use any
  requirement text that may be quoted inline in the story (it may be stale).
- The referenced spec section — just the acceptance criteria and key rules, not
  the full document. Use this to cross-check the registry text is still accurate.
- The referenced ADR(s) — **just the `## Decision` and `## Consequences`
  sections, never an unbounded full read.** Map headings first
  (`Grep pattern="^## " path="docs/architecture/[adr-file].md" output_mode="content" -n`),
  then bounded-`Read` only those two spans. Hold this content: Phase 4's ADR
  constraints check and gate 8 use it — do not re-read it there.
- `docs/architecture/control-manifest.md` header — extract the current
  `Manifest Version:` date (used in Phase 4 staleness check)
- The **research note** (`docs/research/<feature>.md`): its path, its `Status:` and `Date:` header lines and its date by the **Dating rule** below, the `Versions` and `Decision` headings, and its cache decision / security / performance / observability notes — used by gates 1, 4, 5, 6, 7 in Phase 6. If the story claims an exemption, hold the claimed row.
- The **threat model** (if the story requires one): the rows this story owns (threat → mitigation → ASVS/MASVS ID → negative test).
- The **budget row** for the surface in `docs/architecture/perf-budgets.md` (absent file or row → `budget not yet set`).
- `resolve_code_root` (`bash .claude/hooks/yaml-helper.sh resolve_code_root`) — the code roots to Grep; an **empty result means the code-scanning checks did not run**, reported as such, never as zero hits.
- The **evidence directory listing**: Glob `production/qa/evidence/<STORY-ID>/**` once and hold the listing.

### Dating rule — "is A at least as new as B" without assuming a commit exists

`/story-done` runs **before** the commit (Phase 8 only *suggests* one), so the
work it judges is normally untracked or modified, and `git log` for such a path
prints nothing or an older commit. A freshness, review-currency or
research-before-code check that reads only `git log` therefore passes stale
evidence or fails fresh evidence without saying so. Every such check in
Phases 3, 5 and 6 uses this rule and **states the source it used**:

1. **Uncommitted?** `git status --porcelain -- <path>`: any output (untracked
   `??`, modified ` M`, staged `A`/`M`) means the file's committed history does
   not describe its current content.
2. **Pick the date source, in this order, per file:**
   - **git commit date** — only for a path that is tracked **and** clean:
     `git log -1 --format=%cI -- <path>` (last change) or
     `git log --diff-filter=A --format=%cI -- <path>` (first added, last line).
   - **file mtime** — for an untracked or modified path: `stat -c %y <path>`
     (GNU) or `stat -f %Sm -t %FT%T <path>` (BSD). Weaker evidence: a fresh
     checkout or copy resets it. Say so when mtime decided the result.
   - **the artifact's own date line** — `Date:` (research note, threat model),
     `Started:` / `Last Updated:` (story, set by `/dev-story`), the `Recorded:`
     or date field of an evidence file. Day granularity only: two artifacts dated
     the same day cannot be ordered by it.
3. **Compare like with like.** A commit date against an mtime is not a
   comparison; when sources differ for the two sides, use the strongest source
   both have (mtime, then date line). If the only common source is a day-granular
   date line and both fall on the same day, the order is **not established**.
4. **Name it.** Every verdict that rests on this rule carries
   `freshness source: git commit | file mtime | date line` (and, for a mixed
   case, which side used which). A check that found no usable source on either
   side is `not checked` — never `current`, `fresh` or `before the code`.

---
