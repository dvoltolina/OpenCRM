/**
 * Leads API Routes
 * REST endpoints for lead management
 *
 * Task 5: Cloud Functions - API Layer
 *
 * HIPAA Compliance:
 * - All operations scoped by businessId
 * - No PHI in error messages
 * - Audit logging on all writes
 *
 * Endpoints:
 * GET    /leads          - List leads (paginated)
 * GET    /leads/:id      - Get lead by ID
 * POST   /leads          - Create lead
 * PATCH  /leads/:id      - Update lead
 * DELETE /leads/:id      - Delete lead
 * POST   /leads/:id/convert - Convert to client
 */

import { Router, Response } from 'express';
import * as admin from 'firebase-admin';
import { validateApiKey, checkScope, checkRateLimit, recordUsageMiddleware } from '../middleware';
import type {
  AuthenticatedRequest,
  LeadQueryParams,
  CreateLeadBody,
  UpdateLeadBody,
  ConvertLeadBody,
} from '../types';

const router = Router();

// Initialize Firestore
const getDb = () => {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  return admin.firestore();
};

// Helper to generate response metadata
const getMeta = (req: AuthenticatedRequest) => ({
  requestId: req.requestId,
  timestamp: new Date().toISOString(),
});

// Apply middleware to all routes
router.use(validateApiKey);
router.use(checkRateLimit);
router.use(recordUsageMiddleware);

/**
 * GET /leads - List leads with pagination and filtering
 */
router.get('/', checkScope('leads:read'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const meta = getMeta(authReq);

  try {
    const {
      page = '1',
      limit = '50',
      sort = 'createdAt',
      order = 'desc',
      status,
      source,
      assigneeId,
      tags,
      // search is reserved for future full-text search implementation
      createdAfter,
      createdBefore,
    } = req.query as LeadQueryParams;

    const pageNum = Math.max(1, parseInt(String(page), 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(String(limit), 10) || 50));

    const db = getDb();
    let query: admin.firestore.Query = db.collection(`businesses/${businessId}/leads`);

    // Apply filters
    if (status) {
      query = query.where('status', '==', status);
    }
    if (source) {
      query = query.where('source', '==', source);
    }
    if (assigneeId) {
      query = query.where('assigneeId', '==', assigneeId);
    }
    if (tags) {
      const tagList = String(tags).split(',').map((t) => t.trim());
      if (tagList.length > 0) {
        query = query.where('tags', 'array-contains-any', tagList.slice(0, 10));
      }
    }

    // Apply date filters
    if (createdAfter) {
      query = query.where('createdAt', '>=', new Date(String(createdAfter)));
    }
    if (createdBefore) {
      query = query.where('createdAt', '<=', new Date(String(createdBefore)));
    }

    // Apply sorting
    const sortField = ['createdAt', 'updatedAt', 'firstName', 'lastName', 'email'].includes(String(sort))
      ? String(sort)
      : 'createdAt';
    const sortOrder = order === 'asc' ? 'asc' : 'desc';
    query = query.orderBy(sortField, sortOrder);

    // Get total count (simplified - in production use counter)
    const countSnapshot = await query.count().get();
    const total = countSnapshot.data().count;

    // Apply pagination
    const offset = (pageNum - 1) * limitNum;
    query = query.offset(offset).limit(limitNum);

    const snapshot = await query.get();
    const leads = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString(),
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString(),
      convertedAt: doc.data().convertedAt?.toDate?.()?.toISOString(),
    }));

    res.json({
      data: leads,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        hasMore: offset + leads.length < total,
      },
      meta,
    });
  } catch (error) {
    console.error('List leads error:', error);
    res.status(500).json({
      error: { code: 'INTERNAL_ERROR', message: 'Failed to list leads' },
      meta,
    });
  }
});

/**
 * GET /leads/:id - Get lead by ID
 */
