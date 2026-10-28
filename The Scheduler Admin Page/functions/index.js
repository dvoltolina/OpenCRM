const functions = require('firebase-functions');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');
const {
  deriveEntitlements,
  normalizeStatus,
  normalizeStripeEvent,
  verifyStripeWebhook,
  buildStubCheckoutUrl,
  parseAddOnIds,
} = require('./billing');
const {
  generateReportMock,
  buildCsvFromReport,
  buildPdfBuffer,
  buildFileName,
  createDataUrl,
} = require('./reporting');

admin.initializeApp();
const firestore = admin.firestore();
const { FieldValue } = admin.firestore;
exports.ping = onRequest((req, res) => {
  res.status(200).send('ok');
});
exports.billing = onRequest(async (req, res) => {
  applyCorsHeaders(req, res);

  if (req.method === 'OPTIONS') {
    return res.status(204).send('');
  }

  const path = normalizePath(req.path);

  try {
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'method_not_allowed' });
    }

    if (path === '/create-checkout-session') {
      return await handleCreateCheckoutSession(req, res);
    }
    if (path === '/create-portal-session') {
      return await handleCreatePortalSession(req, res);
    }
    if (path === '/webhook') {
      return await handleBillingWebhook(req, res);
    }

    return res.status(404).json({ error: 'not_found' });
  } catch (error) {
    const status = Number.isInteger(error.status) ? error.status : Number(error.code) || 500;
    logger.error('Billing endpoint failed', {
      path,
      status,
      message: error.message,
    });
    return res.status(status).json({
      error: error.publicMessage || 'server_error',
    });
  }
});

const billingCreateCheckoutSession = onCall(async (request) => {
  requireAuth(request);
  const { data, auth } = request;
  const businessId = requireBusinessId(data);
  const profile = await loadUserProfile(auth.uid);
  if (!profile || profile.businessId !== businessId) {
    throw new HttpsError('permission-denied', 'Tenant mismatch');
  }
  if (profile.role !== 'owner') {
    throw new HttpsError('permission-denied', 'Owner role required');
  }

  const planId =
    (typeof data.plan === 'string' && data.plan) ||
    (typeof data.planId === 'string' && data.planId) ||
    'starter';
  const addOnIds = parseAddOnIds(data.addOns || data.addons);
  const parsedSeats = Number(data.seats);
  const seats = Number.isFinite(parsedSeats) && parsedSeats > 0 ? Math.round(parsedSeats) : undefined;

  return createCheckoutSession({
    businessId,
    uid: auth.uid,
    planId,
    addOnIds,
    seats,
  });
});
exports['billing-createCheckoutSession'] = billingCreateCheckoutSession;

const billingCreatePortalSession = onCall(async (request) => {
  requireAuth(request);
  const { data, auth } = request;
  const businessId = requireBusinessId(data);
  const profile = await loadUserProfile(auth.uid);
  if (!profile || profile.businessId !== businessId) {
    throw new HttpsError('permission-denied', 'Tenant mismatch');
  }
  if (profile.role !== 'owner') {
    throw new HttpsError('permission-denied', 'Owner role required');
  }

  const snapshot = await firestore.doc(`businesses/${businessId}/subscriptions/current`).get();
  const subscription = snapshot.exists ? snapshot.data() : {};
  const url = buildPortalUrl(businessId, subscription?.stripeCustomerId);

  await writeAuditEvent(businessId, auth.uid, 'billingPortalRequested', {
    subscriptionId: subscription?.subscriptionId || null,
    status: subscription?.status || null,
  });

  return { url };
});
exports['billing-createPortalSession'] = billingCreatePortalSession;

