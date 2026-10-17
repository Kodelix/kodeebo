#!/usr/bin/env python3
# S59c (part 5): check the inference in F521. Download skiko-awt-runtime-windows-x64-0.150.2.jar from Maven Central (new empty dir), read it in memory only
# (nothing is extracted or executed), list entries, and look for version strings of FreeType, HarfBuzz and ICU in the native DLL.
# Run: python3 -I scripts/p5-s59c-skiko-jar-natives.py <empty download dir>
import sys, os, urllib.request, zipfile, re, hashlib
d = sys.argv[1]; os.makedirs(d, exist_ok=True)
url = "https://repo1.maven.org/maven2/org/jetbrains/skiko/skiko-awt-runtime-windows-x64/0.150.2/skiko-awt-runtime-windows-x64-0.150.2.jar"
path = os.path.join(d, "skiko-awt-runtime-windows-x64-0.150.2.jar")
if not os.path.exists(path):
    urllib.request.urlretrieve(url, path)
raw = open(path, "rb").read()
print("jar bytes", len(raw), "sha256", hashlib.sha256(raw).hexdigest())
z = zipfile.ZipFile(path)
for i in z.infolist(): print("  entry", i.filename, i.file_size)
for i in z.infolist():
    if i.filename.lower().endswith((".dll", ".dat")):
        b = z.read(i.filename)
        print(f"\n-- {i.filename} {len(b)} bytes")
        for pat in (rb"FreeType[ -~]{0,60}", rb"HarfBuzz[ -~]{0,40}", rb"harfbuzz[ -~]{0,40}", rb"ICU [ -~]{0,40}", rb"icudt[0-9]+[a-z]?", rb"\b74\.2\b", rb"\b2\.14\.\d\b", rb"13\.1\.\d", rb"SkFontMgr_[A-Za-z]+", rb"m150[ -~]{0,30}"):
            hits = sorted(set(m.group(0).decode("latin1") for m in re.finditer(pat, b)))
            print("   ", pat.decode("latin1")[:28], "->", hits[:8])
