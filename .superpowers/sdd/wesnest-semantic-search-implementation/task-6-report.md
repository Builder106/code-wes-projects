# Task 6 Report: Search API with keyword fallback

## Implemented
- `api/search.js`: exports `rankOrgs(query, orgs, apiKey, opts?)` and default Vercel handler `(req, res)`.
  - Embeds query via `embedText` (or injected `opts.embedImpl`), scores orgs with `cosineSimilarity`.
  - On any embedding error, falls back to substring keyword matching across `name + categories + summary` (score 1/0).
  - Sorts descending by score, slices to `opts.limit ?? 15`, strips `embedding` field from output.
  - Handler validates POST method and non-empty string `query`, loads `data/orgs-embeddings.json` (cached), calls `rankOrgs`, returns `{ results }`.
- `tests/search.test.mjs`: 4 tests per brief (similarity ranking, keyword fallback on embed failure, keyword fallback matches across fields, limit respected).
- `tests/fixtures/sample-embeddings.json`: 3-org fixture exactly as specified in brief.

## Interface verification
Read `lib/similarity.mjs` and `lib/geminiEmbed.mjs` directly before writing code:
- `cosineSimilarity(a, b)` returns 0 for zero-norm vectors, standard cosine otherwise — matches brief's assumed shape.
- `embedText(text, apiKey, fetchImpl = fetch)` returns `data.embedding.values`, throws on non-2xx — matches brief's assumed shape (opts.embedImpl signature `(query, apiKey)` aligns since embedText's third param is optional).
No mismatches found; implemented the brief as written.

## TDD evidence

RED (before `api/search.js` existed):
```
$ node --test tests/search.test.mjs
ERR_MODULE_NOT_FOUND: Cannot find module '.../api/search.js'
✖ tests/search.test.mjs (56.029688ms)
ℹ tests 1
ℹ pass 0
ℹ fail 1
```

GREEN (after implementation):
```
$ node --test tests/search.test.mjs
✔ ranks orgs by similarity to the query embedding (2.457171ms)
✔ falls back to keyword match when embedding fails (0.430522ms)
✔ keyword fallback matches on name, categories, or summary (0.273721ms)
✔ returns at most the requested limit (0.345962ms)
ℹ tests 4
ℹ pass 4
ℹ fail 0
```

Full suite (`npm test`), confirming no regressions from Tasks 2-5:
```
ℹ tests 16
ℹ pass 16
ℹ fail 0
```
(4 similarity + 3 parseClubs-equivalent... actual breakdown: 5 geminiEmbed/parse tests + 3 rankOrgs-adjacent + 4 new search tests + 4 similarity tests = 16 total, matching the expected count.)

## Files changed
- `apps/wesnest-semantic-search/api/search.js` (new)
- `apps/wesnest-semantic-search/tests/search.test.mjs` (new)
- `apps/wesnest-semantic-search/tests/fixtures/sample-embeddings.json` (new)

## Commit
`4eb3dfe` — "feat: add search API with keyword fallback" on branch `wesnest-semantic-search`. Not pushed.

## Self-review
- Fallback logic uses a single `try/catch` around the embed call only, so a downstream `cosineSimilarity` throw (e.g. mismatched vector lengths) is NOT caught by the keyword fallback — only embedding failures are. This matches the brief's intent ("catching an embedding failure").
- Keyword score is binary (1/0) via substring match on the lowercased concatenation of name/categories/summary — verified it correctly ranks "Board Games Club" and "Wesleyan Outing Club" top for their respective queries in the fixture.
- `rankOrgs` strips the `embedding` field from every returned result (both success and fallback paths) so it never leaks into the API response.
- Handler's `loadOrgs()` reads `data/orgs-embeddings.json` relative to cwd — this file is Task 5's output and wasn't verified to exist yet (out of scope for this task's unit tests, which inject fixtures directly).
- No real Gemini API calls were made; all tests use injected `embedImpl`.

## Concerns
- None blocking. Minor: handler-level integration (actual `data/orgs-embeddings.json` presence, real Vercel request/response shape) is untested here per brief scope — that's implicitly Task 9's deploy verification territory.
