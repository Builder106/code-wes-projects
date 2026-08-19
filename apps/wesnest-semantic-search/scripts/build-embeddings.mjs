import { readFileSync, writeFileSync } from 'node:fs';
import { parseClubsMarkdown } from '../lib/parseClubsMarkdown.mjs';
import { embedText } from '../lib/geminiEmbed.mjs';

export async function buildEmbeddings(markdown, apiKey, embedImpl = embedText) {
  const orgs = parseClubsMarkdown(markdown);
  const results = [];
  for (const org of orgs) {
    const text = `${org.name}. ${org.categories}. ${org.summary}`;
    const embedding = await embedImpl(text, apiKey);
    results.push({ ...org, embedding });
  }
  return results;
}

async function main() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error('GEMINI_API_KEY is not set');
    process.exit(1);
  }
  const markdown = readFileSync('data/wesleyan_clubs.md', 'utf8');
  const results = await buildEmbeddings(markdown, apiKey);
  writeFileSync('data/orgs-embeddings.json', JSON.stringify(results, null, 2));
  console.log(`Wrote ${results.length} org embeddings to data/orgs-embeddings.json`);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
