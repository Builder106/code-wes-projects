// api/search.js
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { cosineSimilarity } from '../lib/similarity.mjs';
import { embedText } from '../lib/geminiEmbed.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ORGS_PATH = path.join(__dirname, '..', 'data', 'orgs-embeddings.json');

function keywordScore(query, org) {
  const q = query.toLowerCase();
  const haystack = `${org.name} ${org.categories} ${org.summary}`.toLowerCase();
  return haystack.includes(q) ? 1 : 0;
}

export async function rankOrgs(query, orgs, apiKey, opts = {}) {
  const embedImpl = opts.embedImpl ?? embedText;
  const limit = opts.limit ?? 15;

  let scored;
  try {
    const queryEmbedding = await embedImpl(query, apiKey, undefined, 'RETRIEVAL_QUERY');
    scored = orgs.map((org) => ({
      ...org,
      score: cosineSimilarity(queryEmbedding, org.embedding),
    }));
  } catch {
    scored = orgs.map((org) => ({ ...org, score: keywordScore(query, org) }));
  }

  return scored
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map(({ embedding, ...rest }) => rest);
}

let cachedOrgs;
function loadOrgs() {
  if (!cachedOrgs) {
    cachedOrgs = JSON.parse(readFileSync(ORGS_PATH, 'utf8'));
  }
  return cachedOrgs;
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }
  const { query } = req.body ?? {};
  if (!query || typeof query !== 'string') {
    res.status(400).json({ error: 'query is required' });
    return;
  }
  const apiKey = process.env.GEMINI_API_KEY;
  const results = await rankOrgs(query, loadOrgs(), apiKey);
  res.status(200).json({ results });
}
