#!/usr/bin/env python3
# S51 (part 5): survey the copyleft-relevant entries of Electron 44.8.0's LICENSES.chromium.html (saved copy; read-only).
# Run: python3 -I scripts/p5-s51-survey-entries.py fetched/licences/electron-44.8.0-dist-LICENSES.chromium.html
import re, sys, html
src = open(sys.argv[1], encoding="utf-8", errors="replace").read()
prods = re.findall(r'<div class="product">\s*<span class="title">(.*?)</span>(.*?)(?=<div class="product">|$)', src, flags=re.S)
want = ["ffmpeg","Braille Translation Library","hunspell","hunspell dictionaries","hyphenation-patterns","ISimpleDOM COM interfaces for accessibility",
        "Mozilla Windows Cert code","Mozilla Personal Security Manager","Netscape Portable Runtime (NSPR)","WebKit","url_parse","Node.js","IAccessible2 COM interfaces for accessibility"]
marks = ["Mozilla Public License Version 2.0","Mozilla Public License Version 1.1","MOZILLA PUBLIC LICENSE","GNU LESSER GENERAL PUBLIC LICENSE","Version 2.1, February 1999","Version 3, 29 June 2007","GNU GENERAL PUBLIC LICENSE","Version 2, June 1991","Exhibit A","Secondary Licenses"]
print("total entries", len(prods))
for t, b in prods:
    tt = html.unescape(t).strip()
    if tt not in want: continue
    s = html.unescape(re.sub(r"<[^>]+>", "", b))
    s = re.sub(r"[ \t]+", " ", s)
    print("\n=====", repr(tt), "len", len(s))
    print("HEAD:", s[:700].replace("\n", " | "))
    for m in marks:
        idx = [x.start() for x in re.finditer(re.escape(m), s)]
        if idx: print("  marker", repr(m), "at", idx[:4])
