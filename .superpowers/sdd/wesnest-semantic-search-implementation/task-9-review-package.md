## Commits
75a1eec data: regenerate embeddings with correct RETRIEVAL_DOCUMENT task_type
b31e5a4 fix: use RETRIEVAL_DOCUMENT/RETRIEVAL_QUERY task_type for asymmetric search
f963406 data: generate embeddings for full club dataset
732034b fix: switch to gemini-embedding-001, text-embedding-004 retired

## Diffstat
 apps/wesnest-semantic-search/api/search.js         |      2 +-
 .../data/orgs-embeddings.json                      | 822095 ++++++++++++++++++
 apps/wesnest-semantic-search/lib/geminiEmbed.mjs   |     12 +-
 .../scripts/build-embeddings.mjs                   |     29 +-
 .../tests/geminiEmbed.test.mjs                     |     24 +-
 5 files changed, 822154 insertions(+), 8 deletions(-)

## Full diff (excluding the large embeddings JSON, summarized separately)
diff --git a/apps/wesnest-semantic-search/api/search.js b/apps/wesnest-semantic-search/api/search.js
index 2a74a8b..7e8edb4 100644
--- a/apps/wesnest-semantic-search/api/search.js
+++ b/apps/wesnest-semantic-search/api/search.js
@@ -8,21 +8,21 @@ function keywordScore(query, org) {
   const haystack = `${org.name} ${org.categories} ${org.summary}`.toLowerCase();
   return haystack.includes(q) ? 1 : 0;
 }
 
 export async function rankOrgs(query, orgs, apiKey, opts = {}) {
   const embedImpl = opts.embedImpl ?? embedText;
   const limit = opts.limit ?? 15;
 
   let scored;
   try {
-    const queryEmbedding = await embedImpl(query, apiKey);
+    const queryEmbedding = await embedImpl(query, apiKey, undefined, 'RETRIEVAL_QUERY');
     scored = orgs.map((org) => ({
       ...org,
       score: cosineSimilarity(queryEmbedding, org.embedding),
     }));
   } catch {
     scored = orgs.map((org) => ({ ...org, score: keywordScore(query, org) }));
   }
 
   return scored
     .sort((a, b) => b.score - a.score)
diff --git a/apps/wesnest-semantic-search/lib/geminiEmbed.mjs b/apps/wesnest-semantic-search/lib/geminiEmbed.mjs
index 0e0a318..a2ec6b4 100644
--- a/apps/wesnest-semantic-search/lib/geminiEmbed.mjs
+++ b/apps/wesnest-semantic-search/lib/geminiEmbed.mjs
@@ -1,16 +1,18 @@
-const ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent';
+const ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent';
 
-export async function embedText(text, apiKey, fetchImpl = fetch) {
+export async function embedText(text, apiKey, fetchImpl = fetch, taskType) {
+  const body = { content: { parts: [{ text }] } };
+  if (taskType) {
+    body.taskType = taskType;
+  }
   const response = await fetchImpl(`${ENDPOINT}?key=${apiKey}`, {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
-    body: JSON.stringify({
-      content: { parts: [{ text }] },
-    }),
+    body: JSON.stringify(body),
   });
   if (!response.ok) {
     throw new Error(`Gemini embedding request failed: ${response.status}`);
   }
   const data = await response.json();
   return data.embedding.values;
 }
diff --git a/apps/wesnest-semantic-search/scripts/build-embeddings.mjs b/apps/wesnest-semantic-search/scripts/build-embeddings.mjs
index 732ddba..910f91d 100644
--- a/apps/wesnest-semantic-search/scripts/build-embeddings.mjs
+++ b/apps/wesnest-semantic-search/scripts/build-embeddings.mjs
@@ -1,21 +1,48 @@
 import { readFileSync, writeFileSync } from 'node:fs';
 import { parseClubsMarkdown } from '../lib/parseClubsMarkdown.mjs';
 import { embedText } from '../lib/geminiEmbed.mjs';
 
+function sleep(ms) {
+  return new Promise((resolve) => setTimeout(resolve, ms));
+}
+
+async function embedWithRetry(text, apiKey, embedImpl, taskType, maxAttempts = 6) {
+  let attempt = 0;
+  let lastError;
+  while (attempt < maxAttempts) {
+    try {
+      return await embedImpl(text, apiKey, undefined, taskType);
+    } catch (error) {
+      lastError = error;
+      const isRateLimited = /\b(429|5\d\d)\b/.test(error.message ?? '');
+      if (!isRateLimited) {
+        throw error;
+      }
+      attempt += 1;
+      const backoffMs = Math.min(30000, 1000 * 2 ** attempt);
+      await sleep(backoffMs);
+    }
+  }
+  throw lastError;
+}
+
 export async function buildEmbeddings(markdown, apiKey, embedImpl = embedText) {
   const orgs = parseClubsMarkdown(markdown);
   const results = [];
   for (const org of orgs) {
     const text = `${org.name}. ${org.categories}. ${org.summary}`;
-    const embedding = await embedImpl(text, apiKey);
+    const embedding = await embedWithRetry(text, apiKey, embedImpl, 'RETRIEVAL_DOCUMENT');
     results.push({ ...org, embedding });
+    if (embedImpl === embedText) {
+      await sleep(300);
+    }
   }
   return results;
 }
 
 async function main() {
   const apiKey = process.env.GEMINI_API_KEY;
   if (!apiKey) {
     console.error('GEMINI_API_KEY is not set');
     process.exit(1);
   }
diff --git a/apps/wesnest-semantic-search/tests/geminiEmbed.test.mjs b/apps/wesnest-semantic-search/tests/geminiEmbed.test.mjs
index 2fdaeff..a30b893 100644
--- a/apps/wesnest-semantic-search/tests/geminiEmbed.test.mjs
+++ b/apps/wesnest-semantic-search/tests/geminiEmbed.test.mjs
@@ -18,20 +18,42 @@ test('returns the embedding vector on success', async () => {
   assert.deepEqual(result, [0.1, 0.2, 0.3]);
 });
 
 test('sends the API key and text in the request', async () => {
   let captured;
   const fetchImpl = async (url, options) => {
     captured = { url, options };
     return { ok: true, status: 200, json: async () => ({ embedding: { values: [1] } }) };
   };
   await embedText('board games', 'my-key', fetchImpl);
-  assert.ok(captured.url.includes('text-embedding-004:embedContent'));
+  assert.ok(captured.url.includes('gemini-embedding-001:embedContent'));
   assert.ok(captured.url.includes('key=my-key'));
   const body = JSON.parse(captured.options.body);
   assert.equal(body.content.parts[0].text, 'board games');
 });
 
 test('throws on a non-2xx response', async () => {
   const fetchImpl = fakeFetch({ error: 'rate limited' }, false);
   await assert.rejects(() => embedText('x', 'key', fetchImpl), /Gemini embedding request failed/);
 });
+
+test('omits taskType from the request body when not provided', async () => {
+  let captured;
+  const fetchImpl = async (url, options) => {
+    captured = options;
+    return { ok: true, status: 200, json: async () => ({ embedding: { values: [1] } }) };
+  };
+  await embedText('board games', 'my-key', fetchImpl);
+  const body = JSON.parse(captured.body);
+  assert.equal('taskType' in body, false);
+});
+
+test('includes taskType in the request body when provided', async () => {
+  let captured;
+  const fetchImpl = async (url, options) => {
+    captured = options;
+    return { ok: true, status: 200, json: async () => ({ embedding: { values: [1] } }) };
+  };
+  await embedText('board games', 'my-key', fetchImpl, 'RETRIEVAL_DOCUMENT');
+  const body = JSON.parse(captured.body);
+  assert.equal(body.taskType, 'RETRIEVAL_DOCUMENT');
+});
