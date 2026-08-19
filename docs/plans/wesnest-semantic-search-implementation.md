# WesNest Semantic Search Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a static search tool that lets students find Wesleyan clubs by meaning ("something with public speaking") instead of exact-name matching, backed by precomputed embeddings and a single Vercel serverless function.

**Architecture:** A static `index.html` (Alpine.js, no build step) posts a query to `/api/search.js`, a plain Vercel serverless function that embeds the query via the Gemini embeddings API, ranks Wesleyan's 271 orgs by cosine similarity against a precomputed `data/orgs-embeddings.json`, and falls back to keyword matching if the embedding call fails. Two standalone scripts (`scripts/scrape-clubs.mjs`, `scripts/build-embeddings.mjs`) regenerate the source data and its embeddings on demand.

**Tech Stack:** Node.js (built-in `node:test` runner), Playwright (scraping + e2e), Alpine.js (CDN), Gemini embeddings API (`text-embedding-004`), Vercel (static hosting + serverless functions).

**Spec:** [docs/specs/wesnest-semantic-search.md](../specs/wesnest-semantic-search.md)

## Global Constraints

- New repo lives at `github.com/Code-Wes/wesnest-semantic-search` — a repo the user does not personally own, so **all work happens on the ampere-dev VM**, never on the Mac (`npm install`, `npm test`, `git`, `gh repo create`, Playwright — everything). Use the `vm-builds` skill's `verify-on-vm`/`dev-on-vm` wrappers.
- No bundler, no frontend framework — `index.html` + Alpine.js via CDN only.
- No database — org data is a committed JSON file, refreshed manually.
- No auth, no accounts, no cron.
- `gh repo create` under the `Code-Wes` org is a write action against a shared org — confirm with the user before running it (Task 1).
- Embedding model: Gemini `text-embedding-004` via direct `fetch` to `https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent` — no SDK dependency, keeps `npm install` minimal.
- API key read from `process.env.GEMINI_API_KEY` — never hardcoded, never logged.

---

## File Structure

```
wesnest-semantic-search/
  package.json
  vercel.json
  index.html                          # Alpine.js frontend, no build step
  api/
    search.js                         # Vercel serverless function
  lib/
    similarity.mjs                    # cosineSimilarity(a, b)
    parseClubsMarkdown.mjs            # markdown table -> [{name, categories, summary}]
    geminiEmbed.mjs                   # embedText(text, apiKey, fetchImpl) -> number[]
  scripts/
    build-embeddings.mjs              # data/wesleyan_clubs.md -> data/orgs-embeddings.json
    scrape-clubs.mjs                  # WesNest -> data/wesleyan_clubs.md (Playwright)
  data/
    wesleyan_clubs.md                 # source snapshot (copied in Task 1)
    orgs-embeddings.json              # generated, committed
  tests/
    similarity.test.mjs
    parseClubsMarkdown.test.mjs
    geminiEmbed.test.mjs
    buildEmbeddings.test.mjs
    search.test.mjs
    scrapeClubs.spec.mjs              # Playwright, fixture-driven
    frontend.spec.mjs                 # Playwright, e2e
    fixtures/
      sample-clubs.md
      wesnest-orgs-fixture.html
  README.md
```

Each `lib/` module has one responsibility and no dependency on the others except through plain function calls — `api/search.js` and `scripts/build-embeddings.mjs` both import `lib/similarity.mjs` and `lib/geminiEmbed.mjs`, so a bug fixed in one place fixes both call sites.

---

## Task 1: Repo scaffold

**Files:**
- Create: `package.json`
- Create: `vercel.json`
- Create: `.gitignore`
- Create: `data/wesleyan_clubs.md` (copied from the notebook repo)
- Create: `README.md`

**Interfaces:**
- Produces: an npm project with `npm test` wired to `node --test tests/`, ready for later tasks to add files under `lib/`, `api/`, `scripts/`, `tests/`.

- [ ] **Step 1: Confirm repo creation with the user**

Ask explicitly: "I'm about to run `gh repo create Code-Wes/wesnest-semantic-search --public` on ampere-dev. OK to proceed?" Do not run the command until the user confirms — this is a write action against a shared org repo per the Mac's global git-safety rules.

- [ ] **Step 2: Create the repo on ampere-dev**

Run (on ampere-dev, via SSH):

