# Independent re-check — M21/M22/Q-counteronly amendment batch (2026-10-20, Proposed)

Date: 2026-10-20
Reviewer: independent session (did not author the batch). Read-only apart from this file: no ADR, registry, threat model or research note edited; nothing staged or committed.
Scope: the uncommitted diff to ADR-0001, ADR-0007, ADR-0008, `docs/registry/architecture.yaml`, `docs/architecture/threat-models/staff-auth.md` and `docs/research/staff-auth-takeover-and-enrolment.md`. It was checked against the research note (§§ 5 and 9, plus Part 1 § 5 conditions 1–12 and Part 2 § 5 Decisions 1–4), ADR-0002 (Device scope, the closed `app.*` list), and the accepted text at HEAD (7791001).

Reviewed-Content-Hash (working tree):
- docs/architecture/adr-0001-tenancy-model.md 2ec61384485ca25fb35b92ecd057c83258f44416
- docs/architecture/adr-0002-tenant-context.md 9429898b3f505b813cbc40f6623a23c3b494694e (unchanged)
- docs/architecture/adr-0007-staff-auth.md f4ee6dae1c485095884efac77d000b8d4bc23352
- docs/architecture/adr-0008-roles-permissions.md aa2a9cc2e9dae7dbcbc2f3cee02ae2d9c52b95f1
- docs/architecture/threat-models/staff-auth.md e94135ce6a44baec4523f7317e81abbeb88724e6
- docs/registry/architecture.yaml 2fcaed4dc0df01cae305613549d80133ccbdb6b1
- docs/research/staff-auth-takeover-and-enrolment.md a4ede60bd0c9f034e3812342b7bcad528bb32412

## Verdict: FAIL (text fixes only)

**3 BLOCKER · 9 MAJOR · 7 MINOR.**

Three findings block acceptance:
- **B1** contradicts another part of the same batch.
- **B2** and **B3** are new database rules that break flows that are already Accepted.

Every finding has a text fix, and none needs new research. B1, M2, M5 and M9 need a founder choice; each one says so.

**What is sound:**
- Every founder decision in § 5 is carried with its numbers and conditions: M21 option B with conditions 1–12, Q-intended, Q-fallback, Q-matching, M22.1–M22.4 and the counter-only privileged case. The § 9 Q-counteronly decision is also carried: option (a), partial unique indexes, the device from context, per-slot compare-and-set, one per-person sequence, the feed and tombstones, the person lock, the re-enrolment cost and the nudge.
- Three items the brief flagged are sourced in the note, so they are not findings:
  - "owner-switchable" password path for non-privileged users: Part 1 § 5 condition 8;
  - "poll ≤ 2 s": condition 9;
  - "one live request per device": Part 1 § 3 (g) and the § 6 approval-bombing note.
- The `B3` number-matching direction matches the Part 1 § 4 row. `app.device_id` is on ADR-0002's closed list (ADR-0002:88, 108), so using it adds no new setting.
- The `consumeReceipt(receiptHash, userId)` signature agrees across ADR-0001, ADR-0008, the registry (an "Amended 2026-10-20" suffix on IC-PRE-CONTEXT-LOOKUPS-R11), the research note and M57.
- Partial unique indexes plus `CHECK confirmed = (minting_device_id IS NULL)` are sound as a shape. Under FORCE RLS the restrictive TD `tenant_isolation` policy (no `TO`) still binds a `SECURITY DEFINER` owner, so tenant isolation holds whoever owns the trigger.
- **Registry:**
  - the YAML parses: 205 entries, no duplicate ids;
  - only six `status:` lines changed (append-only rule kept);
  - every successor id exists;
  - no base id has two active entries;
  - the 6-superseded / 10-added header is accurate;
  - it follows the earlier Proposed-batch convention ("return to active if rejected").
