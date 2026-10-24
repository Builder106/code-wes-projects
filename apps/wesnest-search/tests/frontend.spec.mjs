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
  await expect(page.locator('[data-testid="match-score"]')).toContainText('90% match');
  await expect(page.locator('[data-testid="category-chip"]')).toHaveCount(2);

  const orgLink = page.locator('[data-testid="org-link"]');
  await expect(orgLink).toHaveAttribute('href', 'https://wesleyan.campuslabs.com/engage/organization/code-wes');
});

test('shows an empty state before any query', async ({ page }) => {
  await page.goto('/index.html');
  await expect(page.locator('[data-testid="result-card"]')).toHaveCount(0);
  await expect(page.locator('[data-testid="zero-state"]')).toBeVisible();
  await expect(page.locator('[data-testid="suggestion-chip"]')).toHaveCount(6);
});

test('clicking suggestion chip populates search and fetches results', async ({ page }) => {
  await page.route('**/api/search', async (route) => {
    const postData = JSON.parse(route.request().postData());
    expect(postData.query).toBe('Robotics');
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        results: [
          { name: 'Robotics Club', categories: 'STEM, Engineering', summary: 'Building autonomous robots.', score: 0.88 },
        ],
      }),
    });
  });

  await page.goto('/index.html');
  await page.locator('[data-testid="suggestion-chip"]:has-text("Robotics")').click();
  await expect(page.locator('[data-testid="search-input"]')).toHaveValue('Robotics');
  await expect(page.locator('[data-testid="result-card"]')).toHaveCount(1);
  await expect(page.locator('[data-testid="status-announcer"]')).toContainText('Found 1 student organization');
});

test('clear button resets search query and results', async ({ page }) => {
  await page.route('**/api/search', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        results: [
          { name: 'Code_Wes', categories: 'Academic', summary: 'Club for coding.', score: 0.95 },
        ],
      }),
    });
  });

  await page.goto('/index.html');
  await page.fill('[data-testid="search-input"]', 'coding');
  await expect(page.locator('[data-testid="result-card"]')).toHaveCount(1);

  await page.locator('[data-testid="clear-search"]').click();
  await expect(page.locator('[data-testid="search-input"]')).toHaveValue('');
  await expect(page.locator('[data-testid="result-card"]')).toHaveCount(0);
  await expect(page.locator('[data-testid="zero-state"]')).toBeVisible();
});

test('shows empty state when no results return', async ({ page }) => {
  await page.route('**/api/search', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ results: [] }),
    });
  });

  await page.goto('/index.html');
  await page.fill('[data-testid="search-input"]', 'nonexistent club query xyz');
  await expect(page.locator('[data-testid="empty-state"]')).toBeVisible();
  await expect(page.locator('[data-testid="status-announcer"]')).toContainText('Found 0 student organizations');
});
