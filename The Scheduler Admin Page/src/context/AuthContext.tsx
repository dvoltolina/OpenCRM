import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  updateProfile,
  signOut as firebaseSignOut,
  sendEmailVerification,
  reload,
  setPersistence,
  browserSessionPersistence,
  type MultiFactorError,
  type User as FirebaseUser,
  getMultiFactorResolver,
  getIdTokenResult,
  multiFactor,
} from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';

import {
  DEMO_BUSINESS_ID,
  DEMO_USER_EMAIL,
  DEMO_USER_ID,
  DEMO_USER_NAME,
  isDemoMode,
  notifyDemoActionBlocked,
} from '../config/demo';
import { getFirebaseAuth, getDb } from '../lib/firebase';
import {
  hasRequiredRole,
  normalizeUserRole,
  type AppUser,
  type AuthState,
  type PendingUser,
  type RoleRequirement,
  type UserRole,
} from '../types/auth';

type AuthContextValue = {
  state: AuthState;
  signIn: (email: string, password: string) => Promise<void>;
  createAccount: (email: string, password: string, displayName: string) => Promise<void>;
  signOut: () => Promise<void>;
  refreshUser: () => Promise<void>;
  sendVerification: () => Promise<void>;
  reloadCurrentUser: () => Promise<void>;
  hasRole: (required: RoleRequirement) => boolean;
  requireRole: (required: RoleRequirement) => void;
  isSuperAdmin: boolean; // From Firebase custom claim - grants cross-tenant ops access
};

const AuthContext = createContext<AuthContextValue | null>(null);

