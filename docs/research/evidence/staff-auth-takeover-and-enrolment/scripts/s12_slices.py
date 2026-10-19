"""S12 (tier-E): print verbatim slices of the saved RFC texts so that summarised findings can be
checked. Usage: python3 -I s12_slices.py <rfc8628.txt> <rfc10027.txt>
Reads two local files; writes only to stdout. Slice = from a heading line to the next heading line."""
import re
import sys


def load(p):
    t = open(p, encoding="utf-8").read()
    # drop RFC page-break furniture so slices read continuously
    t = re.sub(r"\n.*\[Page \d+\]\n\f?\n?.*\n", "\n", t)
    return t


def slice_between(text, start_pat, end_pat, limit=6000):
    m = re.search(start_pat, text, re.M)
    if not m:
        return "!! start not found: %s" % start_pat
    e = re.search(end_pat, text[m.end():], re.M)
    end = m.end() + (e.start() if e else limit)
    return text[m.start():end][:limit]


r8628 = load(sys.argv[1])
r10027 = load(sys.argv[2])

print("######## RFC 8628")
for name, s, e in [
    ("3.2 response", r"^3\.2\.\s+Device Authorization Response", r"^3\.3\.\s"),
    ("3.3.1 non-textual", r"^3\.3\.1\.\s", r"^3\.4\.\s"),
    ("3.5 polling", r"^3\.5\.\s", r"^4\.\s"),
    ("5.1 user code brute forcing", r"^5\.1\.\s", r"^5\.2\.\s"),
    ("5.4 remote phishing", r"^5\.4\.\s", r"^5\.5\.\s"),
    ("5.5 session spying", r"^5\.5\.\s", r"^5\.6\.\s"),
    ("6.1 user code recommendations", r"^6\.1\.\s", r"^6\.2\.\s"),
]:
    print("-------- slice:", name)
    print(slice_between(r8628, s, e))

print("######## RFC 10027")
for name, s, e in [
    ("6.1.2 short-lived", r"^6\.1\.2\.\s", r"^6\.1\.3\.\s"),
    ("6.1.7 trusted devices", r"^6\.1\.7\.\s", r"^6\.1\.8\.\s"),
    ("6.1.14 user experience", r"^6\.1\.14\.\s", r"^6\.1\.15\.\s"),
    ("6.1.15 authenticate then initiate", r"^6\.1\.15\.\s", r"^6\.1\.16\.\s"),
    ("6.1.16 request initiation verification", r"^6\.1\.16\.\s", r"^6\.1\.17\.\s"),
    ("6.1.17 request binding", r"^6\.1\.17\.\s", r"^6\.1\.18\.\s"),
    ("6.2.1 RFC 8628", r"^6\.2\.1\.\s", r"^6\.2\.2\.\s"),
    ("6.2.2 CIBA", r"^6\.2\.2\.\s", r"^6\.2\.3\.\s"),
]:
    print("-------- slice:", name)
    print(slice_between(r10027, s, e))
