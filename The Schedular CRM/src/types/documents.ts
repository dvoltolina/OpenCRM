/**
 * Document Management Types
 * Schema contracts for documents, folders, templates, and e-signature participants.
 *
 * HIPAA: Document metadata may reference PHI; all records are scoped by businessId
 * and must be accessed through repository/service layers with SecurityContext.
 */

export type DocumentType =
  | 'proposal'
  | 'contract'
  | 'quote'
  | 'invoice'
  | 'agreement'
  | 'attachment'
  | 'other';

export type DocumentStatus =
  | 'draft'
  | 'pending_signature'
  | 'signed'
  | 'expired'
  | 'voided'
  | 'final';

export type SignatureStatus = 'pending' | 'signed' | 'declined' | 'expired';

export interface DocumentSigner {
  id: string;
  name: string;
  email: string;
  role: string; // e.g., 'client', 'sales', 'manager'
  order: number; // Signing order
  status: SignatureStatus;
  signedAt?: Date;
  declinedReason?: string;
}

export interface Document {
  id: string;
  businessId: string;

  // Basic info
  name: string;
  description?: string;
  documentType: DocumentType;
  status: DocumentStatus;

  // File info
  fileName: string;
  fileType: string; // MIME type
  fileSize: number;
  storageUrl: string; // Cloud Storage path

  // Versioning
  version: number;
  previousVersionId?: string;
  isLatestVersion: boolean;

  // Association
  associatedEntityType?: 'deal' | 'lead' | 'client';
  associatedEntityId?: string;

  // E-signature
  requiresSignature: boolean;
  signatureRequestId?: string; // From e-sign provider
  signers?: DocumentSigner[];
  signedAt?: Date;
  signedDocumentUrl?: string;

  // Metadata
  tags?: string[];
  folderId?: string;

  // Ownership
  uploadedById: string;
  uploadedByName: string;
  ownerId: string;
  ownerName: string;

  // Access
  isPublic: boolean; // Accessible via link
  publicLinkToken?: string;
  publicLinkExpiresAt?: Date;
  accessUserIds?: string[];
  accessTeamIds?: string[];

  createdAt: Date;
  updatedAt?: Date;
  expiresAt?: Date;
}

export interface DocumentFolder {
  id: string;
  businessId: string;
  name: string;
  parentFolderId?: string; // For nested folders
  color?: string;

  // Access
  ownerId: string;
  isShared: boolean;
  sharedWithUserIds?: string[];
  sharedWithTeamIds?: string[];

  createdAt: Date;
  updatedAt?: Date;
}

export interface DocumentMergeField {
  key: string; // e.g., {{client_name}}
  label: string;
  source: 'lead' | 'client' | 'deal' | 'business' | 'custom';
  sourceField?: string;
}

export interface SignaturePlacement {
  signerRole: string;
  page: number;
  x: number;
  y: number;
  width: number;
  height: number;
  type: 'signature' | 'initials' | 'date' | 'text';
}

export interface DocumentTemplate {
  id: string;
  businessId: string;
  name: string;
  description?: string;
  documentType: DocumentType;

  // Template file
  templateUrl: string;
  fileType: string;

  // Merge fields
  mergeFields: DocumentMergeField[];

  // Signature config
  requiresSignature: boolean;
  defaultSigners?: Omit<DocumentSigner, 'id' | 'status' | 'signedAt'>[];
  signaturePlacements?: SignaturePlacement[];

  // Metadata
  category: string;
  isActive: boolean;
  usageCount: number;

  createdById: string;
  createdAt: Date;
  updatedAt?: Date;
}

export interface DocumentActivity {
  id: string;
  businessId: string;
  documentId: string;

  activityType:
    | 'created'
    | 'viewed'
    | 'downloaded'
    | 'updated'
    | 'signed'
    | 'declined'
    | 'sent_for_signature'
    | 'voided'
    | 'expired';
  actorId?: string;
  actorName?: string;
  actorEmail?: string; // For external signers

  details?: Record<string, unknown>;

  occurredAt: Date;
  createdAt: Date;
  updatedAt?: Date;
}
