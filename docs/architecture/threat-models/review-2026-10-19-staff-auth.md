# Independent review: threat model `staff-auth.md` (2026-10-19)

> **Reviewed**: `docs/architecture/threat-models/staff-auth.md` at commit 7053ee2 (Status Draft, verdict NOT ASSESSED)
> **Reviewer**: independent fresh session (reviewer, not author). No file other than this one was changed.
> **Method**: `.claude/skills/threat-model/SKILL.md` and references 2–4; template `.claude/docs/templates/threat-model.md`. Checks C1–C14 were re-run against the inputs. All 104 distinct `0007:n` / `0008:n` citations were read against the ADR lines. Every ASVS ID and level in § 8 was compared with the CSV by script. The API Top 10 and MASVS rows were compared with the repo's saved copies.
> **Inputs read**: ADR-0007, ADR-0008 (Accepted 2026-10-19); `architecture-review-2026-10-19-adr-0008.md` (B1, M5, M7, R1, R4, item 11); ADR-0001/0003/0005 lines the model cites; `docs/research/staff-auth-and-roles.md` (RN lines cited); `tenant-isolation.md` and `licensing.md` (TI/LIC IDs cited); `project.yaml`; `docs/stack-reference/`; `docs/research/evidence/staff-auth-and-roles-part-3/asvs-download/asvs-5.0.0.csv` (sha256 `98c8fe91…cdf680`, matches the model); `docs/research/evidence/tenant-isolation/part-6/src/{api10/0x11-t10.md,masvs/MASVS-*.md}`.

## Verdict: CONCERNS

There is no blocker. The model's own verdict, **NOT ASSESSED**, is correct, and I derived it independently:
- no BLOCKED condition holds: every sensitive area is covered, every threat has a mitigation or a § 7 row, and every High residual has a named acceptor;
- the two NOT ASSESSED causes are real: `project.yaml:47-51` leaves `distribution.model` and `tenancy.model` empty, and `docs/stack-reference/` has no desktop-runtime layer (`compose/` is Jetpack Compose for Android).

The model's claim that it would otherwise be COMPLETE (staff-auth.md:701) holds only mechanically. It still needs:
- four threats added (findings 5–8);
- two residuals corrected (findings 2 and 3);
- one founder decision (M10) reconciled with ADR-0008's catalogue (finding 1).

All of this should happen before the amendment batch writes the decisions into the ADRs.

**Findings: BLOCKER 0 · MAJOR 9 · MINOR 9.**

## Checks C1–C14 (re-run)

| # | Ran | Result |
|---|---|---|
| C1 | ran | Pass. Authentication → TB1, TB2, TB3. Authorization model → T1.20–T1.23, TB5. Admin → TB2, TB8. PII export/delete → T1.14, T1.15, T5.13, P1–P11. New integration → TB6, TB7. |
| C2 | ran | Pass. TB1–TB10 appear in the Mermaid edges, the boundary table and the STRIDE headings; the Mermaid block exists. One flow is not drawn (finding 17). |
| C3 | ran | Pass on categories: all six per boundary, with N/A reasons on T9.7 and T6.11. Fails the method rule that each rating is reasoned (finding 4). |
| C4 | ran | Pass. All 10 cross-tenant prompts are answered by a threat ID or `N/A - reason`. |
| C5 | ran | Pass. 28 abuse cases. Licence bypass is deferred to `licensing.md` with a reason (licensing is not a Required-because area here). |
| C6 | ran | Pass. Every T and AB row has a mitigation or a § 7 row; T9.7 is N/A with a reason; every M addresses at least one threat. There are 47 one-way traceability links (finding 14). |
| C7 | ran | Pass on form: 54 `NEW:` stories with named tests; Done 0 / Planned 54 / Gap 0 matches staff-auth.md:511. Several named tests do not exercise the threats they claim (finding 9). |
| C8 | ran | Pass. All 107 ASVS 5.0.0 IDs exist in the CSV with the level printed. The 7 API Top 10 2023 names match the saved `0x11-t10.md`. The 5 MASVS 2.1.0 controls match the saved control files. NOT SOURCEABLE mapping rows: 0. Count wording is off (finding 15). |
| C9 | ran | No Unaccepted High residual. Seven High residuals (R3, R4, R6, R7, R12, R12b, R15) each name Kamel Mohamed, founder, 2026-10-19, with a trigger. Problems: R3/R4/R7 scope (finding 3), R15's compensating control (finding 2), event-only review-by (finding 13). |
| C10 | ran | Pass. The secrets table covers location, reader, rotation and logging. Throttle-HMAC and email-credential rotation are marked "Not stated", which is acknowledged. |
| C11 | ran | Pass. Covers email provider, KMS, breached-password source, bot defence, Bitwarden and Tailscale, and the AI-agent CI provider. |
| C12 | ran | Pass. The privacy review is done from the repo's saved law and regulation extractions; GDPR and Labour Law 14/2025 are recorded as NOT SOURCEABLE; no EU population is named. |
| C13 | read-through | Pass. No secret, key material, working exploit or customer data. Only public URLs, a truncated CSV hash, role names and generic technique names (`docker inspect`, `/proc/<pid>/environ`). No scanner was run on the file. |
| C14 | ran | Pass. Required because, Standards versions and Next review are present. One pointer is wrong (finding 12). |

