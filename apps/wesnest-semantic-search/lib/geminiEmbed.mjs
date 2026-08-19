const ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent';

export async function embedText(text, apiKey, fetchImpl = fetch) {
  const response = await fetchImpl(`${ENDPOINT}?key=${apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      content: { parts: [{ text }] },
    }),
  });
  if (!response.ok) {
    throw new Error(`Gemini embedding request failed: ${response.status}`);
  }
  const data = await response.json();
  return data.embedding.values;
}
