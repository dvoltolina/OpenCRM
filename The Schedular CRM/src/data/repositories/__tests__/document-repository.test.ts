import { beforeEach, describe, expect, it, vi } from 'vitest';
import { DocumentRepository } from '../document-repository';
import type { SecurityContext } from '../repository-types';
import type { Document } from '../../../types/documents';
import { successResult } from '../../errors/repository-errors';

vi.mock('../../../lib/firebase', () => ({
  getFirebaseDb: vi.fn(() => ({})),
}));

vi.mock('firebase/firestore', () => ({
  collection: vi.fn(),
  doc: vi.fn(),
  getDoc: vi.fn(),
  getDocs: vi.fn(() => ({ docs: [], empty: true })),
  setDoc: vi.fn(),
  updateDoc: vi.fn(),
  deleteDoc: vi.fn(),
  onSnapshot: vi.fn(),
  writeBatch: vi.fn(),
  query: vi.fn(),
  where: vi.fn(),
  orderBy: vi.fn(),
  limit: vi.fn(),
  startAfter: vi.fn(),
  Timestamp: {
    now: vi.fn(() => ({ toDate: () => new Date() })),
    fromDate: vi.fn((date: Date) => ({ toDate: () => date })),
  },
}));

describe('DocumentRepository RBAC and folders', () => {
  let repo: DocumentRepository;
  let context: SecurityContext;
  let baseDocument: Document;

  beforeEach(() => {
    repo = new DocumentRepository();
    context = {
      businessId: 'biz-1',
      userId: 'user-1',
      userName: 'User One',
      userRole: 'staff',
      teamIds: ['team-1'],
      managedTeamIds: [],
    };

    baseDocument = {
      id: 'doc-owner',
      businessId: context.businessId,
      name: 'Doc',
      documentType: 'contract',
      status: 'draft',
      fileName: 'doc.pdf',
      fileType: 'application/pdf',
      fileSize: 100,
      storageUrl: 'businesses/biz-1/documents/doc-owner/original/doc.pdf',
      version: 1,
      isLatestVersion: true,
      requiresSignature: false,
      uploadedById: context.userId,
      uploadedByName: context.userName,
      ownerId: context.userId,
      ownerName: context.userName,
      isPublic: false,
      accessUserIds: [context.userId],
      accessTeamIds: [],
      createdAt: new Date(),
    };

    vi.clearAllMocks();
  });

  it('filters documents to those accessible by user/team/public visibility', async () => {
    const docs: Document[] = [
      baseDocument,
      {
        ...baseDocument,
        id: 'doc-team',
        ownerId: 'other',
        uploadedById: 'other',
        accessUserIds: [],
        accessTeamIds: ['team-1'],
      },
      {
        ...baseDocument,
        id: 'doc-public',
        ownerId: 'other',
        uploadedById: 'other',
        accessUserIds: [],
        accessTeamIds: [],
        isPublic: true,
      },
      {
        ...baseDocument,
        id: 'doc-denied',
        ownerId: 'other',
        uploadedById: 'other',
        accessUserIds: ['another'],
        accessTeamIds: ['team-2'],
        isPublic: false,
      },
    ];

    vi.spyOn(repo as any, 'getAll').mockResolvedValue(
      successResult({ data: docs, lastDoc: null, hasMore: false })
    );

    const result = await repo.getDocuments(context, {});

    expect(result.success).toBe(true);
    const ids = result.success ? result.data.map((doc) => doc.id) : [];
    expect(ids).toContain('doc-owner');
    expect(ids).toContain('doc-team');
    expect(ids).toContain('doc-public');
    expect(ids).not.toContain('doc-denied');
  });

  it('allows org-privileged users to access documents regardless of access lists', async () => {
    const docs: Document[] = [
      { ...baseDocument, id: 'doc-public', isPublic: true },
      {
        ...baseDocument,
        id: 'doc-restricted',
        ownerId: 'other',
        uploadedById: 'other',
        accessUserIds: [],
        accessTeamIds: [],
        isPublic: false,
      },
    ];
    context = { ...context, userRole: 'admin' };

    vi.spyOn(repo as any, 'getAll').mockResolvedValue(
      successResult({ data: docs, lastDoc: null, hasMore: false })
    );

    const result = await repo.getDocuments(context, {});

    expect(result.success).toBe(true);
    const ids = result.success ? result.data.map((doc) => doc.id) : [];
    expect(ids).toEqual(['doc-public', 'doc-restricted']);
  });

  it('returns permission error when fetching an inaccessible document', async () => {
    const restrictedDoc: Document = {
      ...baseDocument,
      id: 'doc-denied',
      ownerId: 'other',
      uploadedById: 'other',
      accessUserIds: [],
      accessTeamIds: [],
      isPublic: false,
    };

    vi.spyOn(repo as any, 'getById').mockResolvedValue(successResult(restrictedDoc));

    const result = await repo.getDocument(context, restrictedDoc.id);

    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('PERMISSION_DENIED');
  });

  it('moves documents into folders when user has access', async () => {
    const folderedDoc = { ...baseDocument, folderId: 'folder-2' };
    vi.spyOn(repo, 'getDocument').mockResolvedValue(successResult(baseDocument));
    const updateSpy = vi
      .spyOn(repo as any, 'update')
      .mockResolvedValue(successResult(folderedDoc));

    const result = await repo.moveToFolder(context, baseDocument.id, 'folder-2');

    expect(updateSpy).toHaveBeenCalledWith(context, baseDocument.id, { folderId: 'folder-2' });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.folderId).toBe('folder-2');
    }
  });
});
