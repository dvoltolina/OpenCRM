import { buildDemoDocuments } from './demo-data/build-documents';
import { BUSINESS_ID, DEMO_DRY_RUN, DEMO_PROJECT_ID } from './demo-data/common';

type BatchLike = {
  set(ref: unknown, data: Record<string, unknown>, options?: { merge?: boolean }): void;
  commit(): Promise<void>;
};

type FirestoreLike = {
  batch(): BatchLike;
  doc(path: string): unknown;
};

type AppModule = {
  initializeApp(options: { credential?: unknown; projectId?: string }): unknown;
  applicationDefault(): unknown;
};

type FirestoreModule = {
  getFirestore(): FirestoreLike;
};

async function importFirst<T>(paths: string[]): Promise<T> {
  let lastError: unknown;
  for (let index = 0; index < paths.length; index += 1) {
    try {
      return (await import(paths[index])) as T;
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError;
}

async function loadFirestore(): Promise<FirestoreLike> {
  const appModule = await importFirst<AppModule>([
    '../functions/node_modules/firebase-admin/lib/app/index.js',
    'firebase-admin/app',
  ]);
  const firestoreModule = await importFirst<FirestoreModule>([
    '../functions/node_modules/firebase-admin/lib/firestore/index.js',
    'firebase-admin/firestore',
  ]);
  appModule.initializeApp({
    credential: appModule.applicationDefault(),
    projectId: DEMO_PROJECT_ID || undefined,
  });
  return firestoreModule.getFirestore();
}

function summarizeDocuments(
  docs: Array<{ collection: string }>,
): Record<string, number> {
  const summary: Record<string, number> = {};
  docs.forEach((doc) => {
    summary[doc.collection] = (summary[doc.collection] || 0) + 1;
  });
  return summary;
}

async function writeDocuments(
  db: FirestoreLike,
  docs: Array<{ path: string; data: Record<string, unknown> }>,
): Promise<void> {
  const chunkSize = 400;
  for (let index = 0; index < docs.length; index += chunkSize) {
    const batch = db.batch();
    docs.slice(index, index + chunkSize).forEach((doc) => {
      batch.set(db.doc(doc.path), doc.data, { merge: true });
    });
    await batch.commit();
  }
}

async function main(): Promise<void> {
  const docs = buildDemoDocuments();
  const summary = summarizeDocuments(docs);

  console.log(
    'Prepared demo seed for business ' + BUSINESS_ID + ' with ' + docs.length + ' documents.',
  );
  Object.keys(summary)
    .sort()
    .forEach((collection) => {
      console.log('  ' + collection + ': ' + summary[collection]);
    });

  if (DEMO_DRY_RUN) {
    console.log('Dry run enabled. No Firestore writes were made.');
    return;
  }

  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.warn(
      'GOOGLE_APPLICATION_CREDENTIALS is not set. Export a demo service account path before writing data.',
    );
  }

  const db = await loadFirestore();
  await writeDocuments(db, docs);
  console.log(
    'Demo seed write complete for project ' +
      (DEMO_PROJECT_ID || '(application default project)') +
      '.',
  );
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error('Demo seed failed:', message);
  process.exitCode = 1;
});
