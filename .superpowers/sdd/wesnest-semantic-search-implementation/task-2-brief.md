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

