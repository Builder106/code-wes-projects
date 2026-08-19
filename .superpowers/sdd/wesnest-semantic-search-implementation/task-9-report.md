# Task 9 Report (Steps 1, 2, and the embeddings-commit part of Step 5)

**UPDATE:** the relevance failure documented below in "Step 2" and
"Concerns for the coordinator" was investigated further at the
coordinator's direction and root-caused. See "Root cause investigation
and fix" below — it supersedes the original "Concerns" section. Final
state: Wesleyan Debate Society ranks #3 in the top 5 for the test query,
against the corrected, regenerated 267-entry embeddings file.

## Scope

Did NOT do: Step 3 (vercel deploy), Step 4 (e2e against deployed URL), or
the git push part of Step 5. All work stayed on the wesnest-semantic-search
branch, on ampere-dev, nothing pushed to any remote.

## Plan defect found and fixed (logged, coordinator-approved)

`npm run build-embeddings` initially failed with HTTP 404:
`models/text-embedding-004 is not found for API version v1beta, or is
not supported for embedContent.` Google retired that model.

Verified via `ListModels` that the current embedding-capable models are
gemini-embedding-001, gemini-embedding-2-preview, gemini-embedding-2.
Curl-tested gemini-embedding-001 directly: HTTP 200, valid
`embedding.values` array, same response shape the existing code already
parsed. Coordinator ruled: use gemini-embedding-001 as primary (GA-named,
non-preview, matches the original "pin to a stable model" intent).

Fixed as its own commit (732034b), separate from the embeddings-generation
commit, since `lib/geminiEmbed.mjs` is Task 4 code with an already-approved
review:
- `lib/geminiEmbed.mjs`: ENDPOINT constant now points at
  `gemini-embedding-001:embedContent`.
- `tests/geminiEmbed.test.mjs`: updated the assertion that checked the URL
  contained `text-embedding-004:embedContent` to check for
  `gemini-embedding-001:embedContent` instead.
- `scripts/build-embeddings.mjs`: added retry/backoff (exponential, up to 6
  attempts, capped at 30s) wrapping `embedText` for 429/5xx responses, plus
  a 300ms throttle between real (non-test) calls. The first real run at full
  speed hit a 429 partway through 271 sequential calls; this fix was needed
  to complete the run at all. Kept out of `geminiEmbed.mjs` itself so the
  existing unit test (which expects an immediate throw on a non-2xx
  response) still passes unmodified.
- Ran `npm test`: all 16 unit tests pass (was 16/16 before, still 16/16
  after — no test count change, just the one assertion updated).

## Step 1: Generate embeddings for the real dataset

Ran (ampere-dev, Node v26.7.0, sourced .env.local for GEMINI_API_KEY):
`npm run build-embeddings`

Output: `Wrote 267 org embeddings to data/orgs-embeddings.json`

Note on count: the brief said "271 entries" but the live
`data/wesleyan_clubs.md` has 269 pipe-table rows, minus 1 header + 1
separator row = 267 data rows. 267 is the correct count for the actual
current dataset; the brief's 271 was evidently an earlier estimate that
went stale as the scraped source changed. Verified with `wc -l` and
`grep -c`.

Validated the output structurally (python3, not committed as a script):
- 267 entries.
- Every entry has keys: name, categories, summary, embedding.
- Every embedding has length 3072 (gemini-embedding-001 default output
  dimensionality) and is non-empty.
- ~75 entries have an empty `categories` string. Inspected all of them:
  they're all real Wesleyan departments/offices (Athletics, Registrar,
  Payroll, Financial Aid, etc.), not clubs — the source markdown simply
  has no category tag for those rows. This is the exact case the existing
  test "handles an empty categories column" already covers. Not a bug.

## Step 2: Manual relevance check

One-off script at `/tmp/verify-relevance.mjs` on ampere-dev (deleted after
use, never committed). Called `rankOrgs("something with public speaking",
orgs, apiKey, { limit: 5 })` against the real generated
`data/orgs-embeddings.json`.

