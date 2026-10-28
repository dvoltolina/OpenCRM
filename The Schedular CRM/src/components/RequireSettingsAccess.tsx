import type { ReactNode } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import {
  normalizeSettingsTab,
  SETTINGS_NOTIFICATION_TAB,
} from '../pages/settings-tabs';

interface RequireSettingsAccessProps {
  children: ReactNode;
}

export function RequireSettingsAccess({ children }: RequireSettingsAccessProps) {
  const location = useLocation();
  const { crmUser } = useAuth();

  if (!crmUser) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (crmUser.role === 'owner' || crmUser.role === 'admin') {
    return <>{children}</>;
  }

  const params = new URLSearchParams(location.search);
  const rawTab = params.get('tab');
  const normalizedTab = normalizeSettingsTab(
    rawTab,
    [SETTINGS_NOTIFICATION_TAB],
    SETTINGS_NOTIFICATION_TAB
  );

  if (rawTab === normalizedTab) {
    return <>{children}</>;
  }

  params.set('tab', normalizedTab);
  return (
    <Navigate
      to={{ pathname: '/settings', search: `?${params.toString()}` }}
      state={{ from: location }}
      replace
    />
  );
}
