# Task 5 Report: Build-embeddings script

## Implemented
- `scripts/build-embeddings.mjs`: exports `buildEmbeddings(markdown, apiKey, embedImpl = embedText)`, plus a `main()` CLI entry point (reads `data/wesleyan_clubs.md`, writes `data/orgs-embeddings.json`), guarded by `import.meta.url` check so it doesn't run under test.
- `tests/buildEmbeddings.test.mjs`: 2 tests from the brief, verbatim.

Confirmed against actual Task 3/4 exports before writing: `parseClubsMarkdown(markdown)` returns `{name, categories, summary}[]` (lib/parseClubsMarkdown.mjs); `embedText(text, apiKey, fetchImpl = fetch)` returns `number[]` (lib/geminiEmbed.mjs). Both matched the brief's assumed signatures exactly — no adaptation needed.

## TDD evidence

RED (module not yet created):
```
node --test tests/buildEmbeddings.test.mjs
Error [ERR_MODULE_NOT_FOUND]: Cannot find module '.../scripts/build-embeddings.mjs'
ℹ tests 1
ℹ pass 0
ℹ fail 1
```

GREEN (after implementation):
```
node --test tests/buildEmbeddings.test.mjs
✔ embeds each parsed org and preserves its fields
✔ embeds the concatenation of name, categories, and summary
ℹ tests 2
ℹ pass 2
ℹ fail 0
```

Full suite (`npm test`), confirming no regressions:
```
ℹ tests 12
ℹ pass 12
ℹ fail 0
```
(4 from Task 2's cosine similarity, 3 from Task 3's parser, 3 from Task 4's embed client, 2 new from this task = 12.)

## Files changed
- `apps/wesnest-semantic-search/scripts/build-embeddings.mjs` (new)
- `apps/wesnest-semantic-search/tests/buildEmbeddings.test.mjs` (new)

## Commit
`d22f4c7` — "feat: add build-embeddings script" on branch `wesnest-semantic-search`. Not pushed.

## Self-review
- Interfaces from Tasks 3/4 matched the brief exactly; no guessing/workarounds needed.
- `embedImpl` default param correctly enables dependency injection for tests while defaulting to the real `embedText` for the CLI path.
- CLI `main()` path (reading `GEMINI_API_KEY`, hitting the real API) is intentionally untested here per task instructions — deferred to Task 9.
- Working tree clean after commit; only touched this task's two files.

## Concerns
None. Ready for Task 6 (search API) to consume the JSON shape `{name, categories, summary, embedding}[]`.
