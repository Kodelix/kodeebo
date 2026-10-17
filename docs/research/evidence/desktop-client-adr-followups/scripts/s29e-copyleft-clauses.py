#!/usr/bin/env python3
# S29e (part 2): extract, verbatim, the clauses that decide what a distributor of binaries must provide, from texts already saved:
# GPL-2.0 section 3 (openjdk/jdk21u LICENSE), and the FFmpeg entry of Electron's LICENSES.chromium.html for its LGPL v2.1 section 6 (relink / source), plus MPL 2.0 section 3.2.
# Read-only on saved files. Run: python3 -I s29e-copyleft-clauses.py <jdk21u-LICENSE.txt> <LICENSES.chromium.html>
import re, sys, html
jdk = open(sys.argv[1], encoding="utf-8", errors="replace").read()
i = jdk.find("3. You may copy and distribute the Program")
print("== GPL-2.0 s3 (jdk21u LICENSE), first 1900 chars from the marker; index", i)
print(re.sub(r"[ \t]+", " ", jdk[i:i+1900]) if i >= 0 else "marker not found")
src = open(sys.argv[2], encoding="utf-8", errors="replace").read()
prods = re.findall(r'<div class="product">\s*<span class="title">(.*?)</span>(.*?)(?=<div class="product">|$)', src, flags=re.S)
for t, b in prods:
    if html.unescape(t).strip() == "ffmpeg":
        s = html.unescape(re.sub(r"<[^>]+>", "", b))
        print("\n== ffmpeg entry length", len(s), "; contains LGPL 2.1 section 6 marker:", "6. As an exception to the Sections above" in s)
        j = s.find("6. As an exception to the Sections above")
        print(re.sub(r"[ \t]+", " ", s[j:j+2300]) if j >= 0 else "section 6 marker not found")
        for pat in ("COPYING.LGPLv2.1", "ffmpeg.org", "--enable-gpl", "--enable-nonfree"):
            print("mentions", pat, ":", pat in s)
