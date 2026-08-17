# WesNest Semantic Search

**Status:** Design
**Repo:** to be created at `github.com/Code-Wes/wesnest-semantic-search`

## Problem

WesNest's org directory (`wesleyan.campuslabs.com/engage/organizations`) only
matches on exact words in an org's name. A student who knows roughly what
they want ("something with public speaking," "I like tinkering with
hardware") but not the club's actual name gets nothing useful back. There
are 271 orgs; browsing by hand doesn't scale.

## Goals

- Free-text search over Wesleyan's club directory that matches on meaning,
  not just name substrings.
- Usable by any student, not just the person who built it.
- No ongoing infrastructure cost or maintenance burden beyond an occasional
  manual data refresh.

## Non-goals

- Live sync with WesNest (data is refreshed manually, on demand).
- Auth, accounts, or personalization.
- Editing/submitting org data — this is read-only search.

## Architecture

Static site + one serverless function, deployed on Vercel.

```
index.html (Alpine.js, CDN)
    -> POST /api/search { query }
        -> api/search.js (Vercel serverless function, plain Node)
            -> embed query (Gemini embeddings API)
            -> cosine similarity vs. orgs-embeddings.json (precomputed)
            -> return top N ranked orgs
    <- render result cards
```

- **Frontend**: single `index.html`. Alpine.js handles the search input,
  debouncing, loading state, and rendering result cards (name, categories,
  summary, link back to the org's WesNest page). No build step, no bundler.
- **Backend**: `api/search.js`, a plain Vercel serverless function (no
  framework). Keeps the Gemini API key server-side. Loads
  `orgs-embeddings.json` at cold start, embeds the incoming query, ranks by
  cosine similarity, returns JSON.
- **Fallback**: if the embedding call fails (API down, rate limited),
  `api/search.js` falls back to a keyword substring match over the same
  JSON so search degrades instead of breaking.

## Data pipeline

Two scripts, run manually, both executed on ampere-dev (Playwright + any
install/build step happens there, per VM policy — nothing regenerable runs
on the Mac).

1. `scripts/scrape-clubs.mjs` — Playwright script that re-pulls the WesNest
   org directory into `wesleyan_clubs.md`, matching the existing table
   format (name | categories | summary).
2. `scripts/build-embeddings.mjs` — reads `wesleyan_clubs.md`, embeds
   `name + categories + summary` per org via the Gemini embeddings API,
   writes `orgs-embeddings.json`. Committed to the repo alongside the
   source markdown.

**Refresh flow:** rerun script 1, rerun script 2, commit both outputs,
redeploy. No cron, no auto-refresh — the club roster doesn't change often
enough to justify automation.

## Testing

Playwright checks against the deployed site:

- A vague-phrasing query (e.g., "something with coding") returns a
  relevant org (Code_Wes) near the top of results.
- Empty query state renders without error.
- Simulated embedding-API failure triggers the keyword-fallback path and
  still returns results.

## Open questions

- Exact result-card visual treatment (deferred to implementation —
  loosely modeled on WesNest's own org cards, not a pixel clone).
- Whether to cap total orgs returned or paginate; default to top 10-15
  unless that proves too few during testing.
