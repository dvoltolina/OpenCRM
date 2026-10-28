/**
 * Token Encryption Service
 * Provides secure encryption/decryption for OAuth tokens and other sensitive data
 *
 * HIPAA Compliance:
 * - Uses AES-256-GCM (NIST approved authenticated encryption)
 * - Supports envelope encryption with KEK/DEK pattern
 * - Key rotation support via key versioning
 * - No sensitive data in logs or errors
 *
 * Security:
 * - 256-bit AES encryption with GCM mode (authenticated)
 * - Random IV for each encryption operation
 * - HMAC authentication tag prevents tampering
 * - Supports Google Cloud KMS for production key management
 *
 * Usage:
 * - Development: Set TOKEN_ENCRYPTION_KEY environment variable (32 bytes, hex encoded)
 * - Production: Set GOOGLE_CLOUD_KMS_KEY_NAME for Cloud KMS integration
 */

import crypto from 'crypto';

// ============================================
// Types
// ============================================

/**
 * Encrypted token format
 * Contains all data needed for decryption
 */
interface EncryptedToken {
  /** Encryption algorithm used */
  algorithm: 'aes-256-gcm';
  /** Key version for rotation support */
  keyVersion: number;
  /** Initialization vector (base64) */
  iv: string;
  /** Authentication tag (base64) */
  authTag: string;
  /** Encrypted data (base64) */
  ciphertext: string;
}

/**
 * Encryption configuration
 */
interface EncryptionConfig {
  /** Current key version */
  keyVersion: number;
  /** Whether to use Cloud KMS (vs local key) */
  useCloudKms: boolean;
  /** Cloud KMS key name (if using KMS) */
  kmsKeyName?: string;
}

// ============================================
// Constants
// ============================================

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 16; // 128 bits
const AUTH_TAG_LENGTH = 16; // 128 bits
const KEY_LENGTH = 32; // 256 bits

// ============================================
// Token Encryption Service
// ============================================

export class TokenEncryptionService {
  private config: EncryptionConfig;
  private encryptionKey: Buffer | null = null;
  private initialized = false;

  constructor() {
    this.config = {
      keyVersion: 1,
      useCloudKms: !!process.env.GOOGLE_CLOUD_KMS_KEY_NAME,
      kmsKeyName: process.env.GOOGLE_CLOUD_KMS_KEY_NAME,
    };
  }

  /**
   * Initialize the encryption service
   * Must be called before encrypt/decrypt operations
   */
  async initialize(): Promise<void> {
    if (this.initialized) return;

    if (this.config.useCloudKms) {
      // Cloud KMS mode - key is managed by Google Cloud
      // We'll use envelope encryption: KMS encrypts/decrypts DEKs
      this.initialized = true;
    } else {
      // Local key mode - load from environment variable
      const keyHex = process.env.TOKEN_ENCRYPTION_KEY;

      if (!keyHex) {
        throw new Error(
          'TOKEN_ENCRYPTION_KEY environment variable is required. ' +
            'Generate with: node -e "console.log(require(\'crypto\').randomBytes(32).toString(\'hex\'))"'
        );
      }

      // Validate key format
      if (!/^[0-9a-fA-F]{64}$/.test(keyHex)) {
        throw new Error('TOKEN_ENCRYPTION_KEY must be 64 hex characters (32 bytes)');
      }

      this.encryptionKey = Buffer.from(keyHex, 'hex');
      this.initialized = true;
    }
  }

  /**
   * Encrypt a token or sensitive string
   *
   * @param plaintext The token to encrypt
   * @returns Encrypted token as JSON string (safe for storage)
   */
  async encrypt(plaintext: string): Promise<string> {
    await this.ensureInitialized();

    if (!plaintext) {
      throw new Error('Cannot encrypt empty value');
    }

    if (this.config.useCloudKms) {
      return this.encryptWithKms(plaintext);
    }

    return this.encryptWithLocalKey(plaintext);
  }

