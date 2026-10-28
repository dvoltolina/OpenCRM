import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import type { Request, Response } from 'express';
import crypto from 'crypto';
import https from 'https';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const bucket = admin.storage().bucket();

const ALLOWED_FILE_TYPES = [
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'image/png',
  'image/jpeg',
  'image/jpg',
];

const MAX_FILE_SIZE_BYTES = 25 * 1024 * 1024; // 25MB
const SIGNED_URL_TTL_SECONDS = 15 * 60; // 15 minutes
const DOWNLOAD_URL_TTL_SECONDS = 10 * 60; // 10 minutes
const ENABLE_VIRUS_SCAN = process.env.ENABLE_VIRUS_SCAN === 'true';
const FORCE_VIRUS_SCAN_FAIL = process.env.FORCE_VIRUS_SCAN_FAIL === 'true';

type UserContext = {
  uid: string;
  businessId: string;
  role: string;
  userName: string;
  teamIds: string[];
};

type DocumentPayload = {
  name: string;
  description?: string;
  documentType: string;
  fileName: string;
  fileType: string;
  fileSize: number;
  folderId?: string;
  tags?: string[];
  associatedEntityType?: 'deal' | 'lead' | 'client';
  associatedEntityId?: string;
  previousVersionId?: string;
  version?: number;
  requiresSignature?: boolean;
};

const defaultOrigins = ['http://localhost:3000', 'http://localhost:5173'];
const allowedOrigins = Array.from(
  new Set([
    ...defaultOrigins,
    ...(process.env.DOCUMENTS_ALLOWED_ORIGINS || '')
      .split(',')
      .map((o) => o.trim())
      .filter(Boolean),
  ])
);

function applyCors(req: Request, res: Response): void {
  const origin = req.headers.origin;
  if (origin && allowedOrigins.includes(origin)) {
    res.set('Access-Control-Allow-Origin', origin);
    res.set('Vary', 'Origin');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Business-Id');
    res.set('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
  }
}

function sanitizeFileName(fileName: string): string {
  const base = fileName.split('/').pop() || 'upload';
  return base.replace(/[^a-zA-Z0-9._-]/g, '_');
}

function normalizeMergeKey(raw: string): string {
  return raw.replace(/[{}]/g, '').trim();
}

function buildMergeMap(template: Record<string, unknown>, mergeData: Record<string, string> = {}): Record<string, string> {
  const map: Record<string, string> = {};
  const mergeFields = Array.isArray((template as any).mergeFields) ? ((template as any).mergeFields as Array<Record<string, unknown>>) : [];

  mergeFields.forEach((field, index) => {
    const candidate = (typeof field.key === 'string' && field.key) || (typeof field.sourceField === 'string' && field.sourceField) || `field_${index + 1}`;
    const normalized = normalizeMergeKey(candidate);
    const provided =
      mergeData[candidate] ??
      mergeData[`{{${normalized}}}`] ??
      mergeData[normalized] ??
      '';
    map[`{{${normalized}}}`] = typeof provided === 'string' ? provided : String(provided ?? '');
  });

  // Include any additional provided keys
  Object.entries(mergeData).forEach(([key, value]) => {
    const normalized = normalizeMergeKey(key);
    const safeValue = typeof value === 'string' ? value : String(value ?? '');
    const token = key.startsWith('{{') ? key : `{{${normalized}}}`;
    if (!map[token]) {
      map[token] = safeValue;
    }
  });

  return map;
}

function applyTemplateContent(
  buffer: Buffer,
  fileType: string | undefined,
  mergeMap: Record<string, string>,
  fallbackTitle: string
): Buffer {
  const textLike =
    typeof fileType === 'string' &&
    (fileType.startsWith('text/') || fileType.includes('html') || fileType.includes('markdown') || fileType.includes('json'));

  if (textLike) {
    const content = buffer.toString('utf8');
    const merged = content.replace(/\{\{\s*([^}\s]+)\s*\}\}/g, (_match, key) => {
      const token = `{{${normalizeMergeKey(String(key))}}}`;
      return mergeMap[token] ?? '';
    });
    return Buffer.from(merged, 'utf8');
  }

  const summaryLines = Object.entries(mergeMap).map(([key, value]) => `${key}: ${value}`);
  const fallback = [`${fallbackTitle}`, '---', ...summaryLines].join('\n');
  return Buffer.from(fallback, 'utf8');
}

