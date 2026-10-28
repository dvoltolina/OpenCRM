/**
 * Sidebar Component
 * Agent CRM-35: Enhanced with accessibility improvements
 */

import { NavLink } from 'react-router-dom';
import { getVisibleNavItems } from '../nav';
import { getFeatureFlags } from '../config/features';
import { useAuth } from '../context/AuthContext';
import { DEMO_SIGN_UP_URL, isDemoMode } from '../config/demo';
import { NotificationBell } from './notifications/NotificationBell';

function Icon({ name }: { name: string }) {
  const iconProps = {
    fill: 'none',
    stroke: 'currentColor',
    strokeLinecap: 'round' as const,
    strokeLinejoin: 'round' as const,
    strokeWidth: 1.75,
    viewBox: '0 0 20 20',
  };

  switch (name) {
    case 'chart-bar':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <path d="M3.5 16.5h13" />
            <path d="M6 16V10" />
            <path d="M10 16V6" />
            <path d="M14 16v-3.5" />
          </svg>
        </span>
      );
    case 'shield-check':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <path d="M10 3.2 14.7 5v4.2c0 3-1.9 5.6-4.7 6.6-2.8-1-4.7-3.6-4.7-6.6V5L10 3.2Z" />
            <path d="m7.6 10 1.5 1.5 3.4-3.4" />
          </svg>
        </span>
      );
    case 'view-columns':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <rect x="3.5" y="4" width="4.5" height="12" rx="1.2" />
            <rect x="12" y="4" width="4.5" height="12" rx="1.2" />
          </svg>
        </span>
      );
    case 'user-plus':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <path d="M10 15c0-2.2-1.8-4-4-4S2 12.8 2 15" />
            <circle cx="6" cy="7.5" r="2.5" />
            <path d="M14 7h4" />
            <path d="M16 5v4" />
          </svg>
        </span>
      );
    case 'currency-dollar':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <path d="M10 3v14" />
            <path d="M13 5.4a2.9 2.9 0 0 0-3-1.4c-1.8.2-3 1.2-3 2.6 0 1.3 1 2 3.1 2.4 2.1.3 3.1 1.1 3.1 2.5 0 1.5-1.4 2.5-3.3 2.5-1.5 0-2.7-.5-3.6-1.5" />
          </svg>
        </span>
      );
    case 'users':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <circle cx="7" cy="7" r="2.3" />
            <circle cx="13.4" cy="8" r="2" />
            <path d="M2.7 15c.5-2 2.1-3.3 4.3-3.3S11 13 11.4 15" />
            <path d="M11.5 14.6c.4-1.4 1.6-2.4 3.2-2.4 1.2 0 2.2.5 2.8 1.5" />
          </svg>
        </span>
      );
    case 'building-office':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <path d="M4 16.5V4.5c0-.6.4-1 1-1h7.5c.6 0 1 .4 1 1v12" />
            <path d="M2.5 16.5h15" />
            <path d="M7 6.5h1" />
            <path d="M10 6.5h1" />
            <path d="M7 9.5h1" />
            <path d="M10 9.5h1" />
            <path d="M8.8 16.5V13h1.9v3.5" />
          </svg>
        </span>
      );
    case 'clipboard-list':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <rect x="4.5" y="4.2" width="11" height="12" rx="1.4" />
            <path d="M7.3 4.2c.2-1 1-1.7 2-1.7h1.4c1 0 1.8.7 2 1.7" />
            <path d="M7.4 8h5.4" />
            <path d="M7.4 11h5.4" />
            <path d="M7.4 14h3.2" />
          </svg>
        </span>
      );
    case 'bell':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <path d="M6 8.5a4 4 0 1 1 8 0c0 4 1.2 4.8 1.2 4.8H4.8S6 12.5 6 8.5Z" />
            <path d="M8.5 15.3a1.7 1.7 0 0 0 3 0" />
          </svg>
        </span>
      );
    case 'folder-open':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <path d="M3 7.5h5l1.5 1.7H17v5.3c0 .8-.7 1.5-1.5 1.5H4.5C3.7 16 3 15.3 3 14.5v-7c0-.8.7-1.5 1.5-1.5h3" />
          </svg>
        </span>
      );
    case 'trophy':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <path d="M6 4h8v2.5A4 4 0 0 1 10 10.5 4 4 0 0 1 6 6.5V4Z" />
            <path d="M6 5H4.5A1.5 1.5 0 0 0 3 6.5c0 1.5 1.3 2.7 2.9 2.7H6" />
            <path d="M14 5h1.5A1.5 1.5 0 0 1 17 6.5c0 1.5-1.3 2.7-2.9 2.7H14" />
            <path d="M10 10.5V14" />
            <path d="M7.5 16.5h5" />
          </svg>
        </span>
      );
    case 'map':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <path d="m3.5 5.5 4-2 5 2 4-2v11l-4 2-5-2-4 2Z" />
            <path d="M7.5 3.5v11" />
            <path d="M12.5 5.5v11" />
          </svg>
        </span>
      );
    case 'clock':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <circle cx="10" cy="10" r="6.5" />
            <path d="M10 6.5v4l2.8 1.6" />
          </svg>
        </span>
      );
    case 'arrow-path':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <path d="M15.5 6.5V3.5h-3" />
            <path d="M4.5 13.5v3h3" />
            <path d="M14.8 8A5.5 5.5 0 0 0 5.5 6.5" />
            <path d="M5.2 12A5.5 5.5 0 0 0 14.5 13.5" />
          </svg>
        </span>
      );
    case 'chart-pie':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <path d="M10 3.5A6.5 6.5 0 1 0 16.5 10H10Z" />
            <path d="M11.3 3.7A6.5 6.5 0 0 1 16.3 8.7h-5Z" />
          </svg>
        </span>
      );
    case 'document-chart-bar':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <path d="M6 3.5h5l3 3v10c0 .6-.4 1-1 1H6c-.6 0-1-.4-1-1v-12c0-.6.4-1 1-1Z" />
            <path d="M11 3.5v3h3" />
            <path d="M7.5 13.5V10" />
            <path d="M10 13.5V8.5" />
            <path d="M12.5 13.5v-2.5" />
          </svg>
        </span>
      );
    case 'clipboard-document-list':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <rect x="4.5" y="4.2" width="11" height="12" rx="1.4" />
            <path d="M7.3 4.2c.2-1 1-1.7 2-1.7h1.4c1 0 1.8.7 2 1.7" />
            <path d="M7.4 8h5.4" />
            <path d="M7.4 11h5.4" />
            <path d="M7.4 14h5.4" />
          </svg>
        </span>
      );
    case 'link':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <path d="M8 12.5 12 8.5" />
            <path d="M6.2 14.3 4.8 15.7a2.6 2.6 0 1 1-3.7-3.7L2.5 10.6" />
            <path d="m13.8 5.7 1.4-1.4a2.6 2.6 0 1 1 3.7 3.7l-1.4 1.4" />
            <path d="m7.2 6.2 1.4-1.4a3 3 0 0 1 4.2 4.2l-1.1 1.1" />
          </svg>
        </span>
      );
    case 'cog':
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <circle cx="10" cy="10" r="2.3" />
            <path d="M10 3.5v1.6" />
            <path d="M10 14.9v1.6" />
            <path d="m5.4 5.4 1.1 1.1" />
            <path d="m13.5 13.5 1.1 1.1" />
            <path d="M3.5 10h1.6" />
            <path d="M14.9 10h1.6" />
            <path d="m5.4 14.6 1.1-1.1" />
            <path d="m13.5 6.5 1.1-1.1" />
          </svg>
        </span>
      );
    default:
      return (
        <span className="nav-icon" aria-hidden="true">
          <svg {...iconProps}>
            <circle cx="10" cy="10" r="1.8" fill="currentColor" stroke="none" />
          </svg>
        </span>
      );
  }
}

