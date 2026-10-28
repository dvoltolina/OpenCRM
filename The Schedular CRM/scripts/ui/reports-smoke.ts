/**
 * Reports & Saved Views Smoke Test (Playwright)
 *
 * Usage:
 *   BASE_URL=http://localhost:5173 CRM_EMAIL=you@example.com CRM_PASSWORD=secret npx tsx scripts/ui/reports-smoke.ts
 *
 * What it does:
 * - Logs in via the standard login form
 * - Navigates to /reports
 * - Saves a new report view and verifies it appears in the saved views list
 * - Tries to trigger an aggregated CSV export (skips if the feature flag disables exports)
 *
 * Notes:
 * - Requires a running app at BASE_URL and valid credentials with reporting access.
 * - Headless mode defaults to true; set HEADLESS=false for visual debugging.
 */

import { chromium } from 'playwright-chromium';

const BASE_URL = process.env.BASE_URL || 'http://localhost:5173';
const EMAIL = process.env.CRM_EMAIL;
const PASSWORD = process.env.CRM_PASSWORD;
const HEADLESS = (process.env.HEADLESS ?? 'true').toLowerCase() !== 'false';

if (!EMAIL || !PASSWORD) {
  console.error('CRM_EMAIL and CRM_PASSWORD must be set.');
  process.exit(1);
}

async function main() {
  const browser = await chromium.launch({ headless: HEADLESS });
  const page = await browser.newPage();
  const viewName = `Smoke View ${Date.now()}`;

  try {
    // Login
    await page.goto(`${BASE_URL}/login`);
    await page.fill('#email', EMAIL);
    await page.fill('#password', PASSWORD);
    await Promise.all([
      page.waitForNavigation({ url: '**/dashboard', waitUntil: 'networkidle' }),
      page.getByRole('button', { name: /sign in/i }).click(),
    ]);

    // Navigate to Reports
    await page.goto(`${BASE_URL}/reports`);
    await page.getByRole('heading', { name: /reports/i }).waitFor({ timeout: 10000 });

    // Save a new view
    await page.getByPlaceholder('View name').fill(viewName);
    await page.getByPlaceholder('Share with team IDs (comma separated)').fill('');
    await page.getByRole('button', { name: /save view/i }).click();
    await page.getByRole('button', { name: viewName }).waitFor({ timeout: 10000 });

    // Apply the view to confirm it loads
    await page.getByRole('button', { name: viewName }).click();

    // Attempt export (skip if disabled)
    const exportButton = page.getByRole('button', { name: /Export CSV \(Aggregated\)/i });
    const isDisabled = await exportButton.isDisabled();
    if (!isDisabled) {
      await exportButton.click();
      await page.waitForTimeout(1000); // allow export handler to run
    } else {
      console.log('Export disabled by feature flag; skipping export step.');
    }

    console.log('Reports smoke test completed.');
  } finally {
    await page.close();
    await browser.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
