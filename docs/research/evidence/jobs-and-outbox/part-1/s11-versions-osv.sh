#!/usr/bin/env bash
# S11 (jobs-and-outbox part 1): current versions, licences, repo state and OSV advisories of the JVM job-library candidates.
# Run: bash docs/research/evidence/jobs-and-outbox/part-1/s11-versions-osv.sh > docs/research/evidence/jobs-and-outbox/part-1/s11-output.txt 2>&1
# Network: repo1.maven.org (metadata + pom only, a few KB), api.github.com (repo metadata, unauthenticated), api.osv.dev. No artifacts are downloaded.
set -u
M=https://repo1.maven.org/maven2
echo "### date $(date -u +%FT%TZ)"
osv() { # $1 groupId:artifactId  $2 version(optional)
  local body
  if [ -n "${2:-}" ]; then body="{\"package\":{\"ecosystem\":\"Maven\",\"name\":\"$1\"},\"version\":\"$2\"}"
  else body="{\"package\":{\"ecosystem\":\"Maven\",\"name\":\"$1\"}}"; fi
  curl -s --max-time 30 -X POST https://api.osv.dev/v1/query -d "$body" | jq -c '{n:(.vulns|length // 0), ids:([.vulns[]?.id]|.[0:12])}'
}
for ga in "com/github/kagkarlsson/db-scheduler" "org/jobrunr/jobrunr" "org/quartz-scheduler/quartz"; do
  g=$(echo "$ga" | sed 's#/[^/]*$##; s#/#.#g'); a=$(basename "$ga"); name="$g:$a"
  echo; echo "=== $name ==="
  curl -s --max-time 30 "$M/$ga/maven-metadata.xml" | grep -E "<(latest|release|lastUpdated)>"
  rel=$(curl -s --max-time 30 "$M/$ga/maven-metadata.xml" | sed -n 's#.*<release>\(.*\)</release>.*#\1#p')
  echo "release=$rel"
  echo "--- jar HEAD (size only, not downloaded)"
  curl -sI --max-time 30 "$M/$ga/$rel/$a-$rel.jar" | grep -iE "^(HTTP|content-length|last-modified)"
  echo "--- pom licences + java hints"
  curl -s --max-time 30 "$M/$ga/$rel/$a-$rel.pom" | grep -iE -A3 "<license>|maven.compiler|<java.version>|<release>" | head -24
  echo "--- OSV at release $rel"; osv "$name" "$rel"
  echo "--- OSV all versions (ids, first 12)"; osv "$name"
done
echo; echo "=== OSV positive control: log4j-core 2.14.1 (expect many) ==="
osv "org.apache.logging.log4j:log4j-core" "2.14.1"
for r in kagkarlsson/db-scheduler jobrunr/jobrunr quartz-scheduler/quartz; do
  echo; echo "=== GitHub $r ==="
  curl -s --max-time 30 "https://api.github.com/repos/$r" | jq -c '{license:.license.spdx_id, archived, pushed_at, open_issues_count, stars:.stargazers_count}'
  curl -s --max-time 30 "https://api.github.com/repos/$r/releases/latest" | jq -c '{tag:.tag_name, published:.published_at}'
done
