<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: Can Compose Multiplatform Desktop (A), Electron (B) or Tauri 2 (C) do the cashier counter's duties on a 4 GB Windows 10 reference VM? -->
<!-- Date: 2026-10-16 -->

# Prototype: desktop client spike (round 1)

**Status:** round 1 for A and B concluded 2026-10-17: **G0 PASS; A and B both PASS G1 and G2** (Findings below). **C (Tauri 2) not run — founder decision, 2026-10-17** (see below). Round 2 (G3 Arabic, G4 update, tamper legs) not started. Indicative only: VM, not the physical 4 GB PC.
**Risk tested:** `design/product-brief.md` risk 2: "A desktop technology runs well, prints and opens the drawer on Windows 10/11."
**Plan:** `docs/research/desktop-client-technology.md` § 9 (Spikes): S1/S40, S7/S43, S10, S20 and the phase 1 text. Round 1 covers the part of them listed under "Gates" below.
**Path:** code spike (feasibility). Throwaway: nothing here is imported by production code, and if a runtime is chosen, its production code is written from scratch (`.claude/rules/prototype-code.md`). The spike does **not** choose the stack. It feeds the runtime ADR.

## Round 4 (started 2026-10-19): G5 local migration under power cut, tamper legs

**Status:** runs ended 2026-10-19 16:53 (G5-F4 fix test included); **verdict NOT ASSESSED until the founder reviews it.** **Timebox:** the 1-day cap of `/prototype`, no waiver (04:30 to 16:53). Evidence: `evidence/g5/`.
**Question:** on Windows, through each runtime's own SQLite3MC binding, does the M1 migration (followups § 4.2, SC-21a design) survive a power cut at every step, and does the app refuse, rather than overwrite, a store it cannot trust (wrong key, damaged bytes, deleted file)?

