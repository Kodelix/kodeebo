#!/usr/bin/env bash
# S22 (part 2): read-only inventory of what the spike actually shipped/cached: licence fields, licence file heads, JDK legal folder, Gradle-cached jars.
# Input is untrusted downloaded data under prototypes/desktop-client-spike/.cache; this script only lists and reads text, runs nothing from there.
# Usage: s22-local-inventory.sh <spike-cache-dir> <outdir-for-copied-licences>
set -u
cache="$1"; out="$2"; mkdir -p "$out"
date -u +"run at %Y-%m-%dT%H:%MZ"
echo "== cache top levels"; ls -1 "$cache" | head -30
echo "== build-b top"; ls -1 "$cache/build-b" | head; echo "== node_modules count: $(ls "$cache/build-b/node_modules" | wc -l)"
echo "== B: licence field of production deps (better-sqlite3-multiple-ciphers, koffi, node-addon-api, bindings, file-uri-to-path, prebuild-install...)"
for p in better-sqlite3-multiple-ciphers koffi node-addon-api bindings file-uri-to-path prebuild-install; do
  f="$cache/build-b/node_modules/$p/package.json"
  [ -f "$f" ] && python3 -I -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["name"], d["version"], "license=", d.get("license"), d.get("licenses"), "repo=", d.get("repository"))' "$f" || echo "$p: not present"
done
echo "== B: electron-dist version file and licence heads"
cat "$cache/build-b/electron-dist/version" 2>/dev/null; echo
head -c 400 "$cache/build-b/electron-dist/LICENSE"; echo; echo "(LICENSES.chromium.html size: $(wc -c < "$cache/build-b/electron-dist/LICENSES.chromium.html") bytes, <h3> entries: $(grep -c '<h3>' "$cache/build-b/electron-dist/LICENSES.chromium.html"))"
cp "$cache/build-b/electron-dist/LICENSE" "$out/electron-44.8.0-dist-LICENSE.txt"
cp "$cache/build-b/electron-dist/LICENSES.chromium.html" "$out/electron-44.8.0-dist-LICENSES.chromium.html"
for p in better-sqlite3-multiple-ciphers koffi node-addon-api electron-builder builder-util-runtime; do
  for n in LICENSE LICENSE.txt LICENSE.md license; do [ -f "$cache/build-b/node_modules/$p/$n" ] && cp "$cache/build-b/node_modules/$p/$n" "$out/B-$p-$n" && echo "copied $p/$n ($(wc -c < "$out/B-$p-$n") bytes)" && break; done
done
echo "== B: Chromium notices: licence names counted in LICENSES.chromium.html (first 60 distinct <h3> titles)"
grep -o '<h3>[^<]*</h3>' "$cache/build-b/electron-dist/LICENSES.chromium.html" | sort -u | head -60
echo "== B: GPL/LGPL/MPL/AGPL mentions in LICENSES.chromium.html"
grep -ciE 'GNU (Lesser |Library )?General Public|GPL' "$cache/build-b/electron-dist/LICENSES.chromium.html"
grep -oiE '(GNU (Lesser |Library )?General Public License[^<]{0,40}|Mozilla Public License[^<]{0,20}|LGPL[^<]{0,20})' "$cache/build-b/electron-dist/LICENSES.chromium.html" | sort | uniq -c | sort -rn | head -15
echo "== A: any JDK/legal/gradle caches"
find "$cache" -maxdepth 3 -type d \( -name legal -o -name 'jdk*' -o -name 'build-a*' -o -name '.gradle*' -o -name caches \) 2>/dev/null | head -20
echo "== A: jars in Gradle cache for shipped components (names only)"
find "$cache" -type f \( -name 'skiko*.jar' -o -name 'sqlite-jdbc*.jar' -o -name 'jna*.jar' -o -name 'kotlinx-coroutines-core*.jar' -o -name 'desktop*.jar' \) 2>/dev/null | head -30
