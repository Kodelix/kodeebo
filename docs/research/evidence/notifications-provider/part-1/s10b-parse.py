# S10b: parse the raw JSON saved by s10-versions-osv.sh (the grep there matched single-line JSON, so it printed nothing useful: see F116),
# and fetch the OSV record of GHSA-9342-92gg-6v29 as a control for the empty OSV batch result.
import json, urllib.request, sys
R = "docs/research/evidence/notifications-provider/part-1/raw/"
def load(n):
    with open(R + n) as f: return json.load(f)
for n in ("angus-releases.json", "sjm-releases.json"):
    print("==", n)
    for r in load(n)[:6]: print(r.get("tag_name"), r.get("published_at"), r.get("prerelease"))
for n in ("angus-license.json", "sjm-license.json"):
    d = load(n); print("==", n, d.get("license"))
print("== ghsa-angus.json (global advisories, affects=org.eclipse.angus:angus-mail)")
g = load("ghsa-angus.json")
print(type(g).__name__, (g if not isinstance(g, list) else len(g)))
for a in (g if isinstance(g, list) else []):
    print(a.get("ghsa_id"), a.get("cve_id"), a.get("severity"), a.get("published_at"), a.get("summary"))
    for v in a.get("vulnerabilities", []): print("   ", v.get("package"), v.get("vulnerable_version_range"), v.get("first_patched_version"))
print("== OSV control: GHSA-9342-92gg-6v29")
try:
    with urllib.request.urlopen("https://api.osv.dev/v1/vulns/GHSA-9342-92gg-6v29", timeout=40) as x:
        raw = x.read(); open(R + "osv-GHSA-9342-92gg-6v29.json", "wb").write(raw)
    o = json.loads(raw)
    print(o.get("id"), o.get("aliases"), o.get("published"), o.get("summary"))
    print((o.get("details") or "")[:700])
    for a in o.get("affected", []): print("  ", a.get("package"), a.get("ranges"))
    print(o.get("database_specific"))
except Exception as e: print("ERR", e)
