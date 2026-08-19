## Commits
edf7c8b feat: add cosine similarity

## Diffstat
 apps/wesnest-semantic-search/lib/similarity.mjs     | 11 +++++++++++
 .../tests/similarity.test.mjs                       | 21 +++++++++++++++++++++
 2 files changed, 32 insertions(+)

## Full diff
diff --git a/apps/wesnest-semantic-search/lib/similarity.mjs b/apps/wesnest-semantic-search/lib/similarity.mjs
new file mode 100644
index 0000000..7de5de3
--- /dev/null
+++ b/apps/wesnest-semantic-search/lib/similarity.mjs
@@ -0,0 +1,11 @@
+// lib/similarity.mjs
+export function cosineSimilarity(a, b) {
+  let dot = 0, normA = 0, normB = 0;
+  for (let i = 0; i < a.length; i++) {
+    dot += a[i] * b[i];
+    normA += a[i] * a[i];
+    normB += b[i] * b[i];
+  }
+  if (normA === 0 || normB === 0) return 0;
+  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
+}
diff --git a/apps/wesnest-semantic-search/tests/similarity.test.mjs b/apps/wesnest-semantic-search/tests/similarity.test.mjs
new file mode 100644
index 0000000..2f3c6d5
--- /dev/null
+++ b/apps/wesnest-semantic-search/tests/similarity.test.mjs
@@ -0,0 +1,21 @@
+// tests/similarity.test.mjs
+import { test } from 'node:test';
+import assert from 'node:assert/strict';
+import { cosineSimilarity } from '../lib/similarity.mjs';
+
+test('identical vectors have similarity 1', () => {
+  assert.equal(cosineSimilarity([1, 0, 0], [1, 0, 0]), 1);
+});
+
+test('orthogonal vectors have similarity 0', () => {
+  assert.equal(cosineSimilarity([1, 0], [0, 1]), 0);
+});
+
+test('opposite vectors have similarity -1', () => {
+  assert.equal(cosineSimilarity([1, 0], [-1, 0]), -1);
+});
+
+test('scales correctly for non-unit vectors', () => {
+  const result = cosineSimilarity([3, 4], [6, 8]);
+  assert.ok(Math.abs(result - 1) < 1e-9);
+});
