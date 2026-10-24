# WesNest Semantic Search

> Free-text, meaning-based search over Wesleyan University's student organization directory.

Developed by the **Code_Wes** student engineering team at Wesleyan University.

---

## 🎯 The Problem

Wesleyan's official WesNest directory (`wesleyan.campuslabs.com/engage/organizations`) only matches exact substrings in organization names. If a student searches for "community service", "public speaking", "robotics", or "tinkering with hardware", WesNest returns zero matches unless those exact words appear in the club's name.

With over 270 registered campus organizations, manual browsing does not scale. WesNest Semantic Search embeds club names, categories, and descriptions using Google Gemini embeddings (`text-embedding-004`) to rank results by semantic relevance to natural-language student queries.

---

## 🏗️ Architecture

```
Student Query ("something with public speaking")
       │
       ▼
[ index.html (Alpine.js UI) ]
       │  POST /api/search { query }
       ▼
[ api/search.js (Vercel Serverless Function) ]
       │
       ├─► 1. Embed query via Gemini API (lib/geminiEmbed.mjs)
       │      └─► Fallback: keyword matching if API unavailable
       │
       ├─► 2. Cosine similarity vs data/orgs-embeddings.json (lib/similarity.mjs)
       │
       └─► 3. Rank, slice top results, return JSON
```

- **Frontend**: Zero-bundler static single-page app in `index.html` powered by Alpine.js via CDN. Fast, lightweight, and accessible.
- **Backend API**: Plain Node.js Vercel serverless function (`api/search.js`). Keeps the Gemini API key secure on the server side.
- **Resilience / Fallback**: If the Gemini embedding call is rate-limited or unavailable, the backend automatically degrades to keyword matching across the org database so search never completely breaks.
- **Offline / Precomputed Embeddings**: Club descriptions are precomputed in `data/orgs-embeddings.json`. No runtime database connection is required.

---

## 🚀 Quickstart for Code_Wes Developers

### Prerequisites

- Node.js `24.x` (or `>=24 <27`)
- pnpm `11.x`

### 1. Environment Setup

Copy `.env.example` to `.env` in `apps/wesnest-search/`:

```bash
cp apps/wesnest-search/.env.example apps/wesnest-search/.env
```

Add your Gemini API key from [Google AI Studio](https://aistudio.google.com/).
*Note: If you do not have an API key yet, the local dev server and API will automatically fall back to keyword search.*

### 2. Start Local Development Server

From the repository root:

```bash
pnpm dev:wesnest
```

Or from inside `apps/wesnest-search`:

```bash
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser. The local development server serves the static frontend and dynamically handles `POST /api/search` requests with your local function code.

---

## 🧪 Testing & Quality Gates

Code-Wes projects maintain a strict 100% test coverage gate on core business logic (`lib/**` and `api/**`).

### Unit & Integration Tests

```bash
# Run unit tests
pnpm --filter wesnest-search test

# Run test coverage gate (enforces 100% lines, functions, and branches)
pnpm --filter wesnest-search test:coverage
```

### End-to-End Browser Tests (Playwright)

```bash
# Run all Playwright specs (requires Playwright browser installed)
pnpm --filter wesnest-search test:e2e

# Run only frontend and responsiveness specs
pnpm --filter wesnest-search test:e2e:frontend
```

---

## 🔄 Refreshing Club Data & Embeddings

Club rosters are typically refreshed once per semester around the Student Club Fair:

```bash
# Step 1: Scrape the latest club directory from WesNest
pnpm --filter wesnest-search scrape-clubs

# Step 2: Regenerate semantic embeddings using Gemini API
pnpm --filter wesnest-search build-embeddings
```

Review the updated `data/wesleyan_clubs.md` and `data/orgs-embeddings.json`, commit the diffs, and push via pull request.

---

## 🚢 Deployment

- Deployed automatically via Vercel on merges to `main`.
- Vercel Root Directory: `apps/wesnest-search/`.
- `GEMINI_API_KEY` is configured as a sensitive environment variable in the Vercel project dashboard.
