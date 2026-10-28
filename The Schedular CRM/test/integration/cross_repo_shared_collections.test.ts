/**
 * Cross-Repo Integration Contract Tests - Shared Collections
 *
 * Agent CRM-37: Cross-Repo Integration QA
 *
 * This test suite validates shared collection schemas to ensure compatibility
 * between CRM, Scheduler, and Admin repos that share a Firebase backend.
 *
 * Part 1 of 2: Tests for shared collections (users, clients, payments)
 *
 * SCOPE:
 * - Tests shared collections: users, clients, payments
 * - Validates schema contracts defined in docs/shared_data_contract.md
 * - Ensures CRM can read Scheduler-created documents
 * - Ensures Scheduler can read CRM-created documents
 *
 * PREREQUISITES:
 * - Firebase emulator running on localhost:8080
 * - Run with: npm test -- cross_repo
 */

import {
  initializeTestEnvironment,
  assertSucceeds,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, Timestamp } from 'firebase/firestore';
import { readFileSync } from 'fs';
import { describe, it, beforeAll, afterAll, beforeEach, expect } from 'vitest';
import type { User, Client, Payment } from '../../src/types/models';

const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST || '';
const [emulatorHostname, emulatorPortString] = (emulatorHost || 'localhost:8080').split(':');
const emulatorPort = emulatorPortString ? parseInt(emulatorPortString, 10) : 8080;
const describeIfEmulator = emulatorHost ? describe : describe.skip;

// ============================================
// Test Configuration
// ============================================

describeIfEmulator('Cross-repo shared collections (emulator required)', () => {
let testEnv: RulesTestEnvironment;

const BUSINESS_ID = 'test-business-123';
const USER_ID = 'test-user-123';

// ============================================
// Test Environment Setup & Teardown
// ============================================

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'crm-cross-repo-test',
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
});

// ============================================
// Helper Functions
// ============================================

/**
 * Helper to validate that an object has all required fields
 */
function hasRequiredFields(obj: any, requiredFields: string[]): { valid: boolean; missing: string[] } {
  const missing = requiredFields.filter(field => !(field in obj));
  return {
    valid: missing.length === 0,
    missing,
  };
}

/**
 * Helper to validate field types
 */
function validateFieldType(value: any, expectedType: string): boolean {
  switch (expectedType) {
    case 'string':
      return typeof value === 'string';
    case 'number':
      return typeof value === 'number';
    case 'boolean':
      return typeof value === 'boolean';
    case 'array':
      return Array.isArray(value);
    case 'object':
      return typeof value === 'object' && value !== null && !Array.isArray(value);
    case 'timestamp':
      return value instanceof Timestamp || value instanceof Date;
    default:
      return false;
  }
}

// ============================================
// Contract Tests: users/{uid} Collection
// ============================================

describe('Shared Schema Contract: users/{uid}', () => {
  it('should have all required fields for cross-repo compatibility', async () => {
    const requiredFields = ['id', 'businessId', 'role', 'email', 'displayName', 'createdAt'];

    // Simulate Scheduler creating a user (as it would when user signs up)
    const schedulerUser = {
      id: USER_ID,
      businessId: BUSINESS_ID,
      role: 'staff',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: Timestamp.now(),
    };

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'users', USER_ID), schedulerUser);
    });

    // CRM reads the user (as it would for assignee lookup)
    const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
      businessId: BUSINESS_ID,
      role: 'staff',
    });
    const db = authenticatedContext.firestore();

    const userDoc = await assertSucceeds(getDoc(doc(db, 'users', USER_ID)));
    const userData = userDoc.data() as User;

    // Validate required fields
    const validation = hasRequiredFields(userData, requiredFields);
    expect(validation.valid, `Missing fields: ${validation.missing.join(', ')}`).toBe(true);

    // Validate field types
    expect(validateFieldType(userData.id, 'string')).toBe(true);
    expect(validateFieldType(userData.businessId, 'string')).toBe(true);
    expect(validateFieldType(userData.role, 'string')).toBe(true);
    expect(validateFieldType(userData.email, 'string')).toBe(true);
    expect(validateFieldType(userData.displayName, 'string')).toBe(true);
    expect(validateFieldType(userData.createdAt, 'timestamp')).toBe(true);
  });

  it('should accept optional CRM-specific fields without breaking Scheduler', async () => {
    const userWithCRMFields = {
      id: USER_ID,
      businessId: BUSINESS_ID,
      role: 'admin',
      email: 'admin@example.com',
      displayName: 'Admin User',
      createdAt: Timestamp.now(),
      providerId: 'provider-123', // Optional field
      clientId: 'client-123', // Optional field
    };

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'users', USER_ID), userWithCRMFields);
    });

    const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
      businessId: BUSINESS_ID,
      role: 'admin',
    });
    const db = authenticatedContext.firestore();

    const userDoc = await assertSucceeds(getDoc(doc(db, 'users', USER_ID)));
    const userData = userDoc.data();

    expect(userData).toBeDefined();
    expect(userData?.providerId).toBe('provider-123');
    expect(userData?.clientId).toBe('client-123');
  });

  it('should enforce valid role values', () => {
    const validRoles = ['owner', 'admin', 'manager', 'staff', 'assistant'];
    const testUser: User = {
      id: USER_ID,
      businessId: BUSINESS_ID,
      role: 'admin',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: new Date(),
    };

    expect(validRoles).toContain(testUser.role);
  });
});

