import {
  collection,
  doc,
  getDocs,
  query,
  setDoc,
  Timestamp,
  where,
  writeBatch,
} from 'firebase/firestore';

import { assertDemoMutationAllowed } from '../config/demo';
import { getDb } from '../lib/firebase';
import type { BackupCode } from '../types/models';

export function generateBackupCodes(count: number = 10): string[] {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const codes: string[] = [];
  while (codes.length < count) {
    let code = '';
    for (let i = 0; i < 10; i += 1) {
      const idx = Math.floor(Math.random() * alphabet.length);
      code += alphabet[idx];
      if (i === 3 || i === 7) {
        code += '-';
      }
    }
    codes.push(code);
  }
  return codes;
}

async function hashString(value: string): Promise<string> {
  const subtle = globalThis.crypto?.subtle;
  if (!subtle) {
    throw new Error('Secure hashing is unavailable in this browser; backup codes cannot be generated.');
  }
  const encoded = new TextEncoder().encode(value);
  const hashBuffer = await subtle.digest('SHA-256', encoded);
  return Array.from(new Uint8Array(hashBuffer))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

export async function saveBackupCodes(
  businessId: string,
  userId: string,
  codes: string[],
): Promise<void> {
  assertDemoMutationAllowed('save MFA backup codes');
  if (!businessId) throw new Error('businessId is required to store backup codes');
  if (!userId) throw new Error('userId is required to store backup codes');

  const db = getDb();
  const batch = writeBatch(db);
  // Aligns with deployed Function mfaVerifyBackupCode: users/{uid}/mfaBackupCodes
  const codesCollectionRef = collection(db, 'users', userId, 'mfaBackupCodes');

  // Clear existing codes first by deleting old collection
  const existingCodes = await getDocs(codesCollectionRef);
  existingCodes.forEach((docSnap) => {
    batch.delete(docSnap.ref);
  });

  // Create new backup codes
  for (const code of codes) {
    const codeHash = await hashString(code);
    const codeDocRef = doc(codesCollectionRef);
    const backupCode: BackupCode = {
      id: codeDocRef.id,
      codeHash,
      usedAt: null,
      createdAt: Timestamp.now(),
    };
    batch.set(codeDocRef, backupCode);
  }

  await batch.commit();
}

export async function verifyBackupCode(
  businessId: string,
  userId: string,
  code: string,
): Promise<boolean> {
  assertDemoMutationAllowed('use MFA backup code');
  if (!businessId || !userId || !code) return false;

  const db = getDb();
  const codeHash = await hashString(code);

  // Find code matching hash and not yet used
  const codesRef = collection(db, 'users', userId, 'mfaBackupCodes');
  const q = query(codesRef, where('codeHash', '==', codeHash), where('usedAt', '==', null));
  const snapshot = await getDocs(q);

  if (snapshot.empty) {
    return false;
  }

  // Mark the code as used
  const codeDoc = snapshot.docs[0];
  await setDoc(
    codeDoc.ref,
    {
      usedAt: Timestamp.now(),
    },
    { merge: true },
  );

  return true;
}
