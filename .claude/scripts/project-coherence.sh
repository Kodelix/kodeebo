#!/usr/bin/env bash
#
# project-coherence.sh — compare what the product DECLARES (go.mod, Gradle
# version catalogs, package.json, Compose files, project.yaml) against the
# studio's recommended pins in docs/stack-reference/pins.yaml.
#
# OBSERVATIONS, NEVER VERDICTS. Prints one line per comparison and always
# exits 0; the reader (or /setup-stack, /dependency-audit, /gate-check)
# decides. A comparison that cannot run says so — silence is never "fine".
#
# Line format:  <STATUS>  <layer>.<key>  declared=<v>  pin=<v>  (<file>)
#   MATCH     declared == pin
#   AHEAD     declared  > pin   (fine; pins.yaml may be stale — re-verify)
#   BEHIND    declared  < pin   (missing fixes; check breaking-changes.md first)
#   FLOATING  image tag is `latest` or a bare major — not reproducible
#   LICENCE   an engine in deploy/self-hosted/ that breaks the licence decisions
#   ABSENT    the manifest or key was not found (layer may not be used)
#   SKIPPED   the check could not run, with the reason
#
# Usage: bash .claude/scripts/project-coherence.sh

set -u
cd "$(dirname "$0")/../.." || { echo "project-coherence: cannot reach repo root" >&2; exit 0; }

PY=""
for c in python3 python py; do
    if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; sys.exit(sys.version_info[0] < 3)' 2>/dev/null; then PY="$c"; break; fi
done
if [ -z "$PY" ]; then echo "SKIPPED  all  no Python 3 interpreter — no comparison ran"; exit 0; fi
if [ ! -f docs/stack-reference/pins.yaml ]; then echo "SKIPPED  all  docs/stack-reference/pins.yaml missing — run /setup-stack"; exit 0; fi

"$PY" - <<'PYEOF'
import glob, json, os, re, subprocess

def load_yaml_flat(path):
    """Minimal two-level YAML reader for pins.yaml / project.yaml (no deps)."""
    out, section = {}, None
    for raw in open(path, encoding="utf-8"):
        line = raw.split(" #", 1)[0].rstrip()
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        m = re.match(r"^([A-Za-z0-9_.-]+):\s*(.*)$", line)
        if m and not raw.startswith((" ", "\t")):
            section = m.group(1)
            if m.group(2):
                out[section] = m.group(2).strip().strip('"\'')
            continue
        m = re.match(r"^\s+([A-Za-z0-9_.-]+):\s*(.*)$", line)
        if m and section:
            out[f"{section}.{m.group(1)}"] = m.group(2).strip().strip('"\'')
    return out

pins = load_yaml_flat("docs/stack-reference/pins.yaml")
proj = load_yaml_flat("project.yaml") if os.path.isfile("project.yaml") else {}

def vt(v):
    v = re.sub(r"^[v^~>=<\s]+", "", str(v))
    parts = re.findall(r"\d+", v.split("-")[0])
    return tuple(int(p) for p in parts[:4]) if parts else None

def report(layer_key, declared, src):
    pin = pins.get(layer_key)
    if pin is None:
        return
    if declared is None:
        print(f"ABSENT    {layer_key}  pin={pin}  ({src})")
        return
    a, b = vt(declared), vt(pin)
    if a is None or b is None:
        print(f"SKIPPED   {layer_key}  declared={declared}  pin={pin}  ({src}: not a comparable version)")
        return
    n = min(len(a), len(b))
    status = "MATCH" if a[:n] == b[:n] else ("AHEAD" if a[:n] > b[:n] else "BEHIND")
    print(f"{status:<9} {layer_key}  declared={declared}  pin={pin}  ({src})")

# --- Go ------------------------------------------------------------------------
gomods = [p for p in glob.glob("**/go.mod", recursive=True) if "/vendor/" not in p and "node_modules" not in p]
for gm in gomods:
    txt = open(gm, encoding="utf-8").read()
    m = re.search(r"^go\s+(\S+)", txt, re.M);         report("go.go_directive", m.group(1) if m else None, gm)
    m = re.search(r"^toolchain\s+go(\S+)", txt, re.M); report("go.toolchain", m.group(1) if m else None, gm)
    m = re.search(r"github\.com/jackc/pgx/v5\s+v(\S+)", txt)
    if m: report("go.pgx", m.group(1), gm)
if not gomods and proj.get("stack.backend", "").startswith("go"):
    print("ABSENT    go  stack.backend is go but no go.mod found")

