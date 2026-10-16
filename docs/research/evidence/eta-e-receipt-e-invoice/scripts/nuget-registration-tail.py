#!/usr/bin/env python3
"""Print last 8 versions + publish dates from a saved NuGet registration JSON. Usage: python3 -I nuget-registration-tail.py <registration.json>
(Re-run record: the 2026-10-16 run was an inline heredoc of this same logic; output reproduced in nuget-registration-tail.out.txt)"""
import json,sys,gzip,urllib.request
d=json.load(open(sys.argv[1])); items=[]
for p in d["items"]:
    its=p.get("items")
    if its is None:
        b=urllib.request.urlopen(p["@id"],timeout=40).read()
        try: b=gzip.decompress(b)
        except Exception: pass
        its=json.loads(b)["items"]
    items+=its
for i in items[-8:]:
    c=i["catalogEntry"]; print((c["version"],c.get("published"),c.get("listed")))
