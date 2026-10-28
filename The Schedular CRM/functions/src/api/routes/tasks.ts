/**
 * Tasks API Routes
 * REST endpoints for task management
 *
 * Task 5: Cloud Functions - API Layer
 *
 * Endpoints:
 * GET    /tasks          - List tasks (paginated)
 * GET    /tasks/:id      - Get task by ID
 * POST   /tasks          - Create task
 * PATCH  /tasks/:id      - Update task
 * DELETE /tasks/:id      - Delete task
 * POST   /tasks/:id/complete - Mark as complete
 */

import { Router, Response } from 'express';
import * as admin from 'firebase-admin';
import { validateApiKey, checkScope, checkRateLimit, recordUsageMiddleware } from '../middleware';
import type { AuthenticatedRequest, TaskQueryParams, CreateTaskBody, UpdateTaskBody, CompleteTaskBody } from '../types';

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
 * GET /tasks - List tasks
 */
router.get('/', checkScope('tasks:read'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const meta = getMeta(authReq);

  try {
    const {
      page = '1',
      limit = '50',
      sort = 'dueDate',
      order = 'asc',
      type,
      isCompleted,
      assigneeId,
      dealId,
      clientId,
      leadId,
      dueAfter,
      dueBefore,
      overdue,
    } = req.query as TaskQueryParams;

    const pageNum = Math.max(1, parseInt(String(page), 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(String(limit), 10) || 50));

    const db = getDb();
    let query: admin.firestore.Query = db.collection(`businesses/${businessId}/sales_activities`);

    if (type) query = query.where('type', '==', type);
    if (isCompleted !== undefined) query = query.where('isCompleted', '==', isCompleted === 'true');
    if (assigneeId) query = query.where('assigneeId', '==', assigneeId);
    if (dealId) query = query.where('dealId', '==', dealId);
    if (clientId) query = query.where('clientId', '==', clientId);
    if (leadId) query = query.where('leadId', '==', leadId);
    if (dueAfter) query = query.where('dueDate', '>=', new Date(String(dueAfter)));
    if (dueBefore) query = query.where('dueDate', '<=', new Date(String(dueBefore)));
    if (overdue === 'true') {
      query = query.where('dueDate', '<', new Date()).where('isCompleted', '==', false);
    }

    const sortField = ['dueDate', 'createdAt', 'title'].includes(String(sort)) ? String(sort) : 'dueDate';
    query = query.orderBy(sortField, order === 'desc' ? 'desc' : 'asc');

    const countSnapshot = await query.count().get();
    const total = countSnapshot.data().count;
    const offset = (pageNum - 1) * limitNum;
    query = query.offset(offset).limit(limitNum);

    const snapshot = await query.get();
    const tasks = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      dueDate: doc.data().dueDate?.toDate?.()?.toISOString(),
      reminderAt: doc.data().reminderAt?.toDate?.()?.toISOString(),
      completedAt: doc.data().completedAt?.toDate?.()?.toISOString(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString(),
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString(),
    }));

    res.json({
      data: tasks,
      pagination: { page: pageNum, limit: limitNum, total, hasMore: offset + tasks.length < total },
      meta,
    });
  } catch (error) {
    console.error('List tasks error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to list tasks' }, meta });
  }
});

/**
 * GET /tasks/:id - Get task by ID
 */
router.get('/:id', checkScope('tasks:read'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const db = getDb();
    const doc = await db.doc(`businesses/${businessId}/sales_activities/${id}`).get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Task not found' }, meta });
      return;
    }

    const data = doc.data()!;
    res.json({
      data: {
        id: doc.id,
        ...data,
        dueDate: data.dueDate?.toDate?.()?.toISOString(),
        reminderAt: data.reminderAt?.toDate?.()?.toISOString(),
        completedAt: data.completedAt?.toDate?.()?.toISOString(),
        createdAt: data.createdAt?.toDate?.()?.toISOString(),
        updatedAt: data.updatedAt?.toDate?.()?.toISOString(),
      },
      meta,
    });
  } catch (error) {
    console.error('Get task error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to get task' }, meta });
  }
});