**Hypothesis.** For A (Willena sqlite-jdbc 3.53.4.0) and B (better-sqlite3-multiple-ciphers 13.0.3), as `cashier` on the throttled VM:
- **G5.1 M1 migration** (followups S16; the store half of sync SC-21b). Build 1.0.2 (schema 2) migrates a 1.0.1 store (schema 1, 20 bills, 20 unsynced outbox rows) at first start: copy the store aside (`store.db.premigrate.tmp`, synced, then renamed `store.db.premigrate`), one transaction for all DDL and the `user_version` bump, verify, then delete the copy. **6 hold points × 2 runs × 2 runtimes = 24 exact cuts** (founder): `before-copy`, `during-copy` (half the copy written), `after-copy`, `mid-transaction` (after the first DDL), `after-commit`, `after-delete`. The test build stops at the point named in `hold.txt`, writes `hold-reached.txt` (synced) and waits; the harness then powers off. **Pass, per cut:** after the reboot the store is wholly schema 1 or wholly schema 2, never mixed; `integrity_check` ok; the copy is present until the migration is verified and removed only after; the 20 outbox rows are byte-identical (SHA-256 over `seq|bill_id|payload`); 1.0.2 then completes and starts; the old 1.0.1 app image refuses the schema-2 store without changing it (file hash unchanged).
- **G5.2 TS-05b** (sync note 9.1.1): `key.bin` replaced by a wrong, a truncated (16-byte) and an empty key, and 100 wrong keys in one process. **Pass:** every open fails; no row is returned; the app never treats it as a new install, never creates a store or a key, never changes `store.db` (hash unchanged); each failure is recorded in `events.txt`.
- **G5.3 TS-03c** (Windows store half): bytes flipped in a data page, in page 1 (the header) and in a hot rollback journal (left by a `mid-transaction` cut), with the app closed and while it holds the store open (`--serve`). **Pass:** detected, refused, never written over (the damaged file's hash unchanged), a copy kept aside in `damaged-<ms>/`, the store quarantined (`quarantine.txt`) and the event recorded. Recovery from the server and the gap report are the sync spike's half (TS-03b).
- **G5.4 TS-06c** (Windows store half): delete `store.db` while `--serve` holds it, and while the app is closed. **Record** what Windows does with the open file (`NOT SOURCEABLE — test`, sync note); **pass:** a missing store is never silently treated as a new install (a `store.id` kept outside the store says a store existed; the app refuses and records `store_missing`, never creates a new one).

**Shortcuts (round 4):** the migration is a toy (one column, one table, one index) on a 20-bill store; its copy time at the real store size is not measured here. The app refuses and records; it does not re-bootstrap from a server (sync spike). Hold points stop the process at exact steps; timed cuts between the points are not run (founder: 24 exact cuts).

**Results (G5).** VM, 4 GB, `cashier`, HDD-class throttle; builds A `KodeeboSpikeA-1.0.1/1.0.2.msi` (sha256 a7781b09…, 1f9ee6bc…), B `KodeeboSpikeB Setup 1.0.1/1.0.2.exe` (db5fa584…, aac8a5fb…). Base snapshots `r4-<rt>-s1v2`: 1.0.1 with 20 bills and 20 queued outbox rows (`outbox_sha=07d2c9dd9ddda8f1`, the same in both runtimes), the 1.0.1 program folder copied to `old101\<rt>`, 1.0.2 installed and never started. Evidence: `CUT5`, `TS05`, `TS03`, `TS06` lines in `evidence/g5/run-log-g5-20261019.txt`.

**G5.1 M1 migration: 24 of 24 cuts PASS, plus a control per runtime.** (B `after-copy` run 1 never reached its hold point: `hold.txt` was most likely not written before the app started, so the migration ran through. The harness now checks `hold.txt` is on disk before it starts the app; the rerun `Hafter-copy-1r` passed.) Per hold point, what the cut left and what 1.0.2 found at the next start (the same in A and B, both runs):

| Hold point | Files after the cut | 1.0.2 at the next start (`migration.txt`) |
|---|---|---|
| `before-copy` | store only | schema 1, no copy -> migrated |
| `during-copy` | store + `premigrate.tmp` (0 bytes, or 10240 of 20480: the unsynced half) | schema 1, incomplete copy removed -> migrated |
| `after-copy` | store + full copy (20480) | schema 1, integrity ok, copy present -> copy removed, migrated again |
| `mid-transaction` | store + copy + hot journal (516 or 4616 bytes) | **schema 1, integrity ok** (SQLite rolled the half-done DDL back) -> migrated again |
| `after-commit` | store + copy | **schema 2, integrity ok, copy still present** -> copy removed only now |
| `after-delete` | store only | schema 2 -> no migration |

Every cut: `integrity_check` ok; 20 bills, consistent; **`outbox_sha=07d2c9dd9ddda8f1` unchanged** (the 20 queued rows' stored bytes); the store never mixed schema 1 and 2; the copy was deleted only after the post-COMMIT verify. **The old 1.0.1 app image refused the schema-2 store every time** (`store schema 2 is newer than this app (max 1)`, event `store_newer_than_app`) **and left the file unchanged** (hash before = after). Migration time on the throttled disk: **A 0.68–4.05 s** (control 2.08 s), **B 0.24–0.87 s** (control 0.24 s).

**G5.2 TS-05b: PASS, A and B.** A wrong, a truncated (16-byte) and an empty `key.bin`: every `--check` refused (`SQLITE_NOTADB` "file is not a database"; B with the empty key: "SQL logic error"); `store.db` hash unchanged; the bad `key.bin` left as written (the app created no key and no store); event `store_open_failed` with the key length, and a copy kept in `damaged-<ms>/`. 100 random keys in one process: `opened=0 failed=100`, store unchanged. With the right key back: integrity ok, 20 bills, same `outbox_sha`.

**G5.3 TS-03c (Windows store half), A and B:**
- **Data page (page 3), app closed: PASS.** `integrity_check` raised `SQLITE_CORRUPT`; the app kept a copy in `damaged-<ms>/`, wrote `quarantine.txt`, recorded `store_damaged_quarantined`; `store.db` unchanged; the next start refused (`store quarantined: recovery from the server needed`).
- **Page 1 (offset 200), app closed: PASS, with a limit.** `SQLITE_NOTADB` at open, the same error as a wrong key, so the app cannot tell a damaged header from a wrong key; it refuses, keeps a copy and never writes over the file. Each refused start keeps another copy (two starts, two copies): the product should keep one copy per distinct file hash.
- **Data page while the app holds the store open (`--serve`): NOT DETECTED while running.** The bytes were flipped on disk (Windows allowed the write: SQLite opens the file with read and write sharing), but the running app read its cached pages and reported `ok` every 2 s for 60 s. The next start detected it and quarantined. So in-process damage is caught at the next start, not while the counter runs.
- **Hot journal, app closed: first run did not exercise it** (at the `mid-transaction` cut the store file had not changed on disk yet, and B's 516-byte journal was shorter than the flip offset). **Rerun with build 1.0.3** (A sha256 9b318b8e…, B 39340f37…; snapshots `r4-<rt>-s1v3`), mode `--spill-hold`: a 2-page cache, `CREATE TABLE spill` and 1,000 × 400-byte inserts, so SQLite writes uncommitted pages into `store.db` (20 KB → 425–479 KB) and keeps the originals in a hot journal (9.7–10.8 KB), stopped before COMMIT, then a power cut:
  - **No flip: PASS, A and B.** The next open rolled the transaction back: `store.db` back to 28,672 bytes, no `spill` table, integrity ok, 20 bills, same `outbox_sha`, the journal gone.
  - **64 bytes flipped in the hot journal (offset 600, inside the saved copy of page 1): FAIL of "never written over", A and B alike.** SQLite played the damaged journal back **while opening**, before the app's own check could run. It truncated `store.db` to 28,672 bytes and wrote the damaged page 1 into it, so the store became unreadable (`SQLITE_NOTADB`). The app then refused and recorded `store_open_failed`, and kept a copy, but **of the already overwritten file**; the journal stayed on disk. SQLite's journal checksum samples only some bytes of each page, so a damaged page can pass it (inference from the result, not sourced). This is the same in both runtimes: it is SQLite, not the binding.
  - **Mitigation tested (founder, 2026-10-19: test the fix, then the verdict): build 1.0.4** (A sha256 a2c21eb8…, B f7bd687b…; snapshots `r4-<rt>-s1v4`) = 1.0.3 plus: if `store.db-journal` exists before the open, copy `store.db` and the journal to `prejournal-<ms>/` (synced) and record `hot_journal_found`; after the open, run `integrity_check`; on success delete the copy (`hot_journal_replayed_ok`), on failure keep it and quarantine.
    - **No flip: PASS, A and B.** The copy was made (`hot_journal_found`), SQLite rolled back, integrity ok, 20 bills, same `outbox_sha`, and the copy was removed (`hot_journal_replayed_ok`).
    - **Flip: PASS, A and B.** SQLite still overwrote `store.db` at open (28,672 bytes, `SQLITE_NOTADB`), and the app refused, but **the pre-open state is kept byte-identical**: `prejournal-<ms>/store.db` has the hash and size the store had after the cut (A 475,136 bytes, B 462,848 bytes) and `prejournal-<ms>/store.db-journal` the flipped journal's hash. `store_open_failed` names that copy (`pre_open_copy=`). Recovery is the server's (sync TS-03b).
    - Limit: the failed replay leaves the journal on disk, so every later start makes another `prejournal-` copy, of the already overwritten store (as G5-F5: keep the first copy, one per distinct file hash). The sync spike adopted the rule (sync note OQ28, "Store-design rule", tamper row `hot_journal_page1_flip`, commit 0f13d43).

**Findings (G5):**
- **G5-F1.** The M1 migration design holds on Windows through both bindings at all 6 steps: 24 of 24 cuts, never a mixed schema, queued rows byte-identical, the copy removed only after the verify, and the old app refuses a newer store without touching it.
- **G5-F2 (timing).** On the throttled disk the migration took **A 0.68–4.05 s** and **B 0.24–0.87 s** (20-bill store). It runs once, at the first start after an update, but A's can pass the 3 s counter ceiling: measure it on the physical 4 GB PC with a real-size store.
- **G5-F3.** Damage written to `store.db` while the app runs is not seen until the next start (the app reads its page cache). The product needs an integrity check at start (it has one) and should not rely on the running app to notice.
- **G5-F4.** A damaged hot journal is played back by SQLite at open and overwrites the store before the app can check it (A and B; SQLite, not the binding). **Fix tested in 1.0.4: copy the store and the journal aside before opening whenever a hot journal exists; the pre-open state then survives byte-identical (A and B PASS).** It becomes a rule of the local store design (sync note OQ28).
- **G5-F5.** Wrong key and damaged page 1 give the same error (`SQLITE_NOTADB`); the app cannot tell them apart and refuses both. Each refused start keeps another copy: keep one copy per distinct file hash.
- **G5-F6.** Windows refuses to delete an open store file; a store deleted while the app is closed is detected through `store.id` and never replaced by a new empty store.
- **G5-F7 (harness).** Round 4's installs went through `g4.sh install`, which writes its screenshots to `evidence/g4/` and overwrote the two round 3 `1.0.1` install screenshots there in the working tree (the committed versions in git are intact). The round 4 screenshots are kept as `evidence/g5/r4-install-*.png`. In the committed run log the `key.bin` SHA-256 prefixes are replaced by labels (K1, K2, …; same label = same key file) because the secret scan flags them; the raw log stays in `.cache/`.

**G5.4 TS-06c (Windows store half): PASS, A and B.** **Windows refuses to delete `store.db` while the app holds it open** ("The process cannot access the file … because it is being used by another process"); the app kept serving. App closed: the file deleted, the next start refused (`store missing: re-bootstrap from the server needed`, event `store_missing` with the `store.id`), and **no new store was created**.

**Coordination:** the sync spike cites G5.1 for the store half of SC-21b, if the evidence records per hold point and per runtime: whole old or new schema, integrity ok, the copy kept until verified, queued rows' bytes unchanged (sync session, 2026-10-19). TS-05b, TS-03c and TS-06c run once here and the sync spike cites them.

## Round 3 (started 2026-10-18): G4 per-user update

**Status:** runs ended 2026-10-18 12:20 (A and B, G4.1–G4.4). **Founder: test the fix first: G4.5 (launcher) ran 2026-10-18 to 19 (30 of 30 counted cuts recovered); **G4 PASS for A and B, conditional on the launcher and a faster recovery (founder, 2026-10-19)**. VM reverted to `clean-ssh2` and shut off 2026-10-19 04:20; temporary snapshots r3-a-100, r3-b-100, r3-b-100s, r3-a-100L and r3-b-100L deleted (founder). The VM was reverted to `clean-ssh2` and shut off at 12:25; run log copied to `evidence/g4/run-log-g4-20261018.txt`. **Timebox:** the 1-day cap of `/prototype`, no waiver.
**Question:** can a standard user upgrade and uninstall A and B per-user without a UAC prompt, while the encrypted store survives every path, including a hard power-off during the upgrade? (Followups S10 core, S11, S15, S16; desktop-note S36.) It feeds the runtime ADR.

**Hypothesis.** On the Windows 10 22H2 VM, as the standard user `cashier`, both A (per-user jpackage MSI, fixed `upgradeUuid`) and B (per-user NSIS) will:
- upgrade 1.0.0 → 1.0.1 with no UAC prompt, with the app closed and when the running app starts the upgrade itself and exits;
- keep the encrypted store intact (integrity and consistency checks clean);
- leave the store in place on uninstall;
- after 10 hard power-offs at random moments during each upgrade, start and pass the store check every time.

The signal is the G4 tables in `evidence/g4/`.

**Riskiest assumption (feasibility):** A's MSI major upgrade, run by a standard user while the app may hold its files open, completes or rolls back cleanly. Round 1 found the per-user MSI's uninstall entry under HKLM (F101), and MSI rollback on power loss is a tier-4 lead (followups F118).

**Runs:**

| Run | What | Pass signal |
|---|---|---|
| G4.1 | Install 1.0.0, write 20 bills; run the 1.0.1 installer with the app closed | Exit 0, no UAC prompt on screen, version 1.0.1, store clean with 20 bills; uninstall-entry hive recorded |
| G4.2 | 1.0.0 open: (a) the 1.0.1 installer while the app holds its files; (b) the app's `--self-update` (start the installer, exit) | (a) recorded; (b) no prompt, the app returns as 1.0.1, store clean |
| G4.3 | Uninstall (MSI `/x`, NSIS `/S`) and B's `deleteAppDataOnUninstall` variant | What remains: program files, registry entry, store folder. The store must remain by default (founder rule, followups Q-1P4) |
| G4.4 (S16) | First measure the 1.0.0 → 1.0.1 upgrade duration D per runtime (3 timed runs, median). Then 10 hard power-offs per runtime, cut *k* (k = 0…9) at offset (k + u)·D/10 with u drawn from a seeded generator (seed recorded), so cuts cover the file-replacement window, not only its start or end (founder, 2026-10-18). Boot after each | Every time: the app starts (1.0.0 or 1.0.1, never broken), store clean, re-running the 1.0.1 installer succeeds. **The table records each cut's offset in seconds and as a fraction of D** |

**Followups S11 time box (founder, 2026-10-18)** (followups S11 = the custom `main.wxs`; not desktop-note S11, which is DPAPI key wrapping): if a custom `main.wxs` does not put A's uninstall entry in HKCU within 2 hours, the HKLM entry is recorded as an A finding, the default MSI is used for the rest of round 3, and the fix becomes a build item for A.

**Shortcuts (round 3):**
- The updater's signature, manifest and staged-rollout logic is runtime-neutral code; it belongs to the update story and the threat model, not this spike.
- Unsigned installers: no Authenticode check.
- No Windows 11 leg.
- 10 power cuts per runtime: indicative, not statistical.

**Order to the runtime ADR (founder correction, 2026-10-18):**
1. **Round 3** (this round): G4.
2. **Round 4:** the M1 local migration under power cut, and the tamper legs TS-03c, TS-05b and TS-06c.
3. **The sync spike's phases 4 and 5** (`prototypes/local-first-sync-spike/`).
4. **Then the runtime ADR** (`/architecture-decision`), after the sync spike's phases 4 and 5 report. (This replaces the founder's earlier same-day option of writing the ADR straight after round 3.)

**Coordination with the sync spike:**
- Both spikes use the one VM (`kodeebo-win10`). Each claims it in its own block of `production/session-state/active.md` before a run and releases it after (reverted to `clean-ssh2`, shut off).
- Any tamper leg both spikes need runs **once, on the shared store**, and each spike cites the same evidence.
- **VM access is first-ready, not sequenced** (founder, 2026-10-18): the two spikes run in parallel with no priority; when one block says FREE, the VM goes to whichever spike is ready, through claim and release in the checkpoint. The order of work above is about what precedes the runtime ADR, not about VM priority.
- **Agreed split (desktop and sync sessions, 2026-10-18):**
  - **TS-05b** (wrong, truncated and empty key): desktop round 4 runs it once through each runtime's binding; sync phase 4 cites it.
  - **TS-03c** and **TS-06c**: desktop round 4 runs the Windows store half (detect, refuse, never write over, keep the damaged file aside, Windows delete-while-open behaviour); the sync spike covers the server half on Linux (TS-03b, TS-06a/b) and cites the desktop run.
  - Evidence: `evidence/g5/` (round 4 = gate G5).
  - TS-04b, TS-08, TS-01c and TS-07b stay with sync phase 4.
- **Label note:** *desktop-note S11* (DPAPI key wrapping, key custody) and *followups S11* (custom `main.wxs`, HKCU uninstall entry) are different spikes. Round 3 runs followups S11 only.

**Results (G4, A).** VM, 4 GB, `cashier`; HDD-class throttle unless a row says otherwise. Evidence: `evidence/g4/`, run log `.cache/g4-20261018.txt` (copied to evidence at the end of round 3).

| Run | A (Compose Desktop, jpackage per-user MSI) |
|---|---|
| Install 1.0.0 | exit 0, 308.5 s; MSI log: "no elevation required"; 20 bills written; store check clean |
| G4.1 upgrade 1.0.0 → 1.0.1, app closed | exit 0, no elevation (MSI log), version 1.0.1, store clean (20 bills, store.db hash unchanged). Throttled duration: 141.7, 142.9, 95.3 s → **D = 141.7 s** (median). Unthrottled: 12.4 s, 13.3 s (two runs where a harness fault skipped the throttle; not used for D) |
| G4.2a upgrade with 1.0.0 open on screen | exit 0 in 45.4 and 43.8 s, no prompt. **The running 1.0.0 kept running** (window title still 1.0.0, process alive) although the MSI log says Restart Manager "shut down all applications". Windows Installer moved the in-use files aside to `C:\Config.Msi\*.rbf`, scheduled them for deletion at the next reboot (34 pending deletions, none of the app's own paths), and installed 1.0.1; a new start ran 1.0.1 with the store clean. Evidence: `g42a-a-upgrade-while-open.txt`, `a-pend-after-upgrade-while-open.png` |
| G4.2b `--self-update` (app starts msiexec, exits) | upgrade completed: version 1.0.1, store clean, relaunch screenshot `a-g42b-relaunch.png`. The `--self-update` process itself returned only after 246.7 s, about as long as the upgrade, not at once |
| G4.3 uninstall, app closed | exit 0 in 3.7 s; uninstall entries removed; program folder removed; **store folder left intact** (store.db and key.bin hashes unchanged) |
| G4.3 uninstall, 1.0.1 open | exit 0 in 9.4 s; entries removed; **50 files (93.6 MB) left in the program folder** (in use); the app kept running; store intact |
| G4.4 power cuts, set 1 (D = 141.7 s from the timing runs) | 10/10 survived: after each cut 1.0.0 started with the store clean; re-running the installer gave 1.0.1, store clean. **But every cut (12–131 s) fell before msiexec wrote its log**, i.e. while Windows Installer was still opening and checking the package (no change made yet). Offsets: `cut-offsets-a.txt` |
| Cut-path probe | The upgrade exactly as the cuts start it (`/l*v!` flushed log, right after a snapshot boot, throttled): log opens +118 s; **1.0.0's files removed +186–265 s** (nested uninstall's `InstallFinalize`); **1.0.1's files written +330–402 s**; log closes +459 s. So D on the cut path is 459 s. One probe run, not a median of three. Evidence: `g44-a-cut-path-timeline-probe.txt` |
| G4.4 power cuts, set 2 (D = 459 s, offsets `cut-offsets-a-set2.txt`) | s2k0–s2k4 (35.5–186.5 s; phases: before the log ×3, `RemoveExistingProducts`, `InstallFinalize`): survived, as set 1. **s2k5 (268.9 s; phase: the nested removal of 1.0.0 had ended, the 1.0.1 install had not started): A's whole program folder was ABSENT after the reboot**; launching the app gave the Windows error "Windows cannot find …\\KodeeboSpikeA.exe" (`a-s2k5-hang-screen.png`). Re-running the installer restored 1.0.1 in 4.7 s; the store (its own folder) was untouched. **s2k6 (298.1 s), s2k7 (328.1 s), s2k8 (382.0 s), all inside the new install's `InstallFinalize` (writing 1.0.1): app missing too.** s2k9 (422.4 s, install ended): 1.0.1, store clean. **Set 2 total: 6 of 10 survived; 4 of 10 (268.9–382.0 s, about 30 % of the upgrade) left no runnable app.** Windows Installer never rolled back to 1.0.0 at boot. Re-running the installer repaired every case in 4.7–8.3 s (unthrottled boot); the store check was clean every time |

**Results (G4, B).** Same VM, user and throttle.

| Run | B (Electron 44, electron-builder per-user NSIS) |
|---|---|
| Install 1.0.0 | exit 0 in 857.4 s (seq3; an earlier run passed the 600 s harness timeout, so the timeouts became 1800 s); no UAC prompt (`at10s` screenshots); 20 bills written; store check clean. Uninstall entry: **`HKEY_USERS\<cashier SID>\Software\Microsoft\Windows\CurrentVersion\Uninstall\d35e8870-…`, i.e. HKCU only; no machine-wide entry** (`uninstall-entries found=1`) |
| G4.1 upgrade 1.0.0 → 1.0.1, app closed | exit 0, version 1.0.1, store clean (20 bills, store.db and key.bin hashes unchanged), HKCU entry now 1.0.1. Throttled, right after a snapshot boot: 289.9, 285.2, 343.3 s → **D = 289.9 s** (median) |
| G4.2a upgrade with 1.0.0 open on screen | exit 0 in 197.5 s, no prompt. **The installer closed the running 1.0.0 without asking** (window and taskbar button gone, `b-g42a-after-upgrade-while-open.png`) and did not start 1.0.1; a new start ran 1.0.1 with the store clean (hashes unchanged) |
| G4.2b `--self-update` (app starts the installer, exits) | upgrade completed: version 1.0.1, store clean; the app did not restart itself (relaunch by the harness: `b-g42b-relaunch.png`). The `--self-update` process returned after 136.6 s, not at once (as A) |
| G4.3 uninstall, app closed (on 1.0.1) | exit 0; the uninstaller re-launches itself from `%TEMP%`, entry gone after 32 s; program folder and shortcut removed; **store folder intact** (hashes unchanged). Electron's own `userData` folder `%APPDATA%\KodeeboSpikeB` (52 files, 2.9 MB: Chromium caches, preferences) **stays** |
| G4.3 uninstall, 1.0.0 open | the uninstaller closed the app and removed everything in 45 s: **no program file left** (A left 50); store intact; `userData` stays (`b-g43-after-uninstall-while-open-r2.png`) |
| G4.3 `deleteAppDataOnUninstall: true` variant | entry gone after 126 s; program folder removed; **`%APPDATA%\KodeeboSpikeB` deleted**; the store in `%LOCALAPPDATA%\KodeeboSpike\b` **intact** (hashes unchanged), because the option deletes only Electron's `userData` path |
| G4.4 power cuts (D = 289.9 s, offsets `cut-offsets-b.txt`, seed 20261021) | NSIS writes no log, so the phase signal is the program folder's file count after the reboot (250 = whole). k0–k5 (15.8, 40.1, 82.7, 87.3, 127.0, 154.1 s; 0.06–0.53 D): 1.0.0 started, store clean, 250 files. **k6 (192.6 s, 0.66 D) and k7 (216.9 s, 0.75 D): program folder present but EMPTY (0 files), no app. k8 (243.7 s, 0.84 D): 11 of 250 files (328 MB); the executable was there but did not run.** k9 (287.2 s, 0.99 D): 1.0.1 whole, store clean. **7 of 10 survived; 3 of 10 (192.6–243.7 s, about 20 % of the upgrade) left no runnable app.** Re-running the 1.0.1 installer repaired every case in 18.5–36.8 s (after a cut the boot is unthrottled); the store check was clean after every cut (20 bills, consistent). Cut timing: each power-off landed 0.2–0.5 s after its target |

**Findings (G4):**
- **G4-F1 (A, confirmed with full paths).** A per-user install by `cashier` creates **two** registrations: Windows Installer's own per-user one, `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\<cashier SID>\Products\<packed code>\InstallProperties`, which shows the per-user context, **and** an entry in the machine-wide `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{ProductCode}`. The package itself writes only `HKCU\Software\Unknown\KodeeboSpikeA\1.0.0` (MSI log `RegAddValue`); the machine-wide entry comes from Windows Installer's product registration. So the finding stands: a standard user's per-user install leaves a machine-wide Add/Remove Programs entry that other Windows users on the PC can see. A custom `main.wxs` was **not attempted**, because the package writes no Uninstall key that it could change (inference from the log, not sourced); the founder's S11 time-box rule applied early. Evidence: `g4-f1-registry-paths-a-100.txt`, `msi-install-a-100-excerpt.txt`.
- **G4-F2 (harness).** Fixed during the round:
  - With `pipefail`, the logon check `ssh … query user | grep` failed even when the cashier was logged on, because `query user` exits non-zero. The wait ran to its timeout, and two A upgrades ran unthrottled (not used for D). Round 2's re-logon log line "~325 s" was that same timeout, not a measurement.
  - A fixed 90 s wait missed A's cold start; `gui` now waits for the app's own first-frame line.
  - An edited harness script broke a running job; the job was stopped and rerun.
- **G4-F3 (A).** An upgrade does not stop a running A; the counter keeps the old version until it restarts. The updater must restart the app itself at shift handover (founder rule). No app file is left for a reboot, so a restart gets the new version whole.
- **G4-F5 (A, the power-cut result that matters).** jpackage's MSI performs the major upgrade as "remove 1.0.0, then install 1.0.1". A power cut from the end of the old version's removal through the writing of the new files (s2k5–s2k8, 4 of 10 cuts, about 30 % of the upgrade) leaves **no runnable app**: the counter cannot start until the installer is run again. Windows Installer did not roll the half-done upgrade back at boot. The store survives because it lives outside the program folder. Mitigations to weigh (not tested):
  - author the MSI so the old version is removed **after** the new one is installed (a custom `main.wxs` / `--resource-dir` changing where `RemoveExistingProducts` is scheduled; that brings followups S11's `main.wxs` back, for the upgrade order, not the registry hive);
  - keep the updater and the last good installer **outside** the program folder, so a small launcher can detect the missing app at the next start and re-run the installer (an ADR question for U-A4).
  This is a round 3 failure of the pass signal "the app starts (1.0.0 or 1.0.1, never broken)" for A's default installer, not necessarily for A as a runtime.
- **G4-F6 (harness).** After s2k5's cut the harness read the last lines of `version.txt` and `check.txt`, which were stale (from the snapshot), as "1.0.0, store ok". It also hung on the Windows error dialog until the dialog was dismissed. Fixed: the harness checks the executable exists first, and accepts only lines written by the run. All other cuts' readings carry new process IDs, so they are real.
- **G4-F4 (A, timing, not gated).** Under the throttle, A's first frame after a boot took 474 s and 408 s here (round 2: 49–195 s), with the logon still loading. Indicative only; the physical 4 GB PC decides.
- **G4-F7 (B).** B's per-user NSIS installer and uninstaller **close a running B without asking** and do not start it again (G4.2a, G4.3 open). The upgrade then lands whole and an uninstall leaves no file behind, unlike A (G4-F3, 50 files left). For the counter, an installer started while the cashier works would close the app mid-action: the updater (either runtime) must run only at shift handover, close the app itself first, and start it again after (founder rule). How the installer closes the app (polite close or forced) was not observed.
- **G4-F8 (B, the power-cut result that matters).** 3 of 10 cuts (k6–k8, 192.6–243.7 s, 0.66–0.84 D) left **no runnable app**: the program folder empty or partly written. The file counts show the installer deletes the old version's files before it writes the new ones (observed through counts; the installer's internal order was not read from its source). This is the same failure class as A's G4-F5 (A 4 of 10, about 30 % of its upgrade): neither default installer keeps a runnable app through the whole upgrade, and neither repairs itself at boot. Both repair by re-running the installer (B 18.5–21.9 s, A 4.7–8.3 s), and both kept the store clean through all 20 cuts because it lives outside the program folder. So the mitigation is the same and runtime-neutral: the updater and the last good installer live **outside** the program folder, and a small launcher detects a missing or broken app at start and re-runs the installer (a U-A4 / update-story item; for A, the `RemoveExistingProducts` order is a second option, G4-F5).
- **G4-F9 (B).** B's uninstall entry is in the cashier's own hive only (`HKEY_USERS\<cashier SID>\…\Uninstall\d35e8870-…`); no machine-wide entry, unlike A (G4-F1). Electron's `userData` folder (`%APPDATA%\KodeeboSpikeB`: Chromium caches and preferences) survives a default uninstall; `deleteAppDataOnUninstall: true` deletes it and only it. **Design rule:** the store must never live in Electron's `userData` path, or that option would delete it; the spike's store in `%LOCALAPPDATA%\KodeeboSpike\b` survived every uninstall.
- **G4-F10 (harness).** Fixed during the B runs:
  - seq2's two B uninstalls never ran: the uninstaller path has a space and was single-quoted, which a Windows command line does not treat as quotes ("Cannot convert value KodeeboSpikeB.exe' to type System.Int32"). Fixed with double quotes, plus a poll until the HKCU entry and the `%TEMP%` uninstaller process are gone (NSIS uninstallers re-launch themselves and return in 1–3 s). Both legs were rerun (`g43-closed-r2` on seq2's 1.0.1, `g43-while-open-r2` on 1.0.0).
  - A `state` step after an uninstall launched the missing executable and hung on the Windows error dialog (as G4-F6); it was stopped by hand, and the files line before it is the evidence.
  - The cut step's re-run of the installer now waits up to 1800 s (a full B 1.0.0 install took 857 s).

**G4 summary (both runtimes; verdict pending founder review).**

| Pass signal | A (jpackage MSI) | B (NSIS) |
|---|---|---|
| Upgrade and uninstall as a standard user, no UAC prompt | yes | yes |
| Store intact on every path (upgrades, self-update, uninstalls, 20 cuts) | yes | yes |
| Store left on uninstall | yes | yes (also with `deleteAppDataOnUninstall`) |
| Running app during an upgrade | keeps running the old version (G4-F3) | closed without asking, not restarted (G4-F7) |
| Uninstall while open | 50 files left in the program folder | nothing left |
| Uninstall entry | machine-wide HKLM entry too (G4-F1) | cashier's HKCU only |
| Upgrade duration D, throttled | 141.7 s (timing runs); 459 s on the cut path | 289.9 s |
| 10 power cuts: app starts every time | **no**: 6 of 10 (set 2) | **no**: 7 of 10 |
| Repair by re-running the installer | every case, 4.7–8.3 s | every case, 18.5–21.9 s |

Proposed reading for the founder: **G4 fails the "never broken" power-cut signal for both default installers, by the same mechanism, with the same runtime-neutral fix (G4-F8).** G4 does not rule out either runtime. It separates them on G4-F1 (A's machine-wide entry), G4-F3/F7 (running app kept vs closed) and the uninstall-while-open leftovers. Round 4 (M1 migration under power cut, tamper legs) comes next.

**Founder decision (2026-10-18): test the fix first.** Power cuts are common at Egyptian venues, so a cashier app that will not start after a cut during an update is a real field failure, and the fix may behave differently for the MSI (A) and the NSIS installer (B), which would matter to the runtime ADR. G4 gets no verdict until G4.5 reports. The three temporary snapshots stay until G4.5 reports, then they are deleted.

### G4.5: launcher outside the program folder (started 2026-10-18)

**Question:** with a small launcher outside the program folder that re-runs the last good installer, does the app start after every power cut during an update, with nobody reinstalling?

**Hypothesis.** With the launcher, the same 10 spread power cuts per runtime (A: `cut-offsets-a-set2.txt`, D = 459 s; B: `cut-offsets-b.txt`, D = 289.9 s) all end with the app's first frame after the reboot, started by the launcher at logon, with the store check clean. **Pass: 10 of 10 per runtime, no human action.**

**Design (spike, runtime-neutral; `guest/kspike-launcher.ps1`):**
- Lives in `%LOCALAPPDATA%\KodeeboSpikeLauncher\<rt>\`, outside the program folder and the store folder. It keeps each staged installer in `installers\<version>\` with a manifest of the program folder's expected file count and bytes for that version (in the product, the signed update manifest carries this).
- **Journal** (`journal.txt`, written to a temp file with write-through and then moved over the old one): `state=ok version=<v>` or `state=updating target=<v>`, plus the last good version.
- **Update** (`-update <v>`): write `state=updating`, close the app, run the staged installer silently and wait, check the program folder against the manifest, then write `state=ok version=<v>`.
- **Launch** (default, from the cashier's Startup folder at logon and from the shortcut): if the journal says `updating`, re-run the target installer; otherwise, if the executable is missing or the folder does not match the manifest, re-run the last good installer. If the target installer fails, fall back to the last good one. Then start the app. Every action is timestamped in `launcher.log`.

**Runs:** for each runtime, a snapshot of the 1.0.0 install with 20 bills plus the launcher, with 1.0.0 and 1.0.1 staged (`r3-a-100L`, `r3-b-100L`, temporary). For each cut: boot the snapshot (throttled), put the launcher in the Startup folder, start `-update 1.0.1`, cut at the offset (measured from when the installer starts), boot with the throttle applied straight away, wait up to 1800 s for a new first-frame line, then run `--version` and `--check`, count the files and read `launcher.log`. One `CUT45` line per cut in the run log.

**Shortcuts:** the launcher is a PowerShell script, not the product's signed native launcher. There is no signature check on the staged installers (the updater's trust is the threat model's). The manifest is a file count and byte total, not per-file hashes.

**Harness faults fixed before the counted runs (G4.5):**
- The first setup ran no launcher (a PowerShell `"$update:"` parse error, as round 2's `"$v:"`); the broken snapshot was deleted and rebuilt.
- L0 run 1 is void. The Startup entry was created after logon, so Explorer's delayed Startup pass still ran it during the update, and the entry did not run after the cut. The entry now lives inside `r3-<rt>-100L`, and each cut waits for the launcher's logon launch to draw before it starts the update, as at a venue where the app is open at shift handover.
- L0 runs 2 and 3: the launcher repaired and started A, but the harness saw no frame. **The cut left NUL bytes where the app's unflushed `ready.txt` line had been, with no newline, so the next line joined it and the line count did not grow.** L0 run 3 was watched by hand (`g45-a-L0-run3-after-repair.png`: A 1.0.1 window on screen). The harness now counts the app's own markers (`first_frame_ms=`, `version=`, `integrity=`), not lines.
- The guest's epoch clock differs between snapshot boots and cold boots (about 10 h), so the apps' `ms=` stamps are not compared across boots.

**Results (G4.5, first set: the round 3 offsets).** Every counted cut: the app drew its first frame after the reboot with nobody acting, the store check was clean (20 bills, consistent), and the journal ended `state=ok version=1.0.1`. Evidence: `CUT45` lines in the run log, `evidence/g4/g45-<rt>-L<k>.png`.

| Runtime | Cuts | What the launcher did at the next logon | Boot to first frame |
|---|---|---|---|
| A | L0–L4 (35.5–186.5 s; MSI phase at the cut: `CostInitialize`, `InstallFinalize` ×3, `InstallInitialize`) | found `state=updating`, re-ran the 1.0.1 MSI (173–269 s), folder matched the 1.0.1 manifest, started the app | 628–722 s |
| A | L5–L9 (268.9–422.4 s) | **nothing to repair: the update had already finished** (MSI log `INSTALL. Return value 1`, journal `state=ok`). Under the launcher A's upgrade took 263–328 s, not the 459 s that set these offsets | 495–559 s |
| B | L0–L9 (15.8–287.2 s) | found `state=updating` every time, re-ran the 1.0.1 installer (197–228 s), folder matched, started the app | 681–721 s |

So B: **10 of 10 interrupted updates repaired.** A: 5 of 5 interrupted updates repaired, but only L4 fell inside the window that broke A in round 3 (0.59–0.83 D, about 168–237 s on this path), and the launcher did not record the folder's state before repairing, so these runs do not show which cuts left A broken.

**Supplementary A set (founder, 2026-10-18).** 10 more cuts for A: at least half inside 168–237 s, the rest spread over the measured launcher upgrade (D = 285 s, median of L5–L9), new seed 20261023 (`cut-offsets-a-g45.txt`: 6 of 10 inside the window). The launcher now logs `before repair: exe=… folder files=… bytes=…` when it finds an interrupted update. B stays as is. Labels M0–M9.

**Results (G4.5, supplementary A set, M0–M9; offsets `cut-offsets-a-g45.txt`).** 10 of 10 PASS: after every cut the launcher found `state=updating`, logged the folder it found, re-ran the 1.0.1 MSI, and A 1.0.1 drew its first frame with nobody acting; store check clean (20 bills, consistent) every time.

| Cut | Offset (s) | MSI phase at the cut | Folder before repair | Repair (s) | Boot to frame (s) |
|---|---|---|---|---|---|
| M0 | 23.2 | no action logged yet | 1.0.0 whole (201 files) | 278 | 743 |
| M1 | 106.8 | `InstallFinalize` (nested removal) | 1.0.0 whole | 279 | 741 |
| M2 | 159.1 | `InstallFinalize` | **empty: no app** | 194 | 666 |
| M3 | 171.5 (window) | `InstallValidate` (new install) | **empty** | 190 | 675 |
| M4 | 188.8 | `UnpublishFeatures` ended | **empty** | 171 | 650 |
| M5 | 192.5 (window) | nested `INSTALL` ended | **empty** | 180 | 670 |
| M6 | 203.0 (window) | nested `INSTALL` ended | **empty** | 166 | 657 |
| M7 | 212.7 (window) | nested `INSTALL` ended | **empty** | 182 | 671 |
| M8 | 228.3 (window) | nested `INSTALL` ended | **empty** | 193 | 691 |
| M9 | 244.9 | `InstallValidate` (new install) | **empty** | 162 | 648 |

**8 of 10 cuts (159.1–244.9 s) left A with no program at all**, the round 3 G4-F5 state, and the launcher brought every one back. Without the launcher, round 3 needed someone to re-run the installer.

**G4 summary with G4.5.**
- Default installers alone: neither A (4 of 10 broken) nor B (3 of 10 broken) keeps a runnable app through a power cut during an upgrade (G4-F5, G4-F8).
- **With the launcher outside the program folder: 30 of 30 counted cuts recovered with nobody acting** (A: 15 interrupted updates of which 8 had left no app; B: 10 interrupted updates; A L5–L9 landed after the update had finished and needed nothing). Store intact in every case.
- **MSI vs NSIS under the launcher:** no difference in the outcome. A's MSI exposes a no-app window of about 159–245 s of a 285 s upgrade; B's NSIS one of 192–244 s of 290 s (round 3). Repair takes 162–279 s (A) and 197–228 s (B); the counter is back 10.8–12.4 min after power returns on this disk (boot to first frame, cases that needed a repair).
- **Founder verdict (2026-10-19): G4 PASS for A and B, conditional on the launcher, with a faster recovery.** The launcher (journal written through to disk, staged installers and their manifests outside the program folder, repair at logon) is a requirement of the update story whichever runtime the ADR chooses, **and so is cutting the 10.8–12.4 min recovery** (mostly Windows' Startup delay of 6–8 min and the full reinstall): **target the counter back within 2 minutes of logon after power returns**, by a scheduled task at logon instead of the Startup folder and a repair of changed files only instead of a full reinstall, **measured on the physical 4 GB PC**. G4 rules out neither runtime.
- Earlier proposed reading: **G4 PASS for both runtimes, conditional on the launcher** — the launcher (journal written through to disk, staged installers and their manifests outside the program folder, repair at logon) becomes a requirement of the update story whichever runtime the ADR chooses. It does not separate A and B; G4-F1 (A's machine-wide entry), G4-F3/F7 (running app kept or closed) and the leftovers on uninstall still do.

**Launcher timing on the HDD-class disk (G4.5, observed):** Windows ran the Startup entry 6–8 min after the boot; the launcher's full folder check took 53 s (A, 201 files) and 13 s (B, 250 files) right after a boot, against the 3 s counter ceiling. The product launcher should do the full check only when the journal says `updating`, and a cheap check otherwise. The repair (re-running the installer) took 173–269 s (A) and 197–228 s (B), so after a cut during an update, the counter is back 8–12 min after power returns on this disk.

## Round 2 (started 2026-10-17): G3 Arabic RTL first

**Status:** G3 concluded 2026-10-17, **PASS for A and B** (founder). G4 (S36; followups S10, S11, S15, S16) and the tamper legs did not fit the 1-day cap (about 11:00 to 17:35): they move to **round 3**, before the runtime ADR. The VM was shut off and reverted to `clean-ssh2` at 17:35.
**Question:** do A and B render and accept Egyptian Arabic correctly on Windows 10 22H2 (S6/S46, desktop-note OQ22)? It **blocks the runtime ADR** (founder, 2026-10-17).
**Timebox:** the 1-day cap of `/prototype`, no waiver. Order: G3, then G4 (S36; followups S10, S11, S15, S16) and the tamper legs if the day allows, otherwise round 3.

**Hypothesis.** If the same Arabic test sheet (`apps/ARABIC-SHEET.md`) is built in A and B, then on the Windows 10 22H2 VM both will:
- shape Egyptian Arabic correctly and mirror the layout right to left;
- order mixed Arabic and Latin text, Arabic-Indic and Latin digits, negative amounts, percentages, a time and a phone number inside a sentence correctly;
- truncate a long name with the ellipsis at its logical end;
- render the receipt preview;
- accept Arabic 101 keyboard input in the name and price fields (caret, selection, deletion).

**Signal:** the founder reviews the screenshots and finds no shaping, ordering or mirroring defect, and input works. My reading of each screenshot is written down, but the founder's review decides. With no review, the verdict is NOT ASSESSED.

**Riskiest assumption (feasibility):** Compose Desktop's text stack (Skia, HarfBuzz via Skiko) handles RTL layout and bidirectional text input as well as Chromium.

**How to run** (G3):
- **A:** `apps/a-compose` with `--arabic` (bundled Noto Naskh Arabic 2.021, SIL OFL 1.1, from the host's `noto-fonts` package) or `--arabic-system` (the platform default font). Code: `src/main/kotlin/ArabicSheet.kt`. The MSI is built on the VM with `guest/build-a.ps1` (disposable layer).
- **B:** `apps/b-electron` with `--arabic` or `--arabic-system`. Code: `arabic.html`, `fonts/`. The installer is built on the host with `npx --no-install electron-builder --win --x64 --publish never` in `.cache/build-b`.
- The VM is reverted to `clean-ssh2`, the installer installed as `cashier`, the Arabic 101 layout added for `cashier`, the sheet started on the cashier's desktop, keystrokes sent with `virsh send-key`, and screenshots taken with `virsh screenshot`. Evidence goes to `evidence/g3/`.

**Shortcuts taken (G3):**
- No store, print or update.
- Only the Arabic 101 layout, no other IME.
- No high-DPI scaling.
- No Windows 11 leg (no Windows 11 VM).
- No accessibility or screen-reader check.
- Raw strings with no bidi control marks.
- Synthetic data only.
- Unsigned installers.

**Verdict (G3): PASS for A and B — founder, 2026-10-17, after reviewing the screenshots.** Both render and accept Egyptian Arabic correctly; OQ22 is closed for the runtime ADR. The differences (G3-F3 price-field direction, G3-F4 smoothing) are notes, not blockers. G3-F2 (how amounts display inside Arabic text) is an **open product rule**: decided in the counter and receipt spec, owner `localization-lead` (founder, 2026-10-17).

**What ran:** Windows 10 22H2 VM, 4 GB, throttled disk, `cashier` desktop, 1280×800 console.
- **A run 1** used a sheet with my own label setting (see G3-F1).
- **A run 2 and B** used the sheet as specified.
- **A's input test** was done on run 1. The input fields are the same code in run 2.
- Evidence: `evidence/g3/` (screenshots, `cmp-*` comparison crops, `run-log-20261017.txt`).
- Key screenshots:
  - A: `a2-naskh-01-initial.png`, `a2-system-01-initial.png`, `cmp-a-input-steps.png`.
  - B: `b-naskh-01-initial.png`, `b-system-01-initial.png`, `cmp-b-input-steps.png`.
  - Both: `cmp-rows-a-top-b-bottom.png`, `cmp-back-chevron-a-left-b-right.png`.

| Check | A (Compose Desktop) | B (Electron) |
|---|---|---|
| Arabic shaping (joining, lam-alef, bold title) | correct to my eye, Naskh and Windows UI font | correct to my eye, Naskh and Windows UI font |
| RTL layout mirroring (back at the right, columns reversed) | yes | yes |
| Bidi-mirrored glyph `‹` in an RTL run | shown as `›` | shown as `›` |
| Mixed rows (Latin-led names, brackets, `×2`, `4 لاعبين`) | same visual order as B on every row (run 2) | same as A |
| Arabic-Indic digits and the Arabic decimal separator | rendered | rendered |
| Long name, one line | truncated, ellipsis at the logical end (left) | truncated, ellipsis at the logical end (left) |
| Time and phone number in a sentence | `02:30` and `01012345678` in order | same |
| Receipt preview | rendered; in Naskh the last line falls below the 800 px screen (the sheet does not scroll) | rendered; the page scrolls |
| Arabic 101 typing in the name field | `شاي بالنعناع` shaped, caret at the logical end | same |
| Shift+Left at the logical end | no selection (visual caret movement) | same |
| Shift+Right ×3 | selects `ناع` | same |
| Delete, then Home + `ش` | `شاي بالنع`, then `ششاي بالنع` | same |
| Keypad `45.50` in the price field | Latin digits, aligned right | Latin digits, aligned left |
| Keypad `-12` in the price field | shown `12-` | shown `-12` |

**Findings (G3)** — each is an observation on the VM, indicative only:
- **G3-F1 (my sheet, not the runtime).** Run 1 set A's labels to follow their content (`TextDirection.Content`). Latin-led names became left-to-right paragraphs and sat at the left of their cell. With Compose's default (run 2), A orders every line exactly like B. Run 1's screenshots are kept (`a-naskh-0*` … `a-naskh-2*`).
- **G3-F2 (both runtimes, a product rule).** In a right-to-left paragraph, both apply the standard Unicode bidi result:
  - `120.00 EGP` shows as `EGP 120.00`;
  - `-45.50 ج.م` shows as `ج.م 45.50-`, with the minus on the right of the number;
  - `×2` shows as `2×`.

  The two runtimes don't differ here. Whether this is right for the counter and the receipt is the founder's call. If not, amounts need an explicit direction or isolation, or locale formatting: a localization rule for the spec, not a runtime choice.
- **G3-F3 (runtime default, configurable).** In an input field with no letter in it, A falls back to the layout's right-to-left direction, so `-12` shows as `12-`. B (`dir="auto"`) falls back to left-to-right and shows `-12`. Either can pin a price field's direction explicitly.
- **G3-F4 (rendering).** A draws text with grayscale antialiasing; B uses ClearType subpixel antialiasing (coloured edges in `cmp-back-chevron-…`). Legibility on a real 4 GB PC screen is for the founder to judge.
- **G3-F5 (my sheet).** Noto Naskh Arabic has no Latin glyphs. A falls back to a sans font; B falls back to the browser's default serif, because my CSS names no generic family. A product names its Latin font.
- **G3-F6 (harness).** Three things the harness had to work around:
  - Apps started from SSH (through `schtasks`) don't get the foreground, so typed keys were lost until a real Alt+Tab (`virsh send-key`) moved the focus. Compose drew a caret anyway, from its own focus state. A Notepad control proved the key path (`ctrl-notepad-02-alttab-typed.png`).
  - The first Alt+Shift showed a Windows "Input language switching" toast. The Arabic keyboard is now set as the cashier's default and takes effect at logon.
  - `cashier` cannot run `tasklist` over SSH; the admin account checks processes.
- **G3-F7 (timing, not gated).** On the first launch after the first re-logon, A took 195 s from process start to its sheet; on the next re-logon, 49.7 s, the same as round 1's cold start. Warm starts: about 1.6–2 s (A), about 5 s (B). B's per-user install took 435.5 s here, against 247 s in round 1, on the same throttled VM. One-off numbers; the physical 4 GB PC remains the measurement that counts.

**Not covered:** Windows 11 (no VM); high-DPI scaling; IMEs other than Arabic 101; screen readers; Arabic-Indic digit input from the keyboard (the keypad gives Latin digits).

## Timebox (founder decision, 2026-10-16)

The 1-day cap of `/prototype` applies. The studio's waiver exception covers only the top-ranked risk (sync, risk 1), and this spike tests risk 2, so **no waiver was given**. If round 1 is not demonstrable within one working day, the question is too large: stop, report where it stopped and split it. The 2-hour rule applies to each gate: more than 2 hours without a running result means reframe or drop the runtime.

**Round 1 = G0 to G2.** G3 (Arabic RTL), G4 (per-user update) and the tamper legs TS-03c, TS-05b and TS-06c run **later, as their own prototype, on the survivors only**.

## Hypothesis

> If the Kodeebo cashier app were built on A (Compose Multiplatform Desktop 1.12.2, JDK 21), B (Electron 44.8.0) or C (Tauri 2.12.x), then on a 4 GB Windows 10 22H2 Pro VM with a disk throttled to HDD class, at least one runtime will install per user as a standard user with no UAC prompt, open an encrypted SQLite store through its own binding and survive 100 hard kills with no corruption, deliver an ESC/POS stream through a Windows RAW queue whose captured bytes equal the golden stream, and finish "close bill" with an observed maximum under 3 seconds over 200 runs. We will know from the G0 to G2 tables in `evidence/`.

**Riskiest assumption (feasibility):** the three duties the research left unresearched on the JVM (an encrypted-SQLite binding, RAW printing, an updater: note M4/OQ8) and the Rust/WebView2 stack on a weak PC. G2 tests them first for each runtime.

## Gates (hard gates drop a runtime at its first failure)

| Gate | What runs | Pass signal | Drops the runtime? |
|---|---|---|---|
| G0 environment | The guest channel works (OpenSSH, key only). The disk throttle is set to 100 IOPS and 80 MiB/s (5400 rpm class: an assumption, not a sourced figure), applied live only, never written into the VM definition, and checked with DiskSpd: random 4K within ±20% of 100 IOPS (gated); sequential reported only (founder decision after G0-F2). Reverting to the baseline snapshot returns the VM to a known state (marker file). | All hold | No: stops the spike until fixed |
| G1 build + install | One identical "counter" screen per runtime is built on the VM (jpackage and MSVC need Windows). The VM is reverted; only the installer is copied in and run as the standard user `cashier`. | Per-user install, no UAC prompt, app starts and paints a 200-row list | Yes |
| G2 store + print | Encrypted SQLite through the runtime's binding (settings as the sync spike: rollback journal, `synchronous=FULL`, raw 256-bit key). 100 hard kills (`taskkill /F`) at random points inside the "close bill" transaction, each followed by `integrity_check` and a count check. "Close bill" renders the Arabic receipt as raster ESC/POS and writes it to a Windows RAW queue whose port feeds a capture sink. | 0 corruptions; integrity checks clean; sink bytes equal `docs/research/evidence/desktop-client-technology/p3-out/receipt_80mm_test_576dots.escpos.bin` (20,250 bytes) byte for byte; observed maximum of "close bill" under 3 s over 200 runs, with the first run after a reboot counted | Yes |

**Stop rule:** a runtime is dropped at its first failed hard gate. The spike stops if no runtime remains. A runtime that is dropped gets no further downloads.

**Measured, not gated** (no budget exists until `docs/architecture/perf-budgets.md` is drafted): cold start (first launch after a reboot, 10 runs), warm start (10 runs), idle memory of the whole process tree at 10 minutes (working set and private bytes), installer size, installed size, install time, and build effort (steps, tools, retries). Every number is stated with its conditions: VM, 4 GB, 2 vCPU, throttle values, Defender on, warm or cold.

**Indicative only:** these numbers come from a VM on a fast host. The research note requires cold start and memory on the physical 4 GB PC; nothing here replaces that. A hard gate failure is a finding. A pass is only "worked in the VM".

## Shortcuts taken (a PROCEED never inherits these silently)

- No auth, tenancy, billing, sync or N5; synthetic data only; no real customer data.
- The database key is a raw random 256-bit key stored beside the file. DPAPI/TPM wrapping (S11) is not tested.
- No code signing; the installers are unsigned test builds.
- No real printer. AI-330 and XP-80C runs stay `PENDING` (S20, S21, S23, S24). The capture sink proves that bytes pass the Windows spooler unchanged, not how a printer prints them.
- The windows-update service may be stopped during runs (recorded as a condition). Windows Defender stays on, as at a venue.

## Safety

- Guest channel: OpenSSH with a **dedicated key pair generated in `.keys/`** (gitignored). The founder's personal `~/.ssh` is never read or used: every `ssh` call uses `-F /dev/null -i .keys/spike_ed25519 -o IdentitiesOnly=yes` and a known-hosts file inside `.keys/`.
- Windows auto-logon for the test user `cashier` is for this test VM only. It must never appear in any venue install material, installer or documentation. The password is typed by the founder at a prompt inside the VM; the agent never sees it.
- No server listens on the host. The print sink, results collector and (in round 2) the update feed run inside the guest on 127.0.0.1. Files move with `scp`.
- Nothing is deployed. No secrets in the repository: `.keys/`, `.cache/` and raw run output are gitignored.

## Coordination

- The sync spike session (`prototypes/local-first-sync-spike/`) works in the same tree. I stage and commit only `prototypes/desktop-client-spike/**`, in two separate commands, never `git add -A`.
- Snapshots: `clean` is left untouched. **The working baseline is `clean-ssh2`** (chain `clean` → `clean-ssh` → `clean-ssh2`). `clean-ssh` (OpenSSH + `cashier` auto-logon) is kept but has a broken `cashier` login (G0-F3) — do not use it. Runs restore `clean-ssh2`; **the sync spike's phase 4 should use `clean-ssh2` too.** After every boot the disk throttle must be re-applied (it is live-only).
- `production/session-state/active.md`: my notes live in the `### /prototype desktop-client-spike` block under Notes. The top CHECKPOINT region belongs to the sync spike and is not changed here.

## Downloads (approved by the founder; sizes from header-only requests, 2026-10-16)

Each file is fetched once on the host into its own directory under `.cache/` (gitignored), its SHA-256 is recorded in `evidence/downloads.txt` and checked against the publisher's digest where one exists, then copied into the guest with `scp`. A runtime that is dropped gets no further downloads. Ask first: the VS Build Tools C++ payload (several GB) and any step that would pass 2 GB.

| File | Size | For |
|---|---|---|
| Temurin 21 JDK zip (Adoptium, latest GA) | 195.6 MB | A |
| Gradle 9.7.0 bin zip | 143.3 MB | A |
| WiX Toolset 3.14 binaries zip | 39.4 MB | A (MSI) |
| Node 24.22.0 x64 MSI | 31.8 MB | B, C |
| Electron 44.8.0 win32-x64 zip | 151.2 MB | B |
| rustup-init.exe (x86_64 msvc) | 12.1 MB | C |
| vs_BuildTools.exe bootstrapper | 4.3 MB | C (payload: ask first) |
| WebView2 Evergreen bootstrapper / standalone x64 | 1.8 MB / 204.2 MB | C, only if the base Windows lacks the runtime |
| DiskSpd.zip | 3.4 MB | G0 throttle check |

Sizes known only after resolution (Maven/npm/crates dependencies, the Rust toolchain) are reported after each step.

## How to run

Needs: libvirt access to `qemu:///system` (VM `kodeebo-win10`), the key pair in `.keys/` and the pinned host key in `.keys/known_hosts` (both gitignored; regenerate the key and re-run `guest/setup-ssh.ps1` on a fresh VM if they are missing).

```bash
cd prototypes/desktop-client-spike
virsh -c qemu:///system snapshot-revert kodeebo-win10 clean-ssh2      # known state (VM must be shut off)
virsh -c qemu:///system start kodeebo-win10
tools/vm.sh ssh admin whoami                                           # wait until it answers (~10 s)
virsh -c qemu:///system blkdeviotune kodeebo-win10 sda --live --total-iops-sec 100 --total-bytes-sec 83886080
tools/vm.sh ssh cashier whoami                                         # standard user, auto-logged on
```

`tools/vm.sh` never reads `~/.ssh`: it passes `-F /dev/null`, the dedicated key and the spike's own known-hosts file with strict checking. Guest-side checks are PowerShell files in `guest/`, copied with `tools/vm.sh put` and run with `powershell -NoProfile -ExecutionPolicy Bypass -File` (quoting PowerShell through SSH and cmd breaks).

## Findings

### G0 (2026-10-16): PASS — evidence/g0-guest-channel.txt, evidence/g0-throttle-revert.txt

- **VM baseline:** Windows 10 Pro 22H2 build 19045.2965 (2023-05 image, no later cumulative updates; `wuauserv` stopped). Edge and WebView2 Runtime are **155.0.4283.45**: Edge's own updater ran while the VM was online, so a "base ISO" PC still gets a current WebView2. Defender on. TPM 2.0 present (emulated). UAC on (standard users get a credential prompt).
- **G0-F1:** the Windows 10 OpenSSH capability is **OpenSSH 7.7**, which ignores `KbdInteractiveAuthentication no`; keyboard-interactive stayed on until `ChallengeResponseAuthentication no` was added.
- **G0-F2:** QEMU's IOPS cap counts each request whatever its size, and the guest sends large I/O as ~128 KiB requests. At 100 IOPS, sequential I/O is ~12 MiB/s instead of 80. The founder kept 100 IOPS + 80 MiB/s: random I/O is HDD-like; **sequential-heavy numbers (start-up, install) are an upper bound**.
- **G0-F3:** a `Match User cashier` → `AuthorizedKeysFile` rule was applied on only ~60% of connections by OpenSSH 7.7 for Windows; the key moved to `C:\Users\cashier\.ssh\authorized_keys`, after which 30 of 30 logins worked. Baseline re-saved as `clean-ssh2`.
- **Snapshot revert works** with libvirt 12.8.0 on the external snapshot chain (top overlay discarded, marker gone). The emulated TPM state and UEFI NVRAM are not part of the disk snapshot.

### G1 and G2 for A and B (2026-10-17) — evidence/g2-a/, evidence/g2-b/

All on the 4 GB / 2 vCPU VM, Windows 10 Pro 22H2 build 19045.2965, Defender on, disk throttled to 100 IOPS + 80 MiB/s (sequential effectively ~12 MiB/s, G0-F2), installed and run as the standard user `cashier`. **Indicative only: a VM on a fast host, not the physical 4 GB PC.**

| | A — Compose Multiplatform Desktop 1.12.2 (JDK 21 jlink, sqlite-jdbc 3.53.4.0 SQLite3MC, JNA 5.19.1) | B — Electron 44.8.0 (better-sqlite3-multiple-ciphers 13.0.3, koffi 2.16.3) |
|---|---|---|
| **G1** installer | per-user MSI (jpackage + WiX 3.11 that the Compose plugin downloads itself), 72.6 MB; `MSI_LUA: … no elevation required`; **uninstall entry under HKLM** although the files go to `%LOCALAPPDATA%` | per-user NSIS (`oneClick`, `perMachine:false`), 129 MB; uninstall entry under HKCU |
| install time (throttled) / installed size | 63 s / 136 MB | **247 s / 429 MB** (Electron 369 MB; 60 MB of it are native modules for other platforms, trimmable to ~375 MB) |
| first-ever launch → first frame (throttled) | 12.7 s | 8.8 s |
| **G1 verdict** | **PASS** | **PASS** |
| G2 RAW print: 20 runs, sink vs golden | 20/20 byte-identical, 20,250 bytes, same SHA-256 (and 3/3 on the rebuilt app) | 20/20 byte-identical, 20,250 bytes, same SHA-256 |
| G2 kill test: 100 × `taskkill /F` mid-transaction, then `integrity_check` + consistency | **0 of 100** corrupt or inconsistent (≈1,150 bills at the end) | **0 of 100** corrupt or inconsistent |
| close bill, warm, 200 runs: p50 / p95 / max | 201 / 244 / 390 ms (a repeat run had one 2.68 s outlier: `db` 2.64 s on run 4) | 201 / 247 / 392 ms |
| **after reboot**, no warm-up: native layer load before 1st close / 1st close / max of 200 | 5.4 s (JNA) / 0.51 s / 0.52 s | 2.4 s (koffi) / 1.45 s / 1.45 s |
| **after reboot**, with warm-up: native load / warm-up (store open · print path · dummy tx) / 1st close / max | 5.3 s / 3.08 s (2.95 · 0.11 · 0.02) / 0.66 s / 0.66 s | 2.3–3.2 s / 2.6–3.2 s (store open ~2.6–3.2 s) / 0.87 s / 0.87–0.88 s |
| **G2 verdict (3 s ceiling)** | **PASS** on the rebuilt app (first build: 7.1 s, see A-F3) | **PASS** |
| *Measured, not gated:* first GUI launch after reboot → first frame (reboot, logon, +120 s; 1 run each, not the planned 10) | **49.0 s** | **56.7 s** |
| warm GUI launch → first frame (5 runs) | 0.95–1.01 s | 0.26–0.29 s |
| idle at 10 min: processes / working set / private bytes | 1 / 14.7 MB / 183.5 MB | 4 / 24.4 MB / 92.6 MB |

The cold GUI starts (49 s and 57 s) are **upper bounds**: the throttle pages the runtime in at ~2 MB/s (IOPS-bound, G0-F2), much slower than a real HDD reads sequentially. They still show what the start-up budget must cover on a weak PC, and that both runtimes need a physical-PC measurement before `perf-budgets.md` sets a start-up number.

**Findings**
- **A-F1 (store unreadable after the first run).** `DriverManager.getConnection()` then `PRAGMA hexkey` creates a store that every later process fails to open (`SQLITE_NOTADB`). The key must be applied by the driver while it opens the connection: `SQLiteMCConfig.Builder().withHexKey(bytes).build().createConnection(url)`. Verified: write, reopen, write, reopen → integrity ok, consistent.
- **A-F2 (blocking dialog).** An exception escaping `main()` makes the jpackage launcher show a modal "Failed to launch JVM" box: on an unattended counter PC the app would wait for someone to press OK. Every headless mode now catches its errors.
- **A-F3 (the 7.1 s first sale after reboot).** In the first build, JNA's native library was loaded lazily inside the first print (print 6.57 s of the 7.10 s). Loading the native layer before the first sale moves 5.3–5.4 s into start-up; the first close is then 0.5–0.7 s. JNA unpacks its DLL into `%TEMP%` on first use in every process; koffi ships its DLL unpacked in the install folder and loads in 2.3–3.2 s cold, 5 ms warm.
- **Warm-up (founder question 2):** it moves native loading and store opening (2.6–3.2 s) into the start-up budget. What it does not move: the **first print job after boot** still costs 0.3–0.8 s (`StartDocPrinter` 330–540 ms, B's first `ClosePrinter` 789 ms without warm-up), because `OpenPrinter` alone does not warm the spooler. A production warm-up would need a dummy job or an earlier first print.
- **Sequential reading (founder question 1): not answerable cleanly here.** Inside the app, the first close reads 29–53 KB (≈ 2–4 ms at 12 MiB/s): **the sale itself is not disk-bound.** The multi-second start-up phases happen before in-app counters exist, and process counters miss memory-mapped EXE/DLL paging (B showed 1 MB "read"). The disk-level counter saw ~61 MB read while B started and ran, arriving at ~2 MB/s, i.e. **bound by the 100 IOPS cap, not by sequential speed**, and mixed with Windows' own post-reboot reads (prefetch, Defender), which carry on past the 120 s settle. Separating the app's paging from that needs a per-process disk trace (Windows Performance Recorder) on the physical 4 GB PC: not researched or downloaded yet.
- **Harness findings:** an SSH session is not an interactive logon (msiexec returns 1601; GUI apps get no desktop), so everything on `cashier`'s desktop runs through `schtasks /IT` (`guest/run-interactive.ps1`); for a standard user the ScheduledTasks cmdlets fail with "Access denied" over WMI; `echo %ERRORLEVEL%> f` writes nothing (redirection of handle 0); PowerShell progress bars and stderr version banners abort scripts over SSH.

### Round 1b (C, Tauri 2): not run — founder decision, 2026-10-17

B already covers the web shell the research note asked for (A plus at least one of B or C), and C's main advantage, a smaller install using the PC's WebView2, matters less with A installing at 136 MB. Printer status reading (paper out, cover open) is a runtime-neutral requirement, so instead of building C, the next round adds **S50: a `DLE EOT` status-read test for A and B** on the real-printer day, when the founder borrows the U.POS AI-330 and Xprinter XP-80C (full row in `docs/research/desktop-client-technology.md` § 9 Spikes). The harness is runtime-neutral (`apps/SPEC.md`, `tools/g2.sh`), so C can still be added later if A and B both fail a later gate.

### Next rounds

**Order (founder, 2026-10-17): everything the desktop runtime ADR needs comes first.**

1. **Round 2 (its own prototype run, A and B; 1-day cap; 2026-10-17):** G3 Arabic RTL (S6/S46). **Done: PASS for A and B** (founder, 2026-10-17; note OQ22 closed).
2. **Updater follow-up** (Advanced Installer, InstallAnywhere): done as part 6 of `docs/research/desktop-client-adr-followups.md`. Its Q-6.1 is open.
3. **Round 3 (2026-10-18): G4 per-user update** (S36; followups S10 core, S11, S15, S16). **Round 4:** M1 migration under power cut and the tamper legs TS-03c, TS-05b, TS-06c (a leg the sync spike also needs runs once on the shared store; both spikes cite the same evidence). Then **the sync spike's phases 4 and 5** on the same VM (founder correction, 2026-10-18).
4. **Runtime ADR** (`/architecture-decision`), after the sync spike's phases 4 and 5 report.
5. **At the very end, but before their first stories:**
   - **Phone spikes** on the founder's Honor 400 Pro (followups S32, then S33 only after S32 reports). They come before the owner-app stories; `/setup-stack` records the owner app as "PWA, provisional until S32/S33".
   - **Real-printer day** (the founder borrows the printers), before the printing stories: S50 status read from A and B; the hardware legs of S20 (vendor driver and Generic / Text Only queue), S23 (drawer kick on pin 2 / pin 5, including offline and paper-out), S24 (Arabic raster on paper) and S29 (power-off, paper-out and unplug mid-job without losing or duplicating a receipt).
- **Physical 4 GB PC** (no date set): cold-start and memory numbers that count, with a per-process disk trace for the sequential-read question.

### Answered from the research evidence, confirmed in G2

- **Confirmed on the real sink (G2):** every print from A and B arrived as exactly 20,250 bytes with the golden file's SHA-256. No extra byte was added by the runtime, the spooler, the Generic / Text Only driver or the file port, and no status query reached the sink.
- **The 6-byte gap between the golden file (20,250 bytes) and the 20,256 bytes the research's fake printer received (F226).** The golden stream is complete. Its 20,250 bytes are `ESC @` (2) + `GS v 0` header (8) + raster 72 bytes × 281 rows (20,232) + `LF LF LF` (3) + `ESC p 00 19 fa` drawer pulse (5). The other 6 bytes are two real-time status queries, `DLE EOT 1` (`10 04 01`) and `DLE EOT 4` (`10 04 04`), 3 bytes each. The research test (`fake_tcp_printer.py`) sent them after the receipt to exercise its reply loop (its own output prints `sent len(data) + 6`), and the fake printer records every byte it receives, so they are in its 20,256. They are not part of the receipt.

## Evidence index

`evidence/` holds run output (`.txt`, not `.out`: the repository ignores `*.out`).
