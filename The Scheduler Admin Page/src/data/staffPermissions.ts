import { doc, setDoc } from 'firebase/firestore';

import { assertDemoMutationAllowed } from '../config/demo';
import { fetchDoc } from './firestoreBase';
import { getDb } from '../lib/firebase';
import type { ModuleAccess, OnboardingTeamInvite, StaffPermissions } from '../types/models';
import type { UserRole } from '../types/auth';
import { logAuditEvent } from './auditLog';

const DEFAULT_MODULE_ACCESS: Partial<Record<UserRole, ModuleAccess>> = {
  owner: {
    calendar: 'manage_all',
    clients: 'manage_all',
    leads: 'manage_all',
    deals: 'manage_all',
    marketing: 'manage',
    billing: 'manage',
    settings: 'manage',
    staff: 'manage',
  },
  admin: {
    calendar: 'manage_all',
    clients: 'manage_all',
    leads: 'manage_all',
    deals: 'manage_all',
    marketing: 'manage',
    billing: 'view',
    settings: 'manage',
    staff: 'manage',
  },
  manager: {
    calendar: 'manage_all',
    clients: 'manage_all',
    leads: 'view_all',
    deals: 'view_all',
    marketing: 'view',
    billing: 'none',
    settings: 'view',
    staff: 'view',
  },
  staff: {
    calendar: 'view_all',
    clients: 'view_all',
    leads: 'none',
    deals: 'none',
    marketing: 'none',
    billing: 'none',
    settings: 'none',
    staff: 'none',
  },
  provider: {
    calendar: 'view_own',
    clients: 'view_own',
    leads: 'none',
    deals: 'none',
    marketing: 'none',
    billing: 'none',
    settings: 'none',
    staff: 'none',
  },
  sales: {
    calendar: 'view_own',
    clients: 'view_all',
    leads: 'manage_all',
    deals: 'manage_all',
    marketing: 'view',
    billing: 'none',
    settings: 'none',
    staff: 'none',
  },
  frontDesk: {
    calendar: 'view_all',
    clients: 'view_all',
    leads: 'none',
    deals: 'none',
    marketing: 'none',
    billing: 'none',
    settings: 'none',
    staff: 'none',
  },
  client: {},
};

export function buildDefaultModuleAccess(role?: UserRole): ModuleAccess {
  if (!role) return {};
  const defaults = DEFAULT_MODULE_ACCESS[role];
  return defaults ? { ...defaults } : {};
}

export function isModuleEnabled(access: ModuleAccess, module?: keyof ModuleAccess): boolean {
  if (!module) return true;
  const level = access?.[module];
  // 'none' or undefined means no access
  return level !== undefined && level !== 'none';
}

export async function getStaffPermissions(
  businessId: string,
  userId: string,
): Promise<StaffPermissions | null> {
  if (!businessId) throw new Error('businessId is required to load staff permissions');
  if (!userId) throw new Error('userId is required to load staff permissions');
  const data = await fetchDoc<StaffPermissions>(businessId, ['staff_permissions'], userId);
  if (!data) return null;
  return { ...data, id: userId, userId: data.userId ?? userId };
}

export async function saveStaffPermissions(
  businessId: string,
  userId: string,
  permissions: Omit<StaffPermissions, 'id' | 'userId'>,
  actorId?: string,
): Promise<void> {
  assertDemoMutationAllowed('save staff permissions');
  if (!businessId) throw new Error('businessId is required to save staff permissions');
  if (!userId) throw new Error('userId is required to save staff permissions');
  const db = getDb();
  const ref = doc(db, 'businesses', businessId, 'staff_permissions', userId);
  const now = new Date().toISOString();
  const payload: StaffPermissions = {
    ...permissions,
    userId,
    updatedAt: now,
    createdAt: permissions.createdAt ?? now,
  };
  await setDoc(ref, payload, { merge: true });
  await logAuditEvent({
    businessId,
    userId: actorId ?? userId,
    actionType: 'configWrite',
    entityType: 'StaffPermissions',
    entityId: userId,
    metadata: {
      modulesEnabled: Object.entries(payload.moduleAccess ?? {})
        .filter(([, enabled]) => Boolean(enabled))
        .map(([key]) => key)
        .slice(0, 6),
    },
  });
}

export async function saveInvitePermissions(
  businessId: string,
  invites: OnboardingTeamInvite[],
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('save invite permissions');
  if (!businessId) throw new Error('businessId is required to save invite permissions');
  const db = getDb();
  const ref = doc(db, 'businesses', businessId, 'settings', 'staff_permissions');
  const now = new Date().toISOString();
  await setDoc(ref, { invites: invites ?? [], updatedAt: now }, { merge: true });
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'configWrite',
    entityType: 'StaffPermissions',
    entityId: 'invites',
    metadata: { inviteCount: invites?.length ?? 0 },
  });
}

export async function findInvitePermissions(
  businessId: string,
  email?: string | null,
): Promise<StaffPermissions | null> {
  if (!businessId || !email) return null;
  const data = await fetchDoc<{ invites?: OnboardingTeamInvite[] }>(
    businessId,
    ['settings'],
    'staff_permissions',
  );
  const match =
    data?.invites?.find(
      (invite) => invite.email?.toLowerCase() === email.toLowerCase(),
    ) ?? null;
  if (!match) return null;
  return {
    email: match.email,
    role: match.role,
    moduleAccess: match.moduleAccess ?? {},
    locationIds: match.locationIds ?? [],
    serviceIds: match.serviceIds ?? [],
  };
}
