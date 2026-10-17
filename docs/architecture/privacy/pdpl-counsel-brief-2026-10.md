# Counsel brief: Kodeebo and Egypt's Personal Data Protection Law 151/2020 and its executive regulation

> **To:** [FOUNDER TO FILL: counsel name / firm]
> **From:** Kodelix — [FOUNDER TO FILL: legal form], an Egyptian company; contact [FOUNDER TO FILL]
> **Date:** 2026-10-17 · **Status:** Draft for the founder to review and send
> **Prepared by:** Kodelix engineering (privacy-compliance-specialist role). The authors are not lawyers.
> **Answered by founder decision, not counsel (2026-10-17):** Q1, Q4, Q5 and Q6 — see the marked block under each question. Source: founder statement, until the founder adds counsel's written answer. **Answered by counsel (2026-10-17):** Q2 — counsel told the founder that no PDPL licence is needed now (marked block under Q2). **Still open for counsel:** Q3 (the exact end of the compliance period) and the written confirmation of the founder-recorded answers.

## How to read this brief

**Nothing in this brief is a legal conclusion.** Every statement about the law is our **reading of an
unofficial English translation**, marked **Reading [Sn]**, where *Sn* is the source in § 7. We have not
read the Arabic Gazette text of Law 151/2020 or of its executive regulation. Where the Arabic text,
the Centre's practice or other Egyptian law differs from our reading, the Arabic text and your view win.

Other labels:

- **Product fact**: true of the product or company today.
- **Design (not built)**: what we intend to build. Production code does not exist yet, so we can still change it.
- **Working assumption**: what engineering assumes until you answer. It is not a legal view and we do not rely on it as one.
- **Comparison only**: a foreign rule (EU GDPR, UK ICO). We quote it to explain the question. We do not claim it applies in Egypt.

## 1. What we ask of you

1. Written answers to the questions in § 4 (Q1–Q6), each citing the Arabic article text it rests on.
2. For each answer, where the Centre's published practice or forms (if any) differ from the text.
3. **The minimum Kodelix must have done by 2026-11-01** for Kodeebo, if your answer to Q3 confirms that date. Examples: a licence or permit application filed, a DPO registered, records of processing in place, contract terms changed with our customers. Also, what each venue (as a possible controller) must have done by then.
4. Any point we have missed that a POS vendor in our position should know about (§ 5 lists the ones we can see).

## 2. Who we are and what the product does

- **Product fact.** Kodelix is an Egyptian company. It builds and sells **Kodeebo**, a point-of-sale (POS) system for PlayStation lounges and cafés in Egypt. Kodeebo is in development; it has not launched and holds no personal data yet. Kodelix's earlier product, Glitch, is being retired and is out of scope of this brief (founder decision, 2026-10-17).
- **Product fact.** Delivery is **hosted only**. Kodelix runs the server and the owner's web dashboard. The venue installs the cashier app on its own Windows PC. There is no self-hosted edition.
- **Hosting.** The current plan is a **VPS in Germany**; the alternative is **hosting in Egypt**. Hosting outside Egypt is cleared (Q6, answered by founder decision, not counsel, 2026-10-17); the location is fixed in our hosting architecture decision record. Provider under the current plan: [FOUNDER TO FILL]. Where backups would be stored: [FOUNDER TO CONFIRM — same provider and country, or elsewhere].
- **Product fact.** Each customer (the "tenant") is the owner's organisation. A tenant has one or more branches (venues), and each branch has one cashier PC. The owner and managers use the web dashboard and an Android app.
- **Design (not built).** The cashier PC works **offline first**. It keeps its own encrypted local copy of recent business data and sends changes to the hosted server when the internet is available. The server sends prices and settings back down.

### 2.1 Personal data in the first release

