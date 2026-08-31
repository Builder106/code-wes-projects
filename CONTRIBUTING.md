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

Use short-lived `feature/*` branches for changes. Merge tested work into the
matching production branch for the application being released.

Each application uses its matching branch as its Vercel Production Branch.
Automatic Git deployments are limited to those production branches; `main`,
feature branches, and Dependabot branches remain outside that deployment path.
The production deploy wrapper refuses to deploy an application from a
different branch. See the personal
`CS/projects/personal/monorepo-playbook.md` for the reusable branch model.

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

If you need to test or build the `proposal-email/` (React Email template):

```bash
cd proposal-email
npm install
npm run build
```

## Commit Convention

Write commits in the imperative mood (e.g., `Add architecture plan for Portal 2 bridge`, not `Added...`).
