#!/bin/bash
# Shared definition of the founder's scanner condition for S51. Sourced by the s51-0x scripts.
# Locked-down container: no network, read-only root, all caps dropped, no-new-privileges, non-root,
# pids and memory limits, noexec tmpfs; binary dir and input tarball mounted read-only; one empty
# writable output dir; no home, no docker socket, no env secrets (HOME and cache dir point at the tmpfs).
# The runtime image is one already present locally (--pull=never); the Trivy binary is the downloaded,
# SHA-256-verified one and is only ever executed inside this container.
ROOT=/home/kiko/saas-products/kodeebo
CACHE=$ROOT/production/session-state/cache/build-and-ops-tooling/part-5
EVID=$ROOT/docs/research/evidence/build-and-ops-tooling/part-5
BIN=$CACHE/trivy-dl/bin
RUNTIME=eclipse-temurin:21-jre
MEM=${MEM:-3g}
TMPFS_SIZE=${TMPFS_SIZE:-1g}
# SCAN_FLAGS_DOCKER is the exact docker part; printed to the output for the record.
SCAN_DOCKER_FLAGS=(--pull=never --rm --read-only --network none --cap-drop ALL --security-opt no-new-privileges
  --user 65534:65534 --pids-limit 256 --memory "$MEM" --memory-swap "$MEM" --cpus 2
  --tmpfs "/tmp:rw,noexec,nosuid,nodev,size=$TMPFS_SIZE"
  -e HOME=/tmp -e TRIVY_CACHE_DIR=/tmp/trivycache
  -v "$BIN":/opt/trivy:ro)
