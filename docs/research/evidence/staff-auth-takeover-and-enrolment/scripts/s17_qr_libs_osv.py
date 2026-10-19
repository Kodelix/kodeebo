"""S17 (tier-E): QR-renderer candidates for the counter (only needed for option B2) -- exact latest
versions, release dates and OSV advisories for those exact versions, with a live control query.
Usage: python3 -I s17_qr_libs_osv.py
Network: Maven Central search API, npm registry, api.osv.dev. Stdlib only; writes to stdout. JSON only (< 1 MB)."""
import datetime
import json
import urllib.request


def get(url, data=None):
    req = urllib.request.Request(url, data=data, headers={"User-Agent": "kodeebo-research/1.0",
                                                          "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=40) as r:
        return json.loads(r.read().decode("utf-8"))


def osv(ecosystem, name, version):
    body = json.dumps({"package": {"name": name, "ecosystem": ecosystem}, "version": version}).encode()
    res = get("https://api.osv.dev/v1/query", body)
    ids = [v["id"] for v in res.get("vulns", [])]
    return ids


print("run:", datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%MZ"))

# Maven: zxing core
m = get("https://search.maven.org/solrsearch/select?q=g:com.google.zxing+AND+a:core&core=gav&rows=3&wt=json")
for d in m["response"]["docs"]:
    when = datetime.datetime.fromtimestamp(d["timestamp"] / 1000, datetime.timezone.utc).strftime("%Y-%m-%d")
    print("maven com.google.zxing:core", d["v"], "released", when)
zx = m["response"]["docs"][0]["v"]
print("OSV Maven com.google.zxing:core", zx, "->", osv("Maven", "com.google.zxing:core", zx))

# npm: qrcode
n = get("https://registry.npmjs.org/qrcode")
latest = n["dist-tags"]["latest"]
print("npm qrcode latest", latest, "released", n["time"].get(latest), "license", n.get("license"))
print("OSV npm qrcode", latest, "->", osv("npm", "qrcode", latest))

# control: a version known to have advisories, so an empty result above is meaningful
print("CONTROL OSV Maven org.apache.logging.log4j:log4j-core 2.14.1 ->", len(osv("Maven", "org.apache.logging.log4j:log4j-core", "2.14.1")), "advisories")
