#!/bin/sh
# S53b (fixes S53: bc was missing, use shell arithmetic): build and vet timing of the Go sync-spike server prototype (1 file, ~1.5k lines, pgx v5.11.0).
# usage: s53-go-timing.sh <module-dir> <scratch-dir>   (scratch holds GOCACHE and GOMODCACHE; SCRATCH FILES, not evidence)
mod="$1"; sc="$2"
export GOCACHE="$sc/gocache" GOMODCACHE="$sc/gomod" GOFLAGS=-modcacherw GOTOOLCHAIN=local GOPATH="$sc/gopath"
mkdir -p "$GOCACHE" "$GOMODCACHE" "$GOPATH"
t() { s=$(date +%s%N); "$@" >/dev/null 2>"$sc/err.txt"; rc=$?; e=$(date +%s%N); echo "$(( (e - s) / 1000000 )) ms rc=$rc : $*"; }
echo "host: $(nproc) cpus, $(go version)"
t go mod download -C "$mod"
t go build -C "$mod" -o "$sc/server-bin"
t go build -C "$mod" -o "$sc/server-bin"
t go vet -C "$mod" ./...
t go vet -C "$mod" ./...
echo "binary size: $(wc -c < "$sc/server-bin") bytes"