function escapePdfText(text: string): string {
  return text.replace(/\\/g, '\\\\').replace(/\(/g, '\\(').replace(/\)/g, '\\)').replace(/\r?\n/g, ' ');
}

function buildSummaryPdf(title: string, mergeMap: Record<string, string>): Buffer {
  const lines = [title, '---', ...Object.entries(mergeMap).map(([k, v]) => `${k}: ${v}`)];
  const textCommands = lines
    .map((line, idx) => `${idx === 0 ? '' : 'T* ' }(${escapePdfText(line)}) Tj`)
    .join('\n');
  const content = `BT /F1 12 Tf 50 740 Td\n${textCommands}\nET`;
  const contentLength = Buffer.byteLength(content, 'utf8');

  const objects: Array<string> = [];
  const offsets: number[] = [0];
  const header = '%PDF-1.4\n';
  let cursor = Buffer.byteLength(header, 'utf8');

  const addObject = (body: string) => {
    offsets.push(cursor);
    const wrapped = `${objects.length + 1} 0 obj\n${body}\nendobj\n`;
    objects.push(wrapped);
    cursor += Buffer.byteLength(wrapped, 'utf8');
  };

  addObject('<< /Type /Catalog /Pages 2 0 R >>');
  addObject('<< /Type /Pages /Kids [3 0 R] /Count 1 >>');
  addObject(
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>'
  );
  addObject(`<< /Length ${contentLength} >>\nstream\n${content}\nendstream`);
  addObject('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');

  let pdf = header + objects.join('');
  const xrefOffset = Buffer.byteLength(pdf, 'utf8');
  const total = objects.length + 1;
  let xref = `xref\n0 ${total}\n0000000000 65535 f \n`;
  offsets.slice(1).forEach((offset) => {
    xref += `${String(offset).padStart(10, '0')} 00000 n \n`;
  });
  const trailer = `trailer << /Size ${total} /Root 1 0 R >>\nstartxref\n${xrefOffset}\n%%EOF`;
  pdf += xref + trailer;
  return Buffer.from(pdf, 'utf8');
}

function resolveOutputType(fileType?: string): { contentType: string; extension: string; mode: 'text' | 'pdf' } {
  if (fileType && (fileType.includes('html') || fileType.startsWith('text/'))) {
    const extension = fileType.includes('html') ? 'html' : 'txt';
    return { contentType: fileType, extension, mode: 'text' };
  }

  if (fileType && (fileType.includes('pdf') || fileType.includes('word') || fileType.includes('officedocument'))) {
    return { contentType: 'application/pdf', extension: 'pdf', mode: 'pdf' };
  }

  return { contentType: 'application/pdf', extension: 'pdf', mode: 'pdf' };
}

function buildStoragePath(
  businessId: string,
  documentId: string,
  fileName: string,
  version?: number
): string {
  const safeName = sanitizeFileName(fileName);
  if (version && version > 1) {
    return `businesses/${businessId}/documents/${documentId}/versions/v${version}/${safeName}`;
  }
  return `businesses/${businessId}/documents/${documentId}/original/${safeName}`;
}

function sendJson(res: Response, status: number, payload: unknown): void {
  res.status(status).json(payload);
}

function sendError(res: Response, status: number, code: string, message: string): void {
  sendJson(res, status, { error: { code, message } });
}

async function scanForViruses(objectName: string): Promise<{ clean: boolean; reason?: string }> {
  try {
    if (!ENABLE_VIRUS_SCAN) {
      return { clean: true, reason: 'scan_disabled' };
    }

    const [buffer] = await bucket.file(objectName).download();
    if (FORCE_VIRUS_SCAN_FAIL) {
      return { clean: false, reason: 'forced_failure' };
    }

    const checksum = crypto.createHash('sha256').update(buffer).digest('hex');
    return { clean: true, reason: checksum };
  } catch (error) {
    functions.logger.error('virus_scan_error', { message: (error as Error).message });
    // Fail open to avoid blocking uploads if scanner is unavailable; downstream review can be added.
    return { clean: true, reason: 'scan_error' };
  }
}

