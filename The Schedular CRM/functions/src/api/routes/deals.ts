/**
 * Deals API Routes
 * REST endpoints for deal/opportunity management
 *
 * Task 5: Cloud Functions - API Layer
 *
 * HIPAA Compliance:
 * - All operations scoped by businessId
 * - No PHI in error messages
 *
 * Endpoints:
 * GET    /deals          - List deals (paginated)
 * GET    /deals/:id      - Get deal by ID
 * POST   /deals          - Create deal
 * PATCH  /deals/:id      - Update deal
 * DELETE /deals/:id      - Delete deal
 * PATCH  /deals/:id/stage - Move to stage
 * POST   /deals/:id/won   - Mark as won
 * POST   /deals/:id/lost  - Mark as lost
 */

import { Router, Response } from 'express';
import * as admin from 'firebase-admin';
import { validateApiKey, checkScope, checkRateLimit, recordUsageMiddleware } from '../middleware';
import type { AuthenticatedRequest, DealQueryParams, CreateDealBody, UpdateDealBody, MoveDealStageBody, DealOutcomeBody } from '../types';

const router = Router();

const getDb = () => {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  return admin.firestore();
};

const getMeta = (req: AuthenticatedRequest) => ({
  requestId: req.requestId,
  timestamp: new Date().toISOString(),
});

router.use(validateApiKey);
router.use(checkRateLimit);
router.use(recordUsageMiddleware);

/**
 * GET /deals - List deals
 */
router.get('/', checkScope('deals:read'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const meta = getMeta(authReq);

  try {
    const {
      page = '1',
      limit = '50',
      sort = 'createdAt',
      order = 'desc',
      pipelineId,
      stageId,
      status,
      assigneeId,
      clientId,
      companyId,
    } = req.query as DealQueryParams;

    const pageNum = Math.max(1, parseInt(String(page), 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(String(limit), 10) || 50));

    const db = getDb();
    let query: admin.firestore.Query = db.collection(`businesses/${businessId}/deals`);

    if (pipelineId) query = query.where('pipelineId', '==', pipelineId);
    if (stageId) query = query.where('stageId', '==', stageId);
    if (status) query = query.where('status', '==', status);
    if (assigneeId) query = query.where('assigneeId', '==', assigneeId);
    if (clientId) query = query.where('clientId', '==', clientId);
    if (companyId) query = query.where('companyId', '==', companyId);

    const sortField = ['createdAt', 'updatedAt', 'title', 'valueCents'].includes(String(sort)) ? String(sort) : 'createdAt';
    query = query.orderBy(sortField, order === 'asc' ? 'asc' : 'desc');

    const countSnapshot = await query.count().get();
    const total = countSnapshot.data().count;
    const offset = (pageNum - 1) * limitNum;
    query = query.offset(offset).limit(limitNum);

    const snapshot = await query.get();
    const deals = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString(),
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString(),
      closedAt: doc.data().closedAt?.toDate?.()?.toISOString(),
      expectedCloseDate: doc.data().expectedCloseDate?.toDate?.()?.toISOString(),
    }));

    res.json({
      data: deals,
      pagination: { page: pageNum, limit: limitNum, total, hasMore: offset + deals.length < total },
      meta,
    });
  } catch (error) {
    console.error('List deals error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to list deals' }, meta });
  }
});

/**
 * GET /deals/:id - Get deal by ID
 */
router.get('/:id', checkScope('deals:read'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const db = getDb();
    const doc = await db.doc(`businesses/${businessId}/deals/${id}`).get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Deal not found' }, meta });
      return;
    }

    const data = doc.data()!;
    res.json({
      data: {
        id: doc.id,
        ...data,
        createdAt: data.createdAt?.toDate?.()?.toISOString(),
        updatedAt: data.updatedAt?.toDate?.()?.toISOString(),
        closedAt: data.closedAt?.toDate?.()?.toISOString(),
        expectedCloseDate: data.expectedCloseDate?.toDate?.()?.toISOString(),
      },
      meta,
    });
  } catch (error) {
    console.error('Get deal error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to get deal' }, meta });
  }
});

/**
 * POST /deals - Create deal
 */
