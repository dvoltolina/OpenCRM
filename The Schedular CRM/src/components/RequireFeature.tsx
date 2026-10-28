import type { ReactNode } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { getFeatureFlags } from '../config/features';
import type { FeatureFlags } from '../config/features';

interface RequireFeatureProps {
  children: ReactNode;
  flag?: keyof FeatureFlags;
  flags?: Array<keyof FeatureFlags>;
  mode?: 'all' | 'any';
  redirectTo?: string;
}

export function RequireFeature({
  children,
  flag,
  flags,
  mode,
  redirectTo = '/dashboard',
}: RequireFeatureProps) {
  const location = useLocation();
  const features = getFeatureFlags();
  const featureKeys = flags ?? (flag ? [flag] : []);

  if (featureKeys.length === 0) {
    return <>{children}</>;
  }

  const resolvedMode = mode ?? (featureKeys.length > 1 ? 'any' : 'all');
  const isEnabled = resolvedMode === 'all'
    ? featureKeys.every((featureKey) => Boolean(features[featureKey]))
    : featureKeys.some((featureKey) => Boolean(features[featureKey]));

  if (!isEnabled) {
    return <Navigate to={redirectTo} state={{ from: location }} replace />;
  }

  return <>{children}</>;
}
