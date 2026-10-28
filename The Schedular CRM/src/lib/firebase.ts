import { initializeApp, getApps } from 'firebase/app';
import type { FirebaseApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import type { Auth } from 'firebase/auth';
import {
  getFirestore,
  initializeFirestore,
  memoryLocalCache,
  persistentLocalCache,
  persistentMultipleTabManager,
} from 'firebase/firestore';
import type { Firestore } from 'firebase/firestore';
import { getAnalytics, isSupported } from 'firebase/analytics';
import type { Analytics } from 'firebase/analytics';
import { firebaseConfig, validateFirebaseConfig } from '../config/env';
import { isDemoMode } from '../config/demo';

let app: FirebaseApp | null = null;
let auth: Auth | null = null;
let db: Firestore | null = null;
let analytics: Analytics | null = null;

export function initializeFirebase(): {
  app: FirebaseApp;
  auth: Auth;
  db: Firestore;
  analytics: Analytics | null;
} | null {
  if (!validateFirebaseConfig()) {
    console.warn('Firebase not initialized due to missing configuration');
    return null;
  }

  if (getApps().length === 0) {
    app = initializeApp(firebaseConfig);
  } else {
    app = getApps()[0];
  }

  auth = getAuth(app);
  if (!db) {
    try {
      db = initializeFirestore(app, {
        localCache:
          typeof window === 'undefined'
            ? memoryLocalCache()
            : persistentLocalCache({
                tabManager: persistentMultipleTabManager(),
              }),
      });
    } catch (error) {
      db = getFirestore(app);
      if (error instanceof Error && !/already been initialized|already started/i.test(error.message)) {
        console.warn('[offline] Firestore cache initialization fell back to defaults.', error);
      }
    }
  }
  
  if (!isDemoMode) {
    // Initialize Analytics (Client-side only)
    isSupported().then((yes) => {
      if (yes && app) {
        analytics = getAnalytics(app);
      }
    });
  }

  return { app, auth, db, analytics };
}

export function getFirebaseAuth(): Auth | null {
  if (!auth) {
    const result = initializeFirebase();
    return result?.auth || null;
  }
  return auth;
}

export function getFirebaseDb(): Firestore | null {
  if (!db) {
    const result = initializeFirebase();
    return result?.db || null;
  }
  return db;
}

export function getFirebaseAnalytics(): Analytics | null {
  // Analytics might not be initialized immediately due to async check
  return analytics;
}

export { app, auth, db, analytics };