router.post('/', checkScope('deals:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const meta = getMeta(authReq);

  try {
    const body = req.body as CreateDealBody;

    if (!body.title?.trim()) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { title: 'Title is required' } }, meta });
      return;
    }
    if (!body.pipelineId) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { pipelineId: 'Pipeline ID is required' } }, meta });
      return;
    }
    if (!body.stageId) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { stageId: 'Stage ID is required' } }, meta });
      return;
    }

    const db = getDb();
    const now = admin.firestore.FieldValue.serverTimestamp();

    const dealData = {
      title: body.title.trim(),
      pipelineId: body.pipelineId,
      stageId: body.stageId,
      valueCents: body.valueCents || 0,
      currency: body.currency || 'USD',
      probability: 50,
      status: 'open',
      expectedCloseDate: body.expectedCloseDate ? new Date(body.expectedCloseDate) : null,
      clientId: body.clientId || null,
      clientName: null,
      companyId: body.companyId || null,
      companyName: null,
      assigneeId: body.assigneeId || null,
      assigneeName: null,
      tags: body.tags || [],
      notes: body.notes || null,
      customFields: body.customFields || {},
      createdAt: now,
      updatedAt: now,
    };

    const docRef = await db.collection(`businesses/${businessId}/deals`).add(dealData);

    triggerWebhook(businessId, 'deal.created', { id: docRef.id, ...dealData }).catch(console.error);

    res.status(201).json({
      data: { id: docRef.id, ...dealData, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() },
      meta,
    });
  } catch (error) {
    console.error('Create deal error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to create deal' }, meta });
  }
});

/**
 * PATCH /deals/:id - Update deal
 */
router.patch('/:id', checkScope('deals:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const body = req.body as UpdateDealBody;
    const db = getDb();
    const docRef = db.doc(`businesses/${businessId}/deals/${id}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Deal not found' }, meta });
      return;
    }

    const updates: Record<string, unknown> = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };

    if (body.title !== undefined) updates.title = body.title.trim();
    if (body.valueCents !== undefined) updates.valueCents = body.valueCents;
    if (body.currency !== undefined) updates.currency = body.currency;
    if (body.probability !== undefined) updates.probability = body.probability;
    if (body.expectedCloseDate !== undefined) updates.expectedCloseDate = body.expectedCloseDate ? new Date(body.expectedCloseDate) : null;
    if (body.clientId !== undefined) updates.clientId = body.clientId || null;
    if (body.companyId !== undefined) updates.companyId = body.companyId || null;
    if (body.assigneeId !== undefined) updates.assigneeId = body.assigneeId || null;
    if (body.tags !== undefined) updates.tags = body.tags;
    if (body.notes !== undefined) updates.notes = body.notes || null;
    if (body.customFields !== undefined) updates.customFields = body.customFields;

    await docRef.update(updates);
    const updated = await docRef.get();
    const data = updated.data()!;

    triggerWebhook(businessId, 'deal.updated', { id, ...data }).catch(console.error);

    res.json({
      data: {
        id,
        ...data,
        createdAt: data.createdAt?.toDate?.()?.toISOString(),
        updatedAt: data.updatedAt?.toDate?.()?.toISOString(),
      },
      meta,
    });
  } catch (error) {
    console.error('Update deal error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to update deal' }, meta });
  }
});

/**
 * DELETE /deals/:id - Delete deal
 */
router.delete('/:id', checkScope('deals:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const db = getDb();
    const docRef = db.doc(`businesses/${businessId}/deals/${id}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Deal not found' }, meta });
      return;
    }

    await docRef.delete();
    res.status(204).send();
  } catch (error) {
    console.error('Delete deal error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to delete deal' }, meta });
  }
});

/**
 * PATCH /deals/:id/stage - Move deal to new stage
 */
router.patch('/:id/stage', checkScope('deals:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const body = req.body as MoveDealStageBody;

    if (!body.stageId) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { stageId: 'Stage ID is required' } }, meta });
      return;
    }

    const db = getDb();
    const docRef = db.doc(`businesses/${businessId}/deals/${id}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Deal not found' }, meta });
      return;
    }

    const data = doc.data()!;
    const previousStageId = data.stageId;

    await docRef.update({
      stageId: body.stageId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    triggerWebhook(businessId, 'deal.stage_changed', { id, previousStageId, stageId: body.stageId }).catch(console.error);

    res.json({
      data: {
        id,
        previousStageId,
        stageId: body.stageId,
        updatedAt: new Date().toISOString(),
      },
      meta,
    });
  } catch (error) {
    console.error('Move deal stage error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to move deal stage' }, meta });
  }
});

/**
 * POST /deals/:id/won - Mark deal as won
 */
router.post('/:id/won', checkScope('deals:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const body = req.body as DealOutcomeBody;
    const db = getDb();
    const docRef = db.doc(`businesses/${businessId}/deals/${id}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Deal not found' }, meta });
      return;
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    await docRef.update({
      status: 'won',
      wonLostReason: body.wonReason || null,
      closedAt: now,
      probability: 100,
      updatedAt: now,
    });

    triggerWebhook(businessId, 'deal.won', { id }).catch(console.error);

    res.json({
      data: { id, status: 'won', closedAt: new Date().toISOString() },
      meta,
    });
  } catch (error) {
    console.error('Mark deal won error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to mark deal won' }, meta });
  }
});

