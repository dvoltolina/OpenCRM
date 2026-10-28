/**
 * Firestore Security Rules Tests
 *
 * HIPAA Compliance Tests for CRM Security Rules
 *
 * These tests validate:
 * 1. Authentication required for all operations
 * 2. Tenant isolation (cross-business access blocked)
 * 3. Role-based access control
 * 4. PHI protection (clients, leads, activities)
 *
 * Run with: npm run test:rules
 * Requires: Firebase emulator running
 */

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import path from 'path';
import { describe, it, beforeAll, afterAll, beforeEach } from 'vitest';

const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST || '';
const [emulatorHostname, emulatorPortString] = (emulatorHost || 'localhost:8080').split(':');
const emulatorPort = emulatorPortString ? parseInt(emulatorPortString, 10) : 8080;
const describeIfEmulator = emulatorHost ? describe : describe.skip;
const rulesPath =
  process.env.FIRESTORE_RULES_PATH
    ? path.resolve(process.env.FIRESTORE_RULES_PATH)
    : path.resolve(process.cwd(), '..', 'The Scheduler', 'firestore.rules');
// ============================================
// Test Setup
// ============================================

describeIfEmulator('Firestore security rules (emulator required)', () => {
let testEnv: RulesTestEnvironment;

const BUSINESS_1 = 'business-1';
const BUSINESS_2 = 'business-2';

const OWNER_ID = 'owner-user';
const ADMIN_ID = 'admin-user';
const MANAGER_ID = 'manager-user';
const STAFF_ID = 'staff-user';
const OTHER_BUSINESS_USER = 'other-business-user';
const MANAGER_TOKEN_USER = 'manager-claims-user';

// Mock user data
const mockUsers = {
  [OWNER_ID]: { businessId: BUSINESS_1, role: 'owner', email: 'owner@test.com', teamIds: ['team-a'] },
  [ADMIN_ID]: { businessId: BUSINESS_1, role: 'admin', email: 'admin@test.com', teamIds: ['team-a'] },
  [MANAGER_ID]: { businessId: BUSINESS_1, role: 'manager', email: 'manager@test.com', teamIds: ['team-a'], managedTeamIds: ['team-a'] },
  [STAFF_ID]: { businessId: BUSINESS_1, role: 'staff', email: 'staff@test.com', teamIds: ['team-a'] },
  [OTHER_BUSINESS_USER]: { businessId: BUSINESS_2, role: 'owner', email: 'other@test.com', teamIds: ['team-b'] },
  [MANAGER_TOKEN_USER]: { businessId: BUSINESS_1, role: 'manager', email: 'manager-claims@test.com', teamIds: [], managedTeamIds: [] },
};

// ============================================
// Test Environment Setup
// ============================================

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'crm-rules-test',
    firestore: {
      rules: readFileSync(rulesPath, 'utf8'),
      host: emulatorHostname,
      port: emulatorPort,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  // Set up user documents
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    // Create user documents
    for (const [userId, userData] of Object.entries(mockUsers)) {
      await setDoc(doc(db, 'users', userId), userData);
    }

    // Create test data for business 1
    await setDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`), {
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      status: 'new',
      source: 'website',
      assigneeId: STAFF_ID,
      createdById: STAFF_ID,
      ownerId: STAFF_ID,
      ownerName: 'Staff User',
      teamIds: ['team-a'],
      visibility: 'team',
    });

    await setDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-private`), {
      firstName: 'Private',
      lastName: 'Lead',
      email: 'priv@example.com',
      status: 'new',
      source: 'referral',
      assigneeId: ADMIN_ID,
      createdById: ADMIN_ID,
      ownerId: ADMIN_ID,
      ownerName: 'Admin User',
      teamIds: ['team-b'],
      visibility: 'private',
    });

    await setDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-org`), {
      firstName: 'Org',
      lastName: 'Lead',
      email: 'org@example.com',
      status: 'contacted',
      source: 'website',
      assigneeId: ADMIN_ID,
      createdById: ADMIN_ID,
      ownerId: ADMIN_ID,
      ownerName: 'Admin User',
      teamIds: [],
      visibility: 'org',
    });

    await setDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-managed-token`), {
      firstName: 'Managed',
      lastName: 'Token',
      email: 'managed@example.com',
      status: 'contacted',
      source: 'website',
      assigneeId: ADMIN_ID,
      createdById: ADMIN_ID,
      ownerId: ADMIN_ID,
      ownerName: 'Admin User',
      teamIds: ['team-token'],
      visibility: 'team',
    });

    await setDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`), {
      firstName: 'Jane',
      lastName: 'Smith',
      email: 'jane@example.com',
      lifecycle: 'customer',
      assigneeId: STAFF_ID,
      createdById: ADMIN_ID,
      ownerId: ADMIN_ID,
      ownerName: 'Admin User',
      teamIds: ['team-a'],
      visibility: 'team',
    });

    await setDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-1`), {
      title: 'Test Deal',
      pipelineId: 'pipeline-1',
      stageId: 'stage-1',
      valueCents: 10000,
      status: 'open',
      assigneeId: STAFF_ID,
      createdById: STAFF_ID,
      ownerId: ADMIN_ID,
      ownerName: 'Admin User',
      teamIds: ['team-a'],
      visibility: 'team',
    });

    await setDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-org`), {
      title: 'Org Deal',
      pipelineId: 'pipeline-1',
      stageId: 'stage-1',
      valueCents: 5000,
      status: 'open',
      assigneeId: ADMIN_ID,
      createdById: ADMIN_ID,
      ownerId: ADMIN_ID,
      ownerName: 'Admin User',
      teamIds: [],
      visibility: 'org',
    });

    await setDoc(doc(db, `businesses/${BUSINESS_1}/pipelines/pipeline-1`), {
      name: 'Sales Pipeline',
      isDefault: true,
      ownerId: OWNER_ID,
      ownerName: 'Owner User',
      teamIds: ['team-a'],
      visibility: 'team',
    });

    await setDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/activity-1`), {
      type: 'note',
      title: 'Test Activity',
      createdById: STAFF_ID,
      createdByName: 'Staff User',
      ownerId: STAFF_ID,
      ownerName: 'Staff User',
      teamIds: ['team-a'],
      visibility: 'team',
    });

    await setDoc(doc(db, `businesses/${BUSINESS_1}/report_views/view-1`), {
      name: 'Team View',
      ownerId: OWNER_ID,
      ownerName: 'Owner User',
      filters: { pipelineId: 'pipeline-1', statuses: ['open'] },
      teamIds: ['team-a'],
    });

    await setDoc(doc(db, `businesses/${BUSINESS_1}/reporting_aggregates/agg-1`), {
      pipelineId: 'pipeline-1',
      ownerId: OWNER_ID,
      teamIds: ['team-a'],
      bucket: 'monthly',
      startDate: new Date('2024-01-01'),
      endDate: new Date('2024-01-31'),
      metrics: {
        openCount: 1,
        wonCount: 0,
        lostCount: 0,
        openValueCents: 10000,
        wonValueCents: 0,
        lostValueCents: 0,
        averageCycleDays: 0,
      },
      stageBreakdown: [],
      createdAt: new Date('2024-01-15'),
    });

    // Create test data for business 2
    await setDoc(doc(db, `businesses/${BUSINESS_2}/leads/lead-2`), {
      firstName: 'Other',
      lastName: 'Lead',
      email: 'other@example.com',
      status: 'new',
      source: 'referral',
    });
  });
});

