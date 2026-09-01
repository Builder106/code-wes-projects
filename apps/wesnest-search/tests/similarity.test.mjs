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

test('returns 0 when either vector has zero magnitude', () => {
  assert.equal(cosineSimilarity([0, 0], [1, 1]), 0);
  assert.equal(cosineSimilarity([1, 1], [0, 0]), 0);
});

test('scales correctly for non-unit vectors', () => {
  const result = cosineSimilarity([3, 4], [6, 8]);
  assert.ok(Math.abs(result - 1) < 1e-9);
});
