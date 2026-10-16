# Go (language, toolchain, stdlib) + pgx + Redis clients — Version Reference

Last verified: 2026-10-11. Every claim below was fetched this session; anything unfetched is marked `NOT SOURCEABLE`.

## Pinned versions

| Item | Value |
|---|---|
| Current stable Go | **go1.27.2** (minor, 2026-10-08) on the **Go 1.27** line; go1.27.0 released **2026-08-19** — [go.dev/doc/devel/release](https://go.dev/doc/devel/release) |
| Previous supported line | go1.26.9 (2026-10-08); go1.26.0 released 2026-02-10 — same page |
| Out of support | Go 1.25 (go1.25.14, 2026-08-19 was its last listed point release). Policy below implies 1.25 is EOL since 1.27.0 shipped |
| Support policy | "Each major Go release is supported until there are two newer major releases." Security/critical fixes arrive as minor revisions — [release page](https://go.dev/doc/devel/release). So 1.27 and 1.26 are supported today; 1.26 is EOL when Go 1.28 ships (Go 1.28 date: NOT SOURCEABLE — not stated on the release page) |
| Recommended pin (new products) | Toolchain **go1.27.2**; `go 1.27.0` directive in go.mod for applications (the `go` line is a hard minimum, see [toolchain doc](https://go.dev/doc/toolchain)); CI/Docker with `GOTOOLCHAIN=local` and an image pinned to 1.27.x. Judgement call: 1.27 is the newest line and all pinned libs below support it |
| pgx | **v5.11.0**, 2026-09-07 (Go proxy `Time` 2026-09-07T23:39:32Z; [CHANGELOG](https://github.com/jackc/pgx/blob/master/CHANGELOG.md)). Module `github.com/jackc/pgx/v5`. Min Go **1.25** (since 5.9.0). Pin v5.11.0 (>= v5.9.2 required: SQLi fix) |
| go-redis | **v9.23.0**, 2026-10-05 ([GitHub API](https://api.github.com/repos/redis/go-redis/releases), proxy.golang.org). Module `github.com/redis/go-redis/v9`. **Min Go 1.26** as of 9.23.0. Supports Redis 8.0–8.10 officially ([README](https://github.com/redis/go-redis)). Previous: v9.22.0 (2026-08-03, still go 1.24 directive) |
| rueidis | **v1.0.78**, 2026-09-15 ([GitHub API](https://api.github.com/repos/redis/rueidis/releases), proxy). go.mod `go 1.25.0`. Module `github.com/redis/rueidis` |
| Installed locally | `go version go1.27.1-X:nodwarf5 linux/amd64` (pacman `go 2:1.27.1-2`; **one patch behind go1.27.2**). pgx/go-redis/rueidis are library deps: not installed (no go.mod checked) |
| Last verified | 2026-10-11 |

## Verified sources
- https://go.dev/doc/devel/release (versions, dates, support policy)
- https://go.dev/doc/go1.27 , https://go.dev/doc/go1.26 , https://go.dev/doc/go1.25 , https://go.dev/doc/go1.24 (release notes; 1.27 claims cross-checked by grepping the raw page for `uuid`, `goroutineleak`, `encoding/json/v2`, `CutLast`, `stdversion`, `MaxHeaderValueCount`)
- https://go.dev/doc/toolchain , https://go.dev/doc/pgo , https://go.dev/blog/routing-enhancements , https://go.dev/blog/slog , https://go.dev/blog/synctest , https://go.dev/blog/greenteagc , https://go.dev/blog/flight-recorder , https://go.dev/doc/security/best-practices
- https://github.com/jackc/pgx/blob/master/CHANGELOG.md , https://pkg.go.dev/github.com/jackc/pgx/v5 , https://pkg.go.dev/github.com/jackc/pgx/v5/pgxpool
- https://github.com/redis/go-redis/releases (+ README), https://github.com/redis/rueidis/releases (+ README)
- Release dates for libs: GitHub releases API + proxy.golang.org `@latest` JSON (exact timestamps).

## Knowledge gap warning (post mid-2024 — assume you do NOT know these)
- **Go 1.24 (2025-02-11)**: generic type aliases, Swiss-table maps, `tool` directive in go.mod (`go get -tool`, `go tool`), `os.Root`, `testing.B.Loop`, `T.Context`, `weak`, `runtime.AddCleanup`, `strings.SplitSeq/Lines`, `omitzero`, `crypto/mlkem|hkdf|pbkdf2|sha3`.
- **Go 1.25 (2025-08-12)**: container-aware `GOMAXPROCS`, `testing/synctest` GA, `sync.WaitGroup.Go`, `runtime/trace.FlightRecorder`, `net/http.CrossOriginProtection`, `encoding/json/v2` experiment, Green Tea GC experiment, nil-check bug fix (Go 1.21 bug) now panics correctly.
- **Go 1.26 (2026-02-10)**: `new(expr)`, self-referential generic constraints, Green Tea GC default, rewritten `go fix` (modernizers, `//go:fix inline`), `errors.AsType`, `slog.NewMultiHandler`, ServeMux trailing-slash redirect now 307, `net/url` strict colons, `testing.T.ArtifactDir`, `go mod init` writes `go 1.(N-1).0`.
- **Go 1.27 (2026-08-19)**: generic methods, `encoding/json/v2` + `jsontext` GA, goroutine leak profile GA, `uuid` package, `asynctimerchan` etc. GODEBUGs removed, `go test` runs `stdversion` vet, HTTP/1 body auto-drain, bzr removed, macOS 13+.
- **pgx 5.8–5.11 (Dec 2025–Sep 2026)**: Go 1.24→1.25 minimums, SCRAM-PLUS/OAuth/protocol 3.2, `require_auth`, SQLi advisory GHSA-j88v-2chj-qfwx (5.9.2), libpq-exact connection-string parsing and new date/time parser (5.11.0).
- **go-redis 9.21–9.23 (Jun–Oct 2026)**: auto-pipelining, client-side caching (experimental), maintenance notifications, Go 1.26 minimum, RESP3 default.
- Tooling: see `../tooling/VERSION.md` (gitleaks `git`/`dir`, golangci-lint v2 config).
