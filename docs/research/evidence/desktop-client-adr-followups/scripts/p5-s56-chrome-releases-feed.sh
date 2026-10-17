#!/usr/bin/env bash
# S56 (part 5): Chrome Releases blog (Blogger JSON feed) posts that mention Chromium 152.0.7977.x; list title, date, version strings and CVE ids with their severity/component lines.
# Run: bash scripts/p5-s56-chrome-releases-feed.sh <outdir>
set -u
out="$1"; mkdir -p "$out"
date -u +"run %Y-%m-%dT%H:%MZ"
curl -sSL -m 90 -o "$out/chrome-releases-152.json" -w "feed HTTP %{http_code} %{size_download} bytes\n" "https://chromereleases.googleblog.com/feeds/posts/default?q=152.0.7977&max-results=60&alt=json"
python3 -I - "$out/chrome-releases-152.json" <<'PY'
import json, re, sys, html
d = json.load(open(sys.argv[1]))
ents = d["feed"].get("entry", [])
print("posts:", len(ents))
allcves = {}
for e in ents:
    title = e["title"]["$t"]; pub = e["published"]["$t"][:10]
    body = html.unescape(re.sub(r"<[^>]+>", "\n", e.get("content", {}).get("$t", "")))
    vers = sorted(set(re.findall(r"152\.0\.7977\.\d+(?:/\.?\d+)*", body)))
    cves = re.findall(r"(?:\[[^\]]*\]\s*)?(?:Critical|High|Medium|Low)\s*[:\-]?\s*CVE-\d{4}-\d+[^\n]*", body)
    print(f"\n## {pub} | {title} | versions {vers[:6]} | link {[l['href'] for l in e['link'] if l['rel']=='alternate']}")
    labels = [c["term"] for c in e.get("category", [])]
    print("   labels:", labels)
    for m in re.finditer(r"CVE-\d{4}-\d+", body): allcves.setdefault(m.group(0), pub)
    for c in cves[:40]: print("   ", c.strip()[:220])
    if "Security Fixes and Rewards" in body or "security fix" in body.lower():
        i = body.lower().find("security fixes")
        print("   secfix text:", re.sub(r"\s+", " ", body[i:i+300]))
print("\nCVE ids seen across these posts:", len(allcves))
PY
