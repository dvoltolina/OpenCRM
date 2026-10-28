import type { FeatureFlags } from '../types/models';

const DEFAULT_DEMO_HOSTS = ['admin.example.com'];

export function parseDemoHosts(value?: string): string[] {
  return (value || '')
    .split(',')
    .map((host) => host.trim().toLowerCase())
    .filter(Boolean);
}

export function isDemoHostname(hostname: string, demoHosts: string[]): boolean {
  const normalizedHostname = hostname.trim().toLowerCase();
  if (!normalizedHostname) {
    return false;
  }

  return demoHosts.includes(normalizedHostname);
}

export function resolveDemoMode(options: {
  hostname: string;
  hasDemoFlag: boolean;
  hasDemoFirebaseConfig: boolean;
  demoHosts: string[];
}): boolean {
  if (options.hasDemoFlag) {
    return true;
  }

  if (!options.hasDemoFirebaseConfig) {
    return false;
  }

  return isDemoHostname(options.hostname, options.demoHosts);
}

function readCurrentHostname(): string {
  if (typeof window === 'undefined') {
    return '';
  }

  return window.location.hostname || '';
}

export const DEMO_BUSINESS_ID = import.meta.env.VITE_DEMO_BUSINESS_ID || 'demo-business-001';
export const DEMO_USER_ID = 'demo-user-001';
export const DEMO_USER_EMAIL = import.meta.env.VITE_DEMO_USER_EMAIL || 'demo@example.com';
export const DEMO_USER_NAME = import.meta.env.VITE_DEMO_USER_NAME || 'Demo Owner';
export const DEMO_SIGN_UP_URL =
  import.meta.env.VITE_DEMO_SIGN_UP_URL ||
  import.meta.env.VITE_APP_URL ||
  '/signup';

export const DEMO_BANNER_MESSAGE =
  'You are viewing a demo with sample data. No changes will be saved.';
export const DEMO_DISABLED_ACTION_MESSAGE = 'This action is disabled in demo mode.';
export const DEMO_ACTION_BLOCKED_EVENT = 'admin:demo-action-blocked';

export const demoFirebaseConfig = {
  apiKey: import.meta.env.VITE_DEMO_FIREBASE_API_KEY || '',
  authDomain: import.meta.env.VITE_DEMO_FIREBASE_AUTH_DOMAIN || '',
  projectId: import.meta.env.VITE_DEMO_FIREBASE_PROJECT_ID || '',
  storageBucket: import.meta.env.VITE_DEMO_FIREBASE_STORAGE_BUCKET || '',
  messagingSenderId: import.meta.env.VITE_DEMO_FIREBASE_MESSAGING_SENDER_ID || '',
  appId: import.meta.env.VITE_DEMO_FIREBASE_APP_ID || '',
};

export const demoHosts = (() => {
  const configuredHosts = parseDemoHosts(import.meta.env.VITE_DEMO_HOSTS);
  return configuredHosts.length ? configuredHosts : DEFAULT_DEMO_HOSTS;
})();

export const hasDemoFirebaseConfig = [
  demoFirebaseConfig.apiKey,
  demoFirebaseConfig.authDomain,
  demoFirebaseConfig.projectId,
  demoFirebaseConfig.storageBucket,
  demoFirebaseConfig.messagingSenderId,
  demoFirebaseConfig.appId,
].every(Boolean);

export const isDemoMode = resolveDemoMode({
  hostname: readCurrentHostname(),
  hasDemoFlag: import.meta.env.VITE_DEMO_MODE === 'true',
  hasDemoFirebaseConfig,
  demoHosts,
});

export const demoFeatureFlagOverrides: FeatureFlags = {
  enableCalendarSync: false,
  enableTelehealth: false,
  enableAutomatedReminders: true,
  enablePayments: false,
  enableReporting: true,
  enableImportExport: false,
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

export interface DemoActionBlockedDetail {
  action?: string;
  message: string;
  timestamp: number;
}

export class DemoActionBlockedError extends Error {
  code = 'demo/read-only';

  constructor(message = DEMO_DISABLED_ACTION_MESSAGE) {
    super(message);
    this.name = 'DemoActionBlockedError';
  }
}

export function isDemoActionBlockedError(error: unknown): error is DemoActionBlockedError {
  return error instanceof DemoActionBlockedError;
}

export function notifyDemoActionBlocked(
  detail: Partial<Omit<DemoActionBlockedDetail, 'timestamp'>> = {},
): DemoActionBlockedError {
  const error = new DemoActionBlockedError(detail.message || DEMO_DISABLED_ACTION_MESSAGE);

  if (typeof window !== 'undefined') {
    const event = new CustomEvent<DemoActionBlockedDetail>(DEMO_ACTION_BLOCKED_EVENT, {
      detail: {
        action: detail.action,
        message: error.message,
        timestamp: Date.now(),
      },
    });
    window.dispatchEvent(event);
  }

  return error;
}

export function assertDemoMutationAllowed(action?: string, message?: string): void {
  if (!isDemoMode) {
    return;
  }

  throw notifyDemoActionBlocked({
    action,
    message,
  });
}
