import { describe, expect, it } from 'vitest';

import {
  hasDemoSearchFlag,
  isDemoHostname,
  isDemoPathname,
  parseDemoHosts,
  resolveDemoMode,
} from './demo';

describe('demo config', () => {
  it('parses demo hosts from comma-separated env values', () => {
    expect(
      parseDemoHosts(' crm.example.com, demo.example.com ,,ADMIN.example.com ')
    ).toEqual([
      'crm.example.com',
      'demo.example.com',
      'admin.example.com',
    ]);
  });

  it('matches configured demo hostnames case-insensitively', () => {
    expect(isDemoHostname('CRM.example.com', ['crm.example.com'])).toBe(true);
    expect(isDemoHostname('app.example.com', ['crm.example.com'])).toBe(false);
  });

  it('matches explicit demo URL paths and query flags', () => {
    expect(isDemoPathname('/demo')).toBe(true);
    expect(isDemoPathname('/demo/pipeline')).toBe(true);
    expect(isDemoPathname('/dashboard')).toBe(false);
    expect(hasDemoSearchFlag('?demo=true')).toBe(true);
    expect(hasDemoSearchFlag('?demo=1')).toBe(true);
    expect(hasDemoSearchFlag('?mode=demo')).toBe(true);
    expect(hasDemoSearchFlag('?demo=false')).toBe(false);
  });

  it('enables demo mode for configured demo hostnames', () => {
    expect(
      resolveDemoMode({
        hostname: 'crm.example.com',
        hasDemoFlag: false,
        demoHosts: ['crm.example.com'],
      })
    ).toBe(true);

    expect(
      resolveDemoMode({
        hostname: 'app.example.com',
        hasDemoFlag: false,
        demoHosts: ['crm.example.com'],
      })
    ).toBe(false);
  });

  it('keeps production hostnames in production mode unless configured or explicitly requested', () => {
    expect(
      resolveDemoMode({
        hostname: 'crm.example.com',
        pathname: '/login',
        search: '',
        hasDemoFlag: false,
        demoHosts: [],
      })
    ).toBe(false);

    expect(
      resolveDemoMode({
        hostname: 'crm.example.com',
        pathname: '/demo',
        search: '',
        hasDemoFlag: false,
        demoHosts: [],
      })
    ).toBe(true);
  });

  it('always honors the explicit demo flag', () => {
    expect(
      resolveDemoMode({
        hostname: 'app.example.com',
        hasDemoFlag: true,
        demoHosts: ['crm.example.com'],
      })
    ).toBe(true);
  });
});
