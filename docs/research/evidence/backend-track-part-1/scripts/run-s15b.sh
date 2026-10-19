#!/usr/bin/env bash
# S15b: AppCDS rerun. The CDS section of run-s15.sh was a WRONG TEST (label argument not shifted, so docker treated it as the image name); see F126.
# Command: bash scripts/run-s15b.sh > s15b-output.txt 2>&1   (from the evidence dir)
source "$(dirname "$0")/lib.sh"
D=$EVID/scratch/s15b; rm -rf "$D"; mkdir -p "$D/cds"; chmod 777 "$D/cds"
echo "date=$(date -u +%FT%TZ)"
ONE() { # label, then extra docker args
  local label=$1; shift
  docker rm -f kprobe-run >/dev/null 2>&1
  local t0; t0=$(now_ms)
  docker run -d --name kprobe-run -p 127.0.0.1:18080:8080 --memory=512m --cpus=2 -v "$D/cds:/cds" "$@" kprobe-ktor >/dev/null
  wait_http http://127.0.0.1:18080/ping >/dev/null
  echo "$label wall_ms_to_first_200=$(( $(now_ms) - t0 )) $(sleep 3; rss kprobe-run)"
  docker stop -t 10 kprobe-run >/dev/null; docker rm -f kprobe-run >/dev/null
}
OPTS="-XX:+AutoCreateSharedArchive -XX:SharedArchiveFile=/cds/app.jsa"
ONE no_cds_baseline
ONE no_cds_baseline_again
ONE cds_run1_creates_archive -e "JAVA_OPTS=$OPTS"
ls -la "$D/cds" | tail -1
ONE cds_run2_uses_archive -e "JAVA_OPTS=$OPTS"
ONE cds_run3_uses_archive -e "JAVA_OPTS=$OPTS"
ONE cds_plus_tiered1_serial -e "JAVA_OPTS=$OPTS -XX:TieredStopAtLevel=1"
