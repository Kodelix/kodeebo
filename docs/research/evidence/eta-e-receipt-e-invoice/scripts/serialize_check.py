#!/usr/bin/env python3
"""Tier-E check (S22 partial): implement ETA's published JSON serialisation pseudo-code
(https://sdk.invoicing.eta.gov.eg/document-serialization-approach/) and compare the output with ETA's
published example. Pure read of public sample files; no API call, no credentials.
Usage: python3 -I serialize_check.py <one-doc.json> <one-doc-serialized.json.txt> <parsed-cades-bes.txt>
Keeps number literals exactly as in the source text (json parse with parse_float=str / parse_int=str)."""
import json, sys, hashlib, re

def ser(v, name=None):
    if isinstance(v, dict):
        out = []
        for k, x in v.items():
            if isinstance(x, list):
                out.append('"%s"' % k.upper())
                for el in x:
                    out.append('"%s"' % k.upper())
                    out.append(ser(el))
            else:
                out.append('"%s"' % k.upper()); out.append(ser(x))
        return "".join(out)
    if v is None: return '""'
    return '"%s"' % v

raw = open(sys.argv[1], encoding="utf-8").read()
doc = json.loads(raw, parse_float=str, parse_int=str)  # keep 0.0 as "0.0"
mine = ser(doc)
theirs = open(sys.argv[2], encoding="utf-8").read().strip()
print("my length", len(mine), "their length", len(theirs))
print("EXACT MATCH:", mine == theirs)
if mine != theirs:
    for i,(a,b) in enumerate(zip(mine,theirs)):
        if a!=b: print("first diff at", i, repr(mine[max(0,i-40):i+40]), "||", repr(theirs[max(0,i-40):i+40])); break
h = hashlib.sha256(mine.encode("utf-8")).hexdigest()
print("sha256(my canonical utf-8):", h)
p = open(sys.argv[3], encoding="utf-8", errors="replace").read()
print("digest hex (as published, any OCTET STRING lines):", re.findall(r"OCTET STRING \(32 byte\)\s+([0-9A-Fa-f ]+)", p)[:3])
print("my hash found in parsed CAdES text:", h.lower() in re.sub(r"\s","",p).lower())
