## Task 3: Parse the clubs markdown table

**Files:**
- Create: `lib/parseClubsMarkdown.mjs`
- Create: `tests/fixtures/sample-clubs.md`
- Test: `tests/parseClubsMarkdown.test.mjs`

**Interfaces:**
- Produces: `parseClubsMarkdown(markdown: string) -> Array<{name: string, categories: string, summary: string}>`, used by Task 5 (`build-embeddings.mjs`).

- [ ] **Step 1: Write the fixture**

```markdown
<!-- tests/fixtures/sample-clubs.md -->
# Wesleyan University Clubs and Organizations

| Name | Categories | Summary |
| --- | --- | --- |
| Code_Wes | Independent Projects, Social, Academic, Career | Club for students interested in coding. |
| Board Games Club | Gaming, Social | The purpose of this club is to provide a fun activity for people to meet new friends. |
| Allbritton Center | | At The Allbritton Center for the Study of Public Life, our mission is to cultivate a dynamic community. |
```

- [ ] **Step 2: Write the failing test**

```javascript
// tests/parseClubsMarkdown.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { parseClubsMarkdown } from '../lib/parseClubsMarkdown.mjs';

const fixture = readFileSync(new URL('./fixtures/sample-clubs.md', import.meta.url), 'utf8');

test('parses each row into an org object', () => {
  const orgs = parseClubsMarkdown(fixture);
  assert.equal(orgs.length, 3);
  assert.deepEqual(orgs[0], {
    name: 'Code_Wes',
    categories: 'Independent Projects, Social, Academic, Career',
    summary: 'Club for students interested in coding.',
  });
});

test('handles an empty categories column', () => {
  const orgs = parseClubsMarkdown(fixture);
  const allbritton = orgs.find((o) => o.name === 'Allbritton Center');
  assert.equal(allbritton.categories, '');
});

test('ignores the title and header/separator rows', () => {
  const orgs = parseClubsMarkdown(fixture);
  assert.ok(orgs.every((o) => o.name !== 'Name' && o.name !== '---'));
});
```

- [ ] **Step 3: Run test to verify it fails**

Run: `node --test tests/parseClubsMarkdown.test.mjs`
Expected: FAIL — `Cannot find module '../lib/parseClubsMarkdown.mjs'`

- [ ] **Step 4: Write minimal implementation**

```javascript
// lib/parseClubsMarkdown.mjs
export function parseClubsMarkdown(markdown) {
  const orgs = [];
  const lines = markdown.split('\n');
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed.startsWith('|')) continue;
    const cells = trimmed
      .slice(1, -1)
      .split('|')
      .map((cell) => cell.trim());
    if (cells.length !== 3) continue;
    const [name, categories, summary] = cells;
    if (name === 'Name' || /^-+$/.test(name)) continue;
    orgs.push({ name, categories, summary });
  }
  return orgs;
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `node --test tests/parseClubsMarkdown.test.mjs`
Expected: PASS, 3 tests

- [ ] **Step 6: Commit**

```bash
git add lib/parseClubsMarkdown.mjs tests/parseClubsMarkdown.test.mjs tests/fixtures/sample-clubs.md
git commit -m "feat: parse clubs markdown table"
```

---

