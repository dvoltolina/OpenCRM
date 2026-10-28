import { Navigate, Outlet, useLocation } from 'react-router-dom';

import { isDemoMode } from '../config/demo';
import { useBusinessContext } from '../hooks/useBusinessContext';
import { useOnboarding } from '../hooks/useOnboarding';

export function OnboardingGuard() {
  const location = useLocation();
  const { businessId, userId } = useBusinessContext();
  const { state, loading, needsOnboarding } = useOnboarding(businessId, userId, {
    subscribe: true,
  });
  const pathname = location.pathname;

  if (isDemoMode) {
    return <Outlet />;
  }

  if (loading && !state) {
    return (
      <div className="loading-screen">
        <div className="loading-spinner" aria-label="Loading" role="status">
          <div className="spinner"></div>
          <p className="loading-text">Loading onboarding status...</p>
        </div>
      </div>
    );
  }

  const redirect = getOnboardingRedirect({ needsOnboarding, pathname });
  if (redirect) {
    return <Navigate to={redirect} replace />;
  }

  return <Outlet />;
}

export function getOnboardingRedirect({
  needsOnboarding,
  pathname,
}: {
  needsOnboarding: boolean;
  pathname: string;
}): string | null {
  const onOnboardingRoute = pathname.startsWith('/onboarding');
  const onSuccessPage = pathname === '/onboarding/success';

  // If onboarding needed and not on any onboarding route, redirect to onboarding
  if (needsOnboarding && !onOnboardingRoute) {
    return '/onboarding';
  }

  // If onboarding complete and on main onboarding page (not success), redirect to dashboard
  // Allow the success page to be shown when onboarding is complete
  if (!needsOnboarding && onOnboardingRoute && !onSuccessPage) {
    return '/dashboard';
  }

  return null;
}
