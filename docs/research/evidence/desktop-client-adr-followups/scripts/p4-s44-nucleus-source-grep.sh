#!/usr/bin/env bash
# p4-s44: does the Nucleus updater source mention signature / Authenticode / rollout / rollback? Read-only code search.
set -u
echo "# date: $(date -u +%FT%TZ)"
for Q in "Authenticode" "WinVerifyTrust" "Ed25519" "stagingPercentage" "rollback" "minimumSystemVersion"; do
  echo "## query: $Q  (repo:NucleusFramework/Nucleus)"
  gh search code "$Q" --repo NucleusFramework/Nucleus --limit 8 --json path,repository 2>&1 | jq -r '.[]? | .path' 2>/dev/null | head -8
done
echo "## updater-runtime source tree (paths containing 'updater')"
gh api "repos/NucleusFramework/Nucleus/git/trees/HEAD?recursive=1" --jq '.tree[] | select(.path|test("updater";"i")) | select(.path|test("\\.kt$")) | .path' 2>&1 | head -40