  /**
   * Decrypt an encrypted token
   *
   * @param encryptedData The encrypted token (JSON string from encrypt())
   * @returns Decrypted plaintext
   */
  async decrypt(encryptedData: string): Promise<string> {
    await this.ensureInitialized();

    if (!encryptedData) {
      throw new Error('Cannot decrypt empty value');
    }

    // Parse the encrypted token structure
    let parsed: EncryptedToken;
    try {
      parsed = JSON.parse(encryptedData);
    } catch {
      throw new Error('Invalid encrypted token format');
    }

    // Validate structure
    if (
      parsed.algorithm !== ALGORITHM ||
      !parsed.iv ||
      !parsed.authTag ||
      !parsed.ciphertext
    ) {
      throw new Error('Invalid encrypted token structure');
    }

    if (this.config.useCloudKms) {
      return this.decryptWithKms(parsed);
    }

    return this.decryptWithLocalKey(parsed);
  }

  /**
   * Rotate encryption key
   * Re-encrypts a token with the current key version
   *
   * @param encryptedData Previously encrypted token
   * @returns Re-encrypted token with current key
   */
  async rotate(encryptedData: string): Promise<string> {
    // Decrypt with old key
    const plaintext = await this.decrypt(encryptedData);
    // Re-encrypt with current key
    return this.encrypt(plaintext);
  }

  /**
   * Check if a token needs rotation
   *
   * @param encryptedData Encrypted token to check
   * @returns True if token was encrypted with older key version
   */
  needsRotation(encryptedData: string): boolean {
    try {
      const parsed: EncryptedToken = JSON.parse(encryptedData);
      return parsed.keyVersion < this.config.keyVersion;
    } catch {
      return false;
    }
  }

  // ============================================
  // Private Methods - Local Key Encryption
  // ============================================

  private async encryptWithLocalKey(plaintext: string): Promise<string> {
    if (!this.encryptionKey) {
      throw new Error('Encryption key not initialized');
    }

    // Generate random IV for this encryption
    const iv = crypto.randomBytes(IV_LENGTH);

    // Create cipher
    const cipher = crypto.createCipheriv(ALGORITHM, this.encryptionKey, iv, {
      authTagLength: AUTH_TAG_LENGTH,
    });

    // Encrypt
    const encrypted = Buffer.concat([
      cipher.update(plaintext, 'utf8'),
      cipher.final(),
    ]);

    // Get authentication tag
    const authTag = cipher.getAuthTag();

    // Build encrypted token structure
    const token: EncryptedToken = {
      algorithm: ALGORITHM,
      keyVersion: this.config.keyVersion,
      iv: iv.toString('base64'),
      authTag: authTag.toString('base64'),
      ciphertext: encrypted.toString('base64'),
    };

    return JSON.stringify(token);
  }

  private async decryptWithLocalKey(token: EncryptedToken): Promise<string> {
    if (!this.encryptionKey) {
      throw new Error('Encryption key not initialized');
    }

    // Decode components
    const iv = Buffer.from(token.iv, 'base64');
    const authTag = Buffer.from(token.authTag, 'base64');
    const ciphertext = Buffer.from(token.ciphertext, 'base64');

    // Validate lengths
    if (iv.length !== IV_LENGTH) {
      throw new Error('Invalid IV length');
    }
    if (authTag.length !== AUTH_TAG_LENGTH) {
      throw new Error('Invalid auth tag length');
    }

    // Create decipher
    const decipher = crypto.createDecipheriv(ALGORITHM, this.encryptionKey, iv, {
      authTagLength: AUTH_TAG_LENGTH,
    });
    decipher.setAuthTag(authTag);

    // Decrypt
    try {
      const decrypted = Buffer.concat([
        decipher.update(ciphertext),
        decipher.final(),
      ]);
      return decrypted.toString('utf8');
    } catch {
      throw new Error('Decryption failed - token may be corrupted or tampered');
    }
  }

  // ============================================
  // Private Methods - Cloud KMS Encryption
  // ============================================

