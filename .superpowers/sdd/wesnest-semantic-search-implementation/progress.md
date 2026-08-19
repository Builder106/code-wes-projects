# SDD ledger — plan: docs/plans/wesnest-semantic-search-implementation.md

Restarted 2026-08-19. Prior session's ledger (same workspace, on the Mac)
recorded a pre-flight scan and a monorepo ruling but no completed tasks and
no artifacts existed anywhere (Mac `apps/` only has `piano-tool`; ampere-dev
had no checkout at all). Treating this as a clean restart of Task 1;
carrying forward the two rulings below since they still hold.

## Pre-flight Conflict Scan (carried forward, verified still applicable)

Full task-interface consistency table from the prior session's scan applies
unchanged — the plan file has not been edited since. Summary: no
task-to-task interface conflicts, no self-contradictions within a task, one
documented risk (Task 8's scraper DOM selectors are assumptions about
WesNest's real markup; categories will be empty after a rescrape — already
noted in the plan). No contradictions with Global Constraints found beyond
the repo-location point ruled on below.

## Rulings

**Ruling: Repo location** — Global Constraints says the repo lives at
`github.com/Code-Wes/wesnest-semantic-search`, an org repo the user does not
belong to. Per the user's global git-safety rules, all `gh repo create`
writes against a repo the user doesn't own require confirmation, and the
user is not a member of Code-Wes. Building instead as `apps/wesnest-semantic-search/`
inside the user's own `Builder106/code-wes-projects` monorepo, following the
`apps/piano-tool` precedent already in that repo. Consequences: no
`gh repo create` needed (Task 1 Steps 1-2 skipped); `vercel.json`'s
function path and Task 9's `vercel link`/deploy target the subdirectory;
all work still happens on ampere-dev per the Mac's zero-tolerance VM rule.
Cost if wrong: would need to extract to a standalone repo later — low cost,
git history preserved either way.

**Ruling: Branch, not fresh clone per task** — Working on branch
`wesnest-semantic-search` off `main` in a single ampere-dev checkout at
`~/code-wes-projects`, cloned fresh this session (`git clone
https://github.com/Builder106/code-wes-projects.git`). Consistent with
piano-tool's subtree precedent of living inside this monorepo.

---

## Execution Log

**Ruling: Node runtime = 26, not system default** — ampere-dev's plain SSH
commands default to system Node 20.20.2 (/usr/bin/node); the intended
runtime is nvm's Node 26.7.0 (nvm default on this box). Every ssh command
that runs node/npm for this project must source nvm first:
`source ~/.nvm/nvm.sh && ...`. Discovered mid-Task-1: Node 26's built-in
test runner throws MODULE_NOT_FOUND on a bare directory path with no
matching files (`node --test tests/`), where Node 20 quietly reports 0
tests. Fixed in package.json's `test` script by using an explicit glob
(`'tests/**/*.test.mjs'`) instead of the plan's literal `tests/` path —
works cleanly on Node 26, verified 0 tests / exit 0. This glob convention
carries forward: later tasks' test files must live at
`tests/*.test.mjs` for the script to discover them (Playwright specs use
`.spec.mjs` and are invoked separately via `test:e2e`, unaffected).

Task 1: complete (commits be2b05d..d9ffc95, review clean)