**Top 5 result:**
1. The Presentation Studio (0.5849)
2. President's Office (0.5796)
3. Alumni and Parent Relations (0.5733)
4. Society of Physics Students (0.5721)
5. Weightlifting and Fitness Awareness Club (0.5703)

**Neither Wesleyan Debate Society nor Wesleyan Mock Trial appear in the top
5.** Re-ran with limit=267 to find their actual rank:
- Wesleyan Debate Society: rank 17 (score 0.5547)
- Wesleyan Mock Trial: rank 66 (score 0.5226)

This is a real finding, not fudged. All top-10 scores cluster tightly
(0.55-0.58), and several top-5 results (President's Office, Weightlifting
and Fitness Awareness Club) are not obviously "public speaking" related —
this suggests either the embedding model isn't discriminating well for
this vague query concatenated the way `name. categories. summary.` builds
the input text, or short/generic org summaries (e.g. departments with a
one-line description) are drowning out more specific matches through
score clustering. I did not attempt to fix the ranking algorithm or tune
the query — out of scope for this task, and doing so silently would hide
a real quality issue from the coordinator.

## Root cause investigation and fix (coordinator-directed)

Coordinator's hypothesis: `embedText` sent no `taskType`, so
`gemini-embedding-001` used a generic/symmetric objective instead of one
optimized for asymmetric retrieval (short query vs. longer document).

Investigated empirically, in order:

1. **Does `taskType` exist and get validated?** Curl-tested
   `gemini-embedding-001` with `"taskType": "RETRIEVAL_DOCUMENT"` → HTTP
   200, accepted. Then tested with a garbage value
   `"taskType": "NOT_A_REAL_TASK_TYPE"` → HTTP 400 with
   `"Invalid value at 'task_type' (type.googleapis.com/google.ai.generativelanguage.v1beta.TaskType)"`.
   This confirms the field is real, server-validated, and not silently
   ignored. Also confirmed `RETRIEVAL_QUERY` is accepted (200).

2. **Small-scale test (5 orgs, not the full 267)**: Presentation Studio,
   Weightlifting and Fitness Awareness Club, Wesleyan Debate Society,
   Wesleyan Mock Trial, Wesleyan Democrats — embedded with and without
   `taskType`, query "something with public speaking" scored against
   each.
   - **Without taskType** (current/original behavior): Presentation
     Studio 0.5731, Weightlifting 0.5703, Debate Society 0.5547, Mock
     Trial 0.5226, Democrats 0.5056. Debate Society ranks 3rd of 5.
   - **With RETRIEVAL_QUERY (query) / RETRIEVAL_DOCUMENT (orgs)**:
     Debate Society 0.6491 (now 1st), Presentation Studio 0.6397 (2nd),
     Mock Trial 0.6263 (3rd, up from last), Weightlifting 0.6254,
     Democrats 0.6030.

   Hypothesis confirmed: taskType flips Debate Society to rank 1 and
   pulls Mock Trial from last to 3rd, in the small sample. Re-verified
   this same result through the actual `embedText`/`cosineSimilarity`
   code paths (not just raw curl), to make sure the fix would behave the
   same way once wired into the real code.

Since it confirmed, implemented the fix:

- `lib/geminiEmbed.mjs`: `embedText(text, apiKey, fetchImpl = fetch,
  taskType)` — new optional 4th param, included in the request body only
  when provided (`fetchImpl` stays 3rd for backward compatibility with
  existing test call sites).
- `tests/geminiEmbed.test.mjs`: added two tests — taskType omitted from
  body when not passed, taskType included when passed.
- `scripts/build-embeddings.mjs`: `embedWithRetry` now takes and forwards
  a `taskType` param; `buildEmbeddings` passes `'RETRIEVAL_DOCUMENT'`.
- `api/search.js`: `rankOrgs` passes `'RETRIEVAL_QUERY'` when embedding
  the user's query.
- `npm test`: 18/18 pass (16 original + 2 new).

