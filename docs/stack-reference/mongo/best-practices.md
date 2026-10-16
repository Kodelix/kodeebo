# MongoDB — Best Practices (verified 2026-10-11)

Facts cite a fetched page. Lines marked **(analysis)** are our recommendations, not sourced. Target: MongoDB 9.0.2 (Docker `mongo:9.0.2`).

## 1. Schema validation ($jsonSchema)

- Set with `validator` on `createCollection` or `collMod`. Minimal form (verbatim pattern from the docs page):
  ```javascript
  db.createCollection("students", {
     validator: { $jsonSchema: {
        bsonType: "object",
        required: [ "address", "major", "name", "year" ],
        properties: { name: { bsonType: "string", description: "'name' must be a string and is required" } }
     } }
  })
  ```
  Source: [specify-json-schema](https://www.mongodb.com/docs/manual/core/schema-validation/specify-json-schema/).
- Dialect: draft 4 of JSON Schema with MongoDB differences. Keywords the page names: `bsonType`, `required`, `properties`, `minimum`, `maximum`, `title`, `description`. `enum`, `pattern`, `uniqueItems` NOT CONFIRMED on the page — check the `$jsonSchema` reference before using them.
- Not allowed on `admin`, `local`, `config` databases or system collections.
- **validationLevel** (per [specify-validation-level](https://www.mongodb.com/docs/manual/core/schema-validation/specify-validation-level/)):
  - `strict` (default): all inserts and updates; existing documents not retro-checked, but updates to invalid documents fail.
  - `moderate`: inserts, and updates to documents that already match.
  - `constraint` (new in 9.0): all inserts and updates, and every existing document must satisfy the rules. Requires `validationAction` of `error` or `errorAndLog`. The validator cannot change while `constraint` is set: downgrade to `strict`, edit, upgrade again.
- **validationAction** (per [handle-invalid-documents](https://www.mongodb.com/docs/manual/core/schema-validation/handle-invalid-documents/)):
  - `error` (default): reject the write.
  - `warn`: allow, record in the mongod log.
  - `errorAndLog` (since 8.1): reject and log. Blocks downgrade until the collection is dropped or the action is changed.
- **(analysis)** Use `error` + `strict` for application collections; use `constraint` only after a full-collection audit for data that must always be valid.

## 2. Indexing — ESR rule

Per [ESR guideline](https://www.mongodb.com/docs/manual/tutorial/equality-sort-range-guideline/):
- Compound index order: **Equality** fields first, then **Sort** fields, then **Range** fields.
- Equality fields can be in any order relative to each other; all must precede sort and range fields.
- Sort before range avoids in-memory sorts. A very selective range can go before sort (ERS) when that is cheaper.
- `$ne` and `$nin` are range operators. `$in` is equality alone, but with `.sort()` and fewer than 201 elements it behaves like equality; with 201 or more it is treated as a range. The threshold may change between versions.
- Example from the page: query `{ directors: "David Lynch", runtime: { $lt: 130 } }` sorted by `year` → index `{ directors: 1, year: 1, runtime: 1 }`.

## 3. TTL indexes

Per [TTL indexes](https://www.mongodb.com/docs/manual/core/index-ttl/):
- Single-field index on a date field (or array of dates) with `expireAfterSeconds` (0 to 2147483647). Compound indexes do not support TTL and ignore `expireAfterSeconds`. `_id` cannot have a TTL index.
- Change `expireAfterSeconds` with `collMod`, not `createIndex`. Converting an existing non-TTL single-field index needs `collMod` (5.1+).
- Background thread runs about every 60 seconds; only the primary deletes; deletion is **not immediate** (docs' words: "does not guarantee that expired data is deleted immediately").
- Documents where the field is missing or non-date never expire.

## 4. Operator (NoSQL) injection

Per [MongoDB FAQ — injection](https://www.mongodb.com/docs/manual/faq/fundamentals/):
- Client drivers build queries as BSON objects, not strings, so classic string SQL injection does not apply. Special characters in input simply fail to match.
- Real server-side risk: `$where`, `mapReduce`, `$accumulator`, `$function` run JavaScript. Mitigate with `security.javascriptEnabled: false` in config or `--noscripting`. Most operations do not need JavaScript.
- The MongoDB page does not cover **operator injection** (user-supplied objects such as `{"$ne": null}` injected into a filter). Mitigations below are **(analysis)**:
  - Validate input types at the API boundary (strings stay strings; reject objects where a scalar is expected).
  - Build filters from explicit, known fields; never merge a raw request body into a query.
  - Wrap user values in `$eq` when constructing filters.
  - Never let users supply `$where`, `$expr` text, or logical operators such as `$or`.
  - Third-party npm `mongo-sanitize` strips `$`-keys; it is not part of MongoDB, and it is for Node only.

## 5. Write concern

Per [write concern defaults](https://www.mongodb.com/docs/manual/reference/mongodb-defaults/) and [write concern](https://www.mongodb.com/docs/manual/reference/write-concern/):
- Implicit default: `w: "majority"`. Arbiter exception yields `{ w: 1 }`.
- `w: majority` waits for on-disk journaling by default (`writeConcernMajorityJournalDefault`).
- If `wtimeout` is omitted and the write concern cannot be met, the write **blocks indefinitely**. Set `wtimeout` or a driver timeout on critical paths **(analysis)**.
- Read concern default: `"local"`. Use `"majority"` where rollback-safe reads matter **(analysis)**.
- Default changed to majority in 5.0 per secondary sources only (see breaking-changes.md).

## 6. Transactions

Per [production considerations](https://www.mongodb.com/docs/manual/core/transactions-production-consideration/) and [9.0 release notes](https://www.mongodb.com/docs/manual/release-notes/9.0/):
- Default runtime: less than one minute ("By default, a transaction must have a runtime of less than one minute."). Numeric default of `transactionLifetimeLimitSeconds`: not stated.
- Oplog splits large transactions; each entry must fit 16 MB BSON. A transaction too large for WiredTiger cache aborts with `TransactionTooLargeForCache`.
- Default lock wait: 5 ms (`maxTransactionLockRequestTimeoutMillis`).
- 9.0: `maxConcurrentMultiDocumentTransactions` default 10000; excess returns `TooManyOpenTransactions`.
- 9.0: per-operation memory limit 1 GB or 20% of server memory, whichever is greater.
- "1000 write operations per transaction": NOT SOURCEABLE.
- **(analysis)** Keep transactions short (seconds, not minutes). Do not do network calls inside a transaction.

## 7. Docker image

- Pin the exact patch (e.g. `mongo:9.0.2` or `mongo:9.0.2-noble`). `latest` tracks the newest major.
- Tags and variants per [docker-library README](https://github.com/docker-library/docs/blob/master/mongo/README.md): see VERSION.md. No `-rc` or `-ubi` in that README.
- No mongo image is present on the local host; pull the pinned tag before testing.

## 8. Licensing: shipping MongoDB in a self-hosted bundle

- MongoDB Server is licensed under the **Server Side Public License (SSPL)**, per the license page and FAQ.
- SSPL section 13 — titled "Offering the Program as a Service" — applies when you offer MongoDB to third parties as a service. The license text says you "must make the Service Source Code available via network download" to everyone at no charge. Section 13 covers hosting-style offerings whose value comes entirely or primarily from the Program.
- Section 2 (verified in summary): running the unmodified Program is not restricted, subject to section 13.
- Distributing copies to customers falls under sections 4–6 (conveying copies; the fetched summary says these include providing Corresponding Source with object code). The FAQ does not address a self-hosted on-premise bundle. MongoDB states that customers and OEM partners on a commercial license are not affected, but does not define what that license covers.
- The FAQ says internal-only use, including by subsidiaries, is not treated as offering the software to a third party, and Atlas users are not licensees.
- **Implication (analysis, requires legal review):** a self-hosted bundle that includes MongoDB binaries and is given to customers is outside the section 13 "as a service" case on the FAQ's reading, but it is a conveyance under sections 4–6, and the FAQ does not settle it. Options: ship a compose file that pulls the official image from the customer's own Docker host (no binaries in your bundle), or buy an OEM/commercial license from MongoDB. Get legal sign-off either way.
- Do not call MongoDB "open source" in customer-facing docs until legal confirms the wording. OSI status of SSPL: NOT SOURCEABLE — not stated on any fetched page.

## 9. Checklist

1. Pin `mongo:9.0.2` (or the chosen 8.x patch for the shipped bundle).
2. Add `$jsonSchema` validators with `strict` + `error` on every collection.
3. Index by ESR; add a TTL index for any expiring data.
4. Build filters from explicit fields; set `javascriptEnabled: false`.
5. Set `wtimeout` on critical writes; keep transactions short.
6. Resolve the SSPL bundle question with legal before shipping binaries.