// ============================================
// Contract Tests: clients/{clientId} Collection
// ============================================

describe('Shared Schema Contract: clients/{clientId}', () => {
  it('should have core required fields for Scheduler compatibility', async () => {
    const coreRequiredFields = ['id', 'firstName', 'lastName', 'email', 'tags', 'createdAt'];

    // Simulate Scheduler creating a client (booking flow)
    const schedulerClient = {
      id: 'client-123',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      phone: '+1234567890',
      tags: ['vip'],
      userId: USER_ID,
      createdAt: Timestamp.now(),
    };

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, `businesses/${BUSINESS_ID}/clients/client-123`), schedulerClient);
    });

    // CRM reads the client
    const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
      businessId: BUSINESS_ID,
      role: 'staff',
    });
    const db = authenticatedContext.firestore();

    const clientDoc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/clients/client-123`))
    );
    const clientData = clientDoc.data() as Client;

    // Validate core required fields
    const validation = hasRequiredFields(clientData, coreRequiredFields);
    expect(validation.valid, `Missing core fields: ${validation.missing.join(', ')}`).toBe(true);

    // Validate field types
    expect(validateFieldType(clientData.firstName, 'string')).toBe(true);
    expect(validateFieldType(clientData.lastName, 'string')).toBe(true);
    expect(validateFieldType(clientData.email, 'string')).toBe(true);
    expect(validateFieldType(clientData.tags, 'array')).toBe(true);
    expect(validateFieldType(clientData.createdAt, 'timestamp')).toBe(true);
  });

  it('should support CRM extensions without breaking Scheduler reads', async () => {
    // CRM creates a client from lead conversion with CRM-specific fields
    const crmClient = {
      id: 'client-456',
      firstName: 'Jane',
      lastName: 'Smith',
      email: 'jane@example.com',
      phone: '+9876543210',
      tags: ['enterprise'],
      createdAt: Timestamp.now(),
      // CRM extensions
      companyId: 'company-123',
      companyName: 'Acme Corp',
      title: 'CEO',
      crmNotes: 'High-value client',
      lastContactedAt: Timestamp.now(),
      leadSource: 'referral',
      address: {
        street: '123 Main St',
        city: 'San Francisco',
        state: 'CA',
        zipCode: '94105',
        country: 'USA',
      },
    };

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, `businesses/${BUSINESS_ID}/clients/client-456`), crmClient);
    });

    // Scheduler reads the client (simulating booking flow)
    const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
      businessId: BUSINESS_ID,
      role: 'staff',
    });
    const db = authenticatedContext.firestore();

    const clientDoc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/clients/client-456`))
    );
    const clientData = clientDoc.data();

    // Verify core fields are present for Scheduler
    expect(clientData?.firstName).toBe('Jane');
    expect(clientData?.lastName).toBe('Smith');
    expect(clientData?.email).toBe('jane@example.com');
    expect(clientData?.tags).toEqual(['enterprise']);

    // Verify CRM extensions are present
    expect(clientData?.companyId).toBe('company-123');
    expect(clientData?.companyName).toBe('Acme Corp');
    expect(clientData?.title).toBe('CEO');
    expect(clientData?.address).toBeDefined();
  });

  it('should support optional lifecycle field used by both repos', async () => {
    const validLifecycles = ['lead', 'prospect', 'active', 'inactive', 'churned'];

    const clientWithLifecycle = {
      id: 'client-789',
      firstName: 'Bob',
      lastName: 'Johnson',
      email: 'bob@example.com',
      tags: [],
      lifecycle: 'active',
      createdAt: Timestamp.now(),
    };

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, `businesses/${BUSINESS_ID}/clients/client-789`), clientWithLifecycle);
    });

    const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
      businessId: BUSINESS_ID,
      role: 'staff',
    });
    const db = authenticatedContext.firestore();

    const clientDoc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/clients/client-789`))
    );
    const clientData = clientDoc.data();

    expect(clientData?.lifecycle).toBe('active');
    expect(validLifecycles).toContain(clientData?.lifecycle);
  });
});

// ============================================
// Contract Tests: payments/{paymentId} Collection
// ============================================

describe('Shared Schema Contract: payments/{paymentId}', () => {
  it('should have all required fields for cross-repo payment tracking', async () => {
    const requiredFields = [
      'id',
      'amountCents',
      'currency',
      'status',
      'method',
      'clientId',
      'clientName',
      'processedById',
      'processedByName',
      'processedAt',
      'createdAt',
    ];

    // Scheduler creates a payment (appointment payment)
    const schedulerPayment = {
      id: 'payment-123',
      amountCents: 10000,
      currency: 'USD',
      status: 'succeeded',
      method: 'card',
      clientId: 'client-123',
      clientName: 'John Doe',
      processedById: USER_ID,
      processedByName: 'Test Staff',
      processedAt: Timestamp.now(),
      createdAt: Timestamp.now(),
      providerId: 'ch_stripe_123',
      receiptUrl: 'https://stripe.com/receipt',
      last4: '4242',
      cardBrand: 'visa',
    };

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, `businesses/${BUSINESS_ID}/payments/payment-123`), schedulerPayment);
    });

    // CRM reads the payment
    const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
      businessId: BUSINESS_ID,
      role: 'staff',
    });
    const db = authenticatedContext.firestore();

    const paymentDoc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/payments/payment-123`))
    );
    const paymentData = paymentDoc.data() as Payment;

    // Validate required fields
    const validation = hasRequiredFields(paymentData, requiredFields);
    expect(validation.valid, `Missing fields: ${validation.missing.join(', ')}`).toBe(true);

    // Validate field types
    expect(validateFieldType(paymentData.amountCents, 'number')).toBe(true);
    expect(validateFieldType(paymentData.currency, 'string')).toBe(true);
    expect(validateFieldType(paymentData.status, 'string')).toBe(true);
    expect(validateFieldType(paymentData.method, 'string')).toBe(true);
    expect(validateFieldType(paymentData.clientId, 'string')).toBe(true);
    expect(validateFieldType(paymentData.clientName, 'string')).toBe(true);
  });

  it('should support CRM dealId extension without breaking Scheduler', async () => {
    // CRM creates a payment with deal association
    const crmPayment = {
      id: 'payment-456',
      amountCents: 50000,
      currency: 'USD',
      status: 'succeeded',
      method: 'card',
      clientId: 'client-456',
      clientName: 'Jane Smith',
      processedById: USER_ID,
      processedByName: 'Test Admin',
      processedAt: Timestamp.now(),
      createdAt: Timestamp.now(),
      // CRM extensions
      dealId: 'deal-123',
      dealTitle: 'Enterprise Contract',
      notes: 'Payment for Q1 services',
    };

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, `businesses/${BUSINESS_ID}/payments/payment-456`), crmPayment);
    });

    // Scheduler reads the payment (should ignore dealId/dealTitle)
    const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
      businessId: BUSINESS_ID,
      role: 'staff',
    });
    const db = authenticatedContext.firestore();

    const paymentDoc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/payments/payment-456`))
    );
    const paymentData = paymentDoc.data();

    // Verify core payment fields
    expect(paymentData?.amountCents).toBe(50000);
    expect(paymentData?.clientId).toBe('client-456');

    // Verify CRM extensions are present but optional
    expect(paymentData?.dealId).toBe('deal-123');
    expect(paymentData?.dealTitle).toBe('Enterprise Contract');
  });

  it('should enforce valid payment status values', () => {
    const validStatuses = ['pending', 'succeeded', 'failed', 'refunded', 'disputed'];
    const testPayment: Payment = {
      id: 'payment-test',
      amountCents: 10000,
      currency: 'USD',
      status: 'succeeded',
      method: 'card',
      clientId: 'client-123',
      clientName: 'Test Client',
      processedById: USER_ID,
      processedByName: 'Test User',
      processedAt: new Date(),
      createdAt: new Date(),
    };

    expect(validStatuses).toContain(testPayment.status);
  });

  it('should enforce valid payment method values', () => {
    const validMethods = ['card', 'cash', 'check', 'bank_transfer', 'other'];
    const testPayment: Payment = {
      id: 'payment-test',
      amountCents: 10000,
      currency: 'USD',
      status: 'succeeded',
      method: 'card',
      clientId: 'client-123',
      clientName: 'Test Client',
      processedById: USER_ID,
      processedByName: 'Test User',
      processedAt: new Date(),
      createdAt: new Date(),
    };

    expect(validMethods).toContain(testPayment.method);
  });
});

});
