// tests/search.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { rankOrgs } from '../api/search.js';

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
});

test('returns at most the requested limit', async () => {
  const fakeEmbed = async () => [1, 1, 1];
  const results = await rankOrgs('anything', orgs, 'fake-key', { embedImpl: fakeEmbed, limit: 2 });
  assert.equal(results.length, 2);
});
