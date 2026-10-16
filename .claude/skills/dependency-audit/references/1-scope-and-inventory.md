# /dependency-audit - Phase 1: Scope and Inventory

> Phase 1 of `SKILL.md`. Read it again if the conversation was compacted.

## 1. Parse the argument

| Argument | Runs |
|---|---|
| `full` or none | Phases 2-6, every category |
| `vulns` | Phase 2 vulnerability scans (not gitleaks) + Phase 5 triage |
| `secrets` | gitleaks only |
| `licences` | Phase 4 (bundle rules + licence review) |
| `deprecated` | deprecated-API scan only |
| `freshness` | stack-reference age + `project-coherence.sh` only |
| `--review` | override `review_mode` (gates only) |

A narrowed run is named in the report and **cannot give `CLEAR TO SHIP` for the
product**; the report's verdict line states the scope. `full` is required before
a release.

## 2. Resolve the facts the scope depends on

Read from the resolved config: `stack` (backend, web, site, mobile, deploy,
distribution, tenancy, data) and `review_mode`. Resolve the code roots with
`bash .claude/hooks/yaml-helper.sh resolve_code_root`. These decide which tools
apply.

> **ABSENT DOES NOT MEAN "NOT APPLICABLE".** A layer is skipped only when its
> value is explicitly `none`/`hosted` and the report names the config value. An
> **unset** value is asked (`AskUserQuestion`: Go backend / Ktor backend / web
> app / site / mobile / self-hosted bundle); if unanswerable, run every tool whose
> manifest exists on disk and mark the unset category `NOT ASSESSED - [key] unset
> (set it with /setup-stack)`. A layer with no code root, no manifest or no
> lockfile is `NOT ASSESSED - no manifest under <root>`, never "zero findings".

## 3. Build the inventory (derived, not enumerated)

Search the repository (excluding `.git`, `node_modules`, `vendor`, build
output) and list what exists. The list below says what to look for; the result is
whatever the repository contains, so a new ecosystem is not outside coverage by
being absent from a list.

| Kind | Look for | Used by |
|---|---|---|
| Go | every `go.mod` (and `go.sum`, `go.work`) | govulncheck per module, OSV-Scanner |
| JVM / Android | `gradle.lockfile`, `buildscript-gradle.lockfile`, `gradle/verification-metadata.xml`, version catalogs (`libs.versions.toml`), `build.gradle*` | OSV-Scanner; **no lockfile = unscanned** |
| JS | `pnpm-lock.yaml`, `package-lock.json`, `package.json`, `pnpm-workspace.yaml` | `pnpm audit`, OSV-Scanner, supply-chain settings |
| Swift | `Package.resolved`, `Package.swift`, Xcode project package references | OSV-Scanner attempt; otherwise unscanned |
| Images | `image:` and `FROM` lines in `deploy/hosted/`, `deploy/self-hosted/`, Dockerfiles, compose files, with tag or digest | OSV-Scanner image scan; bundle rules |
| CI | workflow files (action pins), SBOM and scan steps | pin-by-SHA, SBOM check |
| Studio | `docs/stack-reference/pins.yaml`, `docs/stack-reference/*/VERSION.md`, `*/deprecated-apis.md` | freshness, deprecated, coherence |

Print the inventory as a table (kind - path - ecosystem - tool that will scan it).
This table is the **denominator**: Phase 2 reports each row as scanned, unscanned
(with the reason) or not run. A lockfile missing from a tool's own output is
`unscanned`, even when the tool exited 0.

## 4. Record inputs FOUND or ABSENT

| Input | Path | Why |
|---|---|---|
| Resolved config | `project.yaml` via `resolve_config` | scope |
| Pins and tool pins | `docs/stack-reference/pins.yaml` (`tooling.*`) | tool version comparison, coherence |
| Tooling reference | `docs/stack-reference/tooling/best-practices.md`, `VERSION.md` | sourced commands and flags |
| Layer references | `docs/stack-reference/<layer>/{VERSION,deprecated-apis,breaking-changes}.md` | deprecated APIs, freshness |
| Licence decisions | `docs/ROADMAP.md` (L1-L4, T1), `.claude/rules/deploy.md` | bundle rules |
| Earlier audits | `production/qa/dependency-audit-*.md`, `production/qa/security-audit-*.md` | suppressions with expiry, prior findings |
| Studio scripts | `.claude/scripts/project-coherence.sh` | pin drift |

An ABSENT input makes the dependent category `NOT ASSESSED - NO DATA`.

## 5. Report the scope before proceeding

"Auditing [categories] across [roots]; tools: [govulncheck, osv-scanner, pnpm,
gitleaks]; inventory: [N] manifests, [M] lockfiles, [K] images; review mode:
[mode]."
