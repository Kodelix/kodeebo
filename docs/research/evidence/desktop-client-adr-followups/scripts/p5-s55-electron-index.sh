#!/usr/bin/env bash
# S55 (part 5): which Chromium/Node/V8 each Electron 44.x release carries (electronjs.org headers index) and the release notes of 44.8.0 and 44.9.0 (GitHub releases API, unauthenticated).
# Run: bash scripts/p5-s55-electron-index.sh <outdir>
set -u
out="$1"; mkdir -p "$out"
date -u +"run %Y-%m-%dT%H:%MZ"
curl -sS -m 60 -o "$out/electron-index.json" -w "index.json HTTP %{http_code} %{size_download} bytes\n" https://electronjs.org/headers/index.json
for v in v44.8.0 v44.9.0; do
  curl -sS -m 60 -H "Accept: application/vnd.github+json" -o "$out/electron-release-$v.json" -w "release $v HTTP %{http_code} %{size_download} bytes\n" "https://api.github.com/repos/electron/electron/releases/tags/$v"
done
python3 -I - "$out" <<'PY'
import json, sys
out = sys.argv[1]
idx = json.load(open(out + "/electron-index.json"))
rows = [r for r in idx if r["version"].startswith("44.")]
rows.sort(key=lambda r: [int(x) if x.isdigit() else 0 for x in r["version"].replace("-", ".").split(".")[:3]])
print("Electron 44.x entries:", len(rows))
for r in rows:
    print(r["version"], r.get("date"), "chrome", r.get("chrome"), "node", r.get("node"), "v8", r.get("v8"))
for v in ("v44.8.0", "v44.9.0"):
    try:
        d = json.load(open(f"{out}/electron-release-{v}.json"))
        print("\n== release notes", v, d.get("published_at"), "\n", (d.get("body") or "")[:2500])
    except Exception as e:
        print("release", v, "could not parse", e)
PY
