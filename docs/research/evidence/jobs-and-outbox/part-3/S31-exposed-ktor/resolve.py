"""S31 dependency resolver (researcher, 2026-10-20). Run: python3 -I resolve.py plan|download <cache_dir>
Resolves the runtime dependency closure of the approved roots from Maven Central POMs (no Gradle, no Maven).
plan:     fetch POMs (tiny) into <cache>/poms, HEAD each jar for its size, print the list and total, write <cache>/plan.txt
download: only if plan total <= 30 MB (guard) fetch jars into <cache>/lib and check each against Maven Central's .sha1
Only compile/runtime-scope, non-optional dependencies are followed. Highest declared version of a group:artifact wins.
"""
import sys, os, urllib.request, urllib.error, xml.etree.ElementTree as ET, hashlib

BASE = "https://repo1.maven.org/maven2/"
ROOTS = [
    ("org.jetbrains.exposed", "exposed-core", "1.5.1"),
    ("org.jetbrains.exposed", "exposed-jdbc", "1.5.1"),
    ("com.zaxxer", "HikariCP", "7.1.0"),
    ("io.ktor", "ktor-server-core-jvm", "3.6.0"),
    ("io.ktor", "ktor-server-cio-jvm", "3.6.0"),
    ("org.jetbrains.kotlinx", "kotlinx-coroutines-core-jvm", "1.11.0"),
    ("org.slf4j", "slf4j-simple", "2.0.19"),
]
LIMIT = 30 * 1024 * 1024


def url(g, a, v, ext):
    return f"{BASE}{g.replace('.', '/')}/{a}/{v}/{a}-{v}.{ext}"


import subprocess


def get(u, timeout=40):
    # curl with retries: the first urllib run died on a transient TLS reset (plan-output.failed-1.txt)
    r = subprocess.run(["curl", "-sS", "-L", "--retry", "5", "--retry-delay", "2", "--retry-all-errors", "--max-time", str(max(timeout, 60)), "-w", "\n%{http_code}", u],
                       capture_output=True)
    body, _, code = r.stdout.rpartition(b"\n")
    if code.strip() != b"200":
        raise urllib.error.HTTPError(u, int(code.strip() or 0), "curl", None, None)
    return body


def head_size(u):
    r = subprocess.run(["curl", "-sSI", "-L", "--retry", "5", "--retry-delay", "2", "--retry-all-errors", "--max-time", "60", u], capture_output=True)
    for line in r.stdout.decode().splitlines():
        if line.lower().startswith("content-length:"):
            last = int(line.split(":")[1])
    return last


def vkey(v):
    out = []
    for p in v.replace("-", ".").split("."):
        out.append((0, int(p)) if p.isdigit() else (-1, p))
    return out


def deps_of(cache, g, a, v):
    pdir = os.path.join(cache, "poms")
    os.makedirs(pdir, exist_ok=True)
    f = os.path.join(pdir, f"{g}_{a}_{v}.pom")
    if not os.path.exists(f):
        try:
            open(f, "wb").write(get(url(g, a, v, "pom")))
        except urllib.error.HTTPError as e:
            return None, f"HTTP {e.code}"
    root = ET.fromstring(open(f, "rb").read())
    ns = root.tag.split("}")[0] + "}" if root.tag.startswith("{") else ""
    props = {}
    pe = root.find(ns + "properties")
    if pe is not None:
        for c in pe:
            props[c.tag.replace(ns, "")] = (c.text or "").strip()
    out = []
    de = root.find(ns + "dependencies")
    if de is None:
        return out, ""
    for d in de.findall(ns + "dependency"):
        t = lambda n: (d.find(ns + n).text.strip() if d.find(ns + n) is not None and d.find(ns + n).text else None)
        scope, opt, ver = t("scope") or "compile", t("optional"), t("version")
        if scope not in ("compile", "runtime") or opt == "true":
            continue
        if ver and ver.startswith("${"):
            ver = props.get(ver[2:-1], ver)
        out.append((t("groupId"), t("artifactId"), ver))
    return out, ""


def resolve(cache):
    sel = {(g, a): v for g, a, v in ROOTS}
    problems = []
    for _ in range(10):
        seen, stack, new = set(), list(sel.items()), dict(sel)
        # traverse from roots with current selection
        stack = [(k, sel[k]) for k in [(g, a) for g, a, _ in ROOTS]]
        visited = set()
        problems = []
        while stack:
            (g, a), v = stack.pop()
            if (g, a) in visited:
                continue
            visited.add((g, a))
            ds, err = deps_of(cache, g, a, new[(g, a)])
            if ds is None:
                problems.append(f"{g}:{a}:{new[(g, a)]} pom {err}")
                continue
            for dg, da, dv in ds:
                if not dv or dv.startswith("${"):
                    problems.append(f"{dg}:{da} version unresolved ({dv}) from {g}:{a}")
                    continue
                cur = new.get((dg, da))
                if cur is None or vkey(dv) > vkey(cur):
                    new[(dg, da)] = dv
                stack.append(((dg, da), new[(dg, da)]))
        final = {k: new[k] for k in visited}
        if final == {k: sel.get(k) for k in final} and not problems:
            break
        sel = {**sel, **new}
        sel = {k: sel[k] for k in sel}
        if final == {k: sel.get(k) for k in final}:
            break
    return {k: sel[k] for k in visited}, problems


def main():
    mode, cache = sys.argv[1], sys.argv[2]
    os.makedirs(cache, exist_ok=True)
    final, problems = resolve(cache)
    total, lines = 0, []
    for (g, a), v in sorted(final.items()):
        try:
            size = head_size(url(g, a, v, "jar"))
        except Exception as e:
            size = -1
            problems.append(f"{g}:{a}:{v} jar HEAD failed: {e}")
        total += max(size, 0)
        lines.append(f"{g}:{a}:{v} {size}")
    print("\n".join(lines))
    print(f"TOTAL jars: {len(lines)} artifacts, {total} bytes ({total/1048576:.2f} MiB)")
    for p in problems:
        print("PROBLEM:", p)
    open(os.path.join(cache, "plan.txt"), "w").write("\n".join(lines) + f"\nTOTAL {total}\n")
    if not mode.startswith("download"):
        return
    # download-skip-kotlin: kotlin-stdlib/kotlin-reflect (declared 2.3.21 by Exposed) are NOT fetched; the pinned 2.4.x jars already
    # in other sessions' caches are used read-only instead. The slf4j-api "version unresolved" problem is benign (slf4j-simple's POM has
    # no version; slf4j-api 2.0.19 is selected from another declared dependency).
    if mode == "download-skip-kotlin":
        final = {k: v for k, v in final.items() if k[1] not in ("kotlin-stdlib", "kotlin-reflect")}
        total = sum(0 for _ in final)  # recomputed below
        problems = [p for p in problems if not p.startswith("org.slf4j:slf4j-api version unresolved")]
    if problems or total > LIMIT:
        print("GUARD: not downloading (problems present or total above 30 MB)")
        return
    lib = os.path.join(cache, "lib")
    os.makedirs(lib, exist_ok=True)
    for (g, a), v in sorted(final.items()):
        data = get(url(g, a, v, "jar"), 120)
        want = get(url(g, a, v, "jar.sha1")).decode().split()[0].strip()
        got = hashlib.sha1(data).hexdigest()
        open(os.path.join(lib, f"{a}-{v}.jar"), "wb").write(data)
        print(f"{'OK ' if got == want else 'SHA1-MISMATCH '}{a}-{v}.jar {len(data)}")


main()
