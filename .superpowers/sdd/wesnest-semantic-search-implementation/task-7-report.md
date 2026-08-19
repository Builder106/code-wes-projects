# Task 7: Frontend — Report

## Summary

Implemented `index.html`, a build-step-free Alpine.js frontend for WesNest semantic search, backed by a Playwright e2e spec (`tests/frontend.spec.mjs`) and a `playwright.config.mjs` that serves the app statically via `serve` on port 4173.

## TDD evidence

### RED

Wrote `tests/frontend.spec.mjs` exactly as specified in the brief (mocks `POST /api/search` via `page.route`, asserts `[data-testid="result-card"]` count/content after typing into `[data-testid="search-input"]`, and asserts an empty state before any query). At this point neither `index.html` nor `playwright.config.mjs` existed.

Ran:

```
npx playwright test tests/frontend.spec.mjs
```

Result: both tests FAILED, correctly:

```
Error: page.goto: Protocol error (Page.navigate): Cannot navigate to invalid URL
Call log:
  - navigating to "/index.html", waiting until "load"
```

This is the expected failure — no `playwright.config.mjs` / `baseURL` existed yet, so the relative `/index.html` navigation had nowhere to resolve, and no `index.html` file existed to serve anyway.

### SRI hash computation (real, not memorized)

Ran on the VM against the live jsDelivr CDN for the exact pinned version (`alpinejs@3.14.1/dist/cdn.min.js`):

```
curl -s https://cdn.jsdelivr.net/npm/alpinejs@3.14.1/dist/cdn.min.js | openssl dgst -sha384 -binary | openssl base64 -A
```

Output:

```
l8f0VcPi/M1iHPv8egOnY/15TDwqgbOR1anMIJWvU6nLRgZVLTLSaNqi/TOoT5Fh
```

Verified reproducibility by downloading to a local file and re-hashing separately (also confirmed file size 44659 bytes, non-empty/non-error response):

```
curl -s https://cdn.jsdelivr.net/npm/alpinejs@3.14.1/dist/cdn.min.js -o /tmp/alpine.js && wc -c /tmp/alpine.js && openssl dgst -sha384 -binary /tmp/alpine.js | openssl base64 -A
44659 /tmp/alpine.js
l8f0VcPi/M1iHPv8egOnY/15TDwqgbOR1anMIJWvU6nLRgZVLTLSaNqi/TOoT5Fh
```

Same hash both times. Used this value verbatim in `index.html`'s `integrity="sha384-l8f0VcPi/M1iHPv8egOnY/15TDwqgbOR1anMIJWvU6nLRgZVLTLSaNqi/TOoT5Fh"`.

### GREEN

Wrote `index.html` per the brief (Alpine.js `x-data="clubSearch()"`, debounced search input, `POST /api/search`, template loop rendering `.card[data-testid="result-card"]`), `playwright.config.mjs` (webServer running `npx serve . -l 4173`, `baseURL: http://localhost:4173`), and added `serve` as a devDependency (`npm install --save-dev serve`, resolved to `serve@14.2.6`, 85 packages added, 0 vulnerabilities).

Ran:

```
npx playwright test tests/frontend.spec.mjs
```

Result:

```
Running 2 tests using 1 worker

  ✓  1 tests/frontend.spec.mjs:3:1 › renders results after typing a query (1.2s)
  ✓  2 tests/frontend.spec.mjs:22:1 › shows an empty state before any query (275ms)

  2 passed (3.7s)
```

Playwright browsers were already cached on the VM (chromium-1228/1234 present under `~/.cache/ms-playwright`), so no browser install step was needed.

### Regression check (unit tests)

Ran:

```
npm test
```

Result: `16/16` pass, `0` fail — unchanged from before this task, confirming `tests/frontend.spec.mjs` (a `.spec.mjs` file, not `.test.mjs`) is correctly excluded from the `node --test` glob and doesn't interfere with the existing unit suite.

## Files changed

- `apps/wesnest-semantic-search/index.html` (new)
- `apps/wesnest-semantic-search/playwright.config.mjs` (new)
- `apps/wesnest-semantic-search/tests/frontend.spec.mjs` (new)
- `apps/wesnest-semantic-search/package.json` (added `serve` devDependency)
- `apps/wesnest-semantic-search/package-lock.json` (lockfile update for `serve` and its transitive deps)

## Commit

`7bedb8e` — `feat: add search frontend`, on branch `wesnest-semantic-search`, not pushed.

## Self-review

- Diff matches the brief's Step 1/4/5/7 content exactly, with the one required substitution: the real computed SRI hash in place of the brief's placeholder.
- `index.html` uses `data-testid="search-input"` and `data-testid="result-card"` exactly as the test expects; `x-model`/`@input.debounce.400ms` wiring matches Alpine.js 3.x syntax.
- Fetch error handling: if `/api/search` returns non-2xx, `response.json()` would still be attempted and could throw inside the Alpine method — this matches the brief's minimal implementation exactly (no try/catch was specified), so I did not add extra scope. Flagging as a possible follow-up for a later hardening task, not fixed here since it's out of this task's brief.
- `playwright.config.mjs`'s `reuseExistingServer: true` means a stale `serve` process on port 4173 from a prior run would be reused rather than restarted — acceptable for this static, no-build app since `index.html` is served straight from disk with no build step to go stale.
- `package.json`'s existing `test:e2e` script already references `tests/scrapeClubs.spec.mjs`, which does not exist yet (belongs to a later task per the parent instructions) — did not create or touch it, and did not run `npm run test:e2e` for that reason; ran `npx playwright test tests/frontend.spec.mjs` directly instead, per the brief's own Step 2/Step 6 commands.

## Concerns

None blocking. Only note above about the unhandled non-2xx fetch response case, which was intentionally left as-is to match the brief precisely.
