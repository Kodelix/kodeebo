#!/usr/bin/env bash
# SCRATCH / evidence (part 4, S14 for this part): OSV API query per Maven coordinate+version, and GitHub global advisories API (affects=<pkg>@<ver>, ecosystem maven). Public coordinates only.
set -u
echo "## run $(date -u +%FT%TZ)"
osv() { printf '%s\t' "$1@$2"; curl -fsS --max-time 30 -X POST https://api.osv.dev/v1/query -d "{\"package\":{\"name\":\"$1\",\"ecosystem\":\"Maven\"},\"version\":\"$2\"}" | python3 -I -c 'import sys,json; d=json.load(sys.stdin); v=d.get("vulns",[]); print(len(v), [x["id"] for x in v][:10])'; }
gha() { printf '%s\t' "$1@$2"; gh api -H "Accept: application/vnd.github+json" "advisories?ecosystem=maven&affects=$1@$2&per_page=20" --jq '[.[]|.ghsa_id] | "\(length) \(.)"' 2>&1; }
echo "### CONTROL (must return advisories)"; osv org.apache.logging.log4j:log4j-core 2.14.1; gha org.apache.logging.log4j:log4j-core 2.14.1
echo "### OSV (Maven)"
for c in com.lemonappdev:konsist:0.18.1 com.tngtech.archunit:archunit:1.5.1 com.jraska.module.graph.assertion:plugin:2.9.1 \
  io.github.ktlint.core:ktlint-cli:2.0.0-ALPHA-4 io.github.ktlint.core:ktlint-rule-engine:2.0.0-ALPHA-4 io.github.ktlint.core:ktlint-ruleset-standard:2.0.0-ALPHA-4 \
  com.pinterest.ktlint:ktlint-cli:1.8.0 com.pinterest.ktlint:ktlint-rule-engine:1.8.0 \
  dev.detekt:detekt-cli:2.0.0-alpha.6 dev.detekt:detekt-gradle-plugin:2.0.0-alpha.6 io.gitlab.arturbosch.detekt:detekt-cli:1.23.8 \
  org.jlleitschuh.gradle:ktlint-gradle:14.2.0 org.jmailen.gradle:kotlinter-gradle:5.7.0 com.diffplug.spotless:spotless-plugin-gradle:8.10.4 \
  org.jetbrains.kotlin:kotlin-compiler-embeddable:2.4.21 com.github.ajalt.clikt:clikt-jvm:5.1.0 ch.qos.logback:logback-classic:1.6.3; do osv "${c%:*}" "${c##*:}"; done
echo "### GHSA global advisories (maven)"
for c in com.lemonappdev:konsist:0.18.1 com.tngtech.archunit:archunit:1.5.1 io.github.ktlint.core:ktlint-cli:2.0.0-ALPHA-4 com.pinterest.ktlint:ktlint-cli:1.8.0 \
  dev.detekt:detekt-cli:2.0.0-alpha.6 io.gitlab.arturbosch.detekt:detekt-cli:1.23.8 org.jlleitschuh.gradle:ktlint-gradle:14.2.0 org.jmailen.gradle:kotlinter-gradle:5.7.0 \
  com.diffplug.spotless:spotless-plugin-gradle:8.10.4 com.jraska.module.graph.assertion:plugin:2.9.1 ch.qos.logback:logback-classic:1.6.3; do gha "${c%:*}" "${c##*:}"; done
echo "### GHSA by repository (security advisories published on the project repos)"
for r in LemonAppDev/konsist TNG/ArchUnit jraska/modules-graph-assert ktlint/ktlint detekt/detekt JLLeitschuh/ktlint-gradle jeremymailen/kotlinter-gradle diffplug/spotless; do printf '%s\t' $r; gh api "repos/$r/security-advisories?per_page=30" --jq 'length' 2>&1 | head -1; done
