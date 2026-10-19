#!/usr/bin/env bash
# Shared helpers for spikes S10-S13 (scratch). Source this file; it sets EVID and keeps every cache inside the repo.
set -u
REPO=/home/kiko/saas-products/kodeebo
EVID=$REPO/docs/research/evidence/backend-track-part-1
mkdir -p "$EVID/tmp" "$EVID/scratch"
export TMPDIR=$EVID/tmp

# now_ms: current time in milliseconds
now_ms() { echo $(( $(date +%s%N) / 1000000 )); }

# wait_http URL: block until URL answers 200, print elapsed ms since the call started
wait_http() {
  local url=$1 t0; t0=$(now_ms)
  for _ in $(seq 1 2000); do
    if curl -fsS -o /dev/null --max-time 1 "$url" 2>/dev/null; then echo $(( $(now_ms) - t0 )); return 0; fi
    sleep 0.01
  done
  echo -1; return 1
}

# rss CONTAINER: host-side VmRSS and VmHWM (kB) of the container's main process, plus docker's cgroup figure
rss() {
  local pid; pid=$(docker inspect -f '{{.State.Pid}}' "$1")
  echo "VmRSS_kB=$(awk '/VmRSS/{print $2}' /proc/$pid/status) VmHWM_kB=$(awk '/VmHWM/{print $2}' /proc/$pid/status) threads=$(awk '/Threads/{print $2}' /proc/$pid/status) cgroup_mem=$(docker stats --no-stream --format '{{.MemUsage}}' "$1")"
}
