#!/usr/bin/env python3
"""S40: read-only crawl of the PUBLIC ETA SDK docs site (no auth, no API calls, GET of static pages only)
to grep retention/archive/storage/credit/return statements. Usage: python3 -I s40_crawl_sdk.py OUTDIR
Run 2026-10-16. Stdlib only."""
import sys, re, time, urllib.request, urllib.parse, os, html
out = sys.argv[1]; os.makedirs(out, exist_ok=True)
base = "https://sdk.invoicing.eta.gov.eg/"
seen, queue = set(), [base]
UA = {"User-Agent": "Mozilla/5.0 (kodeebo research, read-only docs crawl)"}
def strip(h):
    h = re.sub(r"(?is)<(script|style).*?</\1>", " ", h)
    h = re.sub(r"(?s)<[^>]+>", " ", h)
    return re.sub(r"\s+", " ", html.unescape(h))
while queue and len(seen) < 400:
    u = queue.pop(0).split("#")[0]
    if u in seen: continue
    seen.add(u)
    try:
        req = urllib.request.Request(u, headers=UA)
        with urllib.request.urlopen(req, timeout=30) as r:
            if "text/html" not in r.headers.get("Content-Type", ""): continue
            h = r.read().decode("utf-8", "replace")
    except Exception as e:
        print("FAIL", u, e); continue
    name = re.sub(r"[^A-Za-z0-9]+", "_", u[len(base):]) or "index"
    open(os.path.join(out, name + ".txt"), "w", encoding="utf-8").write("URL: " + u + "\n" + strip(h))
    for m in re.findall(r'href="([^"]+)"', h):
        v = urllib.parse.urljoin(u, m).split("#")[0]
        if v.startswith(base) and not re.search(r"\.(png|jpg|pdf|zip|json|xml|css|js|svg)$", v) and v not in seen:
            queue.append(v)
    time.sleep(0.3)
print("pages", len(seen))
