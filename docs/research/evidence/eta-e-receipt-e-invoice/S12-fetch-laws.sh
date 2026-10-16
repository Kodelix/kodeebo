#!/usr/bin/env bash
# S12: download ETA-hosted law PDFs + pos vendors list; sha256; pdftotext; page count.
set -u
out="$1"
while read -r name url; do
  d="$out/$name"; mkdir -p "$d"
  curl -sS -L -A 'Mozilla/5.0' -o "$d/$name.pdf" -w "$name http=%{http_code} bytes=%{size_download}\n" "$url"
  sha256sum "$d/$name.pdf" | sed "s|$d/||"
  pdfinfo "$d/$name.pdf" | grep -E "Pages|CreationDate"
  pdftotext "$d/$name.pdf" "$d/$name.txt"; echo "  text-bytes: $(wc -c < "$d/$name.txt")"
done <<'LIST'
law-6-2025 https://eta.gov.eg/sites/default/files/2025-02/law_no.6.of_.2025.pdf
etax-licence-337-2022 https://eta.gov.eg/sites/default/files/2022-08/etax-lw.pdf
LIST
