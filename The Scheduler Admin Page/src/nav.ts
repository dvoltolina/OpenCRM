import type { FeatureFlags, ModuleAccess } from './types/models';
import type { RoleRequirement } from './types/auth';

export type NavItem = {
  label: string;
  path: string;
  flag?: keyof FeatureFlags;
  minRole?: RoleRequirement;
  module?: keyof ModuleAccess;
};

const allNavItems: NavItem[] = [
  { label: 'Dashboard', path: '/dashboard' },
  { label: 'Calendar', path: '/calendar', module: 'calendar' },
  { label: 'Staff', path: '/staff', module: 'settings' },
  { label: 'Services', path: '/services', module: 'calendar' },
  {
    label: 'Intake Builder',
    path: '/intake-builder',
    flag: 'enableIntakeBuilder',
    minRole: 'admin',
    module: 'clients',
  },
  { label: 'Clients', path: '/clients', module: 'clients' },
  { label: 'Appointments', path: '/appointments', module: 'calendar' },
  { label: 'Group Sessions', path: '/group-sessions', module: 'calendar' },
  { label: 'Waitlist', path: '/waitlist', flag: 'enableWaitlist', module: 'calendar' },
  { label: 'Locations', path: '/locations', flag: 'enableLocations', module: 'settings' },
  { label: 'Communications', path: '/communications', module: 'clients' },
  {
    label: 'Marketing',
    path: '/marketing',
    flag: 'enableMarketing',
    minRole: 'admin',
    module: 'marketing',
  },
  { label: 'Settings', path: '/settings', module: 'settings' },
  { label: 'Billing', path: '/billing', minRole: 'owner', module: 'billing' },
  { label: 'Reports', path: '/reports', flag: 'enableReporting', minRole: 'admin' },
];

export const navItems = allNavItems;

type NavAccessContext = {
  hasRole: (required: RoleRequirement) => boolean;
  hasModule: (module?: keyof ModuleAccess) => boolean;
  flags: FeatureFlags;
};

type NavVisibilityContext = NavAccessContext & {
  hideBillingEntry?: boolean;
};

export function canAccessNavItem(item: NavItem, context: NavAccessContext): boolean {
  if (item.minRole && !context.hasRole(item.minRole)) return false;
  if (item.module && !context.hasModule(item.module)) return false;
  if (item.flag && !context.flags[item.flag]) return false;
  return true;
}

export function isNavItemVisible(item: NavItem, context: NavVisibilityContext): boolean {
  if (!canAccessNavItem(item, context)) return false;
  if (context.hideBillingEntry && item.path === '/billing') return false;
  return true;
}