// ============================================
// Helper Functions
// ============================================

function getAuthenticatedContext(userId: string) {
  return testEnv.authenticatedContext(userId);
}

function getUnauthenticatedContext() {
  return testEnv.unauthenticatedContext();
}

// ============================================
// Test 1: Authentication Required
// ============================================

describe('Authentication Required', () => {
  it('blocks unauthenticated read on leads', async () => {
    const db = getUnauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`)));
  });

  it('blocks unauthenticated read on clients (PHI)', async () => {
    const db = getUnauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });

  it('blocks unauthenticated read on deals', async () => {
    const db = getUnauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-1`)));
  });

  it('blocks unauthenticated write on leads', async () => {
    const db = getUnauthenticatedContext().firestore();
    await assertFails(
      setDoc(doc(db, `businesses/${BUSINESS_1}/leads/new-lead`), {
        firstName: 'Test',
        lastName: 'Lead',
        email: 'test@example.com',
        status: 'new',
        source: 'test',
        ownerId: STAFF_ID,
      })
    );
  });

  it('blocks unauthenticated write on clients (PHI)', async () => {
    const db = getUnauthenticatedContext().firestore();
    await assertFails(
      setDoc(doc(db, `businesses/${BUSINESS_1}/clients/new-client`), {
        firstName: 'Test',
        lastName: 'Client',
        email: 'test@example.com',
        lifecycle: 'prospect',
        ownerId: STAFF_ID,
      })
    );
  });
});

