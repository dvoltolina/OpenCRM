/**
 * Firebase Admin initialization module.
 *
 * This module must be imported FIRST in any file that uses Firebase Admin SDK.
 * It ensures Firebase is initialized before any services are accessed.
 */

import {initializeApp, getApps, getApp as getFirebaseApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";
import {getAuth} from "firebase-admin/auth";

// Initialize Firebase Admin if not already initialized
if (getApps().length === 0) {
  initializeApp();
}

// Export initialized services
export const db = getFirestore();
export const storage = getStorage();
export const auth = getAuth();
export const app = getFirebaseApp();

// Re-export commonly used types and functions
export {FieldValue, Timestamp} from "firebase-admin/firestore";
