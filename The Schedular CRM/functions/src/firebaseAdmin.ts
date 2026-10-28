/**
 * Firebase Admin SDK helpers
 * Centralized access to Firebase Admin features
 *
 * Note: When imported from tests in the main CRM project, firebase-admin
 * may not be available. We provide mock implementations for that case.
 */

let adminModule: typeof import("firebase-admin") | null = null;

try {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  adminModule = require("firebase-admin");
} catch {
  // firebase-admin not available (e.g., when imported from main CRM project tests)
}

// Export FieldValue - use real admin if available, otherwise provide mock
export const FieldValue = adminModule?.firestore?.FieldValue ?? {
  serverTimestamp: () => new Date(),
  increment: (n: number) => n,
  arrayUnion: (...elements: unknown[]) => elements,
  arrayRemove: (...elements: unknown[]) => elements,
  delete: () => null,
};

export const Timestamp = adminModule?.firestore?.Timestamp ?? {
  now: () => ({ toDate: () => new Date() }),
  fromDate: (date: Date) => ({ toDate: () => date }),
};
