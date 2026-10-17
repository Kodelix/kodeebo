#!/usr/bin/env bash
# S29c (part 2): (1) ASVS 5.0.0 official text from the OWASP/ASVS repo at tag v5.0.0: list 5.0/en files, download the chapters on components/dependencies, crypto and config, print the requirement rows
# that mention components, updates, signatures or integrity. (2) Temurin 21.0.12.1 release record from adoptium/temurin21-binaries (GitHub releases API).
# Usage: s29c-asvs-and-temurin.sh <outdir>
set -u
out="$1"; mkdir -p "$out"
date -u +"run at %Y-%m-%dT%H:%MZ"
gh api "repos/OWASP/ASVS/contents/5.0/en?ref=v5.0.0" --jq '.[].name' | tee "$out/asvs-5.0.0-files.txt"
for f in $(grep -E '0x(2[0-9]|1[0-9]|3[0-9])-V(15|11|13|12|10)-' "$out/asvs-5.0.0-files.txt"); do
  gh api "repos/OWASP/ASVS/contents/5.0/en/$f?ref=v5.0.0" --jq .content | base64 -d > "$out/$f"; echo "saved $f $(wc -c < "$out/$f") bytes"
done
echo "== requirement rows (ID | text) matching keywords"
for f in "$out"/*V15*.md "$out"/*V11*.md "$out"/*V13*.md; do
  echo "--- $(basename "$f")"
  grep -E '^\| \*?\*?[0-9]+\.[0-9]+\.[0-9]+' "$f" | grep -iE 'third-party|component|library|librar|dependenc|signature|integrity|update|untrusted source|repositor|remediation|SBOM|certificate' | cut -c1-520
done
echo "== Temurin releases (latest 5 tags with dates) and body of the 21.0.12.1 one if present"
gh api "repos/adoptium/temurin21-binaries/releases?per_page=6" --jq '.[] | .tag_name+" | "+.published_at+" | "+.name' | tee "$out/temurin21-releases.txt"
gh api "repos/adoptium/temurin21-binaries/releases?per_page=6" --jq '.[] | select(.tag_name|test("21.0.12")) | .tag_name+"\n"+(.body|.[0:1800])' | head -50 | tee "$out/temurin21-0.12-release-body.txt"