Committed as `b31e5a4` "fix: use RETRIEVAL_DOCUMENT/RETRIEVAL_QUERY
task_type for asymmetric search" — separate from the data-regeneration
commit, same pattern as the earlier endpoint fix.

## Full-scale re-verification

Regenerated all 267 embeddings with `RETRIEVAL_DOCUMENT` (`npm run
build-embeddings`, same throttle/retry as before). Re-ran the relevance
check against the corrected file:

**Top 5 for "something with public speaking":**
1. TEDxWesleyan (0.6549)
2. The Presentation Studio (0.6542)
3. **Wesleyan Debate Society (0.6491)**
4. Disorientation (0.6436)
5. Awkward Silence (0.6420)

Wesleyan Mock Trial improved from rank 66 to rank 23 (0.6263) — still
outside top 5, but the brief only requires one of the two orgs in the top
5, and that bar is now met. The top 5 itself also reads as genuinely
on-topic now (TEDx, presentation coaching, debate, and two Wesleyan
comedy/spoken-word groups), unlike the pre-fix top 5 which included
President's Office and a weightlifting club.

Committed as `75a1eec` "data: regenerate embeddings with correct
RETRIEVAL_DOCUMENT task_type", superseding the earlier (pre-fix)
`f963406` embeddings commit.

## Step 5 (partial): commit generated embeddings

`git add data/orgs-embeddings.json && git commit` — first as f963406
(pre-fix, now superseded), then again as 75a1eec after the taskType fix
and regeneration. README.md was NOT modified — its existing "Refreshing
the data" section already documents the regenerate-and-redeploy flow
accurately, and adding a "deployed" note before any deploy has actually
happened would be inaccurate. Left it as-is; whoever does the deploy step
can add a note then if warranted.

No `git push` was run. Branch, working tree, and commit log are local to
ampere-dev only.

## Files changed (4 commits, chronological)

1. 732034b "fix: switch to gemini-embedding-001, text-embedding-004
   retired" — lib/geminiEmbed.mjs, tests/geminiEmbed.test.mjs,
   scripts/build-embeddings.mjs
2. f963406 "data: generate embeddings for full club dataset" —
   data/orgs-embeddings.json (267 entries, pre-taskType-fix, superseded)
3. b31e5a4 "fix: use RETRIEVAL_DOCUMENT/RETRIEVAL_QUERY task_type for
   asymmetric search" — lib/geminiEmbed.mjs, tests/geminiEmbed.test.mjs,
   scripts/build-embeddings.mjs, api/search.js
4. 75a1eec "data: regenerate embeddings with correct RETRIEVAL_DOCUMENT
   task_type" — data/orgs-embeddings.json (267 entries, corrected,
   current)

## Self-review

- Did I do only what was asked? Yes, plus two coordinator-directed/
  approved fixes (the retired-model swap, then the taskType root-cause
  fix) — both were genuine blocking defects surfaced during the task,
  not scope creep, and both were ruled on before I acted.
- Did I fudge the relevance check, either time? No — reported the actual
  top 5 and actual ranks both before and after the fix, including that
  Mock Trial still doesn't make top 5 post-fix.
- Did I verify the hypothesis empirically before implementing, as
  instructed? Yes — curl validation of the field's existence, a 5-org
  small-scale test comparing with/without taskType, then re-verification
  through the real code path, before touching build-embeddings.mjs or
  api/search.js.
- Did I leak the API key anywhere? No — only checked SET/UNSET, never
  echoed, catted, or logged .env.local or the key value.
- Did I deploy, push, or touch main? No.
- Clean tree? Yes — four intended commits, no stray local diffs
  (confirmed `git status --short` clean after each commit), no leftover
  /tmp scripts on ampere-dev.

## Concerns for the coordinator

None blocking. One residual note: Wesleyan Mock Trial (rank 23, score
0.6263) still doesn't make the top 5, only Debate Society does. The brief
only requires one of the two, so this satisfies the stated bar, but if a
tighter bar is wanted later, Mock Trial's summary text is fairly short
("An organization that prepares for and participates in mock trials...")
compared to Debate Society's, which may be worth a look if this comes up
again.
