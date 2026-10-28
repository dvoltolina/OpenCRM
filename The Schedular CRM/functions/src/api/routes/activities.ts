/**
 * Activities API Routes
 * REST endpoints for activity logging
 *
 * Task 5: Cloud Functions - API Layer
 *
 * Endpoints:
 * GET    /activities - List activities (paginated)
 * POST   /activities - Log activity
 */

import { Router, Response } from 'express';
import * as admin from 'firebase-admin';
import { validateApiKey, checkScope, checkRateLimit, recordUsageMiddleware } from '../middleware';
import type { AuthenticatedRequest, ActivityQueryParams, CreateActivityBody } from '../types';

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
 * GET /activities - List activities
 */
router.get('/', checkScope('activities:read'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const meta = getMeta(authReq);

  try {
    const {
      page = '1',
      limit = '50',
      sort = 'createdAt',
      order = 'desc',
      type,
      dealId,
      clientId,
      leadId,
      companyId,
      createdById,
      createdAfter,
      createdBefore,
    } = req.query as ActivityQueryParams;

    const pageNum = Math.max(1, parseInt(String(page), 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(String(limit), 10) || 50));

    const db = getDb();
    let query: admin.firestore.Query = db.collection(`businesses/${businessId}/sales_activities`);

    if (type) query = query.where('type', '==', type);
    if (dealId) query = query.where('dealId', '==', dealId);
    if (clientId) query = query.where('clientId', '==', clientId);
    if (leadId) query = query.where('leadId', '==', leadId);
    if (companyId) query = query.where('companyId', '==', companyId);
    if (createdById) query = query.where('createdById', '==', createdById);
    if (createdAfter) query = query.where('createdAt', '>=', new Date(String(createdAfter)));
    if (createdBefore) query = query.where('createdAt', '<=', new Date(String(createdBefore)));

    query = query.orderBy(String(sort) || 'createdAt', order === 'asc' ? 'asc' : 'desc');

    const countSnapshot = await query.count().get();
    const total = countSnapshot.data().count;
    const offset = (pageNum - 1) * limitNum;
    query = query.offset(offset).limit(limitNum);

    const snapshot = await query.get();
    const activities = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString(),
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString(),
      dueDate: doc.data().dueDate?.toDate?.()?.toISOString(),
      completedAt: doc.data().completedAt?.toDate?.()?.toISOString(),
    }));

    res.json({
      data: activities,
      pagination: { page: pageNum, limit: limitNum, total, hasMore: offset + activities.length < total },
      meta,
    });
  } catch (error) {
    console.error('List activities error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to list activities' }, meta });
  }
});

/**
 * POST /activities - Log activity
 */
router.post('/', checkScope('activities:read'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const meta = getMeta(authReq);

  try {
    const body = req.body as CreateActivityBody;

    if (!body.type) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { type: 'Type is required' } }, meta });
      return;
    }
    if (!body.title?.trim()) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { title: 'Title is required' } }, meta });
      return;
    }

    const db = getDb();
    const now = admin.firestore.FieldValue.serverTimestamp();

    const activityData = {
      type: body.type,
      title: body.title.trim(),
      description: body.description?.trim() || null,
      dealId: body.dealId || null,
      clientId: body.clientId || null,
      leadId: body.leadId || null,
      companyId: body.companyId || null,
      isCompleted: body.type !== 'task',
      completedAt: body.type !== 'task' ? now : null,
      createdById: 'api',
      createdByName: 'API',
      createdAt: now,
      updatedAt: now,
    };

    const docRef = await db.collection(`businesses/${businessId}/sales_activities`).add(activityData);

    res.status(201).json({
      data: {
        id: docRef.id,
        ...activityData,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        completedAt: body.type !== 'task' ? new Date().toISOString() : null,
      },
      meta,
    });
  } catch (error) {
    console.error('Log activity error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to log activity' }, meta });
  }
});

export default router;
