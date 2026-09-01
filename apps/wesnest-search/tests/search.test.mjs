// tests/search.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import handler, { rankOrgs } from '../api/search.js';

const orgs = JSON.parse(readFileSync(new URL('./fixtures/sample-embeddings.json', import.meta.url), 'utf8'));

test('ranks orgs by similarity to the query embedding', async () => {
  const fakeEmbed = async () => [1, 0, 0];
  const results = await rankOrgs('coding', orgs, 'fake-key', { embedImpl: fakeEmbed });
  assert.equal(results[0].name, 'Code_Wes');
  assert.ok(results[0].score > results[1].score);
});

test('falls back to keyword match when embedding fails', async () => {
  const failingEmbed = async () => { throw new Error('embedding API down'); };
  const results = await rankOrgs('board games', orgs, 'fake-key', { embedImpl: failingEmbed });
  assert.equal(results[0].name, 'Board Games Club');
});

test('keyword fallback matches on name, categories, or summary', async () => {
  const failingEmbed = async () => { throw new Error('embedding API down'); };
  const results = await rankOrgs('hiking', orgs, 'fake-key', { embedImpl: failingEmbed });
  assert.equal(results[0].name, 'Wesleyan Outing Club');

  // Test keyword non-match for keywordScore returning 0
  const noMatchResults = await rankOrgs('nonexistentterm123xyz', orgs, 'fake-key', { embedImpl: failingEmbed });
  assert.ok(noMatchResults.every((r) => r.score === 0));
});

test('returns at most the requested limit', async () => {
  const fakeEmbed = async () => [1, 1, 1];
  const results = await rankOrgs('anything', orgs, 'fake-key', { embedImpl: fakeEmbed, limit: 2 });
  assert.equal(results.length, 2);
});

test('uses default options when none are passed to rankOrgs', async () => {
  const fakeEmbed = async () => [1, 0, 0];
  // Calling rankOrgs without opts object
  const results = await rankOrgs('anything', orgs, 'fake-key');
  assert.ok(Array.isArray(results));
});

test('handler rejects non-POST methods with 405', async () => {
  let statusCode;
  let jsonBody;
  const req = { method: 'GET' };
  const res = {
    status(code) {
      statusCode = code;
      return this;
    },
    json(body) {
      jsonBody = body;
      return this;
    },
  };
  await handler(req, res);
  assert.equal(statusCode, 405);
  assert.deepEqual(jsonBody, { error: 'Method not allowed' });
});

test('handler rejects invalid, missing, or empty body query with 400', async () => {
  let statusCode;
  let jsonBody;
  const res = {
    status(code) {
      statusCode = code;
      return this;
    },
    json(body) {
      jsonBody = body;
      return this;
    },
  };

  // Missing body
  await handler({ method: 'POST' }, res);
  assert.equal(statusCode, 400);
  assert.deepEqual(jsonBody, { error: 'query is required' });

  // Missing query property
  await handler({ method: 'POST', body: {} }, res);
  assert.equal(statusCode, 400);

  // Empty string query
  await handler({ method: 'POST', body: { query: '' } }, res);
  assert.equal(statusCode, 400);

  // Non-string query
  await handler({ method: 'POST', body: { query: 123 } }, res);
  assert.equal(statusCode, 400);
});

test('handler successfully processes search request', async () => {
  let statusCode;
  let jsonBody;
  const req = { method: 'POST', body: { query: 'Code_Wes' } };
  const res = {
    status(code) {
      statusCode = code;
      return this;
    },
    json(body) {
      jsonBody = body;
      return this;
    },
  };
  await handler(req, res);
  assert.equal(statusCode, 200);
  assert.ok(Array.isArray(jsonBody.results));
});
