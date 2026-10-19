#!/bin/sh
# S52: OSV.dev query for the versions under comparison. usage: s52-osv.sh <outdir>
out="$1"
q() { # ecosystem name version
  body=$(printf '{"package":{"name":"%s","ecosystem":"%s"},"version":"%s"}' "$2" "$1" "$3")
  res=$(curl -sS -m 40 -X POST https://api.osv.dev/v1/query -d "$body")
  n=$(printf '%s' "$res" | jq '.vulns // [] | length')
  ids=$(printf '%s' "$res" | jq -r '[.vulns // [] | .[].id] | join(",")' | cut -c1-300)
  echo "$1 $2 $3 -> $n advisories $ids"
  printf '%s\n' "$res" > "$out/$1-$(echo $2 | tr ':/' '__')-$3.json"
}
q Maven io.ktor:ktor-server-core 3.6.0
q Maven io.ktor:ktor-server-netty 3.6.0
q Maven org.jetbrains.exposed:exposed-core 1.5.1
q Maven org.jetbrains.kotlin:kotlin-stdlib 2.4.21
q Maven com.zaxxer:HikariCP 7.1.0
q Go stdlib 1.27.2
q Go stdlib 1.27.0
q npm electron 44.8.0
echo "-- control queries (older versions, must return advisories if the endpoint answers) --"
q Maven io.ktor:ktor-server-core 1.0.0
q Go stdlib 1.20.0
