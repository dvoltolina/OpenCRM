#!/usr/bin/env node
/**
 * Mobile layout smoke check using playwright-chromium.
 *
 * Renders representative markup for global search, notifications dropdown,
 * and kanban board at a mobile viewport to validate CSS responsiveness.
 *
 * Usage:
 *   node scripts/ui/mobile-smoke.js
 *
 * Outputs:
 *   - artifacts/mobile-smoke.png (screenshot)
 *   - Console summary with measured widths/heights
 */

import fs from 'fs';
import path from 'path';
import { chromium } from 'playwright-chromium';

const repoRoot = process.cwd();
const artifactsDir = path.join(repoRoot, 'artifacts');
const viewport = { width: 414, height: 896 };

const cssFiles = [
  'src/index.css',
  'src/components/search/search.css',
  'src/components/notifications/notifications.css',
  'src/components/pipeline/pipeline.css',
];

function loadCss() {
  return cssFiles
    .map((relativePath) => {
      const fullPath = path.join(repoRoot, relativePath);
      return fs.readFileSync(fullPath, 'utf-8');
    })
    .join('\n\n');
}

function buildMarkup() {
  // Minimal markup mirroring real component classNames so CSS applies as in-app.
  return `
    <div style="padding:16px; display:flex; flex-direction:column; gap:24px; background:#f8fafc;">
      <section>
        <h3 style="margin-bottom:8px;">Global Search</h3>
        <div class="global-search">
          <div class="global-search__input-wrapper">
            <svg class="global-search__icon" width="20" height="20"></svg>
            <input class="global-search__input" value="demo" />
            <button type="button" class="global-search__clear"><span>×</span></button>
          </div>
          <div class="global-search__dropdown" id="search-results">
            <div class="search-results">
              <div class="search-results__header">
                <span class="search-results__count">4 results</span>
              </div>
              <div class="search-results__group">
                <div class="search-results__group-title"><span class="search-results__group-icon">👤</span>Leads</div>
                <div class="search-results__items">
                  <button class="search-result-item search-result-item--selected">
                    <div class="search-result-item__content">
                      <div class="search-result-item__title">Long Lead Name That Should Truncate Cleanly</div>
                      <div class="search-result-item__subtitle">subtitle value</div>
                    </div>
                    <div class="search-result-item__metadata">Lead</div>
                  </button>
                </div>
              </div>
            </div>
          </div>
          <div class="global-search__hints">
            <span class="global-search__hint"><kbd>↑</kbd><kbd>↓</kbd> nav</span>
          </div>
        </div>
      </section>

      <section>
        <h3 style="margin-bottom:8px;">Notifications</h3>
        <div style="position:relative; height:1px;">
          <div class="notification-dropdown">
            <div class="notification-dropdown-header">
              <h3 class="notification-dropdown-title">Notifications</h3>
              <button class="notification-dropdown-action">Mark all read</button>
            </div>
            <div class="notification-dropdown-content">
              <div class="notification-group">
                <h4 class="notification-group-title notification-group-today">Due Today (2)</h4>
                <div class="task-reminder-card reminder-due-today">
                  <div class="task-reminder-content">
                    <div class="task-reminder-header">
                      <h4 class="task-reminder-title">Reminder title here</h4>
                      <span class="task-reminder-badge reminder-due-today">Due today</span>
                    </div>
                    <p class="task-reminder-entity">Contact • Deal</p>
                  </div>
                </div>
              </div>
            </div>
            <div class="notification-dropdown-footer">
              <button class="notification-view-all-btn">View all</button>
            </div>
          </div>
        </div>
      </section>

      <section>
        <h3 style="margin-bottom:8px;">Kanban</h3>
        <div class="kanban-board" data-testid="kanban-board">
          ${['Lead', 'Qualified', 'Proposal'].map((stage, index) => {
            return `
              <div class="kanban-column">
                <div class="stage-header">
                  <div class="stage-header__top">
                    <div class="stage-header__name-row">
                      <div class="stage-header__color" style="background:${index === 0 ? '#6366f1' : index === 1 ? '#3b82f6' : '#10b981'}"></div>
                      <div class="stage-header__name">${stage}</div>
                    </div>
                    <div class="stage-header__count">2</div>
                  </div>
                  <div class="stage-header__value">$15,000</div>
                  <div class="stage-header__probability">30%</div>
                </div>
                <div class="kanban-column__content">
                  <div class="deal-card">
                    <div class="deal-card__header">
                      <span class="deal-card__title">Extremely long deal title that should clamp to two lines without stretching the card height noticeably beyond the rest</span>
                      <span class="deal-card__value">$25,000</span>
                    </div>
                    <div class="deal-card__client">
                      <div class="deal-card__client-avatar">AC</div>
                      <span class="deal-card__client-name">Acme Corp</span>
                    </div>
                    <div class="deal-card__footer">
                      <span class="deal-card__date">Jan 15</span>
                      <span class="deal-card__probability">60%</span>
                    </div>
                  </div>
                </div>
              </div>
            `;
          }).join('')}
        </div>
      </section>
    </div>
  `;
}

async function main() {
  if (!fs.existsSync(artifactsDir)) {
    fs.mkdirSync(artifactsDir);
  }

  // Some environments resolve the wrong arch path; fall back to arm64 binary when present.
  let executablePath = chromium.executablePath();
  const armPath = path.join(
    process.env.HOME || '',
    'Library',
    'Caches',
    'ms-playwright',
    'chromium_headless_shell-1200',
    'chrome-headless-shell-mac-arm64',
    'chrome-headless-shell'
  );
  if (!fs.existsSync(executablePath) && fs.existsSync(armPath)) {
    executablePath = armPath;
  }

  const browser = await chromium.launch({ headless: true, executablePath });
  const page = await browser.newPage({ viewport });

  const css = loadCss();
  await page.addStyleTag({ content: css });
  await page.setContent(buildMarkup());

  // Measure key elements against viewport width.
  const measurements = await page.evaluate(() => {
    const vw = window.innerWidth;
    const search = document.querySelector('.global-search__dropdown')?.getBoundingClientRect();
    const notifications = document.querySelector('.notification-dropdown')?.getBoundingClientRect();
    const kanban = document.querySelector('.kanban-board')?.getBoundingClientRect();
    const card = document.querySelector('.deal-card')?.getBoundingClientRect();
    return {
      viewportWidth: vw,
      searchWidth: search?.width || 0,
      notificationWidth: notifications?.width || 0,
      kanbanWidth: kanban?.width || 0,
      dealCardHeight: card?.height || 0,
    };
  });

  const screenshotPath = path.join(artifactsDir, 'mobile-smoke.png');
  await page.screenshot({ path: screenshotPath, fullPage: true });
  await browser.close();

  console.log('Mobile smoke results:');
  console.table(measurements);
  console.log(`Screenshot saved to ${screenshotPath}`);
}

main().catch((err) => {
  console.error('Mobile smoke check failed:', err);
  process.exit(1);
});
