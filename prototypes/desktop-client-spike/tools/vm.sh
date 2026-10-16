#!/usr/bin/env bash
# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
#
# SSH/SCP into the test VM with the dedicated spike key only (never ~/.ssh), pinned host key.
# Usage: tools/vm.sh ssh <admin|cashier> <command...>
#        tools/vm.sh put <admin|cashier> <local> <remote>
#        tools/vm.sh get <admin|cashier> <remote> <local>
#        tools/vm.sh ip
set -euo pipefail
D="$(cd "$(dirname "$0")/.." && pwd)"
DOM=kodeebo-win10
V="virsh -c qemu:///system"
ip() { $V domifaddr "$DOM" --source lease | awk '/ipv4/{split($4,a,"/"); print a[1]; exit}'; }
user() { case "$1" in admin) echo kodeebo-win10 ;; cashier) echo cashier ;; *) echo "unknown user $1" >&2; exit 2 ;; esac; }
OPTS=(-F /dev/null -i "$D/.keys/spike_ed25519" -o IdentitiesOnly=yes -o UserKnownHostsFile="$D/.keys/known_hosts"
      -o StrictHostKeyChecking=yes -o BatchMode=yes -o ConnectTimeout=10 -o LogLevel=ERROR)
case "${1:-}" in
  ip)  ip ;;
  ssh) u=$(user "$2"); shift 2; ssh "${OPTS[@]}" "$u@$(ip)" "$@" ;;
  put) u=$(user "$2"); scp -q "${OPTS[@]}" "$3" "$u@$(ip):$4" ;;
  get) u=$(user "$2"); scp -q "${OPTS[@]}" "$u@$(ip):$3" "$4" ;;
  *) sed -n '6,10p' "$0"; exit 2 ;;
esac