// ============================================
// Test 2: Tenant Isolation (Cross-Business Access)
// ============================================

describe('Tenant Isolation', () => {
  it('blocks cross-tenant read on leads', async () => {
    const db = getAuthenticatedContext(OTHER_BUSINESS_USER).firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`)));
  });

  it('blocks cross-tenant read on clients (PHI)', async () => {
    const db = getAuthenticatedContext(OTHER_BUSINESS_USER).firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });

  it('blocks cross-tenant read on deals', async () => {
    const db = getAuthenticatedContext(OTHER_BUSINESS_USER).firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-1`)));
  });

  it('blocks cross-tenant read on reporting aggregates', async () => {
    const db = getAuthenticatedContext(OTHER_BUSINESS_USER).firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/reporting_aggregates/agg-1`)));
  });

  it('blocks cross-tenant write on leads', async () => {
    const db = getAuthenticatedContext(OTHER_BUSINESS_USER).firestore();
    await assertFails(
      setDoc(doc(db, `businesses/${BUSINESS_1}/leads/malicious-lead`), {
        firstName: 'Malicious',
        lastName: 'Actor',
        email: 'bad@example.com',
        status: 'new',
        source: 'attack',
        ownerId: OTHER_BUSINESS_USER,
      })
    );
  });

  it('blocks cross-tenant delete on clients (PHI)', async () => {
    const db = getAuthenticatedContext(OTHER_BUSINESS_USER).firestore();
    await assertFails(deleteDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });

  it('allows same-tenant read', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`)));
  });

  it('allows same-tenant read on clients (PHI)', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });
});

// ============================================
// Test 3: Role-Based Access Control - Leads
// ============================================

describe('Role-Based Access - Leads', () => {
  it('allows staff to read leads', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`)));
  });

  it('allows manager claims to read team-shared lead via managedTeamIds token', async () => {
    const context = testEnv.authenticatedContext(MANAGER_TOKEN_USER, {
      sub: MANAGER_TOKEN_USER,
      token: {
        businessId: BUSINESS_1,
        role: 'manager',
        managedTeamIds: ['team-token'],
      },
    });
    const db = context.firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-managed-token`)));
  });

  it('allows staff to create leads with required fields', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, `businesses/${BUSINESS_1}/leads/new-lead`), {
        firstName: 'New',
        lastName: 'Lead',
        email: 'new@example.com',
        status: 'new',
        source: 'website',
        ownerId: STAFF_ID,
      })
    );
  });

  it('blocks lead creation without required fields', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(
      setDoc(doc(db, `businesses/${BUSINESS_1}/leads/incomplete-lead`), {
        firstName: 'Incomplete',
        // Missing: lastName, email, status, source
        ownerId: STAFF_ID,
      })
    );
  });

  it('allows staff to update assigned lead', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`), {
        status: 'contacted',
      })
    );
  });

  it('blocks staff from deleting leads', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(deleteDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`)));
  });

  it('allows admin to delete leads', async () => {
    const db = getAuthenticatedContext(ADMIN_ID).firestore();
    await assertSucceeds(deleteDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`)));
  });
});

// ============================================
// Test 4: Role-Based Access Control - Clients (PHI)
// ============================================

describe('Role-Based Access - Clients (PHI)', () => {
  it('allows staff to read clients', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });

  it('allows staff to create clients with required fields', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, `businesses/${BUSINESS_1}/clients/new-client`), {
        firstName: 'New',
        lastName: 'Client',
        email: 'newclient@example.com',
        lifecycle: 'prospect',
        ownerId: STAFF_ID,
      })
    );
  });

  it('blocks client creation without required fields', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(
      setDoc(doc(db, `businesses/${BUSINESS_1}/clients/incomplete-client`), {
        firstName: 'Incomplete',
        // Missing: lastName, email, lifecycle
        ownerId: STAFF_ID,
      })
    );
  });

  it('allows assigned staff to update client', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`), {
        phone: '555-1234',
      })
    );
  });

  it('blocks staff from deleting clients (PHI protection)', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(deleteDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });

  it('allows admin to delete clients', async () => {
    const db = getAuthenticatedContext(ADMIN_ID).firestore();
    await assertSucceeds(deleteDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });

  it('allows owner to delete clients', async () => {
    const db = getAuthenticatedContext(OWNER_ID).firestore();
    await assertSucceeds(deleteDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });
});