## Citation spot-check

I checked all 104 distinct `0007:n` / `0008:n` citations, not a sample. 97 point at the line that plans what the model says; the 7 that do not are listed in finding 10. I also spot-checked these references, and all are correct:
- `0005:127`, `0003:99`, `0001:90-98`, `0001:116`, `0001:119`, `0001:295`, `0001:302`;
- `RN:448`, `RN:501`, `RN:613`;
- TI T4.1, T4.2, T5.2, M19, M29, M31, M32, M49, M50, M63, M64, M65, AB3, R-2, R-3, R-4;
- LIC T3.6, T3.7, T4.2, AB1, AB19.

## Coverage of the named inputs

| Input | Where | Result |
|---|---|---|
| ADR-0008 review B1 | T4.1, AB10, M11, M12 | covered |
| M5 | T5.13, R18 | covered |
| M7 | T4.6, T4.7, AB7, AB11, M15, R8 | covered |
| R1 (path ii) | T4.2, M10, M11 | covered |
| R4 | T4.15, R17 | covered |
| § 10 item 11 | T4.3, T4.4, T4.19, TB9, AB15–AB17, M48, M49, R21 | covered. Two of the ADR's listed inputs have no row (finding 16). |
| ADR-0007 residuals by name | 6.3.3 L2 → R5; 6.3.3 L3/AAL3 → R6; 13.3.3 → R3; 6.1.1 → R2; TPM-less restore → R1 | present. Names and dates match. Where the ADR gives a trigger, it matches (R1 0007:219, R6 0007:202/441, R3 0007:442). |
| ADR-0008 residuals by name | 13.3.1/13.3.3 → R4, R7; aggregate budget → R9; widened 6.1.1 → R8; F421 → R12; F422 → R12b; R-7 widened → R14; 16.4.3 → R13; PIN-in-password → R11 | present. Names, dates and the "KMS move or first multi-counter venue" trigger (0008:342) match. The key scope is wrong (finding 3). |
| Founder trigger for R2, R5, R8, R9 | staff-auth.md:520, 523, 526, 527, 551, 692 | consistent everywhere |
| Founder decisions M2, M9, M10, M11, M13, M14, M15, M17, M21, M22, M26, M31; R15–R21 | § 6, § 7, § 9, § 10 | consistent in wording, with three exceptions: M10 conflicts with ADR-0008 (finding 1); the decision-list pointer and M53 (finding 12); the 7b trigger quote (finding 12) |
| M22 → M52 renumbering | every T3.x row, AB12, AB14, R1, R12, § 8 V6.5.6 and V14.2.4 | applied everywhere. No row uses M22 to mean the device store. |

## Findings

### MAJOR

**1. M10 makes `dashboard_reset` owner-only, but ADR-0008 gives "require a PIN reset" to `staff.reset_pin` holders, managers included.**
- **Where:** staff-auth.md:236 (T5.6) and :465 (M10); ADR-0008:146, :174, :271, :460.
- **What is wrong:**
  - T5.6 says `dashboard_reset` facts "have no catalogue key". ADR-0008:146 and :271 map "require a PIN reset" to `staff.reset_pin`, and the manager template holds that key (0008:174).
  - M10's database guard `app.branch_all = 'on'` would therefore remove a manager capability the Accepted ADR grants, without saying so.
  - The amendment batch would write that contradiction into ADR-0008.
