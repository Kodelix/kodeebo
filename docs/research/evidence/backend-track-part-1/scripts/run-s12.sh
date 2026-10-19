#!/usr/bin/env bash
# S12: Ktor 3.6.0 probe in Docker on eclipse-temurin:21-jre: image size, startup, resident memory, JVM container behaviour.
# Also re-times Go startup INCLUDING container create/start, for a like-for-like startup figure (S10 excluded it).
# Command: bash scripts/run-s12.sh > s12-output.txt 2>&1   (from the evidence dir). Needs S10 and S11 to have run.
source "$(dirname "$0")/lib.sh"
echo "date=$(date -u +%FT%TZ) docker=$(docker --version) host_cpus=$(nproc)"
docker pull -q eclipse-temurin:21-jre >/dev/null || { echo PULL_FAILED; exit 1; }
echo "base_image=eclipse-temurin:21-jre digest=$(docker image inspect eclipse-temurin:21-jre -f '{{index .RepoDigests 0}}') size_bytes=$(docker image inspect eclipse-temurin:21-jre -f '{{.Size}}')"
docker run --rm eclipse-temurin:21-jre java -version 2>&1 | head -3
D=$EVID/scratch/s12; rm -rf "$D"; mkdir -p "$D"
cp -r "$EVID/scratch/s11/install/probe-ktor" "$D/app"
cat > "$D/Dockerfile" <<'EOF'
FROM eclipse-temurin:21-jre
COPY app /app
EXPOSE 8080
USER 65532:65532
ENTRYPOINT ["sh","-c","exec java $JAVA_OPTS -cp '/app/lib/*' MainKt"]
EOF
docker build -q -t kprobe-ktor "$D" >/dev/null || { echo BUILD_FAILED; exit 1; }
echo "ktor_image_size_bytes=$(docker image inspect kprobe-ktor -f '{{.Size}}') go_image_size_bytes=$(docker image inspect kprobe-go -f '{{.Size}}')"

run_case() { # image, name, extra docker args
  local img=$1 name=$2; shift 2
  docker rm -f kprobe-run >/dev/null 2>&1
  local t0; t0=$(now_ms)
  docker run -d --name kprobe-run -p 127.0.0.1:18080:8080 "$@" "$img" >/dev/null
  local up; up=$(wait_http http://127.0.0.1:18080/ping)
  echo "--- image=$img case=$name args='$*' wall_ms_from_before_docker_run_to_first_200=$(( $(now_ms) - t0 )) (poll loop ms=$up)"
  sleep 5; echo "idle_5s:   $(rss kprobe-run)"
  echo "info: $(curl -s http://127.0.0.1:18080/info)"
  "$EVID/scratch/s10/loadgen" -url http://127.0.0.1:18080/orders -c 32 -d 20
  echo "after_load: $(rss kprobe-run)"
  sleep 15; echo "idle_15s_after_load: $(rss kprobe-run)"
  echo "info: $(curl -s http://127.0.0.1:18080/info)"
  docker rm -f kprobe-run >/dev/null
}
run_case kprobe-go go_512m_2cpu --memory=512m --cpus=2
run_case kprobe-ktor ktor_1g_2cpu_defaults --memory=1g --cpus=2
run_case kprobe-ktor ktor_512m_2cpu_defaults --memory=512m --cpus=2
run_case kprobe-ktor ktor_256m_1cpu_defaults --memory=256m --cpus=1
run_case kprobe-ktor ktor_512m_2cpu_serialgc_xmx192m --memory=512m --cpus=2 -e "JAVA_OPTS=-XX:+UseSerialGC -Xmx192m -XX:MaxMetaspaceSize=96m -XX:ReservedCodeCacheSize=48m -Xss512k"
run_case kprobe-ktor ktor_unlimited_defaults
