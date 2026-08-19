## Task 9: Generate real embeddings and deploy

**Files:**
- Modify: `data/orgs-embeddings.json` (generated, not hand-written)
- Modify: `README.md` (add deploy note)

**Interfaces:**
- Consumes: `npm run build-embeddings` (Task 5), the live `data/wesleyan_clubs.md` (Task 1).

- [ ] **Step 1: Generate embeddings for the real 271-org dataset**

Run (on ampere-dev, with `GEMINI_API_KEY` set): `npm run build-embeddings`
Expected: `data/orgs-embeddings.json` created with 271 entries, each with a `name`, `categories`, `summary`, and non-empty `embedding` array.

- [ ] **Step 2: Manually verify a known-vague query returns a sane result**

Run a one-off Node script (not committed) that calls `rankOrgs('something with public speaking', orgs, apiKey)` against the real `data/orgs-embeddings.json` and prints the top 5 names. Confirm at minimum that Wesleyan Debate Society or Wesleyan Mock Trial appears in the top 5.

- [ ] **Step 3: Deploy to Vercel**

```bash
vercel link
vercel env add GEMINI_API_KEY
vercel --prod
```

- [ ] **Step 4: Run the full e2e suite against the deployed URL**

Update `playwright.config.mjs`'s `use.baseURL` temporarily (or pass `--base-url`) to the deployed Vercel URL and rerun `npx playwright test tests/frontend.spec.mjs`. Confirm the live `/api/search` endpoint returns real ranked results for a vague query, not just the mocked-route test from Task 7.

- [ ] **Step 5: Commit the generated embeddings and update the README**

```bash
git add data/orgs-embeddings.json README.md
git commit -m "data: generate embeddings for full club dataset, deploy"
git push
```

---

## Self-Review

**Spec coverage:**
- Free-text semantic search → Tasks 2, 4, 6 (similarity + embedding + ranking).
- Static frontend, no bundler → Task 7.
- Serverless function, key stays server-side → Task 6.
- Keyword fallback on embedding failure → Task 6, tested explicitly.
- Scraper regenerating `wesleyan_clubs.md` → Task 8.
- Build-embeddings script regenerating `orgs-embeddings.json` → Task 5.
- Manual refresh flow (rescrape, rebuild, redeploy) → Task 9 + README.
- Testing: vague-query relevance, empty state, fallback path → Tasks 6, 7, 9.
- All work on ampere-dev, not the Mac → Global Constraints + every task's run commands.

**Placeholder scan:** no TBD/TODO markers; every step has real code or an exact command.

**Type consistency:** `orgs-embeddings.json` shape (`{name, categories, summary, embedding}[]`) is produced in Task 5 and consumed identically in Task 6's `loadOrgs()`/`rankOrgs()`. `rankOrgs`'s return shape (`{name, categories, summary, score}`, embedding stripped) matches what Task 7's frontend reads (`org.name`, `org.categories`, `org.summary`). `parseClubsMarkdown`'s output shape (`{name, categories, summary}`) matches what Task 8's `toMarkdownTable` reads back in — confirmed by Task 3's format being the literal target Task 8 tests against.
