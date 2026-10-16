# Run and Observe

**A compile is not a run.** Every story that changes something a user can see
or call is exercised against a running stack before it closes, and the
observation is retained in `production/qa/evidence/<story-id>/`. Not waived at
`qa.level: minimal` — tests are, the look is not.

## 1. Bring the stack up

```bash
docker compose -f deploy/compose.dev.yaml up -d --wait
```
`--wait` blocks until every service's healthcheck passes. If a service never
becomes healthy, that is the finding — capture `docker compose logs <svc>`.

Migrations run as a one-shot service (or `make migrate`) before the API starts.
Seed data comes from `tools/seed/` with a dedicated test tenant — never from a
copy of production data.

## 2. Observe per layer

| Layer | How to observe | Evidence to retain |
|---|---|---|
| **API** | Call the endpoint with `curl`/`httpie` (or the generated client) as each relevant role: owner, member, other tenant, anonymous | request + response (status, headers, body with secrets redacted) → `api-<endpoint>.md` |
| **Web** (`web/`) | `pnpm dev` or the built static bundle behind the dev proxy; Playwright script drives the journey | full-page screenshots, desktop (1440 px) and mobile (390 px), light and dark if supported, **Arabic (RTL) and English** |
| **Marketing site** (`site/`) | `pnpm build && pnpm preview` | screenshots of changed pages + Lighthouse report |
| **Android** | emulator or device; `adb exec-out screencap -p > shot.png` | screenshots of each touched screen, plus RTL |
| **iOS** | simulator; `xcrun simctl io booted screenshot shot.png` | screenshots of each touched screen, plus RTL and Dynamic Type large |
| **Background job / webhook** | trigger it (CLI, test event from provider sandbox) and follow the trace | trace screenshot or exported span list + resulting DB/cache state |
| **Telemetry** | open the trace for the request in the local collector UI | one trace screenshot showing spans for handler → use case → DB/cache |

## 3. UI stories also run impeccable

For any web screen touched: `/impeccable audit <target>` and fix findings, then
`/impeccable polish <target>`. Attach the audit summary to the evidence folder.
Native screens use impeccable's native audit references where applicable.

## 4. What counts as observed

- The feature was exercised end-to-end on the running stack, not just in tests.
- The negative path was exercised too (wrong role / other tenant / invalid input).
- The evidence files are on disk when the story is closed — captured-and-discarded is an assertion, not evidence.

## 5. Tear down safely

```bash
docker compose -f deploy/compose.dev.yaml down
```
Never `down -v` (deletes volumes — blocked by settings) unless the user asks
for a clean slate.
