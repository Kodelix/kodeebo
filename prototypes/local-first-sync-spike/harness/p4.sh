#!/usr/bin/env bash
# PROTOTYPE - NOT FOR PRODUCTION
# Phase 4 driver: the same sync client on the shared Windows 10 VM (README "Phase 4").
# VM access uses the desktop spike's dedicated key and pinned host key BY PATH ONLY (founder, 2026-10-19): this script
# never reads, prints or copies the key. The server and PostgreSQL stay on this host bound to 127.0.0.1; the VM reaches
# them through an SSH reverse tunnel (VM 127.0.0.1:18471 -> host 127.0.0.1:<port>), which dies at every power cut.
#   up                       revert clean-ssh2 (VM shut off), boot, wait for ssh, apply the disk throttle
#   install                  copy Python 3.14.8 embeddable + apsw-sqlite3mc wheel + client to C:\Users\cashier\p4
#   down                     shut the VM off and revert clean-ssh2 (after EACH run)
#   tunnel <host_port>       open the reverse tunnel in the background (pid in runs/p4-tunnel.pid)
#   cs <command...>          run a command as cashier;  ad <command...> as admin
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DESK="$(cd "$HERE/../desktop-client-spike" && pwd)"
KEY="$DESK/.keys/spike_ed25519"           # path only, never read here
KH="$DESK/.keys/known_hosts"
DOM=kodeebo-win10
V="virsh -c qemu:///system"
RUNS="$HERE/runs"
OPTS=(-F /dev/null -i "$KEY" -o IdentitiesOnly=yes -o UserKnownHostsFile="$KH" -o StrictHostKeyChecking=yes
      -o BatchMode=yes -o ConnectTimeout=10 -o LogLevel=ERROR -o ServerAliveInterval=5 -o ServerAliveCountMax=3)
ip() { $V domifaddr "$DOM" --source lease | awk '/ipv4/{split($4,a,"/"); print a[1]; exit}'; }
who() { case "$1" in admin) echo kodeebo-win10 ;; cashier) echo cashier ;; esac; }
sshv() { local u; u=$(who "$1"); shift; ssh "${OPTS[@]}" "$u@$(ip)" "$@" 2>&1 | tr -d '\r'; }
put() { scp -q "${OPTS[@]}" "$2" "$(who "$1")@$(ip):$3"; }
get() { scp -q "${OPTS[@]}" "$(who "$1")@$(ip):$2" "$3"; }
throttle() { $V blkdeviotune $DOM sda --live --total-iops-sec 100 --total-bytes-sec 83886080; }
waitssh() { for _ in $(seq 1 180); do sshv "$1" 'echo up' 2>/dev/null | grep -q up && return 0; sleep 5; done; return 1; }
# set 6 finding: right after a boot one upload can fail ("scp: Connection closed") and nothing noticed. Each install
# upload is checked by its size on the VM and re-sent up to 10 times; every re-send is a logged transport retry.
put_verified() {  # <local file> <VM path with forward slashes>
  local want got n; want=$(stat -c %s "$1")
  for n in $(seq 1 10); do
    put cashier "$1" "$2"
    got=$(sshv cashier "powershell -NoProfile -Command \"(Get-Item '$2').Length\"" | tr -d ' \r\n')
    [ "$got" = "$want" ] && return 0
    echo "transport retry (install upload $n): $(date '+%F %T') $(basename "$1") on the VM is ${got:-missing}, want $want" \
      | tee -a "$RUNS/p4-install-retries.log" >&2
    sleep 5
  done
  echo "install: $(basename "$1") never arrived intact after 10 sends" >&2; return 1
}
log() { printf '%s %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$RUNS/p4-$(date +%Y%m%d).log"; }
W='C:\Users\cashier\p4'

step=${1:?up|install|down|tunnel|put|get|argv|cs|ad}; shift
case "$step" in
up)
  [ "$($V domstate $DOM)" = "shut off" ] || { echo "VM is not shut off: refusing to revert" >&2; exit 1; }
  $V snapshot-revert $DOM clean-ssh2 && $V start $DOM >/dev/null && waitssh admin || { log "p4 up: VM did not come up"; exit 1; }
  throttle; log "p4 up: reverted clean-ssh2, booted, throttled (100 IOPS + 80 MiB/s)" ;;
down)
  [ "$($V domstate $DOM)" = "shut off" ] || { sshv admin 'shutdown /s /t 0' >/dev/null 2>&1; sleep 60; $V destroy $DOM >/dev/null 2>&1; }
  $V snapshot-revert $DOM clean-ssh2 && log "p4 down: shut off, reverted clean-ssh2" ;;
install)
  T="$HERE/tools/win-python-3.14.8"
  waitssh cashier || { echo "install: the cashier account does not answer" >&2; exit 1; }
  sshv cashier "powershell -NoProfile -Command \"New-Item -ItemType Directory -Force $W | Out-Null\"" >/dev/null
  put_verified "$T/python-3.14.8-embed-amd64.zip" "C:/Users/cashier/p4/py.zip" || exit 1
  put_verified "$T/apsw_sqlite3mc-3.54.0.0-cp314-cp314-win_amd64.whl" "C:/Users/cashier/p4/apsw.zip" || exit 1
  put_verified "$HERE/sut/client.py" "C:/Users/cashier/p4/client.py" || exit 1
  sshv cashier "powershell -NoProfile -Command \"Expand-Archive -Force $W\\py.zip $W\\py; Expand-Archive -Force $W\\apsw.zip $W\\site; Add-Content $W\\py\\python314._pth '..\\site'; & $W\\py\\python.exe -c 'import sys, apsw; print(sys.version.split()[0], apsw.apsw_version(), apsw.sqlite_lib_version())'\""
  ;;
tunnel)
  port=${1:?host port}
  ssh "${OPTS[@]}" -N -R "127.0.0.1:18471:127.0.0.1:$port" "cashier@$(ip)" > "$RUNS/p4-tunnel.log" 2>&1 &
  echo $! > "$RUNS/p4-tunnel.pid"; sleep 2; kill -0 "$(cat "$RUNS/p4-tunnel.pid")" && log "p4 tunnel: VM 127.0.0.1:18471 -> host 127.0.0.1:$port" ;;
put) put cashier "$1" "$2" ;;
get) get cashier "$1" "$2" ;;
argv) printf '%s\n' ssh "${OPTS[@]}" "cashier@$(ip)" ;;   # the ssh command line for a piped client (key by path)
cs) sshv cashier "$@" ;;
ad) sshv admin "$@" ;;
esac
