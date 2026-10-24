# Contributing to WesNest Semantic Search

Welcome to the **WesNest Semantic Search** team within Code_Wes! This guide explains our development workflow, engineering standards, and review gates.

---

## 🛠️ Contribution Workflow

1. **Pick an Issue**:
   - Check the [WesNest Search GitHub Milestone / Issues](https://github.com/Builder106/code-wes-projects/issues?q=is%3Aissue+label%3Awesnest-search).
   - Comment on the issue you wish to take on.

2. **Branch Naming**:
   - Create a feature branch off `main`:
     - `feat/wesnest-<feature-name>`
     - `fix/wesnest-<bug-name>`
     - `docs/wesnest-<doc-name>`

3. **Commits**:
   - Use Conventional Commits: `<type>(scope): <imperative subject>` (e.g., `feat(wesnest): add category filter to search API`).
   - Keep commits atomic and focused.

4. **Testing & Quality Gates**:
   - All logic in `lib/` and `api/` must maintain **100% coverage** (branches, lines, and functions).
   - Before opening a PR, ensure all checks pass:
     ```bash
     pnpm --filter wesnest-search test:coverage
     pnpm --filter wesnest-search test:e2e
     ```

5. **Pull Requests**:
   - Open a pull request against `main`.
   - Reference the issue number in the PR description (e.g. `Resolves #XX`).
   - Include screenshot or terminal recording verification for UI/CLI changes.
   - Wait for CI checks to pass.
