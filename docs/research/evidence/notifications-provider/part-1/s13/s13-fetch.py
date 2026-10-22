"""S13 step 1: resolve the versions of angus-mail 2.0.5's runtime dependencies from its
parent pom chain, read each jar's size (HTTP HEAD), print the list, stop if the total is
over 3 MB, otherwise download the four jars into the cache and verify the .sha1.

Run from the repository root:  python3 -I docs/research/evidence/notifications-provider/part-1/s13/s13-fetch.py
Network: repo1.maven.org only. Writes: production/session-state/cache/notifications-provider/ only.
"""
import hashlib, os, re, sys, urllib.request
import xml.etree.ElementTree as ET

BASE = "https://repo1.maven.org/maven2/"
CACHE = "production/session-state/cache/notifications-provider"
LIMIT = 3 * 1024 * 1024
NS = {"m": "http://maven.apache.org/POM/4.0.0"}


def url(g, a, v, ext):
    return f"{BASE}{g.replace('.', '/')}/{a}/{v}/{a}-{v}.{ext}"


def get(u):
    with urllib.request.urlopen(u, timeout=30) as r:
        return r.read()


def head(u):
    req = urllib.request.Request(u, method="HEAD")
    with urllib.request.urlopen(req, timeout=30) as r:
        return int(r.headers.get("Content-Length", "-1"))


os.makedirs(CACHE + "/poms", exist_ok=True)
os.makedirs(CACHE + "/jars", exist_ok=True)

# 1. pom chain: angus-mail -> all -> (its parent ...)
chain = []
props = {}
dm = {}
g, a, v = "org.eclipse.angus", "angus-mail", "2.0.5"
for depth in range(5):
    u = url(g, a, v, "pom")
    data = get(u)
    open(f"{CACHE}/poms/{a}-{v}.pom", "wb").write(data)
    chain.append((g, a, v, u, len(data)))
    root = ET.fromstring(data)
    for p in root.findall("m:properties/*", NS):
        props.setdefault(p.tag.split("}")[1], (p.text or "").strip())
    for d in root.findall("m:dependencyManagement/m:dependencies/m:dependency", NS):
        key = (d.findtext("m:groupId", "", NS), d.findtext("m:artifactId", "", NS))
        dm.setdefault(key, d.findtext("m:version", "", NS))
    par = root.find("m:parent", NS)
    if par is None:
        break
    g, a, v = (par.findtext("m:groupId", "", NS), par.findtext("m:artifactId", "", NS),
               par.findtext("m:version", "", NS))

print("POM CHAIN (fetched, small):")
for g_, a_, v_, u_, n in chain:
    print(f"  {g_}:{a_}:{v_}  {n} bytes  {u_}")


def resolve(s):
    for _ in range(5):
        s = re.sub(r"\$\{([^}]+)\}", lambda m: props.get(m.group(1), m.group(0)), s)
    return s


want = [
    ("org.eclipse.angus", "angus-mail", "2.0.5"),
    ("jakarta.mail", "jakarta.mail-api", None),
    ("jakarta.activation", "jakarta.activation-api", None),
    ("org.eclipse.angus", "angus-activation", None),
]
jars = []
for g_, a_, v_ in want:
    if v_ is None:
        raw = dm.get((g_, a_))
        v_ = resolve(raw) if raw else None
        print(f"dependencyManagement {g_}:{a_} = {raw!r} -> {v_!r}")
    if not v_ or "${" in v_:
        print("UNRESOLVED version for", g_, a_, "- stop, needs a human")
        sys.exit(2)
    jars.append((g_, a_, v_))

print("\nJAR LIST (HEAD sizes):")
total = 0
sizes = {}
for g_, a_, v_ in jars:
    u = url(g_, a_, v_, "jar")
    n = head(u)
    sizes[(g_, a_, v_)] = n
    total += n
    print(f"  {g_}:{a_}:{v_}  {n} bytes  {u}")
print(f"TOTAL {total} bytes ({total/1024/1024:.2f} MiB); limit {LIMIT}")
if total > LIMIT or total <= 0:
    print("needs approval: total over limit or unknown; NOT downloading")
    sys.exit(3)

# 2. download and verify against Maven Central .sha1
print("\nDOWNLOAD + VERIFY:")
ok_all = True
for g_, a_, v_ in jars:
    u = url(g_, a_, v_, "jar")
    data = get(u)
    path = f"{CACHE}/jars/{a_}-{v_}.jar"
    open(path, "wb").write(data)
    sha1_remote = get(u + ".sha1").decode().split()[0].strip().lower()
    sha1_local = hashlib.sha1(data).hexdigest()
    ok = sha1_remote == sha1_local
    ok_all &= ok
    print(f"  {a_}-{v_}.jar  {len(data)} bytes  sha1 {sha1_local}  maven-central .sha1 {sha1_remote}  {'MATCH' if ok else 'MISMATCH'}")
print("ALL SHA1 MATCH" if ok_all else "SHA1 MISMATCH - do not use")
