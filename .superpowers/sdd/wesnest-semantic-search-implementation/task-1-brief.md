## Task 1: Repo scaffold (RULING: monorepo path, not a new Code-Wes repo)

**Controller ruling — read before Steps 3+:** the plan's original Step 1/2
(`gh repo create Code-Wes/wesnest-semantic-search`) do NOT apply. The
controller ruled this project lives inside the user's own monorepo at
`apps/wesnest-semantic-search/` in `Builder106/code-wes-projects`
(precedent: `apps/piano-tool` in the same repo), because the user is not a
member of the `Code-Wes` org and org-repo writes need confirmation the user
hasn't given. You are already on branch `wesnest-semantic-search` in a
checkout at `~/code-wes-projects` on ampere-dev. All file paths below are
relative to `apps/wesnest-semantic-search/` inside that checkout, NOT repo
root — create that directory first (`mkdir -p apps/wesnest-semantic-search`)
and do all work inside it. Skip the plan's Steps 1 and 2 entirely.

**Files (all under `apps/wesnest-semantic-search/`):**
- Create: `package.json`
- Create: `vercel.json`
- Create: `.gitignore`
- Create: `data/wesleyan_clubs.md` (copied from the repo root's `wesleyan_clubs.md`)
- Create: `README.md`

**Interfaces:**
- Produces: an npm project with `npm test` wired to `node --test tests/`, ready for later tasks to add files under `lib/`, `api/`, `scripts/`, `tests/`.

- [ ] **Step 3: Write `package.json`**

```json
{
  "name": "wesnest-semantic-search",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node --test tests/ --test-name-pattern='^(?!.*Playwright)'",
    "test:e2e": "playwright test tests/scrapeClubs.spec.mjs tests/frontend.spec.mjs",
    "build-embeddings": "node scripts/build-embeddings.mjs",
    "scrape-clubs": "node scripts/scrape-clubs.mjs"
  },
  "devDependencies": {
    "@playwright/test": "^1.48.0"
  }
}
```

- [ ] **Step 4: Write `vercel.json`**

```json
{
  "functions": {
    "api/search.js": {
      "runtime": "nodejs20.x"
    }
  }
}
```

- [ ] **Step 5: Write `.gitignore`**

```
node_modules/
test-results/
playwright-report/
.vercel/
```

- [ ] **Step 6: Copy the source data**

The source snapshot already exists in this same checkout, at repo root:
`~/code-wes-projects/wesleyan_clubs.md`. Copy it into
`apps/wesnest-semantic-search/data/wesleyan_clubs.md`:

```bash
mkdir -p apps/wesnest-semantic-search/data
cp ~/code-wes-projects/wesleyan_clubs.md apps/wesnest-semantic-search/data/wesleyan_clubs.md
```

- [ ] **Step 7: Write `README.md`**

```markdown
# WesNest Semantic Search

Free-text, meaning-based search over Wesleyan University's club directory.
WesNest's own search only matches exact words in an org's name; this tool
embeds each org's name, categories, and summary, and ranks results by
similarity to a natural-language query.

## Refreshing the data

```bash
npm run scrape-clubs        # WesNest -> data/wesleyan_clubs.md
npm run build-embeddings    # data/wesleyan_clubs.md -> data/orgs-embeddings.json
```

Commit both files and redeploy.

## Development

Requires `GEMINI_API_KEY` in the environment. Run `npm test` for unit
tests, `npm run test:e2e` for Playwright checks.
```

- [ ] **Step 8: Install dependencies and verify the test command runs**

Run from `apps/wesnest-semantic-search/`: `npm install && npm test`
Expected: passes (no test files yet, `node --test` reports 0 tests, exit code 0).

- [ ] **Step 9: Commit**

Commit on the current branch (`wesnest-semantic-search`) — do NOT push, and
do NOT touch `main`. The controller pushes/merges after the whole-branch
review, per the user's global rule that pushing is confirmed with them
first.

```bash
cd ~/code-wes-projects
git add apps/wesnest-semantic-search/package.json apps/wesnest-semantic-search/vercel.json apps/wesnest-semantic-search/.gitignore apps/wesnest-semantic-search/data/wesleyan_clubs.md apps/wesnest-semantic-search/README.md
git commit -m "chore: scaffold wesnest-semantic-search app"
```

---

