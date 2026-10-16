# Naming: criteria, tiers, screening, language review, trademark record — `/brand-architecture`

Read in Phase 2 for `naming`/`both`; give to every `market-researcher` spawned in
Phase 5. This is **screening**. It never concludes that a name is clear, available,
safe or registrable, and those words are not used about any name, domain, handle or
mark. Anything legal is `NEEDS COUNSEL`.

## Marks (every screening field carries exactly one)

| Mark | Meaning | Allowed when |
|---|---|---|
| `VERIFIED-ON-SITE` | read on the owner's, office's or registry's own page in this run | record URL, date, query, and what the page showed |
| `OBSERVED` | a tool observation made in this run (a `dig` answer, a fetched response) | record the exact command or URL, the date and the status shown |
| `THIRD-PARTY` | from a source other than the owner's own page (search result, directory, press, dictionary) | record source, tier (1-5) and date; tier 4-5 is a lead only |
| `USER-REPORTED` | the user or their counsel or reviewer reported it | record who in role terms (never a name), the date, and the exact words used |
| `PROPOSED` | a suggestion awaiting human review (an Arabic-script rendering, a class, a query variant) | always followed by who must review it |
| `HYPOTHESIS` | a possible concern the agent wants a native speaker or counsel to check | phrased as a question; never as a finding; never "no problem" either |
| `NOT SEARCHED` | the search was not run | the reason: login, CAPTCHA, script-only form, blocked, no public search page, timed out, not attempted |
| `NOT CAPTURED` | the page exists but could not be read, or the tool gave no usable answer | say which |
| `NOT SOURCEABLE` | searched and nothing public found for a fact | list what was searched |

A field never carries a value from memory. An old value from an earlier naming file
is shown with its original date and is not re-marked in this run.

## Name criteria (the user ranks the ones that matter)

1. **Distinct in the category and its neighbours** — no existing product, company or app with the same or a near name in the category or the neighbours the user listed. For a point-of-sale product the neighbours can include payments, accounting, HR and hardware; the user confirms the list.
2. **Says well in every language and dialect group the user named** — easy to say, hear once and spell; no unwanted sound-alike. Judged by native speakers, not by the skill.
3. **Reads and types in both scripts** — a Latin form and one or more Arabic-script renderings that people would actually type; works in mixed-direction text and as a lockup.
4. **Fits the architecture decision** — a master brand does not embed a vertical word it cannot outgrow; a descriptor follows the naming rule; works beside the endorser line.
5. **Short enough for the places it appears** — app name, store listing, receipt, voice and phone spelling, hardware label. Limits of each place are sourced at run time.
6. **Domain and handle pattern** — the user's extensions and platforms observed (observations only).
7. **Searchable** — what a plain web search for the name shows today (an observation: crowded with other meanings, or empty).
8. **Culturally and commercially appropriate for the markets** — checked by native speakers and the user's own market knowledge; the skill supplies questions.
9. **Protectable in principle** — whether a name is distinctive or merely descriptive, and whether it can be protected in each market, is `NEEDS COUNSEL`; the skill only avoids names that are plainly generic words for the product.

The skill records the user's ranking as given. It does not turn criteria into a
weighted score.

## Candidate record

Per candidate: name (Latin), `PROPOSED` Arabic-script renderings, the rationale in
one line, who proposed it (user / `marketing-lead`), the architecture role (master,
descriptor, endorser, mascot), tier, and the sections below. A candidate eliminated
in Tier 1 keeps its record (the conflict found, with source) so it is not proposed
again.

## Tiers (cost control)

