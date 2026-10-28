import { describe, expect, it } from 'vitest';

import { getOnboardingRedirect } from './OnboardingGuard';

describe('OnboardingGuard redirect logic', () => {
  it('sends users to onboarding when needed and off-route', () => {
    expect(getOnboardingRedirect({ needsOnboarding: true, pathname: '/dashboard' })).toBe(
      '/onboarding',
    );
  });

  it('sends users to dashboard when onboarding is complete but they visit onboarding', () => {
    expect(getOnboardingRedirect({ needsOnboarding: false, pathname: '/onboarding' })).toBe(
      '/dashboard',
    );
  });

  it('returns null when already on onboarding and still needs onboarding', () => {
    expect(getOnboardingRedirect({ needsOnboarding: true, pathname: '/onboarding' })).toBeNull();
  });

  it('allows success page when onboarding is complete', () => {
    expect(getOnboardingRedirect({ needsOnboarding: false, pathname: '/onboarding/success' })).toBeNull();
  });

  it('redirects to onboarding if user needs onboarding but visits success page', () => {
    expect(getOnboardingRedirect({ needsOnboarding: true, pathname: '/onboarding/success' })).toBeNull();
  });
});
