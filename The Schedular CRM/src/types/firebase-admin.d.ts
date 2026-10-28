/**
 * Minimal firebase-admin typings for the UI/test build.
 * The functions package installs the real dependency separately, so we stub
 * the bits we reference to avoid optional-dep build failures in CI.
 */
declare module "firebase-admin" {
  export const firestore: {
    FieldValue: {
      serverTimestamp(): unknown;
      increment(n: number): unknown;
      arrayUnion(...elements: unknown[]): unknown;
      arrayRemove(...elements: unknown[]): unknown;
      delete(): unknown;
    };
    Timestamp: {
      now(): { toDate(): Date };
      fromDate(date: Date): { toDate(): Date };
    };
  };
}