- **Tier 1 — quick screen, every candidate:** R1 (category and neighbour search) and
  the domain/handle observations for the user's primary extension. Hit → `CONFLICT
  FOUND`. No hit → the candidate stays `NOT ASSESSED` (Tier 2 not run); it is never
  "passed" on Tier 1.
- **Tier 2 — full screen, the user-approved few:** R1-R5 below, the trademark
  screening record, and the language review requests.

## Required components (R1-R5)

| # | Component | Counts as run when |
|---|---|---|
| R1 | **Category and neighbour conflict search** | web search for the exact name and the spelling variants listed; app-store listings searched; public company registers searched where a public search page exists (a market with none is listed `NOT SEARCHED — no public search page found`, which does not block R1 but is shown) |
| R2 | **WIPO Global Brand Database search** | the database's own page was found and the queries were actually run and results read; coverage notes copied from the database's own page |
| R3 | **National/regional office search for each target market** | the office's own official search page was found, confirmed to be the office's own domain, the queries were run and results read — or the user/counsel reports the search (`USER-REPORTED`, with the queries used) |
| R4 | **Domain and handle observations** for the extensions and platforms the user named | each `dig` ran with a readable status, or is `NOT CAPTURED`; handle pages fetched or `NOT CAPTURED` (a `NOT CAPTURED` here makes the candidate `NOT ASSESSED` until resolved or the user drops that item) |
| R5 | **Language review recorded** for each dialect group the user named | `USER-REPORTED` reviewer role, dialect, date, count and responses to the request set; otherwise `NEEDS NATIVE REVIEW` |

Any of R1-R5 not run makes the candidate `NOT ASSESSED`, and the file names which
component and why. Several can apply at once: list them all.

## Verdict derivation (per candidate)

1. **`CONFLICT FOUND`** — any sourced hit in R1-R3 that is the same name, or a variant the screening queried, for a product/company in the category or a neighbour, or a mark listed in a class the screening proposed. The record states **what surfaced it** (query, office, listed owner company, listed status, listed class) and does not judge likelihood of confusion — that is `NEEDS COUNSEL`. If the user dismisses a flagged hit, the dismissal is recorded verbatim with date, reason and the tag `NEEDS COUNSEL`; the hit no longer sets the verdict but stays in the file.
2. **`NOT ASSESSED`** — no conflict flagged, but R1-R5 are not all run. Reasons named by component.
3. **`SCREEN PASSED — NEEDS COUNSEL`** — R1-R5 run, no flagged hit (or every flagged hit dismissed by the user), language review recorded with no concerns raised or concerns resolved by the user. The label means "nothing in what was searched stopped this name", **not** that the name is safe to use.

A hit found after the verdict was set re-opens it. An item listed under "searches not
run" always appears in the verdict line of a `NOT ASSESSED` candidate.

## Domain and handle observations

**Domains** (extensions the user named; the skill does not pick them from memory).
Per extension, run `dig <name>.<ext> NS` and record the status line shown:

| Observation | Word used |
|---|---|
| `status: NXDOMAIN` | `NO DNS RECORDS SEEN — not proof of availability` (`OBSERVED`) |
| `status: NOERROR` with answers | `RECORDS SEEN — in use or registered` (`OBSERVED`), then fetch the site once and note what it is |
| `NOERROR` with no answers, `SERVFAIL`, `REFUSED`, timeout, `dig` not found, network blocked | `NOT CAPTURED — <which>` |

A name can be registered with no DNS records, held, reserved by a registry, or
restricted to eligible registrants. Registration data and eligibility rules come from
the registry's or registrar's own lookup page, fetched in this run (`VERIFIED-ON-SITE`)
or `NOT CAPTURED`. Registrant personal data is never recorded: only "registered" /
"no registration record shown" and the date of the record if displayed. Nothing is
purchased, reserved or contacted.

**Handles** (platforms the user named). Fetch the public profile URL the platform's
pattern gives (found on the platform's own pages, not from memory). Record
`PROFILE EXISTS (VERIFIED-ON-SITE)`, `PAGE NOT FOUND — not proof of availability`, or
`NOT CAPTURED — <login wall / blocked / script-only>`. No sign-up flow is used to test a
handle, no account is created.

**App stores.** Search the stores' public web pages for the name and variants; record
listing name, publisher (company name), category, store page URL, date. Store naming
and uniqueness rules come from the store's own current developer page, fetched in the
run, or `NOT CAPTURED`.

## Language and pronunciation review

**What the agent prepares** (all `PROPOSED` / `HYPOTHESIS`, none asserted):
1. Renderings: the Latin name, and the Arabic-script renderings people might type or say.
2. A short question set per dialect group the user named: what does this word or sound
   suggest to you; does it sound like any word or name you would not want a business
   associated with; how would you spell it after hearing it once on the phone or a voice
   note; which of the renderings would you type; how is it said by someone who does not
   speak the language of the name; is there a religious, political, brand or family
   association for you.
3. `HYPOTHESIS — ask a native speaker` items the agent noticed, phrased as questions.
   The agent does not rank them or say how likely they are. A hypothesis list that is
   empty is reported as "none noticed — this is not a finding".
4. English and any other language the user named: dictionary lookups the agent fetched
   are `THIRD-PARTY` with source and tier; **absence from a dictionary is not evidence of
   no meaning** (slang, names, and sounds are not in dictionaries).
5. Mascot and symbol questions where relevant (what an animal or figure signals in the
   markets), as questions.

**What comes back** (through the user): reviewer role and dialect (never names), date,
number of reviewers per dialect group, and their answers. Status per candidate and
dialect group: `NEEDS NATIVE REVIEW` · `REVIEWED — CONCERNS RAISED` (list) ·
`REVIEWED — NO CONCERNS RAISED (USER-REPORTED, <date>, n=<count>)`. One reviewer is a
lead, not a consensus; the count is always shown.

The skill must not write phrases such as "no negative meaning", "means X in dialect Y"
or "pronounced easily" as findings.

## Trademark screening record (Tier 2, per candidate × office)

**Offices.** The WIPO Global Brand Database plus the national or regional office for
each target market the user named. Find each office's official search page by search at
run time; use it only when its domain is the office's own (government or international
organisation); record URL and date. Check on the official pages whether a regional or
international filing system exists that covers the user's markets and whether the
database covers the office's data — record what the page says, do not infer coverage.

**Queries.** Exact name; spelling and phonetic variants the agent lists (doubled or
dropped letters, vowel swaps, common misspellings, with/without a descriptor);
`PROPOSED` Arabic-script renderings (marked as awaiting native review); the mascot,
endorser and descriptor names the user put in scope. Text queries only: image/logo
similarity is for counsel.

**Classes.** Identify the current edition of the international classification of goods
and services from WIPO's own classification page and propose the classes that match the
product description in the brief, marked `PROPOSED — counsel confirms`. Search within
them and without a class restriction where the database allows. No class number appears
anywhere unless it came from that fetched page, with the URL.

**Per office, record:** office; URL; date; queries run; classes searched; filters used;
result word (below); hits table (mark text as shown, listed owner **company** — an
individual is written `individual` with no name — status as displayed, listed classes,
listed dates, which query surfaced it); the database's own stated limits (data lag,
coverage) copied from its page; the reason for any `NOT SEARCHED`.

**Result words (fixed):** `HITS LISTED` · `NO HITS LISTED FOR THE QUERIES RUN` ·
`NOT SEARCHED — <reason>`. The second is not a clearance and is printed with this
sentence beside it: *Unlisted pending applications, unregistered use, similar marks
the queries did not cover, and design marks are outside this search.*

If a search page needs a login, a CAPTCHA, a script-only form the fetch cannot drive,
or refuses automated reads, it is `NOT SEARCHED` with that reason. The file then adds a
**"Searches for you to run"** block for that office: the page URL, exactly what to type
for each query, the classes to select, and what to copy back (the fields above). The
user's returned results are recorded `USER-REPORTED` with the queries used.

## Brief for counsel (inside `naming-<date>.md`, self-contained)

Written so it can be handed over on its own. Contents:
1. **Who and what** — applicant entity (`USER TO FILL`), product family, goods and services in plain words from the brief, markets and planned launch dates (`USER TO FILL` if not given), name forms in play (word mark Latin, Arabic-script forms, logo, mascot, tagline), the architecture (master, endorser, descriptors).
2. **Candidates in the user's order of preference.**
3. **What was searched** — every office, date, query, class, result word; **what was not searched** and why.
4. **Hits listed** — the table above, with source URLs.
5. **Language review state** and the unreviewed items.
6. **Domain, handle and store observations**, with their limits.
7. **Use to date** — has the name been shown publicly, where and since when (`USER TO FILL`; the skill does not guess).
8. **Questions, all tagged `NEEDS COUNSEL`:** clearance opinion per market for each form; classes and scope; filing route and order across the markets; whether each name is distinctive in Arabic and in English or too descriptive; whether any word needs authorisation or is restricted in a market or in a company/trade name; how to treat each flagged hit (coexistence, consent, avoid); which entity should own the marks and how a company-to-family licence is arranged; the mascot's artwork ownership and any designer assignment; use of the endorsement line; domain-dispute exposure; what to avoid doing publicly before filing; counsel's estimate of cost and time (the skill states none).
9. **Attachments** — the screening record sections and the sources table.

## Words and claims the skill never writes

"clear", "cleared", "available", "safe to use", "registrable", "no conflicts", "no
risk", "means X in dialect Y", "has no bad meaning", "easy to pronounce"; any filing
fee, timeline, class number, office procedure or legal test not fetched from an
official page in this run. A negation ("not proof of availability") is allowed.
