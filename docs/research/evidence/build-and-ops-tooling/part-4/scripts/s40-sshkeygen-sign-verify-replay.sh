#!/usr/bin/env bash
# S40/S41/S42 (tier E). FAKE keys only: generated for this run, never real, kept in the gitignored
# work dir (production/session-state/cache/...), not in evidence. Public keys + outputs go to stdout.
# Usage: bash s40-sshkeygen-sign-verify-replay.sh <work_dir_in_cache>
# Tests: ssh-keygen -Y sign/verify with namespace + allowed_signers; negative cases; replay/rollback
# gate (next-release + previous-manifest-hash chain); S41 unlocked-agent use by another process and
# `ssh-add -c` confirmation prompt content.
set -u
W="$(readlink -m "${1:?work dir}")"
rm -rf "$W/s40" && mkdir -p "$W/s40/v" "$W/s40/state" "$W/s40/m" && cd "$W/s40" || exit 2
NS="kodeebo-release-manifest-v1"
ID="founder-signing@kodeebo"
echo "# S40 run $(date -u +%FT%TZ) $(ssh -V 2>&1)"
echo "# FAKE keys: generated now, never real"

# --- keys (FAKE) ---
ssh-keygen -q -t ed25519 -N "" -C "FAKE-founder-signing-key" -f founder_FAKE
ssh-keygen -q -t ed25519 -N "" -C "FAKE-attacker-key" -f attacker_FAKE
printf '%s namespaces="%s" %s\n' "$ID" "$NS" "$(cut -d' ' -f1,2 founder_FAKE.pub)" > allowed_signers
printf '%s namespaces="%s",valid-before="20200101Z" %s\n' "$ID" "$NS" "$(cut -d' ' -f1,2 founder_FAKE.pub)" > allowed_signers_expired
echo "## allowed_signers (public data)"; cat allowed_signers

# --- manifest builder: line format, parsed only from verified bytes ---
mk() { # $1 file $2 release $3 prev_sha $4 digest_tag
  printf 'kodeebo-release-manifest-v1\nrelease=%s\nprevious_manifest_sha256=%s\nimage_digest=sha256:FAKE%s\nmigration_ids=0001,0002\nkey_fp.pepper=FAKEFP\n' "$2" "$3" "$4" > "$1"
}
sha() { sha256sum "$1" | cut -d' ' -f1; }

# --- the verifier (what the root deploy script would do; state dir stands in for /var/lib/...) ---
verify_gate() { # $1 manifest $2 sig $3 allowed_signers ; prints decision ; returns 0 accept
  cp "$1" v/m.bin; cp "$2" v/m.sig          # verify and parse the SAME copied bytes (no TOCTOU on the agent-writable inbox)
  if ! ssh-keygen -Y verify -f "$3" -I "$ID" -n "$NS" -s v/m.sig < v/m.bin >v/out 2>v/err; then
    echo "REFUSED reason=bad_signature ($(tr '\n' ' ' < v/err | cut -c1-90))"; return 1; fi
  [ "$(head -1 v/m.bin)" = "kodeebo-release-manifest-v1" ] || { echo "REFUSED reason=bad_header"; return 1; }
  [ "$(grep -c '^release=' v/m.bin)" = 1 ] || { echo "REFUSED reason=release_field_count"; return 1; }
  rel="$(sed -n 's/^release=\([0-9]\{1,9\}\)$/\1/p' v/m.bin)"; prev="$(sed -n 's/^previous_manifest_sha256=\([0-9a-f]\{64\}\|none\)$/\1/p' v/m.bin)"
  [ -n "$rel" ] && [ -n "$prev" ] || { echo "REFUSED reason=field_syntax"; return 1; }
  last="$(cat state/last_release 2>/dev/null || echo 0)"; lastsha="$(cat state/last_sha 2>/dev/null || echo none)"
  [ "$rel" -eq $((last + 1)) ] || { echo "REFUSED reason=not_next_release release=$rel last=$last"; return 1; }
  [ "$prev" = "$lastsha" ] || { echo "REFUSED reason=chain_mismatch release=$rel"; return 1; }
  # accept: the real script would write state only after a successful deploy
  echo "$rel" > state/last_release.tmp && mv state/last_release.tmp state/last_release
  sha v/m.bin > state/last_sha.tmp && mv state/last_sha.tmp state/last_sha
  echo "ACCEPTED release=$rel signer=$ID"; return 0
}
sign() { ssh-keygen -q -Y sign -f "$1" -n "${3:-$NS}" "$2" >/dev/null 2>&1; }   # writes $2.sig

