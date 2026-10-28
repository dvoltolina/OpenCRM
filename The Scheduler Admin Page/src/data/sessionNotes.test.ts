import { beforeEach, describe, expect, it, vi } from 'vitest';

import { doc, setDoc } from 'firebase/firestore';

import { logAuditEvent } from './auditLog';
import { callTenantFunction, scopedCollection } from './firestoreBase';
import {
  createSessionNoteFromPlaintext,
  decryptSessionNoteContent,
  encryptSessionNoteContent,
} from './sessionNotes';

vi.mock('../config/demo', () => ({
  assertDemoMutationAllowed: vi.fn(),
}));

vi.mock('../lib/firebase', () => ({
  getDb: vi.fn(() => ({ __db: true })),
}));

vi.mock('./auditLog', () => ({
  logAuditEvent: vi.fn(),
}));

vi.mock('./firestoreBase', () => ({
  callTenantFunction: vi.fn(),
  fetchCollection: vi.fn(),
  fetchDoc: vi.fn(),
  scopedCollection: vi.fn(),
}));

vi.mock('firebase/firestore', () => ({
  deleteDoc: vi.fn(),
  doc: vi.fn(),
  setDoc: vi.fn(),
  updateDoc: vi.fn(),
  where: vi.fn(),
}));

const mockCallTenantFunction = vi.mocked(callTenantFunction);
const mockScopedCollection = vi.mocked(scopedCollection);
const mockDoc = vi.mocked(doc);
const mockSetDoc = vi.mocked(setDoc);
const mockLogAuditEvent = vi.mocked(logAuditEvent);

describe('session note encryption integration', () => {
  beforeEach(() => {
    vi.resetAllMocks();
    mockScopedCollection.mockReturnValue({
      path: 'businesses/biz-1/session_notes',
      ref: 'session-notes-ref',
    } as any);
    mockDoc.mockReturnValue({ id: 'note-1' } as any);
  });

  it('retries encryption after initializing the business key when missing', async () => {
    mockCallTenantFunction
      .mockRejectedValueOnce({
        code: 'functions/not-found',
        message: 'Encryption key not initialized',
      })
      .mockResolvedValueOnce({ success: true } as any)
      .mockResolvedValueOnce({ ciphertext: 'ciphertext-1' } as any);

    const ciphertext = await encryptSessionNoteContent('biz-1', 'Clinical note');

    expect(ciphertext).toBe('ciphertext-1');
    expect(mockCallTenantFunction).toHaveBeenNthCalledWith(
      1,
      'encryptData',
      'biz-1',
      expect.objectContaining({ plaintext: expect.any(String) }),
    );
    expect(mockCallTenantFunction).toHaveBeenNthCalledWith(
      2,
      'initializeEncryptionKey',
      'biz-1',
      {},
    );
  });

  it('decrypts UTF-8 note content returned by the shared callable', async () => {
    const plaintext = 'Progress note with unicode: cafe and accent';
    const encoded = btoa(String.fromCharCode(...new TextEncoder().encode(plaintext)));
    mockCallTenantFunction.mockResolvedValue({ plaintext: encoded } as any);

    const decrypted = await decryptSessionNoteContent('biz-1', 'cipher-1');

    expect(decrypted).toBe(plaintext);
    expect(mockCallTenantFunction).toHaveBeenCalledWith('decryptData', 'biz-1', {
      ciphertext: 'cipher-1',
    });
  });

  it('stores encrypted content when creating a note from plaintext', async () => {
    mockCallTenantFunction.mockResolvedValue({ ciphertext: 'cipher-1' } as any);

    const note = await createSessionNoteFromPlaintext(
      'biz-1',
      {
        clientId: 'client-1',
        plaintextContent: 'Treatment summary',
        title: 'Follow-up',
      },
      {
        role: 'provider',
        providerId: 'provider-1',
        userId: 'user-1',
        userDisplayName: 'Provider One',
      },
    );

    expect(mockSetDoc).toHaveBeenCalledWith(
      { id: 'note-1' },
      expect.objectContaining({
        id: 'note-1',
        businessId: 'biz-1',
        clientId: 'client-1',
        providerId: 'provider-1',
        title: 'Follow-up',
        encryptedContent: 'cipher-1',
      }),
    );
    expect(note.encryptedContent).toBe('cipher-1');
    expect(mockLogAuditEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        businessId: 'biz-1',
        actionType: 'phiWrite',
      }),
    );
  });
});
