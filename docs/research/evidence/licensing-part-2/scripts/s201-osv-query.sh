#!/usr/bin/env bash
# s201: query OSV (api.osv.dev) for each candidate at the chosen version. Usage: s201-osv-query.sh
set -u
q() { # ecosystem name version
  printf '%s %s@%s -> ' "$1" "$2" "$3"
  curl -sS -m 40 -X POST https://api.osv.dev/v1/query -d "{\"package\":{\"ecosystem\":\"$1\",\"name\":\"$2\"},\"version\":\"$3\"}" | jq -c '[.vulns[]? | {id, aliases: (.aliases // [] | .[0:3]), modified}] | {count: length, vulns: .}'
}
echo "# OSV query $(date -u +%FT%TZ)"
q Go stdlib 1.27.2
q Go github.com/cloudflare/circl 1.6.5
q Go filippo.io/edwards25519 1.2.0
q Maven org.bouncycastle:bcprov-jdk18on 1.86
q Maven com.google.crypto.tink:tink 1.24.0
q npm @noble/curves 2.4.0
q npm @noble/ed25519 3.2.0
q npm libsodium-wrappers 0.8.4
q npm electron 44.8.0
echo "# control (known-vulnerable version must return >0, proves the query works)"
q Go github.com/cloudflare/circl 1.3.6
