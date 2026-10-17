#!/usr/bin/env bash
# Tier-E: OSV API query for Go module golang.org/x/time (all versions) and Valkey-related names.
# Command: bash osv-query.sh > osv-output.txt 2>&1   Date: 2026-10-17
set -u
for pkg in "golang.org/x/time"; do
  echo "== OSV query ecosystem=Go package=$pkg"
  curl -sS --max-time 30 -X POST https://api.osv.dev/v1/query -d "{\"package\":{\"name\":\"$pkg\",\"ecosystem\":\"Go\"}}"
  echo
done
