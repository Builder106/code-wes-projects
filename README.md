# Code-Wes Engineering Hub

> **Project pitches, architecture specs, and prototypes for Wesleyan University's coding club.**

## 💡 What is Code-Wes?

Code-Wes is the student-run Computer Science organization at Wesleyan University where student developers collaborate on ambitious software and systems engineering projects.

This repository is the canonical home for the club's project plans, application prototypes, and related engineering notes. It keeps projects together while they are being developed and makes their history easy to follow.

JavaScript and TypeScript projects use the root pnpm workspace and lockfile. Node 24 is the preferred release runtime, with the package engine range also covering the repository's current Node 26 verification environment. Piano Tool is a Flutter application with separate Python, Android, and Apple-platform projects, so it is intentionally outside that workspace. Proposal Email is a React Email package in the workspace, while Comment Lens and WesNest Search are deployable web applications.

The standalone local Piano Tool checkout is deprecated. It is retained temporarily for reconciliation and will not be published as a separate repository.

## Featured Initiatives

### 1. [Portal 2 Web Bridge](https://github.com/Code-Wes/portal-web-bridge)

Turn a running copy of the video game *Portal 2* into an interactive, crowd-controlled web experiment. Using game network sockets, a fast web server, and a responsive frontend, multiple remote players can queue actions and guide players through test chambers in real time.

- Architecture and Milestones: [portal2-migration.md](./docs/specs/portal2-migration.md)
- Original Project Pitch: [proposal-email/](./proposal-email/)

### 2. [Piano Tool — Interactive Practice Tutor](apps/piano-tool/)

An on-device interactive piano coach and sheet music visualizer built for student musicians in campus practice rooms.

- **Real-Time DSP:** Listens to acoustic or digital pianos via device microphone using a low-latency YIN pitch detection engine.
- **Custom Staff Engine:** Vector-accurate sheet music scrolling and scoring designed with SMuFL notation standards and accessible contrast geometry.
- **Goal:** Provide an open-source, offline ear-and-sight tutor for Wesleyan student musicians and a reference project for real-time audio systems in Flutter.

### 3. [WesNest Search](apps/wesnest-search/)

A free-text, meaning-based search tool over Wesleyan University's WesNest club directory, built because WesNest's own search only matches exact words in a club's name.

- **Semantic Ranking:** Embeds each club's name, categories, and summary with the Gemini API and ranks results by similarity to a natural-language query, with a keyword-match fallback if the embedding call fails.
- **Goal:** Help Wesleyan students find clubs by what they're looking for, not just what a club happens to be named, and serve as a reference project for Gemini embeddings in a serverless deployment.

### 4. [Comment Lens](apps/comment-lens/)

A private review dashboard that inventories repository comments and ranks potentially verbose or boilerplate wording for human review. It stores decisions without modifying source files; hosted scanning and Gemini assessment require separately configured services.

Comment Lens requires a managed Postgres `DATABASE_URL`, `SESSION_SECRET`, `ALLOWED_GITHUB_USER_ID`, GitHub App credentials (`GITHUB_APP_ID`, `GITHUB_APP_CLIENT_ID`, `GITHUB_APP_CLIENT_SECRET`, and `GITHUB_APP_PRIVATE_KEY`), `WORKER_INGEST_SECRET`, and `GEMINI_API_KEY`. `GEMINI_MODEL` is optional and defaults to `gemini-3.5-flash-lite`. Run the committed Drizzle migrations before first use. The GitHub App must be installed only on the selected repositories and the central worker repository; configure the matching worker upload URL and signing secret as Actions variables and secrets. Do not commit credentials or scan artifacts.

`main` is the canonical repository branch and the production source for the Vercel projects. Each Vercel project uses its application directory as its Root Directory: `apps/comment-lens/`, `apps/piano-tool/`, or `apps/wesnest-search/`. There is no shared `staging` branch. Feature branches use CI and review before merging to `main`.

Configure environment variables, GitHub App settings, database access, worker secrets, and Vercel project settings in their respective dashboards. Those platform settings are not reproduced by the repository files.

---

## License

MIT License. See [LICENSE](./LICENSE).
