import { Navigate, Outlet, useLocation } from 'react-router-dom';

import { isDemoMode } from '../config/demo';
import { useBusinessContext } from '../hooks/useBusinessContext';
import { useBillingProfile } from '../hooks/useBillingProfile';
import type { BillingProfile } from '../types/models';

export function BillingGuard() {
  const location = useLocation();
  const { businessId, userId, role } = useBusinessContext();
  const { profile, loading } = useBillingProfile(businessId, userId);
  const onBillingGateRoute = location.pathname === '/billing-gate';
  const bypassStatus =
    typeof location.state === 'object' && location.state !== null
      ? (location.state as { billingStatus?: BillingProfile['status'] }).billingStatus
      : undefined;
  const isOwner = role === 'owner';

  if (isDemoMode) {
    return <Outlet />;
  }

  if (loading) {
    return (
      <div className="loading-screen">
        <div className="loading-spinner" aria-label="Loading" role="status">
          <div className="spinner"></div>
          <p className="loading-text">Loading billing status...</p>
        </div>
      </div>
    );
  }

  // Check if subscription is active (active/trialing/past_due allow progression)
  const hasActiveSubscription = isBillingActive(bypassStatus ?? profile?.status);

  // Non-owners: if billing incomplete, show blocking screen
  if (!isOwner && !hasActiveSubscription && !onBillingGateRoute) {
    return <Navigate to="/billing-gate" replace />;
  }

  // Owner: if billing incomplete, redirect to gate
  if (isOwner && !hasActiveSubscription && !onBillingGateRoute) {
    return <Navigate to="/billing-gate" replace />;
  }

  // If billing is complete and user is on billing gate, redirect to next step (onboarding)
  if (hasActiveSubscription && onBillingGateRoute) {
    return <Navigate to="/onboarding" replace />;
  }

  return <Outlet />;
}

export function isBillingActive(status?: BillingProfile['status']): boolean {
  return ['active', 'trialing', 'past_due'].includes(status ?? '');
}
