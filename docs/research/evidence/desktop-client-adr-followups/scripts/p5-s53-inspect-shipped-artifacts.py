#!/usr/bin/env python3
# S53 (part 5): which copyleft-listed components are visibly in the Windows build the spike shipped. Read-only; nothing is extracted to disk or executed.
#  - Electron 44.8.0 win32-x64 zip: file list, and byte-pattern presence in electron.exe / ffmpeg.dll (presence of a string is an observation, not proof of which licence applies).
#  - Temurin 21.0.12.1 zip: legal/ folder names, the shipped Classpath exception paragraph compared with the jdk21u LICENSE, top-level NOTICE.
#  - MSI / NSIS installers: list contents only if 7z or msiextract exists, else "could not run".
# Run: python3 -I scripts/p5-s53-inspect-shipped-artifacts.py <electron.zip> <temurin.zip> <jdk21u-LICENSE.txt> <msi> <nsis-setup.exe>
import sys, zipfile, re, hashlib, shutil, subprocess
ez, tz, jdklic, msi, nsis = sys.argv[1:6]
def norm(s): return re.sub(r"\s+", " ", s).strip()
print("== Electron zip", ez)
z = zipfile.ZipFile(ez)
names = z.namelist()
print("entries:", len(names))
for n in names:
    if not n.startswith("locales/") and "/" not in n.rstrip("/"): print("  ", n, z.getinfo(n).file_size)
print("  locales/*:", sum(1 for n in names if n.startswith("locales/")), "files; *.bdic dictionaries in zip:", [n for n in names if n.endswith(".bdic")])
pats = [b"hunspell", b"Hunspell", b"liblouis", b"ISimpleDOM", b"IAccessible2", b"nspr", b"avcodec_license", b"LGPL version 2.1 or later", b"GPL version 2 or later", b"GPL version 3 or later", b"--enable-gpl", b"--enable-nonfree", b"--enable-version3", b"libavcodec", b"configuration: "]
for member in ("ffmpeg.dll", "electron.exe"):
    data = z.read(member)
    print(f"\n-- {member}: {len(data)} bytes; sha256 {hashlib.sha256(data).hexdigest()}")
    for p in pats:
        c = data.count(p)
        print(f"   {p.decode():32s} count {c}")
    if member == "ffmpeg.dll":
        for m in re.finditer(rb"(LGPL version [0-9.]+ or later|--enable-[a-z0-9-]+|--disable-[a-z0-9-]+)", data):
            pass
        cfg = sorted(set(m.group(0).decode() for m in re.finditer(rb"--(enable|disable)-[a-z0-9_-]+", data)))
        print("   configure flags found (set):", cfg)
        for m in re.finditer(rb"[ -~]{0,80}(LGPL|GPL)[ -~]{0,80}", data):
            print("   string:", m.group(0).decode()[:200])
print("\n== Temurin zip", tz)
t = zipfile.ZipFile(tz)
tn = t.namelist()
legal = [n for n in tn if "/legal/" in n]
mods = sorted(set(n.split("/legal/")[1].split("/")[0] for n in legal if n.split("/legal/")[1]))
print("entries:", len(tn), "legal files:", len(legal), "legal modules:", len(mods))
for n in tn:
    if n.count("/") == 1 and not n.endswith("/"): print("  top-level:", n, t.getinfo(n).file_size)
for want in ("legal/java.base/LICENSE", "legal/java.base/ASSEMBLY_EXCEPTION", "legal/java.base/ADDITIONAL_LICENSE_INFO"):
    hit = [n for n in tn if n.endswith(want)]
    print(" ", want, "->", hit)
lic = [n for n in tn if n.endswith("legal/java.base/LICENSE")][0]
shipped = t.read(lic).decode("utf-8", "replace")
upstream = open(jdklic, encoding="utf-8", errors="replace").read()
def para(s):
    i = s.find("As a special exception, the copyright holders of this library"); j = s.find("so, delete this exception statement from your version.", i)
    return norm(s[i:j + 54]) if i >= 0 and j > 0 else None
a, b = para(shipped), para(upstream)
print("shipped Classpath paragraph found:", a is not None, "; jdk21u paragraph found:", b is not None, "; identical after whitespace normalisation:", a == b)
print("shipped paragraph:", a)
print("shipped LICENSE sha256:", hashlib.sha256(shipped.encode()).hexdigest(), " upstream jdk21u LICENSE sha256:", hashlib.sha256(upstream.encode()).hexdigest(), " identical text after whitespace normalisation:", norm(shipped) == norm(upstream))
notice = [n for n in tn if n.count("/") == 1 and n.endswith("/NOTICE")]
for n in notice: print("\n-- top-level NOTICE (verbatim):\n" + t.read(n).decode("utf-8", "replace"))
print("\n== installers")
for label, path in (("MSI (A)", msi), ("NSIS setup (B)", nsis)):
    tool = shutil.which("7z") or shutil.which("7za") or shutil.which("7zz") or shutil.which("msiextract")
    print(label, path, "tool:", tool)
    if tool:
        cmd = [tool, "l", path] if "7z" in tool else [tool, "-l", path]
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        print(r.stdout[-6000:], r.stderr[-500:])
    else:
        print("   could not run: no 7z/7za/7zz/msiextract on PATH")
