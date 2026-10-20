# Runbook: Release ceremony

> **Status: DESIGN-TIME.** Written from ADR-0009 before the ceremony scripts exist. Every command shown as
> `<PLACEHOLDER: …>` is replaced with the real command, its exact expected output and its failure output
> when the scripts are written (spikes S46 and S48). Until then this runbook cannot be run.
> **Source:** `docs/architecture/adr-0009-deploy-and-build-tooling.md` (Accepted 2026-10-20) — § 1, § 2, § 3,
> § 3a, § 4a–4c, Key Interfaces, and its two amendment notes of 2026-10-20 (no admin-key host step before the
> agent-account move; build containment). Threat models: `tenant-isolation.md` TB7, TB8 (T8.10, T8.11), M49,
> M63, M64, M66–M68, R-8, R-9, R-10; `staff-auth.md` TB10, T6.12, M26 (escrow custody), M28.
> **Owner:** the founder (Kamel Mohamed) runs it. The AI agent writes it and the scripts; it never runs them.
> **Review rule (founder, 2026-10-20):** the runbook is treated like the ceremony scripts. The founder reads it
> **in full before the first ceremony**; every later change reaches the founder **as a git diff** and is read
> before the next ceremony. The runbook is guidance only: the ceremony runs the reviewed scripts from the
> signing USB, and the trusted script hash lives **off-machine**, never in this file or the repository.
> **Created:** 2026-10-20 · **Last reviewed by the founder:** not yet

## 1. What the ceremony is

Every release is built, scanned, signed and sent **by the founder**, with **no AI agent session running**.
The AI agent has no VPS key, account or sudo entry (ADR-0009 T2), so this ceremony is the only way a release
reaches production. It runs in a **split order**, so that code the agent wrote (Gradle scripts, plugins,
tests, the Dockerfile, dependencies) **never runs while the signing USB is plugged in**:

| Step | USB | What happens |
|---|---|---|
| 1. Prepare | in, then **out** | clean-session check → USB in → off-machine hash check → scripts copied to a root-owned read-only place → USB out |
| 2. Build and scan | **absent** | under the **build account** on rootless Docker: **fetch** (network on: verified dependencies, base images by digest) → **build** (no network: Gradle offline with the dependency cache read-only, image build) → `docker save` → scanners → SBOMs |
| 3. Record | absent | image digest, tarball and SBOM hashes written down |
| 4. Sign and send | in, then **out** | **reboot** → clean-session check → USB in → hash re-check → manifest shown field by field → sign → send → USB out |

The signing USB holds: the manifest signing key, the founder deploy key, the founder admin key (each encrypted
with a passphrase typed by hand) and the reviewed copy of the ceremony scripts. It is separate from the
server-key escrow USB and from Bitwarden.

Three OS accounts take part, and they stay apart (ADR-0009 amendment note, 2026-10-20): the **founder's account**
checks hashes, signs and sends; a dedicated **build account** (neither the founder's nor the agent's) runs the
build and the scanners on a **rootless Docker** runtime, so an escape from a build container lands as an
unprivileged user, never root; the **agent's account** takes no part and must have nothing running. The founder
account's rootful Docker daemon is not used in the ceremony.

## 2. Rules that hold at every step

- **Never** run a ceremony script from the repository; only the reviewed copy from the USB.
- **Never** type the passphrase anywhere but the prompt of the signing or SSH command; never paste it, never
  pass it as an argument.
- **Never** load the deploy or admin key into an `ssh-agent`.
- **Never** sign in to the VPS provider account or the Tailscale admin account from the workstation browser;
  only from the phone, with 2FA.
- **Never** use `ssh-keygen -Y check-novalidate` to decide anything (it accepted an unauthorised signer, F410).
- **Never** continue after a mismatch or a status other than `ok`; follow the failure line for that step.
- **Never** copy VPS output into a file, chat or session the agent reads (tenant text can steer an agent;
  what the agent reads goes to Anthropic).
- **Never** run `docker compose down -v` or prune volumes on the VPS.
- **USB out** as soon as the step that needs it is done.
- **No ceremony and no admin-key host step before the agent-account move** (founder, 2026-10-20).
- **Never** run build code as the founder's account or on the rootful Docker daemon; only as the build account
  on rootless Docker.

## 3. Preconditions before the first ceremony

