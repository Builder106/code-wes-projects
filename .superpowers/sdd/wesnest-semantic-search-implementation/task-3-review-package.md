## Commits
f1deb11 feat: parse clubs markdown table

## Diffstat
 .../lib/parseClubsMarkdown.mjs                     | 17 ++++++++++++++
 .../tests/fixtures/sample-clubs.md                 |  7 ++++++
 .../tests/parseClubsMarkdown.test.mjs              | 27 ++++++++++++++++++++++
 3 files changed, 51 insertions(+)

## Full diff
diff --git a/apps/wesnest-semantic-search/lib/parseClubsMarkdown.mjs b/apps/wesnest-semantic-search/lib/parseClubsMarkdown.mjs
new file mode 100644
index 0000000..b6b4d04
--- /dev/null
+++ b/apps/wesnest-semantic-search/lib/parseClubsMarkdown.mjs
@@ -0,0 +1,17 @@
+export function parseClubsMarkdown(markdown) {
+  const orgs = [];
+  const lines = markdown.split('\n');
+  for (const line of lines) {
+    const trimmed = line.trim();
+    if (!trimmed.startsWith('|')) continue;
+    const cells = trimmed
+      .slice(1, -1)
+      .split('|')
+      .map((cell) => cell.trim());
+    if (cells.length !== 3) continue;
+    const [name, categories, summary] = cells;
+    if (name === 'Name' || /^-+$/.test(name)) continue;
+    orgs.push({ name, categories, summary });
+  }
+  return orgs;
+}
diff --git a/apps/wesnest-semantic-search/tests/fixtures/sample-clubs.md b/apps/wesnest-semantic-search/tests/fixtures/sample-clubs.md
new file mode 100644
index 0000000..d9ab1e0
--- /dev/null
+++ b/apps/wesnest-semantic-search/tests/fixtures/sample-clubs.md
@@ -0,0 +1,7 @@
+# Wesleyan University Clubs and Organizations
+
+| Name | Categories | Summary |
+| --- | --- | --- |
+| Code_Wes | Independent Projects, Social, Academic, Career | Club for students interested in coding. |
+| Board Games Club | Gaming, Social | The purpose of this club is to provide a fun activity for people to meet new friends. |
+| Allbritton Center | | At The Allbritton Center for the Study of Public Life, our mission is to cultivate a dynamic community. |
diff --git a/apps/wesnest-semantic-search/tests/parseClubsMarkdown.test.mjs b/apps/wesnest-semantic-search/tests/parseClubsMarkdown.test.mjs
new file mode 100644
index 0000000..7c29ad6
--- /dev/null
+++ b/apps/wesnest-semantic-search/tests/parseClubsMarkdown.test.mjs
@@ -0,0 +1,27 @@
+import { test } from 'node:test';
+import assert from 'node:assert/strict';
+import { readFileSync } from 'node:fs';
+import { parseClubsMarkdown } from '../lib/parseClubsMarkdown.mjs';
+
+const fixture = readFileSync(new URL('./fixtures/sample-clubs.md', import.meta.url), 'utf8');
+
+test('parses each row into an org object', () => {
+  const orgs = parseClubsMarkdown(fixture);
+  assert.equal(orgs.length, 3);
+  assert.deepEqual(orgs[0], {
+    name: 'Code_Wes',
+    categories: 'Independent Projects, Social, Academic, Career',
+    summary: 'Club for students interested in coding.',
+  });
+});
+
+test('handles an empty categories column', () => {
+  const orgs = parseClubsMarkdown(fixture);
+  const allbritton = orgs.find((o) => o.name === 'Allbritton Center');
+  assert.equal(allbritton.categories, '');
+});
+
+test('ignores the title and header/separator rows', () => {
+  const orgs = parseClubsMarkdown(fixture);
+  assert.ok(orgs.every((o) => o.name !== 'Name' && o.name !== '---'));
+});
