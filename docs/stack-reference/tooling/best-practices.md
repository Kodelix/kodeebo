# Go backend tooling best practices (golangci-lint v2, gitleaks, OSV-Scanner, govulncheck)

Last verified: 2026-10-11. Sourced items cite the page fetched this session. Items marked *judgement* are recommendations.

## golangci-lint v2

### Config format
- `version: "2"` is required; "The only possible value is '2'". Source: [configuration file](https://golangci-lint.run/docs/configuration/file/).
- Linter selection: `linters.default` (`standard`, `all`, `none`, `fast`), then `linters.enable` / `linters.disable`. Per-linter options: `linters.settings`. File exclusions: `linters.exclusions` (`generated`, `rules`, `paths`, `presets`). Source: [configuration file](https://golangci-lint.run/docs/configuration/file/), [migration guide](https://golangci-lint.run/docs/product/migration-guide/).
- Formatters are separate: `formatters.enable` (`gofmt`, `gofumpt`, `goimports`, `gci`) and `formatters.settings`. They moved out of `linters` in v2. Source: [configuration file](https://golangci-lint.run/docs/configuration/file/), [migration guide](https://golangci-lint.run/docs/product/migration-guide/).
- v1 to v2 migration: `golangci-lint migrate` writes a backup `<name>.bck.<ext>`; comments and unknown fields are dropped and must be re-added by hand. Source: [migration guide](https://golangci-lint.run/docs/product/migration-guide/).
- Renamed or merged linters in v2: `gas`→`gosec`, `goerr113`→`err113`, `gomnd`→`mnd`, `logrlint`→`loggercheck`, `vet`/`vetshadow`→`govet`, `megacheck`/`gosimple`/`stylecheck`→`staticcheck`. Removed: deadcode, execinquery, exhaustivestruct, exportloopref, golint, ifshort, interfacer, maligned, nosnakecase, scopelint, structcheck, tenv, varcheck. Source: [migration guide](https://golangci-lint.run/docs/product/migration-guide/).

### Default-enabled linters (v2.14.0, verified locally)
`golangci-lint help linters`: errcheck, govet, ineffassign, staticcheck, unused. Source: local binary output; [quick start](https://golangci-lint.run/docs/welcome/quick-start/) lists the same five.

### Recommended linters for a SaaS backend (*judgement*, each description sourced from [linters](https://golangci-lint.run/docs/linters/))
- Keep the defaults above.
- `gosec`: security problems in source.
- `bodyclose`: HTTP response bodies closed.
- `noctx`: HTTP calls without `context.Context`.
- `contextcheck`: function uses a non-inherited context.
- `sqlclosecheck`, `rowserrcheck`: SQL rows/statements closed and `Rows.Err` checked.
- `errorlint`: error-wrapping problems (Go 1.13+ `errors.Is`/`As`).
- `nilerr`: returns nil despite checking error is non-nil.
- `wrapcheck`: errors from external packages wrapped.
- `copyloopvar`, `intrange`: unnecessary loop copies and integer ranges (both support autofix).
- `testifylint`: only if testify is used.

### Example config (composed from documented keys; not copied from a page)
```yaml
version: "2"
linters:
  default: standard
  enable:
    - gosec
    - bodyclose
    - noctx
    - contextcheck
    - sqlclosecheck
    - rowserrcheck
    - errorlint
    - nilerr
    - wrapcheck
    - copyloopvar
    - intrange
  exclusions:
    generated: lax
formatters:
  enable:
    - gofmt
    - goimports
```
Run `golangci-lint run ./...`. Confirm linter names against `golangci-lint help linters` on the pinned version (verified locally on 2.14.0). Validation subcommands: NOT SOURCEABLE.

## gitleaks

### Pre-commit (verified against local `gitleaks git --help`)
- Flags: `--pre-commit` ("scan using git diff") and `--staged` ("scan staged commits (good for pre-commit)"). Command: `gitleaks git --pre-commit --staged`.
- Pre-commit framework: the README example sets `rev: v8.24.2` (stale). Set `repo: https://github.com/gitleaks/gitleaks`, hook `id: gitleaks`, run `pre-commit autoupdate`, then `pre-commit install`. Source: [gitleaks README](https://github.com/gitleaks/gitleaks/blob/master/README.md).
- Skip one commit: `SKIP=gitleaks git commit ...` (README).

### CI
- `gitleaks git` scans `git log -p`. Pass commit ranges with `--log-opts`, e.g. `gitleaks git -v --log-opts="--all commitA..commitB" path_to_repo`. Source: [gitleaks README](https://github.com/gitleaks/gitleaks/blob/master/README.md).
- Suggested PR job (*judgement*, built from documented flags): `gitleaks git -v --redact --log-opts="origin/main..HEAD" -f sarif -r gitleaks.sarif`.
- Flags: `--redact` (default 100%; accepts a percent), `-f/--report-format` (`json`, `csv`, `junit`, `sarif`, `template`), `-r/--report-path`, `--exit-code` (default 1 on leaks). Source: local `gitleaks git --help` and [README](https://github.com/gitleaks/gitleaks/blob/master/README.md).
- For non-git trees: `gitleaks dir <path>`. Source: [README](https://github.com/gitleaks/gitleaks/blob/master/README.md).
- Config precedence: `--config`/`-c`, then `GITLEAKS_CONFIG` (path), then `GITLEAKS_CONFIG_TOML` (content), then `.gitleaks.toml` in the target path; otherwise built-in defaults. Source: [README](https://github.com/gitleaks/gitleaks/blob/master/README.md).

### Maintenance status
- README: "feature complete"; future releases are security patches only; focus moving to Betterleaks. Source: [README](https://github.com/gitleaks/gitleaks/blob/master/README.md). Plan a migration decision; Betterleaks version: NOT SOURCEABLE.

## OSV-Scanner (Go, Gradle, npm)

### Commands (from [usage](https://google.github.io/osv-scanner/usage/))
- Source scan (default): `osv-scanner scan -r ./path/`.
- Explicit lockfile: `osv-scanner scan -L package-lock.json --output-file scan-results.txt`; `-L` also accepts `go.mod` or `path/to/package-lock.json`.
- Custom config: `osv-scanner scan -L package-lock.json --config ./osv-scanner.toml`.
- Container image: `osv-scanner scan image <image>:<tag>`.
- Machine output: `--format json`; `--format=vertical` also appears in examples. All other `--format` values: NOT SOURCEABLE (Output page not fetched).
- Remediation: `osv-scanner fix -M path/to/package.json -L path/to/package-lock.json`. The page warns `fix` can run package-manager scripts or reach external registries, so run it only on trusted sources. There is no documented `--fix` flag. Source: usage page.

### Lockfile and manifest support (from [supported languages and lockfiles](https://google.github.io/osv-scanner/supported-languages-and-lockfiles/))
| Ecosystem | Supported | Not listed |
|---|---|---|
| Go | `go.mod` | `go.sum`, `go.work` |
| Gradle | `gradle.lockfile`, `buildscript-gradle.lockfile`, `gradle/verification-metadata.xml` | `build.gradle`, `settings.gradle` variants |
| npm | `package-lock.json` | `npm-shrinkwrap.json`, `package.json` |

Caveat from the same page: manifests can declare version ranges, so extracted versions are best-effort. Prefer the resolved lockfile.

### Recommended usage (*judgement*)
- Scan the repo root recursively in CI: `osv-scanner scan -r .` (or `scan source --recursive .` as in the pre-commit examples).
- Fail CI on findings; keep the lockfile committed so results match what is installed.

## govulncheck (Go)
- Install: `go install golang.org/x/vuln/cmd/govulncheck@latest`. Run: `govulncheck ./...`. Reports only vulnerabilities whose functions your code reaches. Source: [govulncheck doc](https://go.dev/doc/security/vuln/).
- `-json` gives streaming JSON; exit code 0 whether or not findings exist (so parse output in CI). `-mode binary` scans a compiled binary. Source: [pkg.go.dev govulncheck](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck).
- The security best-practices page also points to a GitHub Action and `-json` for CI. Source: [security best practices](https://go.dev/doc/security/best-practices).

## Not sourced
- `golangci-lint config verify` subcommand: NOT SOURCEABLE — not on the fetched pages.
- govulncheck Go version requirement: NOT SOURCEABLE — not stated on the fetched pages.
- OSV-Scanner `--format` values other than `json`/`vertical`: NOT SOURCEABLE.
- Betterleaks replacement version: NOT SOURCEABLE.