None of these is met today. The first ceremony waits for all of them.

| # | Precondition | Source | State |
|---|---|---|---|
| P1 | The agent-account move is done: the agent has its own account, not in `docker`, `wheel` or `sudo`, with managed settings. No ceremony **and no admin-key host step** runs before it, so P4 comes after P1 | ADR-0009 § 5 and amendment note, TI M67 | PENDING |
| P2 | Ceremony scripts written by the agent, reviewed by the founder as a git diff, copied to the USB, hash recorded off-machine (§ 4) | ADR-0009 § 4c | PENDING (S46) |
| P3 | Clean-session check proven to detect a process, user unit, timer, lingering, cron and autostart entry of the agent's, the founder's and the build account, and to list system units and timers | ADR-0009 § 4c and amendment note | PENDING (S48) |
| P4 | Host set-up done over the admin key, **after P1**: `deploy` account with the forced command, one sudo entry, `allowed_signers`, gate state initialised, Compose and nginx files, secret files (0400, owner = consuming UID), tailnet ACL limiting SSH to the founder machine | ADR-0009 § 2, § 3a | PENDING (S33 re-checks sshd and the ACL) |
| P5 | Provider snapshots and backups confirmed to exclude the secret files (checked from the phone) | ADR-0009 § 3a | PENDING |
| P6 | First-deploy checklist passed, including the Docker Engine advisories (must-pass) | ADR-0009 § 6 | PENDING |
| P7 | `catalogue_rt` grants confirmed (S58); CycloneDX plugin on Gradle 9.7.0 (S23) | ADR-0009 § 4a, § 4b | PENDING |
| P8 | Before the first privileged migration only: the privileged procedure proven (S57) | ADR-0009 § 4a | PENDING |
| P9 | The founder has read this runbook in full | review rule | PENDING |
| P10 | Build account set up after P1: its own OS account, rootless Docker, its Gradle and Docker caches first filled after the move (dated record, with the download size); the founder machine's container engine passes the same advisory check as the VPS (Decision 6) | ADR-0009 amendment note, TI M53, M66 | PENDING |
| P11 | S59 passed: an image built and saved under rootless Docker loads on the VPS with the manifest's digest, and a JAR changed in the dependency cache fails the offline build. If the second part fails, the dependency cache is fresh for every release and § 7 changes accordingly | ADR-0009 amendment note | PENDING (S59) |

## 4. Before the day: reviews and the off-machine hash

**4.1 Review what is being released.** The founder reviews the commit to release as a git diff, in particular
build files (Gradle scripts and plugins, version catalogue, `gradle/verification-metadata.xml`, lockfiles),
the Dockerfile, dependency bumps and migrations. This review is the trust that remains after everything else
(ADR-0009 § 1).
- **On doubt:** do not release. Ask for the change to be explained or split; a dependency bump that cannot be
  explained is not released.

**4.2 When a ceremony script or this runbook changed:**

| Command | What it does | Expected output | On failure |
|---|---|---|---|
| `git diff <last reviewed commit>..<new commit> -- <PLACEHOLDER: ceremony script directory> docs/runbooks/release-ceremony.md` | shows every change since the last reviewed version | the diff the founder reads in full | anything unexplained → do not approve; nothing is copied |
| `<PLACEHOLDER: copy the reviewed scripts to the USB>` (no agent session running; § 5 check first) | puts the reviewed copy on the USB | the file list | copy error → re-copy; never edit on the USB |
| `<PLACEHOLDER: compute the SHA-256 of the USB copy>` | the hash the ceremony will check | one hex value | — |

The founder writes that hash **on paper or in the Bitwarden app on the phone — never in the Bitwarden browser
extension on the workstation.** The repository never holds the trusted hash.

## 5. The clean-session check

Run at step 1, at step 4 (after the required reboot), and at the start of every host-step session (§ 10).

