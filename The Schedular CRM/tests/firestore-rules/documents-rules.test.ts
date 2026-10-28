/**
 * Firestore security rules tests for documents collections.
 *
 * Skipped by default; enable with TEST_DOCUMENT_RULES=true and point FIRESTORE_RULES_PATH
 * to the rules file that includes document paths.
 */

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import path from 'path';
import { beforeAll, afterAll, beforeEach, describe, it } from 'vitest';

const shouldRun = process.env.TEST_DOCUMENT_RULES === 'true';
const describeIf = shouldRun ? describe : describe.skip;
const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST || 'localhost:8080';
const [emulatorHostname, emulatorPortString] = emulatorHost.split(':');
const emulatorPort = emulatorPortString ? parseInt(emulatorPortString, 10) : 8080;
const rulesPath =
  process.env.FIRESTORE_RULES_PATH
    ? path.resolve(process.env.FIRESTORE_RULES_PATH)
    : path.resolve(process.cwd(), '..', 'The Scheduler', 'firestore.rules');

describeIf('documents security rules', () => {
  let testEnv: RulesTestEnvironment;

  const BUSINESS_1 = 'biz-doc-1';
  const BUSINESS_2 = 'biz-doc-2';
  const OWNER_ID = 'owner-doc';
  const OTHER_ID = 'other-doc';

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'crm-documents-rules-test',
      firestore: {
        rules: readFileSync(rulesPath, 'utf8'),
        host: emulatorHostname,
        port: emulatorPort,
      },
    });
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'users', OWNER_ID), { businessId: BUSINESS_1, role: 'owner', teamIds: ['team-a'] });
      await setDoc(doc(db, 'users', OTHER_ID), { businessId: BUSINESS_2, role: 'owner', teamIds: ['team-b'] });
      await setDoc(doc(db, `businesses/${BUSINESS_1}/documents/doc-1`), {
        businessId: BUSINESS_1,
        name: 'Test',
        documentType: 'contract',
        status: 'draft',
        fileName: 'test.pdf',
        fileType: 'application/pdf',
        fileSize: 100,
        storageUrl: `businesses/${BUSINESS_1}/documents/doc-1/original/test.pdf`,
        version: 1,
        isLatestVersion: true,
        uploadedById: OWNER_ID,
        ownerId: OWNER_ID,
        accessUserIds: [OWNER_ID],
        accessTeamIds: ['team-a'],
        isPublic: false,
        createdAt: new Date(),
      });
    });
  });

  it('allows owner to read own business document', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_ID);
    const db = ctx.firestore();
    await assertSucceeds(getDoc(doc(db, `businesses/${BUSINESS_1}/documents/doc-1`)));
  });

  it('blocks cross-business access to documents', async () => {
    const ctx = testEnv.authenticatedContext(OTHER_ID);
    const db = ctx.firestore();
    await assertFails(getDoc(doc(db, `businesses/${BUSINESS_1}/documents/doc-1`)));
  });
});
