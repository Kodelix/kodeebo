#!/bin/sh
# s41-repo-meta.sh - tier E: licence (SPDX), archived flag and last push of candidate library repositories (GitHub API, read-only).
# Run: sh docs/research/evidence/backend-track-part-4/s41-repo-meta.sh > docs/research/evidence/backend-track-part-4/s41-repo-meta.output.txt 2>&1
echo "# s41-repo-meta $(date -u +%Y-%m-%dT%H:%M:%SZ)"
for r in go-chi/chi labstack/echo danielgtaylor/huma oapi-codegen/oapi-codegen ogen-go/ogen getkin/kin-openapi \
  nicksnyder/go-i18n alexedwards/scs pquerna/otp minio/minio-go aws/aws-sdk-go-v2 firebase/firebase-admin-go SherClockHolmes/webpush-go \
  wneessen/go-mail go-playground/validator testcontainers/testcontainers-go signintech/gopdf johnfercher/maroto phpdave11/gofpdf \
  fe3dback/go-arch-lint arch-go/arch-go alexedwards/argon2id matthewhartstonge/argon2 \
  bcgit/bc-java phxql/argon2-jvm Password4j/password4j samdjstevens/java-totp eatthepath/java-otp \
  minio/minio-java firebase/firebase-admin-java web-push-libs/webpush-java simple-java-mail/simple-java-mail unicode-org/icu \
  testcontainers/testcontainers-java konform-kt/konform LemonAppDev/konsist TNG/ArchUnit LibrePDF/OpenPDF apache/pdfbox itext/itext-java \
  awslabs/aws-sdk-kotlin OpenAPITools/openapi-generator ktorio/ktor; do
  printf '%s\t' "$r"
  gh api "repos/$r" --jq '[.license.spdx_id, ("archived=" + (.archived|tostring)), ("pushed=" + .pushed_at), ("stars=" + (.stargazers_count|tostring))] | join(" ")' 2>&1 | head -1
done