```bash
gh repo create Code-Wes/wesnest-semantic-search --public --description "Semantic search over Wesleyan's WesNest club directory"
git clone git@github.com:Code-Wes/wesnest-semantic-search.git
cd wesnest-semantic-search
```

- [ ] **Step 3: Write `package.json`**

```json
{
  "name": "wesnest-semantic-search",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node --test tests/ --test-name-pattern='^(?!.*Playwright)'",
    "test:e2e": "playwright test tests/scrapeClubs.spec.mjs tests/frontend.spec.mjs",
    "build-embeddings": "node scripts/build-embeddings.mjs",
    "scrape-clubs": "node scripts/scrape-clubs.mjs"
  },
  "devDependencies": {
    "@playwright/test": "^1.48.0"
  }
}
```

- [ ] **Step 4: Write `vercel.json`**

```json
{
  "functions": {
    "api/search.js": {
      "runtime": "nodejs20.x"
    }
  }
}
```

- [ ] **Step 5: Write `.gitignore`**

```
node_modules/
test-results/
playwright-report/
.vercel/
```

- [ ] **Step 6: Copy the source data**

Copy the existing snapshot from the notebook repo into `data/wesleyan_clubs.md`:

```bash
cp "/path/to/code-wes-projects/wesleyan_clubs.md" data/wesleyan_clubs.md
```

