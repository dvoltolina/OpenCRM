import { createContext, useContext, useEffect, useState } from 'react';
import type { ReactNode } from 'react';
import {
  browserSessionPersistence,
  getIdTokenResult,
  getMultiFactorResolver,
  onAuthStateChanged,
  setPersistence,
  signOut as firebaseSignOut,
  signInWithEmailAndPassword,
} from 'firebase/auth';
import type { MultiFactorError, MultiFactorResolver, User } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { getFirebaseAuth, getFirebaseDb } from '../lib/firebase';
import { USERS_COLLECTION, businessPath } from '../lib/collections';
import { normalizeUserRole, type CRMUser, type UserRole } from '../types/models';
import {
  sanitizeTeamIds,
  setDefaultManagedTeamIds,
  setDefaultTeamIds,
} from '../lib/security-context';
import {
  DEMO_BUSINESS_ID,
  DEMO_USER_EMAIL,
  DEMO_USER_ID,
  DEMO_USER_NAME,
  isDemoMode,
  usesLocalDemoData,
} from '../config/demo';

type AuthStatus = 'loading' | 'unauthenticated' | 'authenticated' | 'mfa_required';

interface BusinessSecurityConfig {
  requiresHipaaCompliance?: boolean;
  mfaEnabled?: boolean;
  auditLoggingEnabled?: boolean;
}

interface AuthContextValue {
  user: User | null;
  crmUser: CRMUser | null;
  businessId: string | null;
  isLoading: boolean;
  error: string | null;
  status: AuthStatus;
  requiresMfa: boolean;
  mfaResolver: MultiFactorResolver | null;
  mfaEnrollmentRequired: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  refreshAuthState: () => Promise<void>;
  hasRole: (roles: UserRole[]) => boolean;
}

const AuthContext = createContext<AuthContextValue | null>(null);

interface AuthProviderProps {
  children: ReactNode;
}

const demoUser = {
  uid: DEMO_USER_ID,
  email: DEMO_USER_EMAIL,
  displayName: DEMO_USER_NAME,
  emailVerified: true,
  isAnonymous: false,
  metadata: {
    creationTime: '2026-01-01T00:00:00.000Z',
    lastSignInTime: '2026-01-01T00:00:00.000Z',
  },
  providerData: [],
  refreshToken: 'demo-refresh-token',
  tenantId: null,
  delete: async () => undefined,
  getIdToken: async () => 'demo-token',
  getIdTokenResult: async () => ({
    token: 'demo-token',
    expirationTime: '2099-01-01T00:00:00.000Z',
    authTime: '2026-01-01T00:00:00.000Z',
    issuedAtTime: '2026-01-01T00:00:00.000Z',
    signInProvider: 'demo',
    signInSecondFactor: null,
    claims: {},
  }),
  phoneNumber: null,
  photoURL: null,
  providerId: 'demo',
  reload: async () => undefined,
  toJSON: () => ({
    displayName: DEMO_USER_NAME,
    email: DEMO_USER_EMAIL,
    uid: DEMO_USER_ID,
  }),
} as unknown as User;

const demoCrmUser: CRMUser = {
  id: DEMO_USER_ID,
  businessId: DEMO_BUSINESS_ID,
  role: 'owner',
  email: DEMO_USER_EMAIL,
  displayName: DEMO_USER_NAME,
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
  teamIds: ['team-sales'],
  managedTeamIds: ['team-sales', 'team-success'],
  requiresHipaaCompliance: false,
  mfaEnabled: false,
  auditLoggingEnabled: true,
};

