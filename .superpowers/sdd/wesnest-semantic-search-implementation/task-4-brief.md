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

