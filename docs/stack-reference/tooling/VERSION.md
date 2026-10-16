# Go backend tooling — Version Reference

Last verified: 2026-10-11. Release data fetched this session from GitHub (`gh api`), pkg.go.dev, and the local machine.

## Pinned versions

| Tool | Latest release | Release date | Link | Installed locally |
|---|---|---|---|---|
| golangci-lint | **v2.14.0** | 2026-09-24 | [release](https://github.com/golangci/golangci-lint/releases/tag/v2.14.0) | **2.14.0** (`golangci-lint --version`; built with go1.27.1). pacman package `golangci-lint 2.14.0-1.1`. Matches latest. |
| govulncheck (`golang.org/x/vuln/cmd/govulncheck`) | **v1.8.0** | 2026-09-08 (per pkg.go.dev) | [pkg.go.dev](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck), [tag v1.8.0](https://github.com/golang/vuln/releases/tag/v1.8.0) | **NOT INSTALLED** — `govulncheck` not on PATH, not in pacman, no `~/go/bin`. Install: `go install golang.org/x/vuln/cmd/govulncheck@latest`. |
| gitleaks | **v8.30.1** | 2026-03-21 | [release](https://github.com/gitleaks/gitleaks/releases/tag/v8.30.1) | `/usr/bin/gitleaks`; pacman package `gitleaks 8.30.1-1.1`. `gitleaks version` prints `version is set by build process` (binary has no embedded version), so the package version is the only check. Matches latest. |
| OSV-Scanner | **v2.6.0** | 2026-09-14 | [release](https://github.com/google/osv-scanner/releases/tag/v2.6.0) | **NOT INSTALLED** — not on PATH, not in pacman. |

## Status flags
- **gitleaks maintenance:** the README states Gitleaks is feature complete, will receive security patches only, and the author is shifting focus to Betterleaks. Source: [gitleaks README](https://github.com/gitleaks/gitleaks/blob/master/README.md). Which Betterleaks version to adopt: NOT SOURCEABLE (not researched; decision for the project owner).
- **govulncheck version:** pkg.go.dev marks v1.8.0 as "Latest" but also notes it is not the module's latest version. Tag `v1.8.0` exists on GitHub. Treat v1.8.0 as current until confirmed.

## Sources
- golangci-lint v2 config and migration: https://golangci-lint.run/docs/configuration/file/ , https://golangci-lint.run/docs/product/migration-guide/ , https://golangci-lint.run/docs/welcome/quick-start/
- golangci-lint release: `gh api repos/golangci/golangci-lint/releases/latest`
- gitleaks README: https://github.com/gitleaks/gitleaks/blob/master/README.md ; `gitleaks git --help` (local binary)
- gitleaks release: `gh api repos/gitleaks/gitleaks/releases/latest`
- govulncheck: https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck , https://go.dev/doc/security/vuln/
- OSV-Scanner: https://google.github.io/osv-scanner/usage/ , https://google.github.io/osv-scanner/supported-languages-and-lockfiles/
- OSV-Scanner release: `gh api repos/google/osv-scanner/releases/latest`

## Not sourced
- OSV-Scanner `--format` values beyond `json` and `vertical`: NOT SOURCEABLE — the usage page refers to an Output page not fetched.
- Gitleaks `v8.30.1` vs newer Betterleaks release: NOT SOURCEABLE — not researched.
