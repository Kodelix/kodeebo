#!/usr/bin/env bash
# Tier-E probe: latest published releases of the Electric sync service (filtered from the monorepo release list).
gh api "repos/electric-sql/electric/releases?per_page=100" --jq '.[] | select(.tag_name|test("sync-service|core")) | "\(.tag_name) \(.published_at) prerelease=\(.prerelease)"' | head -8
echo "--- monorepo tags containing sync-service (first 5)"
gh api "repos/electric-sql/electric/tags?per_page=100" --jq '.[].name' | grep -i "sync-service" | head -5
