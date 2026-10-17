#!/usr/bin/env python3
# S59b was re-run after a KeyError on a CVSS metric without cvssData (first output kept as p5-s59b-read-nvd.output.txt.FAILED-KeyError-cvssData.txt).
# S59b (part 5): full NVD descriptions, CPE version bounds, CVSS and references for the WiX and NSIS CVEs saved by S59. Read-only.
# Run: python3 -I scripts/p5-s59b-read-nvd.py fetched/p5-s59
import json, sys, re
out = sys.argv[1]
want = {"CVE-2019-16511","CVE-2024-24810","CVE-2024-29187","CVE-2024-29188","CVE-2015-9267","CVE-2015-9268","CVE-2023-37378","CVE-2025-43715"}
seen = set()
for name in ("nvd-wix-keyword", "nvd-nsis-keyword"):
    for v in json.load(open(f"{out}/{name}.json"))["vulnerabilities"]:
        c = v["cve"]
        if c["id"] in seen or c["id"] not in want: continue
        seen.add(c["id"])
        desc = next(x["value"] for x in c["descriptions"] if x["lang"] == "en")
        print(f"\n== {c['id']} published {c['published'][:10]} lastModified {c['lastModified'][:10]} status {c.get('vulnStatus')}")
        print("   ", re.sub(r"\s+", " ", desc))
        for k, ms in c.get("metrics", {}).items():
            for m in ms:
                d = m.get("cvssData", m); print("    metric", k, d.get("baseScore"), d.get("baseSeverity"), d.get("vectorString"))
        for cfg in c.get("configurations", []):
            for node in cfg.get("nodes", []):
                for m in node.get("cpeMatch", []):
                    print("    cpe", m["criteria"], {k: m[k] for k in ("versionStartIncluding","versionEndExcluding","versionEndIncluding") if k in m}, "vulnerable" if m["vulnerable"] else "")
        print("    refs:", [r["url"] for r in c.get("references", [])][:8])