echo; echo "## S42 replay / rollback / negative cases"
mk m/m1 1 none 1; sign founder_FAKE m/m1;   echo -n "A genuine release 1:                "; verify_gate m/m1 m/m1.sig allowed_signers
S1="$(sha m/m1)"
mk m/m2 2 "$S1" 2; sign founder_FAKE m/m2;  echo -n "B genuine release 2 (prev=sha m1):  "; verify_gate m/m2 m/m2.sig allowed_signers
S2="$(sha m/m2)"
echo -n "C replay of valid release 1:        "; verify_gate m/m1 m/m1.sig allowed_signers
echo -n "D replay of valid release 2 again:   "; verify_gate m/m2 m/m2.sig allowed_signers
cp m/m2 m/m2t; sed -i 's/FAKE2/FAKEX/' m/m2t; echo -n "E tampered release-2 bytes, old sig: "; verify_gate m/m2t m/m2.sig allowed_signers
mk m/m3g 3 "$S2" 3; sign founder_FAKE m/m3g git; echo -n "F signature made in namespace git:   "; verify_gate m/m3g m/m3g.sig allowed_signers
mk m/m3a 3 "$S2" 3; sign attacker_FAKE m/m3a;    echo -n "G attacker key, right namespace:    "; verify_gate m/m3a m/m3a.sig allowed_signers
echo -n "G2 ssh-keygen -Y check-novalidate on the attacker signature (must not be used to decide): "
ssh-keygen -Y check-novalidate -n "$NS" -s m/m3a.sig < m/m3a >/dev/null 2>&1 && echo "exit 0 (OK despite unauthorised signer)" || echo "exit non-zero"
mk m/m4 4 "$S2" 4; sign founder_FAKE m/m4;       echo -n "H skip-ahead (release 4 after 2):    "; verify_gate m/m4 m/m4.sig allowed_signers
mk m/m3f 3 "$(printf 'f%.0s' $(seq 64))" 3; sign founder_FAKE m/m3f; echo -n "I fork (release 3, wrong prev hash): "; verify_gate m/m3f m/m3f.sig allowed_signers
printf 'kodeebo-release-manifest-v1\nrelease=3\nrelease=9\nprevious_manifest_sha256=%s\n' "$S2" > m/m3d; sign founder_FAKE m/m3d
echo -n "J duplicate release= fields:         "; verify_gate m/m3d m/m3d.sig allowed_signers
mk m/m3 3 "$S2" 3; sign founder_FAKE m/m3;       echo -n "K expired signer entry (valid-before 2020): "; cp -r state state.keep; verify_gate m/m3 m/m3.sig allowed_signers_expired; rm -rf state; mv state.keep state
echo -n "L genuine release 3 (after the above): "; verify_gate m/m3 m/m3.sig allowed_signers
echo "state now: release=$(cat state/last_release)"
echo "signature file head (public format):"; head -2 m/m1.sig

echo; echo "## S41 same-user use of an unlocked ssh-agent, and ssh-add -c prompt content (FAKE key)"
# key with a passphrase, loaded into a private agent via an askpass script that supplies it
ssh-keygen -q -t ed25519 -N "fake-passphrase-S41" -C "FAKE-pass-key" -f pass_FAKE
cat > askpass_pass.sh <<'EOS'
#!/bin/sh
echo "$(date -u +%T) askpass-called: $1" >> askpass.log
case "$1" in *assphrase*) echo "fake-passphrase-S41";; *) [ -f deny ] && exit 1; exit 0;; esac
EOS
chmod +x askpass_pass.sh
eval "$(ssh-agent -a ./a.sock -s)" >/dev/null
trap 'kill $SSH_AGENT_PID 2>/dev/null' EXIT
export SSH_ASKPASS="$PWD/askpass_pass.sh" SSH_ASKPASS_REQUIRE=force
ssh-add pass_FAKE >/dev/null 2>&1 && echo "key added to private agent (passphrase supplied once)"
echo "attacker-chosen content that the founder never saw" > m/evil
# a different process of the same user: only needs the socket path and the PUBLIC key
( SSH_AUTH_SOCK="$PWD/a.sock" bash -c 'env -u SSH_ASKPASS -u SSH_ASKPASS_REQUIRE ssh-keygen -q -Y sign -f pass_FAKE.pub -n '"$NS"' m/evil' >/dev/null 2>&1 ) \
  && echo "T1 another process, no passphrase, signed arbitrary content via the agent: $(test -s m/evil.sig && echo YES || echo NO)" || echo "T1 sign via agent failed"
rm -f m/evil.sig
ssh-add -D >/dev/null 2>&1; ssh-add -c pass_FAKE >/dev/null 2>&1 && echo "re-added with confirm (-c)"
: > askpass.log
touch deny
( SSH_AUTH_SOCK="$PWD/a.sock" bash -c 'ssh-keygen -q -Y sign -f pass_FAKE.pub -n '"$NS"' m/evil' >/dev/null 2>&1 ) \
  && echo "T2 confirm DENIED by askpass: signed anyway = $(test -s m/evil.sig && echo YES || echo NO)" || echo "T2 confirm denied: signing refused"
rm -f deny m/evil.sig
( SSH_AUTH_SOCK="$PWD/a.sock" bash -c 'ssh-keygen -q -Y sign -f pass_FAKE.pub -n '"$NS"' m/evil' >/dev/null 2>&1 ) \
  && echo "T3 confirm ACCEPTED by askpass: signed = $(test -s m/evil.sig && echo YES || echo NO)" || echo "T3 sign failed after accept"
echo "askpass prompts the agent showed (what the founder would see):"; cat askpass.log
