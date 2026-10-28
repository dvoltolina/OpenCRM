/**
 * Firestore Security Rules Tests
 *
 * Agent CRM-33: Security & HIPAA Verification Suite
 *
 * This test suite validates Firestore security rules for:
 * 1. Authentication requirements (all operations require auth)
 * 2. Tenant isolation (cross-business data access blocked)
 * 3. Role-based access control (owner/admin/staff permissions)
 * 4. Field validation (required fields enforcement)
 * 5. PHI protection (client/lead/activity access controls)
 *
 * PREREQUISITES:
 * - Firebase emulator must be running on localhost:8080
 * - Run with: npm run test:rules or npm run test:security
 *
 * IMPORTANT:
 * These tests use @firebase/rules-unit-testing to validate
 * security rules in isolation WITHOUT deploying to production.
 */

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import { describe, it, beforeAll, afterAll, beforeEach } from 'vitest';

const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST || '';
const [emulatorHostname, emulatorPortString] = (emulatorHost || 'localhost:8080').split(':');
const emulatorPort = emulatorPortString ? parseInt(emulatorPortString, 10) : 8080;
const describeIfEmulator = emulatorHost ? describe : describe.skip;

// ============================================
// Test Configuration
// ============================================

describeIfEmulator('Firestore security rules (emulator required)', () => {
  let testEnv: RulesTestEnvironment;

  const BUSINESS_1 = 'business-test-1';
  const BUSINESS_2 = 'business-test-2';

  const OWNER_ID = 'owner-user-123';
  const ADMIN_ID = 'admin-user-456';
  const STAFF_ID = 'staff-user-789';
  const OTHER_BUSINESS_USER = 'other-business-user-999';

  // Mock user data (simulates /users collection)
  const mockUsers = {
    [OWNER_ID]: { businessId: BUSINESS_1, role: 'owner', email: 'owner@test.local' },
    [ADMIN_ID]: { businessId: BUSINESS_1, role: 'admin', email: 'admin@test.local' },
    [STAFF_ID]: { businessId: BUSINESS_1, role: 'staff', email: 'staff@test.local' },
    [OTHER_BUSINESS_USER]: { businessId: BUSINESS_2, role: 'owner', email: 'other@test.local' },
  };

  // ============================================
  // Test Environment Setup & Teardown
  // ============================================

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'crm-security-test',
      firestore: {
        rules: readFileSync('firestore.rules', 'utf8'),
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

    // Seed test data with security rules disabled
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      // Seed user documents
      for (const [userId, userData] of Object.entries(mockUsers)) {
        await setDoc(doc(db, 'users', userId), userData);
      }

      // Seed test data for business 1
      await setDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`), {
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phone: '555-0001',
        status: 'new',
        source: 'website',
        assigneeId: STAFF_ID,
        createdById: STAFF_ID,
      });

      await setDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`), {
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane@example.com',
        phone: '555-0002',
        lifecycle: 'customer',
        assigneeId: STAFF_ID,
        createdById: ADMIN_ID,
      });

      await setDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-1`), {
        title: 'Test Deal',
        pipelineId: 'pipeline-1',
        stageId: 'stage-1',
        valueCents: 10000,
        status: 'open',
        assigneeId: STAFF_ID,
        createdById: STAFF_ID,
      });

      await setDoc(doc(db, `businesses/${BUSINESS_1}/pipelines/pipeline-1`), {
        name: 'Sales Pipeline',
        isDefault: true,
      });

      await setDoc(doc(db, `businesses/${BUSINESS_1}/stages/stage-1`), {
        name: 'Discovery',
        pipelineId: 'pipeline-1',
        order: 1,
      });

      await setDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/activity-1`), {
        type: 'note',
        title: 'Test Activity',
        description: 'Test activity note',
        createdById: STAFF_ID,
        createdByName: 'Staff User',
      });

      // Seed test data for business 2 (cross-tenant isolation testing)
      await setDoc(doc(db, `businesses/${BUSINESS_2}/leads/lead-2`), {
        firstName: 'Other',
        lastName: 'Business Lead',
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
// TEST SUITE 1: Authentication Required
// ============================================

describe('CRM-33: Authentication Required', () => {
  it('BLOCKS unauthenticated read on leads', async () => {
    const db = getUnauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`)));
  });

  it('BLOCKS unauthenticated read on clients (PHI)', async () => {
    const db = getUnauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });

  it('BLOCKS unauthenticated read on deals', async () => {
    const db = getUnauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-1`)));
  });

  it('BLOCKS unauthenticated read on sales activities', async () => {
    const db = getUnauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/activity-1`)));
  });

  it('BLOCKS unauthenticated write on leads', async () => {
    const db = getUnauthenticatedContext().firestore();
    await assertFails(
      setDoc(doc(db, `businesses/${BUSINESS_1}/leads/new-lead`), {
        firstName: 'Test',
        lastName: 'Lead',
        email: 'test@example.com',
        status: 'new',
        source: 'test',
      })
    );
  });

  it('BLOCKS unauthenticated write on clients (PHI)', async () => {
    const db = getUnauthenticatedContext().firestore();
    await assertFails(
      setDoc(doc(db, `businesses/${BUSINESS_1}/clients/new-client`), {
        firstName: 'Test',
        lastName: 'Client',
        email: 'test@example.com',
        lifecycle: 'prospect',
      })
    );
  });

  it('BLOCKS unauthenticated delete on clients (PHI)', async () => {
    const db = getUnauthenticatedContext().firestore();
    await assertFails(deleteDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });
});

// ============================================
// TEST SUITE 2: Tenant Isolation
// ============================================

describe('CRM-33: Tenant Isolation (Cross-Business Access Blocked)', () => {
  it('BLOCKS cross-tenant read on leads', async () => {
    const db = getAuthenticatedContext(OTHER_BUSINESS_USER).firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`)));
  });

  it('BLOCKS cross-tenant read on clients (PHI)', async () => {
    const db = getAuthenticatedContext(OTHER_BUSINESS_USER).firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });

  it('BLOCKS cross-tenant read on deals', async () => {
    const db = getAuthenticatedContext(OTHER_BUSINESS_USER).firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-1`)));
  });

  it('BLOCKS cross-tenant read on sales activities', async () => {
    const db = getAuthenticatedContext(OTHER_BUSINESS_USER).firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/activity-1`)));
  });

  it('BLOCKS cross-tenant write on leads', async () => {
    const db = getAuthenticatedContext(OTHER_BUSINESS_USER).firestore();
    await assertFails(
      setDoc(doc(db, `businesses/${BUSINESS_1}/leads/malicious-lead`), {
        firstName: 'Malicious',
        lastName: 'Actor',
        email: 'bad@example.com',
        status: 'new',
        source: 'attack',
      })
    );
  });

  it('BLOCKS cross-tenant update on clients (PHI)', async () => {
    const db = getAuthenticatedContext(OTHER_BUSINESS_USER).firestore();
    await assertFails(
      updateDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`), {
        phone: '555-9999',
      })
    );
  });

  it('BLOCKS cross-tenant delete on clients (PHI)', async () => {
    const db = getAuthenticatedContext(OTHER_BUSINESS_USER).firestore();
    await assertFails(deleteDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });

  it('ALLOWS same-tenant read on leads', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`)));
  });

  it('ALLOWS same-tenant read on clients (PHI)', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });
});

