#!/usr/bin/env bash
# S26 (part 2): Maven Central POMs for runtime A components: declared licences, and the Skiko version Compose Multiplatform 1.12.2 resolves; then OSV for Skiko.
# Usage: s26-maven-poms.sh <outdir>
set -u
out="$1"; mkdir -p "$out"
date -u +"run at %Y-%m-%dT%H:%MZ"
M=https://repo1.maven.org/maven2
get() { # path-without-base name
  code=$(curl -sS --max-time 30 -o "$out/$2.pom" -w '%{http_code}' "$M/$1"); echo "$2 HTTP $code <- $M/$1"
}
get org/jetbrains/kotlin/kotlin-stdlib/2.4.21/kotlin-stdlib-2.4.21.pom kotlin-stdlib-2.4.21
get org/jetbrains/kotlinx/kotlinx-coroutines-core-jvm/1.9.0/kotlinx-coroutines-core-jvm-1.9.0.pom coroutines-core-jvm-1.9.0
get io/github/willena/sqlite-jdbc/3.53.4.0/sqlite-jdbc-3.53.4.0.pom willena-sqlite-jdbc-3.53.4.0
get net/java/dev/jna/jna/5.19.1/jna-5.19.1.pom jna-5.19.1
get org/jetbrains/compose/desktop/desktop-jvm-windows-x64/1.12.2/desktop-jvm-windows-x64-1.12.2.pom cmp-desktop-jvm-windows-x64-1.12.2
get org/jetbrains/compose/desktop/desktop-jvm/1.12.2/desktop-jvm-1.12.2.pom cmp-desktop-jvm-1.12.2
get org/jetbrains/compose/ui/ui-desktop/1.12.2/ui-desktop-1.12.2.pom cmp-ui-desktop-1.12.2
get org/jetbrains/compose/ui/ui-graphics-desktop/1.12.2/ui-graphics-desktop-1.12.2.pom cmp-ui-graphics-desktop-1.12.2
python3 -I - "$out" <<'PY'
import re, sys, glob, os
out = sys.argv[1]
skiko = set()
for f in sorted(glob.glob(out + "/*.pom")):
    t = open(f, encoding="utf-8", errors="replace").read()
    if t.lstrip().startswith("<html") or "<project" not in t:
        print(os.path.basename(f), "NOT A POM (", len(t), "bytes )"); continue
    lic = re.findall(r"<license>\s*<name>(.*?)</name>(?:\s*<url>(.*?)</url>)?", t, flags=re.S)
    deps = re.findall(r"<dependency>\s*<groupId>(.*?)</groupId>\s*<artifactId>(.*?)</artifactId>(?:\s*<version>(.*?)</version>)?", t, flags=re.S)
    print(os.path.basename(f), "| licences:", [(a.strip(), b.strip()) for a, b in lic] or "NONE DECLARED")
    for g, a, v in deps:
        if "skiko" in a or "skiko" in g:
            print("    dep:", g, a, v); skiko.add((a, v))
print("skiko deps seen:", sorted(skiko))
PY
echo "== Skiko version via Gradle module metadata if POM carried none"
code=$(curl -sS --max-time 30 -o "$out/cmp-ui-graphics-desktop-1.12.2.module" -w '%{http_code}' "$M/org/jetbrains/compose/ui/ui-graphics-desktop/1.12.2/ui-graphics-desktop-1.12.2.module"); echo "module HTTP $code"
grep -o '"module": *"skiko[^"]*"\|"version": *"[0-9][^"]*"' "$out/cmp-ui-graphics-desktop-1.12.2.module" 2>/dev/null | grep -B1 -A1 skiko | head -12