/**
 * POST /tasks - Create task
 */
router.post('/', checkScope('tasks:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const meta = getMeta(authReq);

  try {
    const body = req.body as CreateTaskBody;

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

    const taskData = {
      type: body.type,
      title: body.title.trim(),
      description: body.description?.trim() || null,
      dealId: body.dealId || null,
      clientId: body.clientId || null,
      leadId: body.leadId || null,
      companyId: body.companyId || null,
      assigneeId: body.assigneeId || null,
      assigneeName: null,
      dueDate: body.dueDate ? new Date(body.dueDate) : null,
      reminderAt: body.reminderAt ? new Date(body.reminderAt) : null,
      isCompleted: false,
      completedAt: null,
      createdById: 'api',
      createdByName: 'API',
      createdAt: now,
      updatedAt: now,
    };

    const docRef = await db.collection(`businesses/${businessId}/sales_activities`).add(taskData);

    triggerWebhook(businessId, 'task.created', { id: docRef.id, ...taskData }).catch(console.error);

    res.status(201).json({
      data: {
        id: docRef.id,
        ...taskData,
        dueDate: body.dueDate || null,
        reminderAt: body.reminderAt || null,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
      meta,
    });
  } catch (error) {
    console.error('Create task error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to create task' }, meta });
  }
});

/**
 * PATCH /tasks/:id - Update task
 */
router.patch('/:id', checkScope('tasks:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const body = req.body as UpdateTaskBody;
    const db = getDb();
    const docRef = db.doc(`businesses/${businessId}/sales_activities/${id}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Task not found' }, meta });
      return;
    }

    const updates: Record<string, unknown> = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };

    if (body.title !== undefined) updates.title = body.title.trim();
    if (body.description !== undefined) updates.description = body.description?.trim() || null;
    if (body.dueDate !== undefined) updates.dueDate = body.dueDate ? new Date(body.dueDate) : null;
    if (body.reminderAt !== undefined) updates.reminderAt = body.reminderAt ? new Date(body.reminderAt) : null;
    if (body.assigneeId !== undefined) updates.assigneeId = body.assigneeId || null;

    await docRef.update(updates);
    const updated = await docRef.get();
    const data = updated.data()!;

    res.json({
      data: {
        id,
        ...data,
        dueDate: data.dueDate?.toDate?.()?.toISOString(),
        reminderAt: data.reminderAt?.toDate?.()?.toISOString(),
        createdAt: data.createdAt?.toDate?.()?.toISOString(),
        updatedAt: data.updatedAt?.toDate?.()?.toISOString(),
      },
      meta,
    });
  } catch (error) {
    console.error('Update task error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to update task' }, meta });
  }
});

/**
 * DELETE /tasks/:id - Delete task
 */
router.delete('/:id', checkScope('tasks:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const db = getDb();
    const docRef = db.doc(`businesses/${businessId}/sales_activities/${id}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Task not found' }, meta });
      return;
    }

    await docRef.delete();
    res.status(204).send();
  } catch (error) {
    console.error('Delete task error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to delete task' }, meta });
  }
});

/**
 * POST /tasks/:id/complete - Mark task as complete
 */
router.post('/:id/complete', checkScope('tasks:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const body = req.body as CompleteTaskBody;
    const db = getDb();
    const docRef = db.doc(`businesses/${businessId}/sales_activities/${id}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Task not found' }, meta });
      return;
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const updates: Record<string, unknown> = {
      isCompleted: true,
      completedAt: now,
      updatedAt: now,
    };

    if (body.completionNotes) {
      const existingData = doc.data()!;
      updates.description = existingData.description
        ? `${existingData.description}\n\nCompletion notes: ${body.completionNotes}`
        : `Completion notes: ${body.completionNotes}`;
    }

    await docRef.update(updates);

    triggerWebhook(businessId, 'task.completed', { id }).catch(console.error);

    res.json({
      data: { id, isCompleted: true, completedAt: new Date().toISOString() },
      meta,
    });
  } catch (error) {
    console.error('Complete task error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to complete task' }, meta });
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
