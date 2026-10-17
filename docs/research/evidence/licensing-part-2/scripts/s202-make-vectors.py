# s202: build Ed25519 edge-case vectors from RFC 8032 text (no constants from memory).
# usage: python3 -I s202-make-vectors.py <rfc8032.txt> <out.json>
import json, re, sys
txt = open(sys.argv[1]).read()
m = re.search(r"-----TEST 2\n.*?PUBLIC KEY:\n(.*?)\n\n\s*MESSAGE \(length 1 byte\):\n\s*([0-9a-f]+)\n\n\s*SIGNATURE:\n(.*?)\n\n", txt, re.S)
h = lambda s: "".join(s.split())
pub, msg, sig = bytes.fromhex(h(m.group(1))), bytes.fromhex(h(m.group(2))), bytes.fromhex(h(m.group(3)))
q = int(re.search(r"^q = (2\*\*252 \+ \d+)$", txt, re.M).group(1).replace("2**252", str(2**252)).replace("+", "").replace(" ", "") if False else eval(re.search(r"^q = (2\*\*252 \+ \d+)$", txt, re.M).group(1)))
p = 2**255 - 19  # RFC 8032 s5.1: p = 2^255 - 19 (field prime of edwards25519)
assert len(pub) == 32 and len(sig) == 64
R, S = sig[:32], int.from_bytes(sig[32:], "little")
assert S < q
mall = sig[:32] + (S + q).to_bytes(32, "little")          # S + L: same group equation, non-canonical scalar
ident = (1).to_bytes(32, "little")                         # y=1: the identity point (order 1)
noncanon_ident = (p + 1).to_bytes(32, "little")            # y=p+1 == 1 mod p, y not reduced
zero_s = ident + bytes(32)                                 # R=identity, S=0
negzero = bytearray(ident); negzero[31] |= 0x80            # y=1, x=0 with the sign bit set
V = [
 ("valid_rfc8032_test2", pub, msg, sig),
 ("flipped_message_bit", pub, bytes([msg[0] ^ 1]), sig),
 ("malleated_S_plus_L", pub, msg, mall),
 ("key_31_bytes", pub[:31], msg, sig),
 ("sig_63_bytes", pub, msg, sig[:63]),
 ("small_order_key_identity__R_identity_S0", ident, b"any message", zero_s),
 ("noncanonical_key_y_eq_p_plus_1__R_identity_S0", noncanon_ident, b"any message", zero_s),
 ("key_identity_with_sign_bit_set__R_identity_S0", bytes(negzero), b"any message", zero_s),
 ("noncanonical_R_y_eq_p_plus_1_with_key_identity_S0", ident, b"any message", noncanon_ident + bytes(32)),
]
json.dump([{"name": n, "pub": a.hex(), "msg": b.hex(), "sig": c.hex()} for n, a, b, c in V], open(sys.argv[2], "w"), indent=1)
print("wrote", len(V), "vectors")
