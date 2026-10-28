function readEnv(key: string): string {
  const metaEnv = typeof import.meta !== 'undefined' ? (import.meta as any).env : undefined;
  const processEnv = typeof process !== 'undefined' ? process.env : undefined;
  const value = metaEnv?.[key] ?? processEnv?.[key];
  return typeof value === 'string' ? value.trim() : '';
}

function resolveProjectId(): string {
  const isDemoMode = readEnv('VITE_DEMO_MODE') === 'true';
  const primaryProjectId = isDemoMode ?
    readEnv('VITE_DEMO_FIREBASE_PROJECT_ID') :
    readEnv('VITE_FIREBASE_PROJECT_ID');

  return primaryProjectId || readEnv('VITE_FIREBASE_PROJECT_ID') || readEnv('VITE_DEMO_FIREBASE_PROJECT_ID');
}

export function getFunctionsBaseUrl(): string {
  const configured = readEnv('VITE_FUNCTIONS_BASE_URL');
  if (configured) {
    return configured.replace(/\/+$/, '');
  }

  const projectId = resolveProjectId();
  return projectId ? `https://us-central1-${projectId}.cloudfunctions.net` : '';
}

export function hasFunctionsBaseUrl(): boolean {
  return Boolean(getFunctionsBaseUrl());
}
