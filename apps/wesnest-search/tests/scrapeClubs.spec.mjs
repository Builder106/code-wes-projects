// tests/scrapeClubs.spec.mjs
import { test, expect } from '@playwright/test';
import { extractOrgsFromPage, toMarkdownTable } from '../scripts/scrape-clubs.mjs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const fixturePath = path.join(path.dirname(fileURLToPath(import.meta.url)), 'fixtures', 'wesnest-orgs-fixture.html');

test('extracts org name and summary from the fixture page', async ({ page }) => {
  await page.goto(`file://${fixturePath}`);
  const orgs = await extractOrgsFromPage(page);
  expect(orgs).toHaveLength(2);
  expect(orgs[0]).toEqual({ name: 'Code_Wes', categories: '', summary: "Club for students interested in coding. We're working on real-life group projects." });
});

test('renders extracted orgs as a markdown table matching the parser format', () => {
  const table = toMarkdownTable([
    { name: 'Code_Wes', categories: '', summary: 'Club for students interested in coding.' },
  ]);
  expect(table).toContain('| Name | Categories | Summary |');
  expect(table).toContain('| Code_Wes |  | Club for students interested in coding. |');
});
