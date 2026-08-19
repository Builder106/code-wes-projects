## Commits
984853f feat: add Gemini embedding client

## Diffstat
 apps/wesnest-semantic-search/lib/geminiEmbed.mjs   | 16 ++++++++++
 .../tests/geminiEmbed.test.mjs                     | 37 ++++++++++++++++++++++
 2 files changed, 53 insertions(+)

## Full diff
diff --git a/apps/wesnest-semantic-search/lib/geminiEmbed.mjs b/apps/wesnest-semantic-search/lib/geminiEmbed.mjs
new file mode 100644
index 0000000..0e0a318
--- /dev/null
+++ b/apps/wesnest-semantic-search/lib/geminiEmbed.mjs
@@ -0,0 +1,16 @@
+const ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent';
+
+export async function embedText(text, apiKey, fetchImpl = fetch) {
+  const response = await fetchImpl(`${ENDPOINT}?key=${apiKey}`, {
+    method: 'POST',
+    headers: { 'Content-Type': 'application/json' },
+    body: JSON.stringify({
+      content: { parts: [{ text }] },
+    }),
+  });
+  if (!response.ok) {
+    throw new Error(`Gemini embedding request failed: ${response.status}`);
+  }
+  const data = await response.json();
+  return data.embedding.values;
+}
diff --git a/apps/wesnest-semantic-search/tests/geminiEmbed.test.mjs b/apps/wesnest-semantic-search/tests/geminiEmbed.test.mjs
new file mode 100644
index 0000000..2fdaeff
--- /dev/null
+++ b/apps/wesnest-semantic-search/tests/geminiEmbed.test.mjs
@@ -0,0 +1,37 @@
+import { test } from 'node:test';
+import assert from 'node:assert/strict';
+import { embedText } from '../lib/geminiEmbed.mjs';
+
+function fakeFetch(response, ok = true) {
+  return async (url, options) => ({
+    ok,
+    status: ok ? 200 : 500,
+    json: async () => response,
+    _url: url,
+    _options: options,
+  });
+}
+
+test('returns the embedding vector on success', async () => {
+  const fetchImpl = fakeFetch({ embedding: { values: [0.1, 0.2, 0.3] } });
+  const result = await embedText('coding club', 'fake-key', fetchImpl);
+  assert.deepEqual(result, [0.1, 0.2, 0.3]);
+});
+
+test('sends the API key and text in the request', async () => {
+  let captured;
+  const fetchImpl = async (url, options) => {
+    captured = { url, options };
+    return { ok: true, status: 200, json: async () => ({ embedding: { values: [1] } }) };
+  };
+  await embedText('board games', 'my-key', fetchImpl);
+  assert.ok(captured.url.includes('text-embedding-004:embedContent'));
+  assert.ok(captured.url.includes('key=my-key'));
+  const body = JSON.parse(captured.options.body);
+  assert.equal(body.content.parts[0].text, 'board games');
+});
+
+test('throws on a non-2xx response', async () => {
+  const fetchImpl = fakeFetch({ error: 'rate limited' }, false);
+  await assert.rejects(() => embedText('x', 'key', fetchImpl), /Gemini embedding request failed/);
+});