const demoUser: AppUser = {
  uid: DEMO_USER_ID,
  email: DEMO_USER_EMAIL,
  displayName: DEMO_USER_NAME,
  role: 'owner',
  businessId: DEMO_BUSINESS_ID,
  isSuperAdmin: false,
};

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AuthState>(
    isDemoMode ? { status: 'signed_in', user: demoUser } : { status: 'loading' },
  );

  useEffect(() => {
    if (isDemoMode) {
      setState({ status: 'signed_in', user: demoUser });
      return undefined;
    }

    try {
      const auth = getFirebaseAuth();
      const unsubscribe = onAuthStateChanged(auth, async (fbUser) => {
        if (!fbUser) {
          setState({ status: 'signed_out' });
          return;
        }
        try {
          if (!fbUser.emailVerified) {
            setState({ status: 'pending_verification', user: toPendingUser(fbUser) });
            return;
          }
          const appUser = await buildAppUser(fbUser);
          const business = await getBusinessSecurityProfile(appUser.businessId);
          await ensureHipaaSessionPersistence(business);
          const requiresMfa = shouldRequireMfa(business, appUser.role);
          const enrolledFactors = multiFactor(fbUser).enrolledFactors.length;

          if (requiresMfa && enrolledFactors === 0) {
            setState({ status: 'mfa_required', step: 'enroll', user: appUser });
            return;
          }

          setState({ status: 'signed_in', user: appUser });
        } catch (error) {
          console.warn('User profile unavailable, routing to onboarding', error);
          setState({ status: 'pending_profile', user: toPendingUser(fbUser) });
        }
      });
      return unsubscribe;
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Unable to initialize authentication.';
      setState({ status: 'error', error: message });
    }
  }, []);

  const signIn = useCallback(async (email: string, password: string) => {
    if (isDemoMode) {
      throw notifyDemoActionBlocked({
        action: 'sign in',
        message: 'Authentication is bypassed in demo mode. Open the dashboard directly.',
      });
    }

    try {
      await signInWithEmailAndPassword(getFirebaseAuth(), email, password);
    } catch (err) {
      const mfaError = err as MultiFactorError;
      if (mfaError?.code === 'auth/multi-factor-auth-required') {
        const resolver = getMultiFactorResolver(getFirebaseAuth(), mfaError);
        setState({ status: 'mfa_required', step: 'challenge', resolver, email });
        return;
      }
      const message = mfaError instanceof Error ? mfaError.message : 'Unable to sign in.';
      setState({ status: 'error', error: message });
      throw err;
    }
  }, []);

  const createAccount = useCallback(async (email: string, password: string, displayName: string) => {
    if (isDemoMode) {
      throw notifyDemoActionBlocked({
        action: 'create account',
        message: 'Account creation is disabled in demo mode.',
      });
    }

    try {
      const auth = getFirebaseAuth();

      // Create Firebase auth user
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      // Update profile with display name
      if (displayName) {
        await updateProfile(user, { displayName });
      }

      // Kick off email verification for onboarding
      await sendEmailVerification(user, getVerificationActionSettings());
      setState({ status: 'pending_verification', user: toPendingUser(user) });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unable to create account.';
      setState({ status: 'error', error: message });
      throw err;
    }
  }, []);

  const sendVerification = useCallback(async () => {
    if (isDemoMode) {
      return;
    }
    const current = getFirebaseAuth().currentUser;
    if (!current) {
      throw new Error('No authenticated user found.');
    }
    await sendEmailVerification(current, getVerificationActionSettings());
    setState((prev) =>
      prev.status === 'pending_verification' ? { ...prev, user: toPendingUser(current) } : prev,
    );
  }, []);

  const reloadCurrentUser = useCallback(async () => {
    if (isDemoMode) {
      setState({ status: 'signed_in', user: demoUser });
      return;
    }
    const current = getFirebaseAuth().currentUser;
    if (!current) {
      setState({ status: 'signed_out' });
      return;
    }
    await reload(current);
    if (!current.emailVerified) {
      setState({ status: 'pending_verification', user: toPendingUser(current) });
      return;
    }
    setState((prev) =>
      prev.status === 'pending_profile' || prev.status === 'pending_verification'
        ? { status: 'pending_profile', user: toPendingUser(current) }
        : prev,
    );
  }, []);

  const signOut = useCallback(async () => {
    if (isDemoMode) {
      setState({ status: 'signed_in', user: demoUser });
      return;
    }
    await firebaseSignOut(getFirebaseAuth());
    setState({ status: 'signed_out' });
  }, []);

  const refreshUser = useCallback(async () => {
    if (isDemoMode) {
      setState({ status: 'signed_in', user: demoUser });
      return;
    }
    try {
      const current = getFirebaseAuth().currentUser;
      if (!current) {
        setState({ status: 'signed_out' });
        return;
      }
      await reload(current);
      if (!current.emailVerified) {
        setState({ status: 'pending_verification', user: toPendingUser(current) });
        return;
      }
      try {
        const appUser = await buildAppUser(current);
        const business = await getBusinessSecurityProfile(appUser.businessId);
        await ensureHipaaSessionPersistence(business);
        const requiresMfa = shouldRequireMfa(business, appUser.role);
        const enrolledFactors = multiFactor(current).enrolledFactors.length;

        if (requiresMfa && enrolledFactors === 0) {
          setState({ status: 'mfa_required', step: 'enroll', user: appUser });
          return;
        }
        setState({ status: 'signed_in', user: appUser });
      } catch (error) {
        console.warn('Pending user profile during refresh', error);
        setState({ status: 'pending_profile', user: toPendingUser(current) });
      }
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Unable to refresh authenticated user.';
      setState({ status: 'error', error: message });
    }
  }, []);

  const hasRole = useCallback(
    (required: RoleRequirement) => {
      if (state.status !== 'signed_in') {
        return false;
      }
      return hasRequiredRole(state.user.role, required);
    },
    [state],
  );

  const requireRole = useCallback(
    (required: RoleRequirement) => {
      if (!hasRole(required)) {
        throw new Error('Insufficient role for this action.');
      }
    },
    [hasRole],
  );

  const isSuperAdmin = useMemo(() => {
    return state.status === 'signed_in' && state.user.isSuperAdmin === true;
  }, [state]);

  const value = useMemo<AuthContextValue>(
    () => ({
      state,
      signIn,
      createAccount,
      signOut,
      refreshUser,
      sendVerification,
      reloadCurrentUser,
      hasRole,
      requireRole,
      isSuperAdmin,
    }),
    [
      state,
      signIn,
      createAccount,
      signOut,
      refreshUser,
      sendVerification,
      reloadCurrentUser,
      hasRole,
      requireRole,
      isSuperAdmin,
    ],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return ctx;
}

function toPendingUser(fbUser: FirebaseUser): PendingUser {
  return {
    uid: fbUser.uid,
    email: fbUser.email,
    displayName: fbUser.displayName,
    emailVerified: fbUser.emailVerified,
  };
}

