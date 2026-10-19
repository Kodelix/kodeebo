"""S11 (tier-E, arithmetic only): entropy and guess probability of candidate user-code formats
for the approve-on-phone enrolment (RFC 8628 section 6.1 formats and larger ones).
Usage: python3 -I s11_usercode_entropy.py
Stdlib only; no network; no files written. Deterministic."""
import math

formats = [
    ("6 digits", 10, 6),
    ("8 digits", 10, 8),
    ("9 digits (RFC 8628 numeric example)", 10, 9),
    ("8 chars base-20 consonants (RFC 8628 example WDJB-MJHT)", 20, 8),
    ("10 chars base-20 consonants", 20, 10),
    ("12 chars base-20 consonants", 20, 12),
    ("10 chars base-32 (no look-alikes)", 32, 10),
    ("13 chars base-32 (about 65 bits)", 32, 13),
]
print("%-58s %8s %10s" % ("format", "bits", "space"))
for name, base, n in formats:
    bits = n * math.log2(base)
    print("%-58s %8.2f %10.3e" % (name, bits, float(base) ** n))

print()
print("RFC 8628 section 5.1 worked example check: attempts A needed for success probability 2^-32")
print("with an 8-char base-20 code and ONE live code: A = 2^-32 * 20^8 = %.2f" % (2 ** -32 * 20 ** 8))
print()
print("Probability that an attacker who submits A guesses at the approval endpoint hits one of M live")
print("codes (union bound, uniform codes): P = A*M/space. Values for A = guesses allowed per code window.")
print("%-58s %6s %6s %12s" % ("format", "A", "M", "P"))
for name, base, n in formats:
    for A, M in [(5, 1), (10, 1), (10, 20), (100, 20)]:
        space = float(base) ** n
        print("%-58s %6d %6d %12.3e" % (name, A, M, A * M / space))
print()
print("ASVS 6.5.4 minimum 20 bits; 6.6.3 'consider at least 64 bits' (read from the official CSV, see S10).")
for name, base, n in formats:
    bits = n * math.log2(base)
    print("%-58s >=20 bits: %-5s >=64 bits: %s" % (name, bits >= 20, bits >= 64))
