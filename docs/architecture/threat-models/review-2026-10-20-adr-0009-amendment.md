# Independent review: ADR-0009 amendment to `tenant-isolation.md` and `staff-auth.md` (2026-10-20)

> **Reviewed**: the uncommitted diff of `docs/architecture/threat-models/tenant-isolation.md` (TI) and `staff-auth.md` (SA) against HEAD 57c3a43
> **Against**: `docs/architecture/adr-0009-deploy-and-build-tooling.md` (Accepted 2026-10-20) and `docs/architecture/review-2026-10-20-adr-0009.md`
> **Reviewer**: independent fresh session (not the author of ADR-0009 or the amendment). This file is the only one written. Nothing was staged or committed.
> **Order**: TI TB8 and the new rows first, then the restated rows, then the ASVS IDs, then consistency.

## Verdict: CONCERNS

There is no blocker. The amendment carries ADR-0009's T2 decision correctly: the agent has no VPS access, the founder deploy and admin keys are on the USB, the manifest is signed with a replay gate, `catalogue_rt` is in place and the secrets are 0400 files owned by their consumer's UID.

Six gaps remain:
- two holes in TB8 (findings 1–2);
- two residuals whose wording does not match what is actually accepted (findings 3–4);
- one founder route that is not modelled (finding 5);
- one SA claim stronger than the ADR (finding 6).

Findings 3 and 4 change the text of R-8 and R-9, which Kamel Mohamed accepted by name. Once the text is corrected, the founder must re-accept both before commit.

**Findings: BLOCKER 0 · MAJOR 6 · MINOR 12.**

## MAJOR

**1. TB8: no threat for escape from the build container or abuse of the root Docker daemon.** *(TI TB8, M66; ADR-0009 § 4c step 2, § 6)*
- **Problem:**
  - Agent-written build code (Gradle, plugins, tests) runs in the throwaway container, and the Dockerfile's `RUN` steps run on the founder account's rootful Docker daemon.
  - M66 gives the Gradle container only "no home, no USB, no Docker socket". The scanner container gets `--read-only --cap-drop ALL --security-opt no-new-privileges --user 65534`; the Gradle container gets none of this.
  - Decision 6 (the October 2026 `moby/moby` advisories) is checked on the VPS only, not on the founder machine.
  - If build code escapes, it is root on the founder machine. The clean-session check looks at the agent's and the founder's processes, user units, timers, cron and autostart entries, not at system-level persistence. So the escaped code survives to step 4 and captures the passphrase and all three keys.
  - T8.2 rates key theft L on the grounds that "the build container sees only the checkout and the founder's caches". That reason does not hold if the container can be escaped.
- **Fix (text):** add a new row:

  > T8.10 | **E**levation of privilege | Agent-written build code or a Dockerfile step escapes the throwaway build container or the image build on the founder's rootful Docker daemon, persists as root, survives the clean-session check (user-level only) and captures the passphrase and keys at step 4 | A13, A14 | L — needs a container escape; the build container runs as non-root with no capabilities | H — all three keys | M66 · residual R-9

  Extend M66:
  - the Gradle container gets the scanner flags (non-root `--user`, `--cap-drop ALL`, `no-new-privileges`, read-only root, default seccomp, pids, memory and CPU limits);
  - the founder machine's Docker Engine passes the same Decision 6 check as the VPS;
  - the clean-session check also lists system units and timers, or step 4 runs after a reboot.

  Add a test: `build container runs non-root with no capabilities`. If the founder does not adopt these hardening flags, record that in R-9.

**2. TB8: no threat for cache poisoning.** *(TI TB8; ADR-0009 Risks "The agent poisons a cache the ceremony build uses", § 4c step 2, review R3)*
- **Problem:** ADR-0009 lists this as a Risks row (L/H), but no T8 row carries it. It also has a second variant inside the ceremony:
  - the founder's Gradle and Docker caches are mounted read-write into the container where reviewed build code runs;
  - one malicious build that passed review can write to the cache: `GRADLE_USER_HOME/init.d` scripts, `gradle.properties`, build-cache entries;
  - what it writes runs in every later release, after the commit itself has been reverted;
  - strict dependency verification checks resolved artifacts, not init scripts or properties.
