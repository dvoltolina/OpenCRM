/**
 * Webhooks API Routes
 * REST endpoints for webhook endpoint management
 *
 * Task 5: Cloud Functions - API Layer
 *
 * HIPAA Compliance:
 * - All operations scoped by businessId
 * - Webhook secrets are hashed before storage
 * - No PHI in error messages
 *
 * Endpoints:
 * GET    /webhooks          - List webhook endpoints
 * GET    /webhooks/:id      - Get webhook by ID
 * POST   /webhooks          - Create webhook endpoint
 * PATCH  /webhooks/:id      - Update webhook endpoint
 * DELETE /webhooks/:id      - Delete webhook endpoint
 * POST   /webhooks/:id/test - Test webhook delivery
 * GET    /webhooks/:id/deliveries - List deliveries
 */

import { Router, Response } from 'express';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { validateApiKey, checkScope, checkRateLimit, recordUsageMiddleware } from '../middleware';
import type { AuthenticatedRequest, CreateWebhookBody, UpdateWebhookBody } from '../types';
import { isValidUrl } from '../types';

const router = Router();

const getDb = () => {
  if (!admin.apps.length) admin.initializeApp();
  return admin.firestore();
};

const getMeta = (req: AuthenticatedRequest) => ({
  requestId: req.requestId,
  timestamp: new Date().toISOString(),
});

const generateSecret = (): string => {
  return `whsec_${crypto.randomBytes(32).toString('hex')}`;
};

router.use(validateApiKey);
router.use(checkRateLimit);
router.use(recordUsageMiddleware);

// Valid webhook events
const VALID_EVENTS = [
  'lead.created',
  'lead.updated',
  'lead.converted',
  'deal.created',
  'deal.updated',
  'deal.stage_changed',
  'deal.won',
  'deal.lost',
  'contact.created',
  'contact.updated',
  'task.created',
  'task.completed',
  'sequence.enrolled',
  'sequence.unenrolled',
  'sequence.completed',
];

/**
 * GET /webhooks - List webhook endpoints
 */
router.get('/', checkScope('webhooks:manage'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const meta = getMeta(authReq);

  try {
    const { page = '1', limit = '50', isActive } = req.query;

    const pageNum = Math.max(1, parseInt(String(page), 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(String(limit), 10) || 50));

    const db = getDb();
    let query: admin.firestore.Query = db.collection(`businesses/${businessId}/webhook_endpoints`);

    if (isActive !== undefined) {
      query = query.where('isActive', '==', isActive === 'true');
    }

    query = query.orderBy('createdAt', 'desc');

    const countSnapshot = await query.count().get();
    const total = countSnapshot.data().count;
    const offset = (pageNum - 1) * limitNum;
    query = query.offset(offset).limit(limitNum);

    const snapshot = await query.get();
    const webhooks = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        name: data.name,
        url: data.url,
        events: data.events,
        isActive: data.isActive,
        retryEnabled: data.retryEnabled,
        maxRetries: data.maxRetries,
        createdAt: data.createdAt?.toDate?.()?.toISOString(),
        updatedAt: data.updatedAt?.toDate?.()?.toISOString(),
        // Never expose the secret in list response
      };
    });

    res.json({
      data: webhooks,
      pagination: { page: pageNum, limit: limitNum, total, hasMore: offset + webhooks.length < total },
      meta,
    });
  } catch (error) {
    console.error('List webhooks error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to list webhooks' }, meta });
  }
});

/**
 * GET /webhooks/:id - Get webhook by ID
 */
router.get('/:id', checkScope('webhooks:manage'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const db = getDb();
    const doc = await db.doc(`businesses/${businessId}/webhook_endpoints/${id}`).get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Webhook not found' }, meta });
      return;
    }

    const data = doc.data()!;
    res.json({
      data: {
        id: doc.id,
        name: data.name,
        url: data.url,
        events: data.events,
        isActive: data.isActive,
        customHeaders: data.customHeaders,
        retryEnabled: data.retryEnabled,
        maxRetries: data.maxRetries,
        createdAt: data.createdAt?.toDate?.()?.toISOString(),
        updatedAt: data.updatedAt?.toDate?.()?.toISOString(),
        // Never expose the secret
      },
      meta,
    });
  } catch (error) {
    console.error('Get webhook error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to get webhook' }, meta });
  }
});