# --- Gradle version catalogs (Ktor backend, Android, KMP) -----------------------
CAT = {"ktor": "ktor.ktor", "exposed": "ktor.exposed", "hikari": "ktor.hikaricp", "hikaricp": "ktor.hikaricp",
       "kotlin": "kotlin.kotlin", "coroutines": "kotlin.coroutines", "kotlinx-coroutines": "kotlin.coroutines",
       "compose-bom": "compose.bom", "composeBom": "compose.bom", "androidx-compose-bom": "compose.bom",
       "agp": "compose.agp", "android-gradle-plugin": "compose.agp",
       "compose-multiplatform": "kmp.compose_multiplatform", "composeMultiplatform": "kmp.compose_multiplatform",
       "sqldelight": "kmp.sqldelight", "room": "kmp.room"}
for cat in glob.glob("**/gradle/libs.versions.toml", recursive=True):
    inver = False
    for line in open(cat, encoding="utf-8"):
        s = line.strip()
        if s.startswith("["):
            inver = s == "[versions]"; continue
        m = re.match(r'^([A-Za-z0-9_.-]+)\s*=\s*"([^"]+)"', s)
        if inver and m and m.group(1) in CAT:
            report(CAT[m.group(1)], m.group(2), cat)
for kts in glob.glob("**/build.gradle.kts", recursive=True):
    txt = open(kts, encoding="utf-8").read()
    m = re.search(r"targetSdk\s*=\s*(\d+)", txt)
    if m: report("compose.target_sdk", m.group(1), kts)
for gw in glob.glob("**/gradle/wrapper/gradle-wrapper.properties", recursive=True):
    m = re.search(r"gradle-([\d.]+)-", open(gw, encoding="utf-8").read())
    if m: report("kotlin.gradle", m.group(1), gw)

# --- package.json (web app, marketing site) -------------------------------------
NPM = {"react": "vite-react.react", "vite": "vite-react.vite", "typescript": "vite-react.typescript",
       "@tanstack/react-router": "vite-react.tanstack_router", "@tanstack/react-query": "vite-react.tanstack_query",
       "vitest": "vite-react.vitest", "@playwright/test": "vite-react.playwright", "eslint": "vite-react.eslint",
       "astro": "astro.astro", "sharp": "astro.sharp"}
for pj in glob.glob("**/package.json", recursive=True):
    if "node_modules" in pj:
        continue
    try:
        d = json.load(open(pj, encoding="utf-8"))
    except Exception:
        print(f"SKIPPED   npm  ({pj}: not valid JSON)"); continue
    deps = {**d.get("dependencies", {}), **d.get("devDependencies", {})}
    for name, key in NPM.items():
        if name in deps: report(key, deps[name], pj)
    if "react-server-dom-webpack" in deps or "react-server-dom-turbopack" in deps or "react-server-dom-parcel" in deps:
        print(f"LICENCE   vite-react.rsc  react-server-dom-* is a direct dependency — the SPA must not need it (RSC CVE class)  ({pj})")
    pm = d.get("packageManager", "")
    if pm.startswith("pnpm@"): report("vite-react.pnpm", pm.split("@", 1)[1], pj)
    elif deps and "react" in deps: print(f"ABSENT    vite-react.pnpm  no packageManager field — pnpm version is not pinned  ({pj})")
    node = d.get("engines", {}).get("node")
    if node: report("vite-react.node", node, pj)

# --- Compose files: images ------------------------------------------------------
IMG = {"postgres": "postgres.image", "mongo": "mongo.image", "redis": "redis.image_hosted",
       "dragonfly": "dragonfly.image", "otel/opentelemetry-collector-contrib": "opentelemetry.collector_contrib_image",
       "caddy": "docker-compose.caddy", "traefik": "docker-compose.traefik"}
# Images the customer bundle may ship (L1-L4). Product images we build are
# allowed when the service has a `build:` (their FROM lines are checked below).
BUNDLE_ALLOWED = [x.strip() for x in pins.get("bundle.allowlist", "").strip("[]").split(",") if x.strip()] or \
    ["postgres", "valkey/valkey", "mongo", "otel/opentelemetry-collector-contrib",
     "otel/opentelemetry-collector", "caddy", "traefik"]