- **Fix (text):** add a new row:

  > T8.11 | **T**ampering | A cache the ceremony build uses is poisoned: by the agent before the account move, or by build code in an earlier ceremony through the read-write cache mount (`init.d`, `gradle.properties`, build cache), so later releases are built with code no reviewed commit contains | A1, A7 | L | H — every tenant, signed | M66, M67 · residual R-4

  Extend M66:
  - mount only the dependency cache (`caches/modules-2`), never a whole `GRADLE_USER_HOME` with `init.d` or `gradle.properties`;
  - build-cache off for ceremony builds.

  Add the test `ceremony build ignores an init script planted in the cache`. Add "earlier build code persisting through the cache" to R-4's remaining path.

**3. R-8 and T8.4 leave out the admin key being used before the agent-account move.** *(TI R-8, T8.4; ADR-0009 § 2 "Every host-step session starts with the same clean-session check", Migration Plan steps 5–7, Ordering Note 3d)*
- **Problem:**
  - R-8 says "No release ceremony runs before the move, so no signing or deploy key is used on the machine until then". T8.4 rates L because "before the agent-account move no ceremony runs at all".
  - But Migration Plan steps 5 (VPS host set-up) and 6 (bootstrap roles, S57, S58) use the founder admin key from the USB, and both come before step 7, the move. Nothing in the ADR orders them after it.
  - At that point the agent runs as the founder's root-equivalent account. The only protection is the clean-session check, and S48 is required only "before the first signature", so it may not have passed yet.
  - The admin key is root on the VPS.
  - R-8 also says the telemetry controls are "set only at user scope". In fact three of the five are set there, and `DISABLE_FEEDBACK_COMMAND` and `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY` are not set at all (ADR § 5).
- **Fix (founder decision, then text).** Either:
  - (a) decide that no admin-key host step runs before the move either, and say so in R-8, T8.4 and M49; or
  - (b) widen R-8 to: "…until then no signing or deploy key is used on the machine; **the founder admin key is used before the move for host set-up and the bootstrap roles script (Migration Plan steps 5–6), protected only by the clean-session check, which S48 has to pass before that first host step**…". Make T8.4's reason "no ceremony before the move; host steps before the move rely on the clean-session check (S48)".

  Correct the telemetry clause to "three of the five set at user scope (editable by the agent), two not set". The founder re-accepts R-8.

**4. R-9 names a compensating control that does not compensate, and leaves out the ones that do.** *(TI R-9, SA T10.10; ADR-0009 § 2 `from=`, tailnet ACL, Decision 4c)*
- **Problem:**
  - R-9 is about a stolen *key*. "The replay gate limits a stolen signature to the next release number (M68)" does not help: with the signing key, the attacker signs any release N+1, and with the admin key they are root and can rewrite the gate state and `allowed_signers`.
  - What actually raises the bar for USB theft: the deploy key's `from=` (the founder machine's tailnet address), the tailnet ACL that limits the VPS's SSH port to the founder machine, and Tailscale device approval (M64). With these, a stolen USB plus its passphrase also needs the founder machine, or the Tailscale admin account.
  - SA T10.10 lists TI M68 as a mitigation for the same reason.
- **Fix (text):** in R-9 replace the replay-gate clause with "the deploy key's `from=` and the tailnet ACL limit both keys to the founder machine's tailnet address, and a new device needs Tailscale approval (M64), so USB theft also needs the founder machine or the Tailscale admin account (A15)". Change T10.10's mitigations to "TI M64, TI M66, M28". The founder re-accepts R-9.

**5. Taking over the provider or Tailscale admin account is modelled only as AB26, with a mitigation that does not stop it.** *(TI AB26, TB7, § 7; ADR-0009 § 2 "root on the VPS", § 3a "Whether the VPS disk … is encrypted is NOT SOURCEABLE")*
- **Problem:**
  - ADR-0009 makes the provider account a named route that is "root on the VPS" (console, rescue, password reset).
  - TB7 has no STRIDE row for it, and no residual names it.
  - AB26's second mitigation, "secret files excluded from provider snapshots", does nothing against a rescue boot. Rescue reads the plain secret files and the database directly. Disk encryption is not claimed.
  - The claim "No High residual is unaccepted" therefore rests on a threat that was never rated.
