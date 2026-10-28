/* eslint-disable no-console */
const assert = require('assert');
const crypto = require('crypto');

const {
  deriveEntitlements,
  normalizeStripeEvent,
  verifyStripeWebhook,
  MANAGED_FLAG_KEYS,
} = require('./billing');

function testEntitlements() {
  const result = deriveEntitlements('pro', ['addon-marketing']);
  assert.equal(result.planId, 'pro');
  assert.equal(result.flags.enableReporting, true);
  assert.equal(result.flags.enableMarketing, true);
  assert.equal(result.flags.enableImportExport, true);
  assert.deepStrictEqual(result.appliedAddOns, ['addon-marketing']);
  assert.deepStrictEqual(result.managedFlagKeys, MANAGED_FLAG_KEYS);

  const canceled = deriveEntitlements('starter', []);
  assert.equal(canceled.flags.enableReporting, false);
}

function testNormalizeStripeEvent() {
  const ts = Math.floor(Date.now() / 1000);
  const payload = {
    type: 'checkout.session.completed',
    data: {
      object: {
        id: 'cs_test_123',
        status: 'complete',
        metadata: {
          businessId: 'biz_1',
          planId: 'pro',
          addOns: 'addon-reports',
          seats: '5',
        },
      },
    },
  };
  const normalized = normalizeStripeEvent(payload);
  assert.equal(normalized.businessId, 'biz_1');
  assert.equal(normalized.planId, 'pro');
  assert.equal(normalized.addOnIds[0], 'addon-reports');
  assert.equal(normalized.seats, 5);
  assert.equal(normalized.status, 'incomplete'); // session status maps to default
  assert.equal(normalized.eventType, 'checkout.session.completed');
  assert.ok(ts - Math.floor(Date.now() / 1000) <= 1); // sanity check that test runs quickly
}

function testVerifyStripeWebhookHmac() {
  const secret = 'whsec_test';
  const rawBody = Buffer.from('{"id":"evt_123"}', 'utf8');
  const timestamp = Math.floor(Date.now() / 1000);
  const payload = `${timestamp}.${rawBody.toString('utf8')}`;
  const signature = crypto.createHmac('sha256', secret).update(payload).digest('hex');
  const header = `t=${timestamp},v1=${signature}`;

  const result = verifyStripeWebhook(rawBody, header, secret, 300);
  assert.equal(result.valid, true);

  const staleTimestamp = timestamp - 120; // older than tolerance
  const stalePayload = `${staleTimestamp}.${rawBody.toString('utf8')}`;
  const staleSignature = crypto.createHmac('sha256', secret).update(stalePayload).digest('hex');
  const staleHeader = `t=${staleTimestamp},v1=${staleSignature}`;
  const staleResult = verifyStripeWebhook(rawBody, staleHeader, secret, 1);
  assert.equal(staleResult.valid, false);
  assert.equal(staleResult.reason, 'timestamp_out_of_range');
}

function run() {
  testEntitlements();
  testNormalizeStripeEvent();
  testVerifyStripeWebhookHmac();
  console.log('All billing contract tests passed.');
}

run();
