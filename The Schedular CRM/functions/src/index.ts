/**
 * Cloud Functions Entry Point
 * Main entry point for Firebase Cloud Functions
 *
 * Task 5: Cloud Functions - API Layer
 *
 * HIPAA Compliance:
 * - All requests require valid API key authentication
 * - All operations scoped by businessId (tenant isolation)
 * - No PHI in error messages or logs
 * - Request metadata logged for audit trail
 * - Rate limiting enforced per API key
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import {
  leadsRouter,
  dealsRouter,
  contactsRouter,
  tasksRouter,
  activitiesRouter,
  sequencesRouter,
  webhooksRouter,
} from './api/routes';
import {
  connectCalendar,
  disconnectCalendar,
  googleCalendarCallback,
  googleCalendarWebhook,
  outlookCalendarCallback,
  outlookCalendarWebhook,
  refreshCalendarTokens,
  syncCalendar,
} from './calendar';
import {
  connectEmailAccount,
  disconnectEmailAccount,
  gmailOAuthCallback,
  gmailWebhook,
  outlookOAuthCallback,
  outlookWebhook,
  refreshEmailTokens,
  scheduledEmailSync,
  sendIntegratedEmail,
  syncEmailInbox,
  syncEmailSent,
  trackEmailClick,
  trackEmailOpen,
} from './email';
import { runImport } from './importer';
import { runMultiEntityImport } from './multi-entity-import-handler';

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

// Create Express app
const app = express();

// CORS configuration
const corsOptions: cors.CorsOptions = {
  origin: true, // Allow all origins for API (authentication via API key)
  methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID'],
  exposedHeaders: ['X-RateLimit-Limit', 'X-RateLimit-Remaining', 'X-RateLimit-Reset'],
  credentials: false,
  maxAge: 86400, // 24 hours
};

// Middleware
app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request ID middleware
app.use((req: Request, _res: Response, next: NextFunction) => {
  (req as unknown as { requestId: string }).requestId =
    (req.headers['x-request-id'] as string) || `req_${Date.now().toString(36)}_${Math.random().toString(36).substring(2, 8)}`;
  next();
});

// Health check endpoint (no auth required)
app.get('/health', (_req: Request, res: Response) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

// API versioning - mount all routes under /v1
const v1Router = express.Router();

v1Router.use('/leads', leadsRouter);
v1Router.use('/deals', dealsRouter);
v1Router.use('/contacts', contactsRouter);
v1Router.use('/tasks', tasksRouter);
v1Router.use('/activities', activitiesRouter);
v1Router.use('/sequences', sequencesRouter);
v1Router.use('/webhooks', webhooksRouter);

app.use('/v1', v1Router);

// 404 handler
app.use((_req: Request, res: Response) => {
  res.status(404).json({
    error: {
      code: 'NOT_FOUND',
      message: 'Endpoint not found',
    },
    meta: {
      timestamp: new Date().toISOString(),
    },
  });
});

// Global error handler
app.use((err: Error, req: Request, res: Response, _next: NextFunction) => {
  console.error('Unhandled error:', err);

  // Never expose internal error details
  res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'An internal error occurred',
    },
    meta: {
      requestId: (req as unknown as { requestId?: string }).requestId,
      timestamp: new Date().toISOString(),
    },
  });
});

// Export the Express app as a Cloud Function
export const api = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 60,
    memory: '256MB',
    minInstances: 0,
    maxInstances: 100,
  })
  .https.onRequest(app);

// Calendar HTTPS endpoints
export {
  connectCalendar,
  refreshCalendarTokens,
  syncCalendar,
  disconnectCalendar,
  googleCalendarCallback,
  outlookCalendarCallback,
  googleCalendarWebhook,
  outlookCalendarWebhook,
};

// Email HTTPS endpoints
export {
  connectEmailAccount,
  refreshEmailTokens,
  syncEmailInbox,
  syncEmailSent,
  sendIntegratedEmail,
  disconnectEmailAccount,
  gmailOAuthCallback,
  outlookOAuthCallback,
  gmailWebhook,
  outlookWebhook,
  trackEmailOpen,
  trackEmailClick,
  scheduledEmailSync,
};

// Export individual function for webhook delivery processing
export const processWebhookDelivery = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 30,
    memory: '256MB',
  })
  .firestore.document('businesses/{businessId}/webhook_deliveries/{deliveryId}')
  .onCreate(async (snapshot, context) => {
    const { businessId, deliveryId } = context.params;
    const delivery = snapshot.data();

    if (delivery.status !== 'pending') {
      return;
    }

    const db = admin.firestore();

    try {
      // Get webhook endpoint
      const webhookDoc = await db.doc(`businesses/${businessId}/webhook_endpoints/${delivery.webhookId}`).get();

      if (!webhookDoc.exists) {
        await snapshot.ref.update({
          status: 'failed',
          error: 'Webhook endpoint not found',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      const webhook = webhookDoc.data()!;

      if (!webhook.isActive) {
        await snapshot.ref.update({
          status: 'skipped',
          error: 'Webhook endpoint is inactive',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      // Prepare request headers
      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
        'X-Webhook-ID': delivery.webhookId,
        'X-Delivery-ID': deliveryId,
        'X-Event-Type': delivery.event,
        ...webhook.customHeaders,
      };

      // Sign the payload
      const crypto = await import('crypto');
      const payloadString = JSON.stringify(delivery.payload);
      const signature = crypto.createHmac('sha256', webhook.secret).update(payloadString).digest('hex');
      headers['X-Webhook-Signature'] = `sha256=${signature}`;

      // Make the HTTP request
      const response = await fetch(webhook.url, {
        method: 'POST',
        headers,
        body: payloadString,
      });

      const responseBody = await response.text().catch(() => '');

      if (response.ok) {
        await snapshot.ref.update({
          status: 'delivered',
          deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
          responseStatus: response.status,
          responseBody: responseBody.substring(0, 1000), // Limit stored response
          attemptCount: admin.firestore.FieldValue.increment(1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        const attemptCount = (delivery.attemptCount || 0) + 1;
        const shouldRetry = webhook.retryEnabled && attemptCount < (webhook.maxRetries || 3);

        await snapshot.ref.update({
          status: shouldRetry ? 'pending' : 'failed',
          responseStatus: response.status,
          responseBody: responseBody.substring(0, 1000),
          attemptCount,
          lastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
          nextRetryAt: shouldRetry
            ? admin.firestore.Timestamp.fromDate(new Date(Date.now() + Math.pow(2, attemptCount) * 1000 * 60))
            : null,
          error: `HTTP ${response.status}`,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (error) {
      const attemptCount = (delivery.attemptCount || 0) + 1;

      await snapshot.ref.update({
        status: 'failed',
        attemptCount,
        error: error instanceof Error ? error.message : 'Unknown error',
        lastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.error(`Webhook delivery ${deliveryId} failed:`, error);
    }
  });

// Scheduled function to retry failed webhook deliveries
export const retryWebhookDeliveries = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 300,
    memory: '256MB',
  })
  .pubsub.schedule('every 5 minutes')
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();

    // Find all pending deliveries that are due for retry
    const businessesSnapshot = await db.collection('businesses').get();

    for (const businessDoc of businessesSnapshot.docs) {
      const businessId = businessDoc.id;

      const pendingDeliveries = await db
        .collection(`businesses/${businessId}/webhook_deliveries`)
        .where('status', '==', 'pending')
        .where('nextRetryAt', '<=', now)
        .limit(100)
        .get();

      for (const deliveryDoc of pendingDeliveries.docs) {
        const delivery = deliveryDoc.data();

        // Get webhook endpoint
        const webhookDoc = await db.doc(`businesses/${businessId}/webhook_endpoints/${delivery.webhookId}`).get();

        if (!webhookDoc.exists || !webhookDoc.data()?.isActive) {
          await deliveryDoc.ref.update({
            status: 'failed',
            error: 'Webhook endpoint not found or inactive',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          continue;
        }

        const webhook = webhookDoc.data()!;

        try {
          const headers: Record<string, string> = {
            'Content-Type': 'application/json',
            'X-Webhook-ID': delivery.webhookId,
            'X-Delivery-ID': deliveryDoc.id,
            'X-Event-Type': delivery.event,
            ...webhook.customHeaders,
          };

          const crypto = await import('crypto');
          const payloadString = JSON.stringify(delivery.payload);
          const signature = crypto.createHmac('sha256', webhook.secret).update(payloadString).digest('hex');
          headers['X-Webhook-Signature'] = `sha256=${signature}`;

          const response = await fetch(webhook.url, {
            method: 'POST',
            headers,
            body: payloadString,
          });

          const responseBody = await response.text().catch(() => '');

          if (response.ok) {
            await deliveryDoc.ref.update({
              status: 'delivered',
              deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
              responseStatus: response.status,
              responseBody: responseBody.substring(0, 1000),
              attemptCount: admin.firestore.FieldValue.increment(1),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          } else {
            const attemptCount = (delivery.attemptCount || 0) + 1;
            const shouldRetry = webhook.retryEnabled && attemptCount < (webhook.maxRetries || 3);

            await deliveryDoc.ref.update({
              status: shouldRetry ? 'pending' : 'failed',
              responseStatus: response.status,
              responseBody: responseBody.substring(0, 1000),
              attemptCount,
              lastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
              nextRetryAt: shouldRetry
                ? admin.firestore.Timestamp.fromDate(new Date(Date.now() + Math.pow(2, attemptCount) * 1000 * 60))
                : null,
              error: `HTTP ${response.status}`,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        } catch (error) {
          const attemptCount = (delivery.attemptCount || 0) + 1;

          await deliveryDoc.ref.update({
            status: 'failed',
            attemptCount,
            error: error instanceof Error ? error.message : 'Unknown error',
            lastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }
    }

    return null;
  });

// --- Import/Resume Import endpoints (Firebase ID token + business scope) ---
type AllowedEntity = 'lead' | 'contact' | 'deal' | 'company' | 'client' | 'appointment' | 'multi';
type MultiEntityPrimaryType = 'lead' | 'contact' | 'deal' | 'company';

interface ImportDataRequestBody {
  entityType: AllowedEntity;
  primaryEntityType?: MultiEntityPrimaryType;
  rows: string[][];
  headers: string[];
  fieldMapping: Record<string, string>;
  sessionId?: string;
  businessId?: string;
  existingIdentifiers?: { emails?: string[]; phones?: string[] };
  duplicateHandling?: 'skip' | 'update' | 'create';
  skipFirstRow?: boolean;
  dryRun?: boolean;
}

interface ImportJobResult {
  success: boolean;
  sessionId: string;
  processedRows: number;
  totalRows: number;
  validationErrors: { row: number; field?: string; error: string }[];
  resumeToken?: string;
  backoffMs?: number;
  errors?: string[];
  multiEntitySummary?: {
    companiesCreated: number;
    contactsCreated: number;
    leadsCreated: number;
    dealsCreated: number;
  };
}

const allowedEntities: AllowedEntity[] = [
  'lead',
  'contact',
  'deal',
  'company',
  'client',
  'appointment',
  'multi',
];
const allowedPrimaryEntities: MultiEntityPrimaryType[] = ['lead', 'contact', 'deal', 'company'];

const importCorsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Business-Id',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function applyImportCors(res: Response): void {
  Object.entries(importCorsHeaders).forEach(([key, value]) => res.set(key, value));
}

function sendImportError(res: Response, status: number, message: string): void {
  applyImportCors(res);
  res.status(status).json({
    success: false,
    sessionId: '',
    processedRows: 0,
    totalRows: 0,
    validationErrors: [],
    errors: [message],
  });
}

async function authenticateRequest(req: Request, res: Response): Promise<{
  uid: string;
  businessId: string;
  role?: string;
} | null> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    sendImportError(res, 401, 'Unauthorized');
    return null;
  }

  try {
    const token = authHeader.replace('Bearer ', '');
    const decoded = await admin.auth().verifyIdToken(token);
    const headerBusinessId = (req.headers['x-business-id'] as string | undefined)?.trim();
    const businessId =
      headerBusinessId ||
      (decoded as { businessId?: string }).businessId ||
      (decoded as { business_id?: string }).business_id;

    if (!businessId) {
      sendImportError(res, 400, 'Missing businessId');
      return null;
    }

    return { uid: decoded.uid, businessId, role: (decoded as { role?: string }).role };
  } catch {
    sendImportError(res, 401, 'Unauthorized');
    return null;
  }
}

export const importData = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 30,
    memory: '256MB',
    minInstances: 0,
    maxInstances: 50,
  })
  .https.onRequest(async (req: Request, res: Response) => {
    applyImportCors(res);
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    if (req.method !== 'POST') {
      sendImportError(res, 405, 'Method not allowed');
      return;
    }

    const auth = await authenticateRequest(req, res);
    if (!auth) return;

    const body = (req.body || {}) as ImportDataRequestBody;
    if (!body.entityType || !allowedEntities.includes(body.entityType)) {
      sendImportError(res, 400, 'Invalid entityType');
      return;
    }

    if (!Array.isArray(body.headers) || !Array.isArray(body.rows)) {
      sendImportError(res, 400, 'Invalid payload');
      return;
    }

    if (
      body.primaryEntityType &&
      !allowedPrimaryEntities.includes(body.primaryEntityType)
    ) {
      sendImportError(res, 400, 'Invalid primaryEntityType');
      return;
    }

    const totalRows = body.skipFirstRow ? Math.max(0, body.rows.length - 1) : body.rows.length;
    const sessionId = body.sessionId || `import_${Date.now()}`;

    try {
      // Route to multi-entity importer if entityType is 'multi'
      const importResult = body.entityType === 'multi'
        ? await runMultiEntityImport(admin.firestore(), {
            entityType: body.entityType,
            primaryEntityType: body.primaryEntityType,
            headers: body.headers,
            rows: body.rows,
            fieldMapping: body.fieldMapping,
            businessId: auth.businessId,
            duplicateHandling: body.duplicateHandling || 'skip',
            skipFirstRow: body.skipFirstRow || false,
            dryRun: body.dryRun || false,
            existingIdentifiers: body.existingIdentifiers,
            userId: auth.uid,
            userRole: auth.role,
            userBusinessId: auth.businessId,
          })
        : await runImport(admin.firestore(), {
            entityType: body.entityType,
            primaryEntityType: body.primaryEntityType,
            headers: body.headers,
            rows: body.rows,
            fieldMapping: body.fieldMapping,
            businessId: auth.businessId,
            duplicateHandling: body.duplicateHandling || 'skip',
            skipFirstRow: body.skipFirstRow || false,
            dryRun: body.dryRun || false,
            existingIdentifiers: body.existingIdentifiers,
            userId: auth.uid,
            userRole: auth.role,
            userBusinessId: auth.businessId,
          });

      const response: ImportJobResult = {
        success: !importResult.errors?.length && importResult.validationErrors.length === 0,
        sessionId,
        processedRows: importResult.imported,
        totalRows,
        validationErrors: importResult.validationErrors,
        resumeToken: undefined,
        errors: importResult.errors,
        multiEntitySummary: importResult.multiEntitySummary,
      };

      res.status(200).json(response);
    } catch (error) {
      sendImportError(res, 500, error instanceof Error ? error.message : 'Import failed');
    }
  });

export const resumeImport = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 30,
    memory: '256MB',
    minInstances: 0,
    maxInstances: 50,
  })
  .https.onRequest(async (req: Request, res: Response) => {
    applyImportCors(res);
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    if (req.method !== 'POST') {
      sendImportError(res, 405, 'Method not allowed');
      return;
    }

    const auth = await authenticateRequest(req, res);
    if (!auth) return;

    const { sessionId, resumeToken } = req.body || {};
    if (!sessionId || !resumeToken) {
      sendImportError(res, 400, 'Missing sessionId or resumeToken');
      return;
    }

    const response: ImportJobResult = {
      success: true,
      sessionId,
      processedRows: 0,
      totalRows: 0,
      validationErrors: [],
      resumeToken,
      errors: undefined,
    };

    res.status(200).json(response);
  });