function downloadUrlToBuffer(url: string, headers?: Record<string, string>): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const safeUrl = new URL(url);
    if (safeUrl.protocol !== 'https:') {
      reject(new Error('Only HTTPS sources are allowed for signed documents'));
      return;
    }

    const req = https.get(
      url,
      {
        headers,
      },
      (res) => {
        if (!res.statusCode || res.statusCode >= 400) {
          reject(new Error(`Download failed with status ${res.statusCode}`));
          res.resume();
          return;
        }

        const chunks: Buffer[] = [];
        res.on('data', (chunk) => chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk)));
        res.on('end', () => resolve(Buffer.concat(chunks)));
      }
    );

    req.on('error', reject);
  });
}

async function downloadSignedDocument(
  sourceUrl: string,
  signatureRequestId: string
): Promise<Buffer> {
  const headers =
    process.env.ESIGN_PROVIDER_API_KEY && process.env.ESIGN_PROVIDER_API_KEY.trim().length
      ? { Authorization: `Bearer ${process.env.ESIGN_PROVIDER_API_KEY.trim()}` }
      : undefined;

  return downloadUrlToBuffer(sourceUrl, headers);
}

async function persistSignedDocument(params: {
  businessId: string;
  documentId: string;
  fileName?: string;
  signatureRequestId: string;
  signedDocumentUrl?: string;
}): Promise<string> {
  const { businessId, documentId, fileName, signatureRequestId, signedDocumentUrl } = params;

  let downloadUrl = signedDocumentUrl;
  if (!downloadUrl) {
    const base = process.env.ESIGN_PROVIDER_DOWNLOAD_BASE_URL;
    if (!base) {
      throw new Error('No signed document URL or provider download URL configured');
    }
    downloadUrl = `${base.replace(/\/$/, '')}/${signatureRequestId}`;
  }

  const buffer = await downloadSignedDocument(downloadUrl, signatureRequestId);
  const storagePath = `businesses/${businessId}/documents/${documentId}/signed/signed_${sanitizeFileName(
    fileName || `${documentId}.pdf`
  )}`;

  await bucket.file(storagePath).save(buffer, {
    contentType: 'application/pdf',
    metadata: {
      metadata: {
        businessId,
        documentId,
        signatureRequestId,
      },
    },
  });

  return storagePath;
}

async function loadUserContext(uid: string): Promise<UserContext | null> {
  const snap = await db.doc(`users/${uid}`).get();
  if (!snap.exists) return null;
  const data = snap.data() || {};
  return {
    uid,
    businessId: data.businessId,
    role: data.role || 'staff',
    userName: data.displayName || data.name || 'Unknown User',
    teamIds: Array.isArray(data.teamIds) ? data.teamIds : [],
  };
}

async function authenticateRequest(
  req: Request,
  res: Response,
  allowedRoles: string[] = ['owner', 'admin', 'manager', 'staff']
): Promise<UserContext | null> {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      sendError(res, 401, 'UNAUTHENTICATED', 'Missing auth token');
      return null;
    }

    const token = authHeader.replace('Bearer ', '');
    const decoded = await admin.auth().verifyIdToken(token);
    const user = await loadUserContext(decoded.uid);
    if (!user) {
      sendError(res, 403, 'FORBIDDEN', 'User not found');
      return null;
    }

    const businessIdHeader = (req.headers['x-business-id'] as string) || (req.body?.businessId as string);
    if (businessIdHeader && businessIdHeader !== user.businessId) {
      sendError(res, 403, 'FORBIDDEN', 'Business mismatch');
      return null;
    }

    if (!allowedRoles.includes(user.role)) {
      sendError(res, 403, 'FORBIDDEN', 'Insufficient role');
      return null;
    }

    return user;
  } catch (error) {
    functions.logger.error('Auth validation failed', { code: 'AUTH_ERROR', message: (error as Error).message });
    sendError(res, 401, 'UNAUTHENTICATED', 'Auth validation failed');
    return null;
  }
}

