import { beforeEach, describe, expect, it, vi } from 'vitest';

import { postTenantEndpoint } from './firestoreBase';

vi.mock('../config/demo', () => ({
  isDemoMode: false,
  notifyDemoActionBlocked: vi.fn(),
}));

vi.mock('../config/env', () => ({
  firebaseEnv: {
    projectId: 'admin-project',
  },
}));

vi.mock('../lib/firebase', () => ({
  getDb: vi.fn(() => ({})),
  getFunctionsClient: vi.fn(() => ({})),
  getFirebaseAuth: vi.fn(() => ({
    currentUser: {
      getIdToken: vi.fn().mockResolvedValue('id-token'),
    },
  })),
}));

vi.mock('firebase/firestore', () => ({
  collection: vi.fn(),
  doc: vi.fn(),
  getDoc: vi.fn(),
  getDocs: vi.fn(),
  query: vi.fn(),
}));

vi.mock('firebase/functions', () => ({
  httpsCallable: vi.fn(),
}));

describe('postTenantEndpoint', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.unstubAllEnvs();
    vi.stubEnv('VITE_FUNCTIONS_BASE_URL', '');
  });

  it('falls back to the Firebase project functions host and sends tenant auth headers', async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({success: true}), {
        status: 200,
        headers: {'content-type': 'application/json'},
      }),
    );
    vi.stubGlobal('fetch', fetchMock);

    await postTenantEndpoint('/createPaymentIntent', 'biz-1', {amount: 100});

    expect(fetchMock).toHaveBeenCalledWith(
      'https://us-central1-admin-project.cloudfunctions.net/createPaymentIntent',
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({
          Authorization: 'Bearer id-token',
          'X-Business-Id': 'biz-1',
        }),
        body: JSON.stringify({businessId: 'biz-1', amount: 100}),
      }),
    );
  });

  it('uses the configured override host when present', async () => {
    vi.stubEnv('VITE_FUNCTIONS_BASE_URL', 'https://functions.example.test/');
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({success: true}), {
        status: 200,
        headers: {'content-type': 'application/json'},
      }),
    );
    vi.stubGlobal('fetch', fetchMock);

    await postTenantEndpoint('refundPayment', 'biz-2', {paymentIntentId: 'pi_123'});

    expect(fetchMock.mock.calls[0]?.[0]).toBe('https://functions.example.test/refundPayment');
  });
});
