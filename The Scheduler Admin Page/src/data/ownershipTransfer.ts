/**
 * Ownership Transfer Data Layer
 * Handles the transfer of business ownership from current owner to an existing admin.
 *
 * Security:
 * - Requires password re-authentication
 * - Validates new owner has admin role
 * - Uses Cloud Function for atomic updates (with Firestore fallback)
 * - Logs all transfers in audit log (NO PHI)
 */

import {
  doc,
  getDoc,
  updateDoc,
  writeBatch,
  serverTimestamp,
  type Firestore,
} from 'firebase/firestore';
import {
  EmailAuthProvider,
  reauthenticateWithCredential,
} from 'firebase/auth';
import { httpsCallable } from 'firebase/functions';

import { assertDemoMutationAllowed } from '../config/demo';
import { getDb, getFirebaseAuth, getFunctionsClient } from '../lib/firebase';
import { normalizeUserRole } from '../types/auth';
import { logAuditEvent } from './auditLog';

export interface OwnershipTransferInput {
  businessId: string;
  currentOwnerId: string;
  newOwnerId: string;
  password: string;
}

export interface OwnershipTransferResult {
  success: boolean;
  error?: string;
}

/**
 * Transfers ownership of a business from current owner to a new owner.
 *
 * Process:
 * 1. Re-authenticate current owner with password
 * 2. Verify new owner is currently an admin
 * 3. Call Cloud Function for atomic updates (or fallback to Firestore)
 * 4. Log audit event
 *
 * @param input - Transfer parameters
 * @returns Result object with success status
 */
export async function transferOwnership(
  input: OwnershipTransferInput
): Promise<OwnershipTransferResult> {
  assertDemoMutationAllowed('transfer ownership');
  const { businessId, currentOwnerId, newOwnerId, password } = input;

  try {
    // Step 1: Re-authenticate current owner
    const auth = getFirebaseAuth();
    const currentUser = auth.currentUser;

    if (!currentUser) {
      return {
        success: false,
        error: 'No authenticated user found. Please sign in again.',
      };
    }

    if (currentUser.uid !== currentOwnerId) {
      return {
        success: false,
        error: 'Authentication mismatch. Please sign in as the current owner.',
      };
    }

    if (!currentUser.email) {
      return {
        success: false,
        error: 'User email not found. Re-authentication requires email.',
      };
    }

    // Re-authenticate with password
    const credential = EmailAuthProvider.credential(currentUser.email, password);
    await reauthenticateWithCredential(currentUser, credential);

    // Step 2: Verify new owner is currently an admin on the canonical user profile.
    const db = getDb();
    const newOwnerUserRef = doc(db, 'users', newOwnerId);
    const newOwnerSnap = await getDoc(newOwnerUserRef);

    if (!newOwnerSnap.exists()) {
      return {
        success: false,
        error: 'Selected user was not found in this workspace.',
      };
    }

    const newOwnerData = newOwnerSnap.data();
    if (newOwnerData.businessId !== businessId) {
      return {
        success: false,
        error: 'Selected user must belong to this business.',
      };
    }

    if (normalizeUserRole(newOwnerData.role) !== 'admin') {
      return {
        success: false,
        error: 'Selected user must have Admin role to become owner.',
      };
    }

    // Step 3: Try Cloud Function first, fallback to Firestore
    try {
      await transferViaCloudFunction(input);
    } catch {
      console.warn('Cloud Function transfer failed, using Firestore fallback.');
      await transferViaFirestore(input, db);
    }

    // Step 4: Log audit event (NO PHI)
    await logAuditEvent({
      businessId,
      userId: currentOwnerId,
      actionType: 'securityEvent',
      entityType: 'Business',
      entityId: businessId,
      metadata: {
        action: 'ownership_transferred',
        newOwnerId,
        previousOwnerId: currentOwnerId,
      },
    });

    return { success: true };
  } catch (error) {
    console.error('Ownership transfer failed');

    // Extract user-friendly error message
    let errorMessage = 'Failed to transfer ownership. Please try again.';

    if (error instanceof Error) {
      if (error.message.includes('auth/wrong-password')) {
        errorMessage = 'Incorrect password. Please try again.';
      } else if (error.message.includes('auth/too-many-requests')) {
        errorMessage = 'Too many attempts. Please try again later.';
      } else if (error.message.includes('auth/user-mismatch')) {
        errorMessage = 'Authentication failed. Please sign in again.';
      } else if (error.message.includes('permission-denied')) {
        errorMessage = 'Permission denied. You must be the current owner.';
      } else {
        errorMessage = error.message;
      }
    }

    return {
      success: false,
      error: errorMessage,
    };
  }
}

