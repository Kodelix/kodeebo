# Competitor file — `business/competitors/<slug>.md`

Fields are the protocol's (`business-research-protocol.md` → "Competitor
analysis"). One file per **company** (never a named individual). Read in
Phase 3 and give it to every `market-researcher` you spawn.

## Marks (every field carries exactly one)

| Mark | Meaning | Allowed when |
|---|---|---|
| `VERIFIED-ON-SITE` | read on the vendor's own domain in this run | the page was fetched now; record URL, date, and what the page showed |
| `THIRD-PARTY` | from a source other than the vendor's own page | record the source link, its tier (1–5) and its date; tier 4–5 is a lead only |
| `NOT CAPTURED` | the vendor page exists but could not be read | login wall, script-rendered content, geo-gated, blocked, timed out — say which |
| `NOT SOURCEABLE` | searched and nothing public found | list what was searched |

A field never carries a value from memory, and a stale value from an older file
is not re-marked `VERIFIED-ON-SITE` — it is marked with its original capture
date (and `THIRD-PARTY`/`PRIOR CAPTURE`) until it is re-fetched.

## Capture rules for prices

- Record **as published**: currency, period (month/year/one-time), per what (user, seat, location, instance), tax status shown on the page (`incl. VAT`, `excl. VAT`, `not stated`), plan name exactly as written, and the plan limits beside it.
- A price shown differently by country or currency is captured per country with the page's own selector state noted ("page showed EGP when opened from this session" is not the same as "EGP price list"). If the visible price depends on location and could not be varied, the other countries are `NOT CAPTURED`.
- "Contact sales" is a real capture: write it; do not estimate.
- Add the **archive link if one already exists** for the page (look it up; do not submit pages to an archive service on your own).
- Conversions: the published currency first; EGP/SAR/AED/USD equivalents only with the rate, its source (central-bank or authority page) and its date. Never convert and drop the original.
- Never bypass a login, paywall or bot check, and never use an account to see a price list. A price that sits behind a login is `NOT CAPTURED — login required`.

## Layout

```
# <Company> (<product name>)

URL: <vendor URL>   First captured: <date>   Last captured: <date>   Segment: <who they sell to>
Overall capture status: <n of m fields VERIFIED-ON-SITE>

## Plans and prices (dated capture)
Capture <YYYY-MM-DD> - URL <exact page> - archive: <link | none found>
| Plan (as written) | Price as published | Period | Per | Tax shown | Limits (as written) | Mark |
Equivalents: <EGP | SAR | AED | USD> at <rate> (<source>, <date>) - original shown first

## Billing options
Monthly / annual / one-time / usage; annual discount as published; trial and free tier terms | Mark

## Local payment methods
Cards, Fawry, InstaPay, mada, Apple Pay, wallets, bank transfer - as listed on their pages | Mark each

## Arabic / RTL support
Product UI, docs, support language, site language, currency/locale handling | Mark each

## Self-hosted / on-prem offer
Offered? how licensed, how priced (or "contact sales"), support terms | Mark

## Data-residency claims
Regions named, claims as written (quote at most one short line), certifications claimed | Mark;
a claim on a page is a CLAIM, not a verified fact

## Reviews
| Site | Rating | Number of reviews | Date | Corroborated by (second source) |
Tier 4 sources: sample size and date mandatory; one site alone is a lead.

## Customers
Logo wall / named customers = claims, unverified; never a customer count.

## Change log
| Capture date | Plan | Old price | New price | Note |
Older captures are kept; a refresh appends, it never overwrites.

## NOT SOURCEABLE / NOT CAPTURED
| Field | Why | Searched |

## Sources
| # | URL | Tier | Date fetched |
```

## Staleness

The user sets the horizon (ask; if the user has no view, propose 90 days and say
this is a studio convention, not a sourced figure). A capture older than the
horizon is flagged `STALE` in the file and in the matrix; EGP prices older than
the horizon are flagged even earlier if the rate has moved materially — say
whether the capture precedes or follows a major rate move.
