#!/usr/bin/env bash
# p4-s43: read the LICENSE files of Nucleus and jDeploy (first lines, size). Read-only.
set -u
echo "# date: $(date -u +%FT%TZ)"
for R in NucleusFramework/Nucleus shannah/jdeploy; do
  echo "## $R : licence-like files in repo root"
  gh api repos/$R/contents --jq '.[] | select(.name|test("(?i)licen|notice|copying")) | "\(.name) \(.size)"' 2>&1
  for F in LICENSE LICENSE.md LICENSE.txt; do
    echo "-- $R/$F (first 25 lines)"
    gh api repos/$R/contents/$F --jq '.content' 2>/dev/null | base64 -d 2>/dev/null | head -25
  done
done
