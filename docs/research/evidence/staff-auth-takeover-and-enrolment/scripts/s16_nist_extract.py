"""S16 (tier-E): print verbatim passages from the saved NIST SP 800-63B-4 page.
Usage: python3 -I s16_nist_extract.py <sp800-63b.html>
Reads one local file; stdlib only; writes to stdout. HTML tags are stripped (crudely) before searching."""
import html
import re
import sys

raw = open(sys.argv[1], encoding="utf-8", errors="replace").read()
raw = re.sub(r"(?is)<(script|style).*?</\1>", " ", raw)
text = html.unescape(re.sub(r"<[^>]+>", " ", raw))
text = re.sub(r"\s+", " ", text)
print("text characters:", len(text))

needles = [
    "112 bits",
    "40 bits",
    "across endpoints",
    "mechanism independent of the transaction",
    "no longer considered acceptable",
    "not phishing-resistant",
    "associate the approval with the authentication transaction",
    "SHALL NOT reset the failed authentication count",
    "within 10 minutes",
    "Authentication Intent",
]
for n in needles:
    hits = [m.start() for m in re.finditer(re.escape(n), text)]
    print("\n==== needle: %r  hits: %d" % (n, len(hits)))
    for h in hits[:3]:
        print("...%s..." % text[max(0, h - 450): h + 450])
        print("-" * 20)
