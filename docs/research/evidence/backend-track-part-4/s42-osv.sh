#!/bin/sh
# s42-osv.sh - tier E: OSV (which aggregates GitHub Security Advisories) query per candidate library + version, plus a positive control.
# Run: sh docs/research/evidence/backend-track-part-4/s42-osv.sh > docs/research/evidence/backend-track-part-4/s42-osv.output.txt 2>&1
# Control: pgx 5.9.0 must return GHSA-j88v-2chj-qfwx (go/VERSION.md says it was fixed in 5.9.2). If the control fails, the run proves nothing.
q() { # ecosystem name version
  printf '%s %s %s\t' "$1" "$2" "$3"
  curl -fsS --max-time 25 -X POST https://api.osv.dev/v1/query \
    -d "{\"package\":{\"ecosystem\":\"$1\",\"name\":\"$2\"},\"version\":\"$3\"}" \
    | jq -r 'if .vulns then ([.vulns[] | .id + "(" + ((.modified // "")|.[0:10]) + ")"] | join(",")) else "none" end' || echo "QUERY-FAILED"
}
echo "# s42-osv $(date -u +%Y-%m-%dT%H:%M:%SZ)"
q Go github.com/jackc/pgx/v5 5.9.0   # CONTROL: expect a hit
q Go github.com/go-chi/chi/v5 5.5.0
q Go github.com/labstack/echo/v4 4.16.0
q Go github.com/labstack/echo/v5 5.4.0
q Go github.com/danielgtaylor/huma/v2 2.39.1
q Go github.com/oapi-codegen/oapi-codegen/v2 2.8.0
q Go github.com/ogen-go/ogen 1.24.0
q Go github.com/getkin/kin-openapi 0.151.0
q Go golang.org/x/crypto 0.58.0
q Go golang.org/x/text 0.43.0
q Go github.com/alexedwards/scs/v2 2.9.0
q Go github.com/pquerna/otp 1.5.0
q Go github.com/minio/minio-go/v7 7.4.1
q Go github.com/aws/aws-sdk-go-v2/service/s3 1.114.3
q Go firebase.google.com/go/v4 4.22.0
q Go github.com/wneessen/go-mail 0.8.1
q Go github.com/go-playground/validator/v10 10.30.5
q Go github.com/testcontainers/testcontainers-go 0.44.0
q Go github.com/signintech/gopdf 0.38.2
q Go github.com/johnfercher/maroto/v2 2.4.3
q Maven io.ktor:ktor-server-core 3.6.0
q Maven io.ktor:ktor-server-netty 3.6.0
q Maven org.bouncycastle:bcprov-jdk18on 1.86
q Maven de.mkammerer:argon2-jvm 2.12
q Maven com.password4j:password4j 1.8.4
q Maven software.amazon.awssdk:s3 2.56.0
q Maven io.minio:minio 9.0.3
q Maven com.google.firebase:firebase-admin 9.11.0
q Maven nl.martijndwars:web-push 5.1.2
q Maven org.simplejavamail:simple-java-mail 9.3.6
q Maven com.ibm.icu:icu4j 78.3
q Maven org.testcontainers:testcontainers 2.0.5
q Maven org.apache.pdfbox:pdfbox 3.0.8
q Maven com.github.librepdf:openpdf 3.0.5
q Maven com.itextpdf:itext-core 9.8.0
q Maven org.openapitools:openapi-generator 7.26.0
echo "## proxy retry for webpush-go with Go proxy case-encoding (upper-case letters escaped as !lower); first run used the raw path and got 404 = wrong test, see s40-versions.output.txt"
curl -fsS --max-time 20 "https://proxy.golang.org/github.com/!sher!clock!holmes/webpush-go/@latest" | tr -d '\n' | cut -c1-160; echo
