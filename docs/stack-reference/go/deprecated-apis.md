# Go deprecated, removed and renamed APIs (Go 1.25–1.27)

Last verified: 2026-10-11. Sources are the release notes for each version (all fetched this session). "Since" is the Go release that announced the change.

| Deprecated / removed | Replacement | Since | Source |
|---|---|---|---|
| `net/http/httputil.ReverseProxy.Director` (deprecated) | `ReverseProxy.Rewrite` (a client can strip headers that `Director` adds) | Go 1.26 | [go1.26 notes](https://go.dev/doc/go1.26) |
| `cmd/doc` and `go tool doc` (deleted) | `go doc` (same flags and arguments) | Go 1.26 | [go1.26 notes](https://go.dev/doc/go1.26) |
| `GOEXPERIMENT=synctest` old testing/synctest API (removed) | `testing/synctest` (GA) | Removed Go 1.26; GA Go 1.25 | [go1.25 notes](https://go.dev/doc/go1.25) |
| `GOEXPERIMENT=jsonv2` (experiment) | `encoding/json/v2` and `encoding/json/jsontext` (GA; `encoding/json` now uses v2) | Go 1.27 | [go1.27 notes](https://go.dev/doc/go1.27) |
| `encoding/json` v2 tag option `inline` | `embed` | Go 1.27 | [go1.27 notes](https://go.dev/doc/go1.27) |
| `encoding/json/v2` tag options `format`, `unknown`; `DiscardUnknownMembers`; `SkipFunc` sentinel error (removed in v2) | No direct replacement listed on the notes page | Go 1.27 | [go1.27 notes](https://go.dev/doc/go1.27) |
| `crypto/tls` `Config.Rand` (deprecated) | Replacement NOT SOURCEABLE — the notes state only that it is deprecated | Go 1.27 | [go1.27 notes](https://go.dev/doc/go1.27) |
| `GODEBUG=asynctimerchan` (removed; time channels always unbuffered) | None stated (channels are always unbuffered) | Removed Go 1.27 | [go1.27 notes](https://go.dev/doc/go1.27) |
| `GODEBUG=gotypesalias` (removed; `go/types` always produces `Alias`) | None needed | Removed Go 1.27 | [go1.27 notes](https://go.dev/doc/go1.27) |
| `GODEBUG` `tlsunsafeekm`, `tlsrsakex`, `tls3des`, `tls10server`, `x509keypairleaf` (removed permanently) | None; these settings no longer exist | Removed Go 1.27 | [go1.27 notes](https://go.dev/doc/go1.27) |
| `GODEBUG` settings removed from `go.mod` `godebug` lines or `//go:debug` (old non-default values fail the build) | Delete the line or set the final default | Go 1.27 | [go1.27 notes](https://go.dev/doc/go1.27) |
| `go fix` `fmtappendf` fixer (removed); `waitgroup` fixer (renamed) | `waitgroupgo` fixer | Go 1.27 | [go1.27 notes](https://go.dev/doc/go1.27) |
| `bzr`-hosted module fetching (removed) | None stated | Go 1.27 | [go1.27 notes](https://go.dev/doc/go1.27) |
| `GOEXPERIMENT=nogreenteagc` (opt-out; go1.26 notes say removal expected in Go 1.27) | Remove the opt-out; the 1.27 notes do not mention it | Go 1.26 (removal status in 1.27: NOT SOURCEABLE) | [go1.26 notes](https://go.dev/doc/go1.26) |
| `GOEXPERIMENT=nojsonv2` (opt-out; removal expected in a future release) | Migrate to v2 semantics via new `Options` | Go 1.27 | [go1.27 notes](https://go.dev/doc/go1.27) |
| `GOEXPERIMENT=nosizespecializedmalloc` (opt-out; removal expected in Go 1.28) | None | Go 1.27 | [go1.27 notes](https://go.dev/doc/go1.27) |
| `GODEBUG=urlstrictcolons=0` (opt-out from strict `net/url` host parsing) | Fix hosts with extra colons | Go 1.26 | [go1.26 notes](https://go.dev/doc/go1.26) |
| `windows/arm` 32-bit port (removed) | None stated | Removed Go 1.26 | [go1.25 notes](https://go.dev/doc/go1.25) |
| macOS 12 support | macOS 13 or later | Last on Go 1.26; required macOS 13 on Go 1.27 | [go1.26 notes](https://go.dev/doc/go1.26), [go1.27 notes](https://go.dev/doc/go1.27) |
| ELFv1 on linux/ppc64 (last supported Go 1.26) | None stated | Go 1.27 (unsupported) | [go1.26 notes](https://go.dev/doc/go1.26) |
| `go mod init` default go line one minor lower | Set explicitly with `go get go@version` | Go 1.26 (behaviour, not deprecation) | [go1.26 notes](https://go.dev/doc/go1.26) |

## Not sourced
- Go 1.28 removal dates beyond the stated "expected" items: NOT SOURCEABLE — not stated in the go1.27 notes.
- Replacement for `encoding/json` v2 `format`/`unknown`/`DiscardUnknownMembers`: NOT SOURCEABLE — the go1.27 notes list the removal without a replacement.