- **Threat model:**
  - the new T rows give reasons for both ratings;
  - links run both ways for T1.30, T3.20, T3.21, T4.25 and T4.26 (with M21, M50, M57, M52, M16), and for T4.1 and T4.8 with M57;
  - the M row count (57) and the Planned count are right;
  - R23 and R25 are honestly marked "not yet accepted";
  - R24 is accepted by name, as research § 9 records;
  - the ASVS IDs V8.3.1, V2.3.3, V6.5.4 and V6.6.4 match the ASVS 5.0.0 CSV in `docs/research/evidence/staff-auth-and-roles-part-3/asvs-download/`.

## Findings

### BLOCKER

**B1 — The post-PIN "that was me" step for privileged people contradicts `phone_assertion` "travels fleet-wide", and has no database path.**
- **Where:**
  - ADR-0007:156 says the post-PIN confirmation "comes before the verifier is delivered beyond the counter" (Part 1 § 5 condition 6, founder Q-matching).
  - ADR-0008:138 says a `phone_assertion` upload "is confirmed, and it travels fleet-wide". IC-PIN-VERIFIER-CUSTODY-R5 says the same.
- **Why it cannot be built as written:** there is no state for "server-checked but awaiting the holder's confirmation". `PinVerifiers.confirm` is owner-only (`app.branch_all = 'on'`, M10) and is refused for anyone holding a privileged key (M11), so a manager cannot confirm their own PIN through it.
- **Fix:** while the confirmation is on, a privileged person's `phone_assertion` verifier lands in the minting device's slot. A new holder-side function promotes it to confirmed. That function is bound to the request id, needs step-up `counter.enrol.approve`, and is separate from `PinVerifiers.confirm`. State the promotion in ADR-0008 item 3 and in Implementation Guidelines. (Founder: or drop the post-PIN step and record that.)

**B2 — The `pin_upload_facts` BEFORE INSERT trigger raises when `app.device_id` is unset, but `app_rt` inserts `dashboard_reset` facts in Staff scope.**
- **Where:**
  - ADR-0008:141: "An unset setting raises".
  - ADR-0008:496 and :499: `app_rt` inserts kind `dashboard_reset` (accepted R3 rule).
  - ADR-0002:88: `app.device_id` is set for device requests only.
- **Impact:** every "reset required" insert fails. That path is the amendment's only fleet-wide lock clear (ADR-0008:147) and the owner's lock clear (ADR-0008:359). In addition, "`device_rt`'s policies require a fact's `device_id` to equal the setting" would hide an `app_rt`-inserted fact from the device that must consume it.
- **Fix:** apply the overwrite-and-raise only to `device_rt` inserts, that is to the device-inserted kinds. A `dashboard_reset` row carries `device_id` NULL, and the consuming trigger matches it by (tenant, person, fact id). State the per-kind device rule in the Must (data) bullet and in IC-PIN-VERIFIER-CUSTODY-R5.

**B3 — The owner's confirmation (path ii, non-privileged people) cannot run under the new schema.**
- **What the amendment says:** confirmation "turns that one slot into the confirmed row and deletes the others" (ADR-0008:145).
- **Why it fails:**
  - `app_rt` holds only "UPDATE of `pin_verifiers.confirmed`" (ADR-0008:499), with no DELETE and no SELECT.
  - Setting `confirmed` alone violates `CHECK confirmed = (minting_device_id IS NULL)` (ADR-0008:140).
  - The one-confirmed-row index requires the old confirmed row to go first.
- **Fix:** make `PinVerifiers.confirm` a TD-side function owned by the trigger owner (see M1). Under the M10 guard, it does this in one transaction:
  1. delete the old confirmed row;
  2. set `minting_device_id = NULL` and `confirmed = true` on the chosen slot;
  3. delete and tombstone the other slots.

  Amend line 499's grant to "EXECUTE on that function only".

### MAJOR