// ============================================
// Test 5: Role-Based Access Control - Pipelines
// ============================================

describe('Role-Based Access - Pipelines', () => {
  it('allows staff to read pipelines when shared via owner or team', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/pipelines/pipeline-1`)));
  });

  it('blocks staff from creating pipelines', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(
      setDoc(doc(db, `businesses/${BUSINESS_1}/pipelines/new-pipeline`), {
        name: 'New Pipeline',
        ownerId: STAFF_ID,
      })
    );
  });

  it('allows admin to create pipelines', async () => {
    const db = getAuthenticatedContext(ADMIN_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, `businesses/${BUSINESS_1}/pipelines/new-pipeline`), {
        name: 'New Pipeline',
        ownerId: ADMIN_ID,
        teamIds: ['team-a'],
        visibility: 'team',
      })
    );
  });

  it('blocks admin from deleting pipelines', async () => {
    const db = getAuthenticatedContext(ADMIN_ID).firestore();
    await assertFails(deleteDoc(doc(db, `businesses/${BUSINESS_1}/pipelines/pipeline-1`)));
  });

  it('allows owner to delete pipelines', async () => {
    const db = getAuthenticatedContext(OWNER_ID).firestore();
    await assertSucceeds(deleteDoc(doc(db, `businesses/${BUSINESS_1}/pipelines/pipeline-1`)));
  });
});

// ============================================
// Test 6: Role-Based Access Control - Activities
// ============================================

describe('Role-Based Access - Activities', () => {
  it('allows staff to read activities', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/activity-1`)));
  });

  it('allows staff to create activities with required fields', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/new-activity`), {
        type: 'call',
        title: 'Follow-up call',
        createdById: STAFF_ID,
        createdByName: 'Staff User',
        ownerId: STAFF_ID,
      })
    );
  });

  it('allows creator to update their activity', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/activity-1`), {
        title: 'Updated Activity',
      })
    );
  });

  it('blocks staff from deleting activities', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(deleteDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/activity-1`)));
  });

  it('allows admin to delete activities', async () => {
    const db = getAuthenticatedContext(ADMIN_ID).firestore();
    await assertSucceeds(deleteDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/activity-1`)));
  });
});

// ============================================
// Test 7: Role-Based Access Control - Report Views
// ============================================

