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

