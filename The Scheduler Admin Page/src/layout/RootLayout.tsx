import { useEffect, useMemo, useState } from 'react';
import { Link, NavLink, Navigate, Outlet, useLocation } from 'react-router-dom';

import { DemoBanner } from '../components/DemoBanner';
import { isDemoMode } from '../config/demo';
import { Topbar } from '../components/Topbar';
import { canAccessNavItem, isNavItemVisible, navItems } from '../nav';
import { useAuth } from '../context/AuthContext';
import { useBusinessContext } from '../hooks/useBusinessContext';
import { useFeatureFlags } from '../hooks/useFeatureFlags';
import { useBillingProfile } from '../hooks/useBillingProfile';
import { isBillingActive } from '../components/BillingGuard';
import { useStaffPermissions } from '../hooks/useStaffPermissions';

export function RootLayout() {
  const { state, signOut, isSuperAdmin } = useAuth();
  const location = useLocation();
  const [hasHydratedAccess, setHasHydratedAccess] = useState(false);
  const { businessId, hasRole, userId, role } = useBusinessContext();
  const { flags, loading: flagsLoading } = useFeatureFlags(businessId);
  const { profile: billingProfile } = useBillingProfile(businessId, userId);
  const userEmail = state.status === 'signed_in' ? state.user.email : null;
  const { hasModule, loading: permissionsLoading } = useStaffPermissions(
    businessId,
    userId,
    role,
    userEmail,
  );

  useEffect(() => {
    setHasHydratedAccess(true);
  }, []);

  const filteredNav = useMemo(
    () =>
      navItems.filter((item) => {
        return isNavItemVisible(item, {
          hasRole,
          hasModule,
          flags,
          hideBillingEntry: !isDemoMode && isBillingActive(billingProfile?.status),
        });
      }),
    [billingProfile?.status, flags, hasModule, hasRole],
  );

  const activeNavItem = useMemo(
    () => navItems.find((item) => item.path === location.pathname),
    [location.pathname],
  );

  const canEvaluateRouteAccess = hasHydratedAccess && !flagsLoading && !permissionsLoading;
  if (
    activeNavItem &&
    canEvaluateRouteAccess &&
    !canAccessNavItem(activeNavItem, { hasRole, hasModule, flags })
  ) {
    return <Navigate to="/dashboard" replace />;
  }

  return (
    <>
      <DemoBanner />
      <div className={`app-shell${isDemoMode ? ' app-shell--demo' : ''}`}>
        <aside className="sidebar">
          <div className="sidebar__brand">
            <div>
              <div className="brand-title">OpenCRM</div>
              <div className="brand-subtitle">Admin Portal</div>
            </div>
          </div>
          <nav className="sidebar__nav">
            {filteredNav.map((item) => (
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
          {isSuperAdmin && (
            <div className="sidebar__footer">
              <Link to="/ops" className="nav-link nav-link--ops">
                <span>Ops Portal</span>
              </Link>
            </div>
          )}
        </aside>
        <div className="main">
          <Topbar
            onSignOut={
              isDemoMode
                ? undefined
                : async () => {
                    await signOut();
                  }
            }
            userLabel={
              state.status === 'signed_in'
                ? `${state.user.displayName ?? 'User'} · ${state.user.role}`
                : 'Signed out'
            }
          />
          <main className="main__content">
            <Outlet />
          </main>
        </div>
      </div>
    </>
  );
}
