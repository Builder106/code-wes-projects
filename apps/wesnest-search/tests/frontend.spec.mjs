import { test, expect } from '@playwright/test';

test('renders results after typing a query', async ({ page }) => {
  await page.route('**/api/search', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        results: [
          { name: 'Code_Wes', categories: 'Academic, Career', summary: 'Club for students interested in coding.', score: 0.9 },
        ],
      }),
    });
  });

  await page.goto('/index.html');
  await page.fill('[data-testid="search-input"]', 'coding');
  await expect(page.locator('[data-testid="result-card"]')).toHaveCount(1);
  await expect(page.locator('[data-testid="result-card"]')).toContainText('Code_Wes');
});

test('shows an empty state before any query', async ({ page }) => {
  await page.goto('/index.html');
  await expect(page.locator('[data-testid="result-card"]')).toHaveCount(0);
});