// ============================================
// TEST SUITE 3: Role-Based Access - Leads
// ============================================

describe('CRM-33: Role-Based Access - Leads', () => {
  it('ALLOWS staff to read leads', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`)));
  });

  it('ALLOWS staff to create leads with required fields', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, `businesses/${BUSINESS_1}/leads/new-lead`), {
        firstName: 'New',
        lastName: 'Lead',
        email: 'new@example.com',
        status: 'new',
        source: 'website',
      })
    );
  });

  it('BLOCKS lead creation without required fields', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(
      setDoc(doc(db, `businesses/${BUSINESS_1}/leads/incomplete-lead`), {
        firstName: 'Incomplete',
        // Missing: lastName, email, status, source
      })
    );
  });

  it('ALLOWS assigned staff to update lead', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`), {
        status: 'contacted',
      })
    );
  });

  it('BLOCKS staff from deleting leads', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(deleteDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`)));
  });

  it('ALLOWS admin to delete leads', async () => {
    const db = getAuthenticatedContext(ADMIN_ID).firestore();
    await assertSucceeds(deleteDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`)));
  });

  it('ALLOWS owner to delete leads', async () => {
    const db = getAuthenticatedContext(OWNER_ID).firestore();
    await assertSucceeds(deleteDoc(doc(db, `businesses/${BUSINESS_1}/leads/lead-1`)));
  });
});

// ============================================
// TEST SUITE 4: Role-Based Access - Clients (PHI)
// ============================================