| Command | What it does | Expected output | On failure |
|---|---|---|---|
| **Reboot** and log in at a **text console** as the founder — **required before step 4**; preferred before step 1 and host steps | ends every process the build steps started, including the rootless Docker daemon and anything an escape left in memory, so the check only has to find persistence | — | — |
| `<PLACEHOLDER: clean-session check, run from the USB copy at step 4 and in host steps; at step 1 from the read-only copy of the previous ceremony or the USB — decided in S48>` | looks for any process of the agent's account or the build account, any Claude Code process under any account, user units, timers, lingering, cron and autostart entries of the agent's, the founder's and the build account, and lists the system units and timers | `<PLACEHOLDER: e.g. clean>` | **Not clean:** do not insert the USB. Reboot into a text console and re-run. Still not clean: stop the ceremony for the day, find the cause with the USB absent, and treat an unexplained process, unit or timer as a possible compromise (§ 11). A reboot does not undo an escape that reached root and persisted; that is why the build runs rootless. |

## 6. Step 1 — Prepare (USB in, then out)

| # | Command | What it does | Expected output | On failure |
|---|---|---|---|---|
| 1.1 | § 5 clean-session check | — | clean | see § 5 |
| 1.2 | Insert the USB; `<PLACEHOLDER: mount read-only>` | — | mounted | does not mount or asks to format → **do not format**; USB out; § 11.1 (broken USB) |
| 1.3 | `<PLACEHOLDER: USB hash check — computes the SHA-256 of the USB scripts and asks the founder to type the off-machine value>` | compares the USB copy with the reviewed hash | `<PLACEHOLDER: e.g. hash ok>` | **Mismatch:** stop. USB out. Run nothing from it. Compare the USB copy with the last reviewed commit, with the USB on a machine with no agent session. Never "fix" it by writing down the new hash without a fresh git-diff review. Unexplained change → § 11. |
| 1.4 | `<PLACEHOLDER: copy the scripts to a root-owned, read-only location>` | the build steps run from this copy, not from the USB | the target path | error → stop; USB out |
| 1.5 | `<PLACEHOLDER: unmount>`; **USB out** | — | unmounted | will not unmount → find what holds it with the USB still in; do not start step 2 while it is in |

## 7. Step 2 — Build and scan (USB absent, build account)

Everything in this step runs **as the build account on its rootless Docker runtime**, never as the founder's
account or on the rootful daemon. Build containers see only the checkout and the dependency cache: no home
directory, no USB, no Docker socket. The Gradle container gets the scanner flags: non-root `--user`,
`--cap-drop ALL`, `--security-opt no-new-privileges`, read-only root, a bounded `/tmp` tmpfs, the default seccomp
profile, and pids, memory and CPU limits. The step is split in two: **fetch** (2.3–2.4) is the only part with
network; **build** (2.5–2.6) runs with none. The build account's caches were first filled after the
agent-account move (P10); the one-time download is measured then and recorded in ADR-0009 (PENDING).

