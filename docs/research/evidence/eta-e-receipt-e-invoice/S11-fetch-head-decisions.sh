#!/usr/bin/env bash
# S11: download head-of-ETA mandate decisions, record sha256, render pages to PNG (text layers are image/garbled).
# Usage: S11-fetch-head-decisions.sh <outdir>
set -u
out="$1"
while read -r name url; do
  d="$out/$name"; mkdir -p "$d"
  curl -sS -L -A 'Mozilla/5.0' -o "$d/$name.pdf" -w "$name http=%{http_code} bytes=%{size_download}\n" "$url"
  sha256sum "$d/$name.pdf" | sed "s|$d/||"
  pdfinfo "$d/$name.pdf" | grep -E "Pages|CreationDate"
  pdftoppm -r 80 -png "$d/$name.pdf" "$d/p"
done <<'LIST'
karar-302-2024 https://eta.gov.eg/sites/default/files/2024-07/eta-karar-302-2024-e-reciept.pdf
karar-396-2024 https://eta.gov.eg/sites/default/files/2024-09/karar-396-2024-e-reciept.pdf
karar-455-2024 https://eta.gov.eg/sites/default/files/2024-12/karar-455-2024-e-reciept-phase6-wave2.pdf
karar-123-2025 https://eta.gov.eg/sites/default/files/2025-03/karar-123-2025-e.reciept-phase7-wave12.pdf
karar-232-2024 https://eta.gov.eg/sites/default/files/2024-06/eta-karar-232-2024-e-reciept.pdf
LIST
