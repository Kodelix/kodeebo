#!/usr/bin/env bash
# S10: download ETA official PDFs, record sha256, extract text layer with pdftotext.
# Usage: S10-fetch-eta-pdfs.sh <outdir>   ; each PDF goes in its own subdirectory.
set -u
out="$1"
while read -r name url; do
  d="$out/$name"; mkdir -p "$d"
  curl -sS -L -A 'Mozilla/5.0' -o "$d/$name.pdf" -w "$name http=%{http_code} bytes=%{size_download}\n" "$url"
  sha256sum "$d/$name.pdf" | sed "s|$d/||"
  pdftotext -layout "$d/$name.pdf" "$d/$name.txt" 2>&1 | head -2
  echo "  text-bytes: $(wc -c < "$d/$name.txt" 2>/dev/null)"
done <<'LIST'
decision-230-2022 https://eta.gov.eg/sites/default/files/2024-09/decision.no_.230.for_.2022.pdf
decision-38-2024 https://eta.gov.eg/sites/default/files/2024-09/decision.no_.38.for_.2024.pdf
karar-361-2025 https://eta.gov.eg/sites/default/files/2025-09/karar-361-2025-e.reciept-phase9-wave1.pdf
ereceipt-faq-v24 https://eta.gov.eg/sites/default/files/2024-02/ERECEIPT-FAQ-V24-31-1-2024.pdf
pos-requirements-v3.2 https://eta.gov.eg/sites/default/files/2023-02/POS-requirements_v3.2.pdf
pos-vendor-docs https://eta.gov.eg/sites/default/files/2022-06/pos-docs.pdf
pos-verified-vendors-v29 https://eta.gov.eg/sites/default/files/2026-09/pos_verified_vendors_contact_data.v29.pdf
pos-device-request https://eta.gov.eg/sites/default/files/2024-08/tlb_alhswl_ly_nqtt_by.pdf
karar-289-2022 https://eta.gov.eg/sites/default/files/2022-06/e-receipt-stage1.pdf
LIST
