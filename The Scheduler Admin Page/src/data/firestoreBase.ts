import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  type CollectionReference,
  type DocumentReference,
  type Firestore,
  type Query,
  type QueryConstraint,
} from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';

import {
  isDemoMode,
  notifyDemoActionBlocked,
} from '../config/demo';
import { firebaseEnv } from '../config/env';
import { getDb, getFirebaseAuth, getFunctionsClient } from '../lib/firebase';

export type ScopedCollection<T> = {
  path: string;
  ref: CollectionReference<T>;
};

export type ScopedDocument<T> = {
  path: string;
  ref: DocumentReference<T>;
};

export type TenantFunctionOptions<TResult> = {
  fallbackValue?: TResult;
  demoBehavior?: 'block' | 'fallback';
};

export type TenantHttpOptions<TResult> = {
  fallbackValue?: TResult;
  demoBehavior?: 'block' | 'fallback';
};

function getViteEnvValue(key: string): string | undefined {
  const env = (import.meta as ImportMeta & {
    env?: Record<string, string | boolean | undefined>;
  }).env;
  const value = env?.[key];
  if (typeof value === 'string' && value.length > 0) {
    return value;
  }

  if (typeof process !== 'undefined') {
    const processValue = process.env?.[key];
    if (typeof processValue === 'string' && processValue.length > 0) {
      return processValue;
    }
  }

  return undefined;
}

function tenantPath(businessId: string, segments: string[]): string {
  return ['businesses', businessId, ...segments].join('/');
}

export function scopedCollection<T>(
  businessId: string,
  segments: string[],
  db?: Firestore,
): ScopedCollection<T> {
  const database = db ?? getDb();
  const path = tenantPath(businessId, segments);
  const ref = collection(database, path) as CollectionReference<T>;
  return { path, ref };
}

export function scopedDoc<T>(
  businessId: string,
  segments: string[],
  id: string,
  db?: Firestore,
): ScopedDocument<T> {
  const database = db ?? getDb();
  const path = tenantPath(businessId, [...segments, id]);
  const ref = doc(database, path) as DocumentReference<T>;
  return { path, ref };
}

export async function fetchDoc<T>(
  businessId: string,
  segments: string[],
  id: string,
  db?: Firestore,
): Promise<T | null> {
  const docRef = scopedDoc<T>(businessId, segments, id, db).ref;
  const snap = await getDoc(docRef);
  return snap.exists() ? (snap.data() as T) : null;
}

export async function fetchCollection<T>(
  scoped: ScopedCollection<T>,
  constraints: QueryConstraint[] = [],
): Promise<T[]> {
  const q = constraints.length
    ? (query(scoped.ref, ...constraints) as Query<T>)
    : (scoped.ref as Query<T>);
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...d.data() } as T));
}

export async function callTenantFunction<
  TPayload extends Record<string, unknown> = Record<string, unknown>,
  TResult = void,
>(
  functionName: string,
  businessId: string,
  payload: TPayload = {} as TPayload,
  options: TenantFunctionOptions<TResult> = {},
): Promise<TResult> {
  const finalPayload = { businessId, ...payload };

  if (isDemoMode) {
    if (options.demoBehavior === 'fallback') {
      return (options.fallbackValue ?? ({} as TResult));
    }
    throw notifyDemoActionBlocked({ action: functionName });
  }

  try {
    const callable = httpsCallable<typeof finalPayload, TResult>(
      getFunctionsClient(),
      functionName,
    );
    const result = await callable(finalPayload);
    return result.data;
  } catch (error) {
    console.error(`callTenantFunction(${functionName}) failed`);
    throw error;
  }
}

function getFunctionsHttpBaseUrl(): string {
  const configured = getViteEnvValue('VITE_FUNCTIONS_BASE_URL')?.trim();
  if (configured) {
    return configured.replace(/\/+$/, '');
  }

  const projectId = firebaseEnv.projectId?.trim();
  if (!projectId) {
    throw new Error('Firebase projectId is required to resolve the Functions host.');
  }

  return `https://us-central1-${projectId}.cloudfunctions.net`;
}

export async function postTenantEndpoint<
  TPayload extends Record<string, unknown> = Record<string, unknown>,
  TResult = void,
>(
  endpointPath: string,
  businessId: string,
  payload: TPayload = {} as TPayload,
  options: TenantHttpOptions<TResult> = {},
): Promise<TResult> {
  const finalPayload = { businessId, ...payload };

  if (isDemoMode) {
    if (options.demoBehavior === 'fallback') {
      return (options.fallbackValue ?? ({} as TResult));
    }
    throw notifyDemoActionBlocked({ action: endpointPath });
  }

  const currentUser = getFirebaseAuth().currentUser;
  if (!currentUser) {
    throw new Error('Authentication required.');
  }

  const idToken = await currentUser.getIdToken();
  const normalizedPath = endpointPath.startsWith('/') ? endpointPath : `/${endpointPath}`;
  const response = await fetch(`${getFunctionsHttpBaseUrl()}${normalizedPath}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
      'X-Business-Id': businessId,
    },
    body: JSON.stringify(finalPayload),
  });

  const contentType = (response.headers.get('content-type') || '').toLowerCase();
  const isJsonResponse = contentType.includes('application/json');
  const isTextResponse =
    contentType.startsWith('text/') ||
    contentType.includes('csv') ||
    contentType.includes('xml') ||
    contentType.includes('javascript');

  const payloadData: unknown = isJsonResponse
    ? await response.json().catch(() => ({}))
    : isTextResponse
      ? await response.text().catch(() => '')
      : await response.blob().catch(() => new Blob());

  if (!response.ok) {
    let message = 'Request failed.';

    if (typeof payloadData === 'string' && payloadData.trim().length) {
      message = payloadData;
    } else if (
      payloadData &&
      typeof payloadData === 'object' &&
      'error' in payloadData &&
      typeof payloadData.error === 'string'
    ) {
      message = payloadData.error;
    } else if (payloadData instanceof Blob && payloadData.size > 0) {
      const blobText = await payloadData.text().catch(() => '');
      if (blobText.trim().length) {
        message = blobText;
      }
    }

    throw new Error(message);
  }

  return payloadData as TResult;
}
