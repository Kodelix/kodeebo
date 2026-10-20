#!/usr/bin/env bash
# S40v — ssh-keygen -Y verify behaviour ON THE VPS (founder-run, 2026-10-20).
# Run by the founder on the production VPS as an unprivileged user, pasted as `bash -s <<'EOF' ... EOF`.
# Throwaway FAKE keys in a mktemp dir, deleted at the end; no root, no real key, no config touched.
# Repeats the F410 refusals (S40, founder machine) on the VPS's own OpenSSH, to close the ADR-0009
# acceptance blocker "VPS OpenSSH supports -Y verify with allowed_signers, namespaces=, valid-before".
set -u; d=$(mktemp -d); cd "$d" || exit 1; ns=kodeebo-release-manifest-v1; id=founder-signing@kodeebo
echo "ssh-keygen: $(command -v ssh-keygen || echo MISSING)"; ssh -V 2>&1; dpkg -S "$(command -v ssh-keygen)" 2>/dev/null
ssh-keygen -q -t ed25519 -N '' -C FAKE-founder -f k; ssh-keygen -q -t ed25519 -N '' -C FAKE-attacker -f a
printf 'release=1\nprevious_manifest_sha256=00\n' > m; cp m mg; cp m ma
ssh-keygen -q -Y sign -f k -n "$ns" m; ssh-keygen -q -Y sign -f k -n git mg; ssh-keygen -q -Y sign -f a -n "$ns" ma
echo "$id namespaces=\"$ns\" $(cat k.pub)" > as; echo "$id namespaces=\"$ns\",valid-before=\"20200101Z\" $(cat k.pub)" > as_exp
v(){ ssh-keygen -Y verify -f "$1" -I "$id" -n "$ns" -s "$2" < "$3" >/dev/null 2>&1; echo $?; }
r=$(v as m.sig m);                               [ "$r" = 0 ] && echo "T1 valid signature accepted: PASS" || echo "T1 valid signature accepted: FAIL rc=$r"
r=$(printf 'release=2\n' | ssh-keygen -Y verify -f as -I "$id" -n "$ns" -s m.sig >/dev/null 2>&1; echo $?); [ "$r" != 0 ] && echo "T2 tampered manifest refused: PASS" || echo "T2 tampered manifest refused: FAIL"
r=$(v as mg.sig mg);                             [ "$r" != 0 ] && echo "T3 wrong namespace refused: PASS" || echo "T3 wrong namespace refused: FAIL"
r=$(v as ma.sig ma);                             [ "$r" != 0 ] && echo "T4 unknown signer refused: PASS" || echo "T4 unknown signer refused: FAIL"
r=$(v as_exp m.sig m);                           [ "$r" != 0 ] && echo "T5 expired signer (valid-before) refused: PASS" || echo "T5 expired signer refused: FAIL"
cd / && rm -rf "$d"; echo done
