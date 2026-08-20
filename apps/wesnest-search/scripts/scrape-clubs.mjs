// scripts/scrape-clubs.mjs
// Note: WesNest's org-listing cards do not expose category tags on the
// listing page itself, only name + summary. `categories` is written empty
// by a rescrape; the current data/wesleyan_clubs.md's categories were
// hand-curated and will need re-curating after a rescrape if kept.
import { chromium } from '@playwright/test';
import { writeFileSync } from 'node:fs';

export async function extractOrgsFromPage(page) {
  return page.$$eval('.org-card', (cards) =>
    cards.map((card) => ({
      name: card.querySelector('.org-name').textContent.trim(),
      categories: '',
      summary: card.querySelector('.org-summary').textContent.trim(),
    }))
  );
}

export function toMarkdownTable(orgs) {
  const header = '| Name | Categories | Summary |\n| --- | --- | --- |';
  const rows = orgs.map((o) => `| ${o.name} | ${o.categories} | ${o.summary} |`);
  return ['# Wesleyan University Clubs and Organizations', '', header, ...rows].join('\n');
}

async function main() {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('https://wesleyan.campuslabs.com/engage/organizations');
  const orgs = await extractOrgsFromPage(page);
  writeFileSync('data/wesleyan_clubs.md', toMarkdownTable(orgs));
  console.log(`Wrote ${orgs.length} orgs to data/wesleyan_clubs.md`);
  await browser.close();
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
