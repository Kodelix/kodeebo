#!/bin/sh
# S52b: better Maven control and an all-versions query for Ktor. usage: s52b-osv-controls.sh <outdir>
out="$1"
r=$(curl -sS -m 40 -X POST https://api.osv.dev/v1/query -d '{"package":{"name":"org.apache.logging.log4j:log4j-core","ecosystem":"Maven"},"version":"2.14.1"}')
echo "control log4j-core 2.14.1 -> $(printf '%s' "$r" | jq '.vulns // [] | length') advisories"
for pkg in io.ktor:ktor-server-core io.ktor:ktor-server-netty io.ktor:ktor-client-core org.jetbrains.exposed:exposed-core; do
  r=$(curl -sS -m 40 -X POST https://api.osv.dev/v1/query -d "{\"package\":{\"name\":\"$pkg\",\"ecosystem\":\"Maven\"}}")
  printf '%s\n' "$r" > "$out/allversions-$(echo $pkg | tr ':/' '__').json"
  echo "$pkg (all versions) -> $(printf '%s' "$r" | jq '.vulns // [] | length') advisories: $(printf '%s' "$r" | jq -r '[.vulns // [] | .[] | .id + " (" + (.modified // "") + ")"] | join("; ")' | cut -c1-400)"
done
