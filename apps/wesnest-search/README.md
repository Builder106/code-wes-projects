# WesNest Search

Free-text, meaning-based search over Wesleyan University's club directory.
WesNest's own search only matches exact words in an org's name; this tool
embeds each org's name, categories, and summary, and ranks results by
similarity to a natural-language query.

## Refreshing the data

```bash
pnpm --filter wesnest-search scrape-clubs
pnpm --filter wesnest-search build-embeddings
```

Commit both files and redeploy.

## Development

Requires `GEMINI_API_KEY` in the environment. Run
`pnpm --filter wesnest-search test` for unit tests and
`pnpm --filter wesnest-search test:e2e` for Playwright checks.

## Deployment

The app is deployed from this monorepo through Vercel. `main` is the canonical
and production branch, and the Vercel Root Directory for this project is
`apps/wesnest-search/`. There is no shared `staging` branch. Feature branches
use CI and pull-request review before they are merged to `main`.

`GEMINI_API_KEY` is set as a Sensitive environment variable on Production in
the Vercel dashboard. Never commit it. A merge to `main` starts the configured
production deployment for this app; keep the Vercel Root Directory and build
settings aligned with `apps/wesnest-search/`.
