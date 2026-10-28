/**
 * API Routes Tests
 * Tests for all REST API endpoints
 *
 * Task 5: Cloud Functions - API Layer
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import express, { Express } from 'express';
import request from 'supertest';

// Mock Firebase Admin - factory must not reference outside variables
vi.mock('firebase-admin', () => {
  let docIdCounter = 0;
  const createMockDocRef = () => ({
    id: `mock-doc-${++docIdCounter}`,
    get: vi.fn(),
    set: vi.fn().mockResolvedValue(undefined),
    update: vi.fn().mockResolvedValue(undefined),
    delete: vi.fn().mockResolvedValue(undefined),
  });

  const createMockCollectionRef = () => {
    const ref: Record<string, ReturnType<typeof vi.fn>> = {
      doc: vi.fn(),
      add: vi.fn(),
      where: vi.fn(),
      orderBy: vi.fn(),
      limit: vi.fn(),
      offset: vi.fn(),
      count: vi.fn(),
      get: vi.fn(),
    };
    ref.where.mockReturnValue(ref);
    ref.orderBy.mockReturnValue(ref);
    ref.limit.mockReturnValue(ref);
    ref.offset.mockReturnValue(ref);
    ref.count.mockReturnValue(ref);
    ref.doc.mockReturnValue(createMockDocRef());
    return ref;
  };

  const mockFirestore = {
    collection: vi.fn().mockImplementation(() => createMockCollectionRef()),
    doc: vi.fn().mockImplementation(() => createMockDocRef()),
    batch: vi.fn().mockReturnValue({
      set: vi.fn(),
      update: vi.fn(),
      delete: vi.fn(),
      commit: vi.fn().mockResolvedValue(undefined),
    }),
  };

  return {
    apps: [],
    initializeApp: vi.fn(),
    firestore: Object.assign(vi.fn(() => mockFirestore), {
      FieldValue: {
        serverTimestamp: vi.fn().mockReturnValue({ _serverTimestamp: true }),
        increment: vi.fn((n: number) => ({ _increment: n })),
      },
      Timestamp: {
        fromDate: vi.fn((d: Date) => ({ toDate: () => d })),
      },
    }),
  };
});

// Mock the middleware to skip auth for testing
vi.mock('../middleware', () => ({
  validateApiKey: vi.fn((_req, _res, next) => {
    _req.businessId = 'test-business-id';
    _req.apiKey = {
      id: 'test-api-key',
      businessId: 'test-business-id',
      name: 'Test Key',
      scopes: ['leads:read', 'leads:write', 'deals:read', 'deals:write', 'contacts:read', 'contacts:write', 'tasks:read', 'tasks:write', 'activities:read', 'sequences:read', 'sequences:write', 'webhooks:manage'],
      rateLimit: 1000,
      rateLimitWindow: 3600000,
      isActive: true,
    };
    _req.requestId = 'test-request-id';
    next();
  }),
  checkScope: vi.fn(() => (_req: express.Request, _res: express.Response, next: express.NextFunction) => next()),
  checkAnyScope: vi.fn(() => (_req: express.Request, _res: express.Response, next: express.NextFunction) => next()),
  checkAllScopes: vi.fn(() => (_req: express.Request, _res: express.Response, next: express.NextFunction) => next()),
  checkRateLimit: vi.fn((_req, _res, next) => next()),
  recordUsageMiddleware: vi.fn((_req, _res, next) => next()),
}));

import * as admin from 'firebase-admin';
import leadsRouter from '../routes/leads';
import dealsRouter from '../routes/deals';
import contactsRouter from '../routes/contacts';
import tasksRouter from '../routes/tasks';
import activitiesRouter from '../routes/activities';
import sequencesRouter from '../routes/sequences';
import webhooksRouter from '../routes/webhooks';

// Helper functions for mocking
let docIdCounter = 0;
const createMockDocRef = () => ({
  id: `mock-doc-${++docIdCounter}`,
  get: vi.fn(),
  set: vi.fn().mockResolvedValue(undefined),
  update: vi.fn().mockResolvedValue(undefined),
  delete: vi.fn().mockResolvedValue(undefined),
});

const createMockCollectionRef = () => {
  const ref: Record<string, ReturnType<typeof vi.fn>> = {
    doc: vi.fn(),
    add: vi.fn(),
    where: vi.fn(),
    orderBy: vi.fn(),
    limit: vi.fn(),
    offset: vi.fn(),
    count: vi.fn(),
    get: vi.fn(),
  };
  ref.where.mockReturnValue(ref);
  ref.orderBy.mockReturnValue(ref);
  ref.limit.mockReturnValue(ref);
  ref.offset.mockReturnValue(ref);
  ref.count.mockReturnValue(ref);
  ref.doc.mockReturnValue(createMockDocRef());
  return ref;
};

describe('API Routes', () => {
  let app: Express;
  let mockDb: ReturnType<typeof admin.firestore>;

  beforeEach(() => {
    app = express();
    app.use(express.json());
    app.use('/leads', leadsRouter);
    app.use('/deals', dealsRouter);
    app.use('/contacts', contactsRouter);
    app.use('/tasks', tasksRouter);
    app.use('/activities', activitiesRouter);
    app.use('/sequences', sequencesRouter);
    app.use('/webhooks', webhooksRouter);

    mockDb = admin.firestore();
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('Leads API', () => {
    describe('GET /leads', () => {
      it('should list leads with pagination', async () => {
        const mockLeadDoc = {
          id: 'lead123',
          data: () => ({
            firstName: 'John',
            lastName: 'Doe',
            email: 'john@example.com',
            status: 'new',
            createdAt: { toDate: () => new Date('2024-01-15') },
            updatedAt: { toDate: () => new Date('2024-01-15') },
          }),
        };

        const collRef = createMockCollectionRef();
        collRef.get.mockResolvedValue({
          data: () => ({ count: 1 }),
          docs: [mockLeadDoc],
        });
        (mockDb.collection as ReturnType<typeof vi.fn>).mockReturnValue(collRef);

        const response = await request(app)
          .get('/leads')
          .set('Authorization', 'Bearer test-key');

        expect(response.status).toBe(200);
        expect(response.body.data).toHaveLength(1);
        expect(response.body.data[0].firstName).toBe('John');
        expect(response.body.pagination).toBeDefined();
        expect(response.body.meta).toBeDefined();
      });

      it('should filter leads by status', async () => {
        let whereCalledWith: string[] = [];

        const collRef = createMockCollectionRef();
        collRef.where.mockImplementation((...args: string[]) => {
          whereCalledWith = args;
          return collRef;
        });
        collRef.get.mockResolvedValue({
          data: () => ({ count: 0 }),
          docs: [],
        });
        (mockDb.collection as ReturnType<typeof vi.fn>).mockReturnValue(collRef);

        await request(app)
          .get('/leads?status=qualified')
          .set('Authorization', 'Bearer test-key');

        expect(whereCalledWith).toContain('status');
        expect(whereCalledWith).toContain('qualified');
      });
    });

    describe('GET /leads/:id', () => {
      it('should return a lead by ID', async () => {
        const mockDocRef = createMockDocRef();
        mockDocRef.get.mockResolvedValue({
          exists: true,
          id: 'lead123',
          data: () => ({
            firstName: 'John',
            lastName: 'Doe',
            email: 'john@example.com',
            createdAt: { toDate: () => new Date('2024-01-15') },
            updatedAt: { toDate: () => new Date('2024-01-15') },
          }),
        });
        (mockDb.doc as ReturnType<typeof vi.fn>).mockReturnValue(mockDocRef);

        const response = await request(app)
          .get('/leads/lead123')
          .set('Authorization', 'Bearer test-key');

        expect(response.status).toBe(200);
        expect(response.body.data.firstName).toBe('John');
      });

      it('should return 404 for non-existent lead', async () => {
        const mockDocRef = createMockDocRef();
        mockDocRef.get.mockResolvedValue({
          exists: false,
        });
        (mockDb.doc as ReturnType<typeof vi.fn>).mockReturnValue(mockDocRef);

        const response = await request(app)
          .get('/leads/nonexistent')
          .set('Authorization', 'Bearer test-key');

        expect(response.status).toBe(404);
        expect(response.body.error.code).toBe('NOT_FOUND');
      });
    });

    describe('POST /leads', () => {
      it('should create a new lead', async () => {
        const collRef = createMockCollectionRef();
        collRef.add.mockResolvedValue({ id: 'newlead123' });
        collRef.get.mockResolvedValue({ docs: [] });
        (mockDb.collection as ReturnType<typeof vi.fn>).mockReturnValue(collRef);

        const response = await request(app)
          .post('/leads')
          .set('Authorization', 'Bearer test-key')
          .send({
            firstName: 'Jane',
            lastName: 'Smith',
            email: 'jane@example.com',
          });

        expect(response.status).toBe(201);
        expect(response.body.data.id).toBe('newlead123');
        expect(response.body.data.firstName).toBe('Jane');
      });

      it('should validate required fields - firstName', async () => {
        const response = await request(app)
          .post('/leads')
          .set('Authorization', 'Bearer test-key')
          .send({
            lastName: 'Smith',
            email: 'jane@example.com',
          });

        expect(response.status).toBe(400);
        expect(response.body.error.code).toBe('VALIDATION_ERROR');
        expect(response.body.error.details.firstName).toBeDefined();
      });

      it('should validate required fields - lastName', async () => {
        const response = await request(app)
          .post('/leads')
          .set('Authorization', 'Bearer test-key')
          .send({
            firstName: 'Jane',
            email: 'jane@example.com',
          });

        expect(response.status).toBe(400);
        expect(response.body.error.code).toBe('VALIDATION_ERROR');
        expect(response.body.error.details.lastName).toBeDefined();
      });

      it('should validate required fields - email', async () => {
        const response = await request(app)
          .post('/leads')
          .set('Authorization', 'Bearer test-key')
          .send({
            firstName: 'Jane',
            lastName: 'Smith',
          });

        expect(response.status).toBe(400);
        expect(response.body.error.code).toBe('VALIDATION_ERROR');
        expect(response.body.error.details.email).toBeDefined();
      });

      it('should validate email format', async () => {
        const response = await request(app)
          .post('/leads')
          .set('Authorization', 'Bearer test-key')
          .send({
            firstName: 'Jane',
            lastName: 'Smith',
            email: 'invalid-email',
          });

        expect(response.status).toBe(400);
        expect(response.body.error.details.email).toBeDefined();
      });
    });

    describe('PATCH /leads/:id', () => {
      it('should update an existing lead', async () => {
        const mockDocRef = createMockDocRef();
        mockDocRef.get
          .mockResolvedValueOnce({
            exists: true,
            data: () => ({ firstName: 'John', lastName: 'Doe' }),
          })
          .mockResolvedValueOnce({
            exists: true,
            id: 'lead123',
            data: () => ({
              firstName: 'John Updated',
              lastName: 'Doe',
              createdAt: { toDate: () => new Date('2024-01-15') },
              updatedAt: { toDate: () => new Date('2024-01-16') },
            }),
          });
        mockDocRef.update.mockResolvedValue(undefined);
        (mockDb.doc as ReturnType<typeof vi.fn>).mockReturnValue(mockDocRef);

        // Mock webhook collection
        const collRef = createMockCollectionRef();
        collRef.get.mockResolvedValue({ docs: [] });
        (mockDb.collection as ReturnType<typeof vi.fn>).mockReturnValue(collRef);

        const response = await request(app)
          .patch('/leads/lead123')
          .set('Authorization', 'Bearer test-key')
          .send({
            firstName: 'John Updated',
          });

        expect(response.status).toBe(200);
        expect(mockDocRef.update).toHaveBeenCalled();
      });

      it('should return 404 when updating non-existent lead', async () => {
        const mockDocRef = createMockDocRef();
        mockDocRef.get.mockResolvedValue({
          exists: false,
        });
        (mockDb.doc as ReturnType<typeof vi.fn>).mockReturnValue(mockDocRef);

        const response = await request(app)
          .patch('/leads/nonexistent')
          .set('Authorization', 'Bearer test-key')
          .send({
            firstName: 'Updated',
          });

        expect(response.status).toBe(404);
        expect(response.body.error.code).toBe('NOT_FOUND');
      });
    });

    describe('DELETE /leads/:id', () => {
      it('should delete an existing lead', async () => {
        const mockDocRef = createMockDocRef();
        mockDocRef.get.mockResolvedValue({
          exists: true,
        });
        mockDocRef.delete.mockResolvedValue(undefined);
        (mockDb.doc as ReturnType<typeof vi.fn>).mockReturnValue(mockDocRef);

        const response = await request(app)
          .delete('/leads/lead123')
          .set('Authorization', 'Bearer test-key');

        expect(response.status).toBe(204);
        expect(mockDocRef.delete).toHaveBeenCalled();
      });

      it('should return 404 when deleting non-existent lead', async () => {
        const mockDocRef = createMockDocRef();
        mockDocRef.get.mockResolvedValue({
          exists: false,
        });
        (mockDb.doc as ReturnType<typeof vi.fn>).mockReturnValue(mockDocRef);

        const response = await request(app)
          .delete('/leads/nonexistent')
          .set('Authorization', 'Bearer test-key');

        expect(response.status).toBe(404);
        expect(response.body.error.code).toBe('NOT_FOUND');
      });
    });
  });

  describe('Deals API', () => {
    describe('POST /deals', () => {
      it('should create a new deal', async () => {
        const collRef = createMockCollectionRef();
        collRef.add.mockResolvedValue({ id: 'deal123' });
        collRef.get.mockResolvedValue({ docs: [] });
        (mockDb.collection as ReturnType<typeof vi.fn>).mockReturnValue(collRef);

        const response = await request(app)
          .post('/deals')
          .set('Authorization', 'Bearer test-key')
          .send({
            title: 'New Deal',
            pipelineId: 'pipeline123',
            stageId: 'stage123',
            valueCents: 100000,
          });

        expect(response.status).toBe(201);
        expect(response.body.data.id).toBe('deal123');
        expect(response.body.data.title).toBe('New Deal');
      });

      it('should validate required fields - title', async () => {
        const response = await request(app)
          .post('/deals')
          .set('Authorization', 'Bearer test-key')
          .send({
            pipelineId: 'pipeline123',
            stageId: 'stage123',
          });

        expect(response.status).toBe(400);
        expect(response.body.error.code).toBe('VALIDATION_ERROR');
        expect(response.body.error.details.title).toBeDefined();
      });

      it('should validate required fields - pipelineId', async () => {
        const response = await request(app)
          .post('/deals')
          .set('Authorization', 'Bearer test-key')
          .send({
            title: 'New Deal',
            stageId: 'stage123',
          });

        expect(response.status).toBe(400);
        expect(response.body.error.code).toBe('VALIDATION_ERROR');
        expect(response.body.error.details.pipelineId).toBeDefined();
      });

      it('should validate required fields - stageId', async () => {
        const response = await request(app)
          .post('/deals')
          .set('Authorization', 'Bearer test-key')
          .send({
            title: 'New Deal',
            pipelineId: 'pipeline123',
          });

        expect(response.status).toBe(400);
        expect(response.body.error.code).toBe('VALIDATION_ERROR');
        expect(response.body.error.details.stageId).toBeDefined();
      });
    });

    describe('POST /deals/:id/won', () => {
      it('should mark deal as won', async () => {
        const mockDocRef = createMockDocRef();
        mockDocRef.get.mockResolvedValue({
          exists: true,
          data: () => ({ title: 'Test Deal', status: 'open' }),
        });
        mockDocRef.update.mockResolvedValue(undefined);
        (mockDb.doc as ReturnType<typeof vi.fn>).mockReturnValue(mockDocRef);

        const collRef = createMockCollectionRef();
        collRef.get.mockResolvedValue({ docs: [] });
        (mockDb.collection as ReturnType<typeof vi.fn>).mockReturnValue(collRef);

        const response = await request(app)
          .post('/deals/deal123/won')
          .set('Authorization', 'Bearer test-key')
          .send({ wonReason: 'Good price' });

        expect(response.status).toBe(200);
        expect(response.body.data.status).toBe('won');
      });
    });

    describe('POST /deals/:id/lost', () => {
      it('should mark deal as lost', async () => {
        const mockDocRef = createMockDocRef();
        mockDocRef.get.mockResolvedValue({
          exists: true,
          data: () => ({ title: 'Test Deal', status: 'open' }),
        });
        mockDocRef.update.mockResolvedValue(undefined);
        (mockDb.doc as ReturnType<typeof vi.fn>).mockReturnValue(mockDocRef);

        const collRef = createMockCollectionRef();
        collRef.get.mockResolvedValue({ docs: [] });
        (mockDb.collection as ReturnType<typeof vi.fn>).mockReturnValue(collRef);

        const response = await request(app)
          .post('/deals/deal123/lost')
          .set('Authorization', 'Bearer test-key')
          .send({ lostReason: 'Budget constraints' });

        expect(response.status).toBe(200);
        expect(response.body.data.status).toBe('lost');
      });
    });
  });

  describe('Contacts API', () => {
    describe('POST /contacts', () => {
      it('should create a new contact', async () => {
        const collRef = createMockCollectionRef();
        collRef.add.mockResolvedValue({ id: 'contact123' });
        collRef.get.mockResolvedValue({ docs: [] });
        (mockDb.collection as ReturnType<typeof vi.fn>).mockReturnValue(collRef);

        const response = await request(app)
          .post('/contacts')
          .set('Authorization', 'Bearer test-key')
          .send({
            firstName: 'Alice',
            lastName: 'Johnson',
            email: 'alice@example.com',
          });

        expect(response.status).toBe(201);
        expect(response.body.data.id).toBe('contact123');
      });
    });
  });

  describe('Tasks API', () => {
    describe('POST /tasks', () => {
      it('should create a new task', async () => {
        const collRef = createMockCollectionRef();
        collRef.add.mockResolvedValue({ id: 'task123' });
        collRef.get.mockResolvedValue({ docs: [] });
        (mockDb.collection as ReturnType<typeof vi.fn>).mockReturnValue(collRef);

        const response = await request(app)
          .post('/tasks')
          .set('Authorization', 'Bearer test-key')
          .send({
            type: 'follow_up',
            title: 'Follow up call',
            dueDate: '2024-01-20T10:00:00Z',
          });

        expect(response.status).toBe(201);
        expect(response.body.data.id).toBe('task123');
      });
    });

    describe('POST /tasks/:id/complete', () => {
      it('should mark task as complete', async () => {
        const mockDocRef = createMockDocRef();
        mockDocRef.get.mockResolvedValue({
          exists: true,
          data: () => ({ type: 'task', title: 'Test Task', isCompleted: false }),
        });
        mockDocRef.update.mockResolvedValue(undefined);
        (mockDb.doc as ReturnType<typeof vi.fn>).mockReturnValue(mockDocRef);

        const collRef = createMockCollectionRef();
        collRef.get.mockResolvedValue({ docs: [] });
        (mockDb.collection as ReturnType<typeof vi.fn>).mockReturnValue(collRef);

        const response = await request(app)
          .post('/tasks/task123/complete')
          .set('Authorization', 'Bearer test-key')
          .send({ completionNotes: 'Done!' });

        expect(response.status).toBe(200);
        expect(response.body.data.isCompleted).toBe(true);
      });
    });
  });

  describe('Activities API', () => {
    describe('POST /activities', () => {
      it('should log an activity', async () => {
        const collRef = createMockCollectionRef();
        collRef.add.mockResolvedValue({ id: 'activity123' });
        (mockDb.collection as ReturnType<typeof vi.fn>).mockReturnValue(collRef);

        const response = await request(app)
          .post('/activities')
          .set('Authorization', 'Bearer test-key')
          .send({
            type: 'call',
            title: 'Sales call with client',
          });

        expect(response.status).toBe(201);
        expect(response.body.data.id).toBe('activity123');
      });
    });
  });

  describe('Webhooks API', () => {
    describe('POST /webhooks', () => {
      it('should create a webhook endpoint', async () => {
        const collRef = createMockCollectionRef();
        collRef.add.mockResolvedValue({ id: 'webhook123' });
        (mockDb.collection as ReturnType<typeof vi.fn>).mockReturnValue(collRef);

        const response = await request(app)
          .post('/webhooks')
          .set('Authorization', 'Bearer test-key')
          .send({
            name: 'My Webhook',
            url: 'https://example.com/webhook',
            events: ['lead.created', 'deal.won'],
          });

        expect(response.status).toBe(201);
        expect(response.body.data.id).toBe('webhook123');
        expect(response.body.data.secret).toBeDefined();
        expect(response.body.data.secret).toMatch(/^whsec_/);
      });

      it('should validate HTTPS URL requirement', async () => {
        const response = await request(app)
          .post('/webhooks')
          .set('Authorization', 'Bearer test-key')
          .send({
            name: 'My Webhook',
            url: 'http://example.com/webhook',
            events: ['lead.created'],
          });

        expect(response.status).toBe(400);
        expect(response.body.error.details.url).toBeDefined();
      });

      it('should validate event types', async () => {
        const response = await request(app)
          .post('/webhooks')
          .set('Authorization', 'Bearer test-key')
          .send({
            name: 'My Webhook',
            url: 'https://example.com/webhook',
            events: ['invalid.event'],
          });

        expect(response.status).toBe(400);
        expect(response.body.error.details.events).toBeDefined();
      });
    });

    describe('POST /webhooks/:id/test', () => {
      it('should queue a test delivery', async () => {
        const mockDocRef = createMockDocRef();
        mockDocRef.get.mockResolvedValue({
          exists: true,
          data: () => ({ name: 'Test Webhook', isActive: true }),
        });
        (mockDb.doc as ReturnType<typeof vi.fn>).mockReturnValue(mockDocRef);

        const mockDeliveryDocRef = createMockDocRef();
        mockDeliveryDocRef.set.mockResolvedValue(undefined);

        const collRef = createMockCollectionRef();
        collRef.doc.mockReturnValue(mockDeliveryDocRef);
        (mockDb.collection as ReturnType<typeof vi.fn>).mockReturnValue(collRef);

        const response = await request(app)
          .post('/webhooks/webhook123/test')
          .set('Authorization', 'Bearer test-key');

        expect(response.status).toBe(200);
        expect(response.body.data.deliveryId).toBeDefined();
      });
    });
  });

  describe('Sequences API', () => {
    describe('POST /sequences/:id/enroll', () => {
      it('should enroll entity in sequence', async () => {
        const mockDocRef = createMockDocRef();
        mockDocRef.get.mockResolvedValue({
          exists: true,
          data: () => ({ name: 'Welcome Sequence', isActive: true }),
        });
        (mockDb.doc as ReturnType<typeof vi.fn>).mockReturnValue(mockDocRef);

        let addCalled = false;
        (mockDb.collection as ReturnType<typeof vi.fn>).mockImplementation((path: string) => {
          const collRef = createMockCollectionRef();
          if (path.includes('sequence_enrollments')) {
            collRef.get.mockResolvedValue({
              empty: true,
              docs: [],
            });
            collRef.add.mockImplementation(() => {
              addCalled = true;
              return Promise.resolve({ id: 'enrollment123' });
            });
          } else if (path.includes('webhook_endpoints')) {
            collRef.get.mockResolvedValue({ docs: [] });
          }
          return collRef;
        });

        const response = await request(app)
          .post('/sequences/seq123/enroll')
          .set('Authorization', 'Bearer test-key')
          .send({
            entityType: 'lead',
            entityId: 'lead123',
          });

        expect(response.status).toBe(201);
        expect(response.body.data.id).toBe('enrollment123');
        expect(addCalled).toBe(true);
      });

      it('should prevent duplicate enrollments', async () => {
        const mockDocRef = createMockDocRef();
        mockDocRef.get.mockResolvedValue({
          exists: true,
          data: () => ({ name: 'Welcome Sequence', isActive: true }),
        });
        (mockDb.doc as ReturnType<typeof vi.fn>).mockReturnValue(mockDocRef);

        (mockDb.collection as ReturnType<typeof vi.fn>).mockImplementation((path: string) => {
          const collRef = createMockCollectionRef();
          if (path.includes('sequence_enrollments')) {
            collRef.get.mockResolvedValue({
              empty: false,
              docs: [{ id: 'existing123' }],
            });
          }
          return collRef;
        });

        const response = await request(app)
          .post('/sequences/seq123/enroll')
          .set('Authorization', 'Bearer test-key')
          .send({
            entityType: 'lead',
            entityId: 'lead123',
          });

        expect(response.status).toBe(409);
        expect(response.body.error.code).toBe('CONFLICT');
      });

      it('should validate entity type', async () => {
        const response = await request(app)
          .post('/sequences/seq123/enroll')
          .set('Authorization', 'Bearer test-key')
          .send({
            entityType: 'invalid',
            entityId: 'lead123',
          });

        expect(response.status).toBe(400);
        expect(response.body.error.code).toBe('VALIDATION_ERROR');
      });
    });
  });
});

describe('Response Format', () => {
  let app: Express;
  let mockDb: ReturnType<typeof admin.firestore>;

  beforeEach(() => {
    app = express();
    app.use(express.json());
    app.use('/leads', leadsRouter);
    mockDb = admin.firestore();
    vi.clearAllMocks();
  });

  it('should include meta in all responses', async () => {
    const collRef = createMockCollectionRef();
    collRef.get.mockResolvedValue({
      data: () => ({ count: 0 }),
      docs: [],
    });
    (mockDb.collection as ReturnType<typeof vi.fn>).mockReturnValue(collRef);

    const response = await request(app)
      .get('/leads')
      .set('Authorization', 'Bearer test-key');

    expect(response.body.meta).toBeDefined();
    expect(response.body.meta.requestId).toBeDefined();
    expect(response.body.meta.timestamp).toBeDefined();
  });

  it('should include pagination in list responses', async () => {
    const collRef = createMockCollectionRef();
    collRef.get.mockResolvedValue({
      data: () => ({ count: 100 }),
      docs: [],
    });
    (mockDb.collection as ReturnType<typeof vi.fn>).mockReturnValue(collRef);

    const response = await request(app)
      .get('/leads?page=2&limit=10')
      .set('Authorization', 'Bearer test-key');

    expect(response.body.pagination).toBeDefined();
    expect(response.body.pagination.page).toBe(2);
    expect(response.body.pagination.limit).toBe(10);
    expect(response.body.pagination.total).toBe(100);
    expect(response.body.pagination.hasMore).toBeDefined();
  });
});
