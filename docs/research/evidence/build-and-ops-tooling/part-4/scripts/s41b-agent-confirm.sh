#!/usr/bin/env bash
# S41b (tier E): re-run of the `ssh-add -c` confirmation test with the correct set-up
# (SSH_ASKPASS exported BEFORE ssh-agent starts). Supersedes T2/T3 of S40 run 1, which were wrong set-up.
# FAKE keys only, in the gitignored work dir. Usage: bash s41b-agent-confirm.sh <work_dir_in_cache>
set -u
W="$(readlink -m "${1:?work dir}")"
rm -rf "$W/s41b" && mkdir -p "$W/s41b/m" && cd "$W/s41b" || exit 2
echo "# S41b run $(date -u +%FT%TZ) $(ssh -V 2>&1)"
NS="kodeebo-release-manifest-v1"
ssh-keygen -q -t ed25519 -N "" -C "FAKE-confirm-key" -f k_FAKE
cat > askpass.sh <<'EOS'
#!/bin/sh
# logs exactly what the agent asks the human; answers by presence of ./deny
echo "$(date -u +%T) askpass-called argv1=[$1]" >> askpass.log
[ -f deny ] && exit 1
exit 0
EOS
chmod +x askpass.sh
export SSH_ASKPASS="$PWD/askpass.sh" SSH_ASKPASS_REQUIRE=force
eval "$(ssh-agent -a ./a.sock -s)" >/dev/null
trap 'kill $SSH_AGENT_PID 2>/dev/null' EXIT
ssh-add -c k_FAKE 2>&1 | tail -2
echo "attacker-chosen content that the founder never saw" > m/evil
: > askpass.log
touch deny
if SSH_AUTH_SOCK="$PWD/a.sock" ssh-keygen -q -Y sign -f k_FAKE.pub -n "$NS" m/evil >/dev/null 2>&1; then echo "T2 confirmation DENIED: signed anyway = YES"; else echo "T2 confirmation DENIED: signing refused"; fi
rm -f deny m/evil.sig
if SSH_AUTH_SOCK="$PWD/a.sock" ssh-keygen -q -Y sign -f k_FAKE.pub -n "$NS" m/evil >/dev/null 2>&1; then echo "T3 confirmation ACCEPTED: signed = $(test -s m/evil.sig && echo YES || echo NO)"; else echo "T3 confirmation ACCEPTED: signing failed"; fi
echo "--- askpass.log: the text the founder would be shown ---"; cat askpass.log
echo "--- ssh-add -l (what an agent client can learn without a secret) ---"
SSH_AUTH_SOCK="$PWD/a.sock" ssh-add -l 2>&1
