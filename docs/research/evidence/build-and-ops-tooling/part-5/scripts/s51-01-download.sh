#!/bin/bash
# S51 step 1: download ONLY the approved Trivy v0.76.0 Linux 64-bit tarball and its checksums file,
# verify SHA-256 against the checksums file, extract with tar. Nothing is executed on the host.
# Usage: s51-01-download.sh <trivy_dl_dir (new, empty)>
set -u
DL="$1"
echo "date_utc: $(date -u +%FT%TZ)"
[ -d "$DL" ] && [ -z "$(ls -A "$DL")" ] || { echo "dir must exist and be empty: $DL"; exit 1; }
API=https://api.github.com/repos/aquasecurity/trivy/releases/tags/v0.76.0
curl -fsS --max-time 30 "$API" -o "$DL/../release-v0.76.0.json" || { echo "api failed"; exit 1; }
python3 -I - "$DL/../release-v0.76.0.json" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]))
print("tag",r["tag_name"],"published",r["published_at"],"prerelease",r["prerelease"],"immutable",r.get("immutable"))
for a in r["assets"]:
    if "Linux-64bit" in a["name"] or "checksums" in a["name"]:
        print("asset",a["name"],a["size"],a["browser_download_url"])
PY
TAR=trivy_0.76.0_Linux-64bit.tar.gz
SUMS=trivy_0.76.0_checksums.txt
BASE=https://github.com/aquasecurity/trivy/releases/download/v0.76.0
curl -fsSL --max-time 30 -o "$DL/$SUMS" "$BASE/$SUMS" || { echo "checksums download failed"; exit 1; }
SZ=$(curl -fsSIL --max-time 30 "$BASE/$TAR" | grep -i '^content-length' | tail -1 | tr -d '\r ' | cut -d: -f2)
echo "tarball content-length reported: $SZ (approved: 52253735)"
[ "$SZ" = "52253735" ] || { echo "SIZE MISMATCH - not downloading"; exit 1; }
curl -fsSL --max-time 300 -o "$DL/$TAR" "$BASE/$TAR" || { echo "tarball download failed"; exit 1; }
ls -l "$DL"
echo "--- checksums file line for the tarball"; grep "$TAR" "$DL/$SUMS"
echo "--- sha256sum of tarball"; sha256sum "$DL/$TAR"
EXPECT=$(grep " $TAR\$" "$DL/$SUMS" | cut -d' ' -f1)
ACTUAL=$(sha256sum "$DL/$TAR" | cut -d' ' -f1)
if [ "$EXPECT" = "$ACTUAL" ] && [ -n "$EXPECT" ]; then echo "SHA-256 MATCH"; else echo "SHA-256 MISMATCH expect=$EXPECT actual=$ACTUAL"; exit 1; fi
echo "sigstore bundle: NOT verified (cosign not installed)"
mkdir "$DL/bin" && tar -xzf "$DL/$TAR" -C "$DL/bin" && ls -l "$DL/bin"
echo "--- tar member list"; tar -tzf "$DL/$TAR"