**M1 — The `SECURITY DEFINER` trigger has no owner that ADR-0001 allows.**
- **Where:** ADR-0008:142 makes the trigger `SECURITY DEFINER`. ADR-0001:322 (C5, Accepted) allows definer functions owned only by `auth_lookup`, `support_fn` or `audit_writer`. `auth_lookup` is "PL only" (ADR-0001:123).
- **Impact:** CI fails the build, or the trigger is owned by a role outside the inventory (C4).
- **Fix:** name a NOLOGIN owner (for example `pin_writer`) and add it to the ADR-0001 role inventory and to the C4 and C5 lists. Give it permissive policies `TO pin_writer` on `pin_verifiers`, `pin_upload_facts` and `devices`. Record that the restrictive tenant predicate still binds it.

**M2 — Per-slot compare-and-set lets a stale device-minted upload in after "reset required" (a regression).**
- **Where:** ADR-0008:143 compares a device-minted upload only with "its own slot, or with 'no slot'".
- **Scenario:** a `self_change` or `counter_reset` minted offline before a "reset required", a raised floor or an erasure is uploaded afterwards. It finds "no slot" and is accepted.
- **Why it is a regression:** at HEAD (ADR-0008:334) the per-person version bump refused it as `stale_version`. Now the leaked PIN keeps a slot on that counter, against item 6 "to retire an old PIN everywhere … reset required" (ADR-0008:351) and T4.8.
- **Fix:** a device-minted upload also carries the confirmed `verifier_version`, or a per-person reset epoch, that the device held when it minted. The trigger refuses the upload if a reset, floor raise, erasure or confirmed change came after that. Add a negative test to M57 and to ADR-0008 Validation. (`cto` picks version or epoch.)

**M3 — The per-counter lock clear has no data shape.**
- **Where:** ADR-0008:147 and ADR-0007:270 say a counter reset clears a person lock only on its own counter. But:
  - `AuthoritySnapshot` carries `personLocked` per (tenant, branch) (ADR-0008:463);
  - the lock reaches "every device of their branches through the feed" (ADR-0008:358);
  - M17 journals only "person lock and unlock".
- **Open questions:** where a per-device clear is stored, how the snapshot or feed carries it per device, and whether the per-person failure sum is reset.
- **Fix:** add a per-(person, device) clear record and per-device lock state in the snapshot or feed. State the effect on the M15 sum. Add the clear to the M17 control-journal kinds.

**M4 — `login_failure_state` expiry would lift durable blocks.**
- **Where:** rows "expire" and `FailureState.purgeExpired()` deletes "expired rows" (ADR-0001:224, ADR-0001:230; ADR-0007:173). But the ceiling and not-me blocks last "until a reset" (M2; Part 2 § 5 Decision 4: "durable account state").
- **Fix:** `expires_at` is NULL while either block is set, and `purgeExpired` deletes only unblocked rows. Add the test "a blocked row survives `purgeExpired`".

**M5 — The table cannot hold the accepted M2 per-signal ceilings.**
- **Where:** IC-SIGNIN-FAILURE-CEILING and the ADR-0007 sign-in bullet (Accepted) keep separate ceilings: anonymous attempts per login, and each known-device signal per (login, signal), which "blocks only that signal". `login_failure_state` has one count and one `ceiling_block` per login.
- **Impact:** either the signal ceilings stay in memory, and a restart resets a signal block (ADR-0007:173 claims the address delay "is the only throttle state a restart now resets"), or the schema is short.
- **Fix:** founder or `cto` choice. Either key rows by (tenant_id, user_id, signal_hash NULL for anonymous), or state that per-signal ceilings stay in memory and correct ADR-0007:173.

**M6 — The restore scope misses the new state.**
- **Where:** ADR-0007 § 3 Restore (ADR-0007:213) and M17 replay credential changes. They do not cover ceiling and not-me block or unblock, so a restore to before a "not me" click silently lifts that block. Unconsumed approve-on-phone requests from before the restore point are not voided either; enrolment assertions are (ADR-0007:556).
- **Fix:**
  - add block and unblock to the control-journal kinds, replayed after a restore;
  - void unconsumed enrolment requests at restore;
  - add both to ADR-0007 Validation and the M57/M22 tests.

