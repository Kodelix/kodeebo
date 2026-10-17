#!/usr/bin/env bash
# S59 (part 5): NVD CVE API 2.0 queries for ICU 74.2 (CPE), WiX Toolset (keyword) and NSIS (keyword), plus GitHub repo advisories for wixtoolset/wix3 and NSIS-related repos. Unauthenticated NVD: 5 requests per 30 s, so the calls are spaced.
# Run: bash scripts/p5-s59-nvd-wix-nsis-icu.sh <outdir>
set -u
out="$1"; mkdir -p "$out"
date -u +"run %Y-%m-%dT%H:%MZ"
nvd() { curl -sSL -m 90 -o "$out/$1.json" -w "$1 HTTP %{http_code} %{size_download} bytes\n" "https://services.nvd.nist.gov/rest/json/cves/2.0?$2"; sleep 8; }
nvd nvd-icu-74.2 "cpeName=cpe:2.3:a:icu-project:international_components_for_unicode:74.2:*:*:*:*:*:*:*"
nvd nvd-wix-keyword "keywordSearch=WiX%20Toolset"
nvd nvd-nsis-keyword "keywordSearch=Nullsoft%20Scriptable%20Install%20System"
nvd nvd-nsis-short "keywordSearch=NSIS%20installer"
python3 -I - "$out" <<'PY'
import json, sys, re
out = sys.argv[1]
for name in ("nvd-icu-74.2", "nvd-wix-keyword", "nvd-nsis-keyword", "nvd-nsis-short"):
    try: d = json.load(open(f"{out}/{name}.json"))
    except Exception as e: print(name, "could not parse", e); continue
    vs = d.get("vulnerabilities", [])
    print(f"\n== {name}: totalResults {d.get('totalResults')}, returned {len(vs)}")
    for v in vs[:40]:
        c = v["cve"]; desc = next((x["value"] for x in c["descriptions"] if x["lang"] == "en"), "")
        print(" ", c["id"], c.get("published","")[:10], "|", re.sub(r"\s+", " ", desc)[:230])
PY
echo "--- GitHub repo advisories"
for r in wixtoolset/wix3 wixtoolset/wix; do echo "$r:"; gh api "repos/$r/security-advisories?state=published&per_page=50" 2>&1 | head -c 300; echo; done
