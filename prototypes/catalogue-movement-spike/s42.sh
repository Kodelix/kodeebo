#!/usr/bin/env bash
# PROTOTYPE - NOT FOR PRODUCTION
# S42 driver on the shared Windows 10 VM (founder 2026-10-22: VM free for S42). Mirrors the sync spike's p4.sh steps
# (prototypes/local-first-sync-spike/harness/p4.sh, read only): shut off, revert clean-ssh2, boot, disk throttle
# 100 IOPS + 80 MiB/s, install, run, fetch, shut off + revert clean-ssh2 (always, via the EXIT trap).
# The desktop spike's key and pinned host key are used BY PATH ONLY: never read, printed or copied here.
# Windows Python 3.14.8 embeddable + apsw-sqlite3mc 3.54.0.0 come from the sync spike's tools folder, read only.
# Logs and results stay in this folder (runs/). Usage: bash s42.sh  [env SALES_PER_N VOIDS_PER_N GAP_S HISTORY_LINES]
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
DESK="$ROOT/prototypes/desktop-client-spike"
KEY="$DESK/.keys/spike_ed25519"           # path only, never read here
KH="$DESK/.keys/known_hosts"
TOOLS="$ROOT/prototypes/local-first-sync-spike/tools/win-python-3.14.8"   # read only
DOM=kodeebo-win10
V="virsh -c qemu:///system"
RUNS="$HERE/runs"; mkdir -p "$RUNS"
STATUS="$RUNS/s42.status"; LOG="$RUNS/s42.log"
OPTS=(-F /dev/null -i "$KEY" -o IdentitiesOnly=yes -o UserKnownHostsFile="$KH" -o StrictHostKeyChecking=yes
      -o BatchMode=yes -o ConnectTimeout=10 -o LogLevel=ERROR -o ServerAliveInterval=5 -o ServerAliveCountMax=3)
ip() { $V domifaddr "$DOM" --source lease | awk '/ipv4/{split($4,a,"/"); print a[1]; exit}'; }
who() { case "$1" in admin) echo kodeebo-win10 ;; cashier) echo cashier ;; esac; }
sshv() { local u; u=$(who "$1"); shift; ssh "${OPTS[@]}" "$u@$(ip)" "$@" 2>&1 | tr -d '\r'; }
put() { scp -q "${OPTS[@]}" "$2" "$(who "$1")@$(ip):$3"; }
get() { scp -q "${OPTS[@]}" "$(who "$1")@$(ip):$2" "$3"; }
throttle() { $V blkdeviotune $DOM sda --live --total-iops-sec 100 --total-bytes-sec 83886080; }
waitssh() { for _ in $(seq 1 180); do sshv "$1" 'echo up' 2>/dev/null | grep -q up && return 0; sleep 5; done; return 1; }
log() { printf '%s %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG"; }
st() { printf '%s %s\n' "$*" "$(date +%H:%M:%S)" >> "$STATUS"; }
shutoff() {
  [ "$($V domstate $DOM)" = "shut off" ] && return 0
  sshv admin 'shutdown /s /t 0' >/dev/null 2>&1
  for _ in $(seq 1 24); do sleep 5; [ "$($V domstate $DOM)" = "shut off" ] && return 0; done
  $V destroy $DOM >/dev/null 2>&1   # hard power-off only if Windows did not shut down within 2 minutes
}
down() { shutoff; $V snapshot-revert $DOM clean-ssh2 && log "s42 down: shut off, reverted clean-ssh2" && st down; }
trap 'down; st DONE' EXIT
W='C:\Users\cashier\s42'

st "start $(git -C "$ROOT" rev-parse --short HEAD)$(git -C "$ROOT" status --porcelain -- prototypes/catalogue-movement-spike | grep -qv '^?? prototypes/catalogue-movement-spike/runs/' && echo +dirty)"
log "s42: VM state before: $($V domstate $DOM)"
shutoff
$V snapshot-revert $DOM clean-ssh2 && $V start $DOM >/dev/null && waitssh admin || { log "s42 up: VM did not come up"; st "up FAILED"; exit 1; }
throttle; log "s42 up: reverted clean-ssh2, booted, throttled (100 IOPS + 80 MiB/s)"; st up
sshv cashier "powershell -NoProfile -Command \"New-Item -ItemType Directory -Force $W | Out-Null\"" >/dev/null
put cashier "$TOOLS/python-3.14.8-embed-amd64.zip" "C:/Users/cashier/s42/py.zip"
put cashier "$TOOLS/apsw_sqlite3mc-3.54.0.0-cp314-cp314-win_amd64.whl" "C:/Users/cashier/s42/apsw.zip"
put cashier "$HERE/s42.py" "C:/Users/cashier/s42/s42.py"
sshv cashier "powershell -NoProfile -Command \"Expand-Archive -Force $W\\py.zip $W\\py; Expand-Archive -Force $W\\apsw.zip $W\\site; Add-Content $W\\py\\python314._pth '..\\site'; & $W\\py\\python.exe -c 'import sys, apsw; print(sys.version.split()[0], apsw.apsw_version(), apsw.sqlite_lib_version())'\"" | tee -a "$LOG"
st install
envs="set SALES_PER_N=${SALES_PER_N:-400}&& set VOIDS_PER_N=${VOIDS_PER_N:-100}&& set GAP_S=${GAP_S:-1.0}&& set HISTORY_LINES=${HISTORY_LINES:-50000}&&"
log "s42 run: $envs"
sshv cashier "$envs $W\\py\\python.exe -B $W\\s42.py $W" > "$RUNS/s42-run.out"; rc=$?
st "run rc=$rc"; log "s42 run rc=$rc"
get cashier "C:/Users/cashier/s42/s42-summary.json" "$RUNS/s42-summary.json" && get cashier "C:/Users/cashier/s42/s42-results.csv" "$RUNS/s42-results.csv" && st fetched
