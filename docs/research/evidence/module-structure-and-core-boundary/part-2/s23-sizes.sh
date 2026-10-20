#!/usr/bin/env bash
# SCRATCH / evidence script S23 (part 2): dependency lists and download sizes (HEAD only, nothing downloaded).
M=https://repo1.maven.org/maven2
echo "== konsist 0.18.1 pom dependencies"
curl -fsS $M/com/lemonappdev/konsist/0.18.1/konsist-0.18.1.pom | sed -n '/<dependencies>/,/<\/dependencies>/p' | grep -E "groupId|artifactId|version|scope"
echo "== archunit 1.5.1 pom dependencies"
curl -fsS $M/com/tngtech/archunit/archunit/1.5.1/archunit-1.5.1.pom | sed -n '/<dependencies>/,/<\/dependencies>/p' | grep -E "groupId|artifactId|version|scope"
echo "== konsist gradle module metadata runtime deps"
curl -fsS $M/com/lemonappdev/konsist/0.18.1/konsist-0.18.1.module | grep -E '"(group|module|version|requires)"' | head -60
echo "== sizes (bytes)"
for p in com/lemonappdev/konsist/0.18.1/konsist-0.18.1.jar com/tngtech/archunit/archunit/1.5.1/archunit-1.5.1.jar com/tngtech/archunit/archunit-junit5/1.5.1/archunit-junit5-1.5.1.jar com/tngtech/archunit/archunit-junit5-api/1.5.1/archunit-junit5-api-1.5.1.jar com/tngtech/archunit/archunit-junit5-engine/1.5.1/archunit-junit5-engine-1.5.1.jar; do
  printf "%s " "$p"; curl -sI --max-time 20 $M/$p | grep -i '^content-length' | tr -d '\r'; echo
done
