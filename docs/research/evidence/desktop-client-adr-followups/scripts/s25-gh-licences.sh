#!/usr/bin/env bash
# S25 (part 2): official-repo licence files via the authenticated GitHub API (licence endpoint + repo root listing).
# Usage: s25-gh-licences.sh <outdir>   Only reads public metadata; no secrets in requests.
set -u
out="$1"; mkdir -p "$out"
date -u +"run at %Y-%m-%dT%H:%MZ"
lic() { # repo [ref]
  local repo="$1" ref="${2:-}" name; name="$(echo "$repo" | tr '/' '_')${ref:+@$ref}"
  local url="repos/$repo/license"; [ -n "$ref" ] && url="$url?ref=$ref"
  gh api "$url" > "$out/$name.license.json" 2>"$out/$name.err" || { echo "$repo$ref: FAILED $(head -c 200 "$out/$name.err")"; return; }
  python3 -I -c 'import json,sys,base64; d=json.load(open(sys.argv[1])); open(sys.argv[2],"wb").write(base64.b64decode(d["content"])); print(sys.argv[3], "| file:", d["path"], "| spdx:", d["license"]["spdx_id"], "|", d["html_url"], "| bytes", len(base64.b64decode(d["content"])))' "$out/$name.license.json" "$out/$name.LICENSE.txt" "$repo${ref:+@$ref}"
}
lic Willena/sqlite-jdbc-crypt
lic utelle/SQLite3MultipleCiphers v2.6.1
lic java-native-access/jna 5.19.1
lic JetBrains/skiko
lic JetBrains/compose-multiplatform
lic JetBrains/kotlin
lic Kotlin/kotlinx.coroutines
lic openjdk/jdk21u
lic adoptium/temurin-build
lic wixtoolset/wix3
lic electron-userland/electron-builder
lic electron/electron v44.8.0
lic nodejs/node v24.22.0
lic m4heshd/better-sqlite3-multiple-ciphers
lic Koromix/koffi
echo "== repo root listings (licence-related file names)"
for r in Willena/sqlite-jdbc-crypt utelle/SQLite3MultipleCiphers java-native-access/jna JetBrains/skiko openjdk/jdk21u wixtoolset/wix3; do
  echo "-- $r"; gh api "repos/$r/contents" --jq '.[].name' 2>&1 | grep -iE 'licen|notice|copying|assembly|third|readme' | head -12
done
echo "== sqlite3mc / sqlite-jdbc-crypt READMEs: licence sections"
for r in Willena/sqlite-jdbc-crypt utelle/SQLite3MultipleCiphers; do
  n="$(echo "$r" | tr '/' '_')"; gh api "repos/$r/readme" --jq '.content' | base64 -d > "$out/$n.README.md" 2>/dev/null
  echo "-- $r README licence lines"; grep -n -i -B1 -A6 'licen' "$out/$n.README.md" | head -40
done
