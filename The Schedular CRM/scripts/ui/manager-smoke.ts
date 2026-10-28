/**
 * Manager Surface Smoke Test (Playwright)
 *
 * Usage:
 *   BASE_URL=http://localhost:5173 CRM_EMAIL=manager@example.com CRM_PASSWORD=secret npx tsx scripts/ui/manager-smoke.ts
 *
 * What it does:
 * - Logs in via the standard login form
 * - Navigates to /manager and checks tab presence (Dashboard/Team/Approvals/Reports)
 * - Verifies the dashboard is reachable (table/card surfaces only)
 * - Visits Approvals and Reports tabs to confirm they render without data dependency
 *
 * Notes:
 * - Requires a running app at BASE_URL and credentials with manager/admin access and managed team claims.
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

  try {
    // Login
    await page.goto(`${BASE_URL}/login`);
    await page.fill('#email', EMAIL);
    await page.fill('#password', PASSWORD);
    await Promise.all([
      page.waitForNavigation({ url: '**/dashboard', waitUntil: 'networkidle' }),
      page.getByRole('button', { name: /sign in/i }).click(),
    ]);

    // Navigate to Manager surface
    await page.goto(`${BASE_URL}/manager`);
    await page.getByRole('heading', { name: /manager dashboard/i }).waitFor({ timeout: 10000 });

    // Tabs should exist
    for (const tab of ['Dashboard', 'Team', 'Approvals', 'Reports'] as const) {
      await page.getByRole('button', { name: new RegExp(tab, 'i') }).waitFor({ timeout: 5000 });
    }

    // Dashboard tab: confirm a table/card-only section renders
    await page.getByRole('heading', { name: /pipeline by stage/i }).waitFor({ timeout: 5000 });

    // Approvals tab: ensure it loads even without data
    await page.getByRole('button', { name: /approvals/i }).click();
    await page.getByRole('heading', { name: /approvals/i }).waitFor({ timeout: 5000 });
    await page.getByText(/audit-log driven/i).waitFor({ timeout: 5000 });

    // Reports tab: ensure it renders
    await page.getByRole('button', { name: /reports/i }).click();
    await page.getByRole('heading', { name: /manager reporting/i }).waitFor({ timeout: 5000 });

    console.log('Manager smoke test completed.');
  } finally {
    await page.close();
    await browser.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