**M7 — The approve-on-phone request store has no class and no access rule.**
- **Where:** research § 7 stores requests and codes in PostgreSQL with `expires_at`. ADR-0001 § 1a requires every table to have a class in its migration. The ADR-0001 amendment and TR-TABLE-CLASSES-R9 name only `login_failure_state`.
- **What needs stating:** the counter creates and polls requests as `device_rt`, and the approver looks one up by code HMAC as `app_rt`. The failure count that "a new request never resets" needs a home.
- **Fix:** name the table and its class: TD with `device_rt`/`app_rt` permissive policies if the lookup is inside the approver's tenant context; PL plus § 1c functions only if it is found before context. List its issue, approve and poll functions, and add it to TR-TABLE-CLASSES.

**M8 — Nobody is allowed to write a `phone_assertion` fact, and its kind is device-claimed.**
- **Where:** the accepted R3 list (ADR-0008:494–499) lets `device_rt` insert only the device-minted kinds, plus `password_assertion` with a receipt. Nothing ties `phone_assertion` versus `password_assertion` to how the assertion was issued (T4.9). Nothing names where "password path refused for privileged people" is enforced.
- **Fix:**
  - add "`device_rt` may insert `phone_assertion` with a valid receipt";
  - store the issuing path on `enrolment_assertions` and have `consumeReceipt` return it, so the trigger sets the kind;
  - `Enrolment.issueAssertion` refuses the password path for the owner and for anyone holding a privileged key once approve-on-phone ships.

**M9 — R15's remainder is re-rated without a reason or an acceptance.**
- **Where:** the R15 row (threat model:567) rates the post-ship remainder "Medium" with no reason. T3.21 (:211) is M likelihood / H impact, the same as T3.12, which made R15 High.
- **Acceptance gaps:**
  - the remainder has no acceptor ("closing path decided");
  - R15's own trigger "M21 research landing" (:563) fired on 2026-10-20, and no founder re-review is recorded.
- **Fix:** rate the same-device remainder High, or give the reason for Medium. Mark it "proposed for acceptance with the 2026-10-20 amendment", like R23 and R25, and record the triggered review. (Founder.)

### MINOR

**m1 — Additions the note does not decide.** Mark each as `cto` design for the founder's acceptance, or source it:
- (a) `login_failure_state` is keyed by (tenant_id, user_id), but Part 2 § 5 Decision 4 says "keyed by the throttle HMAC". The class PL and the § 1c function set are the author's design. Record why: a user id covers both the username and the email identifier.
- (b) ADR-0007:174 adds review triggers for every 2026-10-20 row.
- (c) ADR-0007:172 puts HIBP into ADR-0005's sub-processor table, while research § 6 says no new third party receives user data, and ADR-0005 is not amended in this batch.
- (d) ADR-0008:145: the owner's confirmation deletes the other slots.
- (e) The refusal list at ADR-0007:149–153 drops "lease-valid" from condition 2. Fix: add "or not lease-valid".

**m2 — Untouched accepted text is now stale.**
- ADR-0008:329, item 3(i), says "a new `password_assertion` upload, which replaces the pending verifier" (singular, password only) and has no inline note.
- ADR-0007:270 says "re-enrols by either path".
- ADR-0008:359 says an owner's lock is cleared by "… followed by a password-path enrolment", but the password path is refused for the owner once approve-on-phone ships. The inline note only adds "or".

Fix with inline notes: "(i) a `password_assertion` or `phone_assertion` upload, which replaces every slot", and "once approve-on-phone ships, a privileged person re-enrols by approve-on-phone, or a counter-only one by the sponsored path, per counter".

**m3 — `login_failure_state` details.**
- No column holds "at most one notice per 24 h", so a restart can resend the notice.
- `clearOnSuccess` must reset the count only, never a block.
- The write happens only for known logins, which can add a timing difference against unknown identifiers (ASVS 6.3.8).

Fix: add `last_notice_at`, state the `clearOnSuccess` rule, and state that the write is timing-equalised or off the response path.