  /**
   * Load Google Cloud KMS client dynamically
   * Returns null if package is not installed
   *
   * Uses Function constructor to prevent Vite/bundler from analyzing the import
   */
  private async loadKmsClient(): Promise<any> {
    try {
      // Use indirect eval to prevent bundler from analyzing the import
      // This is safe because we control the string and it's not user input
      const moduleName = '@google-cloud/kms';
      const importFn = new Function('moduleName', 'return import(moduleName)');
      const kmsModule = await importFn(moduleName);
      return new kmsModule.KeyManagementServiceClient();
    } catch {
      throw new Error(
        'Google Cloud KMS integration requires @google-cloud/kms package. ' +
          'Install with: npm install @google-cloud/kms'
      );
    }
  }

  private async encryptWithKms(plaintext: string): Promise<string> {
    // Google Cloud KMS integration
    // Uses envelope encryption: generate DEK, encrypt data with DEK, encrypt DEK with KEK
    const kmsClient = await this.loadKmsClient();

    // Generate a Data Encryption Key (DEK)
    const dek = crypto.randomBytes(KEY_LENGTH);
    const iv = crypto.randomBytes(IV_LENGTH);

    // Encrypt plaintext with DEK
    const cipher = crypto.createCipheriv(ALGORITHM, dek, iv, {
      authTagLength: AUTH_TAG_LENGTH,
    });
    const encrypted = Buffer.concat([
      cipher.update(plaintext, 'utf8'),
      cipher.final(),
    ]);
    const authTag = cipher.getAuthTag();

    // Encrypt DEK with KMS (KEK)
    const [encryptedDekResponse] = await kmsClient.encrypt({
      name: this.config.kmsKeyName,
      plaintext: dek,
    });

    if (!encryptedDekResponse.ciphertext) {
      throw new Error('KMS encryption failed');
    }

    // Build envelope encrypted token
    const token = {
      algorithm: ALGORITHM,
      keyVersion: this.config.keyVersion,
      iv: iv.toString('base64'),
      authTag: authTag.toString('base64'),
      ciphertext: encrypted.toString('base64'),
      // Wrapped DEK (encrypted by KMS)
      wrappedDek: Buffer.from(encryptedDekResponse.ciphertext).toString('base64'),
      kmsKeyName: this.config.kmsKeyName,
    };

    return JSON.stringify(token);
  }

  private async decryptWithKms(token: EncryptedToken & { wrappedDek?: string; kmsKeyName?: string }): Promise<string> {
    if (!token.wrappedDek || !token.kmsKeyName) {
      throw new Error('Invalid KMS encrypted token - missing wrapped DEK');
    }

    const kmsClient = await this.loadKmsClient();

    // Decrypt DEK with KMS
    const [decryptedDekResponse] = await kmsClient.decrypt({
      name: token.kmsKeyName,
      ciphertext: Buffer.from(token.wrappedDek, 'base64'),
    });

    if (!decryptedDekResponse.plaintext) {
      throw new Error('KMS decryption failed');
    }

    const dek = Buffer.from(decryptedDekResponse.plaintext);

    // Decode components
    const iv = Buffer.from(token.iv, 'base64');
    const authTag = Buffer.from(token.authTag, 'base64');
    const ciphertext = Buffer.from(token.ciphertext, 'base64');

    // Decrypt data with DEK
    const decipher = crypto.createDecipheriv(ALGORITHM, dek, iv, {
      authTagLength: AUTH_TAG_LENGTH,
    });
    decipher.setAuthTag(authTag);

    try {
      const decrypted = Buffer.concat([
        decipher.update(ciphertext),
        decipher.final(),
      ]);
      return decrypted.toString('utf8');
    } catch {
      throw new Error('Decryption failed - token may be corrupted or tampered');
    }
  }

  // ============================================
  // Private Helpers
  // ============================================

  private async ensureInitialized(): Promise<void> {
    if (!this.initialized) {
      await this.initialize();
    }
  }
}

// ============================================
// Singleton Instance
// ============================================

let tokenEncryptionService: TokenEncryptionService | null = null;

/**
 * Get the singleton TokenEncryptionService instance
 */
export function getTokenEncryptionService(): TokenEncryptionService {
  if (!tokenEncryptionService) {
    tokenEncryptionService = new TokenEncryptionService();
  }
  return tokenEncryptionService;
}

/**
 * Reset singleton (for testing)
 */
export function resetTokenEncryptionService(): void {
  tokenEncryptionService = null;
}
