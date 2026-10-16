# Price-test design — `/pricing-strategy`

A price test is **designed** here and **run by the user** (publishing a price is
the user's action). It is a proposal until the user decides.

## The fields every test states

| Field | Content |
|---|---|
| Hypothesis | "At EGP X the annual-plan conversion is not lower than at EGP Y by more than D points" — one primary claim |
| Arms | control price, one or two variants; same plan, same currency, same period, same VAT display |
| Unit of randomisation | visitor/session on a public page, or a **lead cohort** — never two prices to the same account, and never shown different prices to members of one organisation |
| Primary metric | for example visitor → paid, or lead → paid for assisted sales; revenue per visitor as the secondary |
| Guard metrics | refund rate, support contacts, trial-to-paid, 30-day churn, downgrade rate |
| Baseline rate | measured, or `ASSUMPTION` (labelled) if no measurement exists |
| Minimum detectable effect | the smallest difference that would change the decision (user's choice) |
| Significance and power | chosen by the user (state them; the common 5 % / 80 % are conventions, not facts about the market) |
| Sample size per arm | **computed**, see below, never guessed |
| Duration | time to reach the sample at the traffic *measured or assumed*, rounded up to whole weeks so every weekday is covered; includes one full billing cycle if the metric is renewal |
| Stop rule | fixed sample size or fixed date, decided in advance; no stopping on a good-looking day |
| Decision rule | written before launch: which result leads to which price; who decides |
| Existing customers | unaffected unless the migration rule says otherwise |
| Not covered | what the test cannot tell you (long-run churn, enterprise deals) |

A test with too little traffic to reach the sample is reported as **not
feasible**, with the alternatives (a longer run, one fewer arm, a larger minimum
effect, a sequential cohort of N sales conversations) — it is not shrunk to fit.
For enterprise/self-hosted prices there is no A/B: use structured price
conversations with a stated count and a pre-written question script.

## Sample size per arm (two proportions)

Run `calc.py` (arithmetic only; no inline script is run) and paste the output into the file:

```text
python3 -I .claude/skills/business-case/references/calc.py "sample_size(0.04, 0.05)"
python3 -I .claude/skills/business-case/references/calc.py "sample_size(0.04, 0.05, 0.05, 0.80)"
```

`sample_size(p1, p2, alpha=0.05, power=0.80)` is the two-proportion, two-sided
formula, rounded up, per arm. `p1` is the baseline conversion and `p2` the
conversion under the variant you want to detect. The baseline `p1` and the effect are *inputs the user owns*;
if `p1` is an assumption the sample size inherits that label.

## Two honest limits

- Stated price elasticity from a test on one landing page is evidence about *that page and that traffic source*. It does not carry to another country or channel.
- Do not let the variant arm carry a different offer, trial length or design: a test that changes two things measures neither.
