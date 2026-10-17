#!/usr/bin/env bash
# p4-s42: advisories, licences and release currency for part-4 candidates (JVM updaters). Read-only queries.
# Run: bash p4-s42-advisories-and-licences.sh   (needs curl, jq, gh authenticated)
set -u
echo "# date: $(date -u +%FT%TZ)"; echo "# curl: $(curl --version | head -1)"; echo "# gh: $(gh --version | head -1)"
echo "## OSV Maven dev.nucleusframework:nucleus.updater-runtime 2.5.18"
curl -s -m 30 -X POST https://api.osv.dev/v1/query -d '{"package":{"ecosystem":"Maven","name":"dev.nucleusframework:nucleus.updater-runtime"},"version":"2.5.18"}' | head -c 600; echo
echo "## OSV Maven control log4j-core 2.14.1 (must return advisories)"
curl -s -m 30 -X POST https://api.osv.dev/v1/query -d '{"package":{"ecosystem":"Maven","name":"org.apache.logging.log4j:log4j-core"},"version":"2.14.1"}' | jq '.vulns|length' 2>/dev/null
echo "## Maven Central metadata for nucleus.updater-runtime"
curl -s -m 30 https://repo1.maven.org/maven2/dev/nucleusframework/nucleus.updater-runtime/maven-metadata.xml | head -30
echo "## npm jdeploy (dist-tags, modified)"
curl -s -m 30 https://registry.npmjs.org/jdeploy | jq '{tags:."dist-tags", modified:.time.modified, license:.license}' 2>/dev/null
echo "## OSV npm jdeploy (latest)"
V=$(curl -s -m 30 https://registry.npmjs.org/jdeploy | jq -r '."dist-tags".latest' 2>/dev/null); echo "latest=$V"
curl -s -m 30 -X POST https://api.osv.dev/v1/query -d "{\"package\":{\"ecosystem\":\"npm\",\"name\":\"jdeploy\"},\"version\":\"$V\"}" | head -c 600; echo
for R in NucleusFramework/Nucleus shannah/jdeploy bekoenig/getdown threerings/getdown; do
  echo "## repo $R"
  gh api repos/$R --jq '{license:.license.spdx_id, archived:.archived, pushed_at:.pushed_at, stars:.stargazers_count}' 2>&1 | head -5
  echo "-- latest release"
  gh api repos/$R/releases/latest --jq '{tag:.tag_name, published:.published_at}' 2>&1 | head -3
  echo "-- published security advisories (count)"
  gh api repos/$R/security-advisories --jq 'length' 2>&1 | head -3
done
