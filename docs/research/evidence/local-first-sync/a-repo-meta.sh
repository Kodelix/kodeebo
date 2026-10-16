#!/usr/bin/env bash
# Tier-E probe (read-only, public GitHub metadata): licence, archived flag, last push, latest releases, published GHSA count.
# usage: a-repo-meta.sh owner/repo [owner/repo ...]
for r in "$@"; do
  echo "=== $r"
  gh api "repos/$r" --jq '"license=\(.license.spdx_id // "none") archived=\(.archived) pushed_at=\(.pushed_at) stars=\(.stargazers_count) default=\(.default_branch) desc=\(.description)"' 2>&1 | head -2
  gh api "repos/$r/releases?per_page=4" --jq '.[] | "release \(.tag_name) published=\(.published_at) prerelease=\(.prerelease)"' 2>&1 | head -5
  echo -n "published-advisories: "
  gh api "repos/$r/security-advisories?per_page=100" --jq '[.[] | "\(.ghsa_id) \(.severity) \(.state) \(.published_at[0:10]) \(.summary)"] | if length==0 then "none" else join("\n  ") end' 2>&1 | head -20
done
