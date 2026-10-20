#!/usr/bin/env bash
# S52 (tier E, part 5): (1) list what Gradle 9.8.1's embedded Kotlin 2.4.10 (F508) would still need from the network, with sizes (HEAD only);
# (2) abort if distribution + gap > 250 MB; (3) otherwise download the 9.8.1 distribution, verify SHA-256, unpack; (4) make the part-5 Gradle user home as a COPY of part 2's home.
set -u
REPO=/home/kiko/saas-products/kodeebo
C=$REPO/production/session-state/cache/module-structure-and-core-boundary
P1=$C/part-1/home/caches/modules-2/files-2.1; P2=$C/part-2/home/caches/modules-2/files-2.1
D=$C/part-5; mkdir -p $D/dist
echo "date: $(date -u +%FT%TZ)"
echo "## (1) 2.4.10 counterparts of the 104 MB 2.4.0 set that kotlin-dsl fetched at Gradle 9.7.0 and are NOT in part 2's home"
gap=0; n=0
while IFS= read -r f; do
  rel=${f#$P1/}; grp=$(echo "$rel" | cut -d/ -f1); art=$(echo "$rel" | cut -d/ -f2); name=$(basename "$f"); new=${name//2.4.0/2.4.10}
  if ls $P2/$grp/$art/2.4.10/*/"$new" >/dev/null 2>&1; then continue; fi
  url=https://repo.maven.apache.org/maven2/$(echo $grp | tr . /)/$art/2.4.10/$new
  len=$(curl -sIL "$url" | awk 'tolower($1)=="content-length:" {l=$2} /^HTTP/ {c=$2} END {gsub("\r","",l); print c" "l}')
  echo "$len $new"; code=${len%% *}; sz=${len##* }
  if [ "$code" = 200 ]; then gap=$((gap+sz)); n=$((n+1)); fi
done < <(find $P1 -type f -path '*/2.4.0/*' \( -name '*.jar' -o -name '*.module' -o -name '*.pom' \))
dist=151620101
echo "gap files: $n, gap bytes: $gap; distribution bytes: $dist; total: $((gap+dist)); cap: 250000000"
if [ $((gap+dist)) -gt 250000000 ]; then echo "ABORT: over cap, needs approval"; exit 3; fi
echo "## (3) download distribution"
cd $D/dist && curl -sL -o gradle-9.8.1-bin.zip https://services.gradle.org/distributions/gradle-9.8.1-bin.zip
ls -l gradle-9.8.1-bin.zip
echo "published: dce76f55f8e251a3a1f130eb120f30b3d271de2b76c9b0729d316b5a1b6dc01f"; echo "actual:    $(sha256sum gradle-9.8.1-bin.zip | cut -d' ' -f1)"
echo "dce76f55f8e251a3a1f130eb120f30b3d271de2b76c9b0729d316b5a1b6dc01f  gradle-9.8.1-bin.zip" | sha256sum -c -
mkdir -p $D/gradle-dist && unzip -q gradle-9.8.1-bin.zip -d $D/gradle-dist && ls $D/gradle-dist
echo "## (4) part-5 user home = copy of part 2's home"
[ -d $D/home ] || cp -r --reflink=auto $C/part-2/home $D/home
rm -rf $D/home/daemon; du -sh $D/home $D/dist $D/gradle-dist
ls $D/gradle-dist/gradle-9.8.1/lib/plugins | grep -i "kotlin-dsl\|kotlin-compiler\|kotlin-stdlib" | head; ls $D/gradle-dist/gradle-9.8.1/lib | grep -i kotlin | head
