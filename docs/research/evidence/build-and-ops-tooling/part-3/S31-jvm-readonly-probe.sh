#!/usr/bin/env bash
# S31: what does a JVM (eclipse-temurin:21-jre) need writable when the root FS is read-only,
# all capabilities are dropped and no-new-privileges is set, as a non-root user.
# Local, already-present image only (--pull=never), --network none. No secrets.
set -u
IMG=eclipse-temurin:21-jre
HARD="--pull=never --network none --read-only --cap-drop ALL --security-opt no-new-privileges --user 10001:10001 --pids-limit 200 --memory 256m"
echo "== versions"; docker --version
echo "== java version (hardened, read-only, NO tmpfs)"
docker run --rm $HARD $IMG java -version 2>&1
echo "== java -Xlog warnings, read-only, NO tmpfs"
docker run --rm $HARD $IMG java -Xlog:all=warning -XX:+UsePerfData -version 2>&1 | head -20
echo "== container-aware memory settings under --memory 256m"
docker run --rm $HARD $IMG java -XshowSettings:system -XX:+PrintFlagsFinal -version 2>&1 | grep -E "Memory Limit|CPU Count|MaxHeapSize|UseContainerSupport" | head
echo "== default CDS archive present in the image (read, not written)?"
docker run --rm $HARD $IMG sh -c 'ls -l $JAVA_HOME/lib/server/ 2>&1 | head; java -Xshare:on -version 2>&1 | head -3'
echo "== JFR to /tmp WITHOUT tmpfs (expect failure on read-only root)"
docker run --rm $HARD $IMG java -XX:StartFlightRecording=filename=/tmp/s31.jfr,duration=1s -version 2>&1 | head -8
echo "== JFR to /tmp WITH tmpfs"
docker run --rm $HARD --tmpfs /tmp:rw,noexec,nosuid,nodev,size=64m $IMG java -XX:StartFlightRecording=filename=/tmp/s31.jfr,duration=1s -version 2>&1 | head -8
echo "== long-running JVM (jwebserver) NOT read-only: which files does it write? (docker diff)"
docker rm -f s31-rw >/dev/null 2>&1
docker run -d --name s31-rw --pull=never --network none --cap-drop ALL --security-opt no-new-privileges --user 10001:10001 $IMG jwebserver -b 127.0.0.1 -p 8080 -d /tmp 2>&1
sleep 4
docker ps --filter name=s31-rw --format '{{.Names}} {{.Status}}'
docker logs s31-rw 2>&1 | head -5
echo "-- docker diff (paths changed in the writable layer)"
docker diff s31-rw 2>&1 | head -30
docker rm -f s31-rw >/dev/null 2>&1
echo "== long-running JVM read-only with tmpfs /tmp only"
docker rm -f s31-ro >/dev/null 2>&1
docker run -d --name s31-ro $HARD --tmpfs /tmp:rw,noexec,nosuid,nodev,size=64m $IMG jwebserver -b 127.0.0.1 -p 8080 -d /tmp 2>&1
sleep 4
docker ps --filter name=s31-ro --format '{{.Names}} {{.Status}}'
docker logs s31-ro 2>&1 | head -5
docker inspect --format 'ReadonlyRootfs={{.HostConfig.ReadonlyRootfs}} CapDrop={{.HostConfig.CapDrop}} SecurityOpt={{.HostConfig.SecurityOpt}} User={{.Config.User}} Mem={{.HostConfig.Memory}} Pids={{.HostConfig.PidsLimit}}' s31-ro
docker rm -f s31-ro >/dev/null 2>&1
