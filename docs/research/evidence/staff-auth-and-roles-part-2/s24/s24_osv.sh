#!/bin/bash
# S24 - OSV advisory query (OSV aggregates GitHub Security Advisories). EVIDENCE tier E. Network: api.osv.dev and repo1.maven.org only; responses are small JSON.
# Run: bash s24_osv.sh   (no secrets in any query)
set -u
echo "date_utc: $(date -u +%FT%TZ)"
echo "== maven-metadata jna-platform (latest/release)"
curl -sS -m 30 https://repo1.maven.org/maven2/net/java/dev/jna/jna-platform/maven-metadata.xml | grep -E "<latest>|<release>|<lastUpdated>"
q() { # ecosystem name version
  printf '%s\n' "== $1 $2 $3"
  curl -sS -m 30 -X POST https://api.osv.dev/v1/query -H 'Content-Type: application/json' \
    -d "{\"package\":{\"ecosystem\":\"$1\",\"name\":\"$2\"},\"version\":\"$3\"}" | python3 -I -c 'import sys,json; d=json.load(sys.stdin); v=d.get("vulns",[]); print("count:",len(v)); [print(" ",x.get("id"),"|",x.get("modified","")[:10],"|",(x.get("summary") or "")[:110]) for x in v]'
}
q Maven org.bouncycastle:bcprov-jdk18on 1.86
q Maven com.password4j:password4j 1.8.4
q Maven net.java.dev.jna:jna-platform 5.17.0
q Maven net.java.dev.jna:jna 5.17.0
q npm electron 44.8.0