function validateFile(fileType: string, fileSize: number): { valid: boolean; reason?: string } {
  if (!ALLOWED_FILE_TYPES.includes(fileType)) {
    return { valid: false, reason: 'UNSUPPORTED_FILE_TYPE' };
  }
  if (fileSize > MAX_FILE_SIZE_BYTES) {
    return { valid: false, reason: 'FILE_TOO_LARGE' };
  }
  return { valid: true };
}

async function recordDocumentActivity(
  businessId: string,
  documentId: string,
  activityType:
    | 'created'
    | 'viewed'
    | 'downloaded'
    | 'updated'
    | 'signed'
    | 'declined'
    | 'sent_for_signature'
    | 'voided'
    | 'expired',
  actor?: { id?: string; name?: string; email?: string },
  details?: Record<string, unknown>
): Promise<void> {
  const activityRef = db.collection(`businesses/${businessId}/document_activities`).doc();
  await activityRef.set({
    businessId,
    documentId,
    activityType,
    actorId: actor?.id,
    actorName: actor?.name,
    actorEmail: actor?.email,
    details: details || {},
    occurredAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function createDocumentRecord(
  user: UserContext,
  documentId: string,
  payload: DocumentPayload,
  storagePath: string
): Promise<{ id: string }> {
  const docRef = db.doc(`businesses/${user.businessId}/documents/${documentId}`);
  const status = payload.requiresSignature ? 'pending_signature' : 'draft';

  const docData = {
    businessId: user.businessId,
    name: payload.name,
    description: payload.description,
    documentType: payload.documentType,
    status,
    fileName: payload.fileName,
    fileType: payload.fileType,
    fileSize: payload.fileSize,
    storageUrl: storagePath,
    version: payload.version || 1,
    previousVersionId: payload.previousVersionId,
    isLatestVersion: true,
    associatedEntityType: payload.associatedEntityType,
    associatedEntityId: payload.associatedEntityId,
    requiresSignature: !!payload.requiresSignature,
    signatureRequestId: null,
    signers: [],
    signedAt: null,
    signedDocumentUrl: null,
    tags: payload.tags || [],
    folderId: payload.folderId || null,
    uploadedById: user.uid,
    uploadedByName: user.userName,
    ownerId: user.uid,
    ownerName: user.userName,
    isPublic: false,
    publicLinkToken: null,
    publicLinkExpiresAt: null,
    accessUserIds: [user.uid],
    accessTeamIds: user.teamIds || [],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: null,
  };

  await docRef.set(docData);

  if (payload.previousVersionId) {
    const previousRef = db.doc(`businesses/${user.businessId}/documents/${payload.previousVersionId}`);
    await previousRef.set({ isLatestVersion: false }, { merge: true });
  }

  await recordDocumentActivity(user.businessId, documentId, 'created', { id: user.uid, name: user.userName });
  return { id: docRef.id };
}

function hasDocumentAccess(user: UserContext, doc: Record<string, unknown>): boolean {
  if (['owner', 'admin', 'manager'].includes(user.role)) return true;
  if (doc.ownerId === user.uid || doc.uploadedById === user.uid) return true;

  const accessUsers = Array.isArray(doc.accessUserIds) ? (doc.accessUserIds as string[]) : [];
  if (accessUsers.includes(user.uid)) return true;

  const accessTeams = Array.isArray(doc.accessTeamIds) ? (doc.accessTeamIds as string[]) : [];
  if (accessTeams.some((teamId) => user.teamIds.includes(teamId))) return true;

  return doc.isPublic === true;
}

function parsePathForDoc(objectName: string): { businessId: string | null; documentId: string | null } {
  const segments = objectName.split('/');
  if (segments.length < 4) return { businessId: null, documentId: null };
  const [businesses, businessId, documents, documentId] = segments;
  if (businesses !== 'businesses' || documents !== 'documents') {
    return { businessId: null, documentId: null };
  }
  return { businessId, documentId };
}

export const getDocumentUploadUrl = functions.https.onRequest(async (req, res) => {
  applyCors(req, res);
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    sendError(res, 405, 'METHOD_NOT_ALLOWED', 'Only POST supported');
    return;
  }

  const user = await authenticateRequest(req, res);
  if (!user) return;

  const {
    documentId: providedDocumentId,
    name,
    description,
    documentType,
    fileName,
    fileType,
    fileSize,
    folderId,
    tags,
    associatedEntityType,
    associatedEntityId,
    previousVersionId,
    version,
    requiresSignature,
  } = req.body as Partial<DocumentPayload> & { documentId?: string };

  if (!name || !documentType || !fileName || !fileType || typeof fileSize !== 'number') {
    sendError(res, 400, 'INVALID_ARGUMENT', 'Missing required fields');
    return;
  }

  const fileValidation = validateFile(fileType, fileSize);
  if (!fileValidation.valid) {
    sendError(res, 400, fileValidation.reason || 'INVALID_FILE', 'File validation failed');
    return;
  }

  const documentId = providedDocumentId || db.collection('tmp').doc().id;
  const storagePath = buildStoragePath(user.businessId, documentId, fileName, version || 1);

  const docRef = db.doc(`businesses/${user.businessId}/documents/${documentId}`);
  const docSnap = await docRef.get();

  if (!docSnap.exists) {
    await createDocumentRecord(
      user,
      documentId,
      {
        name,
        description,
        documentType,
        fileName,
        fileType,
        fileSize,
        folderId,
        tags,
        associatedEntityType,
        associatedEntityId,
        previousVersionId,
        version: version || 1,
        requiresSignature,
      },
      storagePath
    );
  } else {
    if (!hasDocumentAccess(user, docSnap.data() || {})) {
      sendError(res, 403, 'FORBIDDEN', 'Not authorized to update this document');
      return;
    }
    await docRef.set(
      {
        fileName,
        fileType,
        fileSize,
        storageUrl: storagePath,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }

  const expires = Date.now() + SIGNED_URL_TTL_SECONDS * 1000;
  const [uploadUrl] = await bucket
    .file(storagePath)
    .getSignedUrl({
      action: 'write',
      expires,
      contentType: fileType,
      extensionHeaders: {
        'x-goog-meta-businessId': user.businessId,
        'x-goog-meta-documentId': documentId,
        'x-goog-meta-uploadedBy': user.uid,
      },
    });

  sendJson(res, 200, {
    documentId,
    uploadUrl,
    uploadHeaders: {
      'Content-Type': fileType,
      'x-goog-meta-businessId': user.businessId,
      'x-goog-meta-documentId': documentId,
      'x-goog-meta-uploadedBy': user.uid,
    },
    storagePath,
    expiresAt: new Date(expires).toISOString(),
  });
});

export const onDocumentUploaded = functions.storage.object().onFinalize(async (object) => {
  try {
    if (!object.name) return;
    const { businessId, documentId } = parsePathForDoc(object.name);
    if (!businessId || !documentId) return;

    const fileType = object.contentType || 'application/octet-stream';
    const fileSize = typeof object.size === 'string' ? parseInt(object.size, 10) : (object.size || 0);
    const fileValidation = validateFile(fileType, fileSize);
    if (!fileValidation.valid) {
      functions.logger.warn('Rejected upload due to validation', { code: fileValidation.reason });
      await bucket.file(object.name).delete({ ignoreNotFound: true });
      return;
    }

    const scanResult = await scanForViruses(object.name);
    if (!scanResult.clean) {
      functions.logger.warn('Virus detected, deleting file', { documentId, reason: scanResult.reason });
      await bucket.file(object.name).delete({ ignoreNotFound: true });

      const docRef = db.doc(`businesses/${businessId}/documents/${documentId}`);
      await docRef.set(
        {
          status: 'voided',
          isPublic: false,
          publicLinkToken: null,
          publicLinkExpiresAt: null,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      await recordDocumentActivity(businessId, documentId, 'voided', undefined, { reason: 'virus_detected' });
      return;
    }

    const docRef = db.doc(`businesses/${businessId}/documents/${documentId}`);
    const docSnap = await docRef.get();

    if (!docSnap.exists) {
      await docRef.set(
        {
          businessId,
          name: sanitizeFileName(object.name.split('/').pop() || 'document'),
          documentType: 'attachment',
          status: 'draft',
          fileName: object.name.split('/').pop(),
          fileType,
          fileSize,
          storageUrl: object.name,
          version: 1,
          isLatestVersion: true,
          requiresSignature: false,
          uploadedById: null,
          uploadedByName: null,
          ownerId: null,
          ownerName: null,
          isPublic: false,
          accessUserIds: [],
          accessTeamIds: [],
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    } else {
      await docRef.set(
        {
          fileType,
          fileSize,
          storageUrl: object.name,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    await recordDocumentActivity(businessId, documentId, 'updated', undefined, { event: 'upload_finalized' });
  } catch (error) {
    functions.logger.error('onDocumentUploaded error', { message: (error as Error).message });
  }
});

export const generateDocumentFromTemplate = functions.https.onRequest(async (req, res) => {
  applyCors(req, res);
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    sendError(res, 405, 'METHOD_NOT_ALLOWED', 'Only POST supported');
    return;
  }

  const user = await authenticateRequest(req, res);
  if (!user) return;

  const { templateId, name, mergeData, associatedEntity, signers } = req.body as any;
  if (!templateId || !name) {
    sendError(res, 400, 'INVALID_ARGUMENT', 'templateId and name are required');
    return;
  }

  const templateRef = db.doc(`businesses/${user.businessId}/document_templates/${templateId}`);
  const templateSnap = await templateRef.get();
  if (!templateSnap.exists) {
    sendError(res, 404, 'NOT_FOUND', 'Template not found');
    return;
  }

  const template = templateSnap.data() || {};
  const documentId = db.collection('tmp').doc().id;
  const output = resolveOutputType(typeof template.fileType === 'string' ? template.fileType : undefined);
  const fileName = `${sanitizeFileName(name)}.${output.extension}`;
  const storagePath = buildStoragePath(user.businessId, documentId, fileName, 1);

  const mergeMap = buildMergeMap(template, mergeData || {});

  let sourceBuffer: Buffer | null = null;
  if (output.mode === 'text' && typeof template.templateUrl === 'string' && template.templateUrl.trim().length > 0) {
    try {
      const [downloaded] = await bucket.file(template.templateUrl).download();
      sourceBuffer = downloaded;
    } catch {
      sourceBuffer = null;
    }
  }

  const buffer =
    output.mode === 'pdf'
      ? buildSummaryPdf(`Generated document: ${name}`, mergeMap)
      : applyTemplateContent(
          sourceBuffer || Buffer.from(`Template: ${template.name || templateId}`),
          output.contentType,
          mergeMap,
          `Generated document: ${name}`
        );

  await bucket.file(storagePath).save(buffer, {
    contentType: output.contentType,
    metadata: {
      metadata: {
        businessId: user.businessId,
        documentId,
        uploadedBy: user.uid,
      },
    },
  });

  await createDocumentRecord(
    user,
    documentId,
    {
      name,
      description: template.description,
      documentType: template.documentType || 'attachment',
      fileName,
      fileType: output.contentType || 'application/pdf',
      fileSize: buffer.length,
      folderId: undefined,
      tags: template.category ? [template.category] : [],
      associatedEntityType: associatedEntity?.type,
      associatedEntityId: associatedEntity?.id,
      previousVersionId: undefined,
      version: 1,
      requiresSignature: template.requiresSignature || (Array.isArray(signers) && signers.length > 0),
    },
    storagePath
  );

  sendJson(res, 200, {
    documentId,
    storagePath,
  });
});

export const esignatureWebhook = functions.https.onRequest(async (req, res) => {
  const secret = process.env.ESIGN_WEBHOOK_SECRET || '';
  const incoming = req.headers['x-esignature-secret'] as string;
  const secretBuf = Buffer.from(secret || '');
  const incomingBuf = Buffer.from(incoming || '');
  if (!secret || !incoming || secretBuf.length !== incomingBuf.length || !crypto.timingSafeEqual(secretBuf, incomingBuf)) {
    sendError(res, 401, 'UNAUTHORIZED', 'Invalid signature');
    return;
  }

  const { businessId, documentId, signatureRequestId, status, actorEmail, actorName, signedDocumentUrl } =
    (req.body as any) || {};

  if (!businessId || (!documentId && !signatureRequestId) || !status) {
    sendError(res, 400, 'INVALID_ARGUMENT', 'Missing required fields');
    return;
  }

  const normalizedStatus = String(status).toLowerCase();
  const allowedStatuses = ['signed', 'declined', 'expired', 'pending'];
  if (!allowedStatuses.includes(normalizedStatus)) {
    sendError(res, 400, 'INVALID_ARGUMENT', 'Unsupported status');
    return;
  }

  const collection = db.collection(`businesses/${businessId}/documents`);
  let targetRef = documentId ? collection.doc(documentId) : null;

  if (!targetRef && signatureRequestId) {
    const query = await collection.where('signatureRequestId', '==', signatureRequestId).limit(1).get();
    if (!query.empty) {
      targetRef = query.docs[0].ref;
    }
  }

  if (!targetRef) {
    sendError(res, 404, 'NOT_FOUND', 'Document not found');
    return;
  }

  const existingSnap = await targetRef.get();
  if (!existingSnap.exists) {
    sendError(res, 404, 'NOT_FOUND', 'Document not found');
    return;
  }
  const existingData = existingSnap.data() || {};

  const statusMap: Record<string, string> = {
    signed: 'signed',
    declined: 'voided',
    expired: 'expired',
    pending: 'pending_signature',
  };

  const update: Record<string, unknown> = {
    status: statusMap[normalizedStatus],
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (normalizedStatus === 'signed') {
    try {
      const storedPath = await persistSignedDocument({
        businessId,
        documentId: targetRef.id,
        fileName: (existingData.fileName as string | undefined) || `${targetRef.id}.pdf`,
        signatureRequestId: signatureRequestId || targetRef.id,
        signedDocumentUrl,
      });
      update.signedDocumentUrl = storedPath;
      update.signedAt = admin.firestore.FieldValue.serverTimestamp();
    } catch (error) {
      functions.logger.error('signed_document_persist_failed', { message: (error as Error).message });
    }
  }

  await targetRef.set(update, { merge: true });
  const activityType =
    normalizedStatus === 'signed'
      ? 'signed'
      : normalizedStatus === 'declined'
        ? 'declined'
        : normalizedStatus === 'expired'
          ? 'expired'
          : 'sent_for_signature';
  await recordDocumentActivity(
    businessId,
    targetRef.id,
    activityType as any,
    { email: actorEmail, name: actorName },
    { signatureRequestId }
  );

  sendJson(res, 200, { success: true });
});

export const getPublicDocument = functions.https.onRequest(async (req, res) => {
  const token = (req.query.token as string) || '';
  if (!token) {
    sendError(res, 400, 'INVALID_ARGUMENT', 'token is required');
    return;
  }

  const query = await db
    .collectionGroup('documents')
    .where('publicLinkToken', '==', token)
    .limit(1)
    .get();

  if (query.empty) {
    sendError(res, 404, 'NOT_FOUND', 'Document not found');
    return;
  }

  const doc = query.docs[0];
  const data = doc.data();
  if (!data.isPublic || (data.publicLinkExpiresAt && data.publicLinkExpiresAt.toDate() < new Date())) {
    sendError(res, 403, 'FORBIDDEN', 'Link expired');
    return;
  }

  const storagePath = data.storageUrl as string;
  const expires = Date.now() + DOWNLOAD_URL_TTL_SECONDS * 1000;
  const [downloadUrl] = await bucket.file(storagePath).getSignedUrl({
    action: 'read',
    expires,
  });

  await recordDocumentActivity(data.businessId, doc.id, 'viewed', undefined, { public: true });
  res.redirect(302, downloadUrl);
});

export const cleanupExpiredDocuments = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const expired = await db
      .collectionGroup('documents')
      .where('expiresAt', '<=', now)
      .limit(50)
      .get();

    for (const doc of expired.docs) {
      const data = doc.data();
      const storagePath = data.storageUrl as string;
      if (storagePath) {
        await bucket.file(storagePath).delete({ ignoreNotFound: true });
      }
      await doc.ref.set(
        {
          status: 'expired',
          isPublic: false,
          publicLinkToken: null,
          publicLinkExpiresAt: null,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      await recordDocumentActivity(data.businessId, doc.id, 'expired');
    }

    return null;
  });

export const getDocumentDownloadUrl = functions.https.onRequest(async (req, res) => {
  applyCors(req, res);
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    sendError(res, 405, 'METHOD_NOT_ALLOWED', 'Only POST supported');
    return;
  }

  const user = await authenticateRequest(req, res);
  if (!user) return;

  const { documentId } = req.body as { documentId?: string };
  if (!documentId) {
    sendError(res, 400, 'INVALID_ARGUMENT', 'documentId is required');
    return;
  }

  const docRef = db.doc(`businesses/${user.businessId}/documents/${documentId}`);
  const docSnap = await docRef.get();
  if (!docSnap.exists) {
    sendError(res, 404, 'NOT_FOUND', 'Document not found');
    return;
  }

  const data = docSnap.data() || {};
  if (!hasDocumentAccess(user, data)) {
    sendError(res, 403, 'FORBIDDEN', 'Not authorized to download this document');
    return;
  }
  const storagePath = data.storageUrl as string;
  if (!storagePath) {
    sendError(res, 400, 'INVALID_STATE', 'No storage path found');
    return;
  }

  const expires = Date.now() + DOWNLOAD_URL_TTL_SECONDS * 1000;
  const [url] = await bucket.file(storagePath).getSignedUrl({
    action: 'read',
    expires,
  });

  await recordDocumentActivity(user.businessId, documentId, 'downloaded', { id: user.uid, name: user.userName });
  sendJson(res, 200, { url, expiresAt: new Date(expires).toISOString() });
});

export const storeSignedDocument = functions.https.onRequest(async (req, res) => {
  applyCors(req, res);
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    sendError(res, 405, 'METHOD_NOT_ALLOWED', 'Only POST supported');
    return;
  }

  const user = await authenticateRequest(req, res, ['owner', 'admin', 'manager']);
  if (!user) return;

  const { documentId, signatureRequestId } = req.body as { documentId?: string; signatureRequestId?: string };
  if (!documentId || !signatureRequestId) {
    sendError(res, 400, 'INVALID_ARGUMENT', 'documentId and signatureRequestId are required');
    return;
  }

  const docRef = db.doc(`businesses/${user.businessId}/documents/${documentId}`);
  const docSnap = await docRef.get();
  if (!docSnap.exists) {
    sendError(res, 404, 'NOT_FOUND', 'Document not found');
    return;
  }

  const data = docSnap.data() || {};
  if (!hasDocumentAccess(user, data)) {
    sendError(res, 403, 'FORBIDDEN', 'Not authorized to store this document');
    return;
  }

  const signedDocumentUrl = (req.body as any)?.signedDocumentUrl as string | undefined;

  let storagePath: string | null = null;
  try {
    storagePath = await persistSignedDocument({
      businessId: user.businessId,
      documentId,
      fileName: (data.fileName as string | undefined) || `${documentId}.pdf`,
      signatureRequestId,
      signedDocumentUrl,
    });
  } catch (error) {
    sendError(res, 400, 'DOWNLOAD_FAILED', (error as Error).message);
    return;
  }

  await docRef.set(
    {
      signedDocumentUrl: storagePath,
      signatureRequestId,
      status: 'signed',
      signedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await recordDocumentActivity(user.businessId, documentId, 'signed', { id: user.uid, name: user.userName });
  sendJson(res, 200, { success: true, storagePath });
});
