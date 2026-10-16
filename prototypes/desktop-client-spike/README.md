<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: Can Compose Multiplatform Desktop (A), Electron (B) or Tauri 2 (C) do the cashier counter's duties on a 4 GB Windows 10 reference VM? -->
<!-- Date: 2026-10-16 -->

# Prototype: desktop client spike (round 1)

**Status:** in-progress. Plan approved by the founder 2026-10-16 (with changes below). **G0 PASS** (2026-10-16, evidence/g0-*.txt). G1 next.
**Risk tested:** `design/product-brief.md` risk 2: "A desktop technology runs well, prints and opens the drawer on Windows 10/11."
**Plan:** `docs/research/desktop-client-technology.md` § 9 (Spikes): S1/S40, S7/S43, S10, S20 and the phase 1 text. Round 1 covers the part of them listed under "Gates" below.
**Path:** code spike (feasibility). Throwaway: nothing here is imported by production code, and if a runtime is chosen, its production code is written from scratch (`.claude/rules/prototype-code.md`). The spike does **not** choose the stack. It feeds the runtime ADR.

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

### Answered from the research evidence (to confirm in G2)

- **The 6-byte gap between the golden file (20,250 bytes) and the 20,256 bytes the research's fake printer received (F226).** The golden stream is complete. Its 20,250 bytes are `ESC @` (2) + `GS v 0` header (8) + raster 72 bytes × 281 rows (20,232) + `LF LF LF` (3) + `ESC p 00 19 fa` drawer pulse (5). The other 6 bytes are two real-time status queries, `DLE EOT 1` (`10 04 01`) and `DLE EOT 4` (`10 04 04`), 3 bytes each. The research test (`fake_tcp_printer.py`) sent them after the receipt to exercise its reply loop (its own output prints `sent len(data) + 6`), and the fake printer records every byte it receives, so they are in its 20,256. They are not part of the receipt.
- **G2 must confirm it on the real sink**, not only compare files: the sink must receive exactly 20,250 bytes, with the same SHA-256 as the golden file. A Windows RAW queue is write-oriented, so no `DLE EOT` query is expected to reach the sink. If any extra byte appears, G2 records what it is and which layer added it (runtime, spooler, driver or port).

## Evidence index

`evidence/` holds run output (`.txt`, not `.out`: the repository ignores `*.out`).
