# /dev-story — Phase 6: Verify — Layer Checks and Run-and-Observe

> Part of `/dev-story`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 6: Verify — Layer Checks and Run-and-Observe

**In this file:**

- First: did the agent actually finish?
- Layer checks
- Run and observe
- Retain the evidence

### First: did the agent actually finish?

**Do not assume completion.** A lead can stop at its turn limit mid-edit, and the
work it leaves behind can be broken — a helper called but never defined, an
import half-moved, a migration written with no down. Its partial report reads
like progress, and the summary would print "Implementation Complete" over code
that does not build.

1. **Check each agent's terminal state.** If any reported stopping early, hit a turn/step limit, or its report ends mid-task, treat the story as **INCOMPLETE**.
2. **Check each lane's named artifacts exist** (Glob the files the report lists). A listed file that is not on disk is a failed phase, however fluent the report reads.
3. **Run the layer checks below.** They are the proof; the agent's own "all green" is a claim.

**If INCOMPLETE:** say so as the headline, list what exists so far, name the
specific breakage, and offer to resume the agent. Do **not** emit
"Implementation Complete", and do not advance the story's status.

### Layer checks

Read `references/layer-checks.md` for the commands per layer. Run (this skill's own `Bash` grants cover the root-level commands; rows that name an agent are run by that agent via `Agent`), for **each
lane the story touched**, every row that applies — exit codes answer the
question, not the agent's prose. For each check record: the command, the exit
code, and the decisive output lines (failures, finding counts, coverage lines).

Rules:

- **Report real output.** A pass is `passed (exit 0)` with the summary line the tool printed (`ok  	…/domain	0.4s`, `BUILD SUCCESSFUL`, `0 vulnerabilities`), not "tests pass".
- **A check that could not run is `not run — [reason]`** and appears in the summary's `Not run` list: toolchain missing (`govulncheck` not installed), container runtime unreachable (integration tests, run-and-observe), task or script undefined (`ktlintCheck`, `pnpm typecheck`), host mismatch (Swift tests need macOS with Xcode — "expected on macOS CI", never skipped silently), no emulator/device. Offer the user the fix (install it / run it in CI); do not substitute a weaker check and call it equivalent.
- **Failures are findings, not noise.** A failing check means the story is not complete: report it, return it to the lead (resume the agent, naming the failing command and output), and re-run. Never weaken a test, a lint rule or a scan to get green; never disable a failing test.
- **Test location sanity.** Glob the test files the plan promised (Phase 4) — a test file at a path no test runner picks up (`tests` count of zero) is the same as no test: a suite that started and executed zero tests is reported `FAILED — 0 tests executed` (never `passed`), while a suite that could not start is `not run`. Confirm the runner's reported test count includes the new tests (`-run`/`-v` output, Gradle report, Vitest summary).
- **Dependency scan** (`govulncheck ./...` in `backend/` for Go, `osv-scanner scan -r .` across Go/Gradle/npm/SwiftPM, `pnpm -C web audit`) is part of DoD gate 7 — a story that adds or bumps a dependency without a clean scan (or a recorded waiver) is not complete.
- **Secrets**: `gitleaks` over the changed paths before the summary.
- **Coverage signal** (`qa.level: full` — extra evidence): domain + app packages ≥ 85 % line coverage, any drop explained; below that is reported, not hidden.

Save each check's output to `production/qa/evidence/[STORY-ID]/checks-[layer].md`
(command, exit code, trimmed output). These are **new files under a path this
skill names** — write them without a second prompt. A check that did not run
gets a file line too: `not run — [reason]`.

### Run and observe

**A compile is not a run.** Every story that changes something a user can see or
call is exercised against a running stack before it closes, and the observation
is retained in `production/qa/evidence/[STORY-ID]/`. Procedure:
`.claude/docs/run-and-observe.md`. This step is **not waived at
any `qa.level`**, and neither are the tests.

1. **Bring the stack up**: `docker compose -f deploy/compose.dev.yaml up -d --wait`. If a service never becomes healthy, that is the finding — capture the logs. Migrations run before the API starts; seed data comes from `tools/seed/` with a dedicated test tenant, never a copy of production data.
2. **Observe per layer** (table in `run-and-observe.md` §2). **Who runs these:** this skill holds no grant for `curl`/`httpie`, `adb`, `xcrun`, Lighthouse or a Playwright journey script. They are run by the lane's lead spawned via `Agent` (`go-lead`/`ktor-lead` or `qa-tester` for API calls, `web-lead` for Playwright, `pnpm dev` and Lighthouse, `android-lead`/`ios-lead` for `adb`/`xcrun`), each returning the retained file paths; this skill then `Read`s the files. For this story:
   - **API / contract**: call each new or changed endpoint with `curl`/`httpie` or the generated client **as owner, member, other tenant, and anonymous**, plus an invalid-input call; retain request + response (status, headers, body, secrets redacted) as `api-[endpoint].md`. The error body is RFC 9457 `application/problem+json`; the cross-tenant call returns not-found/forbidden with no data of the other tenant.
   - **Web**: `pnpm -C web dev` (or the built static bundle behind the dev proxy); a Playwright script drives the journey; screenshots at 1440 px and 390 px, light and dark if supported, **Arabic (RTL) and English**. Then `ui-designer` (spawned via `Agent`, not run by this skill) runs `/impeccable audit [target]`, the lead fixes its findings, then `ui-designer` runs `/impeccable polish [target]` (`run-and-observe.md` §3); keep the audit summary in the folder. An audit nobody ran is reported `not run`.
   - **Android / iOS**: emulator/simulator screenshots of each touched screen, plus RTL (iOS: Dynamic Type large). Android: `adb exec-out screencap -p > shot.png`; iOS: `xcrun simctl io booted screenshot shot.png` — **macOS only**; elsewhere `NOT VERIFIED — requires macOS with Xcode`.
   - **Marketing site**: `pnpm -C site build` then `pnpm -C site preview` (two commands); screenshots of changed pages + a Lighthouse report.
   - **Background job / webhook**: trigger it (CLI, provider sandbox test event) and follow the trace; retain the exported span list plus the resulting DB/cache state.
   - **Telemetry**: open the trace for one request in the local collector UI and retain a screenshot showing handler → use case → DB/cache spans, `trace_id` in the log line, and no PII in attributes (DoD gate 4).
3. **Then `Read` each retained image** and compare it with the acceptance criteria: clipped text, an overflowing panel, un-mirrored RTL layout, a missing empty/error state, a token or id leaking into the page are defects, and this is the only step that finds them.
4. **Negative path too**: wrong role, other tenant, invalid input — observed and retained, not only reasoned about.
5. **Tear down**: `docker compose -f deploy/compose.dev.yaml down` (never `down -v` unless the user asks).

Report exactly one line — `Run result: OBSERVED — <what was exercised/seen>` with
the retained path, `Run result: NOT VERIFIED — <reason>`, or
`Run result: N/A — <reason>` for a story with genuinely nothing a user can see or
call (a pure domain refactor with no surface). **`NOT VERIFIED` is a blocker at
BLOCKING levels for UI, Contract, Integration and Security stories, not a note** —
`/story-done` reads this line. A run on only part of the scope is
`OBSERVED — partial: [what was not run]`, naming the gap; it is not a plain
OBSERVED.

### Retain the evidence

List what is on disk under `production/qa/evidence/[STORY-ID]/` (Glob) and print
the listing in the summary. **A filename that is mentioned but not on disk is not
evidence**: captured-and-discarded is an assertion, not evidence. Missing
expected files are reported as gaps, with the command that would produce them.

---