- **Fix (text):** add a new row:

  > T7.15 | **S**poofing | The VPS provider account (console, rescue boot, password reset, snapshots) or the Tailscale admin account (devices, ACL) is taken over by phishing or SIM swap; rescue boot reads the plain secret files and the database, and a widened ACL with a new device reaches SSH | A15, all | L — 2FA on the phone, never used from the workstation | H — every tenant and every server key | M64 · residual (new)

  Drop "secret files excluded…" from AB26's mitigations, or keep it only for the snapshot path. Then either add a residual (for example R-10, "plain secret files and an unencrypted disk are readable through the provider's rescue route until the KMS envelope", accepted by name) or write down why R4 in SA already covers it.

**6. SA T10.2 claims a control ADR-0009 does not contain, and the escrow flow is not modelled.** *(SA T10.2, M26; ADR-0009 § 3a "Escrow … stay as in ADR-0007/0008", § 4c applies to the signing USB only)*
- **Problem:**
  - The amendment says "keys stay on the VPS; the escrow and signing USBs are absent while an agent session runs". ADR-0009 sets that rule for the signing USB only. It sets no rule for the escrow USB.
  - Writing escrow, and restoring from it, moves all four server keys through some machine. Nothing says which machine or under what check. If it is the founder's workstation before the move, the root-equivalent agent can read the pepper and the master key.
