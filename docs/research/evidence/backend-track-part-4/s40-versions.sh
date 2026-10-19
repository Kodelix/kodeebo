#!/bin/sh
# s40-versions.sh - tier E: latest published version + date of candidate libraries (read-only HTTP GETs, no secrets).
# Run: sh docs/research/evidence/backend-track-part-4/s40-versions.sh > docs/research/evidence/backend-track-part-4/s40-versions.output.txt 2>&1
# Sources: proxy.golang.org (@latest JSON), repo1.maven.org maven-metadata.xml, registry.npmjs.org.
echo "# s40-versions $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "## Go modules (proxy.golang.org @latest: Version, Time)"
for m in github.com/go-chi/chi/v5 github.com/labstack/echo/v4 github.com/labstack/echo/v5 github.com/danielgtaylor/huma/v2 \
  github.com/oapi-codegen/oapi-codegen/v2 github.com/ogen-go/ogen github.com/getkin/kin-openapi \
  golang.org/x/crypto golang.org/x/text github.com/nicksnyder/go-i18n/v2 \
  github.com/alexedwards/scs/v2 github.com/pquerna/otp \
  github.com/aws/aws-sdk-go-v2/service/s3 github.com/minio/minio-go/v7 \
  firebase.google.com/go/v4 github.com/SherClockHolmes/webpush-go github.com/wneessen/go-mail \
  github.com/go-playground/validator/v10 github.com/testcontainers/testcontainers-go \
  github.com/signintech/gopdf github.com/johnfercher/maroto/v2 github.com/phpdave11/gofpdf github.com/jung-kurt/gofpdf \
  github.com/fe3dback/go-arch-lint github.com/arch-go/arch-go github.com/matthewhartstonge/argon2 github.com/alexedwards/argon2id; do
  printf '%s\t' "$m"
  curl -fsS --max-time 20 "https://proxy.golang.org/$m/@latest" | tr -d '\n' || echo "FETCH-FAILED"
  echo
done
echo "## Maven Central (maven-metadata.xml: latest/release/lastUpdated)"
for ga in io.ktor/ktor-server-core io.ktor/ktor-server-sessions io.ktor/ktor-server-auth io.ktor/ktor-server-status-pages \
  io.ktor/ktor-server-request-validation io.ktor/ktor-server-openapi io.ktor/ktor-server-routing-openapi \
  org.openapitools/openapi-generator org.bouncycastle/bcprov-jdk18on de.mkammerer/argon2-jvm com.password4j/password4j \
  org.springframework.security/spring-security-crypto dev.samstevens.totp/totp com.eatthepath/java-otp \
  software.amazon.awssdk/s3 aws.sdk.kotlin/s3 io.minio/minio com.google.firebase/firebase-admin nl.martijndwars/web-push \
  org.simplejavamail/simple-java-mail org.eclipse.angus/angus-mail com.ibm.icu/icu4j org.testcontainers/testcontainers \
  org.testcontainers/postgresql io.konform/konform-jvm org.hibernate.validator/hibernate-validator \
  com.github.librepdf/openpdf org.apache.pdfbox/pdfbox com.itextpdf/itext-core com.lemonappdev/konsist com.tngtech.archunit/archunit \
  com.github.ajalt.clikt/clikt io.insert-koin/koin-core org.jetbrains.kotlinx/kotlinx-datetime org.jetbrains.kotlinx/kotlinx-serialization-json; do
  g=$(echo "$ga" | cut -d/ -f1 | tr . /); a=$(echo "$ga" | cut -d/ -f2)
  printf '%s\t' "$ga"
  curl -fsS --max-time 20 "https://repo1.maven.org/maven2/$g/$a/maven-metadata.xml" | tr -d '\n ' | sed -e 's/.*<latest>\([^<]*\)<\/latest>.*<release>\([^<]*\)<\/release>.*<lastUpdated>\([^<]*\)<\/lastUpdated>.*/latest=\1 release=\2 lastUpdated=\3/' -e 's/^<?xml.*<release>\([^<]*\)<\/release>.*<lastUpdated>\([^<]*\)<\/lastUpdated>.*/release=\1 lastUpdated=\2/' | cut -c1-200 || echo "FETCH-FAILED"
  echo
done
echo "## npm (dist-tags.latest)"
for p in openapi-typescript openapi-fetch @hey-api/openapi-ts electron; do
  printf '%s\t' "$p"; curl -fsS --max-time 20 "https://registry.npmjs.org/$p" | jq -r '."dist-tags".latest + " " + (.time[."dist-tags".latest])' || echo "FETCH-FAILED"
done