async function ensureHipaaSessionPersistence(config: BusinessSecurityConfig | null): Promise<void> {
  if (!config?.requiresHipaaCompliance && !config?.mfaEnabled) {
    return;
  }

  const auth = getFirebaseAuth();
  if (!auth) {
    return;
  }

  try {
    await setPersistence(auth, browserSessionPersistence);
  } catch {
    // Fail closed on session policy without surfacing raw auth internals.
  }
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<User | null>(null);
  const [crmUser, setCrmUser] = useState<CRMUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [status, setStatus] = useState<AuthStatus>('loading');
  const [requiresMfa, setRequiresMfa] = useState(false);
  const [mfaEnrollmentRequired, setMfaEnrollmentRequired] = useState(false);
  const [mfaResolver, setMfaResolver] = useState<MultiFactorResolver | null>(null);
  const [, setBusinessSecurityConfig] = useState<BusinessSecurityConfig | null>(null);

  const auth = usesLocalDemoData ? null : getFirebaseAuth();
  const db = usesLocalDemoData ? null : getFirebaseDb();

  const resetState = () => {
    setCrmUser(null);
    setBusinessSecurityConfig(null);
    setRequiresMfa(false);
    setMfaEnrollmentRequired(false);
    setMfaResolver(null);
    setDefaultTeamIds([]);
    setDefaultManagedTeamIds([]);
  };

  const isPrivilegedRole = (role?: UserRole) =>
    role === 'owner' || role === 'admin' || role === 'manager';

  const processAuthUser = async (firebaseUser: User | null) => {
    setIsLoading(true);
    setUser(firebaseUser);

    if (!firebaseUser || !db) {
      resetState();
      setStatus(firebaseUser ? 'authenticated' : 'unauthenticated');
      setIsLoading(false);
      return;
    }

    try {
      const userDocRef = doc(db, USERS_COLLECTION, firebaseUser.uid);
      const userSnap = await getDoc(userDocRef);
      if (!userSnap.exists()) {
        resetState();
        setStatus('unauthenticated');
        setError('User profile missing. Please contact support.');
        setIsLoading(false);
        return;
      }

      const data = userSnap.data();
      const tokenResult = await getIdTokenResult(firebaseUser, true);

      const claimTeamIds = tokenResult?.claims?.teamIds;
      const claimManagedTeamIds = tokenResult?.claims?.managedTeamIds;
      const claimedBusinessId =
        typeof tokenResult?.claims?.businessId === 'string'
          ? tokenResult.claims.businessId.trim()
          : undefined;
      const claimedRole =
        typeof tokenResult?.claims?.role === 'string'
          ? normalizeUserRole(tokenResult.claims.role)
          : undefined;

      const resolvedBusinessId =
        claimedBusinessId || (typeof data.businessId === 'string' ? data.businessId : undefined);

      if (!resolvedBusinessId) {
        resetState();
        setStatus('unauthenticated');
        setError('User profile missing businessId. Please contact support.');
        setIsLoading(false);
        return;
      }

      // Merge profile + token teams to avoid dropping team access when claims or profile are stale
      const resolvedTeamIds = sanitizeTeamIds([
        ...(Array.isArray(data.teamIds) ? data.teamIds : []),
        ...(Array.isArray(claimTeamIds) ? claimTeamIds : []),
      ]);
      const resolvedManagedTeamIds = sanitizeTeamIds([
        ...(Array.isArray(data.managedTeamIds) ? data.managedTeamIds : []),
        ...(Array.isArray(claimManagedTeamIds) ? claimManagedTeamIds : []),
      ]);
      const mappedUser: CRMUser = {
        id: userSnap.id,
        email: data.email || firebaseUser.email || '',
        displayName: data.displayName || firebaseUser.displayName || '',
        role: claimedRole || normalizeUserRole(typeof data.role === 'string' ? data.role : undefined) || 'staff',
        businessId: resolvedBusinessId,
        createdAt: data.createdAt?.toDate() || new Date(),
        providerId: data.providerId,
        clientId: data.clientId,
        crmRole: data.crmRole,
        lastLoginAt: data.lastLoginAt?.toDate(),
        teamIds: resolvedTeamIds,
        managedTeamIds: resolvedManagedTeamIds,
        managerId: data.managerId,
      };

      let businessConfig: BusinessSecurityConfig | null = null;
      if (mappedUser.businessId) {
        const businessDocRef = doc(db, businessPath(mappedUser.businessId));
        const businessSnap = await getDoc(businessDocRef);
        if (businessSnap.exists()) {
          const businessData = businessSnap.data() as BusinessSecurityConfig;
          businessConfig = businessData;
          setBusinessSecurityConfig(businessData);
        }
      }

      await ensureHipaaSessionPersistence(businessConfig);

      const mergedUser: CRMUser = {
        ...mappedUser,
        requiresHipaaCompliance: businessConfig?.requiresHipaaCompliance,
        mfaEnabled: businessConfig?.mfaEnabled,
        auditLoggingEnabled: businessConfig?.auditLoggingEnabled,
      };
      setCrmUser(mergedUser);
      setDefaultTeamIds(mergedUser.teamIds || []);
      setDefaultManagedTeamIds(mergedUser.managedTeamIds || []);

      const businessRequiresMfa =
        (businessConfig?.requiresHipaaCompliance || businessConfig?.mfaEnabled) &&
        isPrivilegedRole(mappedUser.role);

      setRequiresMfa(Boolean(businessRequiresMfa));
      const enrolledFactors = (firebaseUser as any)?.multiFactor?.enrolledFactors?.length || 0;
      const missingEnrollment = Boolean(businessRequiresMfa) && enrolledFactors === 0;

      if (missingEnrollment) {
        setStatus('mfa_required');
        setMfaEnrollmentRequired(missingEnrollment);
      } else {
        setStatus('authenticated');
        setMfaEnrollmentRequired(false);
        setMfaResolver(null);
      }
      return;
    } catch {
      resetState();
      setStatus('unauthenticated');
      setError('Authentication session could not be completed. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (isDemoMode) {
      setUser(demoUser);
      setCrmUser(demoCrmUser);
      setBusinessSecurityConfig(null);
      setRequiresMfa(false);
      setMfaEnrollmentRequired(false);
      setMfaResolver(null);
      setError(null);
      setStatus('authenticated');
      setDefaultTeamIds(demoCrmUser.teamIds || []);
      setDefaultManagedTeamIds(demoCrmUser.managedTeamIds || []);
      setIsLoading(false);
      return undefined;
    }

    if (!auth) {
      setIsLoading(false);
      setStatus('unauthenticated');
      return;
    }

    const unsubscribe = onAuthStateChanged(auth, (firebaseUser) => {
      processAuthUser(firebaseUser);
    });

    return () => unsubscribe();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [auth, db]);

  const signIn = async (email: string, password: string) => {
    if (isDemoMode) {
      setError(null);
      setUser(demoUser);
      setCrmUser(demoCrmUser);
      setStatus('authenticated');
      return;
    }

    if (!auth) {
      setError('Firebase not configured');
      return;
    }

    setError(null);
    try {
      await signInWithEmailAndPassword(auth, email, password);
    } catch (err) {
      const errorCode = (err as { code?: string })?.code;

      if (errorCode === 'auth/multi-factor-auth-required' && auth) {
        const resolver = getMultiFactorResolver(auth, err as MultiFactorError);
        setMfaResolver(resolver);
        setStatus('mfa_required');
        setError('Multi-factor authentication required to continue.');
      } else {
        const message = 'Sign in failed. Please try again.';
        setError(message);
      }
      throw err;
    }
  };

  const signOut = async () => {
    if (isDemoMode) {
      return;
    }

    if (!auth) return;

    try {
      await firebaseSignOut(auth);
      setCrmUser(null);
      setStatus('unauthenticated');
      resetState();
    } catch (err) {
      // Silently handle sign out errors
    }
  };

  const refreshAuthState = async () => {
    if (isDemoMode) {
      setUser(demoUser);
      setCrmUser(demoCrmUser);
      setStatus('authenticated');
      return;
    }

    const current = getFirebaseAuth()?.currentUser || null;
    await current?.reload();
    await processAuthUser(current);
  };

  const hasRole = (roles: UserRole[]): boolean => {
    if (!crmUser) return false;
    return roles.includes(crmUser.role);
  };

  const value: AuthContextValue = {
    user,
    crmUser,
    businessId: crmUser?.businessId || null,
    isLoading,
    status,
    requiresMfa,
    mfaResolver,
    mfaEnrollmentRequired,
    error,
    signIn,
    signOut,
    refreshAuthState,
    hasRole,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