- **Fix:** Ask the founder which was meant, then do one of the following:
  - restate M10's `dashboard_reset` guard as "`staff.reset_pin` plus the strict-subset rule, checked in the database" (owner-only stays for `PinVerifiers.confirm` alone); or
  - list the move of "require a PIN reset" to owner-only as an explicit amendment to ADR-0008 § 1, § 2 and § 8.

  Then correct T5.6's premise either way.

**2. R15 (a High residual) rests on an "owner enrolment notice" that no ADR plans and that no mitigation builds.**
- **Where:** staff-auth.md:476 (M21) and :543 (R15).
- **What is wrong:**
  - M21 says the interim password path "keeps … enrolment notice to the owner (0008:631)". 0008:631 only requires that no capture contains the password.
  - ADR-0007's notice list (0007:172, :236) has no enrolment notice; 0007:471 offers only an enrolment fact "visible to the owner".
  - "No session" is 0007:210, and "password zeroised" is not in either ADR.
  - Whether a counter password-path sign-in raises the new-device alert is also unstated.
- **Fix:** Make the owner enrolment notice, and a new-device alert on counter password-path sign-ins, explicit Planned deliverables of M21 (or a new M), each with a negative test. Then correct the citation and have the founder re-confirm R15 on the corrected compensating controls.

**3. R3, R4 and R7 accept 13.3.1/13.3.3 for every host key. The by-name acceptances in the ADRs cover fewer.**
- **Where:** staff-auth.md:254 (T6.1), :255 (T6.2), :521–522, :525.
- **What is wrong:**
  - ADR-0008:333 accepts 13.3.1 and 13.3.3 for the verifier master key and the pepper only.
  - ADR-0007:442 accepts 13.3.3 for the pepper and the TOTP key only.
  - T6.1 and T6.2 also put these in the secret file and in memory: the TOTP key (for 13.3.1), the throttle-HMAC key and the new M13 receipt key.
  - § 7a calls the rows "carried unchanged", but they silently widen the scope.
- **Fix:** Name all five keys in R3 and R4 and have the founder confirm the widened scope. Add the TOTP, throttle-HMAC and receipt keys to the ADR-0007/0008 amendment batch beside the R2/R5/R8/R9 trigger.

**4. Likelihood and impact ratings are mostly unreasoned, against the method rule and the model's own claim at :127.**
- **Where:** staff-auth.md:127; § 4 tables (:133–:318).
- **What is wrong:**
  - The rule is "L / M / H with a one-line reason" (references/2-stride-and-abuse.md). Only 5 of 139 likelihood cells give a reason.
  - Of 67 High-impact rows, 34 give no reason for either rating, for example T1.22, T1.24, T2.2, T4.10, T4.19, T5.1, T6.2, T8.1–T8.8 and T10.2–T10.8.
  - Among High-impact rows with likelihood M, the likelihood is unreasoned on T1.3, T1.4, T1.9, T1.10, T1.11, T1.16, T1.21, T1.24, T2.2, T3.1, T3.12, T4.2, T5.6, T5.9, T6.2, T7.7, T10.1, T10.2, T10.3 and T10.8.
- **Fix:** Add a one-line reason to every likelihood and impact cell of the High-impact rows at least, and change :127 to say what is actually there until the rest are done.

**5. Missing threat: the issuer of a temporary credential can use it before the person does.**
- **Where:** TB1 and TB3 tables (nearest row T3.16, staff-auth.md:199); ADR-0007:192, :211, :230.
- **What is wrong:**
  - Three issuers see the temporary credential they hand over:
    - the sponsor sees the temporary PIN at sponsored enrolment;
    - the resetter sees the temporary PIN at a counter reset;
    - the `staff.manage` holder sees the temporary dashboard password.
  - Any of them can enter it first and set the "lasting" credential, then act as that person. That defeats ASVS 6.4.6's intent (V6.4.6 is mapped at :582).
  - On the counter, the resulting verifier is device-minted and can then be owner-confirmed under M11.
  - No row models this race. AB6 covers only peers acting under the strict-subset rule.
- **Fix:** Add T1.x and T3.x rows (Spoofing/Repudiation) with detection: a person notice on first use of the temporary credential, and a "first sign-in failed with my temporary credential" path. Add a negative test, such as "temporary PIN already consumed by another sign-in is reported to the person and the owner".

