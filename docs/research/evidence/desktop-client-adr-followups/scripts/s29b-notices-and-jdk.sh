#!/usr/bin/env bash
# S29b (part 2; suffix because S20-S29 are all in use): (1) LICENSE.zentus from the Willena jar downloaded by s29; (2) NSIS licence text from the NSIS source repo / site candidates;
# (3) OpenJDK 2026/08/18 advisory page (JDK 21 fixed version); (4) the Temurin legal-notice statement. Fetched files are untrusted text; only read.
# Usage: s29b-notices-and-jdk.sh <jar-path> <outdir>
set -u
jar="$1"; out="$2"; mkdir -p "$out"
date -u +"run at %Y-%m-%dT%H:%MZ"
python3 -I - "$jar" "$out" <<'PY'
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
for n in ("META-INF/maven/io.github.willena/sqlite-jdbc/LICENSE.zentus", "org/sqlite/native/readme.txt"):
    d = z.read(n); open(sys.argv[2] + "/jar-" + n.replace("/", "_"), "wb").write(d); print("---", n, len(d), "bytes\n" + d.decode("utf-8", "replace"))
PY
for u in https://nsis.sourceforge.io/License https://sourceforge.net/p/nsis/code/HEAD/tree/NSIS/trunk/COPYING?format=raw https://nsis.sourceforge.io/Docs/AppendixI.html; do
  n=$(echo "$u" | tr -c 'A-Za-z0-9' '_' | cut -c1-70)
  code=$(curl -sSL --max-time 30 -o "$out/nsis-$n.txt" -w '%{http_code}' "$u"); echo "NSIS candidate $u -> HTTP $code, $(wc -c < "$out/nsis-$n.txt") bytes"
done
for f in "$out"/nsis-*.txt; do echo "--- head of $f"; sed -e 's/<[^>]*>//g' "$f" | tr -s ' \n' | head -c 1800; echo; done
code=$(curl -sSL --max-time 30 -o "$out/openjdk-2026-08-18.html" -w '%{http_code}' https://openjdk.org/groups/vulnerability/advisories/2026-08-18); echo "openjdk 2026-08-18 -> HTTP $code"
sed -e 's/<[^>]*>/ /g' "$out/openjdk-2026-08-18.html" | tr -s ' \n' | grep -iE '21\.0|jdk 21|21u|CVE-|released|affected' | head -20
