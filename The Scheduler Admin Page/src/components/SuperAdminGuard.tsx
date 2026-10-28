/**
 * SuperAdminGuard
 * Route guard that only allows access to users with the superAdmin Firebase claim.
 * Used to protect the /ops portal routes.
 */

import { Navigate, Outlet } from 'react-router-dom';
import { isDemoMode } from '../config/demo';
import { useAuth } from '../context/AuthContext';

export function SuperAdminGuard() {
  const { state, isSuperAdmin } = useAuth();

  if (isDemoMode) {
    return <Navigate to="/dashboard" replace />;
  }

  if (state.status === 'loading') {
    return (
      <div className="loading-screen">
        <div className="loading-spinner" aria-label="Loading" role="status">
          <div className="spinner"></div>
          <p className="loading-text">Verifying access...</p>
        </div>
      </div>
    );
  }

  if (state.status !== 'signed_in') {
    return <Navigate to="/login" replace />;
  }

  if (!isSuperAdmin) {
    return (
      <div style={{ padding: 24, maxWidth: 600, margin: '80px auto', textAlign: 'center' }}>
        <p className="eyebrow" style={{ color: 'var(--color-danger)' }}>Access Denied</p>
        <h1 style={{ marginBottom: 8 }}>Ops Portal Restricted</h1>
        <p className="muted" style={{ marginBottom: 24 }}>
          This area is restricted to authorized operations personnel only.
          If you believe you should have access, contact your system administrator.
        </p>
        <div>
          <a className="button button--ghost" href="/dashboard">
            Return to Dashboard
          </a>
        </div>
      </div>
    );
  }

  return <Outlet />;
}
