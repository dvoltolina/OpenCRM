import { describe, expect, it } from 'vitest';

import { isDemoHostname, parseDemoHosts, resolveDemoMode } from './demo';

describe('admin demo config', () => {
  it('parses configured demo hostnames', () => {
    expect(
      parseDemoHosts(' admin.example.com, demo.example.com ,,CRM.example.com ')
    ).toEqual([
      'admin.example.com',
      'demo.example.com',
      'crm.example.com',
    ]);
  });

  it('matches the configured admin demo host', () => {
    expect(isDemoHostname('ADMIN.example.com', ['admin.example.com'])).toBe(true);
    expect(isDemoHostname('app.example.com', ['admin.example.com'])).toBe(false);
  });

  it('requires demo firebase config for hostname-driven demo mode', () => {
    expect(
      resolveDemoMode({
        hostname: 'admin.example.com',
        hasDemoFlag: false,
        hasDemoFirebaseConfig: true,
        demoHosts: ['admin.example.com'],
      })
    ).toBe(true);

    expect(
      resolveDemoMode({
        hostname: 'admin.example.com',
        hasDemoFlag: false,
        hasDemoFirebaseConfig: false,
        demoHosts: ['admin.example.com'],
      })
    ).toBe(false);
  });

  it('still honors the explicit demo flag', () => {
    expect(
      resolveDemoMode({
        hostname: 'admin.example.com',
        hasDemoFlag: true,
        hasDemoFirebaseConfig: false,
        demoHosts: ['admin.example.com'],
      })
    ).toBe(true);
  });
});
