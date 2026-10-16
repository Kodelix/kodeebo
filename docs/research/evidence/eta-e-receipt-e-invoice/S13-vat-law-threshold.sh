#!/usr/bin/env bash
# S13: download ETA's English VAT Law 67/2016 PDF and grep registration-threshold wording.
set -u
out="$1"; mkdir -p "$out/vat-law-67-2016"
curl -sS -L -A 'Mozilla/5.0' -o "$out/vat-law-67-2016/vat-law.pdf" -w "http=%{http_code} bytes=%{size_download}\n" https://www.eta.gov.eg/sites/default/files/2024-02/Law-english-no.67-2016.pdf.pdf
sha256sum "$out/vat-law-67-2016/vat-law.pdf"
pdfinfo "$out/vat-law-67-2016/vat-law.pdf" | grep -E "Pages|CreationDate"
pdftotext -layout "$out/vat-law-67-2016/vat-law.pdf" "$out/vat-law-67-2016/vat-law.txt"
grep -n -i -E "Updated on|500,000|five hundred thousand|registration limit|obliged to register|threshold" "$out/vat-law-67-2016/vat-law.txt" | head -40
