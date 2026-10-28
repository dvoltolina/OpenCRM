const DEFAULT_DEMO_HOSTS: string[] = [];
const DEMO_PATH_PREFIX = '/demo';
const DEMO_FIREBASE_PLACEHOLDERS = new Set([
  'demo-public-api-key',
  'demo-project.firebaseapp.com',
  'demo-project-id',
  'demo-project.appspot.com',
  '1234567890',
  '',
]);

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

export function isDemoPathname(pathname: string): boolean {
  const normalizedPathname = pathname.trim().toLowerCase();
  return (
    normalizedPathname === DEMO_PATH_PREFIX ||
    normalizedPathname.startsWith(`${DEMO_PATH_PREFIX}/`)
  );
}

export function hasDemoSearchFlag(search: string): boolean {
  const trimmedSearch = search.trim();
  if (!trimmedSearch) {
    return false;
  }

  const params = new URLSearchParams(
    trimmedSearch.startsWith('?') ? trimmedSearch : `?${trimmedSearch}`
  );
  const demoValue = params.get('demo') || params.get('mode');
  return demoValue === '1' || demoValue === 'true' || demoValue === 'demo';
}

export function resolveDemoMode(options: {
  hostname: string;
  hasDemoFlag: boolean;
  demoHosts: string[];
  pathname?: string;
  search?: string;
}): boolean {
  if (options.hasDemoFlag) {
    return true;
  }

  if (isDemoPathname(options.pathname || '') || hasDemoSearchFlag(options.search || '')) {
    return true;
  }

  return isDemoHostname(options.hostname, options.demoHosts);
}

function readCurrentLocation(): { hostname: string; pathname: string; search: string } {
  if (typeof window === 'undefined') {
    return { hostname: '', pathname: '', search: '' };
  }

  return {
    hostname: window.location.hostname || '',
    pathname: window.location.pathname || '',
    search: window.location.search || '',
  };
}

export const DEMO_BUSINESS_ID = import.meta.env.VITE_DEMO_BUSINESS_ID || 'demo-business-001';
export const DEMO_USER_ID = 'demo-user-001';
export const DEMO_USER_EMAIL = import.meta.env.VITE_DEMO_USER_EMAIL || 'owner@demo.example.com';
export const DEMO_USER_NAME = import.meta.env.VITE_DEMO_USER_NAME || 'Avery Demo';
export const DEMO_SIGN_UP_URL =
  import.meta.env.VITE_DEMO_SIGN_UP_URL ||
  import.meta.env.VITE_APP_URL ||
  '/';

export const DEMO_BANNER_MESSAGE =
  'You are viewing a demo with sample data. No changes will be saved.';
export const DEMO_DISABLED_ACTION_MESSAGE = 'This action is disabled in demo mode.';
export const DEMO_ACTION_BLOCKED_EVENT = 'crm:demo-action-blocked';

export const demoFirebaseConfig = {
  apiKey: import.meta.env.VITE_DEMO_FIREBASE_API_KEY || '',
  authDomain: import.meta.env.VITE_DEMO_FIREBASE_AUTH_DOMAIN || '',
  projectId: import.meta.env.VITE_DEMO_FIREBASE_PROJECT_ID || '',
  storageBucket: import.meta.env.VITE_DEMO_FIREBASE_STORAGE_BUCKET || '',
  messagingSenderId: import.meta.env.VITE_DEMO_FIREBASE_MESSAGING_SENDER_ID || '',
  appId: import.meta.env.VITE_DEMO_FIREBASE_APP_ID || '',
};

function hasConfiguredDemoValue(value: string): boolean {
  const trimmed = value.trim();
  return Boolean(trimmed) && !DEMO_FIREBASE_PLACEHOLDERS.has(trimmed);
}

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
].every(hasConfiguredDemoValue);

export const isDemoMode = resolveDemoMode({
  ...readCurrentLocation(),
  hasDemoFlag: import.meta.env.VITE_DEMO_MODE === 'true',
  demoHosts,
});

export const usesLocalDemoData = isDemoMode && !hasDemoFirebaseConfig;

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

export function notifyDemoActionBlocked(
  detail: Partial<Omit<DemoActionBlockedDetail, 'timestamp'>> = {}
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
