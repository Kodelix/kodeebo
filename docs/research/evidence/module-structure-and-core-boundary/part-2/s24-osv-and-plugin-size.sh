#!/usr/bin/env bash
# SCRATCH / evidence script S24 (part 2): OSV advisory search for chosen versions + size of the jraska plugin before fetching it.
date -u +"run at %Y-%m-%dT%H:%M:%SZ"
P=https://plugins.gradle.org/m2/com/jraska/module/graph/assertion/com.jraska.module.graph.assertion.gradle.plugin/2.9.1/com.jraska.module.graph.assertion.gradle.plugin-2.9.1.pom
echo "== marker pom dependency"; curl -fsS --max-time 20 "$P" | grep -E "<groupId>|<artifactId>|<version>" | head -8
G=$(curl -fsS --max-time 20 "$P" | sed -n '/<dependency>/,/<\/dependency>/p' | grep -m1 '<groupId>' | sed 's/.*<groupId>\(.*\)<\/groupId>.*/\1/')
A=$(curl -fsS --max-time 20 "$P" | sed -n '/<dependency>/,/<\/dependency>/p' | grep -m1 '<artifactId>' | sed 's/.*<artifactId>\(.*\)<\/artifactId>.*/\1/')
echo "plugin artifact: $G:$A"
GP=$(echo "$G" | tr . /)
for ext in jar; do printf "size %s: " "$A-2.9.1.$ext"; curl -sIL --max-time 20 "https://plugins.gradle.org/m2/$GP/$A/2.9.1/$A-2.9.1.$ext" | grep -i '^content-length' | tail -1 | tr -d '\r'; echo; done
echo "== OSV (includes GitHub Security Advisories)"
q(){ printf "%s %s -> " "$1" "$2"; curl -fsS --max-time 30 -X POST https://api.osv.dev/v1/query -d "{\"package\":{\"name\":\"$1\",\"ecosystem\":\"Maven\"},\"version\":\"$2\"}" | tr -d '\n ' | cut -c1-200; echo; }
q org.apache.logging.log4j:log4j-core 2.14.1   # control: must return advisories
q com.lemonappdev:konsist 0.18.1
q com.tngtech.archunit:archunit 1.5.1
q "$G:$A" 2.9.1
q org.jetbrains.kotlin:kotlin-compiler-embeddable 2.4.21
q org.slf4j:slf4j-api 2.0.19