describe('Role-Based Access - Report Views', () => {
  it('allows owner to create report view in business', async () => {
    const db = getAuthenticatedContext(OWNER_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, `businesses/${BUSINESS_1}/report_views/new-view`), {
        name: 'Owner View',
        ownerId: OWNER_ID,
        ownerName: 'Owner User',
        filters: { statuses: ['open'] },
        teamIds: ['team-a'],
      })
    );
  });

  it('blocks staff from deleting view they do not own', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(deleteDoc(doc(db, `businesses/${BUSINESS_1}/report_views/view-1`)));
  });

  it('allows admin to delete any report view', async () => {
    const db = getAuthenticatedContext(ADMIN_ID).firestore();
    await assertSucceeds(deleteDoc(doc(db, `businesses/${BUSINESS_1}/report_views/view-1`)));
  });

  it('blocks cross-tenant read of report views', async () => {
    const db = getAuthenticatedContext(OTHER_BUSINESS_USER).firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/report_views/view-1`)));
  });
});

// ============================================
// Test 7: Deals Access Control
// ============================================

describe('Role-Based Access - Deals', () => {
  it('allows staff to read deals', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-1`)));
  });

  it('allows staff to create deals with required fields', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, `businesses/${BUSINESS_1}/deals/new-deal`), {
        title: 'New Deal',
        pipelineId: 'pipeline-1',
        stageId: 'stage-1',
        valueCents: 50000,
        status: 'open',
        ownerId: STAFF_ID,
      })
    );
  });

  it('blocks deal creation without required fields', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(
      setDoc(doc(db, `businesses/${BUSINESS_1}/deals/incomplete-deal`), {
        title: 'Incomplete Deal',
        // Missing: pipelineId, stageId, valueCents, status
        ownerId: STAFF_ID,
      })
    );
  });

  it('allows team member to update non-sensitive deal fields', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-1`), {
        stageId: 'stage-2',
      })
    );
  });

  it('blocks staff from deleting deals', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(deleteDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-1`)));
  });

  it('allows admin to delete deals', async () => {
    const db = getAuthenticatedContext(ADMIN_ID).firestore();
    await assertSucceeds(deleteDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-1`)));
  });
});

// ============================================
// Test 8: Sharing & Sensitive Fields
// ============================================

describe('Sharing and field-level permissions', () => {
  it('blocks non-owner team member from changing sensitive deal value', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(
      updateDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-1`), {
        valueCents: 20000,
      })
    );
  });

  it('allows staff to read org-visible lead but blocks ownership change', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-org`)));
    await assertFails(
      updateDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-org`), {
        ownerId: STAFF_ID,
      })
    );
  });

  it('blocks staff from reading private lead shared to another team', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-private`)));
  });

  it('allows manager to update sensitive activity description for their team', async () => {
    const db = getAuthenticatedContext(MANAGER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/activity-1`), {
        description: 'Manager updated description',
      })
    );
  });
});

// ============================================
// Test 9: Reporting Aggregates Access Control
// ============================================

describe('Reporting Aggregates Access', () => {
  it('allows admin to create reporting aggregate', async () => {
    const db = getAuthenticatedContext(ADMIN_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, `businesses/${BUSINESS_1}/reporting_aggregates/new-agg`), {
        pipelineId: 'pipeline-1',
        ownerId: OWNER_ID,
        teamIds: ['team-a'],
        bucket: 'monthly',
        startDate: new Date('2024-02-01'),
        endDate: new Date('2024-02-29'),
        metrics: {
          openCount: 1,
          wonCount: 1,
          lostCount: 0,
          openValueCents: 5000,
          wonValueCents: 10000,
          lostValueCents: 0,
          averageCycleDays: 5,
        },
        stageBreakdown: [],
        createdAt: new Date('2024-02-15'),
      })
    );
  });

  it('blocks staff from creating reporting aggregates', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(
      setDoc(doc(db, `businesses/${BUSINESS_1}/reporting_aggregates/staff-agg`), {
        pipelineId: 'pipeline-1',
        bucket: 'monthly',
        startDate: new Date('2024-03-01'),
        endDate: new Date('2024-03-31'),
        metrics: {
          openCount: 1,
          wonCount: 0,
          lostCount: 0,
          openValueCents: 10000,
          wonValueCents: 0,
          lostValueCents: 0,
          averageCycleDays: 0,
        },
        stageBreakdown: [],
        createdAt: new Date('2024-03-15'),
      })
    );
  });

  it('allows staff to read reporting aggregates in their business', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/reporting_aggregates/agg-1`)));
  });
});

});