/**
 * POST /deals/:id/lost - Mark deal as lost
 *
 * HIPAA Compliance:
 * - Server-side PHI validation on lostReason
 * - Blocks emails, phone numbers, and common PHI patterns
 */
router.post('/:id/lost', checkScope('deals:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const body = req.body as DealOutcomeBody;
    const db = getDb();
    const docRef = db.doc(`businesses/${businessId}/deals/${id}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Deal not found' }, meta });
      return;
    }

    // HIPAA: Server-side PHI validation for lost reason
    const lostReason = body.lostReason?.trim() || '';
    if (lostReason) {
      // Check for maximum length (180 chars - matches client-side)
      if (lostReason.length > 180) {
        res.status(400).json({
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Lost reason exceeds maximum length of 180 characters',
            details: { lostReason: 'Maximum 180 characters allowed' },
          },
          meta,
        });
        return;
      }

      // Check for email addresses
      const emailPattern = /@/;
      if (emailPattern.test(lostReason)) {
        res.status(400).json({
          error: {
            code: 'PHI_VALIDATION_ERROR',
            message: 'Lost reason may not contain email addresses (PHI)',
            details: { lostReason: 'Remove email addresses - no PHI allowed' },
          },
          meta,
        });
        return;
      }

      // Check for phone numbers (5+ consecutive digits with optional separators)
      const phonePattern = /\d[\d\-\s().]{4,}/;
      if (phonePattern.test(lostReason)) {
        res.status(400).json({
          error: {
            code: 'PHI_VALIDATION_ERROR',
            message: 'Lost reason may not contain phone numbers (PHI)',
            details: { lostReason: 'Remove phone numbers - no PHI allowed' },
          },
          meta,
        });
        return;
      }

      // Check for SSN pattern (XXX-XX-XXXX or XXXXXXXXX)
      const ssnPattern = /\b\d{3}[-\s]?\d{2}[-\s]?\d{4}\b/;
      if (ssnPattern.test(lostReason)) {
        res.status(400).json({
          error: {
            code: 'PHI_VALIDATION_ERROR',
            message: 'Lost reason may not contain SSN-like numbers (PHI)',
            details: { lostReason: 'Remove SSN-like patterns - no PHI allowed' },
          },
          meta,
        });
        return;
      }

      // Check for date of birth patterns (MM/DD/YYYY, MM-DD-YYYY, etc.)
      const dobPattern = /\b(0?[1-9]|1[0-2])[-/](0?[1-9]|[12]\d|3[01])[-/](19|20)\d{2}\b/;
      if (dobPattern.test(lostReason)) {
        res.status(400).json({
          error: {
            code: 'PHI_VALIDATION_ERROR',
            message: 'Lost reason may not contain dates that could be PHI',
            details: { lostReason: 'Remove date patterns - no PHI allowed' },
          },
          meta,
        });
        return;
      }
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    await docRef.update({
      status: 'lost',
      wonLostReason: lostReason || null,
      closedAt: now,
      probability: 0,
      updatedAt: now,
    });

    triggerWebhook(businessId, 'deal.lost', { id }).catch(console.error);

    res.json({
      data: { id, status: 'lost', closedAt: new Date().toISOString() },
      meta,
    });
  } catch (error) {
    console.error('Mark deal lost error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to mark deal lost' }, meta });
  }
});

async function triggerWebhook(businessId: string, event: string, data: Record<string, unknown>): Promise<void> {
  const db = getDb();
  const webhooksRef = db.collection(`businesses/${businessId}/webhook_endpoints`);
  const query = webhooksRef.where('isActive', '==', true).where('events', 'array-contains', event);
  const snapshot = await query.get();

  for (const doc of snapshot.docs) {
    const deliveryRef = db.collection(`businesses/${businessId}/webhook_deliveries`).doc();
    await deliveryRef.set({
      webhookId: doc.id,
      event,
      payload: { id: `evt_${Date.now().toString(36)}`, type: event, timestamp: new Date().toISOString(), data },
      status: 'pending',
      attemptCount: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

export default router;