const authProvisionWorkspace = onCall(async (request) => {
  requireAuth(request);
  const { data, auth } = request;
  const uid = auth.uid;
  const displayName =
    (typeof data?.displayName === 'string' && data.displayName.trim()) || '';
  const email = (typeof data?.email === 'string' && data.email.trim()) || '';
  const businessName =
    (typeof data?.businessName === 'string' && data.businessName.trim()) ||
    displayName ||
    email ||
    'New Business';

  const userRef = firestore.doc(`users/${uid}`);
  const userSnap = await userRef.get();
  const existingBusinessId = userSnap.exists ? userSnap.get('businessId') : null;
  const businessId = existingBusinessId || `biz_${uid}`;

  const now = FieldValue.serverTimestamp();

  await firestore.doc(`businesses/${businessId}`).set(
    {
      name: businessName,
      ownerUserId: uid,
      createdAt: now,
      updatedAt: now,
      requiresHipaaCompliance: false,
      mfaEnabled: false,
    },
    { merge: true },
  );

  await userRef.set(
    {
      uid,
      email,
      displayName: displayName || email || 'Owner',
      role: 'owner',
      businessId,
      createdAt: now,
    },
    { merge: true },
  );

  await firestore.doc(`businesses/${businessId}/subscriptions/current`).set(
    {
      businessId,
      status: 'incomplete',
      seats: 0,
      addOnIds: [],
      addonIds: [],
      entitlements: {},
      updatedAt: now,
    },
    { merge: true },
  );

  await writeAuditEvent(businessId, uid, 'workspaceProvisioned', {
    businessId,
    email,
  });

  return { businessId };
});
exports['auth-provisionWorkspace'] = authProvisionWorkspace;

const paymentsGetCustomerPortalUrl = onCall((request) => {
  requireAuth(request);
  const { data, auth } = request;
  const businessId = requireBusinessId(data);
  logger.info('Generating customer portal URL', { businessId, uid: auth?.uid });

  const portalUrl = buildCustomerPortalUrl(businessId);
  return { url: portalUrl };
});
exports['payments-getCustomerPortalUrl'] = paymentsGetCustomerPortalUrl;

const reportingExportCsv = onCall((request) => {
  requireAuth(request);
  const normalized = normalizeReportRequest(request.data);
  logger.info('Generating CSV report export', {
    businessId: normalized.businessId,
    startDate: normalized.startDate,
    endDate: normalized.endDate,
    granularity: normalized.granularity,
    uid: request.auth?.uid,
  });

  const report = generateReportMock(normalized.startDate, normalized.endDate);
  const csv = buildCsvFromReport(report, normalized);
  return {
    url: createDataUrl(csv, 'text/csv'),
    mimeType: 'text/csv',
    fileName: buildFileName(normalized, 'csv'),
  };
});
exports['reporting-exportCsv'] = reportingExportCsv;

const reportingExportPdf = onCall((request) => {
  requireAuth(request);
  const normalized = normalizeReportRequest(request.data);
  logger.info('Generating PDF report export', {
    businessId: normalized.businessId,
    startDate: normalized.startDate,
    endDate: normalized.endDate,
    granularity: normalized.granularity,
    uid: request.auth?.uid,
  });

  const report = generateReportMock(normalized.startDate, normalized.endDate);
  const pdfBuffer = buildPdfBuffer(report, normalized);
  return {
    url: `data:application/pdf;base64,${pdfBuffer.toString('base64')}`,
    mimeType: 'application/pdf',
    fileName: buildFileName(normalized, 'pdf'),
  };
});
exports['reporting-exportPdf'] = reportingExportPdf;

// Namespace exports to satisfy existing entrypoints (billing.createCheckoutSession, etc.)
exports.billing = exports.billing || {};
exports.billing.createCheckoutSession = billingCreateCheckoutSession;
exports.billing.createPortalSession = billingCreatePortalSession;
exports.auth = exports.auth || {};
exports.auth.provisionWorkspace = authProvisionWorkspace;
exports.payments = exports.payments || {};
exports.payments.getCustomerPortalUrl = paymentsGetCustomerPortalUrl;
exports.reporting = exports.reporting || {};
exports.reporting.exportCsv = reportingExportCsv;
exports.reporting.exportPdf = reportingExportPdf;

