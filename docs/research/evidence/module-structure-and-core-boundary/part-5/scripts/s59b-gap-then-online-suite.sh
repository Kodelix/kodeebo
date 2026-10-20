#!/usr/bin/env bash
# S59b step 2 (tier E, part 5). The offline-first suite run failed on 9.8.2: "Could not download kotlin-stdlib-2.4.10.jar ... offline" (s59b-suite-driver.output.txt).
# (1) print the buildscript dependency tree (metadata only, offline) so the cause is on record; (2) list every jar of that tree missing from home-b with its size (HEAD only);
# (3) abort if already-downloaded 256,245,292 B + gap > 280,000,000; (4) otherwise run the SAME suite driver with network (OFF flag removed) and report home-b growth.
set -u
REPO=/home/kiko/saas-products/kodeebo; cd $REPO
C=production/session-state/cache/module-structure-and-core-boundary/part-5; H=$C/home-b/caches/modules-2/files-2.1
E=docs/research/evidence/module-structure-and-core-boundary/part-5; P4=$E/probes/part-4
echo "date: $(date -u +%FT%TZ)"
export GRADLE_USER_HOME=$PWD/$C/home-b
$C/gradle-dist/gradle-9.8.2/bin/gradle -p $P4/spike --offline --no-daemon --project-cache-dir $PWD/$C/project-cache-tree -Pmode=clean buildEnvironment > $E/s59b-buildEnvironment-offline.output.txt 2>&1
echo "buildEnvironment exit=$?"; grep -n -E "kotlin-stdlib|FAILED|What went wrong|Could not" $E/s59b-buildEnvironment-offline.output.txt | head -20 | cut -c1-220
python3 -I - $E/s59b-buildEnvironment-offline.output.txt $H > $E/s59b-gap-list.txt <<'PY'
import re,sys,glob,subprocess
txt=open(sys.argv[1]).read(); H=sys.argv[2]
seen={}
for m in re.finditer(r'([A-Za-z0-9_.\-]+):([A-Za-z0-9_.\-]+):([A-Za-z0-9_.\-]+)(?: -> ([A-Za-z0-9_.\-]+))?',txt):
    g,a,v,v2=m.groups(); seen[(g,a,v2 or v)]=1
tot=0; unk=0
for (g,a,v) in sorted(seen):
    if not re.match(r'^\d',v): continue
    d=f"{H}/{g}/{a}/{v}"
    if glob.glob(d+"/*/"+a+"-"+v+"*.jar"): continue
    size=None
    for suf in ("","-gradle813","-gradle96","-gradle88"):
        for base in ("https://repo.maven.apache.org/maven2/","https://plugins.gradle.org/m2/"):
            url=f"{base}{g.replace('.','/')}/{a}/{v}/{a}-{v}{suf}.jar"
            r=subprocess.run(["curl","-sIL","-m","20",url],capture_output=True,text=True).stdout
            code=[l for l in r.splitlines() if l.startswith("HTTP")]; cl=[l.split()[1] for l in r.splitlines() if l.lower().startswith("content-length:")]
            if code and code[-1].split()[1]=="200" and cl: size=int(cl[-1].strip()); break
        if size: break
    if size is None: unk+=1; print("UNKNOWN-SIZE",g,a,v)
    else: tot+=size; print(size,g,a,v)
print("TOTAL_GAP_BYTES",tot,"UNKNOWN",unk)
PY
cat $E/s59b-gap-list.txt | cut -c1-200
gap=$(grep TOTAL_GAP_BYTES $E/s59b-gap-list.txt | awk '{print $2}'); unk=$(grep TOTAL_GAP_BYTES $E/s59b-gap-list.txt | awk '{print $4}')
echo "downloaded so far 256245292 + gap $gap (unknown-size items: $unk); cap 280000000"
if [ -z "$gap" ] || [ "$unk" != "0" ] || [ $((256245292+gap)) -gt 280000000 ]; then echo "ABORT: needs approval or unknown sizes"; exit 3; fi
before=$(du -sb $C/home-b/caches/modules-2 | cut -f1)
sed 's/^OFF=--offline;/OFF="";/' $E/scripts/s59b-suite.sh > $E/scripts/s59b-suite-ONLINE.sh
mv $P4/run-log.txt $P4/run-log.offline-first-attempt.txt
bash $E/scripts/s59b-suite-ONLINE.sh > $E/s59b-suite-online-driver.output.txt 2>&1
echo "modules-2 growth in home-b: $((`du -sb $C/home-b/caches/modules-2 | cut -f1` - before)) bytes"
cat $P4/run-log.txt | cut -c1-230
