# S30 - what a hash-chained device audit journal can and cannot detect when the server stores the chain head acknowledged at each sync.
# Evidence script for research note staff-auth-and-roles.part-3, run 2026-10-19. Python stdlib only. Run: python3 -I s30_device_chain.py
# Model: entries carry IDs and enums only (no names). hash_i = SHA256(hash_{i-1} || canonical_json(payload_i)). The attacker is an insider with
# file access to the local copy and no server access: can edit, delete, recompute hashes (no secret is needed for an unkeyed chain).
import hashlib, json, copy

def h(prev, payload):
    return hashlib.sha256(prev.encode() + json.dumps(payload, sort_keys=True, separators=(',', ':')).encode()).hexdigest()

def build(n):
    prev, out = "0"*64, []
    for i in range(1, n+1):
        p = {"seq": i, "actor": "st_%d" % (i % 3), "action": "void" if i % 7 == 0 else "discount", "ref": "bill_%d" % i,
             "reason": "R%d" % (i % 4), "approver": "st_9" if i % 7 == 0 else None}
        prev = h(prev, p); out.append({"p": p, "h": prev})
    return out

def verify_internal(chain):
    prev = "0"*64
    for i, e in enumerate(chain):
        if h(prev, e["p"]) != e["h"]:
            return "BROKEN at position %d (seq %s)" % (i+1, e["p"]["seq"])
        prev = e["h"]
    return "ok"

def rechain(chain, start):
    prev = chain[start-1]["h"] if start > 0 else "0"*64
    for i in range(start, len(chain)):
        chain[i]["h"] = h(prev, chain[i]["p"]); prev = chain[i]["h"]

def server_check(chain, acked):
    """Server holds acked = {seq: hash} for the last entry of every received batch. On the next sync it compares."""
    for seq, hh in sorted(acked.items()):
        if len(chain) < seq: return "REFUSED: device presents %d entries, server already acknowledged seq %d (truncation)" % (len(chain), seq)
        if chain[seq-1]["h"] != hh: return "REFUSED: hash at seq %d differs from the value acknowledged earlier (history rewritten)" % seq
    return "ok"

N, SYNCED = 100, 80
base = build(N)
acked = {20: base[19]["h"], 50: base[49]["h"], 80: base[79]["h"]}  # three earlier batches were acknowledged by the server

def case(name, mutate):
    c = copy.deepcopy(base); mutate(c)
    print("%-62s internal check: %-34s server head check: %s" % (name, verify_internal(c), server_check(c, acked)))

print("S30 results (100 entries; server acknowledged heads at seq 20, 50, 80; entries 81-100 never synced)")
case("0 control: untouched", lambda c: None)
def a(c): c[49]["p"]["action"] = "discount"            # edit a synced entry, no re-chain
case("a edit synced entry 50, hashes not recomputed", a)
def b(c): c[59]["p"]["approver"] = None; rechain(c, 59)  # edit synced entry 60 and recompute the rest
case("b edit synced entry 60 and recompute later hashes", b)
def c_(c): del c[69]
case("c delete synced entry 70 (middle)", c_)
def d(c): del c[89]
case("d delete UNSYNCED entry 90 (middle)", d)
def e(c): del c[94:]
case("e truncate UNSYNCED tail (entries 95-100)", e)
def f(c): del c[60:]
case("f truncate a synced tail (entries 61-100)", f)
def g(c): c[84]["p"]["action"] = "discount"; rechain(c, 84)
case("g edit UNSYNCED entry 85 and recompute", g)
def i_(c): c[84], c[85] = c[85], c[84]
case("i swap two unsynced entries 85 and 86, hashes untouched", i_)
def j(c):
    del c[90:95]; rechain(c, 90)
case("j delete unsynced entries 91-95 and recompute later hashes", j)
