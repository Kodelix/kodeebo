#!/bin/sh
# S10 (tier E + tier 3 data): versions, licence, release dates and advisories for the JVM mail libraries.
# Run from the repo root. Network reads only; no credentials; no downloads of jars. Output: raw/ + s10-output.txt
D=docs/research/evidence/notifications-provider/part-1
R=$D/raw
c() { curl -sS --max-time 40 -A "kodeebo-researcher" "$@"; }
echo "date: $(date -u +%FT%TZ)"
c "https://api.github.com/repos/eclipse-ee4j/angus-mail/releases?per_page=6" -o $R/angus-releases.json
grep -E '"(tag_name|published_at)"' $R/angus-releases.json
c "https://api.github.com/repos/eclipse-ee4j/angus-mail/license" -o $R/angus-license.json
grep -E '"(spdx_id|name)"' $R/angus-license.json | head -4
c "https://repo1.maven.org/maven2/org/eclipse/angus/angus-mail/2.0.5/angus-mail-2.0.5.pom" -o $R/angus-mail-2.0.5.pom
grep -n -i -E "<license>|<name>|<url>|<artifactId>|<version>" $R/angus-mail-2.0.5.pom | head -40
c "https://repo1.maven.org/maven2/org/eclipse/angus/angus-mail/2.0.5/" -o $R/angus-2.0.5-dir.html
grep -E "pom|jar" $R/angus-2.0.5-dir.html | head -6
c "https://repo1.maven.org/maven2/org/simplejavamail/simple-java-mail/maven-metadata.xml" -o $R/sjm-metadata.xml
grep -E "<latest>|<release>|<lastUpdated>" $R/sjm-metadata.xml
c "https://api.github.com/repos/bbottema/simple-java-mail/releases?per_page=3" -o $R/sjm-releases.json
grep -E '"(tag_name|published_at)"' $R/sjm-releases.json
c "https://api.github.com/repos/bbottema/simple-java-mail/license" -o $R/sjm-license.json
grep -E '"(spdx_id)"' $R/sjm-license.json
echo "--- OSV querybatch"
cat > $R/osv-query.json <<'EOQ'
{"queries":[
{"package":{"ecosystem":"Maven","name":"org.eclipse.angus:angus-mail"},"version":"2.0.5"},
{"package":{"ecosystem":"Maven","name":"org.eclipse.angus:angus-mail"},"version":"2.0.3"},
{"package":{"ecosystem":"Maven","name":"org.eclipse.angus:angus-activation"},"version":"2.0.3"},
{"package":{"ecosystem":"Maven","name":"jakarta.mail:jakarta.mail-api"},"version":"2.1.5"},
{"package":{"ecosystem":"Maven","name":"org.simplejavamail:simple-java-mail"}}
]}
EOQ
c -X POST -H 'Content-Type: application/json' -d @$R/osv-query.json https://api.osv.dev/v1/querybatch -o $R/osv-result.json
cat $R/osv-result.json | head -c 3000; echo
echo "--- GitHub global advisories"
c "https://api.github.com/advisories?ecosystem=maven&affects=org.eclipse.angus:angus-mail&per_page=10" -o $R/ghsa-angus.json
grep -E '"(ghsa_id|cve_id|summary|severity|published_at)"' $R/ghsa-angus.json | head -30
