import {
  collection,
  query,
  where,
  orderBy,
  limit as limitQuery,
  getDocs,
  Timestamp,
  QueryConstraint,
} from 'firebase/firestore';
import { getDb } from '../lib/firebase';
import { scopedCollection } from './firestoreBase';

/**
 * HIPAA-Compliant Activity Log Entry
 *
 * CRITICAL: Logs must NEVER contain PHI.
 * - Only store IDs (userId, entityId, appointmentId, clientId)
 * - Never store names, contact info, or sensitive details
 * - Metadata should be minimal and non-identifying
 */
export interface ActivityLogEntry {
  id: string;
  userId: string;
  action: string;
  entityType?: string;
  entityId?: string;
  metadata: Record<string, unknown>; // NO PHI! Only non-sensitive metadata
  ipAddress?: string;
  timestamp: Date;
}

export interface ActivityLogFilters {
  userId?: string;
  action?: string;
  startDate?: Date;
  endDate?: Date;
  limit?: number;
}

/**
 * List activity logs with optional filtering
 *
 * @param businessId - Business context (required for tenant isolation)
 * @param filters - Optional filters for userId, action, date range, limit
 * @returns Promise<ActivityLogEntry[]>
 */
export async function listActivityLogs(
  businessId: string,
  filters: ActivityLogFilters = {}
): Promise<ActivityLogEntry[]> {
  const db = getDb();
  const logsRef = scopedCollection(businessId, ['auditLogs']).ref;

  const constraints: QueryConstraint[] = [
    orderBy('timestamp', 'desc'),
    limitQuery(filters.limit || 50),
  ];

  // Apply userId filter if provided
  if (filters.userId) {
    constraints.unshift(where('userId', '==', filters.userId));
  }

  // Apply action filter if provided
  if (filters.action) {
    constraints.unshift(where('action', '==', filters.action));
  }

  // Apply date range filters
  if (filters.startDate) {
    constraints.push(where('timestamp', '>=', Timestamp.fromDate(filters.startDate)));
  }

  if (filters.endDate) {
    constraints.push(where('timestamp', '<=', Timestamp.fromDate(filters.endDate)));
  }

  const q = query(logsRef, ...constraints);
  const snapshot = await getDocs(q);

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      userId: data.userId || '',
      action: data.action || '',
      entityType: data.entityType,
      entityId: data.entityId,
      metadata: data.metadata || {},
      ipAddress: data.ipAddress,
      timestamp: data.timestamp?.toDate() || new Date(),
    } as ActivityLogEntry;
  });
}

/**
 * List activity logs for a specific user
 *
 * @param businessId - Business context
 * @param userId - User ID to filter by
 * @param limitCount - Number of entries to return (default: 50)
 * @returns Promise<ActivityLogEntry[]>
 */
export async function listUserActivity(
  businessId: string,
  userId: string,
  limitCount = 50
): Promise<ActivityLogEntry[]> {
  return listActivityLogs(businessId, { userId, limit: limitCount });
}

/**
 * List activity logs for a specific action type
 *
 * @param businessId - Business context
 * @param action - Action type to filter by
 * @param limitCount - Number of entries to return (default: 50)
 * @returns Promise<ActivityLogEntry[]>
 */
export async function listActivityByAction(
  businessId: string,
  action: string,
  limitCount = 50
): Promise<ActivityLogEntry[]> {
  return listActivityLogs(businessId, { action, limit: limitCount });
}

/**
 * Get action configuration for display purposes
 * Maps action types to labels and colors
 *
 * This is HIPAA-compliant as it contains no PHI - only UI metadata
 */
export const ACTION_CONFIG: Record<
  string,
  { label: string; color: 'success' | 'info' | 'warning' | 'danger' | 'muted' }
> = {
  // Authentication
  login_success: { label: 'Logged in', color: 'success' },
  login_failure: { label: 'Failed login attempt', color: 'warning' },
  logout: { label: 'Logged out', color: 'muted' },

  // MFA
  mfa_enrolled: { label: 'Enrolled in MFA', color: 'success' },
  mfa_challenge_success: { label: 'Passed MFA', color: 'success' },
  mfa_challenge_failure: { label: 'Failed MFA', color: 'danger' },

  // Appointments
  appointment_created: { label: 'Created appointment', color: 'info' },
  appointment_updated: { label: 'Updated appointment', color: 'info' },
  appointment_cancelled: { label: 'Cancelled appointment', color: 'warning' },
  appointment_deleted: { label: 'Deleted appointment', color: 'danger' },

  // Clients
  client_created: { label: 'Created client', color: 'info' },
  client_updated: { label: 'Updated client', color: 'info' },
  client_deleted: { label: 'Deleted client', color: 'danger' },

  // Staff
  staff_invited: { label: 'Sent staff invite', color: 'info' },
  staff_joined: { label: 'Staff joined', color: 'success' },
  staff_updated: { label: 'Updated staff', color: 'info' },
  staff_removed: { label: 'Removed staff', color: 'danger' },

  // Roles & Permissions
  role_changed: { label: 'Changed role', color: 'warning' },
  permissions_updated: { label: 'Updated permissions', color: 'info' },

  // HIPAA & Security
  hipaa_enabled: { label: 'Enabled HIPAA mode', color: 'info' },
  hipaa_disabled: { label: 'Disabled HIPAA mode', color: 'warning' },
  ownership_transferred: { label: 'Transferred ownership', color: 'danger' },

  // Settings
  settings_updated: { label: 'Updated settings', color: 'info' },
  feature_enabled: { label: 'Enabled feature', color: 'success' },
  feature_disabled: { label: 'Disabled feature', color: 'warning' },

  // Services
  service_created: { label: 'Created service', color: 'info' },
  service_updated: { label: 'Updated service', color: 'info' },
  service_deleted: { label: 'Deleted service', color: 'danger' },

  // Locations & Resources
  location_created: { label: 'Created location', color: 'info' },
  location_updated: { label: 'Updated location', color: 'info' },
  resource_created: { label: 'Created resource', color: 'info' },
  resource_updated: { label: 'Updated resource', color: 'info' },

  // Default fallback
  default: { label: 'Activity', color: 'info' },
};

/**
 * Get action configuration for a specific action type
 * Falls back to default if action type is unknown
 *
 * @param action - Action type
 * @returns Action configuration object
 */
export function getActionConfig(action: string) {
  return ACTION_CONFIG[action] || ACTION_CONFIG.default;
}
