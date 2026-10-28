import type { FeatureFlags, UserRole } from './types/models';
import { isDemoMode } from './config/demo';

export type NavItem = {
  label: string;
  path: string;
  icon: string;
  flag?: keyof FeatureFlags;
  flags?: Array<keyof FeatureFlags>;
  flagMode?: 'all' | 'any';
  allowedRoles?: UserRole[];
};

export const navItems: NavItem[] = [
  { label: 'Dashboard', path: '/dashboard', icon: 'chart-bar' },
  { label: 'Admin', path: '/admin', icon: 'shield-exclamation', allowedRoles: ['admin', 'owner'] },
  { label: 'Manager', path: '/manager', icon: 'shield-check', allowedRoles: ['manager', 'admin', 'owner'] },
  // Unified funnel flow: Contacts → Leads → Opportunities → Pipeline
  { label: 'Contacts', path: '/contacts', icon: 'users' },
  { label: 'Leads', path: '/leads', icon: 'user-plus' },
  { label: 'Opportunities', path: '/deals', icon: 'currency-dollar' },
  { label: 'Pipeline', path: '/pipeline', icon: 'view-columns' },
  { label: 'Companies', path: '/companies', icon: 'building-office', flag: 'enableCompanies' },
  { label: 'Activities', path: '/activities', icon: 'clipboard-list' },
  { label: 'Notifications', path: '/notifications', icon: 'bell' },
  { label: 'Documents', path: '/documents', icon: 'folder-open', flag: 'enableDocuments' },
  { label: 'Goals', path: '/goals', icon: 'trophy', flag: 'enableGoals' },
  { label: 'Routes', path: '/routes', icon: 'map', flag: 'enableRoutePlanning' },
  { label: 'Team Routes', path: '/team-routes', icon: 'map-pin', flag: 'enableRoutePlanning', allowedRoles: ['manager', 'admin', 'owner'] },
  { label: 'Staff Schedules', path: '/staff-schedules', icon: 'calendar-days', flag: 'enableRoutePlanning', allowedRoles: ['manager', 'admin', 'owner'] },
  { label: 'Territories', path: '/territories', icon: 'globe-americas', flag: 'enableRoutePlanning', allowedRoles: ['manager', 'admin', 'owner'] },
  { label: 'Timesheets', path: '/timesheets', icon: 'clock', allowedRoles: ['manager', 'admin', 'owner'] },
  { label: 'Sequences', path: '/sequences', icon: 'arrow-path', flag: 'enableSequences' },
  { label: 'Reports', path: '/reports', icon: 'chart-pie', flag: 'enableReports' },
  {
    label: 'Report Builder',
    path: '/reports/builder',
    icon: 'document-chart-bar',
    flags: ['enableReports', 'enableAdvancedReporting'],
    flagMode: 'all',
  },
  { label: 'Web Forms', path: '/web-forms', icon: 'clipboard-document-list', flag: 'enableWebForms' },
  {
    label: 'Integrations',
    path: '/integrations',
    icon: 'link',
    flags: ['enableApi', 'enableWebhooks', 'enableCalendarSync'],
    flagMode: 'any',
    allowedRoles: ['admin', 'owner'],
  },
  { label: 'Settings', path: '/settings', icon: 'cog', allowedRoles: ['owner', 'admin'] },
];

// Filter nav items based on feature flags
export function getVisibleNavItems(features: FeatureFlags, role?: UserRole): NavItem[] {
  return navItems.filter((item) => {
    if (isDemoMode && item.path === '/admin') {
      return false;
    }

    const featureKeys = item.flags ?? (item.flag ? [item.flag] : []);
    if (featureKeys.length === 0) return true;

    const mode = item.flagMode ?? (featureKeys.length > 1 ? 'any' : 'all');
    const enabled = mode === 'all'
      ? featureKeys.every((flag) => Boolean(features[flag]))
      : featureKeys.some((flag) => Boolean(features[flag]));

    return enabled;
  }).filter((item) => {
    if (!item.allowedRoles) return true;
    if (!role) return false;
    return item.allowedRoles.includes(role);
  });
}
