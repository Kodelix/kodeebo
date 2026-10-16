# /api-contract - Phase 5: Lint, Breaking-Change Diff, Client Generation

> A tool is run only if the repository already defines it. Nothing here names a
> command line: those are `NOT SOURCEABLE` in `docs/stack-reference/` and are
> never written from memory.

## 1. Discover what the repository defines

Look (read-only) in: an ADR on API linting, diff or client generation
(`docs/architecture/adr-*.md`); CI configuration (`.github/workflows/`,
`.gitlab-ci.yml`, or the CI the product uses); `tools/`; `package.json` scripts
in `web/`; Gradle tasks and version catalogs under `mobile/` and `backend/`;
`Makefile`/`justfile`; `contracts/` for a linter config. Record what exists, with
the file and line that defines it, in this table:

| Step | Defined in repo? | Where | Command (as written in the repo) |
|---|---|---|---|
| Contract lint | yes / no | | |
| Breaking-change diff | yes / no | | |
| Client generation: TypeScript | yes / no / not in stack | | |
| Client generation: KMP | yes / no / not in stack | | |
| Client generation: Swift | yes / no / not in stack | | |

`.claude/rules/contracts.md` says to lint with "Spectral or the ADR-chosen
linter" and to run the breaking-change diff in CI. That names the *requirement*,
not a pinned tool or a command.

## 2. Run what exists, report the real output

For each defined step, ask once if it rewrites files ("May I run [command]?
It will rewrite [paths]." Generation always rewrites client code; lint and diff
only read). The command is whatever the repo defines (no tool is pinned), so this skill holds no
`allowed-tools` grant for it: after the yes, spawn `dev-tooling-engineer` via `Agent` to run
the exact command and return exit code and output, or print the command for the user to
run and paste the result (no output returned = `not run`). Capture exit code and output. Report in the
record: command, exit code, trimmed output, files changed (`git status --short`).
Never reinterpret a tool's non-zero exit as a pass; never paraphrase its findings
away.

| Step | Not defined / cannot run | Reported as |
|---|---|---|
| Lint | not in repo | `not run - tooling not in the stack reference and not set up in this repository` |
| Breaking-change diff | not in repo, or no baseline | `not run - <reason>`; the **manual diff** in step 4 is a labelled hand-check, not a substitute |
| Generator | not in repo | `clients not regenerated - generator not set up`; list which clients are therefore **stale** |
| Any | tool defined but the toolchain is missing (command not found, container runtime down) | `not run - <exact error>` |

Routing for every `not run` tooling row: `dev-tooling-engineer` (via
`principal-engineer`) to add it to CI and the local scripts; `/research` to pick
and pin the tool; `/architecture-decision` to record the generator choice (the
`api-designer` agent requires the generator choice to be an ADR).

## 3. Client generation rules

- The generator is the only author of client code. If generated output differs
  from the committed clients, the generator output wins; if the generated tree
  has hand edits, list them and stop - they are a review failure to fix in the
  contract or the generator configuration, not in the output.
- The contract change and the regenerated clients belong in the **same change**
  (`rules/contracts.md`). If the contract changed and a client target exists but
  was not regenerated, that target is `stale`, and the verdict is
  `NOT ASSESSED` for it.
- Type-check each regenerated client with the layer's own checks (`/test`, or the
  layer's documented command in its stack reference). A client that was
  regenerated but not type-checked is `regenerated, not compiled`.
- Do not write generated code from this skill, and do not touch handler code:
  server-side stubs, if the stack uses them, are the stack lead's.

## 4. Manual breaking-change diff against the last released contract

A hand-check, always performed when a baseline exists, always labelled **manual
review** (even when a tool also ran, a disagreement is reported, not resolved
silently).

`git diff <tag> -- contracts/openapi/<service>.yaml` (or diff the scratch copy
of the released file against the working file). Classify every changed path,
operation, parameter, schema and response:

| Change | Class |
|---|---|
| New operation, new optional request field, new response field, new enum value the contract already told clients to tolerate, new optional parameter, new status code a client can treat generically | ADDITIVE |
| Removed or renamed operation, path, parameter, field or enum value | BREAKING |
| Tightened validation (lower `maxLength`/`maximum`, new `pattern`/`required`, smaller enum) | BREAKING |
| Changed type or format; changed field optional -> required | BREAKING |
| New required input (parameter, header, body field) | BREAKING |
| Changed semantics (same shape, different meaning) or changed status code of an existing outcome | BREAKING |
| Response field removed, or a response enum gaining a value clients must handle exhaustively | BREAKING |
| Loosened validation | ADDITIVE on requests; check responses separately |
| Description-only, example-only, `deprecated: true` added | ADDITIVE |

Semantics changes cannot be detected from text alone: ask the owning engineer
or the user and record the answer. List results as a table (change, class,
reason). The count of BREAKING rows decides Phase 4 of `SKILL.md`.

If the product ships to self-hosted customers on older versions, repeat the
classification against the oldest **supported** released contract when a support
window is stated; say which versions were diffed and which were not.

## 5. Tooling result

```text
Lint: ran (<command>, exit N, N findings) | not run - <reason>
Breaking-change diff (tool): ran (...) | not run - <reason>
Manual diff vs <tag>: N changes, N BREAKING
Clients: TypeScript regenerated/compiled | regenerated, not compiled | not regenerated (<reason>) | not in stack; same for KMP, Swift
```

Verdict contribution: any `not run` in lint, diff or generation = at best
`NOT ASSESSED`; each is named in the report with what closes it. All three real
and clean, with zero unresolved BREAKING = eligible for `COMPLETE`.
