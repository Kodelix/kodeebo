# /manual-test — Phase 3 and 5: Running the Session and Retaining Evidence

> Part of `/manual-test`. `SKILL.md` names when to read this file; the settings
> it resolved and the rules under its headings still apply here.

## 1. Run order

1. Confirm the stack is healthy (`up --wait` returned), the build hash matches
   the charter, and the seeded users for the assigned cells can sign in. Do not
   print or store credentials; they come from the seed or the secret store.
2. Note the start time (UTC). Work the cells in charter risk order. When a cell
   reveals something unexpected, **follow it** (that is exploration), but note the
   detour and keep to the time box.
3. After every cell: result, the evidence file path, and anything odd that did not
   fail. A result is `PASS`, `PASS WITH NOTES`, `FAIL`, `BLOCKED` (what blocks it
   and who owns it) or `NOT COVERED` (reason).
4. Note the end time. Stop at the time box or a stop condition.

## 2. Evidence per surface (`.claude/docs/run-and-observe.md`)

| Surface | Capture | Name |
|---|---|---|
| API | request + response (status, headers, body with secrets redacted), as each actor, **including the negative path** | `api-<endpoint>.md` |
| Web | full-page screenshots, desktop (1440 px) and mobile (390 px), light/dark if supported, **Arabic (RTL) and English** | `web-<screen>-<width>-<lang>.png` |
| Android | `adb exec-out screencap -p > shot.png` per touched screen, plus RTL | `android-<screen>-<lang>.png` |
| iOS | `xcrun simctl io booted screenshot shot.png`, plus RTL and Dynamic Type large — macOS host only | `ios-<screen>-<lang>.png` |
| Background job / webhook | trigger it (CLI, provider sandbox test event), follow the trace | trace screenshot or exported span list + resulting DB/cache state |
| Telemetry | the trace for one request showing handler → use case → DB/cache | `trace-<flow>.png` |

- **Every evidence file is on disk before its cell is marked passed.** After
  saving, list the folder to confirm. A screenshot taken and discarded counts as
  `NOT COVERED`.
- Redact secrets, tokens, OTP codes and personal data **before** saving; check
  with a grep of the saved text files for token-shaped strings.
- The web captures are scripted or manual; if a Playwright script drives them,
  the script's path is recorded in the notes. Browsers not installed → ask
  before installing (the Playwright rules in the `/test` skill; the install is not pre-approved, so the user runs it); declined → web cells
  `NOT COVERED — browser not available`.
- **Induced failures** are recorded: which dependency was stopped (`docker compose
  -f <file> stop <svc>`), what the user saw, whether data was lost, and that the service was
  restored (`start`). Never `down -v`.
- **Read before describing.** Open each screenshot with `Read`; describe only
  what you saw, compare with the cell's expectation, and say when an image shows
  something the cell did not predict.

## 3. Session notes

`production/qa/evidence/[ID]/session-notes.md`:

```markdown
# Session Notes: [ID] — [date]
**Charter**: charter.md · **Build**: [hash] · **Start/End (UTC)**: [..] · **Testers**: [..]

## Coverage
| Cell | Result | Evidence |
(every chartered cell — EXECUTED results or NOT COVERED with the reason)

## Findings
| ID | Title (actor, action, wrong outcome) | Proposed severity (rule matched) | Evidence |
[BUG-NNNN once filed]

## Observations that did not fail
[slow query, odd copy, jank, a log line that should not be there — candidates for stories]

## Questions
[ambiguities in the spec/criteria — routed to product-manager]

## Heuristics applied / not applied
## Not covered
[cells, areas, surfaces, locales and why — device absent, macOS only, no seeded role, time box]

## Verdict: COMPLETE / COMPLETE WITH GAPS / NOT ASSESSED / BLOCKED
```

Merge the agent's `session-notes-qa-tester.md` and the user's answers into this
one file; keep the agent's file as the raw record.

## 4. Story evidence file

When the subject is a story, `production/qa/evidence/[STORY-ID]/test-evidence.md`
(next to the files it cites, not beside the folder) from `.claude/docs/templates/test-evidence.md`: the acceptance criteria results
(only those the session actually executed), the run-and-observe table with real
file names, the screenshots table (filename, what it shows, viewport/locale/
theme, criterion), test conditions (tenant, role, seed, platform). **Sign-off
rows stay unchecked** unless the sign-off happened in this session by the person
who signs. `/story-done` and `/test-evidence-review` glob this directory — a
filename listed with no file beside it fails the UI gate.
