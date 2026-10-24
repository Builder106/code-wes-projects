# Code-Wes-Projects Roadmap

Wesleyan student computing club project directory and showcase roadmap.

## Repository direction

`code-wes-projects` is the canonical repository for these projects. New work
belongs under the appropriate directory here rather than in a standalone
repository. The standalone local Piano Tool checkout is deprecated and is
being kept temporarily while its remaining useful changes are reconciled with
`apps/piano-tool/`; it is not a second source of truth.

## v1.1 — Organization & Portal Migration

- **Comment Lens**: Private dashboard for reviewing repository comment style. Production completion includes GitHub App authorization, signed Actions ingestion, managed Postgres migrations, on-demand Gemini assessment, and Linux ARM64 CI verification.
- **Portal 2.0 Redesign**: Modern responsive project portal per [`docs/specs/portal2-migration.md`](docs/specs/portal2-migration.md).
- **Organization Structure Update**: Finalize repository namespace rename per [`docs/specs/org-rename-plan.md`](docs/specs/org-rename-plan.md).

## v1.2 — WesNest Semantic Search Production Delivery

Led by the **Code_Wes** student engineering team:

- **Data Pipeline & URL Resolution**: Enhance scraper to extract direct WesNest club profile links (`/engage/organization/<slug>`) and preserve categories across table parsing and precomputed embeddings.
- **Search API Filtering & Pagination**: Add optional category filters, pagination bounds (`limit`/`offset`), and relevance thresholds in `api/search.js`.
- **Frontend UI/UX & Wesleyan Design System**: Elevate `apps/wesnest-search/index.html` to an accessible, responsive Alpine.js interface with Wesleyan Cardinal Red palette, loading skeletons, query suggestions, and direct club links.
- **E2E & Responsive Test Coverage**: Expand Playwright test suites covering debouncing, cancellation, mobile viewports, and keyword-fallback degradation.
- **Campus Launch & Feedback**: Establish student feedback mechanisms and production deployment on Vercel.

## v1.3 — Project Showcase & Submissions

- **Student Submission Workflow**: Automated PR validation and metadata extraction for new student projects.
- **Active Project Health Badges**: Dynamic uptime and maintenance status tracking for hosted student demos.

## Out of Scope

- Closed student membership gating
- Commercial advertising

---
For technical specifications, see [`docs/specs/`](docs/specs/).
