#!/bin/sh
# s45-run.sh - S42 spike: EGP and date formatting in JVM (Java 21 CLDR), Node Intl, and Go x/text v0.43.0. Run from repo root:
#   sh docs/research/evidence/backend-track-part-4/s45-run.sh > docs/research/evidence/backend-track-part-4/s45-run.output.txt 2>&1
# The Go module cache is redirected into the evidence folder (s45-gocache, a download, removed after the run; not evidence).
E=docs/research/evidence/backend-track-part-4
echo "# s45-run $(date -u +%Y-%m-%dT%H:%M:%SZ)"; go version; java -version 2>&1 | head -1; node --version
echo "## JVM"; java $E/s45-locale-src/Fmt.java
echo "## Node"; node $E/s45-locale-src/fmt.js
echo "## Go"; ( cd $E/s45-locale-src && GOMODCACHE=$(pwd)/../s45-gocache GOFLAGS=-mod=mod go run . 2>&1 | head -20 )
