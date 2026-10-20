#!/usr/bin/env bash
# RECORD of three inline commands run on 2026-10-20 (S50, S51, S53). Re-typed from the shell history of the run; outputs are the s50-*, s51-*, s53-* .output.txt files beside this folder.
# S50 (18:49 UTC): size and published SHA-256 of the Gradle 9.8.1 distribution, and the current version.
curl -sIL https://services.gradle.org/distributions/gradle-9.8.1-bin.zip | grep -i -E '^(HTTP|content-length|location)'
curl -sL https://services.gradle.org/distributions/gradle-9.8.1-bin.zip.sha256
curl -sL https://services.gradle.org/versions/current | head -c 600
# S51 (18:50 UTC): which Kotlin 2.4.10 / 2.4.0 artifacts exist in the part-1/2/3 Gradle homes (find over caches/modules-2/files-2.1, sizes with -printf '%s %P').
# S53 (18:53 UTC): is the 2.4.10 compiler jar in part 2's home (only the .pom was), and which Gradle wrapper distributions exist under the user's ~/.gradle/wrapper/dists (listing only).
# Note: S56's first part (gradle/libs.versions.toml at tag v9.8.1) returned HTTP 404 and printed nothing - the file lives elsewhere; S57 looked again and also did not find it (F516).
