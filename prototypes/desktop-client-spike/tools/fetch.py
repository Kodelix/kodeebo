# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
#
# Fetch the founder-approved downloads onto the host, one new directory per item, and verify
# each against the publisher's digest where one exists. Never executes anything it downloads.
# Usage: python3 -I tools/fetch.py <cache_dir> <evidence_file> [item_id ...]
import hashlib, json, os, sys, urllib.request

UA = {"User-Agent": "kodeebo-desktop-client-spike/1 (test VM provisioning)"}


def get(url, timeout=60):
    return urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=timeout)


def get_text(url):
    with get(url) as r:
        return r.read().decode("utf-8", "replace")


def get_json(url):
    return json.loads(get_text(url))


def first_hex(text, name=None):
    for line in text.splitlines():
        parts = line.split()
        if parts and len(parts[0]) == 64 and all(c in "0123456789abcdefABCDEF" for c in parts[0]):
            if name is None or (len(parts) > 1 and parts[1].lstrip("*") == name):
                return parts[0].lower()
    return None


def gh_digest(repo_tag_api, asset_name):
    rel = get_json(repo_tag_api)
    for a in rel.get("assets", []):
        if a["name"] == asset_name:
            d = a.get("digest") or ""
            return d.split(":", 1)[1].lower() if d.startswith("sha256:") else None
    return None


def adoptium():
    rows = get_json("https://api.adoptium.net/v3/assets/latest/21/hotspot?architecture=x64&image_type=jdk&os=windows&vendor=eclipse")
    for row in rows:
        pkg = row["binary"]["package"]
        if pkg["name"].endswith(".zip"):
            return pkg["link"], pkg["name"], pkg["checksum"].lower()
    raise SystemExit("no Temurin windows x64 jdk zip found")


def items():
    t, e, w = "https://api.github.com/repos/", None, None
    yield "temurin-jdk21", *adoptium()
    yield "gradle-9.7.0", "https://services.gradle.org/distributions/gradle-9.7.0-bin.zip", "gradle-9.7.0-bin.zip", \
        first_hex(get_text("https://services.gradle.org/distributions/gradle-9.7.0-bin.zip.sha256"))
    wn = "wix314-binaries.zip"
    yield "wix-3.14", "https://github.com/wixtoolset/wix3/releases/download/wix3141rtm/" + wn, wn, \
        gh_digest(t + "wixtoolset/wix3/releases/tags/wix3141rtm", wn)
    nn = "node-v24.22.0-x64.msi"
    yield "node-24.22.0", "https://nodejs.org/dist/v24.22.0/" + nn, nn, \
        first_hex(get_text("https://nodejs.org/dist/v24.22.0/SHASUMS256.txt"), nn)
    en = "electron-v44.8.0-win32-x64.zip"
    yield "electron-44.8.0", "https://github.com/electron/electron/releases/download/v44.8.0/" + en, en, \
        first_hex(get_text("https://github.com/electron/electron/releases/download/v44.8.0/SHASUMS256.txt"), en)
    yield "rustup-init", "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe", "rustup-init.exe", \
        first_hex(get_text("https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe.sha256"))
    yield "vs-buildtools-bootstrapper", "https://aka.ms/vs/17/release/vs_BuildTools.exe", "vs_BuildTools.exe", None
    yield "diskspd", "https://github.com/microsoft/diskspd/releases/latest/download/DiskSpd.zip", "DiskSpd.zip", \
        gh_digest(t + "microsoft/diskspd/releases/latest", "DiskSpd.zip")


def download(url, dest):
    h, n = hashlib.sha256(), 0
    with get(url, timeout=120) as r, open(dest, "wb") as f:
        final = r.geturl()
        while True:
            b = r.read(1 << 20)
            if not b:
                break
            f.write(b)
            h.update(b)
            n += len(b)
    return h.hexdigest(), n, final


def main():
    cache, ev, only = sys.argv[1], sys.argv[2], set(sys.argv[3:])
    os.makedirs(cache, exist_ok=True)
    for item_id, url, name, want in items():
        if only and item_id not in only:
            continue
        d = os.path.join(cache, item_id)
        if os.path.exists(d):
            print(f"{item_id}: directory exists, skipped (each item gets a new, empty directory)")
            continue
        os.makedirs(d)
        dest = os.path.join(d, name)
        try:
            got, n, final = download(url, dest)
        except Exception as ex:
            print(f"{item_id}: FAILED {ex}")
            continue
        status = "publisher digest MATCH" if want and want == got else ("publisher digest MISMATCH (expected %s)" % want if want else "no publisher digest; hash recorded only")
        line = f"{item_id}\t{name}\t{n} bytes\tsha256={got}\t{status}\tfinal={final}"
        print(line)
        with open(ev, "a") as f:
            f.write(line + "\n")
        if want and want != got:
            os.rename(dest, dest + ".REJECTED")


main()
