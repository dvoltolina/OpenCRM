import { type Payment, type PaymentType } from '../types/models';
import {
  assertDemoMutationAllowed,
} from '../config/demo';
import { logAuditEvent } from './auditLog';
import {
  callTenantFunction,
  fetchCollection,
  postTenantEndpoint,
  scopedCollection,
} from './firestoreBase';
import {
  doc,
  getDoc,
} from 'firebase/firestore';
import { getDb } from '../lib/firebase';

export type PaymentFilters = {
  clientId?: string;
  appointmentId?: string;
  status?: Payment['status'];
};

export type PaymentIntentInput = {
  amountCents: number;
  currency: string;
  clientId: string;
  appointmentId?: string;
  captureMethod?: 'automatic' | 'manual';
  type?: PaymentType;
};

export async function listPayments(
  businessId: string,
  filters: PaymentFilters = {},
  userId?: string,
): Promise<Payment[]> {
  const scoped = scopedCollection<Payment>(businessId, ['payments']);
  const rows = await fetchCollection(scoped);
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiReadList',
    entityType: 'Payment',
    entityId: businessId,
    metadata: {
      source: 'listPayments',
      hasClientFilter: Boolean(filters.clientId),
      hasAppointmentFilter: Boolean(filters.appointmentId),
      status: filters.status,
      count: rows.length,
    },
  });
  return rows.filter((row) => {
    if (filters.clientId && row.clientId !== filters.clientId) return false;
    if (filters.appointmentId && row.appointmentId !== filters.appointmentId) return false;
    if (filters.status && row.status !== filters.status) return false;
    return true;
  });
}

export async function createPaymentIntent(
  businessId: string,
  input: PaymentIntentInput,
  userId?: string,
): Promise<{ clientSecret?: string; paymentIntentId?: string }> {
  assertDemoMutationAllowed('create payment');
  if (!businessId) throw new Error('businessId is required to create a payment');
  const result = await postTenantEndpoint<
    {
      amount: number;
      currency: string;
      clientId: string;
      appointmentId?: string;
      metadata: {
        businessId: string;
        clientId: string;
        appointmentId: string | null;
      };
    },
    { clientSecret?: string; paymentIntentId?: string }
  >('/createPaymentIntent', businessId, {
      amount: input.amountCents,
      currency: input.currency,
      clientId: input.clientId,
      appointmentId: input.appointmentId,
      metadata: {
        businessId,
        clientId: input.clientId,
        appointmentId: input.appointmentId ?? null,
      },
  });
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'Payment',
    entityId: input.appointmentId ?? 'unknown',
    metadata: {
      source: 'createPaymentIntent',
      hasAppointment: Boolean(input.appointmentId),
      amountCents: input.amountCents,
    },
  });
  return result;
}

export async function refundPayment(
  businessId: string,
  paymentId: string,
  amountCents?: number,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('refund payment');
  if (!businessId) throw new Error('businessId is required to refund a payment');
  await postTenantEndpoint('/refundPayment', businessId, {
    paymentIntentId: paymentId, // Backend expects paymentIntentId
    amount: amountCents,
    appointmentId: undefined,
  });
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'Payment',
    entityId: paymentId,
    metadata: { source: 'refundPayment', hasAmount: amountCents !== undefined },
  });
}

export async function getCustomerPortalUrl(businessId: string, userId?: string): Promise<string> {
  assertDemoMutationAllowed('open customer portal');
  if (!businessId) {
    throw new Error('businessId is required to open the customer portal');
  }

  const response = await callTenantFunction<{ businessId: string }, { url?: string }>(
    'billingCreatePortalSession',
    businessId,
    { businessId },
  );
  const url = typeof response?.url === 'string' ? response.url.trim() : '';
  if (!url) {
    throw new Error('Billing portal URL is unavailable for this workspace.');
  }
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'dataExport',
    entityType: 'Payment',
    entityId: businessId,
    metadata: { source: 'getCustomerPortalUrl' },
  });
  return url;
}

export async function getPaymentReceiptUrl(
  businessId: string,
  paymentId: string,
  userId?: string,
): Promise<string | null> {
  if (!businessId) throw new Error('businessId is required to retrieve a receipt');
  if (!paymentId) throw new Error('paymentId is required to retrieve a receipt');

  const db = getDb();
  const snap = await getDoc(doc(db, 'businesses', businessId, 'payments', paymentId));
  const data = snap.exists() ? (snap.data() as Payment & Record<string, unknown>) : null;
  const candidates = [
    data?.receiptUrl,
    data?.stripeReceiptUrl,
    data?.hostedInvoiceUrl,
    data?.invoicePdfUrl,
    data?.receipt_url,
  ];
  let url =
    candidates.find((value): value is string => typeof value === 'string' && value.trim().length > 0) ?? null;

  if (!url) {
    const response = await postTenantEndpoint<
      { paymentId: string },
      { url?: string | null; success?: boolean; source?: string }
    >('/getPaymentReceiptUrl', businessId, { paymentId });
    url = typeof response?.url === 'string' && response.url.trim().length > 0 ? response.url : null;
  }

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'dataExport',
    entityType: 'Payment',
    entityId: paymentId,
    metadata: {
      source: 'getPaymentReceiptUrl',
      foundReceiptUrl: Boolean(url),
    },
  });

  return url;
}