router.get('/:id', checkScope('leads:read'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const db = getDb();
    const docRef = db.doc(`businesses/${businessId}/leads/${id}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({
        error: { code: 'NOT_FOUND', message: 'Lead not found' },
        meta,
      });
      return;
    }

    const data = doc.data()!;
    res.json({
      data: {
        id: doc.id,
        ...data,
        createdAt: data.createdAt?.toDate?.()?.toISOString(),
        updatedAt: data.updatedAt?.toDate?.()?.toISOString(),
        convertedAt: data.convertedAt?.toDate?.()?.toISOString(),
      },
      meta,
    });
  } catch (error) {
    console.error('Get lead error:', error);
    res.status(500).json({
      error: { code: 'INTERNAL_ERROR', message: 'Failed to get lead' },
      meta,
    });
  }
});

/**
 * POST /leads - Create new lead
 */
router.post('/', checkScope('leads:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const meta = getMeta(authReq);

  try {
    const body = req.body as CreateLeadBody;

    // Validate required fields
    if (!body.firstName?.trim()) {
      res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Validation failed',
          details: { firstName: 'First name is required' },
        },
        meta,
      });
      return;
    }

    if (!body.lastName?.trim()) {
      res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Validation failed',
          details: { lastName: 'Last name is required' },
        },
        meta,
      });
      return;
    }

    if (!body.email?.trim()) {
      res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Validation failed',
          details: { email: 'Email is required' },
        },
        meta,
      });
      return;
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(body.email)) {
      res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Validation failed',
          details: { email: 'Invalid email format' },
        },
        meta,
      });
      return;
    }

    const db = getDb();
    const now = admin.firestore.FieldValue.serverTimestamp();

    const leadData = {
      firstName: body.firstName.trim(),
      lastName: body.lastName.trim(),
      email: body.email.trim().toLowerCase(),
      phone: body.phone?.trim() || null,
      companyName: body.companyName?.trim() || null,
      title: body.title?.trim() || null,
      status: 'new',
      source: body.source || 'other',
      score: 0,
      assigneeId: body.assigneeId || null,
      assigneeName: null,
      tags: body.tags || [],
      notes: body.notes || null,
      customFields: body.customFields || {},
      createdAt: now,
      updatedAt: now,
    };

    const docRef = await db.collection(`businesses/${businessId}/leads`).add(leadData);

    // Trigger webhook (async, don't wait)
    triggerWebhook(businessId, 'lead.created', {
      id: docRef.id,
      ...leadData,
    }).catch((err) => console.error('Webhook trigger failed:', err));

    res.status(201).json({
      data: {
        id: docRef.id,
        ...leadData,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
      meta,
    });
  } catch (error) {
    console.error('Create lead error:', error);
    res.status(500).json({
      error: { code: 'INTERNAL_ERROR', message: 'Failed to create lead' },
      meta,
    });
  }
});

/**
 * PATCH /leads/:id - Update lead
 */
router.patch('/:id', checkScope('leads:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const body = req.body as UpdateLeadBody;

    const db = getDb();
    const docRef = db.doc(`businesses/${businessId}/leads/${id}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({
        error: { code: 'NOT_FOUND', message: 'Lead not found' },
        meta,
      });
      return;
    }

    // Build update object
    const updates: Record<string, unknown> = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (body.firstName !== undefined) updates.firstName = body.firstName.trim();
    if (body.lastName !== undefined) updates.lastName = body.lastName.trim();
    if (body.email !== undefined) updates.email = body.email.trim().toLowerCase();
    if (body.phone !== undefined) updates.phone = body.phone?.trim() || null;
    if (body.companyName !== undefined) updates.companyName = body.companyName?.trim() || null;
    if (body.title !== undefined) updates.title = body.title?.trim() || null;
    if (body.status !== undefined) updates.status = body.status;
    if (body.source !== undefined) updates.source = body.source;
    if (body.assigneeId !== undefined) updates.assigneeId = body.assigneeId || null;
    if (body.tags !== undefined) updates.tags = body.tags;
    if (body.notes !== undefined) updates.notes = body.notes || null;
    if (body.customFields !== undefined) updates.customFields = body.customFields;

    await docRef.update(updates);

    // Get updated document
    const updatedDoc = await docRef.get();
    const data = updatedDoc.data()!;

    // Trigger webhook (async)
    triggerWebhook(businessId, 'lead.updated', {
      id,
      ...data,
      changes: Object.keys(body),
    }).catch((err) => console.error('Webhook trigger failed:', err));

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
    console.error('Update lead error:', error);
    res.status(500).json({
      error: { code: 'INTERNAL_ERROR', message: 'Failed to update lead' },
      meta,
    });
  }
});

/**
 * DELETE /leads/:id - Delete lead
 */