describe('CRM-33: Role-Based Access - Clients (PHI Protection)', () => {
  it('ALLOWS staff to read clients', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });

  it('ALLOWS staff to create clients with required fields', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, `businesses/${BUSINESS_1}/clients/new-client`), {
        firstName: 'New',
        lastName: 'Client',
        email: 'newclient@example.com',
        lifecycle: 'prospect',
      })
    );
  });

  it('BLOCKS client creation without required fields', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(
      setDoc(doc(db, `businesses/${BUSINESS_1}/clients/incomplete-client`), {
        firstName: 'Incomplete',
        // Missing: lastName, email, lifecycle
      })
    );
  });

  it('ALLOWS assigned staff to update client (PHI)', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`), {
        phone: '555-1234',
      })
    );
  });

  it('BLOCKS staff from deleting clients (PHI protection)', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(deleteDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });

  it('ALLOWS admin to delete clients', async () => {
    const db = getAuthenticatedContext(ADMIN_ID).firestore();
    await assertSucceeds(deleteDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });

  it('ALLOWS owner to delete clients', async () => {
    const db = getAuthenticatedContext(OWNER_ID).firestore();
    await assertSucceeds(deleteDoc(doc(db, `businesses/${BUSINESS_1}/clients/client-1`)));
  });
});

// ============================================
// TEST SUITE 5: Role-Based Access - Pipelines
// ============================================

describe('CRM-33: Role-Based Access - Pipelines', () => {
  it('ALLOWS staff to read pipelines', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/pipelines/pipeline-1`)));
  });

  it('BLOCKS staff from creating pipelines', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(
      setDoc(doc(db, `businesses/${BUSINESS_1}/pipelines/new-pipeline`), {
        name: 'New Pipeline',
      })
    );
  });

  it('ALLOWS admin to create pipelines', async () => {
    const db = getAuthenticatedContext(ADMIN_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, `businesses/${BUSINESS_1}/pipelines/new-pipeline`), {
        name: 'Admin Pipeline',
      })
    );
  });

  it('ALLOWS owner to create pipelines', async () => {
    const db = getAuthenticatedContext(OWNER_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, `businesses/${BUSINESS_1}/pipelines/owner-pipeline`), {
        name: 'Owner Pipeline',
      })
    );
  });

  it('BLOCKS admin from deleting pipelines', async () => {
    const db = getAuthenticatedContext(ADMIN_ID).firestore();
    await assertFails(deleteDoc(doc(db, `businesses/${BUSINESS_1}/pipelines/pipeline-1`)));
  });

  it('ALLOWS owner to delete pipelines', async () => {
    const db = getAuthenticatedContext(OWNER_ID).firestore();
    await assertSucceeds(deleteDoc(doc(db, `businesses/${BUSINESS_1}/pipelines/pipeline-1`)));
  });
});

// ============================================
// TEST SUITE 6: Role-Based Access - Sales Activities
// ============================================

describe('CRM-33: Role-Based Access - Sales Activities', () => {
  it('ALLOWS staff to read sales activities', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/activity-1`)));
  });

  it('ALLOWS staff to create activities with required fields', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/new-activity`), {
        type: 'call',
        title: 'Follow-up call',
        createdById: STAFF_ID,
        createdByName: 'Staff User',
      })
    );
  });

  it('BLOCKS activity creation without required fields', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(
      setDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/incomplete-activity`), {
        type: 'note',
        // Missing: title, createdById, createdByName
      })
    );
  });

  it('ALLOWS creator to update their activity', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/activity-1`), {
        title: 'Updated Activity',
      })
    );
  });

  it('BLOCKS staff from deleting activities', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(deleteDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/activity-1`)));
  });

  it('ALLOWS admin to delete activities', async () => {
    const db = getAuthenticatedContext(ADMIN_ID).firestore();
    await assertSucceeds(deleteDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/activity-1`)));
  });

  it('ALLOWS owner to delete activities', async () => {
    const db = getAuthenticatedContext(OWNER_ID).firestore();
    await assertSucceeds(deleteDoc(doc(db, `businesses/${BUSINESS_1}/sales_activities/activity-1`)));
  });
});

// ============================================
// TEST SUITE 7: Role-Based Access - Deals
// ============================================

describe('CRM-33: Role-Based Access - Deals', () => {
  it('ALLOWS staff to read deals', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-1`)));
  });

  it('ALLOWS staff to create deals with required fields', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, `businesses/${BUSINESS_1}/deals/new-deal`), {
        title: 'New Deal',
        pipelineId: 'pipeline-1',
        stageId: 'stage-1',
        valueCents: 50000,
        status: 'open',
      })
    );
  });

  it('BLOCKS deal creation without required fields', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(
      setDoc(doc(db, `businesses/${BUSINESS_1}/deals/incomplete-deal`), {
        title: 'Incomplete Deal',
        // Missing: pipelineId, stageId, valueCents, status
      })
    );
  });

  it('ALLOWS assigned staff to update deal', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-1`), {
        valueCents: 15000,
      })
    );
  });

  it('BLOCKS staff from deleting deals', async () => {
    const db = getAuthenticatedContext(STAFF_ID).firestore();
    await assertFails(deleteDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-1`)));
  });

  it('ALLOWS admin to delete deals', async () => {
    const db = getAuthenticatedContext(ADMIN_ID).firestore();
    await assertSucceeds(deleteDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-1`)));
  });

  it('ALLOWS owner to delete deals', async () => {
    const db = getAuthenticatedContext(OWNER_ID).firestore();
    await assertSucceeds(deleteDoc(doc(db, `businesses/${BUSINESS_1}/deals/deal-1`)));
  });
});

});
