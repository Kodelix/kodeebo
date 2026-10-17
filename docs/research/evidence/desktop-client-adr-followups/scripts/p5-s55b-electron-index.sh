#!/usr/bin/env bash
# S55b (part 5): re-run of S55 with curl -L (S55's index request got HTTP 301 and no redirect follow: wrong test, its output kept as p5-s55-electron-index.output.txt.WRONG-no-redirect-follow.txt).
# Run: bash scripts/p5-s55b-electron-index.sh <outdir>   (release JSON from S55 is reused)
set -u
out="$1"
date -u +"run %Y-%m-%dT%H:%MZ"
curl -sSL -m 90 -o "$out/electron-index.json" -w "index.json HTTP %{http_code} %{size_download} bytes final %{url_effective}\n" https://electronjs.org/headers/index.json
python3 -I - "$out" <<'PY'
import json, sys
out = sys.argv[1]
idx = json.load(open(out + "/electron-index.json"))
rows = [r for r in idx if r["version"].startswith("44.")]
key = lambda r: [int(x) if x.isdigit() else -1 for x in r["version"].replace("-", ".").split(".")]
rows.sort(key=key)
print("Electron 44.x entries:", len(rows))
for r in rows:
    print(r["version"], r.get("date"), "chrome", r.get("chrome"), "node", r.get("node"), "v8", r.get("v8"))
for v in ("v44.8.0", "v44.9.0"):
    d = json.load(open(f"{out}/electron-release-{v}.json"))
    print("\n== release notes", v, d.get("published_at"), "body length", len(d.get("body") or ""), "\n", (d.get("body") or "")[:3000])
PY
