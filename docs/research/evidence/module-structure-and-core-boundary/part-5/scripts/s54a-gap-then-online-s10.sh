#!/usr/bin/env bash
# S54a step 2 (tier E, part 5): after the offline-first S10 run failed for the missing plugin kotlin-dsl 6.7.6 (s54a-run1-offline-first.output.txt):
# (1) read the Kotlin version that gradle-kotlin-dsl-plugins 6.7.6 depends on; (2) list every artifact missing from home-a with its size (HEAD only);
# (3) abort if 151,620,138 (distribution, already downloaded) + gap > 280,000,000; (4) otherwise run the SAME S10 script once with network (no --offline) to fill home-a.
set -u
REPO=/home/kiko/saas-products/kodeebo
C=$REPO/production/session-state/cache/module-structure-and-core-boundary; D=$C/part-5; H=$D/home-a/caches/modules-2/files-2.1
E=$REPO/docs/research/evidence/module-structure-and-core-boundary/part-5
echo "date: $(date -u +%FT%TZ)"
B=https://plugins.gradle.org/m2/org/gradle/kotlin/gradle-kotlin-dsl-plugins/6.7.6/gradle-kotlin-dsl-plugins-6.7.6
curl -sL -m 30 -w '\n[http %{http_code}]\n' $B.pom | grep -E -A1 'kotlin-gradle-plugin<|kotlin-stdlib<|\[http' | head -12
V=$(curl -sL -m 30 $B.pom | grep -A1 '<artifactId>kotlin-gradle-plugin</artifactId>' | grep -o '<version>[^<]*' | head -1 | sed 's/<version>//'); echo "kotlin-dsl-plugins 6.7.6 -> KGP version: $V"
[ -z "$V" ] && { echo "ABORT: version not found"; exit 4; }
gap=0; n=0
echo "## missing from home-a (HEAD sizes)"
for f in "" ; do :; done
list=$(find $C/part-1/home/caches/modules-2/files-2.1 -type f -path '*/2.4.0/*' \( -name '*.jar' -o -name '*.module' -o -name '*.pom' \))
while IFS= read -r f; do
  rel=${f#$C/part-1/home/caches/modules-2/files-2.1/}; grp=$(echo "$rel" | cut -d/ -f1); art=$(echo "$rel" | cut -d/ -f2); name=$(basename "$f"); new=${name//2.4.0/$V}
  ls $H/$grp/$art/$V/*/"$new" >/dev/null 2>&1 && continue
  url=https://repo.maven.apache.org/maven2/$(echo $grp | tr . /)/$art/$V/$new
  r=$(curl -sIL "$url" | awk 'tolower($1)=="content-length:" {l=$2} /^HTTP/ {c=$2} END {gsub("\r","",l); print c" "l}'); echo "$r $new"
  [ "${r%% *}" = 200 ] && { gap=$((gap+${r##* })); n=$((n+1)); }
done <<< "$list"
for u in $B.pom $B.jar $B.module https://plugins.gradle.org/m2/org/gradle/kotlin/kotlin-dsl/org.gradle.kotlin.kotlin-dsl.gradle.plugin/6.7.6/org.gradle.kotlin.kotlin-dsl.gradle.plugin-6.7.6.pom; do
  r=$(curl -sIL "$u" | awk 'tolower($1)=="content-length:" {l=$2} /^HTTP/ {c=$2} END {gsub("\r","",l); print c" "l}'); echo "$r $(basename $u)"; [ "${r%% *}" = 200 ] && gap=$((gap+${r##* })); done
echo "gap files (kotlin $V): $n, gap bytes incl. plugin files: $gap; distribution 151620138; total $((gap+151620138)); cap 280000000"
[ $((gap+151620138)) -gt 280000000 ] && { echo "ABORT: needs approval"; exit 3; }
echo "## home-a size before: $(du -sb $D/home-a | cut -f1)"
sed 's/--offline //' $E/scripts/run-s10-gradle982.sh > $E/scripts/run-s10-gradle982-ONLINE-fill.sh
bash $E/scripts/run-s10-gradle982-ONLINE-fill.sh > $E/s54a-run2-online-fill.output.txt 2>&1
echo "## home-a size after: $(du -sb $D/home-a | cut -f1)"