function applyCorsHeaders(req, res) {
  const allowedOrigins = getAllowedOrigins();
  const origin = req.get('origin');
  if (origin && allowedOrigins.includes(origin)) {
    res.set('Access-Control-Allow-Origin', origin);
  }
  res.set('Vary', 'Origin');
  res.set('Access-Control-Allow-Methods', 'POST,OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Authorization,Content-Type,Stripe-Signature');
}

function getAllowedOrigins() {
  const configured = functions.config().billing?.allowed_origins || '';
  const defaults = ['http://localhost:5173', 'http://localhost:3000'];
  const configuredOrigins = configured
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  return [...new Set([...configuredOrigins, ...defaults])];
}

function normalizePath(path) {
  if (!path) return '/';
  const trimmed = path.endsWith('/') && path !== '/' ? path.slice(0, -1) : path;
  return trimmed.startsWith('/') ? trimmed : `/${trimmed}`;
}

async function authenticateRequest(req, options = {}) {
  const authHeader = req.get('authorization') || '';
  if (!authHeader.startsWith('Bearer ')) {
    throw createHttpError(401, 'unauthorized');
  }

  const token = authHeader.replace('Bearer ', '').trim();

  let decoded;
  try {
    decoded = await admin.auth().verifyIdToken(token);
  } catch (error) {
    throw createHttpError(401, 'unauthorized');
  }

  const uid = decoded.uid;
  const profileSnap = await firestore.doc(`users/${uid}`).get();
  const profile = profileSnap.exists ? profileSnap.data() : null;

  if (!profile?.businessId) {
    throw createHttpError(403, 'missing_business');
  }

  const body = typeof req.body === 'object' && req.body !== null ? req.body : {};
  const businessId = body.businessId || profile.businessId;

  if (businessId !== profile.businessId) {
    throw createHttpError(403, 'business_mismatch');
  }

  const role = profile.role || decoded.role || 'staff';
  if (options.requireOwner && role !== 'owner') {
    throw createHttpError(403, 'owner_only');
  }

  return { uid, businessId, role };
}

function createHttpError(status, publicMessage) {
  const error = new Error(publicMessage);
  error.status = status;
  error.publicMessage = publicMessage;
  return error;
}

async function loadUserProfile(uid) {
  if (!uid) return null;
  const snap = await firestore.doc(`users/${uid}`).get();
  return snap.exists ? snap.data() : null;
}

async function createCheckoutSession({ businessId, uid, planId, addOnIds, seats }) {
  const sessionId = `cs_${crypto.randomUUID()}`;
  const baseUrl = functions.config().billing?.checkout_base_url;
  const url = baseUrl
    ? `${baseUrl}?session_id=${encodeURIComponent(sessionId)}`
    : buildStubCheckoutUrl(sessionId);

  await firestore.doc(`businesses/${businessId}/billing_sessions/${sessionId}`).set({
    businessId,
    userId: uid,
    planId,
    addOnIds,
    seats: seats ?? null,
    status: 'pending',
    createdAt: FieldValue.serverTimestamp(),
    userAgent: null,
    ip: null,
  });

  await writeAuditEvent(businessId, uid, 'billingCheckoutCreated', {
    planId,
    addOnIds,
    seats: seats ?? null,
    sessionId,
  });

  return { url, sessionId };
}