function getVerificationActionSettings() {
  if (typeof window === 'undefined') return undefined;
  return {
    url: `${window.location.origin}/verify-email`,
    handleCodeInApp: true,
  };
}

async function ensureHipaaSessionPersistence(business: {
  requiresHipaaCompliance: boolean;
  mfaEnabled: boolean;
}) {
  if (!business.requiresHipaaCompliance && !business.mfaEnabled) return;
  try {
    await setPersistence(getFirebaseAuth(), browserSessionPersistence);
  } catch (error) {
    console.warn('Failed to enforce session persistence for HIPAA business', error);
  }
}

async function buildAppUser(fbUser: FirebaseUser): Promise<AppUser> {
  // Force refresh to pick up latest claims (important after Admin SDK updates)
  const tokenResult = await getIdTokenResult(fbUser, true);
  const claims = tokenResult?.claims ?? {};

  // Check for super-admin claim (cross-tenant ops access)
  const isSuperAdmin = claims.superAdmin === true;

  const claimedBusinessId =
    typeof claims.businessId === 'string' ? claims.businessId : undefined;
  const claimedRoleRaw = typeof claims.role === 'string' ? claims.role : undefined;
  const claimedRole = normalizeUserRole(claimedRoleRaw);
  const claimedProviderId =
    typeof claims.providerId === 'string' ? claims.providerId : undefined;
  const claimedClientId =
    typeof claims.clientId === 'string' ? claims.clientId : undefined;

  // Super-admin without tenant context - allowed to operate cross-tenant
  if (isSuperAdmin && !claimedBusinessId) {
    return {
      uid: fbUser.uid,
      email: fbUser.email,
      displayName: fbUser.displayName ?? fbUser.email,
      role: 'owner' as UserRole, // Treat as owner for role hierarchy checks
      businessId: '', // Empty - will use ops portal for tenant selection
      providerId: claimedProviderId,
      clientId: claimedClientId,
      isSuperAdmin: true,
    };
  }

  if (claimedBusinessId && claimedRole) {
    return {
      uid: fbUser.uid,
      email: fbUser.email,
      displayName: fbUser.displayName ?? fbUser.email,
      role: claimedRole,
      businessId: claimedBusinessId,
      providerId: claimedProviderId,
      clientId: claimedClientId,
      isSuperAdmin,
    };
  }

  // Business/user role lookup: expect a lightweight profile document.
  const db = getDb();
  const profileRef = doc(db, 'users', fbUser.uid);
  const snap = await getDoc(profileRef);
  if (!snap.exists()) {
    throw new Error('User profile not found. Contact an administrator.');
  }
  const data = snap.data() as {
    role?: string;
    businessId?: string;
    displayName?: string;
    providerId?: string;
    clientId?: string;
  };

  if (!data.businessId && !isSuperAdmin) {
    throw new Error('User profile missing businessId. Access denied.');
  }

  const role: UserRole = normalizeUserRole(data.role) ?? 'staff';

  return {
    uid: fbUser.uid,
    email: fbUser.email,
    displayName: data.displayName ?? fbUser.displayName ?? fbUser.email,
    role,
    businessId: data.businessId ?? '',
    providerId: data.providerId,
    clientId: data.clientId,
    isSuperAdmin,
  };
}

async function getBusinessSecurityProfile(businessId: string) {
  const db = getDb();
  const businessRef = doc(db, 'businesses', businessId);
  const snap = await getDoc(businessRef);
  if (!snap.exists()) {
    throw new Error('Business profile not found. Access denied.');
  }
  const data = snap.data() as
    | {
        requiresHipaaCompliance?: boolean;
        mfaEnabled?: boolean;
      }
    | undefined;

  return {
    requiresHipaaCompliance: data?.requiresHipaaCompliance ?? false,
    mfaEnabled: data?.mfaEnabled ?? false,
  };
}

function shouldRequireMfa(
  business: { requiresHipaaCompliance: boolean; mfaEnabled: boolean },
  role: UserRole,
) {
  const isPrivileged = role === 'owner' || role === 'admin';
  return isPrivileged && (business.requiresHipaaCompliance || business.mfaEnabled);
}
