/**
 * Contacts API Routes
 * REST endpoints for contact/client management
 *
 * Task 5: Cloud Functions - API Layer
 *
 * Endpoints:
 * GET    /contacts          - List contacts (paginated)
 * GET    /contacts/:id      - Get contact by ID
 * POST   /contacts          - Create contact
 * PATCH  /contacts/:id      - Update contact
 * DELETE /contacts/:id      - Delete contact
 */

import { Router, Response } from 'express';
import * as admin from 'firebase-admin';
import { validateApiKey, checkScope, checkRateLimit, recordUsageMiddleware } from '../middleware';
import type { AuthenticatedRequest, ContactQueryParams, CreateContactBody, UpdateContactBody } from '../types';

const router = Router();

const getDb = () => {
  if (!admin.apps.length) admin.initializeApp();
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
 * GET /contacts - List contacts
 */
router.get('/', checkScope('contacts:read'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const meta = getMeta(authReq);

  try {
    // search is reserved for future full-text search implementation
    const { page = '1', limit = '50', sort = 'createdAt', order = 'desc', lifecycle, companyId, tags } = req.query as ContactQueryParams;

    const pageNum = Math.max(1, parseInt(String(page), 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(String(limit), 10) || 50));

    const db = getDb();
    let query: admin.firestore.Query = db.collection(`businesses/${businessId}/clients`);

    if (lifecycle) query = query.where('lifecycle', '==', lifecycle);
    if (companyId) query = query.where('companyId', '==', companyId);
    if (tags) {
      const tagList = String(tags).split(',').map((t) => t.trim());
      if (tagList.length > 0) query = query.where('tags', 'array-contains-any', tagList.slice(0, 10));
    }

    const sortField = ['createdAt', 'updatedAt', 'firstName', 'lastName', 'email'].includes(String(sort)) ? String(sort) : 'createdAt';
    query = query.orderBy(sortField, order === 'asc' ? 'asc' : 'desc');

    const countSnapshot = await query.count().get();
    const total = countSnapshot.data().count;
    const offset = (pageNum - 1) * limitNum;
    query = query.offset(offset).limit(limitNum);

    const snapshot = await query.get();
    const contacts = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString(),
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString(),
      lastContactedAt: doc.data().lastContactedAt?.toDate?.()?.toISOString(),
    }));

    res.json({
      data: contacts,
      pagination: { page: pageNum, limit: limitNum, total, hasMore: offset + contacts.length < total },
      meta,
    });
  } catch (error) {
    console.error('List contacts error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to list contacts' }, meta });
  }
});

/**
 * GET /contacts/:id - Get contact by ID
 */
router.get('/:id', checkScope('contacts:read'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const db = getDb();
    const doc = await db.doc(`businesses/${businessId}/clients/${id}`).get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Contact not found' }, meta });
      return;
    }

    const data = doc.data()!;
    res.json({
      data: {
        id: doc.id,
        ...data,
        createdAt: data.createdAt?.toDate?.()?.toISOString(),
        updatedAt: data.updatedAt?.toDate?.()?.toISOString(),
        lastContactedAt: data.lastContactedAt?.toDate?.()?.toISOString(),
      },
      meta,
    });
  } catch (error) {
    console.error('Get contact error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to get contact' }, meta });
  }
});

/**
 * POST /contacts - Create contact
 */
router.post('/', checkScope('contacts:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const meta = getMeta(authReq);

  try {
    const body = req.body as CreateContactBody;

    if (!body.firstName?.trim()) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { firstName: 'First name is required' } }, meta });
      return;
    }
    if (!body.lastName?.trim()) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { lastName: 'Last name is required' } }, meta });
      return;
    }
    if (!body.email?.trim()) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { email: 'Email is required' } }, meta });
      return;
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(body.email)) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { email: 'Invalid email format' } }, meta });
      return;
    }

    const db = getDb();
    const now = admin.firestore.FieldValue.serverTimestamp();

    const contactData = {
      firstName: body.firstName.trim(),
      lastName: body.lastName.trim(),
      email: body.email.trim().toLowerCase(),
      phone: body.phone?.trim() || null,
      companyId: body.companyId || null,
      companyName: null,
      title: body.title?.trim() || null,
      lifecycle: body.lifecycle || 'active',
      tags: body.tags || [],
      address: body.address || null,
      createdAt: now,
      updatedAt: now,
    };

    const docRef = await db.collection(`businesses/${businessId}/clients`).add(contactData);

    triggerWebhook(businessId, 'contact.created', { id: docRef.id, ...contactData }).catch(console.error);

    res.status(201).json({
      data: { id: docRef.id, ...contactData, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() },
      meta,
    });
  } catch (error) {
    console.error('Create contact error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to create contact' }, meta });
  }
});

/**
 * PATCH /contacts/:id - Update contact
 */
router.patch('/:id', checkScope('contacts:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const body = req.body as UpdateContactBody;
    const db = getDb();
    const docRef = db.doc(`businesses/${businessId}/clients/${id}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Contact not found' }, meta });
      return;
    }

    const updates: Record<string, unknown> = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };

    if (body.firstName !== undefined) updates.firstName = body.firstName.trim();
    if (body.lastName !== undefined) updates.lastName = body.lastName.trim();
    if (body.email !== undefined) updates.email = body.email.trim().toLowerCase();
    if (body.phone !== undefined) updates.phone = body.phone?.trim() || null;
    if (body.companyId !== undefined) updates.companyId = body.companyId || null;
    if (body.title !== undefined) updates.title = body.title?.trim() || null;
    if (body.lifecycle !== undefined) updates.lifecycle = body.lifecycle;
    if (body.tags !== undefined) updates.tags = body.tags;
    if (body.crmNotes !== undefined) updates.crmNotes = body.crmNotes || null;
    if (body.address !== undefined) updates.address = body.address || null;

    await docRef.update(updates);
    const updated = await docRef.get();
    const data = updated.data()!;

    triggerWebhook(businessId, 'contact.updated', { id, ...data }).catch(console.error);

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
    console.error('Update contact error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to update contact' }, meta });
  }
});

/**
 * DELETE /contacts/:id - Delete contact
 */
router.delete('/:id', checkScope('contacts:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const db = getDb();
    const docRef = db.doc(`businesses/${businessId}/clients/${id}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Contact not found' }, meta });
      return;
    }

    await docRef.delete();
    res.status(204).send();
  } catch (error) {
    console.error('Delete contact error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to delete contact' }, meta });
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
