import { expect, test } from '@playwright/test';

const viewports = [
  { name: 'mobile', width: 375, height: 812 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1440, height: 900 },
];

for (const viewport of viewports) {
  test(`${viewport.name} layout has no horizontal overflow`, async ({ page }) => {
    await page.setViewportSize(viewport);
    await page.goto('/index.html');
    await expect(page.locator('[data-testid="search-input"]')).toBeVisible();
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth + 1)).toBe(true);
  });
}
