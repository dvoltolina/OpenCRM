/**
 * Cross-Repo Integration Contract Tests - Read-Only Collections & Scenarios
 *
 * Agent CRM-37: Cross-Repo Integration QA
 *
 * Part 2 of 2: Tests for read-only shared collections and integration scenarios
 *
 * SCOPE:
 * - Tests read-only collections: appointments, providers
 * - Integration scenarios: Lead→Client conversion, multi-app payment tracking
 * - Validates CRM can read Scheduler-owned collections
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

const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST || '';
const [emulatorHostname, emulatorPortString] = (emulatorHost || 'localhost:8080').split(':');
const emulatorPort = emulatorPortString ? parseInt(emulatorPortString, 10) : 8080;
const describeIfEmulator = emulatorHost ? describe : describe.skip;

// ============================================
// Test Configuration
// ============================================

describeIfEmulator('Cross-repo integration (emulator required)', () => {
let testEnv: RulesTestEnvironment;

const BUSINESS_ID = 'test-business-123';
const USER_ID = 'test-user-123';

// ============================================
// Test Environment Setup & Teardown
// ============================================

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'crm-cross-repo-test-2',
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

// ============================================
// Contract Tests: appointments/{appointmentId} Collection
// ============================================

describe('Shared Schema Contract: appointments/{appointmentId}', () => {
  it('should be readable by CRM for client timeline', async () => {
    const requiredFields = [
      'id',
      'clientId',
      'clientName',
      'providerId',
      'providerName',
      'serviceId',
      'serviceName',
      'startTime',
      'endTime',
      'status',
      'createdAt',
    ];

    // Scheduler creates an appointment
    const schedulerAppointment = {
      id: 'appt-123',
      clientId: 'client-123',
      clientName: 'John Doe',
      providerId: 'provider-123',
      providerName: 'Dr. Smith',
      serviceId: 'service-123',
      serviceName: 'Consultation',
      startTime: Timestamp.now(),
      endTime: Timestamp.now(),
      status: 'scheduled',
      notes: 'First visit',
      createdAt: Timestamp.now(),
    };

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(
        doc(db, `businesses/${BUSINESS_ID}/appointments/appt-123`),
        schedulerAppointment
      );
    });

    // CRM reads the appointment for client timeline
    const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
      businessId: BUSINESS_ID,
      role: 'staff',
    });
    const db = authenticatedContext.firestore();

    const apptDoc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/appointments/appt-123`))
    );
    const apptData = apptDoc.data();

    // Validate required fields
    const validation = hasRequiredFields(apptData, requiredFields);
    expect(validation.valid, `Missing fields: ${validation.missing.join(', ')}`).toBe(true);

    // Validate CRM can read all fields
    expect(apptData?.clientId).toBe('client-123');
    expect(apptData?.clientName).toBe('John Doe');
    expect(apptData?.status).toBe('scheduled');
  });

  it('should support various appointment statuses', async () => {
    const validStatuses = ['scheduled', 'confirmed', 'completed', 'cancelled', 'no_show'];

    for (const status of validStatuses) {
      const appointment = {
        id: `appt-${status}`,
        clientId: 'client-123',
        clientName: 'John Doe',
        providerId: 'provider-123',
        providerName: 'Dr. Smith',
        serviceId: 'service-123',
        serviceName: 'Consultation',
        startTime: Timestamp.now(),
        endTime: Timestamp.now(),
        status: status,
        createdAt: Timestamp.now(),
      };

      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(
          doc(db, `businesses/${BUSINESS_ID}/appointments/appt-${status}`),
          appointment
        );
      });

      const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
        businessId: BUSINESS_ID,
        role: 'staff',
      });
      const db = authenticatedContext.firestore();

      const apptDoc = await assertSucceeds(
        getDoc(doc(db, `businesses/${BUSINESS_ID}/appointments/appt-${status}`))
      );

      expect(apptDoc.data()?.status).toBe(status);
    }
  });
});

// ============================================
// Contract Tests: message_history/{messageId} Collection
// ============================================

describe('Shared Schema Contract: message_history/{messageId}', () => {
  it('should be readable by CRM for client communication history', async () => {
    const requiredFields = [
      'id',
      'clientId',
      'type',
      'direction',
      'preview',
      'sentAt',
      'status',
    ];

    const schedulerMessage = {
      id: 'msg-123',
      clientId: 'client-123',
      type: 'email',
      direction: 'outbound',
      subject: 'Appointment Reminder',
      preview: 'Reminder: your appointment is tomorrow at 10:00 AM.',
      sentAt: Timestamp.now(),
      status: 'delivered',
      createdAt: Timestamp.now(),
    };

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(
        doc(db, `businesses/${BUSINESS_ID}/message_history/msg-123`),
        schedulerMessage
      );
    });

    const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
      businessId: BUSINESS_ID,
      role: 'staff',
    });
    const db = authenticatedContext.firestore();

    const messageDoc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/message_history/msg-123`))
    );
    const messageData = messageDoc.data();

    const validation = hasRequiredFields(messageData, requiredFields);
    expect(validation.valid, `Missing fields: ${validation.missing.join(', ')}`).toBe(true);
    expect(messageData?.type).toBe('email');
    expect(messageData?.direction).toBe('outbound');
    expect(messageData?.status).toBe('delivered');
  });
});

// ============================================
// Contract Tests: providers/{providerId} Collection
// ============================================

describe('Shared Schema Contract: providers/{providerId}', () => {
  it('should be readable by CRM for assignee lookup', async () => {
    const requiredFields = [
      'id',
      'firstName',
      'lastName',
      'email',
      'colorHex',
      'isActive',
      'createdAt',
    ];

    // Scheduler creates a provider
    const schedulerProvider = {
      id: 'provider-123',
      userId: USER_ID,
      firstName: 'Jane',
      lastName: 'Smith',
      email: 'jane@example.com',
      phone: '+1234567890',
      colorHex: '#6366f1',
      isActive: true,
      createdAt: Timestamp.now(),
    };

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(
        doc(db, `businesses/${BUSINESS_ID}/providers/provider-123`),
        schedulerProvider
      );
    });

    // CRM reads the provider for assignee dropdown
    const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
      businessId: BUSINESS_ID,
      role: 'staff',
    });
    const db = authenticatedContext.firestore();

    const providerDoc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/providers/provider-123`))
    );
    const providerData = providerDoc.data();

    // Validate required fields
    const validation = hasRequiredFields(providerData, requiredFields);
    expect(validation.valid, `Missing fields: ${validation.missing.join(', ')}`).toBe(true);

    // Validate CRM can use provider data
    expect(providerData?.firstName).toBe('Jane');
    expect(providerData?.lastName).toBe('Smith');
    expect(providerData?.isActive).toBe(true);
    expect(providerData?.colorHex).toBe('#6366f1');
  });

  it('should handle inactive providers correctly', async () => {
    const inactiveProvider = {
      id: 'provider-inactive',
      firstName: 'Inactive',
      lastName: 'Provider',
      email: 'inactive@example.com',
      colorHex: '#ef4444',
      isActive: false,
      createdAt: Timestamp.now(),
    };

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(
        doc(db, `businesses/${BUSINESS_ID}/providers/provider-inactive`),
        inactiveProvider
      );
    });

    const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
      businessId: BUSINESS_ID,
      role: 'staff',
    });
    const db = authenticatedContext.firestore();

    const providerDoc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/providers/provider-inactive`))
    );

    expect(providerDoc.data()?.isActive).toBe(false);
  });
});

// ============================================
// Integration Scenario Tests
// ============================================

describe('Integration Scenario: Lead → Client Conversion', () => {
  it('should create valid client document that Scheduler can use', async () => {
    // CRM converts a lead to a client
    const convertedClient = {
      id: 'client-converted-123',
      firstName: 'Sarah',
      lastName: 'Connor',
      email: 'sarah@example.com',
      phone: '+1555000000',
      tags: ['converted-lead'],
      lifecycle: 'prospect',
      createdAt: Timestamp.now(),
      // CRM fields from lead
      leadSource: 'website',
      companyName: 'Cyberdyne',
      title: 'Director',
    };

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(
        doc(db, `businesses/${BUSINESS_ID}/clients/client-converted-123`),
        convertedClient
      );
    });

    // Scheduler reads the client for booking
    const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
      businessId: BUSINESS_ID,
      role: 'staff',
    });
    const db = authenticatedContext.firestore();

    const clientDoc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/clients/client-converted-123`))
    );
    const clientData = clientDoc.data();

    // Verify Scheduler has all needed fields
    expect(clientData?.firstName).toBe('Sarah');
    expect(clientData?.lastName).toBe('Connor');
    expect(clientData?.email).toBe('sarah@example.com');
    expect(clientData?.phone).toBe('+1555000000');

    // Verify CRM fields don't break Scheduler
    expect(clientData?.leadSource).toBe('website');
  });

  it('should preserve all core fields during conversion', async () => {
    const coreRequiredFields = ['id', 'firstName', 'lastName', 'email', 'tags', 'createdAt'];

    const convertedClient = {
      id: 'client-conversion-test',
      firstName: 'Test',
      lastName: 'Conversion',
      email: 'test@example.com',
      tags: ['lead-converted', 'vip'],
      createdAt: Timestamp.now(),
      companyId: 'company-abc',
      title: 'Manager',
    };

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(
        doc(db, `businesses/${BUSINESS_ID}/clients/client-conversion-test`),
        convertedClient
      );
    });

    const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
      businessId: BUSINESS_ID,
      role: 'staff',
    });
    const db = authenticatedContext.firestore();

    const clientDoc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/clients/client-conversion-test`))
    );
    const clientData = clientDoc.data();

    // Validate all core fields present
    const validation = hasRequiredFields(clientData, coreRequiredFields);
    expect(validation.valid, `Missing fields: ${validation.missing.join(', ')}`).toBe(true);
  });
});

describe('Integration Scenario: Multi-App Payment Tracking', () => {
  it('should track payments from both Scheduler and CRM', async () => {
    const clientId = 'client-multi-pay';

    // Scheduler creates appointment payment
    const schedulerPayment = {
      id: 'payment-scheduler',
      amountCents: 15000,
      currency: 'USD',
      status: 'succeeded',
      method: 'card',
      clientId: clientId,
      clientName: 'Multi Pay Client',
      processedById: USER_ID,
      processedByName: 'Scheduler',
      processedAt: Timestamp.now(),
      createdAt: Timestamp.now(),
    };

    // CRM creates deal payment
    const crmPayment = {
      id: 'payment-crm',
      amountCents: 50000,
      currency: 'USD',
      status: 'succeeded',
      method: 'bank_transfer',
      clientId: clientId,
      clientName: 'Multi Pay Client',
      dealId: 'deal-123',
      dealTitle: 'Enterprise Deal',
      processedById: USER_ID,
      processedByName: 'CRM Admin',
      processedAt: Timestamp.now(),
      createdAt: Timestamp.now(),
    };

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(
        doc(db, `businesses/${BUSINESS_ID}/payments/payment-scheduler`),
        schedulerPayment
      );
      await setDoc(doc(db, `businesses/${BUSINESS_ID}/payments/payment-crm`), crmPayment);
    });

    // Both apps can read both payments
    const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
      businessId: BUSINESS_ID,
      role: 'staff',
    });
    const db = authenticatedContext.firestore();

    const schedulerDoc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/payments/payment-scheduler`))
    );
    const crmDoc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/payments/payment-crm`))
    );

    expect(schedulerDoc.data()?.amountCents).toBe(15000);
    expect(crmDoc.data()?.amountCents).toBe(50000);
    expect(crmDoc.data()?.dealId).toBe('deal-123');

    // Total payments = 65000 cents
    const total =
      (schedulerDoc.data()?.amountCents ?? 0) + (crmDoc.data()?.amountCents ?? 0);
    expect(total).toBe(65000);
  });

  it('should allow both apps to query same client payments', async () => {
    const clientId = 'client-shared';

    // Create multiple payments for same client
    const payments = [
      {
        id: 'payment-1',
        amountCents: 10000,
        currency: 'USD',
        status: 'succeeded',
        method: 'card',
        clientId,
        clientName: 'Shared Client',
        processedById: USER_ID,
        processedByName: 'User',
        processedAt: Timestamp.now(),
        createdAt: Timestamp.now(),
      },
      {
        id: 'payment-2',
        amountCents: 25000,
        currency: 'USD',
        status: 'succeeded',
        method: 'cash',
        clientId,
        clientName: 'Shared Client',
        dealId: 'deal-456',
        processedById: USER_ID,
        processedByName: 'User',
        processedAt: Timestamp.now(),
        createdAt: Timestamp.now(),
      },
    ];

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      for (const payment of payments) {
        await setDoc(doc(db, `businesses/${BUSINESS_ID}/payments/${payment.id}`), payment);
      }
    });

    // Both CRM and Scheduler can read payments
    const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
      businessId: BUSINESS_ID,
      role: 'staff',
    });
    const db = authenticatedContext.firestore();

    const payment1Doc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/payments/payment-1`))
    );
    const payment2Doc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/payments/payment-2`))
    );

    expect(payment1Doc.exists()).toBe(true);
    expect(payment2Doc.exists()).toBe(true);
    expect(payment1Doc.data()?.clientId).toBe(clientId);
    expect(payment2Doc.data()?.clientId).toBe(clientId);
  });
});

describe('Integration Scenario: Client Timeline Across Apps', () => {
  it('should show appointments and payments for client across apps', async () => {
    const clientId = 'client-timeline';

    // Create client
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, `businesses/${BUSINESS_ID}/clients/${clientId}`), {
        id: clientId,
        firstName: 'Timeline',
        lastName: 'Client',
        email: 'timeline@test.com',
        tags: [],
        createdAt: Timestamp.now(),
      });

      // Scheduler creates appointment
      await setDoc(doc(db, `businesses/${BUSINESS_ID}/appointments/appt-timeline`), {
        id: 'appt-timeline',
        clientId,
        clientName: 'Timeline Client',
        providerId: 'provider-1',
        providerName: 'Dr. Test',
        serviceId: 'service-1',
        serviceName: 'Consultation',
        startTime: Timestamp.now(),
        endTime: Timestamp.now(),
        status: 'completed',
        createdAt: Timestamp.now(),
      });

      // CRM creates payment
      await setDoc(doc(db, `businesses/${BUSINESS_ID}/payments/payment-timeline`), {
        id: 'payment-timeline',
        amountCents: 15000,
        currency: 'USD',
        status: 'succeeded',
        method: 'card',
        clientId,
        clientName: 'Timeline Client',
        dealId: 'deal-timeline',
        processedById: USER_ID,
        processedByName: 'CRM User',
        processedAt: Timestamp.now(),
        createdAt: Timestamp.now(),
      });
    });

    // CRM can read both appointment and payment for timeline
    const authenticatedContext = testEnv.authenticatedContext(USER_ID, {
      businessId: BUSINESS_ID,
      role: 'staff',
    });
    const db = authenticatedContext.firestore();

    const apptDoc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/appointments/appt-timeline`))
    );
    const paymentDoc = await assertSucceeds(
      getDoc(doc(db, `businesses/${BUSINESS_ID}/payments/payment-timeline`))
    );

    expect(apptDoc.data()?.clientId).toBe(clientId);
    expect(paymentDoc.data()?.clientId).toBe(clientId);
    expect(apptDoc.data()?.status).toBe('completed');
    expect(paymentDoc.data()?.dealId).toBe('deal-timeline');
  });
});

});
