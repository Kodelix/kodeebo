#!/bin/sh
# Tier-E: OSV query for libraries named in the pins relevant to the sync feed. Date: run date printed below.
date -u +"run at %Y-%m-%dT%H:%MZ"
q() { echo "== $1 $2 $3"; curl -sS -m 30 -X POST https://api.osv.dev/v1/query -d "{\"version\":\"$3\",\"package\":{\"name\":\"$2\",\"ecosystem\":\"$1\"}}" | python3 -I -c 'import sys,json; d=json.load(sys.stdin); v=d.get("vulns",[]); print(len(v),"advisories"); [print(" ",x["id"],"|",x.get("summary","")[:90]) for x in v]'; }
q Go github.com/jackc/pgx/v5 5.11.0
q Maven io.ktor:ktor-server-core 3.6.0
q Maven org.jetbrains.exposed:exposed-core 1.5.1
q Maven org.jetbrains.kotlinx:kotlinx-coroutines-core 1.11.0
