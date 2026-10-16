#!/usr/bin/env bash
# Tier-E probe: latest dist-tag, its publish time, licence and deprecation flag from the public npm registry.
for p in "$@"; do
  enc=${p/\//%2F}
  curl -s -m 20 "https://registry.npmjs.org/$enc" | jq -r --arg p "$p" '(.["dist-tags"].latest) as $v | "\($p) latest=\($v) published=\(.time[$v]) license=\(.versions[$v].license // .license // "n/a") deprecated=\(.versions[$v].deprecated // "no") modified=\(.time.modified)"'
done
