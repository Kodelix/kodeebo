# Scratch/evidence script: extract ASVS 5.0.0 requirements for chapters V8, V7 (7.4,7.5,7.6), V16, and V2.3 from the downloaded official CSV.
# Usage: python3 -I asvs_extract.py <csv path>
import csv, sys
want = lambda r: (r['chapter_id'] in ('V8','V16')) or r['req_id'].startswith(('V7.4','V7.5','V7.6','V2.3','V6.3.5','V14.2'))
with open(sys.argv[1], newline='', encoding='utf-8') as f:
    for r in csv.DictReader(f):
        if want(r):
            print(f"{r['req_id']} L{r['L']} [{r['section_name']}] {r['req_description']}")
