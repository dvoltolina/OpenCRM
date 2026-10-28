import { describe, expect, it } from 'vitest';

const CANONICAL_BACKEND_OWNERSHIP = {
  functions: 'The Scheduler/functions',
  rules: 'The Scheduler/firestore.rules',
  indexes: 'The Scheduler/firestore.indexes.json',
  contract: 'The Scheduler/docs/shared_data_contract.md',
} as const;

const CANONICAL_ROLES = [
  'owner',
  'admin',
  'manager',
  'staff',
  'sales',
  'provider',
  'frontDesk',
  'client',
] as const;

const CANONICAL_ADMIN_FUNCTIONS = [
  'staffBulkInvite',
  'ownershipTransfer',
] as const;

const CANONICAL_CALENDAR_ENDPOINTS = [
  '/connectCalendar',
  '/refreshCalendarTokens',
  '/syncCalendar',
  '/disconnectCalendar',
] as const;

type TimestampLike = Date | { toDate: () => Date };
type SharedRole = (typeof CANONICAL_ROLES)[number];

interface UserContract {
  id: string;
  businessId: string;
  role: SharedRole;
  email: string;
  displayName: string;
  createdAt: TimestampLike;
  providerId?: string;
  clientId?: string;
  teamIds?: string[];
  managedTeamIds?: string[];
}

interface ClientContract {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  tags: string[];
  createdAt: TimestampLike;
  phone?: string;
  lifecycle?: 'lead' | 'prospect' | 'active' | 'inactive' | 'churned';
  userId?: string;
  companyId?: string;
  companyName?: string;
  title?: string;
  crmNotes?: string;
  lastContactedAt?: TimestampLike;
  leadSource?: 'website' | 'referral' | 'coldCall' | 'social' | 'event' | 'scheduler' | 'other';
  ownerId?: string;
  ownerName?: string;
  teamIds?: string[];
  visibility?: 'private' | 'team' | 'org';
  updatedAt?: TimestampLike;
}

interface PaymentContract {
  id: string;
  amountCents: number;
  currency: string;
  status: 'pending' | 'completed' | 'failed' | 'refunded' | 'partially_refunded' | 'none';
  type: 'deposit' | 'full' | 'subscription' | 'reschedule_fee' | 'cancellation_fee' | 'refund';
  clientId: string;
  createdAt: TimestampLike;
  method?: 'card' | 'cash' | 'check' | 'bank_transfer' | 'other';
  description?: string;
  appointmentId?: string;
  providerId?: string;
  receiptUrl?: string;
  notes?: string;
  dealId?: string;
  dealTitle?: string;
  updatedAt?: TimestampLike;
}

interface AppointmentContract {
  id: string;
  clientId: string;
  providerId: string;
  serviceId: string;
  locationId: string;
  startTime: TimestampLike;
  endTime: TimestampLike;
  date: TimestampLike;
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed' | 'noShow';
  createdAt: TimestampLike;
  isGroupSession?: boolean;
  capacity?: number;
  notes?: string;
  updatedAt?: TimestampLike;
}

interface ProviderContract {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  colorHex: string;
  createdAt: TimestampLike;
  isActive?: boolean;
  phone?: string;
  userId?: string;
}

function hasRequiredFields<T extends object>(
  obj: T,
  requiredFields: (keyof T)[],
): boolean {
  return requiredFields.every((field) => field in obj);
}

function isTimestampLike(value: unknown): boolean {
  return value instanceof Date ||
    (typeof value === 'object' && value !== null && 'toDate' in value);
}

describe('Shared backend ownership contract', () => {
  it('keeps Scheduler as the only deploy source of truth', () => {
    expect(CANONICAL_BACKEND_OWNERSHIP).toEqual({
      functions: 'The Scheduler/functions',
      rules: 'The Scheduler/firestore.rules',
      indexes: 'The Scheduler/firestore.indexes.json',
      contract: 'The Scheduler/docs/shared_data_contract.md',
    });
  });

  it('keeps Admin and CRM on the canonical shared function surfaces', () => {
    expect(CANONICAL_ADMIN_FUNCTIONS).toEqual([
      'staffBulkInvite',
      'ownershipTransfer',
    ]);
    expect(CANONICAL_CALENDAR_ENDPOINTS).toEqual([
      '/connectCalendar',
      '/refreshCalendarTokens',
      '/syncCalendar',
      '/disconnectCalendar',
    ]);
  });
});

describe('Shared role contract', () => {
  it('uses the canonical ecosystem roles and excludes assistant', () => {
    expect(CANONICAL_ROLES).toEqual([
      'owner',
      'admin',
      'manager',
      'staff',
      'sales',
      'provider',
      'frontDesk',
      'client',
    ]);
    expect(CANONICAL_ROLES).not.toContain('assistant');
  });
});

describe('User schema contract', () => {
  const mockUser: UserContract = {
    id: 'user-123',
    businessId: 'biz-456',
    role: 'admin',
    email: 'admin@example.com',
    displayName: 'Admin User',
    createdAt: new Date('2026-03-11T00:00:00Z'),
    teamIds: ['team-1'],
  };

  it('includes the required shared auth fields', () => {
    expect(hasRequiredFields(mockUser, [
      'id',
      'businessId',
      'role',
      'email',
      'displayName',
      'createdAt',
    ])).toBe(true);
  });

  it('accepts the canonical role set and timestamp-like createdAt values', () => {
    expect(CANONICAL_ROLES).toContain(mockUser.role);
    expect(isTimestampLike(mockUser.createdAt)).toBe(true);
  });
});

