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

test('retries on rate limit (429/5xx) errors and succeeds', async () => {
  let attempts = 0;
  const retryEmbed = async () => {
    attempts++;
    if (attempts === 1) {
      const err = new Error('429 Too Many Requests');
      throw err;
    }
    return [1, 2, 3];
  };
  const result = await buildEmbeddings(sampleMarkdown, 'fake-key', retryEmbed);
  assert.equal(result.length, 2);
  assert.ok(attempts >= 2);
});

test('rethrows immediately on non-retryable errors', async () => {
  const badEmbed = async () => {
    throw new Error('401 Unauthorized');
  };
  await assert.rejects(
    async () => {
      await buildEmbeddings(sampleMarkdown, 'fake-key', badEmbed);
    },
    { message: '401 Unauthorized' }
  );
});
