#!/bin/sh
# Compare extracted text of three receipt-type pages (generic, coffee&restaurant, entertainment). Usage: field-diff.sh <text-dir>
d="$1"
for f in documents_receipt-v1-2 documents_coffee-restaurant-receipt-v1-2 documents_entertainment-receipt-v1-2; do
  sed -n '/Egyptian eInvoicing & eReceipt SDK$/,$p' "$d/$f.txt" | grep -v '^\s*$' > "$d/$f.body.txt"
done
echo "=== generic vs coffee"; diff "$d/documents_receipt-v1-2.body.txt" "$d/documents_coffee-restaurant-receipt-v1-2.body.txt"
echo "=== generic vs entertainment"; diff "$d/documents_receipt-v1-2.body.txt" "$d/documents_entertainment-receipt-v1-2.body.txt"
