/**
 * E-Signature Service
 * Handles electronic signature capture, verification, and storage metadata
 *
 * E-Sign Migration Agent - MIGRATED TO REPOSITORY PATTERN
 *
 * SECURITY REQUIREMENTS:
 * - Never store actual signature images in plain text
 * - Store only metadata: signer info, timestamp, IP, verification
 * - Actual signature images should be encrypted and stored in secure storage
 * - All operations require SecurityContext for multi-tenant isolation
 *
 * HIPAA Compliance:
 * - Audit trail for all signature events (via repository)
 * - Verification codes for email confirmation
 * - IP address and user agent logging
 * - Immutable signature records
 * - Uses SignatureRepository for all data access (no direct Firestore)
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import type { SignatureMetadata } from '../types/templates';
import { getSignatureRepository } from '../data/repositories/signature-repository';

// ============================================
// Service Types
// ============================================

export interface CaptureSignatureOptions {
  // Signer information
  signerId: string;
  signerEmail: string;
  signerName: string;
  signerRole?: string;

  // Document reference
  documentId: string;
  documentType: 'template_instance' | 'deal_document' | 'client_document';
  fieldId?: string;

  // Security (optional)
  ipAddress?: string;
  userAgent?: string;

  // Verification (optional)
  verificationCode?: string;
  requireVerification?: boolean;

  // Storage reference for encrypted signature image
  signatureStoragePath?: string;
}

export interface VerifySignatureOptions {
  signatureId: string;
  verificationCode: string;
}

export interface SignatureServiceResult<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

// ============================================
// E-Signature Service
// ============================================

export class ESignService {
  private repository = getSignatureRepository();

  /**
   * Capture a signature (store metadata only)
   *
   * IMPORTANT: This method stores ONLY metadata.
   * The actual signature image must be:
   * 1. Encrypted before storage
   * 2. Stored in secure cloud storage (e.g., Firebase Storage with encryption)
   * 3. Referenced by signatureStoragePath
   */
  async captureSignature(
    context: SecurityContext,
    options: CaptureSignatureOptions
  ): Promise<SignatureServiceResult<SignatureMetadata>> {
    try {
      // Validate required fields
      const validation = this.validateSignatureMetadata(options);
      if (!validation.isValid) {
        return {
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: validation.error || 'Invalid signature data',
          },
        };
      }

      // Generate verification code if needed
      let verificationCode = options.verificationCode;
      if (options.requireVerification && !verificationCode) {
        verificationCode = this.generateVerificationCode();
      }

      // Create signature metadata
      const signatureMetadata: Omit<SignatureMetadata, 'id' | 'createdAt'> = {
        businessId: context.businessId,
        signerId: options.signerId,
        signerEmail: options.signerEmail,
        signerName: options.signerName,
        signerRole: options.signerRole,
        documentId: options.documentId,
        documentType: options.documentType,
        fieldId: options.fieldId,
        signedAt: new Date(),
        ipAddress: options.ipAddress,
        userAgent: options.userAgent,
        verificationCode,
        isVerified: !options.requireVerification, // If no verification required, mark as verified
        signatureStoragePath: options.signatureStoragePath,
      };

      // Use repository to create signature
      const result = await this.repository.create(context, signatureMetadata);

      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'CAPTURE_ERROR',
            message: result.error?.message || 'Failed to capture signature',
          },
        };
      }

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'CAPTURE_ERROR',
          message: error instanceof Error ? error.message : 'Failed to capture signature',
        },
      };
    }
  }

  /**
   * Verify a signature using verification code
   */
  async verifySignature(
    context: SecurityContext,
    options: VerifySignatureOptions
  ): Promise<SignatureServiceResult<SignatureMetadata>> {
    try {
      // Use repository verification method
      const result = await this.repository.verifySignature(
        context,
        options.signatureId,
        options.verificationCode
      );

      if (!result.success) {
        const errorCode = result.error?.message.includes('Invalid verification code')
          ? 'INVALID_CODE'
          : result.error?.message.includes('not found')
          ? 'NOT_FOUND'
          : 'VERIFY_ERROR';

        return {
          success: false,
          error: {
            code: errorCode,
            message: result.error?.message || 'Failed to verify signature',
          },
        };
      }

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'VERIFY_ERROR',
          message: error instanceof Error ? error.message : 'Failed to verify signature',
        },
      };
    }
  }

  /**
   * Get a signature by ID
   */
  async getSignature(
    context: SecurityContext,
    signatureId: string
  ): Promise<SignatureServiceResult<SignatureMetadata>> {
    try {
      const result = await this.repository.getById(context, signatureId);

      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: result.error?.message || 'Signature not found',
          },
        };
      }

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'GET_ERROR',
          message: error instanceof Error ? error.message : 'Failed to get signature',
        },
      };
    }
  }

  /**
   * Get all signatures for a document
   */
  async getDocumentSignatures(
    context: SecurityContext,
    documentId: string,
    options?: { includeUnverified?: boolean }
  ): Promise<SignatureServiceResult<SignatureMetadata[]>> {
    try {
      const result = await this.repository.getByDocument(context, documentId, options);

      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'GET_ERROR',
            message: result.error?.message || 'Failed to get document signatures',
          },
        };
      }

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'GET_ERROR',
          message: error instanceof Error ? error.message : 'Failed to get document signatures',
        },
      };
    }
  }

  /**
   * Get all signatures by a specific signer
   */
  async getSignerSignatures(
    context: SecurityContext,
    signerId: string
  ): Promise<SignatureServiceResult<SignatureMetadata[]>> {
    try {
      const result = await this.repository.getBySigner(context, signerId);

      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'GET_ERROR',
            message: result.error?.message || 'Failed to get signer signatures',
          },
        };
      }

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'GET_ERROR',
          message: error instanceof Error ? error.message : 'Failed to get signer signatures',
        },
      };
    }
  }

  /**
   * Check if a document has all required signatures
   */
  async isDocumentFullySigned(
    context: SecurityContext,
    documentId: string,
    requiredSignerIds: string[]
  ): Promise<SignatureServiceResult<boolean>> {
    try {
      const result = await this.repository.isDocumentFullySigned(
        context,
        documentId,
        requiredSignerIds
      );

      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'CHECK_ERROR',
            message: result.error?.message || 'Failed to check document signatures',
          },
        };
      }

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'CHECK_ERROR',
          message: error instanceof Error ? error.message : 'Failed to check document signatures',
        },
      };
    }
  }

  /**
   * Generate a verification code for email confirmation
   */
  generateVerificationCode(): string {
    // Generate a 6-digit verification code
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  /**
   * Validate signature metadata before storage
   */
  validateSignatureMetadata(options: CaptureSignatureOptions): { isValid: boolean; error?: string } {
    if (!options.signerId) {
      return { isValid: false, error: 'Signer ID is required' };
    }

    if (!options.signerEmail || !this.isValidEmail(options.signerEmail)) {
      return { isValid: false, error: 'Valid signer email is required' };
    }

    if (!options.signerName) {
      return { isValid: false, error: 'Signer name is required' };
    }

    if (!options.documentId) {
      return { isValid: false, error: 'Document ID is required' };
    }

    if (!options.documentType) {
      return { isValid: false, error: 'Document type is required' };
    }

    return { isValid: true };
  }

  /**
   * Validate email format
   */
  private isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }
}

// ============================================
// Singleton Instance
// ============================================

let eSignServiceInstance: ESignService | null = null;

export function getESignService(): ESignService {
  if (!eSignServiceInstance) {
    eSignServiceInstance = new ESignService();
  }
  return eSignServiceInstance;
}

// ============================================
// Helper Functions
// ============================================

/**
 * Generate a secure token for signature verification
 * This is more secure than a simple 6-digit code for high-security scenarios
 */
export function generateSecureVerificationToken(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let token = '';
  for (let i = 0; i < 32; i++) {
    token += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return token;
}

/**
 * Generate a signature audit summary
 * HIPAA: Does not include PHI in output
 */
export function generateSignatureAuditSummary(signature: SignatureMetadata): string {
  return [
    `Signature ID: ${signature.id}`,
    `Document: ${signature.documentType} - ${signature.documentId}`,
    `Signed at: ${signature.signedAt.toISOString()}`,
    signature.ipAddress ? `IP: ${signature.ipAddress}` : '',
    signature.isVerified ? 'Status: Verified' : 'Status: Pending Verification',
  ]
    .filter(Boolean)
    .join(' | ');
}