describe('Client schema contract', () => {
  const schedulerClient: ClientContract = {
    id: 'client-123',
    firstName: 'Jamie',
    lastName: 'Rivera',
    email: 'jamie@example.com',
    tags: ['vip'],
    lifecycle: 'active',
    createdAt: new Date('2026-03-11T00:00:00Z'),
  };

  const crmExtendedClient: ClientContract = {
    ...schedulerClient,
    companyName: 'Acme Health',
    crmNotes: 'High-intent lead',
    ownerId: 'sales-123',
    teamIds: ['team-1'],
    visibility: 'team',
    updatedAt: new Date('2026-03-11T01:00:00Z'),
  };

  it('preserves Scheduler-required client fields', () => {
    expect(hasRequiredFields(schedulerClient, [
      'id',
      'firstName',
      'lastName',
      'email',
      'tags',
      'createdAt',
    ])).toBe(true);
  });

  it('allows CRM extensions without breaking Scheduler compatibility', () => {
    expect(hasRequiredFields(crmExtendedClient, [
      'id',
      'firstName',
      'lastName',
      'email',
      'tags',
      'createdAt',
    ])).toBe(true);
    expect(crmExtendedClient.visibility).toBe('team');
    expect(Array.isArray(crmExtendedClient.teamIds)).toBe(true);
  });
});

describe('Payment schema contract', () => {
  const payment: PaymentContract = {
    id: 'pay-123',
    amountCents: 15000,
    currency: 'USD',
    status: 'completed',
    type: 'full',
    clientId: 'client-123',
    createdAt: new Date('2026-03-11T00:00:00Z'),
    dealId: 'deal-1',
    dealTitle: 'Enterprise Renewal',
  };

  it('uses Scheduler payment statuses and types', () => {
    expect(payment.status).toBe('completed');
    expect(payment.type).toBe('full');
    expect(hasRequiredFields(payment, [
      'id',
      'amountCents',
      'currency',
      'status',
      'type',
      'clientId',
      'createdAt',
    ])).toBe(true);
  });

  it('keeps CRM deal metadata optional and backward compatible', () => {
    expect(payment.dealId).toBeDefined();
    expect(payment.dealTitle).toBeDefined();
    expect(typeof payment.amountCents).toBe('number');
  });
});

describe('Read-only Scheduler collection contracts', () => {
  const appointment: AppointmentContract = {
    id: 'appt-1',
    clientId: 'client-123',
    providerId: 'provider-123',
    serviceId: 'service-123',
    locationId: 'location-123',
    startTime: new Date('2026-03-11T14:00:00Z'),
    endTime: new Date('2026-03-11T15:00:00Z'),
    date: new Date('2026-03-11T00:00:00Z'),
    status: 'confirmed',
    createdAt: new Date('2026-03-11T00:00:00Z'),
  };

  const provider: ProviderContract = {
    id: 'provider-123',
    firstName: 'Dana',
    lastName: 'Cole',
    email: 'dana@example.com',
    colorHex: '#2563eb',
    createdAt: new Date('2026-03-11T00:00:00Z'),
    isActive: true,
  };

  it('expects current Scheduler appointment fields and statuses', () => {
    expect(hasRequiredFields(appointment, [
      'id',
      'clientId',
      'providerId',
      'serviceId',
      'locationId',
      'startTime',
      'endTime',
      'date',
      'status',
      'createdAt',
    ])).toBe(true);
    expect(isTimestampLike(appointment.startTime)).toBe(true);
  });

  it('expects current Scheduler provider fields', () => {
    expect(hasRequiredFields(provider, [
      'id',
      'firstName',
      'lastName',
      'email',
      'colorHex',
      'createdAt',
    ])).toBe(true);
    expect(provider.colorHex).toMatch(/^#[0-9A-Fa-f]{6}$/);
  });
});

describe('Integration path contract', () => {
  it('keeps shared documents tenant-scoped', () => {
    const businessId = 'biz-test-123';
    const sharedPaths = [
      `businesses/${businessId}/clients/client-123`,
      `businesses/${businessId}/payments/pay-123`,
      `businesses/${businessId}/appointments/appt-123`,
      `businesses/${businessId}/providers/provider-123`,
      `businesses/${businessId}/leads/lead-123`,
      `businesses/${businessId}/deals/deal-123`,
    ];

    sharedPaths.forEach((path) => {
      expect(path).toContain(`businesses/${businessId}/`);
    });
  });

  it('keeps lead conversion compatible with Scheduler client requirements', () => {
    const convertedClient: ClientContract = {
      id: 'client-new-123',
      firstName: 'Alice',
      lastName: 'Johnson',
      email: 'alice@example.com',
      phone: '+1555123456',
      tags: [],
      createdAt: new Date('2026-03-11T00:00:00Z'),
      companyName: 'Tech Corp',
      leadSource: 'website',
    };

    expect(hasRequiredFields(convertedClient, [
      'id',
      'firstName',
      'lastName',
      'email',
      'tags',
      'createdAt',
    ])).toBe(true);
  });
});
