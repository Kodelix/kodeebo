#!/usr/bin/env bash
# S20 (tier E): Maven Central latest versions + pom dates, OSV advisories per exact version, GitHub repo metadata.
# Unauthenticated, read-only, small responses. No credential in this script.
set -u
M=https://repo1.maven.org/maven2
echo "date: $(date -u +%F) ; curl $(curl --version | head -1)"
for ga in nl.martijndwars:web-push com.google.firebase:firebase-admin com.google.auth:google-auth-library-oauth2-http org.bouncycastle:bcprov-jdk18on org.bouncycastle:bcpkix-jdk18on; do
  g=${ga%%:*}; a=${ga##*:}; gp=${g//.//}
  meta=$(curl -s "$M/$gp/$a/maven-metadata.xml")
  rel=$(printf '%s' "$meta" | sed -n 's:.*<release>\(.*\)</release>.*:\1:p' | head -1)
  echo "== $ga release=$rel"
  echo -n "pom Last-Modified: "; curl -sI "$M/$gp/$a/$rel/$a-$rel.pom" | grep -i '^last-modified' | tr -d '\r'
  echo -n "OSV vulns for exact version: "
  curl -s -X POST https://api.osv.dev/v1/query -d "{\"package\":{\"name\":\"$g:$a\",\"ecosystem\":\"Maven\"},\"version\":\"$rel\"}" | sed -n 's:.*"id": *"\([^"]*\)".*:\1:p' | sort -u | tr '\n' ' '; echo
  echo -n "OSV vulns, package any version (ids): "
  curl -s -X POST https://api.osv.dev/v1/query -d "{\"package\":{\"name\":\"$g:$a\",\"ecosystem\":\"Maven\"}}" | sed -n 's:.*"id": *"\([^"]*\)".*:\1:p' | sort -u | tr '\n' ' '; echo
done
echo "== control: log4j-core 2.14.1"
curl -s -X POST https://api.osv.dev/v1/query -d '{"package":{"name":"org.apache.logging.log4j:log4j-core","ecosystem":"Maven"},"version":"2.14.1"}' | sed -n 's:.*"id": *"\([^"]*\)".*:\1:p' | sort -u | wc -l
for r in web-push-libs/webpush-java firebase/firebase-admin-java; do
  echo "== GitHub $r"
  curl -s "https://api.github.com/repos/$r" | grep -E '"(archived|pushed_at|license|spdx_id|open_issues_count|default_branch)"' | head -8
  echo "-- latest release:"; curl -s "https://api.github.com/repos/$r/releases/latest" | grep -E '"(tag_name|published_at)"' | head -3
done
echo "== webpush-java source tree (encoding support)"
curl -s "https://api.github.com/repos/web-push-libs/webpush-java/contents/src/main/java/nl/martijndwars/webpush" | grep '"name"'
curl -s "https://raw.githubusercontent.com/web-push-libs/webpush-java/master/src/main/java/nl/martijndwars/webpush/Encoding.java" | head -30
