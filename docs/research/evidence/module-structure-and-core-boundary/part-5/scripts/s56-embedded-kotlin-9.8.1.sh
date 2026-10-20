#!/usr/bin/env bash
# S56 (tier E + source reads, part 5): which Kotlin does Gradle 9.8.1's kotlin-dsl resolve? (small text reads only: POMs and two source files; no jars)
echo "date: $(date -u +%FT%TZ)"
for t in v9.8.1 v9.7.0; do
  echo "=== gradle/gradle $t gradle/libs.versions.toml (kotlin lines)"
  curl -s -m 30 https://raw.githubusercontent.com/gradle/gradle/$t/gradle/libs.versions.toml | grep -n -i -E '^kotlin[A-Za-z-]* *=|kotlin-gradle|embedded' | head -12
  echo "=== gradle/gradle $t kotlin-dsl-plugins build file (published plugin version lines)"
  curl -s -m 30 https://raw.githubusercontent.com/gradle/gradle/$t/platforms/core-configuration/kotlin-dsl-plugins/build.gradle.kts | grep -n -i -E 'publishedKotlinDslPluginVersion|version *=' | head -6
done
for v in 6.7.13 6.7.3; do
  echo "=== plugins.gradle.org/m2 gradle-kotlin-dsl-plugins-$v.pom: kotlin dependencies"
  curl -s -m 30 https://plugins.gradle.org/m2/org/gradle/kotlin/gradle-kotlin-dsl-plugins/$v/gradle-kotlin-dsl-plugins-$v.pom | grep -n -B2 -A3 -i 'kotlin-gradle-plugin\|kotlin-stdlib' | head -30
done
