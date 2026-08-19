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

