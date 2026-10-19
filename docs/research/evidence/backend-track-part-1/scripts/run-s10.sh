#!/usr/bin/env bash
# S10: Go probe build time, reproducibility, image size, container footprint. Output: ../s10-output.txt (stdout of this script).
# Command: bash scripts/run-s10.sh   (from the evidence dir)
source "$(dirname "$0")/lib.sh"
export GOTOOLCHAIN=local GOFLAGS=-mod=readonly CGO_ENABLED=0
export GOCACHE=$EVID/scratch/gocache GOPATH=$EVID/scratch/gopath GOTMPDIR=$EVID/tmp
rm -rf "$EVID/scratch/gocache" "$EVID/scratch/s10"; mkdir -p "$EVID/scratch/s10/a" "$EVID/scratch/s10/b" "$EVID/scratch/s10/dock"
echo "date=$(date -u +%FT%TZ) go=$(go version) docker=$(docker --version) host_cpus=$(nproc) host_mem_MB=$(free -m | awk '/Mem:/{print $2}')"

# copies of the source in two different directories (reproducibility with -trimpath)
cp "$EVID"/scripts/go-probe/main.go "$EVID"/scripts/go-probe/go.mod "$EVID/scratch/s10/a/"
cp "$EVID"/scripts/go-probe/main.go "$EVID"/scripts/go-probe/go.mod "$EVID/scratch/s10/b/"

t0=$(now_ms); (cd "$EVID/scratch/s10/a" && go build -trimpath -ldflags="-s -w" -o probe-go .); echo "go_build_cold_cache_ms=$(( $(now_ms) - t0 ))"
(cd "$EVID/scratch/s10/a" && touch main.go && echo "// touch" >> main.go && sed -i '$d' main.go)
t0=$(now_ms); (cd "$EVID/scratch/s10/b" && go build -trimpath -ldflags="-s -w" -o probe-go .); echo "go_build_warm_cache_ms=$(( $(now_ms) - t0 ))"
echo "sha256_a=$(sha256sum "$EVID/scratch/s10/a/probe-go" | cut -c1-64)"
echo "sha256_b=$(sha256sum "$EVID/scratch/s10/b/probe-go" | cut -c1-64)"
echo "binary_bytes=$(stat -c %s "$EVID/scratch/s10/a/probe-go")"
t0=$(now_ms); (cd "$EVID/scratch/loadgen_build" 2>/dev/null || true); mkdir -p "$EVID/scratch/s10/lg"; cp "$EVID/scripts/loadgen/main.go" "$EVID/scratch/s10/lg/main.go"; printf 'module loadgen\n\ngo 1.27.0\n' > "$EVID/scratch/s10/lg/go.mod"
(cd "$EVID/scratch/s10/lg" && go build -o "$EVID/scratch/s10/loadgen" .) || { echo LOADGEN_BUILD_FAILED; exit 1; }

cp "$EVID/scratch/s10/a/probe-go" "$EVID/scratch/s10/dock/probe-go"; cp "$EVID/scripts/go-probe/Dockerfile" "$EVID/scratch/s10/dock/Dockerfile"
docker build -q -t kprobe-go "$EVID/scratch/s10/dock" >/dev/null || { echo DOCKER_BUILD_FAILED; exit 1; }
echo "image_size_bytes=$(docker image inspect kprobe-go -f '{{.Size}}')"

run_case() { # name, extra docker args
  local name=$1; shift
  docker rm -f kprobe-go-run >/dev/null 2>&1
  local t0; t0=$(now_ms)
  docker run -d --name kprobe-go-run -p 127.0.0.1:18080:8080 "$@" kprobe-go >/dev/null
  local up; up=$(wait_http http://127.0.0.1:18080/ping)
  echo "--- case=$name args='$*' startup_ms_to_first_200=$up (includes docker run overhead)"
  sleep 5; echo "idle_5s:   $(rss kprobe-go-run)"
  echo "info: $(curl -s http://127.0.0.1:18080/info)"
  "$EVID/scratch/s10/loadgen" -url http://127.0.0.1:18080/orders -c 32 -d 15
  echo "after_load: $(rss kprobe-go-run)"
  sleep 15; echo "idle_15s_after_load: $(rss kprobe-go-run)"
  echo "info: $(curl -s http://127.0.0.1:18080/info)"
  docker rm -f kprobe-go-run >/dev/null
}
run_case 512m_2cpu --memory=512m --cpus=2
run_case 128m_1cpu --memory=128m --cpus=1
run_case 512m_2cpu_gomemlimit_100MiB --memory=512m --cpus=2 -e GOMEMLIMIT=100MiB
run_case unlimited
