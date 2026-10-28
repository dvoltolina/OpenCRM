import { demoFirebaseConfig, isDemoMode } from './demo';

/**
 * Typed environment accessors. Populate these via Vite env vars.
 */
const productionEnv = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY as string | undefined,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN as string | undefined,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID as string | undefined,
  appId: import.meta.env.VITE_FIREBASE_APP_ID as string | undefined,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID as string | undefined,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET as string | undefined,
};

export const firebaseEnv = isDemoMode ? demoFirebaseConfig : productionEnv;

export function assertFirebaseEnv() {
  const missing = Object.entries(firebaseEnv)
    .filter(([, value]) => !value)
    .map(([key]) => key);
  if (missing.length) {
    throw new Error(
      `Missing Firebase env vars: ${missing.join(', ')}. ` +
        `Expected ${isDemoMode ? 'VITE_DEMO_FIREBASE_*' : 'VITE_FIREBASE_*'} values.`,
    );
  }
}
