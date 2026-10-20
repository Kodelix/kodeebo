#!/usr/bin/env bash
# S57 (tier E + source reads, part 5): second attempt at S56 - find where libs.versions.kotlin is defined at tag v9.8.1 and read the kotlin-dsl-plugins 6.7.7 POM.
echo "date: $(date -u +%FT%TZ)"
echo "=== files under gradle/ at v9.8.1 matching toml"
curl -s -m 30 -H 'Accept: application/vnd.github+json' "https://api.github.com/repos/gradle/gradle/contents/gradle?ref=v9.8.1" | python3 -I -c 'import sys,json; d=json.load(sys.stdin); print([x["name"] for x in d] if isinstance(d,list) else d)'
for p in gradle/dependency-management/libs.versions.toml gradle/libs.versions.toml build-logic-settings/libs.versions.toml; do
  echo "=== $p"; curl -s -m 30 -w '\n[http %{http_code}]\n' https://raw.githubusercontent.com/gradle/gradle/v9.8.1/$p | grep -n -i -E '^kotlin *=|^kotlin[A-Za-z]* *=|\[http' | head
done
echo "=== kotlin-dsl-plugins 6.7.7 and 6.7.4 POM (plugin portal m2)"
for v in 6.7.7 6.7.4 6.7.3; do echo "-- $v"; curl -s -m 30 -w '[http %{http_code}]\n' https://plugins.gradle.org/m2/org/gradle/kotlin/kotlin-dsl/org.gradle.kotlin.kotlin-dsl.gradle.plugin/$v/org.gradle.kotlin.kotlin-dsl.gradle.plugin-$v.pom | grep -i -E 'artifactId|version|http' | head -8; done
