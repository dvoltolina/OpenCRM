import type { ReactNode } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import type { UserRole } from '../types/models';

interface RequireRoleProps {
  children: ReactNode;
  roles: UserRole[];
  redirectTo?: string;
}

export function RequireRole({
  children,
  roles,
  redirectTo = '/dashboard',
}: RequireRoleProps) {
  const location = useLocation();
  const { crmUser } = useAuth();

  if (!crmUser || !roles.includes(crmUser.role)) {
    return <Navigate to={redirectTo} state={{ from: location }} replace />;
  }

  return <>{children}</>;
}
