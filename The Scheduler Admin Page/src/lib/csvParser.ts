import {
  INVITABLE_USER_ROLES,
  toInvitableUserRole,
  type InvitableUserRole,
} from '../types/auth';

export interface CsvInviteRow {
  email: string;
  role: InvitableUserRole;
  name?: string;
}

export interface ParsedCsvResult {
  valid: CsvInviteRow[];
  invalid: Array<{ row: number; data: Partial<CsvInviteRow>; error: string }>;
}

const ALLOWED_ROLES = [...INVITABLE_USER_ROLES];
const MAX_INVITES = 50;

/**
 * Validates an email address format.
 * HIPAA Note: Email is PII - only validate format, never log content.
 */
function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Validates if a role is allowed for bulk invites.
 * Owner role is excluded - ownership transfer is a separate flow.
 */
function isValidRole(role: string): role is InvitableUserRole {
  return toInvitableUserRole(role) !== undefined;
}

/**
 * Validates a single CSV row for invite data.
 * Returns error message or null if valid.
 * HIPAA Note: Never log email addresses or names in validation errors.
 */
export function validateInviteRow(row: CsvInviteRow, rowNum: number): string | null {
  if (!row.email || !row.email.trim()) {
    return 'Email is required';
  }

  if (!isValidEmail(row.email.trim())) {
    return 'Invalid email format';
  }

  if (!row.role || !row.role.trim()) {
    return 'Role is required';
  }

  if (!isValidRole(row.role.trim())) {
    return `Invalid role. Allowed: ${ALLOWED_ROLES.join(', ')}`;
  }

  if (row.role.trim() === 'owner') {
    return 'Cannot invite as owner - use ownership transfer instead';
  }

  return null;
}

/**
 * Parses CSV content into validated invite rows.
 * HIPAA Note: Only validates format - never logs email addresses or names.
 */
export function parseCsvInvites(csvContent: string): ParsedCsvResult {
  const valid: CsvInviteRow[] = [];
  const invalid: Array<{ row: number; data: Partial<CsvInviteRow>; error: string }> = [];
  const seenEmails = new Set<string>();

  const lines = csvContent.split('\n').map((line) => line.trim());

  // Remove empty lines
  const nonEmptyLines = lines.filter((line) => line.length > 0);

  if (nonEmptyLines.length === 0) {
    invalid.push({ row: 0, data: {}, error: 'CSV file is empty' });
    return { valid, invalid };
  }

  // Parse header
  const headerLine = nonEmptyLines[0];
  const headers = headerLine.split(',').map((h) => h.trim().toLowerCase());

  const emailIdx = headers.indexOf('email');
  const roleIdx = headers.indexOf('role');
  const nameIdx = headers.indexOf('name');

  if (emailIdx === -1) {
    invalid.push({ row: 0, data: {}, error: 'CSV must have "email" column' });
    return { valid, invalid };
  }

  if (roleIdx === -1) {
    invalid.push({ row: 0, data: {}, error: 'CSV must have "role" column' });
    return { valid, invalid };
  }

  // Parse data rows
  for (let i = 1; i < nonEmptyLines.length; i++) {
    const line = nonEmptyLines[i];
    const rowNum = i + 1; // 1-indexed for display

    // Simple CSV parsing (handles basic cases, not complex quoted values)
    const values = line.split(',').map((v) => v.trim());

    const email = values[emailIdx]?.trim() || '';
    const role = values[roleIdx]?.trim() || '';
    const name = nameIdx !== -1 ? values[nameIdx]?.trim() : undefined;

    const rowData: Partial<CsvInviteRow> = {
      email: email || undefined,
      role: toInvitableUserRole(role),
      name: name || undefined,
    };

    if (!role) {
      invalid.push({ row: rowNum, data: rowData, error: 'Role is required' });
      continue;
    }

    const normalizedRole = toInvitableUserRole(role);
    if (!normalizedRole) {
      invalid.push({
        row: rowNum,
        data: rowData,
        error: `Invalid role. Allowed: ${ALLOWED_ROLES.join(', ')}`,
      });
      continue;
    }

    // Validate row
    const inviteRow: CsvInviteRow = {
      email,
      role: normalizedRole,
      name,
    };

    const validationError = validateInviteRow(inviteRow, rowNum);

    if (validationError) {
      invalid.push({ row: rowNum, data: rowData, error: validationError });
      continue;
    }

    // Check for duplicates within CSV
    const normalizedEmail = email.toLowerCase();
    if (seenEmails.has(normalizedEmail)) {
      invalid.push({ row: rowNum, data: rowData, error: 'Duplicate email in CSV' });
      continue;
    }

    seenEmails.add(normalizedEmail);

    // Add to valid list
    valid.push({
      email: email.trim(),
      role: normalizedRole,
      name: name?.trim() || undefined,
    });

    // Enforce max invites limit
    if (valid.length >= MAX_INVITES) {
      // Add remaining rows as invalid
      for (let j = i + 1; j < nonEmptyLines.length; j++) {
        invalid.push({
          row: j + 1,
          data: {},
          error: `Exceeded maximum of ${MAX_INVITES} invites per batch`,
        });
      }
      break;
    }
  }

  return { valid, invalid };
}

/**
 * Generates a CSV template file content for bulk invites.
 */
export function generateCsvTemplate(): string {
  return `email,role,name
john@example.com,staff,John Smith
jane@example.com,admin,Jane Doe
bob@example.com,frontDesk,Bob Wilson`;
}
