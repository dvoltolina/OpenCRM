import { deleteDoc, doc, setDoc } from 'firebase/firestore';
import { deleteObject, getDownloadURL, ref, uploadBytes } from 'firebase/storage';

import type { FileAttachment } from '../types/models';
import { assertDemoMutationAllowed } from '../config/demo';
import { getDb, getStorageClient } from '../lib/firebase';
import { logAuditEvent } from './auditLog';
import { fetchCollection, fetchDoc, scopedCollection } from './firestoreBase';

function normalizeIsoTimestamp(value: unknown): string {
  if (typeof value === 'string') return value;
  if (value instanceof Date) return value.toISOString();
  if (
    value &&
    typeof value === 'object' &&
    'toDate' in value &&
    typeof (value as { toDate?: unknown }).toDate === 'function'
  ) {
    return ((value as { toDate: () => Date }).toDate()).toISOString();
  }
  return new Date().toISOString();
}

function normalizeFileAttachment(input: FileAttachment): FileAttachment {
  const name = input.name ?? input.fileName ?? 'Unnamed file';
  const contentType = input.contentType ?? input.fileType ?? 'application/octet-stream';
  const sizeBytes = input.sizeBytes ?? input.fileSize ?? 0;
  const uploaderId = input.uploaderId ?? input.uploadedBy ?? 'unknown';

  return {
    ...input,
    name,
    contentType,
    sizeBytes,
    uploaderId,
    uploadedAt: normalizeIsoTimestamp(input.uploadedAt),
    fileName: input.fileName ?? name,
    fileType: input.fileType ?? contentType,
    fileSize: input.fileSize ?? sizeBytes,
    uploadedBy: input.uploadedBy ?? uploaderId,
    storageUrl: input.storageUrl ?? input.downloadUrl,
  };
}

function sanitizeStorageMetadataValue(value: string): string {
  return value.replace(/[^\w.\-@]/g, '_').slice(0, 120);
}

export async function listFileAttachments(
  businessId: string,
  clientId: string,
  userId?: string,
): Promise<FileAttachment[]> {
  const scoped = scopedCollection<FileAttachment>(businessId, ['clients', clientId, 'files']);
  const rows = await fetchCollection(scoped);
  const attachments = rows
    .map(normalizeFileAttachment)
    .sort((a, b) => new Date(b.uploadedAt).getTime() - new Date(a.uploadedAt).getTime());

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiReadList',
    entityType: 'FileAttachment',
    entityId: clientId,
    metadata: { source: 'listFileAttachments', count: attachments.length },
  });

  return attachments;
}

export async function uploadFile(
  businessId: string,
  clientId: string,
  file: File,
  uploadedBy: string,
  notes?: string,
  userId?: string,
): Promise<FileAttachment> {
  assertDemoMutationAllowed('upload file');
  if (!businessId) {
    throw new Error('businessId is required to upload a client file.');
  }
  if (!clientId) {
    throw new Error('clientId is required to upload a client file.');
  }

  const uploaderId = uploadedBy?.trim() || userId?.trim() || 'unknown';
  const uploadedAt = new Date().toISOString();
  const db = getDb();
  const filesCollection = scopedCollection<FileAttachment>(businessId, ['clients', clientId, 'files'], db).ref;
  const attachmentRef = doc(filesCollection);
  const storagePath = `businesses/${businessId}/clients/${clientId}/files/${attachmentRef.id}`;
  const storageFileRef = ref(getStorageClient(), storagePath);

  const uploadResult = await uploadBytes(storageFileRef, file, {
    contentType: file.type || 'application/octet-stream',
    customMetadata: {
      businessId: sanitizeStorageMetadataValue(businessId),
      clientId: sanitizeStorageMetadataValue(clientId),
      uploaderId: sanitizeStorageMetadataValue(uploaderId),
      originalName: sanitizeStorageMetadataValue(file.name || 'unknown'),
    },
  });

  let downloadUrl: string | undefined;
  try {
    downloadUrl = await getDownloadURL(uploadResult.ref);
  } catch {
    downloadUrl = undefined;
  }

  const payload: FileAttachment = normalizeFileAttachment({
    id: attachmentRef.id,
    businessId,
    clientId,
    name: file.name,
    contentType: file.type || 'application/octet-stream',
    sizeBytes: file.size,
    storagePath,
    storageUrl: downloadUrl,
    downloadUrl,
    uploadedAt,
    uploaderId,
    accessLevel: 'staff',
    isSensitive: true,
    metadata: {
      uploadSource: 'admin-client-drawer',
    },
    category: 'clientDocument',
    notes,
    fileName: file.name,
    fileType: file.type || 'application/octet-stream',
    fileSize: file.size,
    uploadedBy: uploaderId,
  });

  try {
    await setDoc(attachmentRef, payload);
  } catch (error) {
    await deleteObject(storageFileRef).catch(() => undefined);
    throw error;
  }

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'FileAttachment',
    entityId: payload.id,
    metadata: {
      source: 'uploadFile',
      clientId,
      fileSize: file.size,
      fileType: payload.contentType,
    },
  });

  return payload;
}

export async function deleteFile(
  businessId: string,
  clientId: string,
  fileId: string,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('delete file');
  if (!businessId) {
    throw new Error('businessId is required to delete a client file.');
  }
  if (!clientId) {
    throw new Error('clientId is required to delete a client file.');
  }
  if (!fileId) {
    throw new Error('fileId is required to delete a client file.');
  }

  const db = getDb();
  const attachment = await fetchDoc<FileAttachment>(businessId, ['clients', clientId, 'files'], fileId, db);
  const storagePath = attachment?.storagePath?.trim() || `businesses/${businessId}/clients/${clientId}/files/${fileId}`;
  const storageFileRef = ref(getStorageClient(), storagePath);
  await deleteObject(storageFileRef).catch((error: { code?: string }) => {
    if (error?.code !== 'storage/object-not-found') {
      throw error;
    }
  });

  await deleteDoc(doc(db, 'businesses', businessId, 'clients', clientId, 'files', fileId));

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'FileAttachment',
    entityId: fileId,
    metadata: { source: 'deleteFile', clientId },
  });
}

export async function downloadFile(
  businessId: string,
  attachment: Pick<FileAttachment, 'id' | 'storagePath' | 'downloadUrl' | 'storageUrl'>,
  userId?: string,
): Promise<void> {
  let targetUrl = attachment.downloadUrl ?? attachment.storageUrl;
  if (!targetUrl && attachment.storagePath) {
    targetUrl = await getDownloadURL(ref(getStorageClient(), attachment.storagePath));
  }

  if (!targetUrl) {
    throw new Error('No downloadable URL is available for this file.');
  }

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'dataExport',
    entityType: 'FileAttachment',
    entityId: attachment.id,
    metadata: { source: 'downloadFile' },
  });
  window.open(targetUrl, '_blank', 'noopener,noreferrer');
}