router.delete('/:id', checkScope('leads:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const db = getDb();
    const docRef = db.doc(`businesses/${businessId}/leads/${id}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({
        error: { code: 'NOT_FOUND', message: 'Lead not found' },
        meta,
      });
      return;
    }

    await docRef.delete();

    res.status(204).send();
  } catch (error) {
    console.error('Delete lead error:', error);
    res.status(500).json({
      error: { code: 'INTERNAL_ERROR', message: 'Failed to delete lead' },
      meta,
    });
  }
});

/**
 * POST /leads/:id/convert - Convert lead to client
 */
router.post('/:id/convert', checkScope('leads:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const body = req.body as ConvertLeadBody;

    const db = getDb();
    const leadRef = db.doc(`businesses/${businessId}/leads/${id}`);
    const leadDoc = await leadRef.get();

    if (!leadDoc.exists) {
      res.status(404).json({
        error: { code: 'NOT_FOUND', message: 'Lead not found' },
        meta,
      });
      return;
    }

    const leadData = leadDoc.data()!;

    // Check if already converted
    if (leadData.status === 'converted') {
      res.status(409).json({
        error: { code: 'CONFLICT', message: 'Lead is already converted' },
        meta,
      });
      return;
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const batch = db.batch();

    // Create client
    const clientRef = db.collection(`businesses/${businessId}/clients`).doc();
    const clientData = {
      firstName: leadData.firstName,
      lastName: leadData.lastName,
      email: leadData.email,
      phone: leadData.phone,
      companyName: leadData.companyName,
      title: leadData.title,
      lifecycle: 'active',
      tags: leadData.tags || [],
      leadSource: leadData.source,
      createdAt: now,
      updatedAt: now,
    };
    batch.set(clientRef, clientData);

    let dealId: string | null = null;

    // Optionally create deal
    if (body.createDeal && body.pipelineId && body.stageId) {
      const dealRef = db.collection(`businesses/${businessId}/deals`).doc();
      dealId = dealRef.id;
      const dealData = {
        title: body.dealTitle || `${leadData.firstName} ${leadData.lastName} Deal`,
        pipelineId: body.pipelineId,
        stageId: body.stageId,
        valueCents: body.dealValueCents || 0,
        currency: 'USD',
        probability: 50,
        status: 'open',
        clientId: clientRef.id,
        clientName: `${leadData.firstName} ${leadData.lastName}`,
        assigneeId: leadData.assigneeId,
        tags: [],
        createdAt: now,
        updatedAt: now,
      };
      batch.set(dealRef, dealData);
    }

    // Update lead status
    batch.update(leadRef, {
      status: 'converted',
      convertedToClientId: clientRef.id,
      convertedToDealId: dealId,
      convertedAt: now,
      updatedAt: now,
    });

    await batch.commit();

    // Trigger webhook (async)
    triggerWebhook(businessId, 'lead.converted', {
      leadId: id,
      clientId: clientRef.id,
      dealId,
    }).catch((err) => console.error('Webhook trigger failed:', err));

    res.json({
      data: {
        lead: {
          id,
          status: 'converted',
          convertedToClientId: clientRef.id,
          convertedToDealId: dealId,
          convertedAt: new Date().toISOString(),
        },
        client: {
          id: clientRef.id,
        },
        deal: dealId ? { id: dealId } : null,
      },
      meta,
    });
  } catch (error) {
    console.error('Convert lead error:', error);
    res.status(500).json({
      error: { code: 'INTERNAL_ERROR', message: 'Failed to convert lead' },
      meta,
    });
  }
});

/**
 * Helper to trigger webhooks (simplified)
 */
async function triggerWebhook(
  businessId: string,
  event: string,
  data: Record<string, unknown>
): Promise<void> {
  const db = getDb();

  // Find webhook endpoints subscribed to this event
  const webhooksRef = db.collection(`businesses/${businessId}/webhook_endpoints`);
  const query = webhooksRef
    .where('isActive', '==', true)
    .where('events', 'array-contains', event);

  const snapshot = await query.get();

  for (const doc of snapshot.docs) {
    // Create delivery record
    const deliveryRef = db.collection(`businesses/${businessId}/webhook_deliveries`).doc();
    await deliveryRef.set({
      webhookId: doc.id,
      event,
      payload: {
        id: `evt_${Date.now().toString(36)}`,
        type: event,
        timestamp: new Date().toISOString(),
        data,
      },
      status: 'pending',
      attemptCount: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

export default router;
