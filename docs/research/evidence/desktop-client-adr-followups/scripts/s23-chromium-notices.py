#!/usr/bin/env python3
# S23 (part 2): classify the product entries in Electron 44.8.0's LICENSES.chromium.html by copyleft markers.
# Read-only parse of a text file (untrusted data, never executed). Run: python3 -I s23-chromium-notices.py <html>
import re, sys, html
src = open(sys.argv[1], encoding="utf-8", errors="replace").read()
prods = re.findall(r'<div class="product">\s*<span class="title">(.*?)</span>(.*?)(?=<div class="product">|$)', src, flags=re.S)
print("products:", len(prods))
pat = {
 "LGPL": re.compile(r"GNU (Lesser|Library) General Public License", re.I),
 "GPL": re.compile(r"GNU General Public License", re.I),
 "AGPL": re.compile(r"Affero", re.I),
 "MPL": re.compile(r"Mozilla Public License", re.I),
 "EPL/CDDL": re.compile(r"(Eclipse Public License|Common Development and Distribution)", re.I),
 "SSPL/BUSL/proprietary": re.compile(r"(Server Side Public|Business Source|All rights reserved\.? ?This software is proprietary)", re.I),
}
hits = {k: [] for k in pat}
for title, body in prods:
    t = html.unescape(title).strip()
    for k, rx in pat.items():
        if rx.search(body):
            hits[k].append(t)
for k, v in hits.items():
    print(f"\n== {k}: {len(v)} entries")
    for t in v[:60]:
        print("  -", t)
# Show the licence text excerpts of entries that mention LGPL, trimmed to 300 chars around first match
print("\n== LGPL entry excerpts")
for title, body in prods:
    m = pat["LGPL"].search(body)
    if m:
        s = re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", body)))
        i = max(0, s.find(m.group(0)) - 150)
        print("*", html.unescape(title).strip(), "::", s[i:i+330])
