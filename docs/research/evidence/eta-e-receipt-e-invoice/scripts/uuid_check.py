#!/usr/bin/env python3
"""Tier-E check (S22 partial): does ETA's published sample receipt batch carry a uuid equal to SHA-256 of the serialised receipt
(uuid emptied), using the serialisation rules from serialize_check.py? Variants tried: whole receipt object; uuid removed vs empty.
Usage: python3 -I uuid_check.py <BatchReceipt.json>"""
import json, sys, hashlib, copy
sys.path.insert(0, __file__.rsplit("/",1)[0])
from serialize_check_lib import ser
d = json.loads(open(sys.argv[1], encoding="utf-8").read(), parse_float=str, parse_int=str)
for i, r in enumerate(d["receipts"]):
    want = r["header"]["uuid"]
    for label, mut in (("uuid=''", lambda x: x["header"].__setitem__("uuid","")), ("uuid removed", lambda x: x["header"].pop("uuid"))):
        c = copy.deepcopy(r); mut(c)
        h = hashlib.sha256(ser(c).encode("utf-8")).hexdigest()
        print(i, label, h, "MATCH" if h == want else "no match (sample uuid %s)" % want)
