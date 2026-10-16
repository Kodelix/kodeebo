# /dev-story — Phase 7: Collect and Summarise

> Part of `/dev-story`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 7: Collect and Summarise

Collect:

- Files created or modified, per lane (with paths) and the lead that wrote each
- **Verification results** — every Phase 6 check: command, exit code, outcome; and the `Not run` list with reasons
- Test files created (paths and number of test functions) with the **failing-then-passing** evidence for Logic tests (the tests exist and pass at every `qa.level`)
- The eight-gate evidence plan with a status per gate: `produced` (with path) / `planned for /story-done` / `not run` / `waiver requested`
- Any deviations from the story's Out of Scope boundary, from the ADR, from the research note (flag these), or from an accepted-with-risk choice made in Phase 2
- Any questions or blockers the agents surfaced
- Any stack risks flagged (`NOT SOURCEABLE` APIs, deprecated-API hits)

**No test-evidence waiver exists.** A Logic, Integration, Contract or Security story with no tests row in the summary is reported as a gap (`Tests: not produced`), at every `qa.level`.

Present a concise implementation summary:

```
## Implementation Complete: [Story Title]

**Story**: [STORY-ID] — Type [type] — gate level [BLOCKING / ADVISORY]
**Routing**: [lane → lead (secondaries)], in order [1 → 2 → 3]
**Research**: [path | exempt — row]      **Threat model**: [path + SL-THREAT-MODEL verdict | skipped — mode | not required — reason]
**Contract**: [path / story ID | n/a — reason]

**Files changed**:
- `backend/[path]` — created / modified ([brief description])
- `[test path]` — test file ([N] test functions)

**Verification** (real output; `not run` is not a pass):
| Layer | Check | Command | Result |
|---|---|---|---|
| backend | unit + race | `go -C backend test -race ./...` | passed (exit 0) — ok …/domain 0.4s … |
| backend | lint | `golangci-lint run ./...` | passed (exit 0) |
| backend | vulnerabilities | `govulncheck ./...` | **not run — govulncheck not installed** |
| … | … | … | … |

**Not run**: [list with reasons and who/what will run it — or "none"]
**Run result**: [`OBSERVED — <what was exercised>` + retained path | `OBSERVED — partial: …` | `NOT VERIFIED — <reason>` | `N/A — <reason>`] — see `.claude/docs/run-and-observe.md`
**Evidence on disk** (`production/qa/evidence/[STORY-ID]/`): [listing]

**DoD gates (planned vs produced)**:
| # | Gate | Status | Evidence / gap |
|---|------|--------|----------------|
| 1 | Research first | produced | `docs/research/[feature].md` |
| 2 | Clean architecture | produced | domain-import grep: [result]; ports: [names] |
| 3 | Tests | produced / not run | [paths; counts] |
| 4 | Observability | produced | spans [names]; trace screenshot [file] |
| 5 | Caching | produced | decision: [pattern/key/TTL/invalidation] or `no cache: [reason]` |
| 6 | Performance | produced / not run | budget [row]; queries/request [N]; load test [file / not run] |
| 7 | Security | produced / not run | ASVS/MASVS [IDs]; negatives [tests]; dep scan [clean / not run] |
| 8 | Decision record | none expected / ADR needed: [title] | |

**Acceptance criteria covered**:
- [x] [criterion] — implemented in [file:function], covered by test [test_name]
- [x] [negative criterion] — covered by test [test_name] (other tenant / wrong role)
- [x] [criterion] — OBSERVED in `production/qa/evidence/[STORY-ID]/01-[what].png`
- [ ] [criterion] — DEFERRED: [condition — e.g. needs a deployed stack / provider sandbox / store review; or the *feel* half of a UI criterion → `/team-qa`]

**Deviations from scope / ADR / note**: [None] or [list]
**Stack risks flagged**: [None] or [finding]
**Blockers**: [None] or [describe]

**Before running `/story-done`:** the checks above ran now, on this host. `/story-done` re-reads their saved output in `production/qa/evidence/[STORY-ID]/` and will re-run the layer checks itself if that output is missing or older than the code — but a check that is `not run` here stays `not run` there until it is executed somewhere (locally, or on CI — e.g. Swift tests on the macOS runner) and its result retained. A BLOCKING gate resting on a `not run` check cannot reach `COMPLETE`.

Ready for: `/code-review [file1] [file2]` (review against the eight DoD gates), then `/story-done [story-path]`
```

**Hand the story to `/story-done` by setting `In Review`.** `Status: In Progress`
alone cannot tell `/studio resume`, `/story-readiness` and `/help` whether the
work is still being written or is finished and waiting to be closed. Only when the
headline above is `Implementation Complete` (never for INCOMPLETE or Needs
Attention), in `collaborative` mode ask once — "May I set this story to
`In Review`? This sets `Status:` and `Last Updated:` in `[story-path]` and
`status: review` on its entry in `production/sprint-status.yaml`." — then set
`Status: In Review`, update `Last Updated:` to today and, if
`production/sprint-status.yaml` exists, set the entry to `status: review` and bump
its top-level `updated` (leave the sprint file out of the question and say
`Sprint status not updated: production/sprint-status.yaml absent` when it does
not exist). `guided` and `autonomous` update without asking
(`.claude/docs/automation-modes.md`). If declined, leave `In Progress` and print
`Story left In Progress — In Review declined` in the summary. This skill never
sets `Complete`: closing is `/story-done`'s alone.

If the story is **INCOMPLETE** (Phase 6), print the same block with the headline
`## Implementation INCOMPLETE: [Story Title]`, the breakage named, and the resume
action — never `Implementation Complete`. The story stays `In Progress`.

If a check **failed** and was not fixed, the headline is `## Implementation Needs
Attention: [Story Title]` with the failing command and output; do not advance.

---