async function handleCreateCheckoutSession(req, res) {
  const auth = await authenticateRequest(req, { requireOwner: true });
  const body = typeof req.body === 'object' && req.body !== null ? req.body : {};

  const planId =
    (typeof body.plan === 'string' && body.plan) ||
    (typeof body.planId === 'string' && body.planId) ||
    'starter';
  const addOnIds = parseAddOnIds(body.addOns || body.addons);
  const parsedSeats = Number(body.seats);
  const seats = Number.isFinite(parsedSeats) && parsedSeats > 0 ? Math.round(parsedSeats) : undefined;

  const result = await createCheckoutSession({
    businessId: auth.businessId,
    uid: auth.uid,
    planId,
    addOnIds,
    seats,
  });

  await writeAuditEvent(auth.businessId, auth.uid, 'billingCheckoutRequest', {
    planId,
    addOnIds,
    seats: seats ?? null,
    ip: req.ip,
    userAgent: req.get('user-agent') || null,
  });

  return res.status(200).json(result);
}

async function handleCreatePortalSession(req, res) {
  const auth = await authenticateRequest(req, { requireOwner: true });
  const snapshot = await firestore.doc(`businesses/${auth.businessId}/subscriptions/current`).get();
  const subscription = snapshot.exists ? snapshot.data() : {};

  const url = buildPortalUrl(auth.businessId, subscription?.stripeCustomerId);

  await writeAuditEvent(auth.businessId, auth.uid, 'billingPortalRequested', {
    subscriptionId: subscription?.subscriptionId || null,
    status: subscription?.status || null,
    ip: req.ip,
    userAgent: req.get('user-agent') || null,
  });

  return res.status(200).json({ url });
}

async function handleBillingWebhook(req, res) {
  const secret = getStripeWebhookSecret();
  const signatureHeader = req.get('stripe-signature');
  const tolerance =
    Number(functions.config().stripe?.webhook_tolerance_seconds) ||
    Number(process.env.STRIPE_WEBHOOK_TOLERANCE_SECONDS) ||
    300;
  const verification = verifyStripeWebhook(req.rawBody, signatureHeader, secret, tolerance);

  if (!verification.valid) {
    logger.warn('Stripe webhook signature failed', {
      reason: verification.reason,
      sdkError: verification.sdkError,
    });
    return res.status(400).json({ error: 'invalid_signature' });
  }

  let event = req.body;
  if (typeof req.body === 'string') {
    try {
      event = JSON.parse(req.body);
    } catch (error) {
      return res.status(400).json({ error: 'invalid_json' });
    }
  }

  const update = normalizeStripeEvent(event);

  if (!update.businessId) {
    logger.warn('Billing webhook missing businessId', { eventType: event?.type });
    return res.status(202).json({ received: true, ignored: 'missing_business' });
  }

  const applied = await applySubscriptionUpdate(update.businessId, update);

  await writeAuditEvent(update.businessId, null, 'billingWebhook', {
    eventType: update.eventType || null,
    status: applied.status,
    planId: applied.planId,
    subscriptionId: applied.subscriptionId || null,
  });

  if (event?.type === 'checkout.session.completed') {
    const sessionId = update.rawObject?.id || update.subscriptionId;
    await markCheckoutSessionComplete(update.businessId, sessionId);
  }

  return res.status(200).json({ received: true, status: applied.status });
}

async function applySubscriptionUpdate(businessId, update) {
  const status = normalizeStatus(update.status);
  const entitlements = deriveEntitlements(update.planId, update.addOnIds);
  const isActive = ['active', 'trialing', 'past_due'].includes(status);

  const flagsToWrite = {};
  entitlements.managedFlagKeys.forEach((key) => {
    if (entitlements.flags[key] !== undefined) {
      flagsToWrite[key] = isActive ? Boolean(entitlements.flags[key]) : false;
    }
  });

  const subscriptionDoc = {
    businessId,
    subscriptionId: update.subscriptionId || null,
    stripeCustomerId: update.customerId || null,
    planId: entitlements.planId,
    planLabel: entitlements.planLabel,
    status,
    seats: update.seats || entitlements.defaultSeats || null,
    addOnIds: entitlements.appliedAddOns,
    unknownAddOns: entitlements.unknownAddOns,
    trialEndsAt: update.trialEndsAt || null,
    currentPeriodEnd: update.currentPeriodEnd || null,
    lastEventType: update.eventType || null,
    entitlements: flagsToWrite,
    updatedAt: FieldValue.serverTimestamp(),
  };

  await firestore.doc(`businesses/${businessId}/subscriptions/current`).set(subscriptionDoc, {
    merge: true,
  });

  if (Object.keys(flagsToWrite).length) {
    await firestore.doc(`businesses/${businessId}/settings/feature_flags`).set(flagsToWrite, {
      merge: true,
    });
  }

  return { ...subscriptionDoc, featureFlagsApplied: flagsToWrite };
}

