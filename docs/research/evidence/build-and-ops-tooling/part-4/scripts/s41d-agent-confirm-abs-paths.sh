#!/usr/bin/env bash
# S41d (tier E): `ssh-add -c` confirmation test, corrected. S41b and S41c were wrong set-ups: the
# daemonised ssh-agent runs with cwd "/", so the askpass script's RELATIVE log and `deny` paths
# pointed at "/" and the confirmation was always answered "yes" with nothing logged.
# Here the askpass uses ABSOLUTE paths and the private key file is removed after loading.
# FAKE keys only, in the gitignored work dir. Usage: bash s41d-agent-confirm-abs-paths.sh <work_dir_in_cache>
set -u
W="$(readlink -m "${1:?work dir}")"
rm -rf "$W/s41d" && mkdir -p "$W/s41d/m" && cd "$W/s41d" || exit 2
D="$PWD"
echo "# S41d run $(date -u +%FT%TZ) $(ssh -V 2>&1)"
NS="kodeebo-release-manifest-v1"
ssh-keygen -q -t ed25519 -N "" -C "FAKE-confirm-key" -f k_FAKE
cat > askpass.sh <<EOS
#!/bin/sh
echo "\$(date -u +%T) askpass-called argv1=[\$1]" >> $D/askpass.log
[ -f $D/deny ] && exit 1
exit 0
EOS
chmod +x askpass.sh
export SSH_ASKPASS="$D/askpass.sh" SSH_ASKPASS_REQUIRE=force
eval "$(ssh-agent -a $D/a.sock -s)" >/dev/null
trap 'kill $SSH_AGENT_PID 2>/dev/null' EXIT
ssh-add -c k_FAKE 2>&1 | tail -2
rm -f k_FAKE; echo "private key file removed after loading into the agent; only k_FAKE.pub remains"
echo "attacker-chosen content that the founder never saw" > m/evil
: > askpass.log
touch deny
if SSH_AUTH_SOCK="$D/a.sock" ssh-keygen -q -Y sign -f k_FAKE.pub -n "$NS" m/evil >/dev/null 2>&1; then echo "T2 confirmation DENIED: signed anyway = YES"; else echo "T2 confirmation DENIED: signing refused"; fi
rm -f deny m/evil.sig
if SSH_AUTH_SOCK="$D/a.sock" ssh-keygen -q -Y sign -f k_FAKE.pub -n "$NS" m/evil >/dev/null 2>&1; then echo "T3 confirmation ACCEPTED: signed = $(test -s m/evil.sig && echo YES || echo NO)"; else echo "T3 confirmation ACCEPTED: signing failed"; fi
echo "--- askpass.log: the text the founder would be shown ---"; cat askpass.log
echo "--- is the agent socket mode restricted? ---"; stat -c '%A %U %n' "$D/a.sock"
