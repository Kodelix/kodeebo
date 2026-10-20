# /security-audit — Scanners

> Phase 3 (categories 8 and 9) and Phase 5 of `SKILL.md`. The audit **runs the
> scanners and reports their real output**. A scanner that did not run is
> `not run — [reason]` and is a **failed check, never a clean one**
> (`SL-RELEASE-SECURITY` check 2 counts it as a failure).

Versions come from `docs/stack-reference/pins.yaml` (`tooling.gitleaks`,
`tooling.govulncheck`, `tooling.osv_scanner`) and
`docs/stack-reference/tooling/VERSION.md`. Commands below are the ones sourced
in `docs/stack-reference/tooling/best-practices.md`; anything not there is
`NOT SOURCEABLE` and goes to `/research` — do not improvise flags.

**Before each run**
0. Dates in saved file names come from `date +%F`.
1. `command -v <tool>`. Absent → `not run — <tool> not installed`. Offer the
   install command the reference gives (govulncheck: `go install
   golang.org/x/vuln/cmd/govulncheck@latest`); **do not install without the
   user's yes**. OSV-Scanner has no install command in the reference →
   `NOT SOURCEABLE — install method`; ask the user.
2. Record the tool's reported version next to the pinned one. `gitleaks version`
   prints `version is set by build process` on the packaged binary — then the
   package manager's version is the only check; say so.
3. Run from the repository root unless a directory is stated. Save raw output; the
   report quotes it (secrets redacted) and Phase 6 offers to write it to
   `production/qa/evidence/security-audit-[date]-[scope]/`.
4. Scanning reads the user's own repository and local images only; no scanner is
   pointed at a host the user did not name.

## gitleaks — secrets (category 8)

```bash
gitleaks git -v --redact --log-opts="<base>..HEAD" -f json -r <out>.json
gitleaks dir . --redact -f json -r <out-tree>.json
```
- `--redact` is mandatory **for gitleaks** (it is a gitleaks flag; the other scanners
  have none and print no secret values); the report never carries a secret value (rule ID,
  file, line, commit only).
- `<base>` is the previous release tag or `origin/main`; a full-history scan is
  `gitleaks git` with no `--log-opts` restriction when the user asks for it.
- `dir` covers the working tree (untracked files). Exit code 1 means leaks found
  (`--exit-code` default); any finding is reported with the rule ID.
- Any real secret found: capture the minimal evidence (rule ID, file, line, commit,
  where exposed; never the value; time-boxed, 15 minutes by default), **then rotate**,
  then remove; rotation is never held back for fuller forensics. History rewriting is the
  user's decision. Record the rotation, or `rotation: not done` as an open
  CRITICAL.
- Maintenance note carried from the reference: gitleaks receives security
  patches only; standing decision T1 (`.claude/docs/standing-decisions.md`) keeps it for now.

## govulncheck — Go dependencies (category 9)

```bash
# run from inside backend/ by appsec-engineer (no directory flag is sourced, so no `cd && …` compound)
govulncheck ./...
govulncheck -json ./...        # parse this; exit code is 0 either way
govulncheck -mode binary <built-binary>      # for a release artifact
```
- Applies when `stack.backend` is `go` or `go+ktor`. Otherwise
  `not applicable — no Go backend` (stated, with the stack value).
- **Exit 0 does not mean clean**: read the output. It reports only
  vulnerabilities whose functions the code reaches — record the reachable ones
  as findings and the "present but not reachable" ones as such, with the output
  that says so.
- A multi-module repo is scanned per module (each `go.mod` found under the Go
  code root).

## OSV-Scanner — all ecosystems (category 9)

```bash
osv-scanner scan -r .
osv-scanner scan -L <lockfile> --output-file <out>.txt
osv-scanner scan image <image>:<tag>         # container images
osv-scanner scan -r . --format json
```
- **Supported lockfiles per the reference**: `go.mod`; Gradle `gradle.lockfile`,
  `buildscript-gradle.lockfile`, `gradle/verification-metadata.xml`; npm
  `package-lock.json`. **Not in the sourced table**: `pnpm-lock.yaml` (the SPA's
  lockfile) and SwiftPM `Package.resolved`. They are reported
  **`unscanned`** by name, and the dependency inventory lists them as such. Do
  not claim OSV-Scanner covered them. The `pnpm` audit command from
  `docs/stack-reference/vite-react/best-practices.md` §11 and `/dependency-audit`
  are the follow-ups; a pnpm audit that was not run is `not run`.
- **Gradle**: with no committed Gradle lockfile the JVM/Android dependencies are
  unscanned (manifests give version ranges, "best-effort" per the reference) —
  say `unscanned: no Gradle lockfile`.
- **Never run `osv-scanner fix`**: the reference warns it can run package-manager
  scripts and reach registries.
- `--format` values other than `json` and `vertical`: NOT SOURCEABLE.

## Container image scan (category 9)

- Images in the release: list from `deploy/hosted/` and `deploy/self-hosted/`
  compose files (image names with digests). Scan each with `osv-scanner scan
  image <image>:<tag>` unless an ADR chose another image scanner — then use that
  tool's documented command from `/research`, never from memory.
- An image that is not present locally and cannot be pulled by the user's
  approval: `not scanned — image unavailable`.
- Base-image digest pinning and non-root/read-only checks are read from the
  Dockerfiles and compose files (`.claude/rules/deploy.md`), not by the scanner.

## SBOM and provenance (category 9)

CycloneDX SBOM per release is a baseline requirement. The generator is not
sourced in `docs/stack-reference/tooling/` — check the CI/release config for an
SBOM step and for the stored artifact; absent → `SBOM: not generated` (a finding
at release time), generator choice `NOT SOURCEABLE` → `/research`. Compose-level
SBOM/provenance guidance: `docs/stack-reference/docker-compose/best-practices.md` §5.

## Triage rules

- Reachability first (govulncheck), then exposure (internet-facing vs internal),
  then data class. CVSS base score alone never sets severity.
- A suppression names finding ID, reason, owner and **expiry date**; blanket
  ignores are a finding.
- Severity → fix window from triage: critical 48 h, high 7 d, medium 30 d, low
  90 d (`security-lead` policy).
- Output of every scanner is summarised in the report's **Scans** table:
  tool — version — command — scope — result (`N findings` / `clean` / `not run:
  reason`) — unscanned items.
