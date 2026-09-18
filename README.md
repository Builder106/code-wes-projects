# Code-Wes Engineering Hub

> **Project pitches, architecture specs, and prototypes for Wesleyan University's coding club.**

## 💡 What is Code-Wes?

Code-Wes is the student-run Computer Science organization at Wesleyan University where student developers collaborate on ambitious software and systems engineering projects.

This repository is the canonical home for the club's project plans, application prototypes, and related engineering notes. It keeps projects together while they are being developed and makes their history easy to follow.

JavaScript and TypeScript packages in this hub use the root pnpm workspace (`apps/wesnest-search` and `proposal-email`). Node 24 is the preferred release runtime, with the package engine range also covering the repository's current Node 26 verification environment. WesNest Search is a deployable web application, and Proposal Email is a shared React Email package.

## Featured Initiatives

WesNest Search — In Development

Semantic search for Wesleyan’s WesNest club directory, designed to help students find organizations even when they don’t know the exact club name.

Built with Gemini embeddings and currently being developed as part of Code_Wes.

Configure environment variables, GitHub App settings, database access, worker secrets, and Vercel project settings in their respective dashboards. Those platform settings are not reproduced by the repository files.

---

## License

MIT License. See [LICENSE](./LICENSE).
