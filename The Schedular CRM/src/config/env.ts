// Environment configuration for Firebase
// Copy from your .env file or environment variables

import { demoFirebaseConfig, isDemoMode } from './demo';

const productionFirebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || '',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || '',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || '',
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || '',
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || '',
  appId: import.meta.env.VITE_FIREBASE_APP_ID || '',
};

export const firebaseConfig = isDemoMode ? demoFirebaseConfig : productionFirebaseConfig;

// Validate required config
export function validateFirebaseConfig(): boolean {
  const required = ['apiKey', 'authDomain', 'projectId'];
  const missing = required.filter(
    (key) => !firebaseConfig[key as keyof typeof firebaseConfig]
  );

  if (missing.length > 0) {
    console.warn(
      `Missing Firebase config keys: ${missing.join(', ')}. ` +
        `Create a .env file with ${isDemoMode ? 'VITE_DEMO_FIREBASE_*' : 'VITE_FIREBASE_*'} variables.`
    );
    return false;
  }
  return true;
}