(Path resolved at execution time — the notebook repo lives in the user's `code-wes-projects` directory on the Mac; copy its contents over, e.g. via `scp` to ampere-dev or pasting the file contents, since all work for this repo happens on the VM.)

- [ ] **Step 7: Write `README.md`**

```markdown
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
```

- [ ] **Step 8: Install dependencies and verify the test command runs**

Run (on ampere-dev): `npm install && npm test`
Expected: passes (no test files yet, `node --test` reports 0 tests, exit code 0).

- [ ] **Step 9: Commit**

```bash
git add package.json vercel.json .gitignore data/wesleyan_clubs.md README.md
git commit -m "chore: scaffold repo"
git push -u origin main
```

---

## Task 2: Cosine similarity

**Files:**
- Create: `lib/similarity.mjs`
- Test: `tests/similarity.test.mjs`

**Interfaces:**
- Produces: `cosineSimilarity(a: number[], b: number[]) -> number`, used by Task 5 (`build-embeddings.mjs`) and Task 6 (`api/search.js`).

- [ ] **Step 1: Write the failing test**

```javascript
// tests/similarity.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { cosineSimilarity } from '../lib/similarity.mjs';

test('identical vectors have similarity 1', () => {
  assert.equal(cosineSimilarity([1, 0, 0], [1, 0, 0]), 1);
});

test('orthogonal vectors have similarity 0', () => {
  assert.equal(cosineSimilarity([1, 0], [0, 1]), 0);
});

test('opposite vectors have similarity -1', () => {
  assert.equal(cosineSimilarity([1, 0], [-1, 0]), -1);
});

test('scales correctly for non-unit vectors', () => {
  const result = cosineSimilarity([3, 4], [6, 8]);
  assert.ok(Math.abs(result - 1) < 1e-9);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/similarity.test.mjs`
Expected: FAIL — `Cannot find module '../lib/similarity.mjs'`

- [ ] **Step 3: Write minimal implementation**

```javascript
// lib/similarity.mjs
export function cosineSimilarity(a, b) {
  let dot = 0, normA = 0, normB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA === 0 || normB === 0) return 0;
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test tests/similarity.test.mjs`
Expected: PASS, 4 tests

- [ ] **Step 5: Commit**

```bash
git add lib/similarity.mjs tests/similarity.test.mjs
git commit -m "feat: add cosine similarity"
```

---

## Task 3: Parse the clubs markdown table

**Files:**
- Create: `lib/parseClubsMarkdown.mjs`
- Create: `tests/fixtures/sample-clubs.md`
- Test: `tests/parseClubsMarkdown.test.mjs`

**Interfaces:**
- Produces: `parseClubsMarkdown(markdown: string) -> Array<{name: string, categories: string, summary: string}>`, used by Task 5 (`build-embeddings.mjs`).

- [ ] **Step 1: Write the fixture**

```markdown
<!-- tests/fixtures/sample-clubs.md -->
# Wesleyan University Clubs and Organizations

| Name | Categories | Summary |
| --- | --- | --- |
| Code_Wes | Independent Projects, Social, Academic, Career | Club for students interested in coding. |
| Board Games Club | Gaming, Social | The purpose of this club is to provide a fun activity for people to meet new friends. |
| Allbritton Center | | At The Allbritton Center for the Study of Public Life, our mission is to cultivate a dynamic community. |
```

- [ ] **Step 2: Write the failing test**

```javascript
// tests/parseClubsMarkdown.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { parseClubsMarkdown } from '../lib/parseClubsMarkdown.mjs';

const fixture = readFileSync(new URL('./fixtures/sample-clubs.md', import.meta.url), 'utf8');

test('parses each row into an org object', () => {
  const orgs = parseClubsMarkdown(fixture);
  assert.equal(orgs.length, 3);
  assert.deepEqual(orgs[0], {
    name: 'Code_Wes',
    categories: 'Independent Projects, Social, Academic, Career',
    summary: 'Club for students interested in coding.',
  });
});

test('handles an empty categories column', () => {
  const orgs = parseClubsMarkdown(fixture);
  const allbritton = orgs.find((o) => o.name === 'Allbritton Center');
  assert.equal(allbritton.categories, '');
});

test('ignores the title and header/separator rows', () => {
  const orgs = parseClubsMarkdown(fixture);
  assert.ok(orgs.every((o) => o.name !== 'Name' && o.name !== '---'));
});
```

- [ ] **Step 3: Run test to verify it fails**

Run: `node --test tests/parseClubsMarkdown.test.mjs`
Expected: FAIL — `Cannot find module '../lib/parseClubsMarkdown.mjs'`

- [ ] **Step 4: Write minimal implementation**

```javascript
// lib/parseClubsMarkdown.mjs
export function parseClubsMarkdown(markdown) {
  const orgs = [];
  const lines = markdown.split('\n');
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed.startsWith('|')) continue;
    const cells = trimmed
      .slice(1, -1)
      .split('|')
      .map((cell) => cell.trim());
    if (cells.length !== 3) continue;
    const [name, categories, summary] = cells;
    if (name === 'Name' || /^-+$/.test(name)) continue;
    orgs.push({ name, categories, summary });
  }
  return orgs;
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `node --test tests/parseClubsMarkdown.test.mjs`
Expected: PASS, 3 tests

- [ ] **Step 6: Commit**

```bash
git add lib/parseClubsMarkdown.mjs tests/parseClubsMarkdown.test.mjs tests/fixtures/sample-clubs.md
git commit -m "feat: parse clubs markdown table"
```

---

## Task 4: Gemini embedding client

**Files:**
- Create: `lib/geminiEmbed.mjs`
- Test: `tests/geminiEmbed.test.mjs`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `embedText(text: string, apiKey: string, fetchImpl?: typeof fetch) -> Promise<number[]>`, throws on a non-2xx response. Used by Task 5 (`build-embeddings.mjs`) and Task 6 (`api/search.js`).

- [ ] **Step 1: Write the failing test**

```javascript
// tests/geminiEmbed.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { embedText } from '../lib/geminiEmbed.mjs';

function fakeFetch(response, ok = true) {
  return async (url, options) => ({
    ok,
    status: ok ? 200 : 500,
    json: async () => response,
    _url: url,
    _options: options,
  });
}

test('returns the embedding vector on success', async () => {
  const fetchImpl = fakeFetch({ embedding: { values: [0.1, 0.2, 0.3] } });
  const result = await embedText('coding club', 'fake-key', fetchImpl);
  assert.deepEqual(result, [0.1, 0.2, 0.3]);
});

test('sends the API key and text in the request', async () => {
  let captured;
  const fetchImpl = async (url, options) => {
    captured = { url, options };
    return { ok: true, status: 200, json: async () => ({ embedding: { values: [1] } }) };
  };
  await embedText('board games', 'my-key', fetchImpl);
  assert.ok(captured.url.includes('text-embedding-004:embedContent'));
  assert.ok(captured.url.includes('key=my-key'));
  const body = JSON.parse(captured.options.body);
  assert.equal(body.content.parts[0].text, 'board games');
});

test('throws on a non-2xx response', async () => {
  const fetchImpl = fakeFetch({ error: 'rate limited' }, false);
  await assert.rejects(() => embedText('x', 'key', fetchImpl), /Gemini embedding request failed/);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/geminiEmbed.test.mjs`
Expected: FAIL — `Cannot find module '../lib/geminiEmbed.mjs'`

- [ ] **Step 3: Write minimal implementation**

```javascript
// lib/geminiEmbed.mjs
const ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent';

export async function embedText(text, apiKey, fetchImpl = fetch) {
  const response = await fetchImpl(`${ENDPOINT}?key=${apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      content: { parts: [{ text }] },
    }),
  });
  if (!response.ok) {
    throw new Error(`Gemini embedding request failed: ${response.status}`);
  }
  const data = await response.json();
  return data.embedding.values;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test tests/geminiEmbed.test.mjs`
Expected: PASS, 3 tests

- [ ] **Step 5: Commit**

```bash
git add lib/geminiEmbed.mjs tests/geminiEmbed.test.mjs
git commit -m "feat: add Gemini embedding client"
```

---

## Task 5: Build-embeddings script

**Files:**
- Create: `scripts/build-embeddings.mjs`
- Test: `tests/buildEmbeddings.test.mjs`

**Interfaces:**
- Consumes: `parseClubsMarkdown` (Task 3), `embedText` (Task 4).
- Produces: an exported `buildEmbeddings(markdown: string, apiKey: string, embedImpl?: typeof embedText) -> Promise<Array<{name, categories, summary, embedding: number[]}>>`, plus a CLI entry point that reads `data/wesleyan_clubs.md` and writes `data/orgs-embeddings.json`. Later tasks (6) read the JSON's shape: `{name, categories, summary, embedding}[]`.

- [ ] **Step 1: Write the failing test**

```javascript
// tests/buildEmbeddings.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildEmbeddings } from '../scripts/build-embeddings.mjs';

const sampleMarkdown = `# Clubs

| Name | Categories | Summary |
| --- | --- | --- |
| Code_Wes | Academic, Career | Club for students interested in coding. |
| Board Games Club | Gaming, Social | Meet new friends over board games. |
`;

test('embeds each parsed org and preserves its fields', async () => {
  const fakeEmbed = async (text) => [text.length, 0, 0];
  const result = await buildEmbeddings(sampleMarkdown, 'fake-key', fakeEmbed);
  assert.equal(result.length, 2);
  assert.equal(result[0].name, 'Code_Wes');
  assert.equal(result[0].categories, 'Academic, Career');
  assert.ok(Array.isArray(result[0].embedding));
});

test('embeds the concatenation of name, categories, and summary', async () => {
  const seen = [];
  const fakeEmbed = async (text) => { seen.push(text); return [0]; };
  await buildEmbeddings(sampleMarkdown, 'fake-key', fakeEmbed);
  assert.ok(seen[0].includes('Code_Wes'));
  assert.ok(seen[0].includes('Academic, Career'));
  assert.ok(seen[0].includes('Club for students interested in coding.'));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/buildEmbeddings.test.mjs`
Expected: FAIL — `Cannot find module '../scripts/build-embeddings.mjs'`

- [ ] **Step 3: Write minimal implementation**

```javascript
// scripts/build-embeddings.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { parseClubsMarkdown } from '../lib/parseClubsMarkdown.mjs';
import { embedText } from '../lib/geminiEmbed.mjs';

export async function buildEmbeddings(markdown, apiKey, embedImpl = embedText) {
  const orgs = parseClubsMarkdown(markdown);
  const results = [];
  for (const org of orgs) {
    const text = `${org.name}. ${org.categories}. ${org.summary}`;
    const embedding = await embedImpl(text, apiKey);
    results.push({ ...org, embedding });
  }
  return results;
}

async function main() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error('GEMINI_API_KEY is not set');
    process.exit(1);
  }
  const markdown = readFileSync('data/wesleyan_clubs.md', 'utf8');
  const results = await buildEmbeddings(markdown, apiKey);
  writeFileSync('data/orgs-embeddings.json', JSON.stringify(results, null, 2));
  console.log(`Wrote ${results.length} org embeddings to data/orgs-embeddings.json`);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test tests/buildEmbeddings.test.mjs`
Expected: PASS, 2 tests

- [ ] **Step 5: Commit**

```bash
git add scripts/build-embeddings.mjs tests/buildEmbeddings.test.mjs
git commit -m "feat: add build-embeddings script"
```

---

## Task 6: Search API with keyword fallback

**Files:**
- Create: `api/search.js`
- Create: `tests/fixtures/sample-embeddings.json`
- Test: `tests/search.test.mjs`

**Interfaces:**
- Consumes: `cosineSimilarity` (Task 2), `embedText` (Task 4), an `orgs-embeddings.json`-shaped array (Task 5's output shape).
- Produces: an exported `rankOrgs(query, orgs, apiKey, opts?) -> Promise<Array<{name, categories, summary, score}>>` for testing, and a default-exported Vercel handler `(req, res)` that calls it.

- [ ] **Step 1: Write the fixture**

```json
[
  { "name": "Code_Wes", "categories": "Academic, Career", "summary": "Club for students interested in coding.", "embedding": [1, 0, 0] },
  { "name": "Board Games Club", "categories": "Gaming, Social", "summary": "Meet new friends over board games.", "embedding": [0, 1, 0] },
  { "name": "Wesleyan Outing Club", "categories": "Social", "summary": "Hiking, biking, and canoeing trips.", "embedding": [0, 0, 1] }
]
```

(Save as `tests/fixtures/sample-embeddings.json`.)

- [ ] **Step 2: Write the failing test**

```javascript
// tests/search.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { rankOrgs } from '../api/search.js';

const orgs = JSON.parse(readFileSync(new URL('./fixtures/sample-embeddings.json', import.meta.url), 'utf8'));

test('ranks orgs by similarity to the query embedding', async () => {
  const fakeEmbed = async () => [1, 0, 0];
  const results = await rankOrgs('coding', orgs, 'fake-key', { embedImpl: fakeEmbed });
  assert.equal(results[0].name, 'Code_Wes');
  assert.ok(results[0].score > results[1].score);
});

test('falls back to keyword match when embedding fails', async () => {
  const failingEmbed = async () => { throw new Error('embedding API down'); };
  const results = await rankOrgs('board games', orgs, 'fake-key', { embedImpl: failingEmbed });
  assert.equal(results[0].name, 'Board Games Club');
});

test('keyword fallback matches on name, categories, or summary', async () => {
  const failingEmbed = async () => { throw new Error('embedding API down'); };
  const results = await rankOrgs('hiking', orgs, 'fake-key', { embedImpl: failingEmbed });
  assert.equal(results[0].name, 'Wesleyan Outing Club');
});

test('returns at most the requested limit', async () => {
  const fakeEmbed = async () => [1, 1, 1];
  const results = await rankOrgs('anything', orgs, 'fake-key', { embedImpl: fakeEmbed, limit: 2 });
  assert.equal(results.length, 2);
});
```

- [ ] **Step 3: Run test to verify it fails**

Run: `node --test tests/search.test.mjs`
Expected: FAIL — `Cannot find module '../api/search.js'`

- [ ] **Step 4: Write minimal implementation**

```javascript
// api/search.js
import { readFileSync } from 'node:fs';
import { cosineSimilarity } from '../lib/similarity.mjs';
import { embedText } from '../lib/geminiEmbed.mjs';

function keywordScore(query, org) {
  const q = query.toLowerCase();
  const haystack = `${org.name} ${org.categories} ${org.summary}`.toLowerCase();
  return haystack.includes(q) ? 1 : 0;
}

export async function rankOrgs(query, orgs, apiKey, opts = {}) {
  const embedImpl = opts.embedImpl ?? embedText;
  const limit = opts.limit ?? 15;

  let scored;
  try {
    const queryEmbedding = await embedImpl(query, apiKey);
    scored = orgs.map((org) => ({
      ...org,
      score: cosineSimilarity(queryEmbedding, org.embedding),
    }));
  } catch {
    scored = orgs.map((org) => ({ ...org, score: keywordScore(query, org) }));
  }

  return scored
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map(({ embedding, ...rest }) => rest);
}

let cachedOrgs;
function loadOrgs() {
  if (!cachedOrgs) {
    cachedOrgs = JSON.parse(readFileSync('data/orgs-embeddings.json', 'utf8'));
  }
  return cachedOrgs;
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }
  const { query } = req.body ?? {};
  if (!query || typeof query !== 'string') {
    res.status(400).json({ error: 'query is required' });
    return;
  }
  const apiKey = process.env.GEMINI_API_KEY;
  const results = await rankOrgs(query, loadOrgs(), apiKey);
  res.status(200).json({ results });
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `node --test tests/search.test.mjs`
Expected: PASS, 4 tests

- [ ] **Step 6: Commit**

```bash
git add api/search.js tests/search.test.mjs tests/fixtures/sample-embeddings.json
git commit -m "feat: add search API with keyword fallback"
```

---

## Task 7: Frontend

**Files:**
- Create: `index.html`
- Test: `tests/frontend.spec.mjs` (Playwright)

**Interfaces:**
- Consumes: `POST /api/search` (Task 6), request body `{query: string}`, response body `{results: Array<{name, categories, summary, score}>}`.

- [ ] **Step 1: Write the failing test**

```javascript
// tests/frontend.spec.mjs
import { test, expect } from '@playwright/test';

test('renders results after typing a query', async ({ page }) => {
  await page.route('**/api/search', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        results: [
          { name: 'Code_Wes', categories: 'Academic, Career', summary: 'Club for students interested in coding.', score: 0.9 },
        ],
      }),
    });
  });

  await page.goto('/index.html');
  await page.fill('[data-testid="search-input"]', 'coding');
  await expect(page.locator('[data-testid="result-card"]')).toHaveCount(1);
  await expect(page.locator('[data-testid="result-card"]')).toContainText('Code_Wes');
});

test('shows an empty state before any query', async ({ page }) => {
  await page.goto('/index.html');
  await expect(page.locator('[data-testid="result-card"]')).toHaveCount(0);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx playwright test tests/frontend.spec.mjs`
Expected: FAIL — navigation to `/index.html` 404s (file doesn't exist yet / no dev server configured)

- [ ] **Step 3: Compute the real SRI hash for the pinned Alpine.js version**

Run: `curl -s https://cdn.jsdelivr.net/npm/alpinejs@3.14.1/dist/cdn.min.js | openssl dgst -sha384 -binary | openssl base64 -A`
Copy the printed base64 string — this is the real hash for the exact file being pinned. Do not reuse a hash from memory or another version; jsDelivr's per-version files are immutable, but the hash must match this exact download.

- [ ] **Step 4: Write minimal implementation**

```html
<!-- index.html -->
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>WesNest Semantic Search</title>
  <script
    defer
    src="https://cdn.jsdelivr.net/npm/alpinejs@3.14.1/dist/cdn.min.js"
    integrity="sha384-<paste the hash computed in Step 3>"
    crossorigin="anonymous"
  ></script>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 640px; margin: 2rem auto; padding: 0 1rem; }
    input { width: 100%; padding: 0.75rem; font-size: 1rem; }
    .card { border: 1px solid #ddd; border-radius: 8px; padding: 1rem; margin-top: 1rem; }
    .categories { color: #666; font-size: 0.85rem; }
  </style>
</head>
<body>
  <h1>Find a Wesleyan club</h1>
  <div x-data="clubSearch()">
    <input
      type="search"
      placeholder="Describe what you're looking for..."
      data-testid="search-input"
      x-model="query"
      @input.debounce.400ms="search()"
    />
    <template x-for="org in results" :key="org.name">
      <div class="card" data-testid="result-card">
        <strong x-text="org.name"></strong>
        <div class="categories" x-text="org.categories"></div>
        <p x-text="org.summary"></p>
      </div>
    </template>
  </div>

  <script>
    function clubSearch() {
      return {
        query: '',
        results: [],
        async search() {
          if (!this.query.trim()) {
            this.results = [];
            return;
          }
          const response = await fetch('/api/search', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ query: this.query }),
          });
          const data = await response.json();
          this.results = data.results ?? [];
        },
      };
    }
  </script>
</body>
</html>
```

- [ ] **Step 5: Add a Playwright config pointing at a local static server**

```javascript
// playwright.config.mjs
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: 'tests',
  webServer: {
    command: 'npx serve . -l 4173',
    url: 'http://localhost:4173',
    reuseExistingServer: true,
  },
  use: {
    baseURL: 'http://localhost:4173',
  },
});
```

Add `serve` as a dev dependency: `npm install --save-dev serve`

- [ ] **Step 6: Run test to verify it passes**

Run: `npx playwright test tests/frontend.spec.mjs`
Expected: PASS, 2 tests

- [ ] **Step 7: Commit**

```bash
git add index.html playwright.config.mjs tests/frontend.spec.mjs package.json package-lock.json
git commit -m "feat: add search frontend"
```

---

## Task 8: Scraper

**Files:**
- Create: `scripts/scrape-clubs.mjs`
- Create: `tests/fixtures/wesnest-orgs-fixture.html`
- Test: `tests/scrapeClubs.spec.mjs` (Playwright)

**Interfaces:**
- Produces: an exported `extractOrgsFromPage(page) -> Promise<Array<{name, categories, summary}>>` (tested against a local fixture page) and `toMarkdownTable(orgs) -> string` (same table format `parseClubsMarkdown` from Task 3 reads), plus a CLI entry point that scrapes the live WesNest site and writes `data/wesleyan_clubs.md`.

- [ ] **Step 1: Write the fixture page**

Build a minimal HTML page under `tests/fixtures/wesnest-orgs-fixture.html` with the same DOM shape WesNest's org cards use — one container per org holding a name element and a description element, e.g.:

```html
<!doctype html>
<html>
<body>
  <div class="org-card">
    <div class="org-name">Code_Wes</div>
    <div class="org-summary">Club for students interested in coding. We're working on real-life group projects.</div>
  </div>
  <div class="org-card">
    <div class="org-name">Board Games Club</div>
    <div class="org-summary">The purpose of this club is to provide a fun activity for people to meet new friends.</div>
  </div>
</body>
</html>
```

(WesNest doesn't expose categories directly on the listing page — the scraper leaves `categories` empty; categories in the current `wesleyan_clubs.md` were hand-curated. Note this in the script's header comment so a future maintainer isn't surprised the rescraped file drops categories.)

- [ ] **Step 2: Write the failing test**

```javascript
// tests/scrapeClubs.spec.mjs
import { test, expect } from '@playwright/test';
import { extractOrgsFromPage, toMarkdownTable } from '../scripts/scrape-clubs.mjs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const fixturePath = path.join(path.dirname(fileURLToPath(import.meta.url)), 'fixtures', 'wesnest-orgs-fixture.html');

test('extracts org name and summary from the fixture page', async ({ page }) => {
  await page.goto(`file://${fixturePath}`);
  const orgs = await extractOrgsFromPage(page);
  expect(orgs).toHaveLength(2);
  expect(orgs[0]).toEqual({ name: 'Code_Wes', categories: '', summary: "Club for students interested in coding. We're working on real-life group projects." });
});

test('renders extracted orgs as a markdown table matching the parser format', () => {
  const table = toMarkdownTable([
    { name: 'Code_Wes', categories: '', summary: 'Club for students interested in coding.' },
  ]);
  expect(table).toContain('| Name | Categories | Summary |');
  expect(table).toContain('| Code_Wes |  | Club for students interested in coding. |');
});
```

- [ ] **Step 3: Run test to verify it fails**

Run: `npx playwright test tests/scrapeClubs.spec.mjs`
Expected: FAIL — `Cannot find module '../scripts/scrape-clubs.mjs'`

- [ ] **Step 4: Write minimal implementation**

```javascript
// scripts/scrape-clubs.mjs
// Note: WesNest's org-listing cards do not expose category tags on the
// listing page itself, only name + summary. `categories` is written empty
// by a rescrape; the current data/wesleyan_clubs.md's categories were
// hand-curated and will need re-curating after a rescrape if kept.
import { chromium } from '@playwright/test';
import { writeFileSync } from 'node:fs';

export async function extractOrgsFromPage(page) {
  return page.$$eval('.org-card', (cards) =>
    cards.map((card) => ({
      name: card.querySelector('.org-name').textContent.trim(),
      categories: '',
      summary: card.querySelector('.org-summary').textContent.trim(),
    }))
  );
}

export function toMarkdownTable(orgs) {
  const header = '| Name | Categories | Summary |\n| --- | --- | --- |';
  const rows = orgs.map((o) => `| ${o.name} | ${o.categories} | ${o.summary} |`);
  return ['# Wesleyan University Clubs and Organizations', '', header, ...rows].join('\n');
}

async function main() {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('https://wesleyan.campuslabs.com/engage/organizations');
  const orgs = await extractOrgsFromPage(page);
  writeFileSync('data/wesleyan_clubs.md', toMarkdownTable(orgs));
  console.log(`Wrote ${orgs.length} orgs to data/wesleyan_clubs.md`);
  await browser.close();
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `npx playwright test tests/scrapeClubs.spec.mjs`
Expected: PASS, 2 tests

- [ ] **Step 6: Commit**

```bash
git add scripts/scrape-clubs.mjs tests/scrapeClubs.spec.mjs tests/fixtures/wesnest-orgs-fixture.html
git commit -m "feat: add WesNest scraper"
```

---

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
