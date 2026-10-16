#!/usr/bin/env bash
# Part 5 evidence: generate clients from a synthetic OpenAPI 3.0.3 file with openapi-generator-cli 7.26.0
# Usage: part5-generate.sh <jar> <spec> <outroot>   (jar lives outside the repo; untrusted download)
set -u; jar="$1"; spec="$2"; out="$3"
date -u +"run at %Y-%m-%dT%H:%MZ"; java -version 2>&1 | head -1
java -jar "$jar" version
java -jar "$jar" generate -i "$spec" -g kotlin -o "$out/kotlin-mpp" --library multiplatform --additional-properties=serializationLibrary=kotlinx_serialization,dateLibrary=kotlinx-datetime,packageName=sample.api >"$out/kotlin-mpp.log" 2>&1; echo "kotlin multiplatform exit=$?"
java -jar "$jar" generate -i "$spec" -g typescript-fetch -o "$out/ts-fetch" >"$out/ts-fetch.log" 2>&1; echo "typescript-fetch exit=$?"
java -jar "$jar" generate -i "$spec" -g dart-dio -o "$out/dart-dio" >"$out/dart-dio.log" 2>&1; echo "dart-dio exit=$?"
java -jar "$jar" generate -i "$spec" -g csharp -o "$out/csharp" >"$out/csharp.log" 2>&1; echo "csharp exit=$?"
echo "--- kotlin-mpp build file pins:"; grep -n -i "ktor\|serialization\|kotlin_version\|kotlin(" "$out"/kotlin-mpp/build.gradle* | head -30
