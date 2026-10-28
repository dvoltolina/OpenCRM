const crypto = require('crypto');

const MANAGED_FLAG_KEYS = ['enableReporting', 'enableMarketing', 'enableImportExport'];

const PLAN_CATALOG = {
  starter: {
    label: 'Starter',
    defaultSeats: 3,
    flags: {
      enableReporting: false,
      enableMarketing: false,
      enableImportExport: false,
    },
  },
  pro: {
    label: 'Pro',
    defaultSeats: 10,
    flags: {
      enableReporting: true,
      enableMarketing: true,
      enableImportExport: true,
    },
  },
  scale: {
    label: 'Scale',
    defaultSeats: 30,
    flags: {
      enableReporting: true,
      enableMarketing: true,
      enableImportExport: true,
    },
  },
};

const ADD_ON_CATALOG = {
  'addon-reports': {
    label: 'Reports',
    flags: { enableReporting: true },
  },
  'addon-import-export': {
    label: 'Import/Export',
    flags: { enableImportExport: true },
  },
  'addon-marketing': {
    label: 'Marketing',
    flags: { enableMarketing: true },
  },
};

function parseAddOnIds(value) {
  if (!value) return [];
  if (Array.isArray(value)) return value.filter((id) => typeof id === 'string' && id.trim());
  if (typeof value === 'string') {
    return value
      .split(',')
      .map((id) => id.trim())
      .filter(Boolean);
  }
  return [];
}

function normalizeStatus(status) {
  const normalized = (status || '').toLowerCase();
  if (['active', 'trialing', 'past_due'].includes(normalized)) return normalized;
  if (['canceled', 'cancelled', 'unpaid', 'incomplete_expired'].includes(normalized)) {
    return 'canceled';
  }
  return 'incomplete';
}

function deriveEntitlements(planId, addOnIds = []) {
  const plan = PLAN_CATALOG[planId] || { label: planId || 'unknown', defaultSeats: 0, flags: {} };
  const appliedAddOns = [];
  const unknownAddOns = [];
  let flags = { ...plan.flags };

  parseAddOnIds(addOnIds).forEach((addOnId) => {
    const addOn = ADD_ON_CATALOG[addOnId];
    if (addOn) {
      appliedAddOns.push(addOnId);
      flags = { ...flags, ...addOn.flags };
    } else {
      unknownAddOns.push(addOnId);
    }
  });

  return {
    planId: planId || 'unknown',
    planLabel: plan.label,
    defaultSeats: plan.defaultSeats,
    flags,
    appliedAddOns,
    unknownAddOns,
    managedFlagKeys: MANAGED_FLAG_KEYS,
  };
}

function verifyStripeSignature(rawBody, signatureHeader, secret, toleranceSeconds = 300) {
  if (!secret) {
    return { valid: false, reason: 'missing_webhook_secret' };
  }
  if (!signatureHeader || !rawBody) {
    return { valid: false, reason: 'missing_signature' };
  }

  const segments = signatureHeader.split(',').map((segment) => segment.split('='));
  const map = Object.fromEntries(segments);
  const timestamp = map.t;
  const signature = map.v1;

  if (!timestamp || !signature) {
    return { valid: false, reason: 'invalid_signature_header' };
  }

  const payload = `${timestamp}.${rawBody.toString('utf8')}`;
  const expected = crypto.createHmac('sha256', secret).update(payload).digest('hex');

  if (signature.length !== expected.length) {
    return { valid: false, reason: 'signature_length_mismatch' };
  }

  const valid = crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected));
  const now = Math.floor(Date.now() / 1000);
  const skew = Math.abs(now - Number(timestamp));
  if (skew > toleranceSeconds) {
    return { valid: false, reason: 'timestamp_out_of_range', timestamp };
  }

  return { valid, timestamp };
}

