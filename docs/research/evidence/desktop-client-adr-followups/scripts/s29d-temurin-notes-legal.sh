#!/usr/bin/env bash
# S29d (part 2): (1) Adoptium release-notes API for jdk-21.0.12.1+1 (does it list the fixed CVEs of the 2026-08-18 advisory?);
# (2) list the `legal/` entries of the spike's already-downloaded Temurin JDK zip (names and sizes only, nothing extracted or run).
# Usage: s29d-temurin-notes-legal.sh <jdk-zip> <outdir>
set -u
zip="$1"; out="$2"; mkdir -p "$out"
date -u +"run at %Y-%m-%dT%H:%MZ"
for rn in 'jdk-21.0.12.1%2B1' 'jdk-21.0.12.1%2B1.1'; do
  code=$(curl -sS --max-time 30 -o "$out/adoptium-relnotes-$rn.json" -w '%{http_code}' "https://api.adoptium.net/v3/info/release_notes/$rn"); echo "release_notes/$rn -> HTTP $code, $(wc -c < "$out/adoptium-relnotes-$rn.json") bytes"
  python3 -I -c '
import json,sys
try: d=json.load(open(sys.argv[1]))
except Exception as e: print("not json:", e); sys.exit()
print("keys:", list(d)[:10])
for n in d.get("release_notes",[])[:60]:
    t=(n.get("title") or "")+" "+(n.get("priority") or "")
    if "CVE" in t or "security" in t.lower() or "Security" in str(n.get("component","")): print("  ", n.get("id"), t[:150])
print("notes:", len(d.get("release_notes",[])))
' "$out/adoptium-relnotes-$rn.json"
done
python3 -I - "$zip" <<'PY'
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
leg = [i for i in z.infolist() if "/legal/" in i.filename and not i.filename.endswith("/")]
print("legal entries:", len(leg))
mods = sorted({i.filename.split("/legal/")[1].split("/")[0] for i in leg})
print("legal module folders:", len(mods), mods[:60])
for i in z.infolist():
    if i.filename.count("/") <= 1 and not i.filename.endswith("/"): print("top-level file:", i.filename, i.file_size)
PY
