# JOURNAL — Code-Wes Engineering Portfolio

> Dated log of decisions, pitches, and engineering direction for the Code-Wes Computer Science club at Wesleyan University. Reverse-chronological; one paragraph max per entry.

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
