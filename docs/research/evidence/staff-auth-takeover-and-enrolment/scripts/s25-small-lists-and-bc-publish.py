# S25 (tier E): (1) sizes (no download of the files) and licence of small common-password lists in SecLists via the GitHub contents API;
# (2) whether bcprov-jdk18on 1.86 is on Maven Central (HEAD on the pom). Python 3 stdlib only. Run: python3 -I s25-small-lists-and-bc-publish.py
import json, urllib.request, urllib.error, datetime
H = {"User-Agent": "kodeebo-research-s25", "Accept": "application/json"}
def get(url, method="GET"):
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=H, method=method), timeout=25) as r:
            return r.status, (json.loads(r.read()) if method == "GET" else dict(r.headers))
    except urllib.error.HTTPError as e: return e.code, None
print("run at", datetime.datetime.now(datetime.timezone.utc).isoformat())
s, j = get("https://api.github.com/repos/danielmiessler/SecLists")
print("SecLists repo:", s, (j or {}).get("license"), "pushed", (j or {}).get("pushed_at"))
s, j = get("https://api.github.com/repos/danielmiessler/SecLists/contents/Passwords/Common-Credentials")
if s == 200:
    for f in sorted(j, key=lambda x: -x["size"]):
        if f["type"] == "file" and f["size"] > 200_000 or "10k" in f["name"] or "top-1000000" in f["name"]:
            print("  %-70s %12d bytes" % (f["name"], f["size"]))
    print("  files listed:", len(j))
else: print("contents API status", s)
for v in ("1.86", "1.85"):
    s, h = get("https://repo1.maven.org/maven2/org/bouncycastle/bcprov-jdk18on/%s/bcprov-jdk18on-%s.pom" % (v, v), "HEAD")
    print("Maven Central bcprov-jdk18on", v, "-> HTTP", s, "Last-Modified:", (h or {}).get("Last-Modified"))
