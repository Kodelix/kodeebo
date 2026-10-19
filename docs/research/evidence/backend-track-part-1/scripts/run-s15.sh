#!/usr/bin/env bash
# S15: Ktor probe startup / memory / image-size variants: (1) AppCDS auto-archive, (2) jlink runtime on ubuntu:24.04.
# S16 (appended): re-build both distZip archives with -Prepro and diff their entries (S11 left this unexplained).
# Command: bash scripts/run-s15.sh > s15-output.txt 2>&1   (from the evidence dir). Needs S11, S12 to have run.
source "$(dirname "$0")/lib.sh"
D=$EVID/scratch/s15; rm -rf "$D"; mkdir -p "$D/cds" "$D/jl"
echo "date=$(date -u +%FT%TZ)"
docker run --rm eclipse-temurin:21-jre sh -c '. /etc/os-release; echo "temurin-jre base: $PRETTY_NAME"'

echo "=== (1) AppCDS: -XX:+AutoCreateSharedArchive -XX:SharedArchiveFile on a bind-mounted dir; first run creates, later runs use ==="
chmod 777 "$D/cds"
ONE() { # label, extra args
  docker rm -f kprobe-run >/dev/null 2>&1
  local t0; t0=$(now_ms)
  docker run -d --name kprobe-run -p 127.0.0.1:18080:8080 --memory=512m --cpus=2 -v "$D/cds:/cds" "$@" kprobe-ktor >/dev/null
  wait_http http://127.0.0.1:18080/ping >/dev/null
  echo "$1 wall_ms_to_first_200=$(( $(now_ms) - t0 )) $(sleep 3; rss kprobe-run)"
  docker stop -t 10 kprobe-run >/dev/null; docker rm -f kprobe-run >/dev/null
}
OPTS="-XX:+AutoCreateSharedArchive -XX:SharedArchiveFile=/cds/app.jsa"
ONE "cds_run1_creates_archive" -e "JAVA_OPTS=$OPTS"
ls -la "$D/cds" | tail -2
ONE "cds_run2_uses_archive" -e "JAVA_OPTS=$OPTS"
ONE "cds_run3_uses_archive" -e "JAVA_OPTS=$OPTS"
ONE "no_cds_baseline"
ONE "no_cds_baseline_again"

echo "=== (2) jlink runtime image on ubuntu:24.04 (modules from jdeps) ==="
cp -r "$EVID/scratch/s11/install/probe-ktor" "$D/jl/app"
cat > "$D/jl/Dockerfile" <<'EOF'
FROM eclipse-temurin:21-jdk AS jlink
COPY app /app
RUN MODS=$(jdeps --print-module-deps --ignore-missing-deps --multi-release 21 --class-path '/app/lib/*' /app/lib/probe-ktor.jar) \
 && echo "jdeps modules: $MODS" \
 && jlink --add-modules "$MODS,jdk.unsupported,java.management,jdk.management" --strip-debug --no-man-pages --no-header-files --compress zip-6 --output /jre
FROM ubuntu:24.04
COPY --from=jlink /jre /jre
COPY app /app
EXPOSE 8080
USER 65532:65532
ENTRYPOINT ["sh","-c","exec /jre/bin/java $JAVA_OPTS -cp '/app/lib/*' MainKt"]
EOF
docker build --progress=plain -t kprobe-ktor-jlink "$D/jl" 2>&1 | grep -E "jdeps modules|ERROR|error" | head -5
echo "jlink_image_size_bytes=$(docker image inspect kprobe-ktor-jlink -f '{{.Size}}') temurin_jre_image_size_bytes=$(docker image inspect kprobe-ktor -f '{{.Size}}') ubuntu_2404_bytes=$(docker image inspect ubuntu:24.04 -f '{{.Size}}')"
docker rm -f kprobe-run >/dev/null 2>&1
t0=$(now_ms); docker run -d --name kprobe-run -p 127.0.0.1:18080:8080 --memory=512m --cpus=2 kprobe-ktor-jlink >/dev/null
wait_http http://127.0.0.1:18080/ping >/dev/null; echo "jlink wall_ms_to_first_200=$(( $(now_ms) - t0 )) $(sleep 5; rss kprobe-run)"
docker rm -f kprobe-run >/dev/null

echo "=== S16: distZip reproducibility with -Prepro, both dirs, keep both zips ==="
GRADLE=$EVID/downloads/gradle-9.7.0-dist/gradle-9.7.0/bin/gradle
export GRADLE_USER_HOME=$EVID/scratch/gradle-home JAVA_TOOL_OPTIONS="-Djava.io.tmpdir=$EVID/tmp"
mkdir -p "$D/z"
for d in a b; do
  (cd "$EVID/scratch/s11/$d" && "$GRADLE" --no-daemon --offline -q -Prepro clean distZip 2>/dev/null)
  cp "$EVID/scratch/s11/$d/build/distributions/probe-ktor.zip" "$D/z/$d.zip"
  echo "zip_$d sha256=$(sha256sum "$D/z/$d.zip" | cut -c1-16) bytes=$(stat -c %s "$D/z/$d.zip")"
done
mkdir -p "$D/z/xa" "$D/z/xb"; unzip -q -o "$D/z/a.zip" -d "$D/z/xa"; unzip -q -o "$D/z/b.zip" -d "$D/z/xb"
echo "extracted content diff (files whose bytes differ):"; diff -rq "$D/z/xa" "$D/z/xb" | head
echo "entry list diff:"; diff <(zipinfo -1 "$D/z/a.zip") <(zipinfo -1 "$D/z/b.zip") | head -5
echo "entry timestamps (a / b, first 3):"; zipinfo -T "$D/z/a.zip" | sed -n 3,5p; zipinfo -T "$D/z/b.zip" | sed -n 3,5p
echo done
