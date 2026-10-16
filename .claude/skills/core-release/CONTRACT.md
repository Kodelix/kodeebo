# /core-release - Handoff Contract

## Role in Pipeline
Cuts a release of `saas-core-<track>`. Runs only inside a core repo and only when
the user types it (`disable-model-invocation`). Called in `/studio` flow `core`
after the core repo's own feature work (often started from a `/core-extract`
proposal). Produces what `/core-upgrade` and `/core-use` read in every product:
module CHANGELOGs with Breaking / Deprecated / Migration headings, release notes,
and a tag.

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| Core repo working tree (clean), branch, tags, git history per module | Yes; dirty tree = `BLOCKED` | Yes, except the files this skill writes |
| Core layout, versioning, tag-scheme and deprecation policy in the core's `docs/` | Layout: yes (or user-stated, recorded). Policy absent = `NOT SOURCEABLE` consequences below | Yes |
| Module port files, config schema, adapters, conformance suites, build files, `clients/` | Yes | Yes |
| `project.yaml` (`stack.backend` of the core repo), `docs/stack-reference/pins.yaml` | Yes | Yes |
| Scripts/Gradle tasks the repo defines for tests, lint, scans | Run if defined; else `not run` | Yes |

## Preconditions
- The repo is a core repo and the user confirmed releasing from it (a product repo is refused).
- Tag scheme decided (policy or ADR); without it Phases 1-5 run but no tag is created.

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`, plus `Tag:
created locally (not pushed)` / `not created - reason`. Precedence: BLOCKED, NOT
ASSESSED, COMPLETE WITH GAPS, COMPLETE. CTO-ADR (policy/scheme ADR, full review
mode): APPROVE / CONCERNS / REJECT / NOT ASSESSED / skipped.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `<module>/CHANGELOG.md` entries | version, date, bump class and evidence, Added/Improvements/Bug Fixes/Security/Known Issues, and **Breaking changes / Deprecated / Migration** (each "None" when empty), conformance line | written after approval |
| `docs/releases/<tag>.md` | the release-notes template filled for product teams, module version table, conformance matrix, tag scheme in force | `DRAFT.md` while the scheme is undecided |
| `production/releases/core-<tag>.md` | the audit record: bumps with evidence, policy source, checks with commands and exit codes, `not run` items, decision, commit, tag state | written after approval |
| `production/releases/core-draft/*.md` | agent drafts and raw check output | named paths |
| Release commit; annotated tag (local) | only on explicit asks | never pushed |

## Output Guarantees
- A bump is never lower than the diff supports; a `FAILED` conformance cell or a removal outside the deprecation window leaves no tag.
- Every adapter of every released module has a matrix row: `passed`, `FAILED`, or `not run - reason`; an adapter with no conformance test is reported.
- Absent policy, absent API-diff tool, absent scanners and absent container runtime are named in the record and the notes, never silent.
- The tag points at a commit containing the CHANGELOG and notes, verified by `git rev-parse`.

## Immutability Rules
- No push, no registry publish, no announcement, no `--force`, no existing tag moved or deleted.
- No product repo is read or changed; no commit except the one the user asks for.
- Test code is not weakened or skipped; conformance gaps are reported, not patched here.