interface SidebarProps {
  collapsed?: boolean;
  onToggleCollapse?: () => void;
}

export function Sidebar({ collapsed = false, onToggleCollapse }: SidebarProps) {
  const { crmUser, signOut } = useAuth();
  const features = getFeatureFlags();
  const visibleNavItems = getVisibleNavItems(features, crmUser?.role);

  return (
    <aside className={`sidebar${collapsed ? ' sidebar--collapsed' : ''}`}>
      <div className="sidebar-header">
        <div className="sidebar-header-top">
          <div className="sidebar-brand">
            <span className="sidebar-eyebrow">Workspace</span>
            <h1 className="sidebar-title">The Schedular CRM</h1>
          </div>
          <div className="sidebar-header-actions">
            <NotificationBell />
            <button
              type="button"
              className="sidebar-collapse-btn"
              onClick={onToggleCollapse}
              title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
              aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
            >
              <svg width="18" height="18" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
                {collapsed ? (
                  <path d="M8 4l6 6-6 6" />
                ) : (
                  <path d="M12 4l-6 6 6 6" />
                )}
              </svg>
            </button>
          </div>
        </div>
        {crmUser && (
          <div className="sidebar-user">
            <span className="user-name">{crmUser.displayName}</span>
            <span className="user-role">{crmUser.role}</span>
          </div>
        )}
      </div>

      <nav className="sidebar-nav" role="navigation" aria-label="Main navigation">
        {visibleNavItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) =>
              `nav-item ${isActive ? 'nav-item-active' : ''}`
            }
            end
          >
            {({ isActive }) => (
              <>
                <Icon name={item.icon} />
                <span className="nav-label" aria-current={isActive ? 'page' : undefined}>
                  {item.label}
                </span>
              </>
            )}
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-footer">
        {isDemoMode ? (
          <a className="sign-out-btn" href={DEMO_SIGN_UP_URL}>
            {collapsed ? '→' : 'Sign Up'}
          </a>
        ) : (
          <button onClick={signOut} className="sign-out-btn" type="button">
            {collapsed ? '→' : 'Sign Out'}
          </button>
        )}
      </div>
    </aside>
  );
}
