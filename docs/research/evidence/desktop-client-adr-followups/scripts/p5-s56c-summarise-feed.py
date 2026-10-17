#!/usr/bin/env python3
# S56c (part 5): clean summary of the saved Chrome Releases feed (fetched/p5-s55/chrome-releases-since-0820.json, from S56b). Read-only.
# Run: python3 -I scripts/p5-s56c-summarise-feed.py fetched/p5-s55/chrome-releases-since-0820.json
import json, re, sys, html
d = json.load(open(sys.argv[1]))
ents = d["feed"].get("entry", [])
print("posts in feed:", len(ents))
rows = []
for e in ents:
    body = html.unescape(re.sub(r"<[^>]+>", " ", e.get("content", {}).get("$t", "")))
    body = re.sub(r"\s+", " ", body)
    title = e["title"]["$t"]; pub = e["published"]["$t"][:10]
    labels = [c["term"] for c in e.get("category", [])]
    vers = sorted(set(re.findall(r"\b15[23]\.0\.\d{4}\.\d+", body)))
    cves = re.findall(r"(Critical|High|Medium|Low)\s+(CVE-\d{4}-\d+)", body)
    n = re.search(r"There (?:are|is) (\d+) security fix", body)
    itw = re.findall(r"[^.]{0,120}(?:exploit[^.]{0,80}in the wild|in the wild)[^.]{0,60}", body)
    rows.append((pub, title, labels, vers, cves, n.group(1) if n else None, itw))
rows.sort()
for pub, title, labels, vers, cves, n, itw in rows:
    if not vers: continue
    sev = {}
    for s, c in cves: sev[s] = sev.get(s, 0) + 1
    print(f"{pub} | {title} | {labels} | versions {vers} | 'There are N security fixes' = {n} | listed CVEs {len(cves)} {sev}")
    if itw: print("    in-the-wild text:", itw[0].strip()[:240])
print("\n-- CVE lists for posts naming 152.0.7977.x with security fixes")
for pub, title, labels, vers, cves, n, itw in rows:
    if any(v.startswith("152.0.7977") for v in vers) and cves:
        print(f"\n{pub} {title} {vers}: " + ", ".join(f"{s}:{c}" for s, c in cves))
