/**
 * ULID (Universally Unique Lexicographically Sortable Identifier) Generator
 *
 * Generates ULIDs for business/workspace IDs to ensure:
 * - Global uniqueness
 * - Lexicographic sorting (chronological order)
 * - URL-safe, case-insensitive representation
 *
 * Used for new businesses created via createWorkspace Cloud Function.
 * Legacy businesses may still use timestamp-based IDs.
 */

import {ulid} from "ulidx";

/**
 * Generate a new ULID
 */
export function generateUlid(): string {
  return ulid();
}

/**
 * Validate if a string is a valid ULID format
 */
export function isValidUlid(value: string): boolean {
  // ULID format: 26 characters, Crockford's Base32 alphabet
  const ulidRegex = /^[0-7][0-9A-HJKMNP-TV-Z]{25}$/i;
  return ulidRegex.test(value);
}

/**
 * Extract timestamp from ULID (first 10 characters)
 */
export function getUlidTimestamp(ulidStr: string): Date {
  if (!isValidUlid(ulidStr)) {
    throw new Error("Invalid ULID format");
  }

  // ULID encodes timestamp in first 48 bits (10 base32 chars)
  const timestampPart = ulidStr.substring(0, 10);

  // Decode Crockford's Base32
  const base32Chars = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
  let timestamp = 0;

  for (let i = 0; i < timestampPart.length; i++) {
    const char = timestampPart[i].toUpperCase();
    const value = base32Chars.indexOf(char);
    if (value === -1) {
      throw new Error("Invalid ULID character");
    }
    timestamp = timestamp * 32 + value;
  }

  return new Date(timestamp);
}
