import { useMemo } from 'react';
import { getFeatureFlags } from '../config/features';
import type { FeatureFlags } from '../config/features';

export type { FeatureFlags };

export function useFeatureFlags() {
  const flags = useMemo(() => getFeatureFlags(), []);
  const isEnabled = (flag: keyof FeatureFlags) => Boolean(flags[flag]);
  return { flags, isEnabled };
}