| # | Command | What it does | Expected output | On failure |
|---|---|---|---|---|
| 2.1 | `<PLACEHOLDER: refuse to start while the USB block device is present>` | guards the split order; a missing mount does not prove the USB is out | `<PLACEHOLDER>` | USB present → unmount and remove it, then start step 2 again |
| 2.2 | `<PLACEHOLDER: switch to the build account; fresh checkout of the reviewed commit>` | builds exactly what was reviewed | the commit id, compared by the founder with the one reviewed in § 4.1 | different commit → stop |
| 2.3 | **Fetch, network on:** `<PLACEHOLDER: Gradle resolves dependencies under strict verification into the dependency cache; only caches/modules-2 is kept; a fresh GRADLE_USER_HOME otherwise>` | downloads only verified dependencies | resolution success | **verification failure** → stop; a dependency without a verification entry is reviewed as a diff, verification is **never** turned off |
| 2.4 | **Fetch, network on:** `<PLACEHOLDER: pull the base images by digest from the official repository; show tag→digest>` | the image base, by content address | tag→digest per base image, which the founder checks against the reviewed Dockerfile | digest differs, or the base is not pinned → stop |
| 2.5 | **Build, `--network none`:** `<PLACEHOLDER: Gradle --offline build and tests in the throwaway container; the dependency cache mounted read-only; a fresh GRADLE_USER_HOME on tmpfs (no init.d, no user gradle.properties); no --init-script; build cache and configuration cache off>` | builds and tests the application with nothing fetched | build success | a dependency missing offline → stop (the fetch step is incomplete; never turn the network on here). A changed cached JAR fails verification (S59) → stop: the cache may be poisoned; rebuild it from empty in the fetch step and treat an unexplained change as § 11. Test failure → stop; no release |
| 2.6 | **Build, `--network none`:** `<PLACEHOLDER: image build on the build account's rootless Docker from the pinned base; the Dockerfile copies the built artifacts and installs no packages>` | builds the image | the image id | the build reaches for the network → stop; the Dockerfile is wrong |
| 2.7 | `<PLACEHOLDER: docker save to a tarball>` | the one artifact that is sent | the tarball path | — |
| 2.8 | trivy-db update, in the scanner container with network on (at most once per release and never more than once a day; about 135 MB). Flags for every scanner step: `--pull=never --rm --read-only --cap-drop ALL --security-opt no-new-privileges --user 65534:65534`, pids/memory/CPU limits, a bounded `/tmp` tmpfs (`rw,noexec,nosuid,nodev`), `HOME=/tmp`, the Trivy binary mounted read-only, the cache read-write. Command inside: `trivy image --download-db-only --db-repository ghcr.io/aquasecurity/trivy-db:2 --skip-version-check --disable-telemetry` | refreshes the vulnerability database | DB downloaded; the DB manifest digest recorded | download fails → stop and retry later; **never** point `--db-repository` at another mirror; never scan with the network on |
| 2.9 | Trivy scan, scanner container with `--network none`, DB cache read-only at `/cache`, `TRIVY_CACHE_DIR=/cache`, tarball read-only: `trivy image --input <tar> --cache-backend memory --pkg-types os --scanners vuln --skip-db-update --skip-java-db-update --offline-scan --skip-version-check --disable-telemetry` | OS-package scan of the image | counts by severity | findings at or above the configured severity → stop; release only after a fix or a reviewed ignore entry (git diff). **Scan did not run → `not_run`, never a pass → stop** |
| 2.10 | `<PLACEHOLDER: image SBOM (Trivy, CycloneDX) in the scanner container>` | image inventory | SBOM file | failure → stop |
| 2.11 | `<PLACEHOLDER: application SBOM, CycloneDX Gradle plugin 3.5.1 (after S23), in the offline build container>` | library inventory | SBOM file | failure → stop |
| 2.12 | `<PLACEHOLDER: OSV-Scanner 2.6.0 on gradle.lockfile, scanner container, network on for its lookup>` | dependency advisories | result summary | findings at threshold → as 2.9; GO-2026-4919 is a documented false positive in the ignore file |
| 2.13 | `<PLACEHOLDER: stop the build account's rootless Docker daemon and log the build account out>` | nothing from the build stays running into step 4 | — | will not stop → it ends at the reboot (§ 9 row 4.0); note it, and treat it as § 11 if the reboot check then finds it |

## 8. Step 3 — Record (USB absent)

| # | Command | What it does | Expected output | On failure |
|---|---|---|---|---|
| 3.1 | `<PLACEHOLDER: record image digest, tarball SHA-256, both SBOM SHA-256s, scan summary>` | the values the manifest will carry | one line each | a value missing → stop |
| 3.2 | `<PLACEHOLDER: expected compose_sha256 and nginx_conf_sha256 — source decided when the scripts are written (ADR-0009 does not say where the ceremony reads them; e.g. the founder's record of the last admin-key host change)>` | must equal the host files, or the VPS refuses (`config_mismatch`) | two hex values | unknown → run a host-step session (§ 10) to read them, or stop |
| 3.3 | `<PLACEHOLDER: expected key_fingerprint.<label> values — source decided when the scripts are written (the off-host record made at key creation or rotation; never computed from a key on this machine)>` | the backend refuses to start on a mismatch (`fingerprint_mismatch`) | one value per server key | unknown → stop |
| 3.4 | `<PLACEHOLDER: next release number N and previous manifest SHA-256, from the off-host deploy record>` | the replay gate accepts only N = last + 1, chained | N and a hex value | unclear → stop; never guess N |

## 9. Step 4 — Sign and send (USB in, then out)