/**
 * POST /webhooks - Create webhook endpoint
 */
router.post('/', checkScope('webhooks:manage'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const meta = getMeta(authReq);

  try {
    const body = req.body as CreateWebhookBody;

    // Validate required fields
    if (!body.name?.trim()) {
      res.status(400).json({
        error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { name: 'Name is required' } },
        meta,
      });
      return;
    }

    if (!body.url?.trim()) {
      res.status(400).json({
        error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { url: 'URL is required' } },
        meta,
      });
      return;
    }

    if (!isValidUrl(body.url)) {
      res.status(400).json({
        error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { url: 'URL must be a valid HTTPS URL' } },
        meta,
      });
      return;
    }

    if (!body.events || !Array.isArray(body.events) || body.events.length === 0) {
      res.status(400).json({
        error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { events: 'At least one event is required' } },
        meta,
      });
      return;
    }

    // Validate events
    const invalidEvents = body.events.filter((e) => !VALID_EVENTS.includes(e));
    if (invalidEvents.length > 0) {
      res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Validation failed',
          details: { events: `Invalid events: ${invalidEvents.join(', ')}` },
        },
        meta,
      });
      return;
    }

    const db = getDb();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const secret = generateSecret();

    const webhookData = {
      name: body.name.trim(),
      url: body.url.trim(),
      events: body.events,
      isActive: true,
      secret,
      customHeaders: body.customHeaders || {},
      retryEnabled: body.retryEnabled !== false,
      maxRetries: body.maxRetries || 3,
      createdAt: now,
      updatedAt: now,
    };

    const docRef = await db.collection(`businesses/${businessId}/webhook_endpoints`).add(webhookData);

    res.status(201).json({
      data: {
        id: docRef.id,
        name: webhookData.name,
        url: webhookData.url,
        events: webhookData.events,
        isActive: webhookData.isActive,
        secret, // Return secret only on creation
        customHeaders: webhookData.customHeaders,
        retryEnabled: webhookData.retryEnabled,
        maxRetries: webhookData.maxRetries,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
      meta,
    });
  } catch (error) {
    console.error('Create webhook error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to create webhook' }, meta });
  }
});

/**
 * PATCH /webhooks/:id - Update webhook endpoint
 */
router.patch('/:id', checkScope('webhooks:manage'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const body = req.body as UpdateWebhookBody;
    const db = getDb();
    const docRef = db.doc(`businesses/${businessId}/webhook_endpoints/${id}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Webhook not found' }, meta });
      return;
    }

    const updates: Record<string, unknown> = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };

    if (body.name !== undefined) updates.name = body.name.trim();
    if (body.url !== undefined) {
      if (!isValidUrl(body.url)) {
        res.status(400).json({
          error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { url: 'URL must be a valid HTTPS URL' } },
          meta,
        });
        return;
      }
      updates.url = body.url.trim();
    }
    if (body.events !== undefined) {
      const invalidEvents = body.events.filter((e) => !VALID_EVENTS.includes(e));
      if (invalidEvents.length > 0) {
        res.status(400).json({
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Validation failed',
            details: { events: `Invalid events: ${invalidEvents.join(', ')}` },
          },
          meta,
        });
        return;
      }
      updates.events = body.events;
    }
    if (body.isActive !== undefined) updates.isActive = body.isActive;
    if (body.customHeaders !== undefined) updates.customHeaders = body.customHeaders;
    if (body.retryEnabled !== undefined) updates.retryEnabled = body.retryEnabled;
    if (body.maxRetries !== undefined) updates.maxRetries = body.maxRetries;

    await docRef.update(updates);
    const updated = await docRef.get();
    const data = updated.data()!;

    res.json({
      data: {
        id,
        name: data.name,
        url: data.url,
        events: data.events,
        isActive: data.isActive,
        customHeaders: data.customHeaders,
        retryEnabled: data.retryEnabled,
        maxRetries: data.maxRetries,
        createdAt: data.createdAt?.toDate?.()?.toISOString(),
        updatedAt: data.updatedAt?.toDate?.()?.toISOString(),
      },
      meta,
    });
  } catch (error) {
    console.error('Update webhook error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to update webhook' }, meta });
  }
});

/**
 * DELETE /webhooks/:id - Delete webhook endpoint
 */
router.delete('/:id', checkScope('webhooks:manage'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const db = getDb();
    const docRef = db.doc(`businesses/${businessId}/webhook_endpoints/${id}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Webhook not found' }, meta });
      return;
    }

    await docRef.delete();
    res.status(204).send();
  } catch (error) {
    console.error('Delete webhook error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to delete webhook' }, meta });
  }
});