| Data | Whose | Why it is held | Where it is held | Retention (proposed by us, **not yet** checked against law) | Lawful basis |
|---|---|---|---|---|---|
| Staff name, role, branch assignment | the venue's employees | the venue manages who may use the till and with which permissions | hosted server (Germany planned, Egypt the alternative; hosting outside Egypt cleared, see Q6); the venue's cashier PC | while employed at the venue, then see Q4/Q5 | **counsel** |
| Staff passcode (sign-in on the cashier PC) | the venue's employees | identifies who performed each till action | **Design:** one-way hash on server and PC; never exported | while the account is active | **counsel** |
| Clock-in / clock-out (attendance) | the venue's employees | the venue tracks who was on shift; the owner sees it remotely | hosted server; cashier PC | **open**: see Q5 (Labour Law) | **counsel** |
| Activity log: which staff member did each sale, void, discount and cash paid-out | the venue's employees | the venue's control of cash leakage (the product's core purpose) | hosted server; cashier PC | **Design:** kept as part of the tax archive, at least 5 years (see Q4) | **counsel** |
| Owner / manager account: name, phone or e-mail, sign-in records | the venue's owner and managers | Kodelix's contract with the customer, security, support | hosted server | duration of contract, then **open** | **counsel** |
| Sales and receipt records; a buyer's national ID **only** when an ETA rule requires it (Reading [S6]: a consumer sale above EGP 150,000) | a buyer, rarely | the venue's tax obligations | hosted server (tax archive) | **Design:** at least 5 years after the tax period (see Q4) | **counsel** |

**Not in the first release:** customer records, loyalty or walk-in profiles (planned for a later release); biometric clock-in; card data (none is handled at any point).

**Who can see staff data.** The venue's owner and the managers the owner authorises. Kodelix support
staff, for support and operations only. Kodelix staff work from Egypt and reach the hosted server
remotely, wherever it is located. [FOUNDER TO CONFIRM.]

### 2.2 Retention and deletion as designed today (not built; subject to your answers)

- **Tax archive.** **Design (founder decision).** The hosted server keeps every sale, receipt, cancelled or returned original and audit record, append-only, for **at least five years after the tax period**. The period is a per-venue setting. The archive lives **on the hosted server only**. The owner can export it with a hash manifest. Reason: our reading is that the five-year keeping duty sits with the venue as taxpayer (Reading [S5], [S10]).
- **Cashier PC.** **Design (provisional).** The PC keeps a bounded recent window of about **60 days**. A record leaves the PC only after the server has confirmed it.
- **Backups.** **Design.** Server backups expire on a rolling window **shorter than 60 days**; the exact figure is not set. A single person's or a single venue's data **cannot be removed from inside a backup**: the backup tools encrypt and expire whole backups, never per customer. After any restore, a deletion journal kept outside the database is replayed, so a restore cannot bring back deleted personal data.
- **Closing a venue's account.** **Design.** The owner asks, and the request goes through a cooling-off period. The owner then has an export window. After it, staff personal data and other personal data not needed for tax are deleted. The tax archive is kept apart, with identities removed where the tax record does not need them, until its period ends. Then it is deleted. Every step is logged with date and time.
- **Option held in reserve.** Per-venue encryption of staff personal fields, where deleting the key makes every copy unreadable, backups included. It costs a lot to build and run. We would build it only if your answer to Q4 requires erasure from backups faster than the backup window.

## 3. What we read

Two unofficial English copies (§ 7, [S1] and [S2]) of:

- **Law No. 151 of 2020** on the Protection of Personal Data (the "Law"). The copy we read gives no Gazette issue number or publication date for the Law. We could not find them (see Q3.4).
- **The executive regulation** (the "Regulation"): Minister of Communications and Information Technology **Decree No. 816 of 2025**, which our copy says was printed in **Al-Waqa'i' al-Misriyya Issue No. 244, Supplement A, dated 1 November 2025**. Law-firm websites agree on that number and date; we treat them as leads only.

## 4. Questions

### Q1. Controller or processor: the venue and Kodelix, for staff data

> **Answered by founder decision, not counsel (2026-10-17).** The venue owner is the controller of staff
> data; Kodelix is the processor and acts on the owner's written instruction. Source: founder statement,
> until counsel's written answer is added.

**Facts.** The venue decides to record attendance and to give each employee a till passcode, and the
venue's owner decides who sees the data. Kodelix provides the software, stores the data on its hosted
server and gives support. Kodelix also holds data for its own purposes: owner/manager accounts,
billing and security logs.

**Reading [S2] (Law Art. 1, definitions).** A *controller* decides the method, manner and criteria of
retention or processing for a defined purpose. A *processor* processes on the controller's behalf under its
instructions **and a formal agreement**. A *data holder* is a third defined role. On a plain reading the
venue fits "controller" and Kodelix fits "processor" for staff data. Kodelix may be a controller for its
own purposes.

**Reading [S2] (Law Art. 5; Regulation Art. 4).** A processor acts only on written instructions. It must
delete the data when processing ends, or deliver it to the controller. It keeps a processing record that
includes a copy of the contract with the controller and **the date and time of erasure or of delivery to
the controller**.

**Questions.**

- **Q1.1** For staff attendance, passcodes and the staff activity log, is the venue the controller and Kodelix the processor? Or does Kodelix's role in hosting, retention design and support make it a joint controller or a "data holder"?
- **Q1.2** For owner and manager accounts, billing and Kodelix's own security logs, is Kodelix the controller?
- **Q1.3** What must the "formal agreement" between venue and Kodelix contain? Does our customer contract need a data-processing addendum before 2026-11-01? Must it be in Arabic, signed or registered?
- **Q1.4** Requests from staff (access, correction, erasure, objection). Reading [S2] (Law Art. 10): a decision is due within **six working days**, and silence counts as refusal. Does that time limit bind Kodelix when a request reaches it, or only the venue? May Kodelix pass the request to the venue?
- **Q1.5** Breach notification. Reading [S1], [S2] (Law Art. 7; Regulation Art. 5): **both** controller and processor notify the Centre within **72 hours**, and data subjects are notified within three business days. If Kodelix is the processor, does Kodelix notify the Centre itself as well as the venue? Who notifies the venue's staff? Does "unauthorised access" without any damage count as a breach?
- **Q1.6** Regulation Art. 3: does the duty to **notify the data subject of an erasure** fall on the venue only? (Reading [S1].)

**Working assumption.** The venue is the controller and Kodelix the processor for staff data. Kodelix is the
controller for owner accounts, billing and its own logs. The product records the date and time of every
erasure and export.

### Q2. Licence or permit from the Centre, and a Data Protection Officer

> **Answered by counsel (2026-10-17).** Counsel told the founder that no PDPL licence is needed now.
> This replaces the earlier founder-decision line "the required PDPL licences have been obtained".
> Source: counsel's advice as reported by the founder; the written advice is to be added by the founder.

**Reading [S1], [S2] (Law Arts. 4, 5, 8, 12; Regulation Arts. 3, 4, 7, 8, 36).** Controllers and processors
hold a **licence (3 years) or permit (up to 1 year)** from the Personal Data Protection Centre. A legal
entity appoints and registers a **DPO**. A DPO must hold qualifications, pass the Centre's tests and be
entered in the Centre's register; the Centre decides within 30 business days. Licence and permit
applications go through the Centre's portal. The Centre decides within **90 business days** of a complete
file, and **silence counts as rejection** (Regulation Art. 36; located by us in the saved copy). Sensitive
data has its own licence route (Law Art. 12; Regulation Art. 14).

**Questions.**

- **Q2.1** Does Kodelix need a licence or a permit as a processor, as a controller, or both? Which category, and on what evidence (volume, data type)?
- **Q2.2** Does each venue (a small business, usually one site, with a handful of staff) need its own controller licence or permit for staff attendance and passcodes? Can Kodelix assist, or does each venue apply itself?
- **Q2.3** Must Kodelix appoint and register a DPO? Can it be an employee of Kodelix, a founder, or an outside provider? What happens while registration is pending?
- **Q2.4** If an application is filed before 2026-11-01 but not decided, may Kodelix keep processing in the meantime?
- **Q2.5** Our reading: passcodes are credentials and attendance is not in the "sensitive data" definition (health, biometric, financial, children). Is that correct? Is a till activity log that links an employee to cash handling "financial" data? Would fingerprint or face clock-in (not planned for Kodeebo) make it sensitive?

**Working assumption.** Kodelix needs a licence or permit and a DPO. Nothing is filed yet.
*Superseded by counsel's answer above (2026-10-17).*

### Q3. Does the one-year compliance period end on 2026-11-01?

**Reading [S2] (Law, promulgation Art. 6).** Entities subject to the Law must regularise their status
within **one year from the date of issuance of the Regulation**. **Reading [S1] (Decree Art. 2).** The
Regulation is in force the day after publication, i.e. 2 November 2025. If it was issued on 1 November
2025, the year ends on **1 November 2026**.

**Questions.**

- **Q3.1** Please confirm the decree number, Gazette issue and date **against the Arabic Gazette** (Issue 244, Supplement A). We have only an unofficial English copy.
- **Q3.2** Does "issuance" mean the date the Minister signed the decree, the Gazette date or the date it came into force? How is the year counted, and does it end on 1 or 2 November 2026? Does a Friday/Saturday or holiday shift it? (1 November 2026 is a Sunday.)
- **Q3.3** What does "regularise status" mean in practice? A licence held, an application filed, or the duties in force (records of processing, DPO, contracts)?
- **Q3.4** The Gazette issue and date of Law 151/2020 itself. Our copies give none. Law-firm sites say published 15 July 2020, but they disagree on the date it took effect.
- **Q3.5** Has the Centre published any extension, transition rule or announcement on this period?

### Q4. Erasure vs the five-year tax archive vs backups; does destroying a key count as erasure?

> **Answered by founder decision, not counsel (2026-10-17).** Deletion follows the staged closure in § 2.2
> (purge personal data; tax archive kept segregated for its period; backups expire inside the window;
> deletions replayed after any restore); export in open formats to the owner; per-venue key destruction
> stays the escalation. **Destroying a key counts as erasure.** Source: founder statement, until counsel's
> written answer is added. Not decided by this answer: which fields of the tax archive stay identifiable (Q4.2).

**Facts:** § 2.2. The tax archive identifies the staff member behind each sale, void and paid-out, and
holds a buyer's national ID where an ETA rule requires one.

**Reading [S1], [S2] (Law Arts. 3, 4; Regulation Art. 3).** Data is not kept longer than its purpose
needs. When the purpose ends, the controller erases it, "unless there is a legitimate reason to retain it".
In that case the data must **no longer identify** the data subject, and it is erased when that reason ends.
A record is kept of every erasure request and of data kept for legal reasons. **Reading [S2] (Law Art. 6).**
"To fulfil a legal obligation" is a lawful ground for processing. **Reading [S1] (Regulation Art. 4).** A
processor stores personal data "in an unreadable format". We found **no text** saying that tax records are
exempt from erasure, and no text on backups.

**Reading [S5], [S10], [S3] (tax law, Arabic official copies).** Unified Tax Procedures Law 206/2020: the
taxpayer keeps books, records and copies of invoices for **five years following the tax period**. The
taxpayer also keeps the original and all copies of a **cancelled** invoice or receipt. Law 150/2026
replaced only the first paragraph of Art. 38 and did not touch the retention paragraph. **Reading [S4].**
Law 6/2025 exempts businesses with turnover up to EGP 20 million that opt in from Law 206 bookkeeping. They
follow simplified rules set by a ministerial decision, which we have not read.

**Comparison only [S8], [S9].** UK regulator guidance accepts that backups keep erased data until
overwritten if it is put "beyond use". EU GDPR Art. 17(3) lets erasure yield to a legal obligation to keep.
NIST SP 800-88 Rev. 2 mentions cryptographic erase. We do not know whether any of these reflect Egyptian law
or the Centre's view.

**Questions.**

- **Q4.1** Is the venue's five-year tax duty a "legitimate reason" under Law Art. 4 to keep sales and audit records that name its staff? Or must the staff identity in those records be removed before five years, or when the employee leaves or asks for erasure?
- **Q4.2** If identity must be removed, what must stay identifiable for an ETA inspection? Examples: the cashier who issued a receipt, a buyer's national ID. What counts as "no longer identifiable" when the venue still holds its staff list?
- **Q4.3** When a venue closes its account, **may**, or **must**, Kodelix keep that venue's tax archive until the five years end? On whose instruction, and under what contract term? Or must Kodelix deliver it to the venue and delete its own copy (Law Art. 5)? Our current design keeps the archive on the hosted server only.
- **Q4.4** Does the erasure duty reach **backups**? Is letting backups expire on a rolling window of under 60 days, with deletions replayed after any restore, enough? Or must data be removed from backups at once?
- **Q4.5** Does **destroying an encryption key**, so that all copies (backups included) become unreadable, count as erasure under the Law and Regulation?
- **Q4.6** For a venue under the Law 6/2025 simplified regime, does the five-year period still apply?
- **Q4.7** The cashier PC is the venue's own machine and keeps about 60 days of data. When an account closes, the PC is not wiped automatically, so the venue keeps its own copy. Does Kodelix, as software provider, have any duty for the data left on that PC?

**Working assumption — superseded by the founder decision above (2026-10-17).** Delete personal data the tax duty does not need. Keep the tax archive apart, with
identities removed wherever the tax record does not need them. Let backups expire within the window and
replay deletions after a restore. Do not build key destruction unless your answer requires it.

### Q5. Labour Law 14/2025: retention of staff records

> **Answered by founder decision, not counsel (2026-10-17).** Staff records belong to the owner; Labour
> Law retention is the owner's duty. Kodelix gives the owner the export and then deletes. Source: founder
> statement, until counsel's written answer is added.

**Reading [S7] (an advisory firm's page; we have not read the Law's text).** Labour Law No. 14 of 2025
was published 3 May 2025 and took effect 1 September 2025. The page says employers keep employee files,
digital or physical, for **at least five years after employment ends**. It gives no article number and
does not mention attendance. A search summary we could not verify says attendance and leave registers are
included, and records are kept longer during a dispute.

**Questions.**

- **Q5.1** Does Law 14/2025 require the employer to keep staff records? Which article, for how long, and from what trigger?
- **Q5.2** Are attendance (clock-in/out) records and a till activity log naming the employee "employee records" in that sense?
- **Q5.3** If yes, is that the "legitimate reason" (Law 151 Art. 4) to keep them identifiable after the employee leaves or asks for erasure? For how long during a labour dispute?
- **Q5.4** The duty sits with the venue as employer. Is it met if the venue exports the records when it closes its Kodeebo account? Or must Kodelix keep them on its behalf?

**Working assumption.** Attendance retention is an open, per-venue setting. No period is fixed until you answer.

### Q6. Hosting location: cross-border licence or permit if the server is in Germany

> **Answered by founder decision, not counsel (2026-10-17).** Counsel cleared hosting outside Egypt, and
> counsel told the founder that no PDPL licence is needed now (Q2). No staff consent screen for storage abroad in the current
> release. Source: founder statement, until counsel's written answer is added.

**Facts.** Staff personal data is collected in Egypt on the venue's PC and stored on Kodelix's hosted
server. **The hosting location is not decided.** The current plan is a VPS in Germany; the alternative is
hosting in Egypt. We will decide in our hosting architecture decision record after you answer this question.
Under the current plan the provider would be a sub-processor; [FOUNDER TO FILL: provider name]. Backups:
[FOUNDER TO CONFIRM location]. Kodelix staff in Egypt would access the server remotely. The server is
not running yet.

**Reading [S2] (Law Art. 14).** Transferring, storing or sharing personal data **abroad** is prohibited
unless the destination gives at least the Law's level of protection **and** the Centre licenses or
authorises it. **Reading [S2] (Law Art. 15; located by us in the saved copy).** As an exception,
transfer to a country *without* adequate protection may be allowed with the data subject's explicit
consent, in listed cases. The list includes performing a contract "in favour of the data subject" and
where law requires it. **Reading [S2] (Law Art. 16).** Making data available to a controller or processor
located abroad needs a Centre licence and conditions. **Reading [S1] (Regulation Art. 16 First 1-2, Arts. 23-27; located by us in the saved
copy).** The controller or processor:

- obtains a cross-border licence or permit, based on the Centre's assessment of the destination country;
- **obtains the data subject's consent** for the transfer;
- transfers only to the countries named in the licence.

The Centre is to publish a list of countries with adequate protection. The application names the
destination, the repositories, the categories, volume and retention. The Centre decides within **90
business days** of a complete file, and **silence counts as rejection**.

**Questions.**

- **Q6.1** Would storing data on a VPS in Germany be a "transfer abroad" that needs a cross-border licence or permit? Does the answer change because it is Kodelix's own server, rented, rather than a third party receiving data?
- **Q6.2** Who applies: the venue as controller, Kodelix as processor, or both? Would the German VPS provider be a "processor located outside Egypt" under Law Art. 16?
- **Q6.2a** Can Law Art. 15 (explicit consent plus a listed case) be a route for staff data? Or does it apply only where the destination lacks adequate protection, which we cannot assess?
- **Q6.3** Has the Centre published its list of adequate countries, and does it include Germany or the EU?
- **Q6.4** Must each staff member **consent** to the transfer (Regulation Art. 16 First 2)? In what form? What if an employee refuses?
- **Q6.5** The Centre has up to 90 business days to decide. **May Kodelix host abroad while an application is pending?** If not, must the first release be hosted in Egypt until a licence is granted?
- **Q6.6** Do Egyptian tax rules require tax records to be kept **in Egypt**? We found no such rule (we searched Law 206/2020 Arts. 35, 37, 38, its executive regulation Arts. 43-47 and ETA's SDK).
- **Q6.7** Would hosting with a German provider bring any of this processing under the EU GDPR? This is a question only; we have no view.
- **Q6.8** What must the contract with the hosting provider contain, as a sub-processor, in Germany and in Egypt?
- **Q6.9** If the server is hosted **in Egypt**, does any cross-border rule still apply, for example to remote support from abroad or to an off-site backup copy? Which of the two locations do you advise, on the law alone?

**Working assumption — superseded by the founder decision above (2026-10-17).** No live staff data goes to a server outside Egypt until you answer Q6. Your answer
decides between the two options in our hosting decision record. Changing the plan costs us little now and
much more after launch.

## 5. Further points (lower priority; answer if time allows)

- **Lawful basis and consent for staff data.** Reading [S2] (Law Art. 2): explicit consent is needed "unless law authorises otherwise". Does the employment relationship, or the employer's legal duties, make staff consent unnecessary for attendance and the till activity log? Or must each venue collect consent, and in what form?
- **Staff under 18.** Reading [S1] (Regulation Art. 15): children's data needs a guardian's consent; ages 15 to 18 have their own rule. Lounges and cafés may employ 15- to 17-year-olds. Does the venue need guardian consent for their attendance and passcode? Our later customer-records feature will also meet minors among lounge customers.
- **Fees for data-subject requests.** Reading [S2] (Law Art. 2): the data subject pays, capped at EGP 20,000, except for breach notices. Does a processor charge, or only the controller?
- **Our sales message.** We plan to tell owners they can see "who was on shift" from anywhere. Does that claim, or remote monitoring of staff in general, need any notice to staff or limits?
- **Data-processing agreement.** Will you review, or draft, the data-processing agreement for our customer contract? We can supply a draft from our own template, marked for your approval.

## 6. Engineering decisions waiting on your answers

| Your answer to | Decides | Default until answered |
|---|---|---|
| Q1 — **answered by founder decision, not counsel (2026-10-17)**; Q2 — **answered by counsel (2026-10-17)** | Customer contract terms; incident runbook (72-hour clock) | Venue owner = controller, Kodelix = processor on the owner's written instruction; no PDPL licence needed now (counsel) |
| Q3 | What Kodelix must have done by 2026-11-01 | Open for counsel |
| Q4, Q5 — **answered by founder decision, not counsel (2026-10-17)** | Retention and deletion design; backup policy; key destruction | Staged deletion; backups expire under 60 days; key destruction counts as erasure (escalation, not built); staff records exported to the owner, then deleted. Open: which archive fields stay identifiable |
| Q6 — **answered by founder decision, not counsel (2026-10-17)** | Hosting location in our hosting decision record | Hosting outside Egypt cleared; Germany (current plan) or Egypt decided in the hosting ADR |
| § 5 | Consent screens, staff notices, contract text | No staff consent screen for storage abroad in the current release (founder decision, 2026-10-17); others none built |

## 7. Documents to attach

**Sources we read** (attach the PDF, or send the link):

| Ref | Document | Where | Note |
|---|---|---|---|
| S1 | Executive Regulation of Law 151/2020 (Decree 816/2025), English copy | [Sedona Conference PDF](https://www.thesedonaconference.org/sites/default/files/meeting_paper/7.4%20Egypt%20Personal%20Data%20Protection%20Law%20-%20Executive%20Regulations.pdf); our text copy: [`exec-reg-sedona.txt`](../../research/evidence/tenant-isolation/part-5/sources/exec-reg-sedona.txt) | Unofficial translation on a third-party site |
| S2 | Law 151/2020, English copy | [Andersen PDF](https://eg.andersen.com/wp-content/uploads/2025/06/Law-No.-151-OF-2020.pdf); our text copy: [`law151-andersen.txt`](../../research/evidence/tenant-isolation/part-5/sources/law151-andersen.txt) | Unofficial translation; no Gazette reference printed |
| S3 | Law 150/2026 amending Law 206/2020 (Gazette 30 bis (a), 28 July 2026) | [ETA PDF](https://eta.gov.eg/sites/default/files/2026-08/law.no_.150.of_.2026.pdf); saved [`law.no_.150.of_.2026.pdf`](../../research/evidence/eta-e-receipt-e-invoice/dl-laws/law.no_.150.of_.2026.pdf) | Arabic Gazette text |
| S4 | Law 6/2025 (small-business incentives; Gazette 6 bis (f), 12 Feb 2025) | [ETA PDF](https://www.eta.gov.eg/sites/default/files/2025-02/law_no.6.of_.2025.pdf); saved [`law_no.6.of_.2025.pdf`](../../research/evidence/eta-e-receipt-e-invoice/dl-laws/law_no.6.of_.2025.pdf) | Arabic Gazette text |
| S5 | ETA guide comparing the VAT Law and Law 206/2020 (five-year retention paragraph) | [ETA PDF](https://eta.gov.eg/sites/default/files/2021-04/%D8%AF%D9%84%D9%8A%D9%84%20%D9%82%D8%A7%D9%86%D9%88%D9%86%20%D8%A7%D9%84%D8%B6%D8%B1%D9%8A%D8%A8%D8%A9%D8%B9%D9%84%D9%89%20%D8%A7%D9%84%D9%82%D9%8A%D9%85%D8%A9%20%D8%A7%D9%84%D9%85%D8%B6%D8%A7%D9%81%D8%A9%20%D9%88%D8%A7%D9%84%D9%86%D8%B5%20%D8%A7%D9%84%D9%85%D9%82%D8%A7%D8%A8%D9%84%20%D8%A3%D9%88%D8%A7%D9%84%D9%85%D9%83%D9%85%D9%84%20%D9%85%D9%86%20%D9%82%D8%A7%D9%86%D9%88%D9%86%20%D8%A7%D9%84%D8%A5%D8%AC%D8%B1%D8%A7%D8%A1%D8%A7%D8%AA%20%D8%A7%D9%84%D8%B6%D8%B1%D9%8A%D8%A8%D9%8A%D8%A9%20%D8%A7%D9%84%D9%85%D9%88%D8%AD%D8%AF.pdf) (Arabic, 2021) | ETA-hosted; not the Gazette; predates later amendments |
| S6 | ETA news, 21 May 2024: required content of consumer receipts, buyer ID above EGP 150,000 | [ETA page (Arabic)](https://eta.gov.eg/ar/news/alaltzam-balbyanat-almnsws-lyha-qanwna-baysalat-alby-llmsthlk-alnhayy-fatwrt-alby-llmsthlk) | ETA paraphrase, not the decree |
| S7 | Deloitte Middle East: Egypt's new Labour Law entering into effect | [Deloitte page](https://www.deloitte.com/middle-east/en/services/tax/perspectives/egypt-new-labor-law-entering-into-effect.html) | Advisory page only; Law 14/2025 text not read |
| S8 | UK ICO, right to erasure (backups "beyond use") | [ICO page](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/individual-rights/individual-rights/right-to-erasure/) | Comparison only, foreign; page says it is under review |
| S9 | NIST SP 800-88 Rev. 2, Guidelines for Media Sanitization (Sept 2025) | [NIST page](https://csrc.nist.gov/pubs/sp/800/88/r2/final) | Comparison only; definition not read |
| S10 | Law 206/2020 Art. 37, private law-site copy (cancelled originals kept) | [ragylaw.com PDF](https://ragylaw.com/wp-content/uploads/2024/11/L036.pdf) | Private copy; matches the ETA guide S5 |

**Founder to supply:**

- Kodelix's commercial register extract (legal form and activities).
- For the hosting provider under the current plan (Germany): its contract, data-processing terms and data-centre location, plus the backup location.
- Any notice or form the venues use today to tell staff about attendance tracking.

**Counsel to obtain** (we could not): the **Arabic Gazette text** of Decree 816/2025 (Issue 244, Supplement A) and of Law 151/2020; the text of Labour Law 14/2025; the Centre's published forms, fees and list of adequate countries, if any.

**Not to attach.** Our internal research notes (`docs/research/tenant-isolation.md`,
`docs/research/eta-e-receipt-e-invoice.md`) and the product brief. They contain confidential business and
security design detail, and this brief already carries what you need from them. We can send extracts if you ask.

## 8. Not assessed / not verified

- **No Arabic text** of Law 151/2020 or Decree 816/2025 was read. All readings rest on unofficial English copies.
- **Not read:** Labour Law 14/2025 itself; the Law 206/2020 Gazette text (Arts. 7, 35, 37, 38); the ministerial decision on simplified records under Law 6/2025; any Centre forms, fees or adequacy list.
- **Law Arts. 15-16 and Regulation Arts. 7, 8, 14, 15, 16, 23-27 and 36.** This brief found these articles in the saved English copies to frame Q2, Q6 and § 5. The research note behind the brief does not cover them.
- **Not checked:** the planned German provider's terms, backup location and sub-processors; any Egyptian hosting option.
- **Not decided:** the backup window length (only "under 60 days"), the cooling-off and export window lengths, the attendance retention period.
- **Nothing built:** no production code exists. Every "Design" line is intent, and no control in it has been tested.
- **No commands or tests** were run for this brief. It was written from the research notes and the saved source texts.

---

### Appendix (internal; delete before sending if preferred): traceability

| Brief section | Internal research references |
|---|---|
| § 2.1, § 2.2 | `design/product-brief.md` Tier 1 items 5, 7, Compliance/data; `docs/research/tenant-isolation.md` § 5 decision (DEL-2 + EXP-2), part-5 decision A.1-A.6, F521, F525; `docs/research/eta-e-receipt-e-invoice.md` D5, F404, F405, F415; sync-note OQ29 |
| Q1 | tenant-isolation F504, F506, F508, F509, part-5 decision A.3, A.5; § 9.1 item 1 |
| Q2 | F510; § 9.1 item 1; Regulation Arts. 7, 8, 14, 36 (saved copy) |
| Q3 | F501, F502, F503, F512; § 9.1 item 1 |
| Q4 | F507, F508, F513, F521, F522, F523, F536, DEL-2/DEL-3/DEL-4; eta-note F405, F406, F408, F413, F415, D5; § 9.1 item 2; part-4 Q-OQ9 |
| Q5 | F535; § 9.1 item 2 |
| Q6 | F511; eta-note F424; § 9.1 item 4; Law Arts. 14-16 and Regulation Arts. 16, 23-27 (saved copies); founder 2026-10-17: Germany is the current plan, not decided; Egypt the alternative; decided in the hosting ADR after Q6 |
| § 5 | F505; Regulation Art. 15 (saved copy); product brief line 41 ("who was on shift" PDPL check) |
