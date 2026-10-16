---
paths:
  - "backend/**/*.go"
  - "**/go.mod"
---

# Go Backend Rules

Read `docs/stack-reference/go/` before using any API newer than you are sure of.
Layering per `.claude/docs/clean-architecture.md`.

- `internal/<context>/{domain,app,adapters}`; `domain` imports only the standard library and other domain packages.
- `context.Context` is the first parameter of every function that does I/O or may block; never store it in a struct.
- Interfaces are declared where they are **consumed** (in `app`), small (1–3 methods). Return concrete types.
- Errors: wrap with `fmt.Errorf("...: %w", err)`; compare with `errors.Is/As`; sentinel or typed errors in `domain`; map to RFC 9457 only in the HTTP adapter. Never `panic` for control flow; recover only at the server edge.
- Concurrency: every goroutine has an owner, a cancellation path and a bound (`errgroup` with `SetLimit`, worker pools). No fire-and-forget goroutines in request paths. Run `-race` in CI.
- No package-level mutable state; no `init()` side effects beyond registration. Dependencies are wired in `cmd/<binary>/main.go`.
- HTTP server: `ReadHeaderTimeout`, `ReadTimeout`, `WriteTimeout`, `IdleTimeout` set; body size limited (`http.MaxBytesReader`); graceful shutdown on SIGTERM.
- HTTP clients: never `http.DefaultClient`; explicit timeout, transport limits, OTel instrumentation.
- Database: `pgx` pool with explicit limits; parameterized queries only; transactions via a unit-of-work port; `rows.Close()` and `rows.Err()` always checked.
- Logging: `log/slog` JSON handler with `trace_id`; no `fmt.Println`/`log.Printf` in production code.
- Config: parsed once at startup into a typed struct, validated, fail fast on missing values.
- Lint: `gofmt`, `go vet`, `golangci-lint` (config in repo), `govulncheck` — all clean before commit.
- Tests: table-driven, `t.Parallel()` where safe, Testcontainers for adapters behind the `integration` build tag.
