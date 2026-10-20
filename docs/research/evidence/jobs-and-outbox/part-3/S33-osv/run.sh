#!/usr/bin/env bash
# S33: OSV advisory query for the Ktor-track coordinates of jobs-and-outbox part 3. Query = package name + exact version only.
# Usage: bash run.sh > output.txt 2>&1
set -u
echo "### S33 OSV $(date -u +%FT%TZ)"
q() { # ecosystem name version
  local body; body=$(printf '{"package":{"name":"%s","ecosystem":"%s"},"version":"%s"}' "$2" "$1" "$3")
  local out; out=$(curl -s --max-time 25 -X POST https://api.osv.dev/v1/query -d "$body")
  local n ids
  n=$(printf '%s' "$out" | python3 -I -c 'import sys,json; d=json.load(sys.stdin); print(len(d.get("vulns",[])))' 2>/dev/null || echo "query-failed")
  ids=$(printf '%s' "$out" | python3 -I -c 'import sys,json; d=json.load(sys.stdin); print(" ".join(v["id"] for v in d.get("vulns",[]))[:300])' 2>/dev/null)
  echo "$1 $2 $3 -> $n records $ids"
}
q Maven io.ktor:ktor-server-core-jvm 3.6.0
q Maven io.ktor:ktor-server-cio-jvm 3.6.0
q Maven io.ktor:ktor-server-netty-jvm 3.6.0
q Maven org.jetbrains.exposed:exposed-core 1.5.1
q Maven org.jetbrains.exposed:exposed-jdbc 1.5.1
q Maven com.zaxxer:HikariCP 7.1.0
q Maven org.postgresql:postgresql 42.7.14
q Maven org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm 1.11.0
q Maven org.jetbrains.kotlin:kotlin-stdlib 2.4.21
echo "-- positive control (an old pgjdbc, expect > 0)"
q Maven org.postgresql:postgresql 42.2.0
echo "### done"
