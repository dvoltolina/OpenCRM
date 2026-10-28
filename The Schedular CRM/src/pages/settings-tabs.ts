export type SettingsTab =
  | 'workspace'
  | 'pipeline'
  | 'team'
  | 'fields'
  | 'integrations'
  | 'profile'
  | 'automation'
  | 'notifications';

export const DEFAULT_SETTINGS_TAB: SettingsTab = 'workspace';
export const SETTINGS_NOTIFICATION_TAB: SettingsTab = 'notifications';

const SETTINGS_TAB_ALIASES: Record<string, SettingsTab> = {
  workspace: 'workspace',
  pipeline: 'pipeline',
  pipelines: 'pipeline',
  team: 'team',
  fields: 'fields',
  field: 'fields',
  'custom-fields': 'fields',
  integrations: 'integrations',
  integration: 'integrations',
  profile: 'profile',
  automation: 'automation',
  notifications: 'notifications',
  notification: 'notifications',
};

export function normalizeSettingsTab(
  rawTab: string | null | undefined,
  availableTabs: readonly SettingsTab[],
  fallbackTab: SettingsTab = DEFAULT_SETTINGS_TAB
): SettingsTab {
  const safeFallback = availableTabs.includes(fallbackTab)
    ? fallbackTab
    : availableTabs[0] ?? fallbackTab;

  if (!rawTab) {
    return safeFallback;
  }

  const normalized = SETTINGS_TAB_ALIASES[rawTab.toLowerCase()];
  if (normalized && availableTabs.includes(normalized)) {
    return normalized;
  }

  return safeFallback;
}