| # | Command | What it does | Expected output | On failure |
|---|---|---|---|---|
| 4.0 | **Reboot**; log in at a text console as the founder (required) | ends everything steps 2–3 started | — | — |
| 4.1 | § 5 clean-session check | — | clean | see § 5 |
| 4.2 | Insert the USB; `<PLACEHOLDER: mount>` | — | mounted | § 6 row 1.2 |
| 4.3 | `<PLACEHOLDER: USB hash re-check — the founder types the off-machine value again>` | immediately before display and signing | `<PLACEHOLDER>` | mismatch → as § 6 row 1.3 |
| 4.4 | `<PLACEHOLDER: build the manifest and display every field and its SHA-256>` — fields in order: `release`, `previous_manifest_sha256`, `not_after` (from the configured validity), `git_commit`, `image_digest`, `image_tarball_sha256`, `migrations`, `key_fingerprint.<label>` (one per server key), `compose_sha256`, `nginx_conf_sha256`, `sbom_app_sha256`, `sbom_image_sha256`, `scan` | the founder checks each field against § 4.1 and § 8; the signature covers bytes the founder cannot otherwise see | the field list and one SHA-256 | **any field the founder cannot confirm → do not sign.** Unexpected migration id → stop; it would be refused anyway (`unreviewed_migration`) |
| 4.5 | `ssh-keygen -Y sign -f <USB path to the signing key> -n kodeebo-release-manifest-v1 <manifest file>` — passphrase **typed by hand** at its prompt | signs the manifest (F403; behaviour checked in S40/S40v) | a `<manifest file>.sig` beside it | wrong passphrase → retype; never paste. Other error → stop |
| 4.6 | `ssh-keygen -Y verify -f <USB copy of allowed_signers> -I founder-signing@kodeebo -n kodeebo-release-manifest-v1 -s <manifest file>.sig < <manifest file>` | local check before sending (the VPS repeats it) | `<PLACEHOLDER: exact "Good … signature" line from S46>` and exit 0 | non-zero → do not send; stop |
| 4.7 | `<PLACEHOLDER: send — streams manifest, manifest.sig and image.tar as one length-prefixed stream on the founder deploy key's stdin over OpenSSH on the tailnet; the key file from the USB, never an ssh-agent>` | the VPS's root script verifies and deploys | **one status word**, `ok` (§ 12) | any other word → § 12 |
| 4.8 | `<PLACEHOLDER: unmount>`; **USB out** | — | — | — |
| 4.9 | Write down: release N, the status word, the date | the founder's own trail | — | — |

## 10. Host-step sessions (admin key)

Host steps change what the deploy pipeline never writes: the deploy and rollback scripts, the wrapper,
`allowed_signers`, the gate state, secret files, the Compose file, the nginx configuration. They also cover
rollback, the privileged migration procedure, gate-state re-initialisation and the escrow write and restore.
They are rare and deliberate. **No host step runs before the agent-account move** (founder, 2026-10-20): the
VPS host set-up and the bootstrap roles script wait for it.

| # | Command | What it does | Expected output | On failure |
|---|---|---|---|---|
| H1 | § 5 clean-session check, run **from the USB** | — | clean | see § 5 |
| H2 | USB in; `<PLACEHOLDER: ssh with the admin key file from the USB to kadmin over the tailnet>` | interactive admin login | a shell on the VPS | refused → check the tailnet from the phone (Tailscale admin); still refused → § 11.2 |
| H3 | the host step itself — `<PLACEHOLDER: per step; each gets its own section here when written>` | — | — | — |
| H4 | log out; **USB out** | — | — | — |

**Rollback** (after a switch; before the switch it is automatic): host-step session, then
`<PLACEHOLDER: sudo rollback (no arguments)>`. It re-activates the recorded previous release, never the schema
(migrations are expand-only). Across a key rotation it works inside the re-wrap window; outside it, a new
signed manifest is needed.

**Privileged migration** (`privileged_migration_pending`): host-step session, then
`<PLACEHOLDER: migration job as the bootstrap superuser through the PostgreSQL container's socket, target=<version>>`
(only after S57 passed), then re-send the same signed manifest.

**Gate-state re-initialisation** — after any restore of the VPS or of the gate state, before the next deploy:
host-step session, then `<PLACEHOLDER: set last_release and last_manifest_sha256 from the highest release in the off-host deploy record>`.

**Escrow write and restore** (founder decision 2026-10-20, staff-auth M26 and T6.12) — the four server keys
(pepper, TOTP key, throttle-HMAC key, verifier master key) pass through the founder machine only here:

