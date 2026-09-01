# CONTRIBUTING — Code-Wes Projects Hub

Welcome! This is a personal portfolio repository that acts as an engineering notebook and project hub for the **Code-Wes** Computer Science club at Wesleyan University.

The application source code for these projects lives in this repository, under
`apps/`. This monorepo is the canonical source of truth. The standalone local
Piano Tool checkout is deprecated, is not a publishing target, and should not
be used for new work.

When adding a project, give it a directory under `apps/` (or another existing
top-level category when it is not an application). Keep project-specific
instructions beside the project and update the root documentation when its
name or location changes.

## Branches and deployments

Use short-lived `feature/*` branches for changes. `main` is the canonical
branch and the production branch. There is no shared `staging` branch. Open a
pull request, wait for CI, and merge only after review and all required checks
pass.

Each Vercel project has an app-specific Root Directory: `apps/comment-lens/`,
`apps/piano-tool/`, or `apps/wesnest-search/`. A merge to `main` deploys the
affected project from its configured root. Feature branches are for review and
CI; Dependabot branches do not deploy to production. Keep environment
variables, domains, and other Vercel settings in the dashboard.

## CI gates

The required gates depend on the project. WesNest Search runs syntax and lint
checks plus unit tests with a 100% coverage threshold. Proposal Email runs
type checking. Comment Lens runs TypeScript checks, linting, JavaScript and
scanner coverage gates, integration and security tests, a production build,
and Playwright end-to-end tests. Piano Tool runs Flutter analysis, formatting,
and tests, plus Python Ruff, Black, mypy, and pytest with a 100% coverage
threshold.

Do not merge when a required gate is failing. Run the relevant checks locally
when possible, then rely on CI as the merge gate and on the merge to `main` as
the deployment trigger.

## Package ownership

The root pnpm workspace owns `apps/comment-lens`, `apps/wesnest-search`, and
`proposal-email`, with one root `pnpm-lock.yaml`. Use pnpm from the repository
root for those projects. Piano Tool is intentionally separate from the pnpm
workspace because it owns Flutter, Python, Android, and Apple-platform tooling.

## Comment Lens

Comment Lens uses pnpm for its Next.js control plane and Python 3.12 for its
non-executing scanner. Do not provision hosted services or commit local scan
data; configure GitHub, database, and model credentials only in deployment
environments.

For local configuration, provide `DATABASE_URL`, `SESSION_SECRET` (at least 32
bytes), `ALLOWED_GITHUB_USER_ID`, GitHub App credentials, `WORKER_INGEST_SECRET`,
and `GEMINI_API_KEY`. Apply migrations from
`apps/comment-lens/db/migrations/` with the repository's Drizzle tooling. From
the repository root, the safe migration command is:

```bash
pnpm --filter comment-lens db:migrate
```

This applies the committed migrations using `DATABASE_URL`; it does not
generate or push schema changes. The
worker requires `COMMENT_LENS_GITHUB_APP_ID`,
`COMMENT_LENS_GITHUB_APP_PRIVATE_KEY`, `COMMENT_LENS_INGESTION_SIGNING_SECRET`,
and `COMMENT_LENS_UPLOAD_BASE_URL` in GitHub Actions. Never put repository source
or credentials in logs, URLs, or test snapshots. Run dependency installation,
builds, browser tests, and scanner verification on the designated Linux ARM64
verification environment.

## Proposal Email Setup

If you need to test or build the `proposal-email/` React Email template:

```bash
pnpm --filter proposal-email build
pnpm --filter proposal-email test
```

## Commit Convention

Write commits in the imperative mood (e.g., `Add architecture plan for Portal 2 bridge`, not `Added...`).