**m4 — Slot foreign key and revoke writer.** State the composite FK (tenant_id, minting_device_id) → devices(tenant_id, id). Device revoke "tombstones" slots, but `Devices.revokeCredential` is a PL function and cannot write TD; name the TD-side writer.

**m5 — Research note § 9 formatting and stale status.**
- The multi-line bullets inside the Q-counteronly table row (research note:260–276) end the GFM table, so that row and the Q-samedevice and Q-factkind rows after it render as plain text.
- The header Status (:4) still lists Q-counteronly as open.
- Q-factkind is still open, although ADR-0008 answers it ("replaces … never confirms one"; § 5 "replaces every pending one").

Fix: move the decision to a sub-section with a one-line table row, close Q-factkind, and update Status.

**m6 — Threat model leftovers.**
- T1.19 (:154) still says "in-memory throttle state (accepted loss)".
- M3 (:478) is still a "research item under M22", although 4C is now decided.
- Line 733 still says "all 56 mitigations".
- The § 7b intro (:563) says "All accepted … on 2026-10-19", but the section now holds R24 (2026-10-20) and R23/R25 (not accepted).
- The § 7c heading is dated 2026-10-19 but holds the 2026-10-20 paragraph.
- T1.30 (:165) does not name R25.

**m7 — Registry and ADR-0001 class row.** TR-TABLE-CLASSES-R9 still says "Throttle and rate-limit state … are not tables" before its 2026-10-20 sentence that adds `login_failure_state`. The ADR-0001 § 1a PL row (:107) has no inline note for the new table. Fix: qualify both with "except per-known-login failure state (amendment 2026-10-20)".

## Must be decided before acceptance

- **Founder:** B1 (keep or drop the post-PIN step); M5 (persist per-signal ceilings or not); M9 (R15 remainder rating and acceptance); m1 (a)–(d), confirm or reject.
- **`cto` / `postgres-specialist`:** M1 (definer owner); M2 (version or epoch for device-minted uploads); M3 (per-device lock clear shape); M7 (request table class).

## Re-check 2 (2026-10-20)

