#!/usr/bin/env bash
# SCRATCH / evidence script S21 (part 2): release, licence and activity metadata for architecture-test candidates.
# Read-only GitHub API + Maven metadata GETs. Run: bash s21-registry-meta.sh > s21-registry-meta.output.txt
date -u +"run at %Y-%m-%dT%H:%M:%SZ"
for r in LemonAppDev/konsist TNG/ArchUnit jraska/modules-graph-assert eduardbosch/modules-graph-assert rubensousa/ProjectGuard detekt/detekt ebay/graph-analytics; do
  echo "=== $r"
  gh api repos/$r --jq '{full_name,license:.license.spdx_id,archived,pushed_at,stars:.stargazers_count,open_issues}' 2>&1 | head -3
  gh api repos/$r/releases --jq '.[0:3][]|{tag:.tag_name,published:.published_at,prerelease}' 2>&1 | head -12
done
for u in \
 https://repo1.maven.org/maven2/com/lemonappdev/konsist/maven-metadata.xml \
 https://repo1.maven.org/maven2/com/tngtech/archunit/archunit/maven-metadata.xml \
 https://plugins.gradle.org/m2/com/jraska/module/graph/assertion/com.jraska.module.graph.assertion.gradle.plugin/maven-metadata.xml \
 https://plugins.gradle.org/m2/io/github/eduardbosch/module/graph/assertion/io.github.eduardbosch.module.graph.assertion.gradle.plugin/maven-metadata.xml ; do
  echo "=== $u"; curl -fsS --max-time 30 "$u" | grep -E "<latest>|<release>|<lastUpdated>" ; echo "exit=$?"
done
