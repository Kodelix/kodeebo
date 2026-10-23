# Set 5 attempt 3, seed 1006: the damaged store and the lab salvage (2026-10-23)

Evidence kept untouched (not committed, it holds the run's test key): production/session-state/drafts/s104-seed1006/
(the fetched store, SHA-256 904caa70f401dc6f..., identical to the VM's file; its events, intent log and run log).
Work copy: production/session-state/drafts/s104-seed1006-salvage/ (copies only).

- The cut: NMI (OS crash) held at client:after_mark #1; truncate journal, slot marker, START_CHECK=background,
  BG_MODE=counter (fix 4). After the reboot the client refused the store: store_unusable_at_start,
  "CorruptError: database disk image is malformed". 81 pages of 4 KB; none all-zero.
- Page 1 fails decryption and authentication, so no statement can open the file (page_count, sqlite_schema,
  quick_check, integrity_check all fail). The product's salvage (A) reads rows by query, so it recovers nothing here.
- Money at risk: the client had acknowledged 44 sales (s1006-a0 .. a43); the server held 42 (cursor 42). s1006-a42 and
  s1006-a43 existed only in the device store.
- Lab salvage on a copy: page 1 replaced by page 1 of a fresh store made by the same client code with the same test key
  (grown to 90 pages with rows in an existing table, so the schema and every root page stay the same), read on a
  read-only connection with PRAGMA writable_schema = ON (the header's page count is then ignored for the file size):
  - all 81 pages decrypt and authenticate (dbstat reaches all 37 objects);
  - bills 44 rows: all 44 acknowledged sales, including s1006-a42 (seq 43, 8,150 piasters) and s1006-a43 (seq 44,
    17,975 piasters); payments 44; outbox 2 rows, seq 43 and 44, status pending; counter 44; sync_state acked_seq 42;
  - the minutes table and integrity_check still report "malformed": structural damage from page 1's real header and
    free-page list being lost, not further unreadable pages.
- Conclusion: the money was all physically present; (A) as built would have reported seqs 43-44 as a lost range with an
  owner alert. Option (C) in the sync note's OQ31 row records the rebuild-page-1 salvage for the sync ADR.