**6. Missing threat: local suspend and lift (`staff.suspend_local`).**
- **Where:** TB3 and TB4 tables; ADR-0007:228; ADR-0008:147, :190.
- **What is wrong:**
  - A person holding `staff.suspend_local` suspends an approver on the counter. The suspension takes effect at once, so approvals there stop.
  - A compromised counter can upload a forged "lift" fact for a suspended person, because the lift is device-minted and the server cannot check the lifter's PIN.
  - No row and no test cover suspend or lift. `grep suspend_local` finds nothing in the model.
- **Fix:** Add a DoS row (malicious local suspend) and a Tampering row (forged suspend or lift fact at sync). Map them to M15/M24-style server checks (strict-subset judged at sync, flag, owner alert) with a named negative test.

**7. Missing threat: M22's "not me" link fired by mail-security scanners or link prefetch.**
- **Where:** staff-auth.md:477 (M22 b) and :280 (T7.11).
- **What is wrong:**
  - Many mail providers and corporate gateways open links automatically.
  - A "not me" link that acts on GET would end the owner's own pending sign-in, block their password path and end all their sessions, whenever the notice is sent during a legitimate sign-in.
  - T7.11 models only a human mailbox holder.
- **Fix:** Add the threat to TB7. Make M22(b) require a confirming POST behind the link, and send the "second factor pending" notice only after the factor step has stalled for a configured time. Add the test "a GET on the not-me link changes nothing".

**8. M2 leaves a repeatable malicious lockout of a known identifier's password path, recorded as no deviation.**
- **Where:** staff-auth.md:457 (M2), :150 (T1.18) and :559 (§ 8 V6.1.1).
- **What is wrong:**
  - Anyone who knows a username can drive it to the 100-failure block, again after every reset:
    - a factorless non-privileged staff login (R5 population) has no passkey or recovery code, so it is fully locked out until the owner intervenes;
    - a TOTP-only owner burns recovery codes.
  - § 8 marks V6.1.1 "Deviation accepted (R2, R8, R9)", but those are counter-only lockouts.
- **Fix:** Either add a by-name 6.1.1 residual for the dashboard password-path block (founder, with a trigger) and correct the V6.1.1 row, or extend M2 so the block applies only to attempts that are not preceded by a valid factor or device signal. Add a test for re-blocking after reset.