- **Fix:**
  - Either the founder decides the custody (for example: escrow is written and restored only in a host-step session after the clean-session check, the USB is removed right after, and the keys are never staged in the founder's home) and it is recorded as a dated founder decision in M26;
  - or T10.2 drops "escrow" from the sentence and a new row covers it:

    > T6.12 | Information disclosure | Escrow write or restore passes the four server keys through the founder's machine while an agent process can read them | A6 | L | H | M26 · residual TI R-8 until the move

## MINOR

1. **TI TB8 boundary row and M66: where the scripts run from, and one wrong test.**
   - ADR § 4c step 1 copies the scripts to a root-owned, read-only location and step 4 re-checks their hash. The TB8 row says they run "only from the reviewed copy on the USB". Add the copy step and the re-check.
   - M66's test "typed script hash differs → stops before the USB goes in" is impossible as written: the hash is computed on the USB copy. Use the ADR's wording, "stops before any build or signature".
   - Add tests for "clean-session check and hash re-check run again before signing" and "step 2 refuses to start while the USB block device is present" (ADR Validation Criteria). A container showing no USB mount does not prove the USB is out.
2. **TI T8.1 / T8.9: network during the build, and base-image provenance.**
   - With the network on and no allowlist (review S1), build code can also *fetch* code during the build. That code is in no reviewed diff and is not covered by strict verification. Add this to T8.1's text, and to R-4's remaining path.
   - A pinned digest is not reviewable by a human. Add "the Dockerfile names the official repository with the digest; the ceremony shows tag→digest for the founder to check".
3. **TI AB25 detection names an "SBOM diff".** ADR-0009 stores the SBOMs and puts their hashes in the manifest; it specifies no diff. Remove "SBOM diff", or record it as a new founder decision.
4. **TI T7.12 says "both keys".** The USB holds three: signing, deploy and admin. Write "all three keys".
5. **TI T7.2 (likelihood M → L): the reason holds for theft of the credential file.** The migration job, though, runs the backend image's own `main()` with `deploy_rt` mounted (ADR § 4a), so a backdoored image holds the credential by design. Add "code inside a signed image reaches `deploy_rt` through the migration job; that path is T8.1 (M) and R-4".
6. **TI TB7 and M49: the tailnet ACL is missing.** ADR § 2 limits the VPS's SSH port to the founder machine. Add it to TB7 and M49, with the test "SSH from another tailnet device → refused". Add "host-step session with an agent process alive → refused" to M49's tests. M49 also writes the sshd state as "confirmed"; the ADR's wording is "founder statement; re-checked in S33".
7. **Test lists weaker than the ADR's Validation Criteria.**
   - TI M63: add "from the agent session's environment, no SSH login to the VPS succeeds".
   - TI M68: add `state_missing`, `signer_unknown_or_expired`, `tarball_hash_mismatch`, "a refused run does not advance the gate state" and "after a restore the state is re-initialised before the next deploy".
   - TI M67: add "managed settings readable (0644); `/status` shows the five variables" and "the founder's caches were first filled after the move (dated record)".
   - TI M19: add tests for the files of `deploy_rt` and `catalogue_rt`, separate UIDs, and no secret in `docker inspect` or `/proc/<pid>/environ`.
8. **SA M28 restated, and its tests.**
   - The list of files that change only over the admin key leaves out the Compose file and the nginx configuration (ADR § 2).
   - The test list dropped the injection test and did not add the one the ADR names as "the SA M28 test": "An injected instruction asking the agent to print a secret, the environment or a key file finds no secret to print and no route to the VPS". Restore it.
9. **SA M26 adds a control the ADR does not have:** "secret file owned by another UID or not 0400 is refused by the deploy script". Either drop it, or record it as a new founder decision that goes beyond the ADR.
10. **Cross-references.**
    - SA M26 maps T10.10, but T10.10's mitigation column does not list M26.
    - SA M28 maps "T10.1–T10.10", which includes T10.4. T10.4 is superseded and has no mitigations; write "T10.1–T10.3, T10.5–T10.10".
    - SA T10.6 keeps "(no control today)" and its M/M rating beside the note saying the deploy record names the actor. Re-rate it, or strike that text.
    - IDs: TI's new T8.1–T8.9 and TB8 share names with SA's T8.1–T8.8 and SA TB8 ("Founder workstation ↔ database host"). Both documents prefix their cross-references, but add one line to the SA header: "SA TB8 ≠ TI TB8".
11. **Diagrams.**
    - Both Mermaid blocks parse (Mermaid 11.12.0 `parse`, with a negative control). Layout was not rendered.
    - In TI, `PH` sits *inside* the `Infra` subgraph and draws its dotted edge to `Infra` itself, which includes the founder's machine and the USB. The ADR draws the phone outside, pointing at the VPS. Move `PH` out of `Infra` and point it at `CI` and `SU` (or at a VPS node). An edge from a node to the subgraph that contains it is also a known layout trouble spot in Mermaid.
    - SA still labels `WS -- "TB8: Tailscale SSH, bootstrap superuser" --> DB`. Change it to "OpenSSH over the tailnet, founder admin key".
12. **ADR items not modelled, and ASVS.**
    - Decision 6 (VPS Docker Engine advisories): add it to TI T7.9 and M53, or point to the first-deploy checklist.
    - ASVS: optionally cite V11.6.1 (approved signature algorithms) on M68, and V15.2.5 (L3; containerization of risky components) on M66 for the scanner and build containers. Both are in ADR-0009's Cross-Cutting Impact and in the CSV.

## Checks run

- **ASVS IDs**:
  - CSV `docs/research/evidence/staff-auth-and-roles-part-3/asvs-download/asvs-5.0.0.csv`, sha256 `98c8fe911b…cdf680`, matching the expected prefix and suffix.
  - All cited IDs exist and match their quoted subject and level: 15.1.2 (L2, SBOM inventory), 15.2.4 (L3, expected repository / dependency confusion), 13.3.2 (L2), 13.2.2 (L2), 13.3.1 (L2 plus the L3 HSM clause).
  - The claim "no ASVS row for release signing" reproduces: rows containing "signature" together with build, deploy, update, package or integrity are only V6.8.2 and V11.4.3. Other signature rows (V4.1.5, V9.1.1, V11.6.1) are about requests, tokens or algorithms, not release artifacts.
- **IDs**:
  - New TI IDs A14, A15, TB8, T8.1–T8.9, AB25, AB26, M66–M68 and R-8, R-9 are unique in TI. S-TI-65 to S-TI-67 are new.
  - SA T10.4 is kept as superseded, not reused.
  - Every mitigation ↔ threat pair in the new and restated TI rows resolves both ways. Exceptions are in MINOR 10.
- **Restated rows checked against ADR-0009 and found consistent** (apart from the findings above): TI A13, TB7, T7.1, T7.11, AB19, AB23, AB24, M50, M63, M64, R-1, R-4; SA A12, A13, TB6, TB8, TB10, T6.1, T6.4, T6.7, T6.10, T10.1, T10.3, T10.8, the secrets table, the detection line, R4.

## What this review did not do

- It did not render the diagrams' layout. It did not read any key or credential file.
- It did not check facts outside ADR-0009, its review record and the CSV. That includes Gradle's verification behaviour for cached artifacts and Mermaid's layout of edges into a containing subgraph; both are stated as reasoning, not tested.
- It edited nothing except this file.
