// tests/devServer.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createDevApp } from '../scripts/dev-server.mjs';

test('dev server serves index.html and routes /api/search', async (t) => {
  const server = createDevApp();
  await new Promise((resolve) => server.listen(0, resolve));
  const { port } = server.address();
  const baseUrl = `http://localhost:${port}`;

  t.after(() => {
    server.close();
  });

  const staticRes = await fetch(`${baseUrl}/`);
  assert.equal(staticRes.status, 200);
  const html = await staticRes.text();
  assert.ok(html.includes('WesNest Semantic Search'));

  const missingRes = await fetch(`${baseUrl}/nonexistent-fixture-file.missing`);
  assert.equal(missingRes.status, 404);

  const getSearchRes = await fetch(`${baseUrl}/api/search`);
  assert.equal(getSearchRes.status, 405);

  const postSearchRes = await fetch(`${baseUrl}/api/search`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query: 'coding' }),
  });
  assert.equal(postSearchRes.status, 200);
  const data = await postSearchRes.json();
  assert.ok(Array.isArray(data.results));
});
