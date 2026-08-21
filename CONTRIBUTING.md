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

## Proposal Email Setup

If you need to test or build the `proposal-email/` (React Email template):

```bash
cd proposal-email
npm install
npm run build
```

## Commit Convention

Write commits in the imperative mood (e.g., `Add architecture plan for Portal 2 bridge`, not `Added...`).
