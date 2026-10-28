import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { multiFactor } from 'firebase/auth';

import { isDemoMode } from '../config/demo';
import { useAuth } from '../context/AuthContext';
import { useBusinessContext } from '../hooks/useBusinessContext';
import { useWorkspaceInfo } from '../hooks/useWorkspaceInfo';
import { getFirebaseAuth } from '../lib/firebase';

export function HipaaMfaGuard() {
  const location = useLocation();
  const { state } = useAuth();
  const { businessId } = useBusinessContext();
  const { workspace, loading } = useWorkspaceInfo(businessId);

  const onMfaRoute = location.pathname === '/mfa';
  const isSignedIn = state.status === 'signed_in';
  const requiresMfa =
    Boolean(workspace?.requiresHipaaCompliance) || Boolean(workspace?.mfaEnabled);

  if (isDemoMode) {
    return <Outlet />;
  }

  if (!isSignedIn) {
    return <Navigate to="/login" replace />;
  }

  if (loading) {
    return (
      <div className="loading-screen">
        <div className="loading-spinner" aria-label="Loading" role="status">
          <div className="spinner"></div>
          <p className="loading-text">Checking security requirements...</p>
        </div>
      </div>
    );
  }

  const currentUser = getFirebaseAuth().currentUser;
  const enrolled = currentUser ? multiFactor(currentUser).enrolledFactors.length : 0;
  const redirect = shouldRedirectToMfa({
    requiresMfa,
    enrolledFactors: enrolled,
    onMfaRoute,
  });
  if (redirect) return <Navigate to={redirect} replace />;

  return <Outlet />;
}

export function shouldRedirectToMfa({
  requiresMfa,
  enrolledFactors,
  onMfaRoute,
}: {
  requiresMfa: boolean;
  enrolledFactors: number;
  onMfaRoute: boolean;
}): string | null {
  if (!requiresMfa) return null;
  if (enrolledFactors > 0) return null;
  if (onMfaRoute) return null;
  return '/mfa';
}