def check_bundle_image(ref, name, tag, src, kind):
    """Allowlist check for one image used by the customer bundle."""
    base = re.sub(r"^(docker\.io/)?(library/)?", "", name)
    if "dragonfly" in base:
        print(f"LICENCE   dragonfly  {ref} in the customer bundle — decision L2: hosted only (BSL 1.1); use valkey/valkey  ({src})"); return
    if re.search(r"(^|/)redis$", base):
        v = vt(tag)
        if not (v and len(v) >= 2 and v[:2] == (7, 2)):
            print(f"LICENCE   redis  {ref} in the customer bundle — decision L1: use {pins.get('redis.image_redistributable','valkey/valkey')} (floating or ≥7.4 tags are RSAL/SSPL/AGPL)  ({src})")
        return
    if base == "mongo" or base.endswith("/mongo"):
        if kind == "from":
            print(f"LICENCE   mongo  {src} builds FROM {ref} — decision L3: never ship a derived Mongo image; reference the official image  ({src})")
        elif "/" in name and not name.startswith(("docker.io/library/", "library/")):
            print(f"LICENCE   mongo  {ref} is not the official image — decision L3  ({src})")
        else:
            report("mongo.image_self_hosted", tag, src)
        return
    if re.search(r"grafana|/loki|/tempo|/mimir|minio", base):
        print(f"LICENCE   agpl  {ref} (AGPL family) in the customer bundle — decision L4 / licence review required  ({src})"); return
    if kind == "image" and not any(base == a or base.startswith(a + ":") for a in BUNDLE_ALLOWED):
        print(f"LICENCE   unclassified  {ref} in the customer bundle is not on the allowlist — classify its licence (/dependency-audit) before shipping  ({src})")

compose_files = [p for p in glob.glob("**/*.y*ml", recursive=True)
                 if re.search(r"(compose|docker-compose)[^/]*\.ya?ml$", p) and "node_modules" not in p]
dist = proj.get("distribution.model", "")
for cf in compose_files:
    for m in re.finditer(r"^\s*image:\s*['\"]?([^\s'\"#]+)", open(cf, encoding="utf-8").read(), re.M):
        ref = m.group(1)
        bare = ref.split("@", 1)[0]          # drop @sha256:... before splitting the tag
        name, _, tag = bare.rpartition(":") if ":" in bare.split("/")[-1] else (bare, "", "latest")
        base = name.split("/")[-1] if "otel/" not in name else name
        key = next((v for k, v in IMG.items() if base == k or name.endswith(k)), None)
        if "@" not in ref and (tag in ("latest", "") or re.fullmatch(r"\d+(-[a-z0-9.]+)?", tag)):
            print(f"FLOATING  {ref}  tag is not an exact version — pin the minor/patch (and digest)  ({cf})")
        in_bundle = "/self-hosted/" in "/" + cf.replace(os.sep, "/")
        # Hosted pins do not apply to the customer bundle (it has its own:
        # mongo.image_self_hosted, redis.image_redistributable).
        if key and not (in_bundle and key in ("mongo.image", "redis.image_hosted", "dragonfly.image")):
            pin_tag = pins.get(key, "").rpartition(":")[2]
            if pin_tag: report(key, tag, cf)
        # Licence rules apply to the customer bundle only (decisions L1-L4,
        # docs/ROADMAP.md; rules in .claude/rules/deploy.md). ALLOWLIST: every
        # image in deploy/self-hosted/ must be classified. Unknown images are
        # reported, never assumed fine (see /dependency-audit).
        if "/self-hosted/" in "/" + cf.replace(os.sep, "/"):
            check_bundle_image(ref, name, tag, cf, "image")

for df in glob.glob("deploy/self-hosted/**/Dockerfile*", recursive=True) + glob.glob("deploy/self-hosted/**/*.Dockerfile", recursive=True):
    for m in re.finditer(r"^\s*FROM\s+(?:--platform=\S+\s+)?([^\s]+)", open(df, encoding="utf-8").read(), re.M | re.I):
        ref = m.group(1)
        if ref.lower() == "scratch" or "$" in ref: continue
        bare = ref.split("@", 1)[0]
        name, _, tag = bare.rpartition(":") if ":" in bare.split("/")[-1] else (bare, "", "latest")
        check_bundle_image(ref, name, tag, df, "from")

if dist in ("self-hosted", "hybrid") and not any("/self-hosted/" in "/" + p.replace(os.sep, "/") for p in compose_files):
    print(f"ABSENT    deploy.self-hosted  distribution.model={dist} but no compose file under deploy/self-hosted/ — licence rules could not be checked")

# --- Local toolchain ------------------------------------------------------------
def tool(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=10).stdout
    except Exception:
        return None
gv = tool(["go", "version"])
if gv:
    m = re.search(r"go(\d+\.\d+(?:\.\d+)?)", gv); report("go.toolchain", m.group(1) if m else None, "local `go version`")
gl = tool(["golangci-lint", "--version"])
if gl:
    m = re.search(r"version (\d+\.\d+\.\d+)", gl); report("tooling.golangci_lint", m.group(1) if m else None, "local golangci-lint")
dv = tool(["docker", "compose", "version", "--short"])
if dv: report("docker-compose.compose", dv.strip(), "local `docker compose version`")
nv = tool(["node", "--version"])
if nv:
    report("vite-react.node", nv.strip(), "local `node --version`")
    if vt(nv) and vt(nv)[0] % 2 == 1:
        print(f"SKIPPED   vite-react.node  local Node {nv.strip()} is an odd (non-LTS) line — CI should use the even LTS in pins.yaml")
PYEOF
exit 0
