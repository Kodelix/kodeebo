#!/usr/bin/env bash
# S57 (part 5): which Skia milestone Skiko 0.150.2 builds, and which HarfBuzz / FreeType / ICU commits that Skia milestone pins.
# Sources: GitHub API for JetBrains/skiko (release 0.150.2 and the tag's gradle.properties / README), then Skia's DEPS at the matching branch (raw.githubusercontent.com).
# Run: bash scripts/p5-s57-skiko-skia-deps.sh <outdir>
set -u
out="$1"; mkdir -p "$out"
date -u +"run %Y-%m-%dT%H:%MZ"
H='Accept: application/vnd.github+json'
curl -sSL -m 60 -H "$H" -o "$out/skiko-release-0.150.2.json" -w "skiko release 0.150.2 HTTP %{http_code}\n" https://api.github.com/repos/JetBrains/skiko/releases/tags/0.150.2
python3 -I - "$out/skiko-release-0.150.2.json" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1])); print("published", d.get("published_at"), "name", d.get("name")); print((d.get("body") or "")[:3500])
except Exception as e: print("parse failed", e)
PY
for f in gradle.properties README.md; do
  curl -sSL -m 60 -o "$out/skiko-0.150.2-$f" -w "skiko tag file $f HTTP %{http_code} %{size_download} bytes\n" "https://raw.githubusercontent.com/JetBrains/skiko/0.150.2/$f"
done
echo "--- grep Skia mentions in skiko files"
grep -n -i "skia" "$out/skiko-0.150.2-gradle.properties" | head -20
grep -n -i "milestone\|skia m[0-9]\|chrome/m" "$out/skiko-0.150.2-README.md" | head -20
