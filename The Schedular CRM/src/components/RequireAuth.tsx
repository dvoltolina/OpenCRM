import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export function RequireAuth() {
  const { user, crmUser, businessId, isLoading, status } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return (
      <div className="loading-screen">
        <div className="loading-spinner" />
        <p>Loading session...</p>
      </div>
    );
  }

  if (status === 'mfa_required' && location.pathname !== '/mfa') {
    return <Navigate to="/mfa" state={{ from: location }} replace />;
  }

  if (!user) {
    // Redirect to login, preserving the attempted URL
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  // HIPAA/Security: Require businessId for tenant isolation
  // No default/fallback businessId is permitted
  if (!businessId || !crmUser?.businessId) {
    return <Navigate to="/business-required" state={{ from: location }} replace />;
  }

  return <Outlet />;
}
