# Code-Wes Engineering Hub

> **Project pitches, architecture specs, and prototypes for Wesleyan University's coding club.**

## 💡 What is Code-Wes?

Code-Wes is the student-run Computer Science organization at Wesleyan University where student developers collaborate on ambitious software and systems engineering projects.

This repository is the canonical home for the club's project plans, application prototypes, and related engineering notes. It keeps projects together while they are being developed and makes their history easy to follow.

JavaScript and TypeScript packages in this hub use the root pnpm workspace (`apps/wesnest-search` and `proposal-email`). Node 24 is the preferred release runtime, with the package engine range also covering the repository's current Node 26 verification environment. WesNest Search is a deployable web application, and Proposal Email is a shared React Email package.

Piano Tool and Comment Lens have been graduated and moved out into their own dedicated repositories ([`Builder106/piano-tool`](https://github.com/Builder106/piano-tool) and [`Builder106/comment-lens`](https://github.com/Builder106/comment-lens)).

## Featured Initiatives

### 1. [Portal 2 Web Bridge](https://github.com/Code-Wes/portal-web-bridge)

Turn a running copy of the video game *Portal 2* into an interactive, crowd-controlled web experiment. Using game network sockets, a fast web server, and a responsive frontend, multiple remote players can queue actions and guide players through test chambers in real time.

- Architecture and Milestones: [portal2-migration.md](./docs/specs/portal2-migration.md)
- Original Project Pitch: [proposal-email/](./proposal-email/)

### 2. [WesNest Search](apps/wesnest-search/)

A free-text, meaning-based search tool over Wesleyan University's WesNest club directory, built because WesNest's own search only matches exact words in a club's name.

- **Semantic Ranking:** Embeds each club's name, categories, and summary with the Gemini API and ranks results by similarity to a natural-language query, with a keyword-match fallback if the embedding call fails.
- **Goal:** Help Wesleyan students find clubs by what they're looking for, not just what a club happens to be named, and serve as a reference project for Gemini embeddings in a serverless deployment.

### 3. [Piano Tool (Graduated)](https://github.com/Builder106/piano-tool)

An on-device interactive piano coach and sheet music visualizer built for student musicians in campus practice rooms. Graduated from this hub to its own canonical standalone repository.

### 4. [Comment Lens (Graduated)](https://github.com/Builder106/comment-lens)

A private review dashboard that inventories repository comments and ranks potentially verbose or boilerplate wording for human review. Graduated from this hub to its own canonical standalone repository.

`main` is the canonical repository branch and the production source for the WesNest Search Vercel project (`apps/wesnest-search/`). Feature branches use CI and review before merging to `main`.

Configure environment variables, GitHub App settings, database access, worker secrets, and Vercel project settings in their respective dashboards. Those platform settings are not reproduced by the repository files.

---

## License

MIT License. See [LICENSE](./LICENSE).
