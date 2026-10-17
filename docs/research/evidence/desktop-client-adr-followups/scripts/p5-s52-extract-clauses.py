#!/usr/bin/env python3
# S52 (part 5; replaces the unrun scripts/s29e-copyleft-clauses.py, which stays unchanged): extract licence clauses verbatim from texts already saved.
# Read-only on saved files; writes one file per licence under the output directory given as argv[3].
# Run: python3 -I scripts/p5-s52-extract-clauses.py <jdk21u-LICENSE.txt> <LICENSES.chromium.html> <outdir>
import re, sys, html, os
jdk_path, notices_path, outdir = sys.argv[1:4]
os.makedirs(outdir, exist_ok=True)
def norm(s): return re.sub(r"[ \t]+\n", "\n", re.sub(r"[ \t]+", " ", s))
def entry(prods, name, nth=0):
    hits = [html.unescape(re.sub(r"<[^>]+>", "", b)) for t, b in prods if html.unescape(t).strip() == name]
    return norm(hits[nth])
def cut(s, a, b=None, label=""):
    i = s.find(a)
    if i < 0: return f"[{label}: start marker {a!r} NOT FOUND]\n"
    j = s.find(b, i + len(a)) if b else -1
    return s[i:(j if j > 0 else len(s))] + "\n"
def put(name, text):
    open(os.path.join(outdir, name), "w", encoding="utf-8").write(text)
    print(f"wrote {name}: {len(text)} chars", "NOT FOUND" if "NOT FOUND" in text else "")
jdk = norm(open(jdk_path, encoding="utf-8", errors="replace").read())
src = open(notices_path, encoding="utf-8", errors="replace").read()
prods = re.findall(r'<div class="product">\s*<span class="title">(.*?)</span>(.*?)(?=<div class="product">|$)', src, flags=re.S)
# GPL-2.0 (jdk21u LICENSE): terms 0-4 and the Classpath exception
put("gpl2-terms-0-to-4.txt", cut(jdk, "0. This License applies to any program", "5. You are not required to accept this License", "GPL2"))
put("gpl2-classpath-exception.txt", cut(jdk, "\"CLASSPATH\" EXCEPTION TO THE GPL", None, "CLASSPATH") if "\"CLASSPATH\" EXCEPTION TO THE GPL" in jdk else cut(jdk, "CLASSPATH", None, "CLASSPATH"))
# LGPL-2.1 (inside the ffmpeg entry): the full operative range, sections 0-8
ff = entry(prods, "ffmpeg")
put("ffmpeg-entry-preamble.txt", ff[:ff.find("GNU LESSER GENERAL PUBLIC LICENSE")])
put("lgpl21-sections-0-to-9.txt", cut(ff, "0. This License Agreement applies to any software library", "9. You are not required to accept this License", "LGPL21"))
# MPL 2.0 (NSPR entry carries the full text): whole entry
put("mpl20-full-nspr-entry.txt", entry(prods, "Netscape Portable Runtime (NSPR)"))
put("mpl20-windows-cert-code-preamble.txt", entry(prods, "Mozilla Windows Cert code")[:2100])
# MPL 1.1 (hunspell entry): sections 3.1-3.7 and 4-6, plus the tail after the licence (tri-licence block)
hs = entry(prods, "hunspell")
put("mpl11-hunspell-section-3-to-4.txt", cut(hs, "3. Distribution Obligations.", "5. Application of this License.", "MPL11"))
put("mpl11-hunspell-section-5.txt", cut(hs, "5. Application of this License.", "6. Versions of the License.", "MPL11-5"))
put("mpl11-hunspell-tail-after-exhibit.txt", hs[hs.find("EXHIBIT A"):] if "EXHIBIT A" in hs else hs[-4000:])
put("tri-licence-isimpledom-entry.txt", entry(prods, "ISimpleDOM COM interfaces for accessibility"))
put("lgpl3-liblouis-entry.txt", entry(prods, "Braille Translation Library"))
