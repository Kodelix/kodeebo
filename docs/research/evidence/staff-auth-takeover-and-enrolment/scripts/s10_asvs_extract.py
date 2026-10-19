"""S10 (tier-E): print the ASVS 5.0.0 requirement rows this part relies on, read from the
official CSV already stored in the repository (origin recorded in staff-auth-note F309).
Usage: python3 -I s10_asvs_extract.py <path-to-asvs-5.0.0.csv>
Reads one local file; no network; writes only to stdout."""
import csv
import hashlib
import sys

path = sys.argv[1]
raw = open(path, "rb").read()
print("file:", path)
print("sha256:", hashlib.sha256(raw).hexdigest())
print("bytes:", len(raw))
rows = list(csv.DictReader(raw.decode("utf-8").splitlines()))
wanted = ["6.3.1", "6.3.3", "6.3.5", "6.3.7", "6.4.1", "6.4.4", "6.5.1", "6.5.2", "6.5.3",
          "6.5.4", "6.5.5", "6.5.6", "6.6.1", "6.6.2", "6.6.3", "6.6.4", "6.7.2", "6.8.4",
          "7.5.1", "7.5.3", "2.3.5", "2.4.1", "16.3.1", "7.2.3", "7.2.4", "7.4.2"]
by_id = {r["req_id"]: r for r in rows}
for w in wanted:
    r = by_id.get("V" + w)
    if r is None:
        print("V%s: NOT FOUND" % w)
        continue
    print("V%s (L%s): %s" % (w, r["L"], r["req_description"]))
    print()