| # | Command | What it does | Expected output | On failure |
|---|---|---|---|---|
| E1 | Reboot; text-console login; § 5 clean-session check (only after the agent-account move) | no agent or build-account process can read the keys in transit | clean | see § 5; no escrow that day |
| E2 | Signing USB in (admin key), **escrow USB in**; `<PLACEHOLDER: mount the encrypted escrow volume, passphrase typed by hand>` | — | mounted | does not mount → stop; never format it |
| E3 | **Write:** `<PLACEHOLDER: copy the four key files over the admin SSH session from the VPS straight onto the mounted escrow volume>` · **Restore:** `<PLACEHOLDER: the reverse, onto the VPS paths, owner = backend UID, mode 0400>` | the keys never land in the founder's home, a temp directory or the clipboard | the four file names; after a restore, the backend's fingerprint check (`ok` at start-up) | a file staged anywhere else → delete it at once and record it; a fingerprint mismatch after a restore → stop, the backend stays down; check which key is wrong |
| E4 | `<PLACEHOLDER: unmount>`; **escrow USB out and signing USB out**; log out | — | — | — |

## 11. Recovery routes

### 11.1 Lost, broken or stolen signing USB

What is gone: the signing key, the founder deploy key, the founder admin key and the reviewed script copy.
The running release keeps serving; nothing can be released and no admin login works until recovery.

1. **Broken or lost (no sign of theft):**
   1. From the **phone**, with 2FA, sign in to the **VPS provider account** — never from the workstation
      browser. Which console, rescue and snapshot features the provider offers, and which local account the
      console logs in as (SSH password login is off), are NOT SOURCEABLE today and are checked at host set-up
      (P4): `<PLACEHOLDER: console login procedure>`.
   2. On the founder machine, after a § 5 clean-session check, create new signing, deploy and admin keys on a
      **new** USB, each encrypted with a hand-typed passphrase: `<PLACEHOLDER: key generation commands>`.
   3. Through the provider console: replace the two `authorized_keys` lines (`deploy`, `kadmin`) and the
      `allowed_signers` line with the new public keys; **remove the old ones**: `<PLACEHOLDER>`.
   4. Copy the scripts from the last reviewed commit to the new USB after a git-diff check against that commit;
      record the new hash off-machine (§ 4.2).
   5. Write down the new key fingerprints with the date; the next ceremony runs as normal.
2. **Stolen, or the passphrase may have been seen** (residual TI R-9: a validly signed release and admin root
   are possible):
   1. Do 1.1–1.3 **at once**, from the phone: the old keys must stop working before anything else.
   2. Treat it as an incident (`/incident`): check the off-host deploy record and the gate state for a release
      you did not send; check the running image digest against your last `ok`; review the `kadmin` login
      history.
   3. If anything is unexplained, assume the host is compromised: the incident decides on a rebuild and on
      rotating the server keys from the escrow USB (staff-auth M26).

### 11.2 Locked out of SSH (sshd, Tailscale or the tailnet ACL broken)

1. From the **phone**, check the **Tailscale admin account** (2FA): is the founder machine still approved and
   is the VPS online? Fix device approval or the ACL **from the phone only**. The Tailscale admin account gives
   network reachability only; a key is still required.
2. Still locked out: **provider console** from the phone (§ 11.1 step 1.1), repair sshd or the network, and
   re-check that root login and password authentication are still off.

### 11.3 Provider or Tailscale admin account at risk

Phishing, SIM swap or an unexpected sign-in notice (TI AB26): from the phone, change the password and the
second factor and end other sessions. Then check, through a host-step session, that `authorized_keys`,
`allowed_signers` and the gate state are unchanged, and that no unexpected device joined the tailnet. Snapshots
never hold the secret files, but check for a snapshot or rescue boot you did not start. Anything unexplained →
`/incident`.

## 12. Status words from the VPS and what to do

The deploy entry returns exactly one word and an exit code, never raw output.

