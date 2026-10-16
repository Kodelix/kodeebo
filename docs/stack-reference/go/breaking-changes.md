# Go backend: breaking and behaviour changes (Go 1.25, 1.26, 1.27 + pgx 5.9.2–5.11.0)

Last verified: 2026-10-11. All items fetched this session. Items marked *behaviour* can break code without a compile error.

Sources: [go1.25](https://go.dev/doc/go1.25), [go1.26](https://go.dev/doc/go1.26), [go1.27](https://go.dev/doc/go1.27), [release history](https://go.dev/doc/devel/release), [pgx CHANGELOG](https://github.com/jackc/pgx/blob/master/CHANGELOG.md), [pgx README (Go 1.25+ support)](https://pkg.go.dev/github.com/jackc/pgx/v5).

## Go 1.27 (released 2026-08-19; current patch go1.27.2, 2026-10-08)

| Area | Change | Type |
|---|---|---|
| net/http | HTTP/1 `Response.Body.Close` now drains unread content up to a limit. Servers with many idle connections may slow down. `Transport.DisableKeepAlives` turns reuse off. | behaviour |
| net/http | HTTP/2 server honours client priority (RFC 9218). `Server.DisableClientPriority = true` restores round-robin. | behaviour |
| net/http | New `Server.MaxHeaderValueCount`; `DefaultMaxHeaderValueCount` applies when unset. | new limit |
| net/http/httptest | `NewTestServer` uses an in-memory fake network for `testing/synctest`. | new |
| encoding/json | Now implemented on v2. Marshal roughly unchanged, unmarshal significantly faster. Error text may differ. v1 semantics restorable via new `Options`. Opt out with `GOEXPERIMENT=nojsonv2` (to be removed later). | behaviour |
| encoding/json/v2 | v2 rejects invalid UTF-8 and duplicate object names by default. Removed in v2: `format` and `unknown` tag options, `DiscardUnknownMembers`, `SkipFunc` sentinel. `inline` tag renamed `embed`; `string` tag option and `MatchCaseInsensitiveNames` changed. | breaking (v2 only) |
| compress/flate, gzip, zlib, zip, png | Faster compression, but output bytes can differ. ETags or checksums computed from compressed bytes may change. | behaviour |
| net | `UnixConn` Read methods return `io.EOF` directly, not wrapped in `net.OpError`. Code checking wrapped EOF must change. | behaviour |
| crypto/tls | `Config.Rand` deprecated. ML-DSA in TLS 1.3, `MLKEM1024` key exchange added. | deprecation |
| go command | `bzr`-hosted modules can no longer be fetched. | breaking |
| go command | Removed GODEBUG settings in `go.mod` `godebug` lines or `//go:debug` now fail the build unless set to their final default. | breaking |
| go command | `go mod tidy` (modules declaring go 1.27+) merges require blocks into at most two (direct, indirect). | behaviour |
| go test | Runs the `stdversion` vet check by default (flags std symbols newer than the file's Go version). | behaviour |
| go vet | printf analyzer flags `%w` with a pointer-to-error operand; can break `errors.Is` and type assertions. | vet error |
| go fix | Adds modernizers; `fmtappendf` removed; `waitgroup` renamed `waitgroupgo`. | tooling |
| gofmt | Column alignment logic changed; minor whitespace diffs possible. | behaviour |
| runtime | `goroutineleak` profile GA (`runtime/pprof`, `/debug/pprof/goroutineleak`). Reachability-based; can miss leaks reachable via globals. | new |
| runtime | Small allocations (<80 B) up to 30% cheaper; binary ~60 KB larger. Opt out `GOEXPERIMENT=nosizespecializedmalloc` (expected removal Go 1.28). | behaviour |
| runtime | Tracebacks include pprof goroutine labels for modules declaring go 1.27+. Disable with `tracebacklabels=0`. | behaviour |
| os / platform | macOS 13 or later required. | platform |
| tooling | `go tool trace -http=:port` now listens on localhost only. | behaviour |
| GODEBUG removed | `asynctimerchan` (time channels always unbuffered), `gotypesalias`, `tlsunsafeekm`, `tlsrsakex`, `tls3des`, `tls10server`, `x509keypairleaf`. | breaking |
| testing/synctest | `Sleep` added (= `time.Sleep` + `synctest.Wait`). | new |

## Go 1.26 (released 2026-02-10)

| Area | Change | Type |
|---|---|---|
| net/http ServeMux | Trailing-slash redirects are 307, not 301. | behaviour |
| net/http Client | Cookies scoped to `Request.Host` when available, not connection address host. | behaviour |
| net/http | `HTTP2Config.StrictMaxConcurrentRequests` added. `Transport.NewClientConn` added. | new |
| net/http/httputil | `ReverseProxy.Director` deprecated in favour of `Rewrite` (client can strip headers `Director` adds). | deprecation |
| net/url | `Parse` rejects malformed hosts with colons (`http://::1/`, `http://localhost:80:80/`). Bracketed IPv6 still works. Restore with `GODEBUG=urlstrictcolons=0`. | behaviour |
| log/slog | `NewMultiHandler` added (fan-out; `Enabled` true if any handler enabled). | new |
| errors | `AsType` generic, type-safe, faster alternative to `As`. | new |
| testing | `T`/`B`/`F.ArtifactDir` added. `B.Loop` no longer blocks inlining, so benchmark results may change. | behaviour |
| testing/cryptotest | `SetGlobalRandom` added for deterministic `crypto/rand`. | new |
| go command | `go mod init` writes one minor version lower (`go 1.25.0`). Change with `go get go@version`. | behaviour |
| go command | `go fix` rewritten on the vet analysis framework (modernizers, `//go:fix inline`). | tooling |
| cmd/doc | Deleted. Use `go doc`. | breaking |
| runtime | Green Tea GC default-on. Opt out `GOEXPERIMENT=nogreenteagc`. | behaviour |
| crypto/tls | Hybrid PQ key exchanges (`SecP256r1MLKEM768`, `SecP384r1MLKEM1024`) on by default. Disable via `Config.CurvePreferences` or `GODEBUG=tlssecpmlkem=0`. | behaviour |
| crypto | `random` parameter ignored in `GenerateKey`, `Sign`, `EncryptPKCS1v15`, `rand.Prime` and similar. Use `SetGlobalRandom` or `GODEBUG=cryptocustomrand=1`. | behaviour |
| os/signal | `NotifyContext` cancels with a cause identifying the signal. | behaviour |
| net | `Dialer.DialTCP/DialUDP/DialIP/DialUnix` accept a context. | new |
| platform | macOS 12 last supported; ELFv1 linux/ppc64 last supported; 32-bit `windows/arm` removed. | platform |

## Go 1.25 (released 2025-08-12)

| Area | Change | Type |
|---|---|---|
| runtime | `GOMAXPROCS` follows Linux cgroup CPU bandwidth limit (container-aware), updated periodically. Disable with `GOMAXPROCS` set manually or `containermaxprocs=0`, `updatemaxprocs=0`. `runtime.SetDefaultGOMAXPROCS` restores default. | behaviour |
| testing/synctest | GA. Old `GOEXPERIMENT=synctest` API removed in Go 1.26. | GA / removal |
| testing | `AllocsPerRun` panics if parallel tests are running. | behaviour |
| compiler | Nil-check fix: code that uses a result before checking `err` now panics as the spec requires. Check `err` directly after the call. | behaviour |
| panic output | Recovered-and-repanicked value prints as `panic: PANIC [recovered, repanicked]`. | behaviour |
| crypto/tls | SHA-1 signature algorithms disallowed in TLS 1.2. Re-enable `GODEBUG=tlssha1=1`. Clients and servers stricter on spec compliance. | behaviour |
| crypto/x509 | Missing `SubjectKeyId` populated with truncated SHA-256 (`x509sha256skid=0` reverts). `ParseCertificate` rejects negative `pathLenConstraint`. | behaviour |
| compiler | More slice backing stores allocated on stack; can expose incorrect `unsafe.Pointer` use. | behaviour |
| platform | macOS 12 Monterey or later required. | platform |

## pgx v5 (Go module `github.com/jackc/pgx/v5`; supports Go 1.25+)

| Version (date) | Breaking or behaviour changes |
|---|---|
| **5.11.0** (2026-09-07) | Custom `Rows` implementations, including mocks, must add the `TypeMap` method. Connection URIs use a libpq-matching parser: `+` is literal, malformed percent-encoding is an error, last repeated parameter wins. IPv6 hosts in URIs must be bracketed. Keyword/value strings treat backslash as escape (double Windows paths). Whitespace inside keywords is an error. Empty `host=` means default host; empty port means 5432 (was error). `db` struct tags match case-insensitively, exact match wins. OS user looked up only when no user supplied. `date` rejects impossible dates (2024-02-30). `date`/`timestamp`/`timestamptz` reject out-of-range values in text and binary. `timestamptz` text scans return `time.Local` or `ScanLocation` (changes JSON offsets and `database/sql` values). `pgxpool`: non-positive `MaxConnLifetime` now means unlimited (was immediate expiry). `Numeric` encodes JSON infinity as `"Infinity"`/`"-Infinity"` (was zero). NUL bytes rejected in startup parameters and keyword/value strings. Explicit empty port no longer exempt from `ConnStringAllowedKeys`. Parse/pgtype error text changed. Password redaction covers URI query parameters. |
| **5.10.0** (2026-06-03) | `CancelRequest` sent over TLS when primary connection used TLS. Server SCRAM iteration counts capped. Frontend max message body defaults to about 1 GiB. Binary decoders for hstore, arrays, ranges, multiranges, tsvector reject inputs previously accepted. `require_auth` restricts accepted server auth methods (downgrade mitigation under `sslmode=prefer`). |
| **5.9.2** (2026-04-18) | Security fix: SQL injection via placeholder confusion with dollar-quoted string literals under the simple protocol (GHSA-j88v-2chj-qfwx). Upgrade to >= 5.9.2. |

## Not sourced
- Exact Go 1.27 wording on `slog`/`context` changes: the 1.27 notes list none (checked). Nothing to record.
- Go 1.28 release date: NOT SOURCEABLE — not stated at https://go.dev/doc/devel/release.
