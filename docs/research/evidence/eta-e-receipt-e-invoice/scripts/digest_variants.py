#!/usr/bin/env python3
"""Tier-E follow-up to serialize_check.py: does the published CAdES messageDigest equal a simple variant of the example's digest?
Usage: python3 -I digest_variants.py <one-doc-serialized.json.txt> <parsed-cades-bes.txt> <one-doc.json>"""
import hashlib, sys, re, json
s = open(sys.argv[1], encoding="utf-8").read().strip().encode("utf-8")
p = re.sub(r"\s", "", open(sys.argv[2], encoding="utf-8", errors="replace").read()).lower()
h = hashlib.sha256(s).digest()
cands = {
 "sha256(canonical)": h,
 "sha256(sha256(canonical))": hashlib.sha256(h).digest(),
 "sha256(canonical+newline)": hashlib.sha256(s+b"\n").digest(),
 "sha256(hex string of hash)": hashlib.sha256(h.hex().encode()).digest(),
 "sha256(raw one-doc.json bytes)": hashlib.sha256(open(sys.argv[3],"rb").read()).digest(),
}
for k,v in cands.items(): print(k, v.hex(), "IN PARSED CADES:", v.hex() in p)