| Word | Meaning | What to do |
|---|---|---|
| `ok` | release N is live, recorded off-host, gate state advanced | write it down (§ 9 row 4.9) |
| `busy` | another deploy run holds the lock | wait; re-send the same signed release once; repeated `busy` → host-step session to look |
| `args_present` | the entry received arguments | the send script is wrong; stop; review it as a diff |
| `input_format` | the stream is out of format | the send script or the files are wrong; stop |
| `input_too_large` | a part is over its cap | check the tarball size; the cap change is a host step, reviewed |
| `state_missing` | the gate state is missing | host-step session: re-initialise from the off-host deploy record (§ 10); never accept release 1 again |
| `unsigned` | no signature | sign (§ 9 row 4.5) and re-send |
| `bad_signature` | the signature does not match the manifest | the manifest changed after signing or the wrong file was sent; re-sign; repeated → § 11.1 step 2 |
| `namespace_mismatch` | signed for another namespace | re-sign with `-n kodeebo-release-manifest-v1` |
| `signer_unknown_or_expired` | the key is not in `allowed_signers` or is past `valid-before` | wrong key, or a rotation not finished; host-step session to check `allowed_signers` |
| `field_syntax` | a field is missing, repeated or malformed | rebuild the manifest; re-sign |
| `not_next_release` | N is not last + 1 | re-read the off-host record (§ 8 row 3.4); sign the correct N; never force |
| `chain_mismatch` | `previous_manifest_sha256` is not the last accepted manifest | as `not_next_release` |
| `manifest_expired` | `not_after` has passed | sign a fresh manifest N with the same fields and a new `not_after`, chained to N−1 |
| `config_mismatch` | Compose or nginx hash differs from the host files | the host file changed or the expected value is wrong; host-step session to compare; a change you did not make → § 11.1 step 2 |
| `tarball_hash_mismatch` | the sent tarball is not the signed one | re-send the recorded tarball; repeated → stop |
| `image_digest_mismatch` | the loaded image is not the signed digest | stop; rebuild from step 1 |
| `unreviewed_migration` | a pending migration is not in the signed manifest | stop; find out why it is pending; never add it without review |
| `privileged_migration_pending` | a pending migration is on the privileged list | privileged procedure (§ 10), then re-send |
| `checksum_mismatch` | an applied migration file changed | stop; a changed applied migration is never released; `repair` is a founder-only decision |
| `migration_failed` | the migration job failed | the old version keeps serving; stop; fix with a new reviewed migration (expand-only) |
| `fingerprint_mismatch` | a server key does not match the signed fingerprint | the new version did not start; the old one keeps serving. Wrong expected value → re-sign with the correct value. Key file changed and you did not change it → § 11.1 step 2 |
| `health_failed` | the new version failed its health gate | rolled back automatically before the switch; stop; diagnose without the USB |
| `catalogue_check_failed` | the post-deploy catalogue check found drift | alert; host-step session; treat unexplained drift as an incident (TI M50) |
| `record_failed` | release N is live but the off-host record could not be written | once the store is reachable, re-send the **same** signed manifest N; past `not_after` → as `manifest_expired` |
| `rolled_back` | the run ended with the previous release active | stop; diagnose without the USB |

## 13. Open items

- Every `<PLACEHOLDER: …>` above: real commands and their outputs from S46 (ceremony scripts) and S48
  (clean-session check).
- Where the step-1 clean-session check runs from before the USB is in (ADR-0009 orders the check before USB insertion but does not say from which copy) — S48.
- The source of the expected Compose and nginx hashes (§ 8 row 3.2) and of the key fingerprints (§ 8 row 3.3).
- Provider console features and the console login account (§ 11.1) — checked at host set-up.
- The tailnet ACL syntax and sshd settings — S33.
- The one-time dependency download size into the build account's caches — measured at the first post-move build.
- The build account's name and set-up, and the exact rootless Docker commands — written with the scripts (P10).
- S59: whether a changed cached JAR fails the offline build; if not, § 7 changes to a fresh dependency cache per
  release and the per-release download is measured.
- At the first paying customer: the two FIDO2 keys replace the USB keys (after S45); this runbook changes
  then, as a reviewed diff.

## Revision history

| Date | Change | Founder review |
|---|---|---|
| 2026-10-20 | Created at design time from ADR-0009 (Accepted 2026-10-20); placeholders until S46/S48 | pending: read in full before the first ceremony |
| 2026-10-20 | Build containment approved by the founder (ADR-0009 amendment notes; threat-model review c75bc40): build account on rootless Docker, fetch/build split, offline build with the read-only dependency cache, required reboot before step 4, widened clean-session check, escrow write and restore as a host step, no ceremony or host step before the agent-account move; P10, P11 added | pending: this diff |
