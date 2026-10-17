#!/usr/bin/env bash
# S57b (part 5): S57 guessed the tag "0.150.2" and got 404 (wrong test, output kept as p5-s57-skiko-skia-deps.output.txt.WRONG-tag-name-404.txt). List the real tags and releases, then read the matching files.
# Run: bash scripts/p5-s57b-skiko-tags.sh <outdir>
set -u
out="$1"; mkdir -p "$out"
date -u +"run %Y-%m-%dT%H:%MZ"
H='Accept: application/vnd.github+json'
curl -sSL -m 60 -H "$H" -o "$out/skiko-tags.json" -w "tags HTTP %{http_code}\n" "https://api.github.com/repos/JetBrains/skiko/tags?per_page=60"
curl -sSL -m 60 -H "$H" -o "$out/skiko-releases.json" -w "releases HTTP %{http_code}\n" "https://api.github.com/repos/JetBrains/skiko/releases?per_page=30"
python3 -I - "$out" <<'PY'
import json, sys
out = sys.argv[1]
tags = json.load(open(out + "/skiko-tags.json"))
print("tags:", [t["name"] for t in tags][:60])
rel = json.load(open(out + "/skiko-releases.json"))
for r in rel[:30]:
    print("release", r["tag_name"], r["published_at"], "|", r["name"])
hit = [r for r in rel if "0.150.2" in (r["tag_name"] + (r["name"] or ""))]
for r in hit: print("\n== 0.150.2 release body:\n", (r.get("body") or "")[:3500])
PY
