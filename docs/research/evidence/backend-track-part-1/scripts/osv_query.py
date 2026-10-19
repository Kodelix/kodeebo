"""S13: query OSV (api.osv.dev) and GitHub Security Advisories (gh api) for the pinned versions.
Run with: python3 -I scripts/osv_query.py > s13-output.txt
Sends only public package names and versions. Scratch research script."""
import json
import subprocess
import urllib.request
from datetime import datetime, timezone

# (ecosystem, name, version, pinned-in)
PKGS = [
    ("Maven", "io.ktor:ktor-server-core-jvm", "3.6.0", "pins.yaml ktor.ktor"),
    ("Maven", "io.ktor:ktor-server-netty-jvm", "3.6.0", "pins.yaml ktor.ktor"),
    ("Maven", "io.netty:netty-codec-http", "4.2.17.Final", "resolved by Ktor 3.6.0 in s11-gradle.lockfile (check)"),
    ("Maven", "io.netty:netty-handler", "4.2.17.Final", "resolved by Ktor 3.6.0 in s11-gradle.lockfile (check)"),
    ("Maven", "com.zaxxer:HikariCP", "7.1.0", "pins.yaml ktor.hikaricp"),
    ("Maven", "org.jetbrains.exposed:exposed-core", "1.5.1", "pins.yaml ktor.exposed"),
    ("Maven", "org.jetbrains.kotlin:kotlin-stdlib", "2.4.21", "pins.yaml kotlin.kotlin"),
    ("Maven", "org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm", "1.11.0", "pins.yaml kotlin.coroutines"),
    ("Maven", "io.opentelemetry:opentelemetry-sdk", "1.67.0", "pins.yaml opentelemetry.java_sdk"),
    ("Maven", "io.opentelemetry.javaagent:opentelemetry-javaagent", "2.32.0", "pins.yaml opentelemetry.java_agent"),
    ("Go", "github.com/jackc/pgx/v5", "v5.11.0", "pins.yaml go.pgx"),
    ("Go", "go.opentelemetry.io/otel", "v1.47.0", "pins.yaml opentelemetry.go_sdk"),
    ("Go", "stdlib", "1.27.2", "pins.yaml go.toolchain"),
]


def post(url, body):
    req = urllib.request.Request(url, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def get(url):
    with urllib.request.urlopen(url, timeout=60) as r:
        return json.load(r)


print("date_utc", datetime.now(timezone.utc).isoformat(timespec="seconds"))
queries = [{"package": {"ecosystem": e, "name": n}, "version": v} for e, n, v, _ in PKGS]
res = post("https://api.osv.dev/v1/querybatch", {"queries": queries})["results"]
for (e, n, v, pin), r in zip(PKGS, res):
    ids = [x["id"] for x in r.get("vulns", [])]
    print(f"OSV {e} {n} {v} [{pin}] -> {len(ids)} advisories: {ids}")
    for i in ids:
        d = get("https://api.osv.dev/v1/vulns/" + i)
        sev = [s.get("score") for s in d.get("severity", [])]
        fixed = sorted({ev["fixed"] for a in d.get("affected", []) for rg in a.get("ranges", []) for ev in rg.get("events", []) if "fixed" in ev})
        print(f"    {i} | {d.get('summary','')[:110]} | published {d.get('published','')[:10]} | aliases {d.get('aliases', [])[:3]} | fixed {fixed[:4]} | sev {sev}")

print("--- GitHub Security Advisories (gh api /advisories), affects=<pkg>@<version>")
for e, n, v, _ in PKGS:
    eco = {"Maven": "maven", "Go": "go"}[e]
    if n == "stdlib":
        continue
    vv = v.lstrip("v")
    cmd = ["gh", "api", "-X", "GET", "/advisories", "-f", f"ecosystem={eco}", "-f", f"affects={n}@{vv}", "-f", "per_page=20"]
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    if p.returncode != 0:
        print(f"GHSA {n}@{vv}: gh api failed: {p.stderr.strip()[:200]}")
        continue
    items = json.loads(p.stdout)
    print(f"GHSA {n}@{vv}: {len(items)} advisories {[(a['ghsa_id'], a['severity']) for a in items]}")