function verifyStripeWebhook(rawBody, signatureHeader, secret, toleranceSeconds = 300) {
  // Prefer official Stripe verification but always enforce our HMAC/tolerance guard.
  const hmacResult = verifyStripeSignature(rawBody, signatureHeader, secret, toleranceSeconds);
  try {
    // Lazy require to avoid hard dependency in stub environments
    // eslint-disable-next-line global-require, import/no-extraneous-dependencies
    const Stripe = require('stripe');
    const stripe = new Stripe(process.env.STRIPE_API_KEY || 'sk_test_stub');
    const event = stripe.webhooks.constructEvent(
      rawBody,
      signatureHeader || '',
      secret || '',
      { tolerance: toleranceSeconds },
    );

    if (!hmacResult.valid) {
      return { ...hmacResult, event };
    }

    return { valid: true, event, timestamp: hmacResult.timestamp };
  } catch (sdkError) {
    return { ...hmacResult, sdkError: sdkError?.message };
  }
}

function extractBusinessId(object) {
  return (
    object?.metadata?.businessId ||
    object?.businessId ||
    object?.metadata?.tenantId ||
    null
  );
}

function extractPlanId(object) {
  return (
    object?.metadata?.planId ||
    object?.plan?.id ||
    object?.planId ||
    object?.metadata?.priceId ||
    object?.items?.data?.[0]?.price?.id ||
    null
  );
}

function extractAddOnIds(object) {
  return (
    parseAddOnIds(object?.metadata?.addOns) ||
    parseAddOnIds(object?.metadata?.addons) ||
    []
  );
}

function extractSeats(object) {
  const seatValue =
    object?.metadata?.seats ??
    object?.quantity ??
    object?.quantity_total ??
    object?.subscription_items_total ??
    object?.metadata?.seatCount;
  const parsed = Number(seatValue);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : undefined;
}

function normalizeStripeEvent(event = {}) {
  const object = event.data?.object || {};
  const status = normalizeStatus(object.status || (event.type === 'customer.subscription.deleted' ? 'canceled' : undefined));

  const trialEndsAt = object.trial_end ? new Date(object.trial_end * 1000).toISOString() : undefined;
  const currentPeriodEnd = object.current_period_end
    ? new Date(object.current_period_end * 1000).toISOString()
    : undefined;

  return {
    businessId: extractBusinessId(object),
    subscriptionId: object.subscription || object.id || null,
    customerId: object.customer || object.customerId || object.client_reference_id || null,
    planId: extractPlanId(object),
    addOnIds: extractAddOnIds(object),
    seats: extractSeats(object),
    trialEndsAt,
    currentPeriodEnd,
    status,
    eventType: event.type,
    rawObject: object,
  };
}

function buildStubCheckoutUrl(sessionId) {
  return `https://billing.example.com/checkout?session_id=${encodeURIComponent(sessionId)}`;
}

module.exports = {
  deriveEntitlements,
  normalizeStatus,
  normalizeStripeEvent,
  verifyStripeSignature,
  verifyStripeWebhook,
  buildStubCheckoutUrl,
  MANAGED_FLAG_KEYS,
  PLAN_CATALOG,
  ADD_ON_CATALOG,
  parseAddOnIds,
};

// Lightweight self-check so deploys warn when catalog drifts from managed flags
runCatalogSelfCheck();

function runCatalogSelfCheck() {
  const managedSet = new Set(MANAGED_FLAG_KEYS);
  const issues = [];

  Object.entries(PLAN_CATALOG).forEach(([planId, plan]) => {
    Object.keys(plan.flags || {}).forEach((flag) => {
      if (!managedSet.has(flag)) {
        issues.push(`Plan "${planId}" has unmanaged flag "${flag}"`);
      }
    });
  });

  Object.entries(ADD_ON_CATALOG).forEach(([addOnId, addOn]) => {
    Object.keys(addOn.flags || {}).forEach((flag) => {
      if (!managedSet.has(flag)) {
        issues.push(`Add-on "${addOnId}" has unmanaged flag "${flag}"`);
      }
    });
  });

  if (issues.length) {
    // eslint-disable-next-line no-console
    console.warn('[billing] catalog self-check warnings:', issues.join('; '));
  }
}
