#!/usr/bin/env bash
# S58 (tier E, part 5): Kotlin dependency of gradle-kotlin-dsl-plugins 6.7.7 (the version in gradle/gradle tag v9.8.1, S56) with 6.7.3 (used by Gradle 9.7.0 per part-1 F110) and 6.7.13 (newest on the portal) as references. POM text only; -L follows redirects.
echo "date: $(date -u +%FT%TZ)"
for v in 6.7.7 6.7.3 6.7.13; do
  for f in pom module; do
    url=https://plugins.gradle.org/m2/org/gradle/kotlin/gradle-kotlin-dsl-plugins/$v/gradle-kotlin-dsl-plugins-$v.$f
    echo "=== $v .$f"; curl -sL -m 30 -w '\n[http %{http_code} final %{url_effective}]\n' "$url" | grep -i -E 'kotlin-gradle-plugin|"version"|<version>|\[http|kotlin-stdlib' | cut -c1-160 | head -12
  done
done
