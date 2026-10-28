/**
 * Sequences API Routes
 * REST endpoints for sequence enrollment and management
 *
 * Task 5: Cloud Functions - API Layer
 *
 * HIPAA Compliance:
 * - All operations scoped by businessId
 * - No PHI in error messages
 *
 * Endpoints:
 * GET    /sequences               - List sequences
 * GET    /sequences/:id           - Get sequence by ID
 * POST   /sequences/:id/enroll    - Enroll entity in sequence
 * DELETE /sequences/:id/enrollments/:enrollmentId - Unenroll
 * GET    /sequences/:id/enrollments - List enrollments
 */

import { Router, Response } from 'express';
import * as admin from 'firebase-admin';
import { validateApiKey, checkScope, checkRateLimit, recordUsageMiddleware } from '../middleware';
import type { AuthenticatedRequest, EnrollSequenceBody } from '../types';

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
 * GET /sequences - List sequences
 */
router.get('/', checkScope('sequences:read'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const meta = getMeta(authReq);

  try {
    const { page = '1', limit = '50', isActive } = req.query;

    const pageNum = Math.max(1, parseInt(String(page), 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(String(limit), 10) || 50));

    const db = getDb();
    let query: admin.firestore.Query = db.collection(`businesses/${businessId}/sequences`);

    if (isActive !== undefined) {
      query = query.where('isActive', '==', isActive === 'true');
    }

    query = query.orderBy('createdAt', 'desc');

    const countSnapshot = await query.count().get();
    const total = countSnapshot.data().count;
    const offset = (pageNum - 1) * limitNum;
    query = query.offset(offset).limit(limitNum);

    const snapshot = await query.get();
    const sequences = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString(),
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString(),
    }));

    res.json({
      data: sequences,
      pagination: { page: pageNum, limit: limitNum, total, hasMore: offset + sequences.length < total },
      meta,
    });
  } catch (error) {
    console.error('List sequences error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to list sequences' }, meta });
  }
});

/**
 * GET /sequences/:id - Get sequence by ID
 */
router.get('/:id', checkScope('sequences:read'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const db = getDb();
    const doc = await db.doc(`businesses/${businessId}/sequences/${id}`).get();

    if (!doc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Sequence not found' }, meta });
      return;
    }

    const data = doc.data()!;

    // Get steps
    const stepsSnapshot = await db
      .collection(`businesses/${businessId}/sequences/${id}/steps`)
      .orderBy('order', 'asc')
      .get();

    const steps = stepsSnapshot.docs.map((stepDoc) => ({
      id: stepDoc.id,
      ...stepDoc.data(),
    }));

    res.json({
      data: {
        id: doc.id,
        ...data,
        steps,
        createdAt: data.createdAt?.toDate?.()?.toISOString(),
        updatedAt: data.updatedAt?.toDate?.()?.toISOString(),
      },
      meta,
    });
  } catch (error) {
    console.error('Get sequence error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to get sequence' }, meta });
  }
});

/**
 * POST /sequences/:id/enroll - Enroll entity in sequence
 */
