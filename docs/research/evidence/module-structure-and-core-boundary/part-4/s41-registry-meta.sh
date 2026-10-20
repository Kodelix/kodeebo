#!/usr/bin/env bash
# SCRATCH / evidence (part 4, S41/S42 registry data). Read-only HTTP GETs/HEADs, nothing downloaded except small metadata files to stdout.
# Run 2026-10-20 from repo root: bash <this file>
set -u
echo "## date $(date -u +%FT%TZ)"
gh_rel() { echo "### releases $1"; gh api "repos/$1/releases?per_page=${2:-6}" --jq '.[] | [.tag_name, .published_at, .prerelease] | @tsv' 2>&1; }
gh_rel ktlint/ktlint 8
gh_rel JLLeitschuh/ktlint-gradle 4
gh_rel jeremymailen/kotlinter-gradle 4
gh_rel detekt/detekt 8
gh_rel diffplug/spotless 12
mm() { echo "### maven-metadata $1"; curl -fsS --max-time 30 "$1" | grep -E "<(latest|release|lastUpdated|version)>" | tail -${2:-8}; }
mm https://repo1.maven.org/maven2/io/github/ktlint/core/ktlint-cli/maven-metadata.xml 6
mm https://repo1.maven.org/maven2/com/pinterest/ktlint/ktlint-cli/maven-metadata.xml 5
mm https://repo1.maven.org/maven2/dev/detekt/detekt-cli/maven-metadata.xml 10
mm https://repo1.maven.org/maven2/dev/detekt/detekt-gradle-plugin/maven-metadata.xml 8
mm https://repo1.maven.org/maven2/io/gitlab/arturbosch/detekt/detekt-cli/maven-metadata.xml 4
for p in org.jlleitschuh.gradle.ktlint org.jmailen.kotlinter com.diffplug.spotless dev.detekt io.gitlab.arturbosch.detekt; do
  mm "https://plugins.gradle.org/m2/$(echo $p | tr . /)/$p.gradle.plugin/maven-metadata.xml" 5
done
sz() { printf '%s\t' "$1"; curl -fsSI --max-time 30 "$1" | tr -d '\r' | awk 'tolower($1)=="content-length:"{print $2}' | tail -1; }
echo "### directory listings + sizes (bytes)"
for d in https://repo1.maven.org/maven2/io/github/ktlint/core/ktlint-cli/2.0.0-ALPHA-4/ https://repo1.maven.org/maven2/dev/detekt/detekt-cli/2.0.0-alpha.6/; do
  echo "# $d"
  for f in $(curl -fsS --max-time 30 "$d" | grep -oE 'href="[^"]+\.(jar|pom)"' | sed 's/href="//;s/"//' ); do sz "$d$f"; done
done
