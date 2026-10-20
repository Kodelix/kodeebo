#!/usr/bin/env python3
"""S44 (tier E): read-only HTTP GETs for release metadata, asset sizes and published
security advisories of the candidate signing tools, plus OSV package queries.
No download of any asset (metadata only). No credentials. Run: python3 -I <this file>
"""
import json
import sys
import urllib.request
from datetime import datetime, timezone

UA = {"User-Agent": "kodeebo-research-s44", "Accept": "application/vnd.github+json"}


def get(url):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def post(url, body):
    req = urllib.request.Request(url, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


print("# S44 run", datetime.now(timezone.utc).isoformat())
for repo in ["sigstore/cosign", "jedisct1/minisign", "jedisct1/zig-minisign", "openssh/openssh-portable"]:
    print("\n## releases/latest", repo)
    try:
        j = get(f"https://api.github.com/repos/{repo}/releases/latest")
        print("tag", j.get("tag_name"), "published", j.get("published_at"), "prerelease", j.get("prerelease"))
        for a in j.get("assets", []):
            n = a["name"]
            if any(k in n for k in ("linux-amd64", "linux-x86_64", "linux")) or len(j["assets"]) < 8:
                print("  asset", n, a["size"])
    except Exception as e:  # report, never hide
        print("ERROR", repr(e))

for repo in ["sigstore/cosign", "jedisct1/minisign", "jedisct1/zig-minisign", "openssh/openssh-portable"]:
    print("\n## repository security advisories (published)", repo)
    try:
        j = get(f"https://api.github.com/repos/{repo}/security-advisories?per_page=30")
        print("count", len(j))
        for a in j:
            vul = [(v.get("package", {}).get("name"), v.get("vulnerable_version_range"), v.get("patched_versions")) for v in a.get("vulnerabilities", [])]
            print(" ", a.get("ghsa_id"), a.get("cve_id"), a.get("severity"), a.get("published_at", "")[:10], "|", a.get("summary"), "|", vul)
    except Exception as e:
        print("ERROR", repr(e))

print("\n## OSV package queries")
for eco, name in [("Go", "github.com/sigstore/cosign/v2"), ("Go", "github.com/sigstore/cosign/v3"), ("Go", "github.com/sigstore/cosign"),
                  ("GitHub Actions", "sigstore/cosign-installer"), ("Debian:13", "openssh"), ("Alpine", "openssh")]:
    try:
        j = post("https://api.osv.dev/v1/query", {"package": {"name": name, "ecosystem": eco}})
        vs = j.get("vulns", [])
        print(eco, name, "records", len(vs))
        for v in vs[:40]:
            print("  ", v["id"], (v.get("published") or "")[:10], "|", (v.get("summary") or "")[:110])
    except Exception as e:
        print(eco, name, "ERROR", repr(e))
