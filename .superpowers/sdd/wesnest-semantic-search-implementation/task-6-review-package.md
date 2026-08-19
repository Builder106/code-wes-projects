## Commits
4eb3dfe feat: add search API with keyword fallback

## Diffstat
 apps/wesnest-semantic-search/api/search.js         | 54 ++++++++++++++++++++++
 .../tests/fixtures/sample-embeddings.json          |  5 ++
 apps/wesnest-semantic-search/tests/search.test.mjs | 32 +++++++++++++
 3 files changed, 91 insertions(+)

## Full diff
diff --git a/apps/wesnest-semantic-search/api/search.js b/apps/wesnest-semantic-search/api/search.js
new file mode 100644
index 0000000..2a74a8b
--- /dev/null
+++ b/apps/wesnest-semantic-search/api/search.js
@@ -0,0 +1,54 @@
+// api/search.js
+import { readFileSync } from 'node:fs';
+import { cosineSimilarity } from '../lib/similarity.mjs';
+import { embedText } from '../lib/geminiEmbed.mjs';
+
+function keywordScore(query, org) {
+  const q = query.toLowerCase();
+  const haystack = `${org.name} ${org.categories} ${org.summary}`.toLowerCase();
+  return haystack.includes(q) ? 1 : 0;
+}
+
+export async function rankOrgs(query, orgs, apiKey, opts = {}) {
+  const embedImpl = opts.embedImpl ?? embedText;
+  const limit = opts.limit ?? 15;
+
+  let scored;
+  try {
+    const queryEmbedding = await embedImpl(query, apiKey);
+    scored = orgs.map((org) => ({
+      ...org,
+      score: cosineSimilarity(queryEmbedding, org.embedding),
+    }));
+  } catch {
+    scored = orgs.map((org) => ({ ...org, score: keywordScore(query, org) }));
+  }
+
+  return scored
+    .sort((a, b) => b.score - a.score)
+    .slice(0, limit)
+    .map(({ embedding, ...rest }) => rest);
+}
+
+let cachedOrgs;
+function loadOrgs() {
+  if (!cachedOrgs) {
+    cachedOrgs = JSON.parse(readFileSync('data/orgs-embeddings.json', 'utf8'));
+  }
+  return cachedOrgs;
+}
+
+export default async function handler(req, res) {
+  if (req.method !== 'POST') {
+    res.status(405).json({ error: 'Method not allowed' });
+    return;
+  }
+  const { query } = req.body ?? {};
+  if (!query || typeof query !== 'string') {
+    res.status(400).json({ error: 'query is required' });
+    return;
+  }
+  const apiKey = process.env.GEMINI_API_KEY;
+  const results = await rankOrgs(query, loadOrgs(), apiKey);
+  res.status(200).json({ results });
+}
diff --git a/apps/wesnest-semantic-search/tests/fixtures/sample-embeddings.json b/apps/wesnest-semantic-search/tests/fixtures/sample-embeddings.json
new file mode 100644
index 0000000..acf762f
--- /dev/null
+++ b/apps/wesnest-semantic-search/tests/fixtures/sample-embeddings.json
@@ -0,0 +1,5 @@
+[
+  { "name": "Code_Wes", "categories": "Academic, Career", "summary": "Club for students interested in coding.", "embedding": [1, 0, 0] },
+  { "name": "Board Games Club", "categories": "Gaming, Social", "summary": "Meet new friends over board games.", "embedding": [0, 1, 0] },
+  { "name": "Wesleyan Outing Club", "categories": "Social", "summary": "Hiking, biking, and canoeing trips.", "embedding": [0, 0, 1] }
+]
diff --git a/apps/wesnest-semantic-search/tests/search.test.mjs b/apps/wesnest-semantic-search/tests/search.test.mjs
new file mode 100644
index 0000000..1476d60
--- /dev/null
+++ b/apps/wesnest-semantic-search/tests/search.test.mjs
@@ -0,0 +1,32 @@
+// tests/search.test.mjs
+import { test } from 'node:test';
+import assert from 'node:assert/strict';
+import { readFileSync } from 'node:fs';
+import { rankOrgs } from '../api/search.js';
+
+const orgs = JSON.parse(readFileSync(new URL('./fixtures/sample-embeddings.json', import.meta.url), 'utf8'));
+
+test('ranks orgs by similarity to the query embedding', async () => {
+  const fakeEmbed = async () => [1, 0, 0];
+  const results = await rankOrgs('coding', orgs, 'fake-key', { embedImpl: fakeEmbed });
+  assert.equal(results[0].name, 'Code_Wes');
+  assert.ok(results[0].score > results[1].score);
+});
+
+test('falls back to keyword match when embedding fails', async () => {
+  const failingEmbed = async () => { throw new Error('embedding API down'); };
+  const results = await rankOrgs('board games', orgs, 'fake-key', { embedImpl: failingEmbed });
+  assert.equal(results[0].name, 'Board Games Club');
+});
+
+test('keyword fallback matches on name, categories, or summary', async () => {
+  const failingEmbed = async () => { throw new Error('embedding API down'); };
+  const results = await rankOrgs('hiking', orgs, 'fake-key', { embedImpl: failingEmbed });
+  assert.equal(results[0].name, 'Wesleyan Outing Club');
+});
+
+test('returns at most the requested limit', async () => {
+  const fakeEmbed = async () => [1, 1, 1];
+  const results = await rankOrgs('anything', orgs, 'fake-key', { embedImpl: fakeEmbed, limit: 2 });
+  assert.equal(results.length, 2);
+});
