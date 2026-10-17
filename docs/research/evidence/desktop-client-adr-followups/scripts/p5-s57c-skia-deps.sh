#!/usr/bin/env bash
# S57c (part 5): Skiko v0.150.2 -> "Update skia to m150-a3f509bf52" (S57b). Read Skiko's gradle.properties at tag v0.150.2 and Skia's DEPS at commit a3f509bf52 (google/skia, then JetBrains/skia as fallback); extract the harfbuzz, freetype and icu pins.
# Run: bash scripts/p5-s57c-skia-deps.sh <outdir>
set -u
out="$1"; mkdir -p "$out"
date -u +"run %Y-%m-%dT%H:%MZ"
curl -sSL -m 60 -o "$out/skiko-v0.150.2-gradle.properties" -w "skiko gradle.properties HTTP %{http_code} %{size_download}\n" https://raw.githubusercontent.com/JetBrains/skiko/v0.150.2/gradle.properties
grep -n -i "skia" "$out/skiko-v0.150.2-gradle.properties" | head
for repo in google/skia JetBrains/skia; do
  f="$out/$(echo $repo | tr / _)-DEPS-a3f509bf52"
  curl -sSL -m 60 -o "$f" -w "$repo DEPS@a3f509bf52 HTTP %{http_code} %{size_download}\n" "https://raw.githubusercontent.com/$repo/a3f509bf52/DEPS"
  grep -n -E '"third_party/externals/(harfbuzz|freetype|icu|expat|zlib|libpng|libjpeg|wuffs|libwebp)"' "$f" | head -20
done
