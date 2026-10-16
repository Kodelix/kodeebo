# /test-setup — Phase 1: Detect Stack and Existing State

> Part of `/test-setup`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 1: Detect Stack and Existing State

1. **Read the stack**:
   - Take the layers from the `stack` line of the resolved config
     (`backend`, `web`, `site`, `mobile`, `data`, plus `deploy`,
     `distribution`, `tenancy`). A layer shown as `unset` is not configured.
   - Resolve the code roots with `resolve_code_root` (`layout.code_roots`, else
     the conventional `backend/`, `web/`, `site/`, `mobile/`, `contracts/` that
     exist on disk — `directory-structure.md`). **An empty list means the scan
     did not run** — say so.
   - If **no layer is configured** and no code root exists, stop:
     "Stack not configured. Run `/setup-stack` first, then re-run `/test-setup`."
     Close with `BLOCKED — stack not configured`.
   - A configured layer whose code root does not exist yet (the product is not
     scaffolded) is still planned: its test location is created with the layer
     and Phase 3 records it as `directory only`.
   - If the argument names layers, restrict to those; a named layer that is not
     configured is reported, not silently created.

2. **Read the pins**: read `docs/stack-reference/pins.yaml`. If it is missing,
   stop: "No `docs/stack-reference/pins.yaml`. Run `/setup-stack` to verify and
   write the stack reference." Close with `BLOCKED — pins.yaml missing`. Every version this skill writes comes from here.
   Run `bash .claude/scripts/project-coherence.sh` and report any `BEHIND` or
   `FLOATING` line — a test setup built on a toolchain behind its pin is worth
   saying out loud. A `SKIPPED` line means that comparison did not run.

3. **Research note**: check for `docs/research/test-infrastructure.md`
   (`.claude/docs/research-protocol.md`, DoD gate 1). The note records the
   facts this skill cannot take from the stack reference: the versions of
   Testcontainers modules, JUnit 5 / `kotlin.test` additions, Testing Library,
   the Gradle `integrationTest` source-set configuration, the Playwright and
   Vitest config keys at the pinned versions, the OpenAPI validator choice, and
   the GitHub Actions in use.
   - Present: read it; its recorded versions and APIs are the second source
     (after `pins.yaml`) for Phase 3 and 4.
   - Absent: use `AskUserQuestion`: "No research note for test infrastructure.
     What do you want to do?" Options:
     `[A] Run /research test-infrastructure first (Recommended) — then re-run this skill`,
     `[B] Scaffold only what the stack reference already sources — list the rest as PENDING`.
     Option B is allowed; the summary then lists every pending item and the verdict
     is **PARTIAL**.

4. **Check for existing test infrastructure**, per configured layer:

   | Layer | Look for |
   |---|---|
   | Go backend | `backend/go.mod`; `*_test.go` files; files with a `//go:build integration` line |
   | Ktor / Kotlin | `backend/src/test/kotlin/`, `backend/src/integrationTest/kotlin/`; the Gradle build files and version catalog |
   | Web | `web/package.json` (scripts, `vitest`, `@playwright/test`, `packageManager`), `web/e2e/`, `*.test.ts(x)`, a Playwright config |
   | Marketing site | `site/e2e/`, a Playwright config under `site/` |
   | KMP shared | `mobile/shared/src/commonTest/kotlin/` |
   | Android | `mobile/android/app/src/test/`, `mobile/android/app/src/androidTest/` |
   | iOS | test targets under `mobile/ios/` (Swift Testing / XCUITest) |
   | Contracts | `contracts/openapi/*.yaml`; contract tests in consumers (path or name containing `contract`) |
   | Common | `production/qa/` (`evidence/`, `cases/`), `.github/workflows/` |

   Count real test files, not directories or `.gitkeep` placeholders.

5. **Report findings**:
   - "Stack: [layers]. Code roots: [list or 'none yet']. Research note: [found / not found].
     Existing test files: [per layer]. CI workflow: [found / not found]."
   - If everything already exists AND `force` was not passed:
     "Test infrastructure appears to be in place. Re-run with `/test-setup force`
     to create any missing files. Proceeding will not overwrite existing test files."

If the `force` argument is passed, skip the "already exists" early-exit and
proceed — but still do not overwrite files that already exist at a given path.
Only create files that are missing.

---
