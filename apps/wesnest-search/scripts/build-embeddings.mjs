import { readFileSync, writeFileSync } from 'node:fs';
import { parseClubsMarkdown } from '../lib/parseClubsMarkdown.mjs';
import { embedText } from '../lib/geminiEmbed.mjs';

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function embedWithRetry(text, apiKey, embedImpl, taskType, maxAttempts = 6) {
  let attempt = 0;
  let lastError;
  while (attempt < maxAttempts) {
    try {
      return await embedImpl(text, apiKey, undefined, taskType);
    } catch (error) {
      lastError = error;
      const isRateLimited = /\b(429|5\d\d)\b/.test(error.message ?? '');
      if (!isRateLimited) {
        throw error;
      }
      attempt += 1;
      const backoffMs = Math.min(30000, 1000 * 2 ** attempt);
      await sleep(backoffMs);
    }
  }
  throw lastError;
}

export async function buildEmbeddings(markdown, apiKey, embedImpl = embedText) {
  const orgs = parseClubsMarkdown(markdown);
  const results = [];
  for (const org of orgs) {
    const text = `${org.name}. ${org.categories}. ${org.summary}`;
    const embedding = await embedWithRetry(text, apiKey, embedImpl, 'RETRIEVAL_DOCUMENT');
    results.push({ ...org, embedding });
    if (embedImpl === embedText) {
      await sleep(300);
    }
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
