#!/bin/sh
# s46-run.sh - corrected rerun of s45 (same instant for dates; Go uses MustParseISO). Reuses the module cache s45-gocache (no new download).
# Run from repo root: sh docs/research/evidence/backend-track-part-4/s46-run.sh > docs/research/evidence/backend-track-part-4/s46-run.output.txt 2>&1
E=docs/research/evidence/backend-track-part-4
echo "# s46-run $(date -u +%Y-%m-%dT%H:%M:%SZ)"; go version; java -version 2>&1 | head -1; node --version
echo "## JVM"; java $E/s46-locale-src/Fmt.java
echo "## Node"; node $E/s46-locale-src/fmt.js
echo "## Go"; ( cd $E/s46-locale-src && GOMODCACHE=$(pwd)/../s45-gocache GOFLAGS=-mod=mod go run . 2>&1 | head -20 )
