import { describe, expect, it } from 'vitest';

import { canAccessNavItem, isNavItemVisible, navItems } from './nav';
import type { FeatureFlags, ModuleAccess } from './types/models';
import type { RoleRequirement } from './types/auth';

const enabledFlags: FeatureFlags = {
  enableCalendarSync: true,
  enableTelehealth: true,
  enableAutomatedReminders: true,
  enablePayments: true,
  enableReporting: true,
  enableImportExport: true,
  enableAutomation: true,
  enableWaitlist: true,
  enableLocations: true,
  enableResources: true,
  enableResourceConflicts: true,
  enableClientPortal: true,
  enableSessionNotes: true,
  enableMarketing: true,
  enableIntakeBuilder: true,
  waitlistNotifyChannels: ['sms', 'email'],
};

function buildAccessContext(input?: {
  hasRole?: (required: RoleRequirement) => boolean;
  hasModule?: (module?: keyof ModuleAccess) => boolean;
  flags?: FeatureFlags;
}) {
  return {
    hasRole: input?.hasRole ?? (() => true),
    hasModule: input?.hasModule ?? (() => true),
    flags: input?.flags ?? enabledFlags,
  };
}

describe('nav runtime access', () => {
  it('includes production admin routes regardless of demo mode', () => {
    const paths = navItems.map((item) => item.path);
    expect(paths).toEqual(
      expect.arrayContaining([
        '/calendar',
        '/clients',
        '/appointments',
        '/group-sessions',
        '/waitlist',
        '/communications',
        '/marketing',
        '/reports',
      ]),
    );
  });

  it('respects module access when deciding route visibility', () => {
    const calendarNav = navItems.find((item) => item.path === '/calendar');
    expect(calendarNav).toBeDefined();
    expect(
      canAccessNavItem(
        calendarNav!,
        buildAccessContext({
          hasModule: (module) => module !== 'calendar',
        }),
      ),
    ).toBe(false);
  });

  it('respects role requirements for admin-only surfaces', () => {
    const intakeNav = navItems.find((item) => item.path === '/intake-builder');
    expect(intakeNav).toBeDefined();
    expect(
      canAccessNavItem(
        intakeNav!,
        buildAccessContext({
          hasRole: (required) =>
            Array.isArray(required) ? !required.includes('admin') : required !== 'admin',
        }),
      ),
    ).toBe(false);
  });

  it('respects feature flags for feature-gated surfaces', () => {
    const marketingNav = navItems.find((item) => item.path === '/marketing');
    expect(marketingNav).toBeDefined();
    expect(
      canAccessNavItem(
        marketingNav!,
        buildAccessContext({
          flags: { ...enabledFlags, enableMarketing: false },
        }),
      ),
    ).toBe(false);
  });

  it('can hide billing nav entry without changing core access checks', () => {
    const billingNav = navItems.find((item) => item.path === '/billing');
    expect(billingNav).toBeDefined();
    const context = buildAccessContext();
    expect(canAccessNavItem(billingNav!, context)).toBe(true);
    expect(isNavItemVisible(billingNav!, { ...context, hideBillingEntry: true })).toBe(false);
  });
});