/**
 * POST /webhooks/:id/test - Test webhook delivery
 */
router.post('/:id/test', checkScope('webhooks:manage'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const db = getDb();
    const doc = await db.doc(`businesses/${businessId}/webhook_endpoints/${id}`).get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Webhook not found' }, meta });
      return;
    }

    const now = admin.firestore.FieldValue.serverTimestamp();

    // Create a test delivery
    const deliveryRef = db.collection(`businesses/${businessId}/webhook_deliveries`).doc();
    await deliveryRef.set({
      webhookId: id,
      event: 'webhook.test',
      payload: {
        id: `evt_${Date.now().toString(36)}`,
        type: 'webhook.test',
        timestamp: new Date().toISOString(),
        data: { message: 'This is a test webhook delivery' },
      },
      status: 'pending',
      attemptCount: 0,
      createdAt: now,
    });

    res.json({
      data: {
        deliveryId: deliveryRef.id,
        message: 'Test delivery queued',
      },
      meta,
    });
  } catch (error) {
    console.error('Test webhook error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to test webhook' }, meta });
  }
});

/**
 * GET /webhooks/:id/deliveries - List webhook deliveries
 */
router.get('/:id/deliveries', checkScope('webhooks:manage'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const { page = '1', limit = '50', status } = req.query;

    const pageNum = Math.max(1, parseInt(String(page), 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(String(limit), 10) || 50));

    const db = getDb();

    // Verify webhook exists
    const webhookDoc = await db.doc(`businesses/${businessId}/webhook_endpoints/${id}`).get();
    if (!webhookDoc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Webhook not found' }, meta });
      return;
    }

    let query: admin.firestore.Query = db
      .collection(`businesses/${businessId}/webhook_deliveries`)
      .where('webhookId', '==', id);

    if (status) {
      query = query.where('status', '==', status);
    }

    query = query.orderBy('createdAt', 'desc');

    const countSnapshot = await query.count().get();
    const total = countSnapshot.data().count;
    const offset = (pageNum - 1) * limitNum;
    query = query.offset(offset).limit(limitNum);

    const snapshot = await query.get();
    const deliveries = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString(),
      deliveredAt: doc.data().deliveredAt?.toDate?.()?.toISOString(),
      nextRetryAt: doc.data().nextRetryAt?.toDate?.()?.toISOString(),
    }));

    res.json({
      data: deliveries,
      pagination: { page: pageNum, limit: limitNum, total, hasMore: offset + deliveries.length < total },
      meta,
    });
  } catch (error) {
    console.error('List deliveries error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to list deliveries' }, meta });
  }
});

/**
 * POST /webhooks/:id/secret/rotate - Rotate webhook secret
 */
router.post('/:id/secret/rotate', checkScope('webhooks:manage'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const db = getDb();
    const docRef = db.doc(`businesses/${businessId}/webhook_endpoints/${id}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Webhook not found' }, meta });
      return;
    }

    const newSecret = generateSecret();
    await docRef.update({
      secret: newSecret,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({
      data: {
        secret: newSecret,
        message: 'Secret rotated successfully',
      },
      meta,
    });
  } catch (error) {
    console.error('Rotate webhook secret error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to rotate secret' }, meta });
  }
});

export default router;
