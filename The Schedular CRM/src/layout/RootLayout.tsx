/**
 * RootLayout Component
 * Agent CRM-35: Enhanced with skip link and main landmark
 */

import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from '../components/Sidebar';
import { DemoBanner } from '../components/DemoBanner';
import { OfflineNotice } from '../components/common';
import { isDemoMode } from '../config/demo';

export function RootLayout() {
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);

  return (
    <div className={`app-layout${isDemoMode ? ' app-layout--demo' : ''}${sidebarCollapsed ? ' app-layout--collapsed' : ''}`}>
      <DemoBanner />
      <OfflineNotice />
      {/* Skip to main content link for keyboard users */}
      <a href="#main-content" className="skip-link">
        Skip to main content
      </a>
      <Sidebar collapsed={sidebarCollapsed} onToggleCollapse={() => setSidebarCollapsed((c) => !c)} />
      <main id="main-content" className="main-content" role="main">
        <Outlet />
      </main>
    </div>
  );
}