Scope: the revised uncommitted batch (same six files; `docs/research/local-first-sync.md` ignored as another session's) after the founder's answers (B1 drop the post-PIN step, M5 persist per-signal ceilings, M9 High + proposed, m1 keep a/b/d and drop c) and the `cto` design for the rest. Read-only apart from this appended section.

Reviewed-Content-Hash (working tree): adr-0001 f6b7c4add78e9c9bbe92e4113de3e9eed807cae0 · adr-0007 067df166aaa1e335c9bc2a07b6ee9c3ef122958d · adr-0008 8a9759804ecca05d5698337b8699cd75151d26d0 · threat-models/staff-auth 51ec85bad8274bf4a8c1ca4c30cccf016c995de4 · registry b5c452c5a46c1864e17135beaea65eb022354542 · research note d3a04c5bd718a329b64c916130287c5e4c2b7f4e.

### Verdict: CONCERNS — 0 BLOCKER · 1 MAJOR · 7 MINOR (new)

All 19 earlier findings are resolved. The fixes introduce one MAJOR gap: the per-kind `WITH CHECK` split leaves no allowed writer for `activation_code` facts (N1). Fix N1, and N4 (it changes what R25 is accepted on), before the founder accepts; the other minors can go in the same pass.

**Checked and sound:**
- **Registry:** parses (206 entries, no duplicate ids); 7 `status:` lines changed; every successor exists; the header's 7 superseded / 11 added is accurate; TR-ROLE-INVENTORY-R11 carries `pin_writer`; entries were corrected in place before any commit, as the header says.
- **ADR-0008:** the P1/P2 PostgreSQL 18 citations support the design, the definer-policy point is marked as an inference with a test, and `pin_writer` without BYPASSRLS and not a table owner is bound by the restrictive tenant predicate.
- **Research note:** § 9 renders as one table again, § 9.1 holds the decision, and Q-factkind and Q-matching are closed with the founder's revision.
- **Threat model:** the counts (57) and the 7b/7c dating are honest.

### Earlier findings, one line each

- **B1 — resolved.** The post-PIN step is dropped consistently in ADR-0007:156, ADR-0008:138, IC-APPROVE-ON-PHONE-ENROLMENT and research § 5/§ 9; R25 still names it (N4).
- **B2 — resolved.** Per-kind device rule; `dashboard_reset` carries `device_id` NULL; `app_rt` and `device_rt` `WITH CHECK` split; matched by (tenant, person, fact id); test added. Leaves an `activation_code` gap (N1).
- **B3 — resolved.** `PinVerifiers.confirm(personId, deviceId, expectedVersion)` is a `pin_writer` function that swaps the slot in one statement, tombstones the rest and bumps the epoch; the `app_rt` UPDATE grant is removed (ADR-0008:499).
- **M1 — resolved.** `pin_writer` is NOLOGIN in § 1b with C2/C4/C5 and its permissive policies; `consumeReceipt` EXECUTE moves to it.
- **M2 — resolved.** A credential epoch in `pin_person_state`, carried by device-minted facts and refused as `stale_epoch`, with a test.
- **M3 — resolved in design.** `lock_seq` plus `pin_lock_clears` plus the journal kind `pin.lock.clear_device`. The interface line was not updated (N3).
- **M4 — resolved.** `expires_at` is NULL while blocked, and `purgeExpired` deletes unblocked rows only.
- **M5 — resolved.** Keyed by (tenant, user, `signal_hash`), so per-signal ceilings persist; ADR-0007:173 is corrected.
- **M6 — resolved.** Journal kinds `login.block`/`login.unblock`, `pin.epoch.bump` and `pin.lock.clear_device`; the restore voids pending and approved `enrolment_requests`; tests added. Wording issue in N5.
- **M7 — resolved.** TD tables `enrolment_requests` and `enrolment_device_failures`, with `pin_writer` functions `issue`, `approve` and `poll`, in ADR-0001 § 1a and TR-TABLE-CLASSES-R9. Gaps in N2 and N7.
- **M8 — resolved.** `issuing_path` and `request_id` on `enrolment_assertions`; `consumeReceipt` returns `{path, requestId}`; `kind_mismatch`; `password_assertion` backstop for privileged people; `device_rt` may insert `phone_assertion` with a receipt. The switch is unnamed (N8).
- **M9 — resolved.** The R15 remainder is rated High with a reason, proposed and not accepted, and the triggered review is recorded.
- **m1 — resolved.** (a), (b) and (d) are kept and marked; (c), the HIBP sub-processor line, is removed; (e) "not lease-valid" is added.
- **m2 — resolved.** Inline notes at ADR-0008:329 (item 3(i)), ADR-0007:270 (PIN reset) and ADR-0008:359 (owner lock).
- **m3 — resolved.** `last_notice_at`, the `clearOnSuccess` rule, and the write timing-equalised or off the response path.
- **m4 — resolved.** Composite FK with MATCH SIMPLE and ON DELETE RESTRICT; `devices UNIQUE (tenant_id, id)`; `PinVerifiers.dropDeviceSlots` runs in each revoke transaction, and the licensing revoke runs inside tenant context (ADR-0001:152), so it works.
- **m5 — resolved.** Table, § 9.1, Status and Q-factkind.
- **m6 — resolved.** T1.19, M3, line 733, 7b, 7c and T1.30 → R25.
- **m7 — resolved.** The PL row note in ADR-0001:107, and the registry's "stated exception" wording.

### New findings

**N1 — MAJOR — The new `WITH CHECK` split leaves no allowed writer for `activation_code` facts.**
- **Where:**
  - ADR-0008:141 lists the device-inserted kinds as `sponsor`, `counter_reset`, `self_change`, `password_assertion` and `phone_assertion`, and lets `device_rt` insert only those, and `app_rt` only `dashboard_reset`.
  - `activation_code` facts are written by `PinActivation.redeem`, which `device_rt` calls (ADR-0008:496; ADR-0001:201).
- **Impact:** as written, that insert is refused, so the Accepted remote-onboarding flow breaks. Simply adding `activation_code` to `device_rt`'s `WITH CHECK` would let a counter forge a confirmed, fleet-wide fact (T4.9).
- **Fix:**
  - make `PinActivation.redeem` a `pin_writer` function that inserts the fact with `device_id` from `app.device_id`;
  - keep `activation_code` out of `device_rt`'s and `app_rt`'s `WITH CHECK`;
  - add a test that "a direct `activation_code` insert as `device_rt` is refused";
  - add the same inline note at ADR-0001:201, which still lists only the three device-minted kinds.

**N2 — MINOR — `approve` calls `StepUp.consume`, but only `app_rt` may execute it.**
- **Where:** ADR-0007:157 says `approve` (a `pin_writer` definer function) gets the session's user from `StepUp.consume`. ADR-0001:183 grants `StepUp.consume` EXECUTE to `app_rt` only, and inside the function the caller is `pin_writer`.
- **Fix:** grant `pin_writer` EXECUTE on `StepUp.consume` in § 1c (amendment row), or have the use case consume the step-up first and pass the token hash for `approve` to re-check.

**N3 — MINOR — Interfaces do not show the new lock and epoch fields.**
- **Where:** ADR-0008:463 `AuthoritySnapshot` still says `personLocked`, and the `StaffFeedVerifier` line lacks `lockClearedSeq` and the credential epoch. The amendment says the snapshot carries `personLockSeq` and the feed carries `lockClearedSeq` and the epoch.
- **Also:** `lock_seq` returns to NULL at "reset required", so a later lock must take a new generation, never a reused one, or old `pin_lock_clears` rows would apply again.
- **Fix:** update both interface lines, and state that lock generations come from a monotonic per-person counter (or that reset deletes the person's clear rows).

**N4 — MINOR — R25 is proposed for acceptance on a control that was dropped.**
- **Where:** threat model:577 still lists "post-PIN confirmation for privileged people (M21)" among R25's compensating controls.
- **Fix:** remove it and keep Medium with a reason (number matching and notices remain), or re-rate R25.

**N5 — MINOR — A database function cannot write the control journal.**
- **Where:** ADR-0001:232 says `FailureState.block` and `unblock` "write `login.block` / `login.unblock` to the control journal". The journal is outside the restorable database (ADR-0005:125).
- **Fix:** say the calling use case writes the journal entry in the same operation, and state the order, so a failed journal write cannot leave a block that is never replayed.

**N6 — MINOR — The key with a NULL `signal_hash` needs a stated constraint.**
- **Where:** ADR-0001:224–232 key `login_failure_state` by (tenant, user, `signal_hash`) with NULL for anonymous attempts. A primary key cannot hold NULL.
- **Fix:**
  - use `UNIQUE NULLS NOT DISTINCT (tenant_id, user_id, signal_hash)`, available since PostgreSQL 15, or a pair of partial unique indexes;
  - state that the not-me block sits on the anonymous row (`signal_hash` NULL) and blocks the login's password path for every signal;
  - state that `unblock(user)` clears all of the login's rows.

**N7 — MINOR — What counts as a "failure" in `enrolment_device_failures` is not defined.**
- **Where:** ADR-0007:157. Wrong user-code guesses are typed in approver sessions, not on the device, so a per-device count cannot limit them.
- **Fix:** define the device-side failures (declined, expired, not-me) and add a per-approver and per-tenant wrong-code limit for `approve`, to cover the ASVS 6.6.3 mapping that M21 claims.

**N8 — MINOR — The "approve-on-phone enabled" switch is not named.**
- **Where:** ADR-0008:138. The trigger refuses `password_assertion` for privileged people "once approve-on-phone is enabled", but the switch it reads is not named.
- **Fix:** name the switch (a G-table release flag, or a per-tenant setting) and who sets it, and make the ADR-0007 API refusal read the same switch.

## Re-check 3 (2026-10-20)

Scope: the N1–N8 fixes in the same uncommitted batch. Read-only apart from this appended section.

Reviewed-Content-Hash (working tree): adr-0001 254f633243836329d0964a812cf1ff5ff1a2a208 ac1ae52a0272e190aef78ae32082c94e9308f7ad 7df4c24756cf9359fade1a9a0e27b45c5f2a9aef 325936a001c0cde7eb41e58884197ff2a575ba79 3b03d81ee080af718cf345739bb5b82fe575c2e8 d3a04c5bd718a329b64c916130287c5e4c2b7f4e  · adr-0007  · adr-0008  · threat-models/staff-auth  · registry  · research note .

### Verdict: PASS — 0 BLOCKER · 0 MAJOR · 1 MINOR (new)

N1–N8 are resolved. One new minor (N9) is a naming gap; it can go in with acceptance.

**Registry:** parses (206 entries, all ids unique); still 7 `status:` lines changed; every successor exists. The new entries carry the N fixes:
- `PinActivation.redeem` in TR-ROLE-INVENTORY-R11 and IC-PIN-VERIFIER-CUSTODY-R5;
- `StepUp.consume` for `pin_writer`, and `NULLS NOT DISTINCT`, in IC-PRE-CONTEXT-LOOKUPS-R11;
- the release flag and the monotonic lock generations in IC-PIN-VERIFIER-CUSTODY-R5;
- the wrong-code limits in IC-APPROVE-ON-PHONE-ENROLMENT.

### N items, one line each

- **N1 — resolved.** `PinActivation.redeem` is a `pin_writer` function (EXECUTE `device_rt`) that inserts the `activation_code` fact with the device from `app.device_id`. The kind is in neither role's WITH CHECK (ADR-0008:141), with an inline note at ADR-0001:201, a Key Interfaces note (ADR-0008:473) and the test "a direct `activation_code` insert as `device_rt` or `app_rt` is refused and `PinActivation.redeem` still onboards" (ADR-0008:667).
- **N2 — resolved.** ADR-0001:183 adds EXECUTE by `pin_writer`, and `StepUp.consume` returns the session's user; ADR-0007:157 points to it.
- **N3 — resolved.** ADR-0008:463 (`personLocked` becomes `personLockSeq`) and :464 (`credentialEpoch`, `lockClearedSeq`). Lock generations come from a monotonic per-person counter and are never reused (ADR-0008:147), with a test (:667).
- **N4 — resolved.** R25 (threat model:577) no longer cites the post-PIN step, and keeps Medium with a stated reason.
- **N5 — resolved.** The use case appends to the journal first, then calls the function (ADR-0001:232). Wording note, not a finding: an entry whose block call failed is not quite "harmless" on replay, because replay then applies the block, though that is the safe direction. The not-me use case should report failure and retry rather than tell the user the block landed.
- **N6 — resolved.** `UNIQUE NULLS NOT DISTINCT (tenant_id, user_id, signal_hash)`; the not-me block sits on the anonymous row and blocks every signal; `unblock(user)` clears every row (ADR-0001:227).
- **N7 — resolved.** Device-side failures are defined (declined, expired unconsumed, not-me). `approve` has per-approver-session and per-tenant wrong-code limits, and lookup misses alert (ADR-0007:157).
- **N8 — resolved.** The release flag `approve_on_phone_enabled` lives in a class-G table, is written only by a reviewed migration, and is read by both the trigger and the sign-in API (ADR-0008:138, ADR-0007:159).

### New finding

**N9 — MINOR — The G table holding `approve_on_phone_enabled` is not named.**
- **Where:** ADR-0008:138 says "a class-G table" without a name. ADR-0001 requires every G table on the allow-list (C3), and neither ADR-0001 § 1a nor TR-TABLE-CLASSES-R9 ("G also holds …") lists it.
- **Fix:** name the table (for example `release_flags (flag, enabled)`), add it to the ADR-0001 G list and C3 allow-list, and add it to TR-TABLE-CLASSES-R9, in the same edit.
