# WesNest Semantic Search

Free-text, meaning-based search over Wesleyan University's club directory.
WesNest's own search only matches exact words in an org's name; this tool
embeds each org's name, categories, and summary, and ranks results by
similarity to a natural-language query.

## Refreshing the data

```bash
npm run scrape-clubs        # WesNest -> data/wesleyan_clubs.md
npm run build-embeddings    # data/wesleyan_clubs.md -> data/orgs-embeddings.json
```

Commit both files and redeploy.

## Development

Requires `GEMINI_API_KEY` in the environment. Run `npm test` for unit
tests, `npm run test:e2e` for Playwright checks.
