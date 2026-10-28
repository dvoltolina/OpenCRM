/**
 * Signature Repository
 * Firestore data access for electronic signature metadata
 *
 * E-Sign Migration Agent Implementation
 * HIPAA Compliance: Signature operations with comprehensive audit logging
 *
 * Storage Path: businesses/{businessId}/signatures/{signatureId}
 * Indexes: documentId, signerId, signedAt (desc)
 *
 * SECURITY REQUIREMENTS:
 * - All operations require SecurityContext validation
 * - Signatures are IMMUTABLE once created (no updates allowed)
 * - Audit logging for ALL signature operations (legal requirement)
 * - NO PHI in audit logs (use IDs only, not emails/names)
 * - Tenant isolation enforced via businessId
 */

import type { WhereFilterOp } from 'firebase/firestore';
import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  ValidationResult,
  Validator,
} from './repository-types';
import {
  ValidationError,
  failedResult,
  successResult,
  InvalidArgumentError,
} from '../errors/repository-errors';
import type { SignatureMetadata } from '../../types/templates';

// ============================================
// Validator
// ============================================

/**
 * Validate signature metadata
 * HIPAA: Email validation is critical as it's PHI
 */
export function validateSignatureMetadata(data: Partial<SignatureMetadata>): ValidationResult {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  // Required fields validation
  if (data.signerId !== undefined && !data.signerId?.trim()) {
    errors.push({
      field: 'signerId',
      message: 'Signer ID is required',
      code: 'REQUIRED',
    });
  }

  if (data.signerEmail !== undefined) {
    if (!data.signerEmail?.trim()) {
      errors.push({
        field: 'signerEmail',
        message: 'Signer email is required',
        code: 'REQUIRED',
      });
    } else if (!isValidEmail(data.signerEmail)) {
      errors.push({
        field: 'signerEmail',
        message: 'Invalid email format',
        code: 'INVALID_FORMAT',
      });
    }
  }

  if (data.signerName !== undefined && !data.signerName?.trim()) {
    errors.push({
      field: 'signerName',
      message: 'Signer name is required',
      code: 'REQUIRED',
    });
  }

  if (data.documentId !== undefined && !data.documentId?.trim()) {
    errors.push({
      field: 'documentId',
      message: 'Document ID is required',
      code: 'REQUIRED',
    });
  }

  if (data.documentType !== undefined) {
    const validTypes = ['template_instance', 'deal_document', 'client_document'];
    if (!validTypes.includes(data.documentType)) {
      errors.push({
        field: 'documentType',
        message: 'Invalid document type',
        code: 'INVALID_VALUE',
      });
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

/**
 * Validate email format
 */
function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

// ============================================
// Signature Repository Class
// ============================================

/**
 * SignatureRepository
 * Provides CRUD operations and query methods for electronic signatures
 *
 * IMPORTANT: Signatures are IMMUTABLE after creation
 * - Updates are blocked except for verification status
 * - This ensures legal integrity of signed documents
 */
export class SignatureRepository extends BaseRepository<SignatureMetadata> {
  constructor() {
    super({
      collectionName: 'signatures',
      softDelete: false, // Hard delete only (signatures should rarely be deleted)
    });
    this.setValidator(validateSignatureMetadata as Validator<SignatureMetadata>);
  }

  // ============================================
  // Create Override (with audit logging)
  // ============================================

  /**
   * Create a new signature metadata entry
   * HIPAA: Logs signature creation with IDs only (no PHI)
   */
  async create(
    context: SecurityContext,
    data: Omit<SignatureMetadata, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<SignatureMetadata>> {
    // Ensure required fields
    const signatureData = {
      ...data,
      businessId: context.businessId,
      signedAt: data.signedAt || new Date(),
      isVerified: data.isVerified ?? false,
    };

    // Create signature using base repository
    const result = await super.create(context, signatureData, customId);

    if (result.success) {
      // HIPAA: Audit log WITHOUT PHI (no email, no name)
      await this.logAudit(context, 'create', result.data.id, {
        documentId: result.data.documentId,
        documentType: result.data.documentType,
        signerId: result.data.signerId,
        isVerified: result.data.isVerified,
      });
    }

    return result;
  }

  // ============================================
  // Verification Methods
  // ============================================

  /**
   * Verify a signature using verification code
   * This is the ONLY allowed update operation
   */
  async verifySignature(
    context: SecurityContext,
    signatureId: string,
    verificationCode: string
  ): Promise<RepositoryResult<SignatureMetadata>> {
    try {
      this.ensureSecurityContext(context);

      // Get existing signature
      const existing = await this.getById(context, signatureId);
      if (!existing.success || !existing.data) {
        return failedResult(new InvalidArgumentError('Signature not found'));
      }

      const signature = existing.data;

      // Check if already verified
      if (signature.isVerified) {
        return successResult(signature);
      }

      // Verify code
      if (signature.verificationCode !== verificationCode) {
        await this.logAudit(context, 'update', signatureId, {
          action: 'verification_failed',
          reason: 'invalid_code',
        });
        return failedResult(new ValidationError('Invalid verification code', []));
      }

      // Update verification status using base update
      const updateResult = await super.update(context, signatureId, {
        isVerified: true,
      });

      if (updateResult.success) {
        await this.logAudit(context, 'update', signatureId, {
          action: 'verified',
          documentId: signature.documentId,
        });
      }

      return updateResult;
    } catch (error) {
      return failedResult(error, 'Failed to verify signature');
    }
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * Get all signatures for a specific document
   * Ordered by most recent first
   */
  async getByDocument(
    context: SecurityContext,
    documentId: string,
    options?: { includeUnverified?: boolean }
  ): Promise<RepositoryResult<SignatureMetadata[]>> {
    const whereClause: Array<{ field: string; operator: WhereFilterOp; value: unknown }> = [
      { field: 'documentId', operator: '==', value: documentId },
    ];

    // By default, only return verified signatures
    if (!options?.includeUnverified) {
      whereClause.push({ field: 'isVerified', operator: '==', value: true });
    }

    const result = await this.getAll(context, {
      where: whereClause,
      orderBy: { field: 'signedAt', direction: 'desc' },
    });

    if (!result.success) {
      return failedResult(result.error);
    }

    // HIPAA: Audit read operation (log document ID only)
    await this.logAudit(context, 'read', null, {
      action: 'get_by_document',
      documentId,
      count: result.data.data.length,
    });

    return successResult(result.data.data);
  }

  /**
   * Get all signatures by a specific signer
   */
  async getBySigner(
    context: SecurityContext,
    signerId: string,
    limit: number = 50
  ): Promise<RepositoryResult<SignatureMetadata[]>> {
    const result = await this.getAll(context, {
      where: [{ field: 'signerId', operator: '==', value: signerId }],
      orderBy: { field: 'signedAt', direction: 'desc' },
      limit,
    });

    if (!result.success) {
      return failedResult(result.error);
    }

    // HIPAA: Audit read operation (log signer ID only)
    await this.logAudit(context, 'read', null, {
      action: 'get_by_signer',
      signerId,
      count: result.data.data.length,
    });

    return successResult(result.data.data);
  }

  /**
   * Check if a document is fully signed
   * Returns true if all required signers have verified signatures
   */
  async isDocumentFullySigned(
    context: SecurityContext,
    documentId: string,
    requiredSignerIds: string[]
  ): Promise<RepositoryResult<boolean>> {
    try {
      this.ensureSecurityContext(context);

      if (!requiredSignerIds || requiredSignerIds.length === 0) {
        return successResult(false);
      }

      // Get all verified signatures for this document
      const signaturesResult = await this.getByDocument(context, documentId, {
        includeUnverified: false,
      });

      if (!signaturesResult.success) {
        return failedResult(signaturesResult.error);
      }

      const signatures = signaturesResult.data;

      // Create set of verified signer IDs
      const verifiedSignerIds = new Set(signatures.map((s) => s.signerId));

      // Check if all required signers have signed
      const allSigned = requiredSignerIds.every((id) => verifiedSignerIds.has(id));

      // HIPAA: Audit check operation
      await this.logAudit(context, 'read', null, {
        action: 'check_fully_signed',
        documentId,
        requiredCount: requiredSignerIds.length,
        verifiedCount: verifiedSignerIds.size,
        allSigned,
      });

      return successResult(allSigned);
    } catch (error) {
      return failedResult(error, 'Failed to check document signature status');
    }
  }

  /**
   * Get signatures for a specific field in a document
   */
  async getByDocumentField(
    context: SecurityContext,
    documentId: string,
    fieldId: string
  ): Promise<RepositoryResult<SignatureMetadata[]>> {
    const result = await this.getAll(context, {
      where: [
        { field: 'documentId', operator: '==', value: documentId },
        { field: 'fieldId', operator: '==', value: fieldId },
        { field: 'isVerified', operator: '==', value: true },
      ],
      orderBy: { field: 'signedAt', direction: 'desc' },
    });

    if (!result.success) {
      return failedResult(result.error);
    }

    return successResult(result.data.data);
  }

  // ============================================
  // Override: Block Updates (Immutability)
  // ============================================

  /**
   * Override update to prevent modification of signature metadata
   * Signatures are IMMUTABLE per legal requirements
   * Use verifySignature() for verification updates
   */
  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<SignatureMetadata, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<SignatureMetadata>> {
    // Only allow verification status updates through verifySignature method
    if (Object.keys(data).length === 1 && 'isVerified' in data) {
      return super.update(context, id, data);
    }

    // Block all other updates
    return failedResult(
      new ValidationError('Signatures are immutable and cannot be updated', [
        {
          field: 'signature',
          message: 'Use verifySignature() to verify signatures',
        },
      ])
    );
  }

  // ============================================
  // Delete Override (with audit)
  // ============================================

  /**
   * Delete a signature (rare - usually for cleanup or errors)
   * HIPAA: Logs deletion without PHI
   */
  async delete(context: SecurityContext, id: string): Promise<RepositoryResult<void>> {
    // Get signature details for audit log
    const existing = await this.getById(context, id);

    const result = await super.delete(context, id);

    if (result.success && existing.success) {
      await this.logAudit(context, 'delete', id, {
        documentId: existing.data.documentId,
        signerId: existing.data.signerId,
      });
    }

    return result;
  }
}

// ============================================
// Singleton Instance Factory
// ============================================

let signatureRepositoryInstance: SignatureRepository | null = null;

export function getSignatureRepository(): SignatureRepository {
  if (!signatureRepositoryInstance) {
    signatureRepositoryInstance = new SignatureRepository();
  }
  return signatureRepositoryInstance;
}