**9. Several mitigations claim High threats that their named negative test never attempts.**
- **Where:** staff-auth.md:497 (M42), :483 (M28), :508 (M53).
- **What is wrong:**
  - M42 has one test, the enrolment-only state, yet it is the main control for:
    - T1.11 (M/H: a stolen session adds the attacker's factor or contact). Nothing tests that a factor or contact change without full re-authentication is refused (ASVS 7.5.1).
    - T1.20 (a privileged key gained without a factor). Untested.
  - M28 has one test, a secret-read command, for eight TB10 threats. There is none for T10.4 (the fixed script called with arguments or a stolen CI token), T10.6 (attribution) or T10.8 (docker-group membership).
  - M53's tests check retention and export on the happy path only.
- **Fix:** Add named negative tests:
  - M42: `` `factor add without password and factor re-entry is refused` `` and `` `role gaining a privileged key sends the login to enrolment` ``;
  - M28: `` `deploy script invoked with arguments refuses` ``, `` `agent account is not in the docker group` `` and `` `deploy record names agent or founder` ``;
  - M53: `` `erased person's upload facts and codes are absent from the extract and the database` ``.

### MINOR

**10. Seven of 104 distinct ADR citations do not point at the planning line.**
- **Where and what:**
  - staff-auth.md:597, V7.2.1 "device-local session": cites `0007:220` (switching); the session is `0007:222`.
  - :476, M21: cites `0008:631`, which carries none of the listed controls except "no capture contains the password" (finding 2).
  - :605, V7.4.3: cites `0007:171`; "a factor change ends every other session" is `0007:170`.
  - :583, V6.5.1: cites `0007:177` (step-up); TOTP single use is `0007:167`.
  - :586, V6.5.4: cites `0008:349` (CSPRNG); the 8-character entropy floor is `0008:350`.
  - :207, T4.3 "non-privileged only": cites `0008:359`; that restriction is `0008:345` and `0008:371`.
  - :147, T1.15 cites `0008:234` for three claims. The tenant-level trail rule is `0008:245`, and the session list is `0007:170`.
- **Fix:** Correct each citation as listed.

**11. The 7.2.1 recorded deviation is filed as residual R20.**
- **Where:** staff-auth.md:528 (R10), :548 (R20), :193 (T3.10), :597.
- **What is wrong:** ADR-0007:222 and :437 record 7.2.1 (device-local session) as a recorded deviation, but R10 leaves it out. The walk-away risk is labelled the 7.2.1 deviation; it is closer to 7.3.1, idle timeout.
- **Fix:** Add 7.2.1 to R10. Relabel R20, T3.10 and the V7.2.1 row to the walk-away residual and V7.3.1.

**12. Small inconsistencies in how founder decisions are recorded.**
- **Where:** staff-auth.md:6, :539, :551, :508.
- **What is wrong:**
  - The header says the amendments carry "the decisions in § 7a"; the decision list is at :551, after § 7b.
  - :551 lists M53 under "Founder decisions … that need dated amendments", but M53 (:508) is not marked "Decided (founder)".
  - § 7b quotes the founder as "Accept all, review at KMS", while recording the trigger "KMS move or first multi-counter venue".
- **Fix:** Point the header at :551. Mark M53 as founder-decided or move it out of that list. Confirm the 7b trigger wording with the founder.

**13. Review-by is an event, never a date, for 21 of 22 residual rows.**
- **Where:** staff-auth.md:520–549.
- **What is wrong:** SKILL.md Phase 5 and C9 ask for a review-by date. Only R1 has one (2027-04-18). The header's "at the latest 2027-04-18" (:6) backstop is not carried to the rows.
- **Fix:** Append "or 2027-04-18 at the latest" to each event-only trigger, with the founder's agreement, so no residual depends only on an event that may never happen.

**14. 47 one-way traceability links between § 4/§ 5 and § 6.**
- **Where:** § 4, § 5 and § 6.
- **What is wrong:**
  - The Addresses column of M50 is "High threats per § 5", yet M50 is attached to non-High rows (T1.18, T3.4, T3.5, T3.7, T3.11, T3.13, T4.6, T4.7, T4.11, T4.15, T4.16, T6.8, T7.6, T9.1, T9.2, T9.6, AB7, AB26).
  - Links named on the threat side but missing from the mitigation's Addresses: T1.3→M6, T7.10→M26, T8.1→M36, AB1→M2, AB2→M5/M6, AB5→M42, AB20→M26.
  - Links named on the mitigation side but missing from the threat row: M34→T2.8/T2.10, M44→T7.5.
- **Fix:** List M50's threats explicitly and make each link two-way.

**15. Wrong row count for the ASVS CSV, and one chapter label.**
- **Where:** staff-auth.md:555, :594, :654.
- **What is wrong:**
  - The model says the CSV has "346 rows"; it has 345 requirement records (347 lines, one header).
  - V11.7.2 sits under "Data protection", but it is V11.7 "In-Use Data Cryptography". The count line already counts it in V11.
- **Fix:** Say 345 in both places and relabel the row "Cryptography".

**16. ADR-0008's threat-model inputs without a row of their own.**
- **Where:** ADR-0008:365–371 and :651–666; staff-auth.md:503 (M48).
- **What is wrong:** These inputs have no row of their own (coverage is indirect at best):
  - a role edit silently widening authority (0008:651, :547);
  - self-approval (0008:651): tested in M24 but never a threat;
  - feed injection, or a planted verifier in the local store (0008:656): T3.7 omits verifier rows;
  - verifiers, salts or PINs in logs (0008:660);
  - a stolen owner session issuing activation codes (0008:368);
  - a code redeemed at a wrong-branch counter (0008:369);
  - a backdated claim time that avoids `approver_authority_changed` (0008:220).

  M48's named test also omits the wrong-branch and privileged-person refusals of 0008:630.
- **Fix:** Add a row, or an explicit "covered by Tx.y" line, for each input. Extend M48's test with the two missing refusals.

**17. The counter's password-path call to the dashboard sign-in API is not drawn.**
- **Where:** staff-auth.md:98–123 (diagram and boundary table), :195 (T3.12).
- **What is wrong:** The counter calls the dashboard sign-in API (`app_rt`, 0007:210). That flow crosses venue → app on the dashboard surface, and it is subject to TB1 throttling and the CGNAT question. It is neither a diagram edge nor in the "Data crossing" column of TB1 or TB4.
- **Fix:** Add the edge (TB1 or TB4, say which) and list it in that row.

**18. "Planned" status alone does not show that the M21 test is deferred.**
- **Where:** staff-auth.md:476, :511.
- **What is wrong:** M21's third test is "after research" and depends on a design that does not exist yet, but the counts line reports "Planned 54" with no qualifier on the test.
- **Fix:** Tag the deferred test "(after research)" in the § 6 counts line as well, so the C7 count does not overstate the named tests.

## What this review did not do

- It did not edit the model, any ADR, the registry or the research note, and it ran no scanner.
- It did not re-fetch the online ASVS, API Top 10 or MASVS documents; the comparison used the repo's saved copies, whose hash matches the model's.
- It did not re-read the NIST SP 800-63B-4 text (the model also cites it only through the ADRs).

## Re-check 2026-10-19

> **Scope:** the uncommitted working tree after the authoring session's fix batch:
> - `staff-auth.md`;
> - the dated amendment blocks and inline notes in ADR-0001, ADR-0005, ADR-0007 and ADR-0008;
> - `docs/registry/architecture.yaml`.
>
> Same reviewer. No file other than this one was touched.

### Verdict: CONCERNS

All 18 findings are resolved. The amendments carry the founder's decisions faithfully, and the registry follows its append-only rule. The fixes introduced two new MAJOR items and five MINOR ones (below).

There is still no blocker. The model's verdict, NOT ASSESSED, still stands for the same two causes.

Mechanical re-run of the model:
- 149 threat rows, 30 abuse cases, 56 mitigations and 23 residual rows, matching the revision history;
- all 69 High-impact rows give a reason for both ratings;
- every threat and mitigation link is two-way (0 one-way, was 47);
- no ID is duplicated.

### (a) The 18 findings

| # | Result | Evidence |
|---|---|---|
| 1 | resolved | M10 (:478) is owner-only for `PinVerifiers.confirm`, and `dashboard_reset` stays with `staff.reset_pin` plus the strict-subset rule. T5.6 (:246) is corrected. ADR-0008 § 1 owner-only row adds `staff.confirm_verifier`; the manager template is untouched. |
| 2 | resolved | M21 (:489) adds the zeroising, the owner enrolment notice and the new-device alert as deliverables with a test. ADR-0007 amendment block (counter password path). R15 (:559) is re-accepted on the corrected controls. |
| 3 | resolved | R3 and R4 (:537–538) name the four keys and are re-accepted. ADR-0008 amendment block and ADR-0007 deviation list carry the scope. The receipt key is gone (M13 is keyless). |
| 4 | resolved | Every High-impact row gives both reasons (checked by script); :128 states what is there. |
| 5 | resolved | T1.27, T3.17, AB29, M55 with two negative tests; ADR-0007 § 5 and § 8 notes. |
| 6 | resolved | T3.18, T4.22, AB30, M56; ADR-0007 § 8 note. See new item N3 for a wording clash. |
| 7 | resolved | T7.12; M22(b) uses a confirming POST and a stall delay; test "a GET on the not-me link changes nothing". |
| 8 | resolved | M2 narrowed; R22 accepted; the V6.1.1 row names R22. The narrowing opens new item N2. |
| 9 | resolved | M42, M28 and M53 each gained the tests proposed. |
| 10 | resolved | All 7 citations are corrected against the pre-amendment ADR text. New item N1 makes the scheme stale. |
| 11 | resolved | R10 holds 7.2.1 (0007:222, :437); R20, T3.10 and V7.3.1 relabelled. |
| 12 | resolved | Header points to § 7c; M53 marked decided; § 7b explains the trigger quote. |
| 13 | resolved | Every residual carries "2027-04-18 at the latest"; ADR-0007 and ADR-0008 state the backstop. |
| 14 | resolved | M50 lists its threats; 0 one-way links. |
| 15 | resolved | "345 requirement rows" (:574, :613); V11.7.2 labelled Cryptography (:673). |
| 16 | resolved | T1.28, T1.29, T3.19, T4.23, T4.24; T3.7 now includes a planted verifier; M48 tests the wrong-branch and privileged refusals. |
| 17 | resolved | Diagram edge `CA -- TB1 --> NX` (:99); TB1 row lists the password-path call. |
| 18 | resolved | Counts line (:527) names the deferred M21 test. |

### (b) ADR amendments against the model and the untouched ADR text

- **Consistent with § 6/§ 7:**
  - ADR-0008: M9, M10, M11, M13, M14, M15, M17, the item-10 trigger with backstop, and the 13.3.1/13.3.3 key scope;
  - ADR-0007: M2 with R22, M31, the counter password-path notice and alert, temporary-credential first use, local suspend judged at sync, the R2/R5 triggers, and the 13.3.3 scope;
  - ADR-0005: the M53 defaults, markers, sub-processor table and breach register;
  - ADR-0001: the `Enrolment.consumeReceipt` § 1c row.
- **M10 against ADR-0008 § 1/§ 2/§ 8:** no contradiction. `staff.reset_pin` keeps "require a PIN reset" in § 1 (0008:146 old numbering), in the manager template (§ 2) and in § 8. `staff.confirm_verifier` is owner-only, so it falls in the privileged set by the § 1 rule ("every owner-only key").
- **M13 against ADR-0001 § 1c and ADR-0008's Implementation Guidelines:** consistent. The § 1c row gives `device_rt` EXECUTE, which is the role the PostgreSQL 18 trigger runs as (0008:75). The Must (data) bullets carry inline notes ("accepted only when the trigger consumes a matching receipt"; `device_rt` may insert `password_assertion` with a receipt). Three loose ends: N4, N5 and N6.
- **Untouched text that now contradicts an amendment:** see N5.

### (c) Registry

- **Append-only rule:** followed. The only lines removed are 5 `status: active` lines.
  - 7 entries became `superseded_by: … -> <successor>`. Two of them, TR-STRICT-SUBSET-R2 and IC-PIN-ACTIVATION-R2, had no `status` line before, so one was added. No entry's text was edited.
- **New entries:** 10, each `status: active`, `adr_status: Accepted`. Each successor exists. The file parses as YAML.
- **Header line:** the "7 superseded, 10 added" line is accurate.
- **Content:** the new entries match the amendments: M9 and M56 in TR-STRICT-SUBSET-R3; M10 in IC-PERMISSION-CATALOGUE-R2 and IC-PIN-VERIFIER-CUSTODY-R4; M13 in IC-PRE-CONTEXT-LOOKUPS-R10; M11, M15, M17, R15 controls and the temporary-PIN notice in IC-COUNTER-ENROLMENT-R6; M14 in IC-PIN-ACTIVATION-R3; M53 in TR-RETENTION-DEFAULTS-R5; M2 in IC-SIGNIN-FAILURE-CEILING; M31 in IC-NOTICE-GATED-FACTOR-CHANGE; FP-IP-ONLY-BLOCK.
- **One gap:** the temporary-password first-use notice (ADR-0007 § 5, M55) is in no entry (MINOR, N7).

### (d) New items introduced by the fixes

**N1 (MAJOR). Every `0007:n` / `0008:n` citation in the model now points at the wrong line of the amended ADRs.**
- **Where:** staff-auth.md:14 (citation scheme) and every citation.
- **What is wrong:**
  - The amendment blocks insert 9 lines into ADR-0007 near line 134, and 2 + 10 lines into ADR-0008 near lines 59 and 122.
  - Every citation after those points is now off:
    - `0007:164` (sign-in) now lands on the TOTP-secrets bullet;
    - `0007:173` (restore) now lands on the sign-in bullet;
    - `0008:241` (authorization logging) now lands on `authority_version`;
    - `0008:333` (deviations) now lands on "8. Lockout".
  - The model was cross-checked against the pre-amendment text, and the new rows cite it too, so the citations are internally consistent. They just don't match the files the reader will open.
- **Fix:** Pin the scheme in the method comment ("`0007:n` / `0008:n` = line n of the ADR at commit 7053ee2"). Or renumber every citation against the amended files once they are committed. Pinning is one line and cannot drift again.

**N2 (MAJOR). M2's known-device exemption removes the 100-failure ceiling for attempts that carry the device signal, and the device cookie itself is undesigned.**
- **Where:** staff-auth.md:470 (M2), :566 (R22); ADR-0007:137 and :173 (amendment); registry IC-SIGNIN-FAILURE-CEILING.
- **What is wrong:**
  - "Only attempts without a known-device signal count toward the block" means guesses from a browser that holds the device cookie never reach the ceiling. They face only the per-identifier delay. Such a browser could be:
    - a shared office or venue PC where several staff once signed in;
    - a copied cookie.
  - That departs from the "100 consecutive failures" limit cited at 0007:164 (F106, F207) and from ASVS 6.3.1 as documented (V6.3.1 row, :591). No residual names it.
  - The device cookie is a new credential-like artifact, and no ADR states:
    - its attributes and lifetime;
    - whether it is bound to the login;
    - whether a password reset or `endOthers` revokes it;
    - its place in the crypto inventory.
- **Fix:**
  - Count known-device attempts too, in a separate per-(login, device signal) ceiling of at most 100 that blocks only that signal. Add the test "100 failures from a known browser block that browser's password path".
  - Define the cookie in ADR-0007 § 3: `__Host-`, HttpOnly, an opaque random value stored hashed, bound to the login, revoked by reset and `endOthers`.

**N3 (MINOR). Suspend and lift facts: "refused by the database" versus "flagged for owner review".**
- **Where:** ADR-0008 amendment block, M9 bullet; staff-auth.md:477 (M9 Addresses includes T4.22).
- **What is wrong:** The M9 bullet lists "a local suspend or lift accepted at sync" among writes the database refuses. ADR-0007's amendment, M56 (:525) and TR-STRICT-SUBSET-R3 say a failing fact is flagged and its lift is not applied beyond its device. A refused insert leaves nothing to flag.
- **Fix:** Reword the M9 bullet: the fact is always recorded; the database refuses only applying its effect (a suspension or lift beyond the device) when the strict-subset check fails.

**N4 (MINOR). M12's negative test contradicts M13.**
- **Where:** staff-auth.md:480.
- **What is wrong:** M12's test says `` `device_rt cannot insert a password_assertion or activation_code fact` ``. After M13, `device_rt` may insert `password_assertion` with a valid receipt (ADR-0008 Must (data) note; IC-PIN-VERIFIER-CUSTODY-R4). The test would fail against the correct build.
- **Fix:** Reword the test to `` `device_rt cannot insert an activation_code fact, or a password_assertion fact without a valid unconsumed receipt` ``.

**N5 (MINOR). Untouched ADR text that now contradicts an amendment.**
- **Where and what:**
  - ADR-0008:649, Validation: "A successful PIN sign-in reported at contact clears the person's failure sum". M15 now says a success clears only the same device's failures.
  - ADR-0008:443, `PinVerifiers.accept … Refused(…)`: lacks `privileged` (M14) and a receipt refusal (M13).
  - ADR-0007:339: `Enrolment.consumeAssertion … -> user | Refused` lacks the receipt that ADR-0001's row now returns.
  - ADR-0007:488, Cross-Cutting note: still scopes the 13.3.1 deviation to "the pepper and the verifier master key".
- **Fix:** Add an inline *(Amended 2026-10-19 by the staff-auth threat model …)* note to each of the four lines.

**N6 (MINOR). `Enrolment.consumeReceipt` binds a person id that the PL row may not hold.**
- **Where:** ADR-0001 amendment row; ADR-0008 M13 bullet.
- **What is wrong:** `enrolment_assertions` is issued for a login `user` (0007:329 old numbering). The receipt is "bound to … the person", and the trigger passes a staff `personId`. If the login id is not the staff id, the PL function needs a TD mapping, and that is outside `auth_lookup`'s one narrow TD read (0008:203 old numbering).
- **Fix:** State that the receipt binds the login `user` and that the trigger resolves `personId` to that login on the TD side. Or state that a login's id is its staff person id.

**N7 (MINOR). One registry gap and one wording point.**
- **Where:** registry; ADR-0005 retention table (breach-register row).
- **What is wrong:**
  - No registry entry carries the temporary-password first-use notice (ADR-0007 § 5 note, M55).
  - The breach-register row reads "5 years — PDPL executive regulation Art 5 secure register". The regulation requires the register; the 5 years is the founder's M53 default (the model, :433, says the law sets no number for these).
- **Fix:** Add the notice to the next IC entry that touches temporary passwords. Write the row's rule as "register required by REG Art 5; 5 years is the founder default (M53)".

**Counts: BLOCKER 0 · MAJOR 2 (N1, N2) · MINOR 5 (N3–N7).** Open items for the founder:
- N2: the ceiling for known-device attempts is a design choice.
- N1: choose pinned or renumbered citations.

The others are text fixes.
