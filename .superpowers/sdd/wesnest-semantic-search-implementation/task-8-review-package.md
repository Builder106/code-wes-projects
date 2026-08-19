## Commits
fce5d3e feat: add WesNest scraper

## Diffstat
 .../scripts/scrape-clubs.mjs                       | 37 ++++++++++++++++++++++
 .../tests/fixtures/wesnest-orgs-fixture.html       | 13 ++++++++
 .../tests/scrapeClubs.spec.mjs                     | 22 +++++++++++++
 3 files changed, 72 insertions(+)

## Full diff
diff --git a/apps/wesnest-semantic-search/scripts/scrape-clubs.mjs b/apps/wesnest-semantic-search/scripts/scrape-clubs.mjs
new file mode 100644
index 0000000..84d7c52
--- /dev/null
+++ b/apps/wesnest-semantic-search/scripts/scrape-clubs.mjs
@@ -0,0 +1,37 @@
+// scripts/scrape-clubs.mjs
+// Note: WesNest's org-listing cards do not expose category tags on the
+// listing page itself, only name + summary. `categories` is written empty
+// by a rescrape; the current data/wesleyan_clubs.md's categories were
+// hand-curated and will need re-curating after a rescrape if kept.
+import { chromium } from '@playwright/test';
+import { writeFileSync } from 'node:fs';
+
+export async function extractOrgsFromPage(page) {
+  return page.$$eval('.org-card', (cards) =>
+    cards.map((card) => ({
+      name: card.querySelector('.org-name').textContent.trim(),
+      categories: '',
+      summary: card.querySelector('.org-summary').textContent.trim(),
+    }))
+  );
+}
+
+export function toMarkdownTable(orgs) {
+  const header = '| Name | Categories | Summary |\n| --- | --- | --- |';
+  const rows = orgs.map((o) => `| ${o.name} | ${o.categories} | ${o.summary} |`);
+  return ['# Wesleyan University Clubs and Organizations', '', header, ...rows].join('\n');
+}
+
+async function main() {
+  const browser = await chromium.launch();
+  const page = await browser.newPage();
+  await page.goto('https://wesleyan.campuslabs.com/engage/organizations');
+  const orgs = await extractOrgsFromPage(page);
+  writeFileSync('data/wesleyan_clubs.md', toMarkdownTable(orgs));
+  console.log(`Wrote ${orgs.length} orgs to data/wesleyan_clubs.md`);
+  await browser.close();
+}
+
+if (import.meta.url === `file://${process.argv[1]}`) {
+  main();
+}
diff --git a/apps/wesnest-semantic-search/tests/fixtures/wesnest-orgs-fixture.html b/apps/wesnest-semantic-search/tests/fixtures/wesnest-orgs-fixture.html
new file mode 100644
index 0000000..03eb771
--- /dev/null
+++ b/apps/wesnest-semantic-search/tests/fixtures/wesnest-orgs-fixture.html
@@ -0,0 +1,13 @@
+<!doctype html>
+<html>
+<body>
+  <div class="org-card">
+    <div class="org-name">Code_Wes</div>
+    <div class="org-summary">Club for students interested in coding. We're working on real-life group projects.</div>
+  </div>
+  <div class="org-card">
+    <div class="org-name">Board Games Club</div>
+    <div class="org-summary">The purpose of this club is to provide a fun activity for people to meet new friends.</div>
+  </div>
+</body>
+</html>
diff --git a/apps/wesnest-semantic-search/tests/scrapeClubs.spec.mjs b/apps/wesnest-semantic-search/tests/scrapeClubs.spec.mjs
new file mode 100644
index 0000000..7bc98d7
--- /dev/null
+++ b/apps/wesnest-semantic-search/tests/scrapeClubs.spec.mjs
@@ -0,0 +1,22 @@
+// tests/scrapeClubs.spec.mjs
+import { test, expect } from '@playwright/test';
+import { extractOrgsFromPage, toMarkdownTable } from '../scripts/scrape-clubs.mjs';
+import path from 'node:path';
+import { fileURLToPath } from 'node:url';
+
+const fixturePath = path.join(path.dirname(fileURLToPath(import.meta.url)), 'fixtures', 'wesnest-orgs-fixture.html');
+
+test('extracts org name and summary from the fixture page', async ({ page }) => {
+  await page.goto(`file://${fixturePath}`);
+  const orgs = await extractOrgsFromPage(page);
+  expect(orgs).toHaveLength(2);
+  expect(orgs[0]).toEqual({ name: 'Code_Wes', categories: '', summary: "Club for students interested in coding. We're working on real-life group projects." });
+});
+
+test('renders extracted orgs as a markdown table matching the parser format', () => {
+  const table = toMarkdownTable([
+    { name: 'Code_Wes', categories: '', summary: 'Club for students interested in coding.' },
+  ]);
+  expect(table).toContain('| Name | Categories | Summary |');
+  expect(table).toContain('| Code_Wes |  | Club for students interested in coding. |');
+});
