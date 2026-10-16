# Proposal template — `business/sales/<product>-proposal-template.md`

A fill-in template. It contains **no real customer, price or promise**: every
`{slot}` is filled per deal by the user. Any example shown is marked
`ILLUSTRATIVE`. Prices come from the pricing file; terms come from the
enterprise-terms table (only rows with status `OFFERED`).

```
# Proposal - {Customer organisation}            Validity: until {date}   Version: {n}
Prepared for: {role titles}   Prepared by: {role}   Date: {date}
Language: {Arabic | English | both}   Edition: {hosted | self-hosted}

## 1. The customer's stated problem
As recorded in the discovery notes of {date(s)} - {the customer's own words from the notes,
paraphrased; attribute by role, not name}. If no discovery notes exist: "not recorded" and the
proposal is not sent.

## 2. What we propose
Scope, edition, plan, quantities (users / instances / locations), what is NOT included.

## 3. Price
| Item | Quantity | Unit price (currency, period) | Line total | VAT line |
Currency first, USD equivalent only with rate, source, date. VAT presentation per {authority rule}
(confirm with a qualified advisor). Payment terms: {from the playbook row}. Quote expiry: {date}.
Discount: {depth and reason} - within the authority table / approved by {role}.

## 4. Term and renewal
Subscription term / licence term; renewal price rule; cancellation; for one-time licence: update window,
maintenance %, behaviour after expiry. For self-hosted: instance/user bounds, offline grace, update window.

## 5. Service levels and support
SLA % and response times by severity - only terms with status OFFERED, each with its source in the playbook.
Support hours and channels (Egypt / Gulf time zones). Anything else: "not offered" or "subject to
written engineering confirmation" - never implied.

## 6. Data, security and residency
Hosting region(s) actually supported, subprocessors list, data-export and exit rights, security-review
support. Claims limited to what the questionnaire library can evidence.

## 7. Implementation plan
Milestones with dates, customer responsibilities, success criteria the customer stated.

## 8. Assumptions
Every assumption the price or timeline depends on.

## 9. Acceptance
Steps to accept, who signs, how the licence or tenant is provisioned. (Signing and sending are the
user's actions.)
```

Rules for the template:
- No capability is promised that is not shipped or on a dated, **approved** roadmap.
- No customer reference, logo, quote or case study unless the customer has agreed in writing (the user confirms).
- No legal wording drafted as binding: contract terms are for the user's legal advisor.