/**
 * Transfer ownership via Cloud Function (preferred method).
 * Cloud Function ensures atomic updates and custom claims updates.
 */
async function transferViaCloudFunction(input: OwnershipTransferInput): Promise<void> {
  const functions = getFunctionsClient();

  // Call canonical Cloud Function name; Scheduler also exports the legacy alias
  // This function should:
  // 1. Verify current owner's role
  // 2. Update business.ownerId
  // 3. Update old owner's staff role to 'admin'
  // 4. Update new owner's staff role to 'owner'
  // 5. Update custom claims for both users
  // 6. All in a transaction for atomicity

  const transferOwnershipFn = httpsCallable<
    {
      businessId: string;
      newOwnerId: string;
    },
    { success: boolean; error?: string }
  >(functions, 'ownershipTransfer');

  const result = await transferOwnershipFn({
    businessId: input.businessId,
    newOwnerId: input.newOwnerId,
  });

  if (!result.data.success) {
    throw new Error(result.data.error || 'Cloud Function transfer failed');
  }
}

/**
 * Transfer ownership via direct Firestore writes (fallback for development).
 * NOTE: This does NOT update custom claims - users must sign out/in to refresh.
 */
async function transferViaFirestore(
  input: OwnershipTransferInput,
  db: Firestore
): Promise<void> {
  const { businessId, currentOwnerId, newOwnerId } = input;

  // Use batch write for atomicity
  const batch = writeBatch(db);

  // Update business.ownerId
  const businessRef = doc(db, 'businesses', businessId);
  batch.update(businessRef, {
    ownerId: newOwnerId,
    updatedAt: serverTimestamp(),
  });

  const workforceTargets = [
    { path: ['businesses', businessId, 'providers', currentOwnerId], role: 'admin' },
    { path: ['businesses', businessId, 'providers', newOwnerId], role: 'owner' },
    { path: ['businesses', businessId, 'staff', currentOwnerId], role: 'admin' },
    { path: ['businesses', businessId, 'staff', newOwnerId], role: 'owner' },
  ] as const;

  for (const target of workforceTargets) {
    const workforceRef = doc(db, ...target.path);
    const workforceSnap = await getDoc(workforceRef);
    if (!workforceSnap.exists()) {
      continue;
    }

    batch.update(workforceRef, {
      role: target.role,
      updatedAt: serverTimestamp(),
    });
  }

  // Update user documents
  const oldOwnerUserRef = doc(db, 'users', currentOwnerId);
  batch.update(oldOwnerUserRef, {
    role: 'admin',
    updatedAt: serverTimestamp(),
  });

  const newOwnerUserRef = doc(db, 'users', newOwnerId);
  batch.update(newOwnerUserRef, {
    role: 'owner',
    updatedAt: serverTimestamp(),
  });

  await batch.commit();

  // Note: Custom claims are NOT updated in fallback mode.
  // Users will need to sign out and sign back in to refresh claims.
  console.warn(
    'Firestore fallback used: Custom claims NOT updated. Users must sign out/in to refresh.'
  );
}

/**
 * Validates that a user can initiate ownership transfer.
 *
 * @param businessId - Business ID
 * @param userId - User ID attempting transfer
 * @returns True if user is current owner
 */
export async function canTransferOwnership(
  businessId: string,
  userId: string
): Promise<boolean> {
  try {
    const db = getDb();
    const businessRef = doc(db, 'businesses', businessId);
    const businessSnap = await getDoc(businessRef);

    if (!businessSnap.exists()) {
      return false;
    }

    const businessData = businessSnap.data();
    return businessData.ownerId === userId;
  } catch {
    console.error('Failed to check ownership transfer permission');
    return false;
  }
}
