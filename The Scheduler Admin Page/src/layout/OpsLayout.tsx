/**
 * OpsLayout
 * Layout for the Ops Portal (super-admin only).
 * Separate navigation and branding from the main app.
 */

import { NavLink, Outlet } from 'react-router-dom';
import { Topbar } from '../components/Topbar';
import { useAuth } from '../context/AuthContext';

const opsNavItems = [
  { label: 'Tenants', path: '/ops/tenants' },
  { label: 'Audit Log', path: '/ops/audit' },
];

export function OpsLayout() {
  const { state, signOut } = useAuth();

  return (
    <div className="app-shell">
      <aside className="sidebar sidebar--ops">
        <div className="sidebar__brand">
          <div>
            <div className="brand-title">Ops Portal</div>
            <div className="brand-subtitle">Super Admin</div>
          </div>
        </div>
        <nav className="sidebar__nav">
          {opsNavItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                `nav-link${isActive ? ' nav-link--active' : ''}`
              }
            >
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>
        <div className="sidebar__footer">
          <a href="/dashboard" className="nav-link">
            <span className="nav-link__icon" aria-hidden>
              ←
            </span>
            <span>Exit Ops Portal</span>
          </a>
        </div>
      </aside>
      <div className="main">
        <Topbar
          onSignOut={async () => {
            await signOut();
          }}
          userLabel={
            state.status === 'signed_in'
              ? `${state.user.displayName ?? 'Operator'} (Super Admin)`
              : 'Signed out'
          }
        />
        <main className="main__content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
