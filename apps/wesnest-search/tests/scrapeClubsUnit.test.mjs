import { test } from 'node:test';
import assert from 'node:assert/strict';
import { extractOrgsFromPage, toMarkdownTable } from '../scripts/scrape-clubs.mjs';

test('toMarkdownTable formats organizations into markdown table', () => {
  const orgs = [
    { name: 'Code_Wes', categories: 'Tech', summary: 'Coding club' },
    { name: 'Chess Club', categories: '', summary: 'Play chess' },
  ];
  const markdown = toMarkdownTable(orgs);
  assert.ok(markdown.includes('# Wesleyan University Clubs and Organizations'));
  assert.ok(markdown.includes('| Name | Categories | Summary |'));
  assert.ok(markdown.includes('| Code_Wes | Tech | Coding club |'));
  assert.ok(markdown.includes('| Chess Club |  | Play chess |'));
});

test('extractOrgsFromPage extracts org card details from page', async () => {
  const mockPage = {
    $$eval: async (selector, callback) => {
      const mockCards = [
        {
          querySelector: (sel) => {
            if (sel === '.org-name') return { textContent: '  Mock Club  ' };
            if (sel === '.org-summary') return { textContent: '  Mock Summary  ' };
            return null;
          },
        },
      ];
      return callback(mockCards);
    },
  };
  const result = await extractOrgsFromPage(mockPage);
  assert.deepEqual(result, [
    { name: 'Mock Club', categories: '', summary: 'Mock Summary' },
  ]);
});
