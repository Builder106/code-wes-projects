## Task 5: Build-embeddings script

**Files:**
- Create: `scripts/build-embeddings.mjs`
- Test: `tests/buildEmbeddings.test.mjs`

**Interfaces:**
- Consumes: `parseClubsMarkdown` (Task 3), `embedText` (Task 4).
- Produces: an exported `buildEmbeddings(markdown: string, apiKey: string, embedImpl?: typeof embedText) -> Promise<Array<{name, categories, summary, embedding: number[]}>>`, plus a CLI entry point that reads `data/wesleyan_clubs.md` and writes `data/orgs-embeddings.json`. Later tasks (6) read the JSON's shape: `{name, categories, summary, embedding}[]`.

- [ ] **Step 1: Write the failing test**

```javascript
// tests/buildEmbeddings.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildEmbeddings } from '../scripts/build-embeddings.mjs';

const sampleMarkdown = `# Clubs

| Name | Categories | Summary |
| --- | --- | --- |
| Code_Wes | Academic, Career | Club for students interested in coding. |
| Board Games Club | Gaming, Social | Meet new friends over board games. |
`;

test('embeds each parsed org and preserves its fields', async () => {
  const fakeEmbed = async (text) => [text.length, 0, 0];
  const result = await buildEmbeddings(sampleMarkdown, 'fake-key', fakeEmbed);
  assert.equal(result.length, 2);
  assert.equal(result[0].name, 'Code_Wes');
  assert.equal(result[0].categories, 'Academic, Career');
  assert.ok(Array.isArray(result[0].embedding));
});

test('embeds the concatenation of name, categories, and summary', async () => {
  const seen = [];
  const fakeEmbed = async (text) => { seen.push(text); return [0]; };
  await buildEmbeddings(sampleMarkdown, 'fake-key', fakeEmbed);
  assert.ok(seen[0].includes('Code_Wes'));
  assert.ok(seen[0].includes('Academic, Career'));
  assert.ok(seen[0].includes('Club for students interested in coding.'));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/buildEmbeddings.test.mjs`
Expected: FAIL — `Cannot find module '../scripts/build-embeddings.mjs'`

- [ ] **Step 3: Write minimal implementation**

```javascript
// scripts/build-embeddings.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { parseClubsMarkdown } from '../lib/parseClubsMarkdown.mjs';
import { embedText } from '../lib/geminiEmbed.mjs';

export async function buildEmbeddings(markdown, apiKey, embedImpl = embedText) {
  const orgs = parseClubsMarkdown(markdown);
  const results = [];
  for (const org of orgs) {
    const text = `${org.name}. ${org.categories}. ${org.summary}`;
    const embedding = await embedImpl(text, apiKey);
    results.push({ ...org, embedding });
  }
  return results;
}

async function main() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error('GEMINI_API_KEY is not set');
    process.exit(1);
  }
  const markdown = readFileSync('data/wesleyan_clubs.md', 'utf8');
  const results = await buildEmbeddings(markdown, apiKey);
  writeFileSync('data/orgs-embeddings.json', JSON.stringify(results, null, 2));
  console.log(`Wrote ${results.length} org embeddings to data/orgs-embeddings.json`);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test tests/buildEmbeddings.test.mjs`
Expected: PASS, 2 tests

- [ ] **Step 5: Commit**

```bash
git add scripts/build-embeddings.mjs tests/buildEmbeddings.test.mjs
git commit -m "feat: add build-embeddings script"
```

---

