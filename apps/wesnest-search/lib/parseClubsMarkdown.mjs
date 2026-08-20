export function parseClubsMarkdown(markdown) {
  const orgs = [];
  const lines = markdown.split('\n');
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed.startsWith('|')) continue;
    const cells = trimmed
      .slice(1, -1)
      .split('|')
      .map((cell) => cell.trim());
    if (cells.length !== 3) continue;
    const [name, categories, summary] = cells;
    if (name === 'Name' || /^-+$/.test(name)) continue;
    orgs.push({ name, categories, summary });
  }
  return orgs;
}