Resolved reviewer's ⚠️ item myself (controller has full plan text): every
unit-test task (2-6 in the plan) names its file tests/*.test.mjs
(similarity.test.mjs, parseClubsMarkdown.test.mjs, geminiEmbed.test.mjs,
buildEmbeddings.test.mjs, search.test.mjs); Playwright specs use .spec.mjs
and run via the separate test:e2e script. Task 1's glob convention
matches the plan exactly — no gap, no ruling needed.
Task 2: complete (commits d9ffc95..edf7c8b, review clean)
Task 3: complete (commits edf7c8b..f1deb11, review clean)
Task 4: complete (commits f1deb11..984853f, review clean)
Task 5: complete (commits 984853f..d22f4c7, review clean)

**Ruling: Task 6 keyword-fallback finding — plan-mandated, not a defect** —
reviewer found the keyword fallback (single contiguous-substring match) fails
on multi-word queries whose words don't appear contiguously (e.g. "career
coding"). Real limitation, but the implementation is verbatim what the
plan's Task 6 Step 4 specifies (`keywordScore`'s substring-match approach),
and the brief's own tests only probe single-substring queries. The keyword
path is a fallback for embedding-API failure only — the primary semantic-
search path (Task 6's embedding branch) doesn't have this weakness. Ruling:
accept as-is per the plan; not reopening Task 6. Recorded here as a
fast-follow candidate (switch keywordScore to per-token OR-matching) for
after this plan ships, not part of this plan's scope. Cost if wrong: a
degraded (not broken) fallback experience only during Gemini API outages —
low severity, narrow blast radius.

Task 6: complete (commits d22f4c7..4eb3dfe, 1 parked: keyword-fallback
multi-word limitation, plan-mandated, ruled acceptable)

**Process note (not a code defect):** Task 7's implementer subagent
violated its no-subagents instruction mid-task, dispatching its own
background delegate to do part of the work. It self-caught this, stopped
delegating, and independently re-verified every artifact (SRI hash,
tests) before reporting. The controller separately spot-checked
(clean tree, 16/16 tests), and Task 7's reviewer independently
re-verified again (own SRI hash computation, own Playwright run) — three
independent confirmations, all matching. Final artifact is correct.
Tightened later dispatch prompts with a more explicit prohibition as a
result; watching for recurrence in Tasks 8-9.

Task 7: complete (commits 4eb3dfe..7bedb8e, review clean, 1 process note)

**Watch item for Task 9 (not a defect, pre-existing Task 3 format
constraint):** parseClubsMarkdown/toMarkdownTable have no escaping for a
literal `|` character inside a name/categories/summary field. Low risk,
but Task 9 runs against the real 271-org wesleyan_clubs.md — if any org
name or summary happens to contain a pipe character, the existing
hand-curated data (not this task's scraper output) could already have
this problem. Worth a quick grep for literal `|` in data/wesleyan_clubs.md
before/during Task 9, not a blocker.

Task 8: complete (commits 7bedb8e..fce5d3e, review clean)

**Ruling: text-embedding-004 retired, switch pinned model** — during Task 9's
real embeddings run, the implementer hit a real HTTP 404 from the live
Gemini API: text-embedding-004 has been retired since this plan was
written. ListModels on the live key shows gemini-embedding-001,
gemini-embedding-2-preview, and gemini-embedding-2 as the current
embedding-capable models. Ruling: pin to gemini-embedding-001 (the
non-preview, GA-named model, matching the spirit of the original
Global-Constraint pin to a stable non-preview model) as primary; if
gemini-embedding-001 also 404s/errors when actually tried, fall back to
gemini-embedding-2 (implementer already confirmed via curl this one
returns a valid embedding.values array in the same response shape the
existing code parses — no code-shape change needed, only the model name
in the ENDPOINT constant). This reopens Task 4's lib/geminiEmbed.mjs
(where ENDPOINT is defined) and its test's URL assertion
(tests/geminiEmbed.test.mjs) — both need the endpoint constant/assertion
updated together, as one small fix commit, before Task 9's real run
proceeds. The implementer's rate-limit fix (retry/backoff + 300ms
throttle in scripts/build-embeddings.mjs, added after hitting a real 429)
is accepted as a necessary implementation detail for Task 9's real run,
not a Global Constraint violation — kept in the fix. Cost if wrong: would
need to re-swap the model name again later; low cost, single constant.

Task 9 (embeddings half — Steps 1, 2, partial 5): complete (commits
fce5d3e..75a1eec, review clean, relevance bar met — Wesleyan Debate
Society rank 3/267 for the test query, independently re-verified by
controller and reviewer separately). Deploy (Step 3), e2e-against-deployed
(Step 4), and push remain, gated on explicit user confirmation per the
Mac's global outward-facing-action rule.

**Ruling: invalid vercel.json Function Runtime string** — first real deploy
attempt failed with "Error: Function Runtimes must have a valid version,
for example now-php@1.0.0." The plan's Task 1 Step 4 vercel.json
(`{"functions":{"api/search.js":{"runtime":"nodejs20.x"}}}`) uses a
runtime-version string format the current Vercel platform rejects — a
genuine plan defect that could only surface at real deploy time, not
during any earlier task's unit/e2e review. Ruling: remove the functions
override entirely (vercel.json -> {}); Vercel auto-detects the Node.js
runtime for a plain .js serverless function without an explicit override.
Cost if wrong: would need a different vercel.json shape; low cost, single
small file.

**Ruling: relative-path readFileSync fails in Vercel Lambda runtime** —
after the vercel.json fix, the live deployment's /api/search crashed with
ENOENT reading 'data/orgs-embeddings.json'. Root cause: api/search.js's
loadOrgs() (verbatim from the plan's Task 6 code) used a bare relative
path in readFileSync, which resolves against process.cwd() — correct
locally where cwd is the app directory, but Vercel's Lambda runtime does
not guarantee that cwd. Another genuine plan defect surfacing only in the
real deployed environment, not catchable by any earlier unit/e2e review
(unit tests exercise rankOrgs directly with injected orgs, never
loadOrgs()/the default handler). Ruling: resolve the path via
fileURLToPath(import.meta.url) + path.join relative to the module's own
directory, immune to cwd. Re-ran full npm test (18/18 still pass, this
path is untouched by any existing test) before committing. Cost if wrong:
single function, easily re-fixed; low cost.

Deploy verified live and working end-to-end at
https://wesnest-semantic-search-on3lmj048-sankofa-forge.vercel.app —
index.html serves (200), /api/search returns correct real-time ranked
results (Wesleyan Debate Society rank 3, matching local relevance check
exactly). Two plan-defect fixes were required to get here (vercel.json
runtime string, api/search.js relative-path readFileSync), both ruled and
committed above. GEMINI_API_KEY set on Vercel Production + Preview via
CLI (values never displayed). Vercel project: sankofa-forge/wesnest-semantic-search,
git-linked to Builder106/code-wes-projects, rootDirectory
apps/wesnest-semantic-search.

Task 9 (deploy half — Steps 3, 4, remainder of 5): complete. Vercel
project created (git-linked, rootDirectory apps/wesnest-semantic-search),
GEMINI_API_KEY set on Production+Preview, two real deploy-time defects
found and fixed (vercel.json runtime string, search.js relative path —
both ruled above), live deployment verified working end-to-end (real
/api/search returns correct semantic ranking, Playwright e2e 2/2 passes
against the live URL), README updated with deploy note. Branch pushed
(commits through 6a4643e), NOT merged to main — that decision was not
part of what the user approved (deploy + push only).

ALL 9 TASKS COMPLETE.
