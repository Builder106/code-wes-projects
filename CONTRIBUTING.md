# CONTRIBUTING — Code-Wes Projects Hub

Welcome! This repository serves as an engineering notebook and project hub for the **Code-Wes** Computer Science club at Wesleyan University.

The application source code for active club initiatives lives in this repository under `apps/` or dedicated workspace packages. This monorepo is the canonical source of truth for ongoing prototypes and initiatives before they graduate.

---

## Branches and deployments

Use short-lived `feat/*`, `fix/*`, or `chore/*` branches for changes. `main` is the canonical branch and the production source for deployed applications. There is no shared `staging` branch. Open a pull request, wait for CI, and merge only after review and all required checks pass.

Each Vercel project has an app-specific Root Directory (such as `apps/wesnest-search/`). A merge to `main` deploys the affected project from its configured root. Feature branches are for review and CI; Dependabot branches do not deploy to production. Keep environment variables, domains, and other Vercel settings in the dashboard.

---

## CI gates

The required gates depend on the project:

- **WesNest Search**: Runs syntax and lint checks (`node --check`), unit tests with a 100% coverage threshold on `lib/**` and `api/**`, and Playwright end-to-end browser tests.
- **Proposal Email**: Runs TypeScript type checking and test rendering.

Do not merge when a required gate is failing. Run the relevant checks locally before opening a pull request, rely on CI as the merge gate, and use merges to `main` as the deployment trigger.

---

## Package ownership

The root pnpm workspace owns `apps/wesnest-search` and `proposal-email`, with a shared `pnpm-lock.yaml`. Use pnpm from the repository root for workspace commands:

```bash
# Run tests across workspace
pnpm test

# Run WesNest Search local dev server
pnpm dev:wesnest

# Run WesNest Search unit tests and coverage gate
pnpm --filter wesnest-search test
pnpm --filter wesnest-search test:coverage
```

*(Note: Comment Lens and Piano Tool have graduated into standalone canonical repositories under `Builder106/comment-lens` and `Builder106/piano-tool`.)*

---

## Proposal Email Setup

If you need to test or build the `proposal-email/` React Email template:

```bash
pnpm --filter proposal-email build
pnpm --filter proposal-email test
```

---

## Commit Convention

Write commits in the imperative mood adhering to Conventional Commits: `<type>(<optional-scope>): <imperative subject>` (e.g., `feat(wesnest): add category filtering to search API`).
