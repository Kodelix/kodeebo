# Go backend best practices (Go 1.27 line, pgx v5.11.0)

Last verified: 2026-10-11. Every bullet cites a page fetched this session. Items marked *judgement* are recommendations built on sourced facts, not a documented rule.

## Toolchain pin
- Latest patch: go1.27.2 (2026-10-08). Go 1.26 is still supported; support lasts until two newer major releases ship. Source: [release history](https://go.dev/doc/devel/release).
- `go mod init` writes a go line one minor lower (`go 1.25.0` on Go 1.26). Set the line explicitly with `go get go@1.27.x`. Source: [go1.26 notes](https://go.dev/doc/go1.26).
- *Judgement:* pin `go 1.27.x` in go.mod and `GOTOOLCHAIN=local` in CI so builds use the image's compiler.

## net/http routing (ServeMux, Go 1.22+ patterns)
- Method prefix before path: `GET /posts/{id}`. A GET pattern also matches HEAD. Other methods match exactly. Unmatched methods return 405 with an `Allow` header.
- `{name}` matches one segment; read it with `req.PathValue("name")`. `{name...}` matches the remaining segments.
- `{$}` matches only the trailing-slash path (`/posts/{$}` matches `/posts/`, not `/posts`).
- Most specific pattern wins (`/posts/latest` beats `/posts/{id}`). Patterns that overlap without either being more specific **panic at registration** (startup), in either order. Source: [routing enhancements](https://go.dev/blog/routing-enhancements).
- Trailing-slash redirects are 307 since Go 1.26. Source: [go1.26 notes](https://go.dev/doc/go1.26).

## net/http server timeouts
- `ReadTimeout`: whole request including body; zero or negative = none.
- `ReadHeaderTimeout`: headers only; if zero, `ReadTimeout` is used.
- `WriteTimeout`: response writes; zero or negative = none.
- `IdleTimeout`: keep-alive wait; if zero, `ReadTimeout` is used.
- Consequence: if you set only `ReadHeaderTimeout`, `IdleTimeout` and `ReadTimeout` stay unlimited unless set. Set all four explicitly. Source: [net/http Server](https://pkg.go.dev/net/http#Server).
- CSRF for browser-facing handlers: `net/http.CrossOriginProtection` (Fetch metadata, no tokens or cookies), added in Go 1.25. Source: [go1.25 notes](https://go.dev/doc/go1.25).
- Go 1.27 `Server.MaxHeaderValueCount` caps header values; `DefaultMaxHeaderValueCount` applies when unset. Source: [go1.27 notes](https://go.dev/doc/go1.27).

## log/slog
- Key-value convention: `slog.Info("msg", "user", id)`. A vet check flags common mistakes in these pairs. Source: [slog blog](https://go.dev/blog/slog).
- Production output: `slog.New(slog.NewJSONHandler(os.Stdout, nil))`. Source: [slog blog](https://go.dev/blog/slog).
- Hot paths: `slog.LogAttrs` with `slog.Attr` values to reduce allocations. Source: [slog blog](https://go.dev/blog/slog).
- Common fields: `Logger.With(...)` attaches attributes to all output. Source: [slog blog](https://go.dev/blog/slog).
- Redaction and structured values: implement `LogValue()` on the type (`LogValuer`). Source: [slog blog](https://go.dev/blog/slog).
- Context-aware: `slog.LogAttrs(ctx, ...)` lets a handler read request values such as trace IDs. Canceling `ctx` does not stop the entry being written. Source: [slog blog](https://go.dev/blog/slog).
- Fan-out to several handlers: `slog.NewMultiHandler` (Go 1.26). Source: [go1.26 notes](https://go.dev/doc/go1.26).
- Custom handlers: `Enabled` drops events early; `WithAttrs`/`WithGroup` pre-format once. Verify with `testing/slogtest`. Source: [slog blog](https://go.dev/blog/slog).

## context
- Pass `context.Context` as the first argument on the request path. Source: [context blog](https://go.dev/blog/context).
- Always call the cancel func (`defer cancel()`); WithTimeout timers hold resources until cancel. Source: [context blog](https://go.dev/blog/context).
- Cancel on a parent cancels all derived contexts. Done closes on cancel; `Err()` says why. Source: [context blog](https://go.dev/blog/context).
- Context values carry request-scoped data only; must be concurrency-safe. Source: [context blog](https://go.dev/blog/context).
- Tests: `t.Context()` (added Go 1.24) is canceled just before `Cleanup` functions run. Source: [testing T.Context](https://pkg.go.dev/testing#T.Context).

## Concurrency
- Bounded fan-out with errors: `errgroup.WithContext`, `g.SetLimit(n)`, `g.Go`, `g.Wait`. The derived context cancels at the first non-nil error or when `Wait` returns. `SetLimit` blocks `Go` when at the cap. Do not change the limit while goroutines are active. `TryGo` returns false instead of blocking. Source: [errgroup](https://pkg.go.dev/golang.org/x/sync/errgroup) (latest shown v0.24.0, 2026-09-23).
- `sync.WaitGroup.Go` (Go 1.25) starts and counts a goroutine in one call; use it when no error propagation is needed. Source: [go1.25 notes](https://go.dev/doc/go1.25).
- Worker sizing: since Go 1.25 `GOMAXPROCS` follows the Linux cgroup CPU limit in containers. Source: [go1.25 notes](https://go.dev/doc/go1.25).
- Leak detection: `goroutineleak` profile GA in Go 1.27 at `/debug/pprof/goroutineleak`. Reachability-based; can miss leaks held via globals. Source: [go1.27 notes](https://go.dev/doc/go1.27).
- *Judgement:* prefer `errgroup` with `SetLimit` over unbounded `go` statements for DB or outbound-HTTP fan-out.

## pgx v5 pool (`github.com/jackc/pgx/v5/pgxpool`)
- Construct: `pgxpool.New(ctx, connString)` or `pgxpool.ParseConfig` then pool creation. Source: [pgxpool](https://pkg.go.dev/github.com/jackc/pgx/v5/pgxpool).
- Defaults from `ParseConfig`: `pool_max_conns` = max(4, NumCPU); `pool_max_conn_lifetime` = 1h; `pool_max_conn_idle_time` = 30m; `pool_health_check_period` = 1m; `pool_min_conns` = 0. Source: [pgxpool](https://pkg.go.dev/github.com/jackc/pgx/v5/pgxpool).
- Since 5.11.0 a non-positive `MaxConnLifetime` means unlimited. Source: [pgx CHANGELOG](https://github.com/jackc/pgx/blob/master/CHANGELOG.md).
- `Pool.Close` closes all connections, rejects new `Acquire`, and blocks until connections are returned and closed. Source: [pgxpool](https://pkg.go.dev/github.com/jackc/pgx/v5/pgxpool).
- Transactions: `Pool.Begin` is listed; `Pool.BeginFunc` is not listed on the fetched page. Source: [pgxpool](https://pkg.go.dev/github.com/jackc/pgx/v5/pgxpool).
- Placeholders: positional `$1, $2, ...` with arguments passed to `Exec`/`Query`. Source: [pgx Conn.Query](https://pkg.go.dev/github.com/jackc/pgx/v5#Conn.Query).
- Statement cache: default mode `cache_statement`, capacity 512; queries run through `Conn.Query`/`QueryRow`/`Exec` are prepared automatically on first use. Source: [pgx Conn.Query](https://pkg.go.dev/github.com/jackc/pgx/v5#Conn.Query), [ParseConfig](https://pkg.go.dev/github.com/jackc/pgx/v5/pgxpool).
- Use pgx >= 5.9.2 (SQL injection fix for dollar-quoted literals under simple protocol). Source: [pgx CHANGELOG](https://github.com/jackc/pgx/blob/master/CHANGELOG.md).

## Security and supply chain
- `govulncheck ./...` reports only vulnerabilities whose functions your code reaches. Run in CI; `-json` for machine output (exit code 0 either way). Sources: [govulncheck doc](https://go.dev/doc/security/vuln/), [pkg.go.dev govulncheck](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck).
- Stay on the latest Go minor; point releases carry security fixes. Review each dependency update before merging. Source: [security best practices](https://go.dev/doc/security/best-practices).
- Fuzz input-handling code (coverage-guided fuzzing). Source: [security best practices](https://go.dev/doc/security/best-practices).
- Module integrity: `go.sum` records checksums; `go mod verify` checks the module cache against downloaded hashes. Default `GOPROXY` is `https://proxy.golang.org,direct`; default `GOSUMDB` is `sum.golang.org`. Sources: [go.dev/ref/mod](https://go.dev/ref/mod).
- Go 1.27 TLS: `Config.Rand` deprecated. Go 1.26: PQ hybrid TLS on by default; keep current. Sources: [go1.27 notes](https://go.dev/doc/go1.27), [go1.26 notes](https://go.dev/doc/go1.26).

## Testing
- Table-driven tests: a slice of cases with a `name` field, `t.Run(tt.name, ...)` per case, `t.Parallel()` inside subtests. Failure messages include input, got, and want. `t.Errorf` continues; `t.Fatalf` stops the subtest. Source: [TableDrivenTests wiki](https://go.dev/wiki/TableDrivenTests).
- Loop variable copy (`tt := tt`) is needed only before Go 1.22. Source: [TableDrivenTests wiki](https://go.dev/wiki/TableDrivenTests).
- Race detector: `go test -race ./...`. Only finds races on executed paths. Overhead: 2–20x time, 5–10x memory. Source: [race detector](https://go.dev/doc/articles/race_detector).
- `testing/synctest` GA (Go 1.25): `synctest.Test(t, f)` runs `f` in an isolated bubble with virtual time; `synctest.Wait()` waits until goroutines in the bubble are durably blocked; `synctest.Sleep(d)` (Go 1.27) = sleep + wait. Source: [pkg.go.dev testing/synctest](https://pkg.go.dev/testing/synctest), [go1.25 notes](https://go.dev/doc/go1.25).
- `httptest.NewTestServer` (Go 1.27) uses an in-memory network for synctest-based HTTP tests. Source: [go1.27 notes](https://go.dev/doc/go1.27).
- `testing.T.ArtifactDir` (Go 1.26) returns a per-test output directory; kept only with `go test -artifacts`. Source: [go1.26 notes](https://go.dev/doc/go1.26).
- `testing/cryptotest.SetGlobalRandom` (Go 1.26) gives deterministic randomness for `crypto/rand` in tests. Source: [go1.26 notes](https://go.dev/doc/go1.26).
- `testing.AllocsPerRun` panics when parallel tests run. Source: [go1.25 notes](https://go.dev/doc/go1.25).
- `go test` runs the `stdversion` vet check by default (Go 1.27). Source: [go1.27 notes](https://go.dev/doc/go1.27).

## Not sourced
- Go 1.27 `log/slog` and `context` changes: NOT SOURCEABLE beyond the 1.27 notes, which list none.
- `html/template` vs `text/template` escaping guidance, input-validation patterns, and SQL placeholder examples beyond pgx `$n`: NOT SOURCEABLE — the security best-practices page does not cover them.
- Go 1.28 release date: NOT SOURCEABLE — not stated at https://go.dev/doc/devel/release.