async function markCheckoutSessionComplete(businessId, sessionId) {
  if (!sessionId) return;
  try {
    await firestore.doc(`businesses/${businessId}/billing_sessions/${sessionId}`).set(
      {
        status: 'completed',
        completedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  } catch (error) {
    logger.warn('Failed to mark checkout session complete', { businessId, sessionId });
  }
}

async function writeAuditEvent(businessId, userId, actionType, metadata = {}) {
  if (!businessId) return;
  try {
    await firestore.collection('businesses').doc(businessId).collection('audit_logs').add({
      businessId,
      userId: userId || 'system',
      actionType,
      entityType: 'Billing',
      entityId: businessId,
      metadata: sanitizeAuditMetadata(metadata),
      timestamp: FieldValue.serverTimestamp(),
    });
  } catch (error) {
    logger.warn('Audit log write failed', { businessId, actionType });
  }
}

function sanitizeAuditMetadata(metadata) {
  if (!metadata || typeof metadata !== 'object') return {};
  const safe = {};
  Object.entries(metadata).forEach(([key, value]) => {
    if (value === undefined || value === null) return;
    if (typeof value === 'string') {
      safe[key] = value.slice(0, 120);
      return;
    }
    if (typeof value === 'number' || typeof value === 'boolean') {
      safe[key] = value;
      return;
    }
    if (Array.isArray(value)) {
      safe[key] = value.slice(0, 10).map((item) => {
        if (typeof item === 'string') return item.slice(0, 120);
        if (typeof item === 'number' || typeof item === 'boolean') return item;
        return null;
      });
    }
  });
  return safe;
}

function getStripeWebhookSecret() {
  return (
    functions.config().stripe?.webhook_secret ||
    process.env.STRIPE_WEBHOOK_SECRET ||
    ''
  );
}

function buildPortalUrl(businessId, customerId) {
  const base = functions.config().billing?.portal_base_url;
  const defaultUrl = `https://billing.example.com/portal?business=${encodeURIComponent(businessId)}`;
  const portalUrl = base || defaultUrl;
  if (!customerId) return portalUrl;
  const separator = portalUrl.includes('?') ? '&' : '?';
  return `${portalUrl}${separator}customer=${encodeURIComponent(customerId)}`;
}

function requireAuth(context) {
  if (!context.auth) {
    throw new HttpsError('unauthenticated', 'Authentication is required.');
  }
}

function requireBusinessId(data) {
  if (!data || typeof data.businessId !== 'string' || !data.businessId.trim()) {
    throw new HttpsError('invalid-argument', 'businessId is required.');
  }
  return data.businessId.trim();
}

function normalizeReportRequest(data) {
  const businessId = requireBusinessId(data);
  const today = new Date().toISOString().slice(0, 10);
  const startDate =
    typeof data.startDate === 'string' && data.startDate.trim().length > 0 ? data.startDate : today;
  const endDate =
    typeof data.endDate === 'string' && data.endDate.trim().length > 0 ? data.endDate : startDate;
  const granularity = data.granularity === 'week' ? 'week' : 'day';
  return { businessId, startDate, endDate, granularity };
}

function buildCustomerPortalUrl(businessId) {
  const slug = businessId.replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 24);
  return `https://dashboard.stripe.com/b/${slug || 'tenant'}/billing/portal?session=${Date.now()}`;
}
