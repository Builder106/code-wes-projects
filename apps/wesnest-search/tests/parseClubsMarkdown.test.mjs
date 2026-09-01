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

test('ignores non-table lines, headers, separators, and malformed rows', () => {
  const markdown = `
# Title
Some intro text
| Not enough cells |
| Name | Categories | Summary |
| --- | --- | --- |
| Valid Club | Category | Great description |
`;
  const orgs = parseClubsMarkdown(markdown);
  assert.equal(orgs.length, 1);
  assert.equal(orgs[0].name, 'Valid Club');
});
