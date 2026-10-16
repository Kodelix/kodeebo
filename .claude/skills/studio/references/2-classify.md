# /studio — Phase 2: Classify the Goal

> Part of `/studio`.

Restate the goal in one sentence in the user's language, then pick exactly one
flow. If two fit equally, ask with `AskUserQuestion` (options = the two flows,
each with what it will do first).

| Flow | Signals (Arabic or English) | First step |
|---|---|---|
| **new-product** | no `design/product-brief.md`; "I want to build / عايز أعمل منتج" | `/start` |
| **feature** | "add / build / support X", "ضيف / اعمل ميزة" | `/research` |
| **bug** | "broken / error / crash / wrong", "مش شغال / بيضرب" | `/bug-report` |
| **performance** | "slow / timeout / memory / cost", "بطيء" | `/perf-profile` |
| **security** | vulnerability, CVE, audit, pentest finding, "ثغرة" | `/security-audit` or `/threat-model` |
| **integration** | a named provider (payments, SMS/OTP, email, storage, push, OAuth) | `/integration` |
| **data-change** | schema, migration, new store, retention | `/db-migration` |
| **api-change** | endpoint/contract change | `/api-contract` |
| **ui** | screen, flow, design, "شكل / شاشة / تصميم" | `/team-ui` |
| **test** | "test / QA / UAT / pentest / اختبار" | `/test`, `/manual-test`, `/uat`, `/pentest` by intent |
| **release** | "ship / release / publish / submit / انشر" | `/release-checklist` |
| **incident** | production down/degraded, "السيستم واقع" | `/incident` (act first, document after) |
| **core** | capability that belongs in `saas-core-<track>` | `/core-use` or `/core-extract` |
| **business** | market, pricing, competitors, offers, marketing, sales, "أسعار / سوق / تسويق / بيع" | `/business` |
| **question** | "how / why / should we / إزاي / ليه" | answer from artifacts; propose a flow only if action is needed |

**Incident overrides everything:** if the goal describes a live outage, pick
`incident` immediately and say so — no clarifying round first.

**Ambiguity check before committing:** name the product area (bounded context
from `design/specs/domain-map.md` if present) and the layers touched (from the
stack line). If either is unknown and matters for routing, ask one question.
