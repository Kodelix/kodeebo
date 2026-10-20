#!/usr/bin/env bash
# SCRATCH / evidence (part 4, S40): copy part-2 spike sources+build files (not .gradle/.kotlin/build), rename packages to the net.kodelix root.
# Mapping: kodeebo.notifications|identity -> net.kodelix.core.<m> (Layer 1); kodeebo.orders|gaming -> net.kodelix.kodeebo.<m> (Layer 2/3).
set -eu
SRC=docs/research/evidence/module-structure-and-core-boundary/part-2/spike
DST=docs/research/evidence/module-structure-and-core-boundary/part-4/spike
rsync -a --exclude .gradle --exclude .kotlin --exclude build "$SRC"/ "$DST"/
cd "$DST"
for m in notifications identity; do
  mkdir -p $m/src/main/kotlin/net/kodelix/core
  mv $m/src/main/kotlin/kodeebo/$m $m/src/main/kotlin/net/kodelix/core/$m
done
for m in orders gaming; do
  mkdir -p $m/src/main/kotlin/net/kodelix/kodeebo
  mv $m/src/main/kotlin/kodeebo/$m $m/src/main/kotlin/net/kodelix/kodeebo/$m
done
find . -type d -empty -delete
# rewrite package/import text (sources and test rules)
find . -name '*.kt' -print0 | xargs -0 sed -i -E \
  -e 's/\bkodeebo\.(notifications|identity)\b/net.kodelix.core.\1/g' \
  -e 's/\bkodeebo\.(orders|gaming)\b/net.kodelix.kodeebo.\1/g'
grep -rn "kodeebo\." --include=*.kt . | grep -v "net.kodelix" || true