router.post('/:id/enroll', checkScope('sequences:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const body = req.body as EnrollSequenceBody;

    if (!body.entityType) {
      res.status(400).json({
        error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { entityType: 'Entity type is required' } },
        meta,
      });
      return;
    }

    if (!['lead', 'contact', 'deal'].includes(body.entityType)) {
      res.status(400).json({
        error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { entityType: 'Invalid entity type' } },
        meta,
      });
      return;
    }

    if (!body.entityId) {
      res.status(400).json({
        error: { code: 'VALIDATION_ERROR', message: 'Validation failed', details: { entityId: 'Entity ID is required' } },
        meta,
      });
      return;
    }

    const db = getDb();

    // Verify sequence exists and is active
    const sequenceDoc = await db.doc(`businesses/${businessId}/sequences/${id}`).get();
    if (!sequenceDoc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Sequence not found' }, meta });
      return;
    }

    const sequenceData = sequenceDoc.data()!;
    if (!sequenceData.isActive) {
      res.status(400).json({
        error: { code: 'VALIDATION_ERROR', message: 'Sequence is not active' },
        meta,
      });
      return;
    }

    // Check for existing enrollment
    const existingEnrollment = await db
      .collection(`businesses/${businessId}/sequence_enrollments`)
      .where('sequenceId', '==', id)
      .where('entityId', '==', body.entityId)
      .where('status', '==', 'active')
      .limit(1)
      .get();

    if (!existingEnrollment.empty) {
      res.status(409).json({
        error: { code: 'CONFLICT', message: 'Entity is already enrolled in this sequence' },
        meta,
      });
      return;
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const startAt = body.startAt ? new Date(body.startAt) : new Date();

    const enrollmentData = {
      sequenceId: id,
      sequenceName: sequenceData.name,
      entityType: body.entityType,
      entityId: body.entityId,
      status: 'active',
      currentStepIndex: 0,
      startedAt: startAt,
      nextStepAt: startAt,
      completedSteps: [],
      enrolledBy: 'api',
      createdAt: now,
      updatedAt: now,
    };

    const enrollmentRef = await db.collection(`businesses/${businessId}/sequence_enrollments`).add(enrollmentData);

    // Trigger webhook
    triggerWebhook(businessId, 'sequence.enrolled', {
      enrollmentId: enrollmentRef.id,
      sequenceId: id,
      entityType: body.entityType,
      entityId: body.entityId,
    }).catch(console.error);

    res.status(201).json({
      data: {
        id: enrollmentRef.id,
        ...enrollmentData,
        startedAt: startAt.toISOString(),
        nextStepAt: startAt.toISOString(),
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
      meta,
    });
  } catch (error) {
    console.error('Enroll in sequence error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to enroll in sequence' }, meta });
  }
});

/**
 * DELETE /sequences/:id/enrollments/:enrollmentId - Unenroll from sequence
 */
router.delete('/:id/enrollments/:enrollmentId', checkScope('sequences:write'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id, enrollmentId } = req.params;
  const meta = getMeta(authReq);

  try {
    const db = getDb();
    const enrollmentRef = db.doc(`businesses/${businessId}/sequence_enrollments/${enrollmentId}`);
    const enrollmentDoc = await enrollmentRef.get();

    if (!enrollmentDoc.exists) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Enrollment not found' }, meta });
      return;
    }

    const enrollmentData = enrollmentDoc.data()!;
    if (enrollmentData.sequenceId !== id) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Enrollment not found for this sequence' }, meta });
      return;
    }

    await enrollmentRef.update({
      status: 'cancelled',
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      cancelledBy: 'api',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Trigger webhook
    triggerWebhook(businessId, 'sequence.unenrolled', {
      enrollmentId,
      sequenceId: id,
      entityType: enrollmentData.entityType,
      entityId: enrollmentData.entityId,
    }).catch(console.error);

    res.status(204).send();
  } catch (error) {
    console.error('Unenroll from sequence error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to unenroll from sequence' }, meta });
  }
});

/**
 * GET /sequences/:id/enrollments - List enrollments for sequence
 */
router.get('/:id/enrollments', checkScope('sequences:read'), async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  const { businessId } = authReq;
  const { id } = req.params;
  const meta = getMeta(authReq);

  try {
    const { page = '1', limit = '50', status } = req.query;

    const pageNum = Math.max(1, parseInt(String(page), 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(String(limit), 10) || 50));

    const db = getDb();
    let query: admin.firestore.Query = db
      .collection(`businesses/${businessId}/sequence_enrollments`)
      .where('sequenceId', '==', id);

    if (status) {
      query = query.where('status', '==', status);
    }

    query = query.orderBy('createdAt', 'desc');

    const countSnapshot = await query.count().get();
    const total = countSnapshot.data().count;
    const offset = (pageNum - 1) * limitNum;
    query = query.offset(offset).limit(limitNum);

    const snapshot = await query.get();
    const enrollments = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      startedAt: doc.data().startedAt?.toDate?.()?.toISOString(),
      nextStepAt: doc.data().nextStepAt?.toDate?.()?.toISOString(),
      completedAt: doc.data().completedAt?.toDate?.()?.toISOString(),
      cancelledAt: doc.data().cancelledAt?.toDate?.()?.toISOString(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString(),
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString(),
    }));

    res.json({
      data: enrollments,
      pagination: { page: pageNum, limit: limitNum, total, hasMore: offset + enrollments.length < total },
      meta,
    });
  } catch (error) {
    console.error('List enrollments error:', error);
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Failed to list enrollments' }, meta });
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
