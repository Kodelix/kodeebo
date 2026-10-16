# /core-use — Phase 4: Implement and Verify

> Part of `/core-use`. Read again if the conversation was compacted.

## 1. Implement

Spawn `principal-engineer` via `Agent` to route the approved plan to the lead(s)
in the plan's order (the same routing as `/dev-story` Phase 3). Brief with: the
plan path, the approved file set, the tag, the Phase 2 fit table, and these
instructions, stated plainly:

- Implement **only** the approved file set. A needed file outside it is returned
  as a request, not written.
- Tests first for the use-case behaviour; the composition-root and integration
  tests are part of the change, not a follow-up.
- Use the dependency mechanism the product already has; do not add a
  repository/credential setting without `platform-lead`.
- Read the core module's **docs and port files at the pinned tag** before using
  an API; any symbol not found there is reported `NOT SOURCEABLE`, not guessed.
  Symbols marked deprecated in the CHANGELOG are not used.
- Never edit, vendor or fork core code. If the module needs a change, stop and
  return it as a `/core-extract` input.
- Return: files created/changed, commands run **with real output summaries**,
  and every check that could not run as `not run — <reason>`.

The agent's report is a file at the path you named
(`production/core/adopt-<module>-<date>-impl.md`) — verify it exists
(`error-recovery-protocol.md`, Trigger 0).

## 2. Verify — run, don't assume

This skill holds no test-runner grants. Spawn the stack lead (`go-lead`, `ktor-lead` or
`web-lead`, per `stack`) via `Agent` as a **separate verification run** (not the
implementer's own claim) to run, from the repository root, per layer, using
the `layer-checks.md` lookup table in the `dev-story` skill folder (`.claude/skills/dev-story/`) for the command table (Go
and Gradle commands are not repeated or recalled here; Gradle task names are
confirmed from the build files first). Report each as `passed` / `FAILED` /
`not run — <reason>`:

| Check | Notes |
|---|---|
| Dependency resolves at the pinned tag from a clean state | the tool's own output (lockfile/verify step) |
| Build and unit tests | |
| Integration tests (Testcontainers) | needs a reachable container runtime; absent → `not run`, which caps the verdict at `NOT ASSESSED` |
| Lint / static analysis | |
| Dependency scan of the new transitive set | `osv-scanner` / `govulncheck` per `layer-checks.md`; not installed → `not run` (route `/dependency-audit`) |
| `bash .claude/scripts/project-coherence.sh` | show the real lines; observations, not a verdict |
| Run-and-observe | when the module changes anything callable or visible (login, OTP delivery, file upload, billing): bring up the dev stack per `.claude/docs/run-and-observe.md`, call it, retain request/response (secrets redacted) and one trace in `production/qa/evidence/<STORY-ID or adopt-<module>>/` |

Security-sensitive module: the negative tests the threat model assigns (authz
bypass, cross-tenant, injection, rate limit) must exist and pass — they are not
waivable and not downgraded by `qa.level: minimal`.

## 3. Failure handling

- A failing check is shown with its output; **do not auto-fix**. Ask: send it
  back to the lead, revert the adoption, or stop. A revert of the dependency and
  wiring leaves `project.yaml` untouched (Phase 5 never ran).
- A flaky or environment failure (container runtime down) is `not run`, with the
  reason — never retried until green and never reported as passed.
