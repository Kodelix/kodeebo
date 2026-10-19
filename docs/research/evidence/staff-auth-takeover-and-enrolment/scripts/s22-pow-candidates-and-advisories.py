# S22 (tier E): licences, release dates and OSV advisories for proof-of-work CAPTCHA candidates and Bouncy Castle 1.86.
# Python 3 stdlib only; unauthenticated GitHub REST API, npm registry, Maven Central search, api.osv.dev.
# Run: python3 -I s22-pow-candidates-and-advisories.py
import json, urllib.request, urllib.error, datetime
def get(url, data=None):
    req = urllib.request.Request(url, data=data, headers={"User-Agent": "kodeebo-research-s22", "Accept": "application/json", **({"Content-Type": "application/json"} if data else {})})
    try:
        with urllib.request.urlopen(req, timeout=25) as r: return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e: return e.code, None
    except Exception as e: return -1, str(e)
print("run at", datetime.datetime.now(datetime.timezone.utc).isoformat())
repos = ["altcha-org/altcha", "altcha-org/altcha-lib", "altcha-org/altcha-lib-java", "altcha-org/altcha-lib-kotlin",
         "mCaptcha/mCaptcha", "tiagozip/cap", "TecharoHQ/anubis", "friendlycaptcha/friendly-challenge", "friendlycaptcha/friendly-lite-server"]
print("== GitHub repos ==")
for r in repos:
    s, j = get("https://api.github.com/repos/" + r)
    if s != 200: print(r, "-> HTTP", s); continue
    lic = (j.get("license") or {}).get("spdx_id")
    rs, rj = get("https://api.github.com/repos/%s/releases/latest" % r)
    rel = (rj.get("tag_name"), (rj.get("published_at") or "")[:10]) if rs == 200 and rj else ("no release", rs)
    print(r, "| licence:", lic, "| archived:", j.get("archived"), "| pushed:", j.get("pushed_at", "")[:10], "| stars:", j.get("stargazers_count"), "| latest release:", rel, "| desc:", (j.get("description") or "")[:90])
print("== npm ==")
npm = {}
for p in ["altcha", "altcha-lib", "@cap.js/widget", "@cap.js/server"]:
    s, j = get("https://registry.npmjs.org/" + p.replace("/", "%2F"))
    if s != 200: print(p, "-> HTTP", s); continue
    v = j["dist-tags"]["latest"]; npm[p] = v
    print(p, "latest", v, "published", j["time"].get(v, "")[:10], "licence", j["versions"][v].get("license"))
print("== Maven Central: bcprov-jdk18on 1.86 present? ==")
s, j = get("https://search.maven.org/solrsearch/select?q=g:org.bouncycastle+AND+a:bcprov-jdk18on+AND+v:1.86&core=gav&rows=1&wt=json")
print("maven status", s, json.dumps(j.get("response", {}).get("docs", j) if isinstance(j, dict) else j)[:300])
print("== OSV ==")
def osv(eco, name, ver):
    s, j = get("https://api.osv.dev/v1/query", json.dumps({"version": ver, "package": {"name": name, "ecosystem": eco}}).encode())
    ids = [v["id"] for v in (j or {}).get("vulns", [])] if s == 200 else None
    print(eco, name, ver, "-> HTTP", s, "advisories:", ids)
osv("Maven", "org.bouncycastle:bcprov-jdk18on", "1.86")
for p, v in npm.items(): osv("npm", p, v)
osv("Maven", "org.apache.logging.log4j:log4j-core", "2.14.1")  # control: must be non-empty
