#!/bin/bash
# S51 step 2: export the two local images with docker save into the cache dir (never into evidence).
# Usage: s51-02-docker-save.sh <cache_dir>
set -u
P="$1"; mkdir -p "$P/images"
echo "date_utc: $(date -u +%FT%TZ)"
docker version --format 'client {{.Client.Version}} server {{.Server.Version}}'
docker image ls --digests --format '{{.Repository}}:{{.Tag}} id={{.ID}} size={{.Size}} digest={{.Digest}}' | grep -E 'eclipse-temurin|kprobe-ktor'
for i in eclipse-temurin:21-jre kprobe-ktor:latest; do
  echo "--- $i"
  docker image inspect "$i" --format 'id={{.Id}} os={{.Os}}/{{.Architecture}} size={{.Size}} created={{.Created}} repodigests={{.RepoDigests}}'
done
docker save -o "$P/images/eclipse-temurin-21-jre.tar" eclipse-temurin:21-jre
docker save -o "$P/images/kprobe-ktor-latest.tar" kprobe-ktor:latest
ls -l "$P/images"; sha256sum "$P/images/"*.tar
