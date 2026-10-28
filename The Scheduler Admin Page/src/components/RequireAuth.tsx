import { Navigate, Outlet } from 'react-router-dom';

import { isDemoMode } from '../config/demo';
import { useAuth } from '../context/AuthContext';
import { AccessBoundary } from './AccessBoundary';

export function RequireAuth() {
  const { state } = useAuth();

  if (isDemoMode) {
    return (
      <AccessBoundary>
        <Outlet />
      </AccessBoundary>
    );
  }

  if (state.status === 'loading') {
    return (
      <div style={{ padding: 24 }}>
        <p>Loading account…</p>
      </div>
    );
  }

  if (state.status === 'signed_out') {
    return <Navigate to="/login" replace />;
  }

  if (state.status === 'pending_verification') {
    return <Navigate to="/verify-email" replace />;
  }

  if (state.status === 'pending_profile') {
    return <Navigate to="/owner-onboarding" replace />;
  }

  if (state.status === 'mfa_required') {
    return <Navigate to="/mfa" replace />;
  }

  if (state.status === 'error') {
    return (
      <div style={{ padding: 24 }}>
        <p>Authentication failed.</p>
        <p className="muted">{state.error}</p>
      </div>
    );
  }

  // SECURITY: Enforce strict tenant scoping - businessId is required for all admin operations
  if (state.status === 'signed_in' && !state.user.businessId) {
    return (
      <div style={{ padding: 24 }}>
        <h2>Business Context Required</h2>
        <p>Your account is not associated with a business workspace.</p>
        <p className="muted">
          Contact your administrator to grant you access to a business workspace.
        </p>
      </div>
    );
  }

  return (
    <AccessBoundary>
      <Outlet />
    </AccessBoundary>
  );
}
