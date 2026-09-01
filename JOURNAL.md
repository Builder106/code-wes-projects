# JOURNAL — Code-Wes Engineering Portfolio

> Dated log of decisions, pitches, and engineering direction for the Code-Wes Computer Science club at Wesleyan University. Reverse-chronological; one paragraph max per entry.

## 2026-08-31: Remove shared staging branch #decision #deployment

Removed the shared `staging` branch and its automatic Vercel deployment rules. The independently deployed applications keep matching production branches, while feature branches use CI and project-specific review before promotion. This avoids unrelated Vercel builds and keeps each project's deployment root and environment boundary explicit.

## 2026-08-31: Comment Lens database baseline #database #drizzle

The Comment Lens production database was empty when checked. The source tree now uses a Drizzle-generated baseline with migration metadata instead of the incomplete hand-written migration set. The app also records `pg` as a development dependency for Node-based migration commands. The baseline was applied successfully using the raw Neon connection string; Vercel's masked environment export cannot be used to validate that connection locally.

## 2026-08-31: Comment Lens task-first dashboard #design #accessibility

Replaced the Comment Lens landing-page treatment with a task-first review workspace. The dashboard now shows one clear action for each connection, access, scan, and failure state, then shifts to a queue with a focused comment detail view. The visual system uses cool paper, graphite, slate, and cobalt tokens with responsive layouts and keyboard and accessibility coverage. The redesign changes no backend, scanner, source-retention, or repository-write behavior.

## 2026-08-30: Comment Lens monorepo integration #architecture #milestone

Added Comment Lens as a private Next.js dashboard with a Python comment scanner, dedicated CI coverage, and a `comment-lens` Vercel production branch. Service provisioning, credentials, and deployment remain separate operational setup.

## 2026-08-30: Comment Lens production boundaries #decision #security

Kept Tree-sitter as the primary parser with Pygments fallback, retained only comments and short source context, and separated deterministic review-priority scoring from optional on-demand Gemini assessment. GitHub App installation tokens, signed worker chunks, owner-scoped persistence, and explicit `comment-lens` plus `staging` deployment rules formed the production boundary at that time; this staging language is superseded by the 2026-08-31 entry above. No repository files are modified by dashboard review actions.

## 2026-08-29: Allow staging previews in app projects #decision [superseded 2026-08-31]

Piano Tool and WesNest Search now accept Git-triggered deployments from `staging` for Preview, while keeping `piano-tool` and `wesnest-search` as their Production Branches. All other branches, including Dependabot branches, remain disabled.

## 2026-08-28: Per-project Vercel branch gates #decision #architecture

Set each Vercel project to deploy only from its matching branch: `piano-tool` for Piano Tool and `wesnest-search` for WesNest Search. The repository disables automatic Git deployments from all other branches, including `main`, `staging`, feature branches, and Dependabot branches. The old WesNest `ignoreCommand` was removed because it created canceled deployment records. `scripts/deploy-vercel.mjs` allows manual production deployment only from the matching branch.

## 2026-08-21 — Canonical monorepo and local Piano Tool deprecation #decision #pivot

Confirmed `code-wes-projects` as the canonical repository for the projects in this hub. The standalone local Piano Tool checkout is deprecated and will remain only until its useful differences have been reconciled with `apps/piano-tool/`; it will not become a separate GitHub repository.

## 2026-08-19 — WesNest Search Monorepo Integration #architecture #milestone

Built WesNest Search under `apps/wesnest-search/` — a Gemini-embeddings-backed free-text search over Wesleyan's WesNest club directory, since WesNest's own search only matches exact words in a club name. It lives in this monorepo rather than a separate repository. Its Vercel deployment uses the app directory as its root and follows the monorepo's canonical path.

## 2026-08-18 — Piano Tool Monorepo Integration #architecture #milestone

Folded the Piano Tool interactive tutor into the repository under `apps/piano-tool/` via `git subtree`. Framed the application as a Code-Wes audio systems initiative and campus practice room aid, giving Wesleyan musicians an accessible ear-and-sight coach while demonstrating real-time YIN pitch detection and SMuFL staff rendering in Flutter.

## 2026-07-17 — Portfolio Hub Pivot #pivot #milestone

Realized that keeping actual application code on my personal profile wasn't scalable since I have two years left at Wesleyan and will be transferring all code to the Code-Wes GitHub organization anyway. Pivoted this repository to be a permanent "Hub" on my profile — a place for pitches, architecture docs, and this journal.

## 2026-06-01 — Portal 2 Bridge Conception #decision #inspiration

Conceived the Portal 2 Web Bridge project after watching a YouTuber hack the Source engine in Portal 2 to function as a working HTTP server using the `-netconport` flag. Decided this would be the perfect semester-long project for the Wesleyan CS Club: taking that proof-of-concept and scaling it with a proper web UI, command queuing, and stream encoding so multiple people can safely control the game over a low-latency connection. Drafted the initial proposal email (`proposal-email/`).
