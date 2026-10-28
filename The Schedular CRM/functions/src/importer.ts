import {FieldValue} from "./firebaseAdmin";

// Firestore type for function parameters (avoids firebase-admin namespace dependency)
type FirestoreDB = {
  collection: (path: string) => FirestoreCollectionRef;
};
type FirestoreCollectionRef = {
  doc: (id?: string) => FirestoreDocRef;
  add: (data: Record<string, unknown>) => Promise<{ id: string }>;
  limit: (n: number) => { get: () => Promise<FirestoreQuerySnapshot> };
};
type FirestoreDocRef = {
  id: string;
  collection: (path: string) => FirestoreCollectionRef;
  set: (data: Record<string, unknown>, options?: unknown) => Promise<unknown>;
  update: (data: Record<string, unknown>) => Promise<unknown>;
  get: () => Promise<{ exists: boolean; data: () => Record<string, unknown> | undefined }>;
};
type FirestoreQuerySnapshot = {
  docs: Array<{ id: string; data: () => Record<string, unknown> }>;
};

type AllowedEntity = "lead" | "contact" | "deal" | "company" | "client" | "appointment" | "multi";
export type MultiEntityPrimaryType = "lead" | "contact" | "deal" | "company";
type DuplicateHandling = "skip" | "update" | "create";

// ============================================
// RBAC & Security (Agent M4)
// ============================================

/**
 * Roles allowed to import data
 * Per security requirements: owner, admin, manager, sales, staff
 */
const LEGACY_ROLE_MAP = {
  assistant: "frontDesk",
  sales_rep: "sales",
  marketing: "sales",
  user: "staff",
} as const;

const ALLOWED_IMPORT_ROLES = ["owner", "admin", "manager", "sales", "staff"];

/**
 * Validate if the user role is allowed to import data
 * @param role - User role to validate
 * @returns true if role is allowed, false otherwise
 */
export function isAllowedToImport(role: string): boolean {
  const normalizedRole =
    LEGACY_ROLE_MAP[role.toLowerCase().trim() as keyof typeof LEGACY_ROLE_MAP] ??
    role.toLowerCase().trim();
  return ALLOWED_IMPORT_ROLES.includes(normalizedRole);
}

/**
 * Validate import authorization
 * @param role - User role
 * @param businessId - Business ID for audit logging
 * @param userId - User ID for audit logging
 * @throws Error if role is not authorized
 */
export function validateImportAuthorization(role: string, businessId: string, userId: string): void {
  if (!role || role.trim() === "") {
    console.error("Import denied: No role specified", {businessId, userId});
    throw new Error("Access denied: No role specified for import operation");
  }

  if (!isAllowedToImport(role)) {
    console.error("Import denied: Invalid role", {role, businessId, userId});
    throw new Error(
      `Access denied: Role '${role}' is not authorized to import data. ` +
      `Allowed roles: ${ALLOWED_IMPORT_ROLES.join(", ")}`
    );
  }
}

/**
 * Validate multi-tenant isolation for import
 * Ensures all operations are scoped to the correct businessId
 * @param businessId - Business ID for the import
 * @param userBusinessId - User's business ID
 * @throws Error if businessId mismatch detected
 */
export function validateBusinessIdIsolation(businessId: string, userBusinessId: string): void {
  if (!businessId || businessId.trim() === "") {
    throw new Error("Security violation: No businessId specified for import operation");
  }

  if (!userBusinessId || userBusinessId.trim() === "") {
    throw new Error("Security violation: No userBusinessId found in context");
  }

  if (businessId !== userBusinessId) {
    console.error("Cross-tenant import attempt blocked", {
      userBusinessId,
      importBusinessId: businessId,
    });
    throw new Error(
      "Security violation: Attempted cross-tenant import. " +
      `User businessId: ${userBusinessId}, Import businessId: ${businessId}`
    );
  }
}

export interface ExistingIdentifiers {
  emails?: string[];
  phones?: string[];
}

export interface ImportJobPayload {
  entityType: AllowedEntity;
  primaryEntityType?: MultiEntityPrimaryType;
  headers: string[];
  rows: string[][];
  fieldMapping: Record<string, string>;
  businessId: string;
  duplicateHandling: DuplicateHandling;
  skipFirstRow?: boolean;
  dryRun?: boolean;
  existingIdentifiers?: ExistingIdentifiers;
  /** User ID for security validation and audit logging (required by Agent M4) */
  userId?: string;
  /** User role for RBAC validation (required by Agent M4) */
  userRole?: string;
  /** User's business ID for cross-tenant isolation check (required by Agent M4) */
  userBusinessId?: string;
}

export interface ImportExecutionResult {
  imported: number;
  skipped: number;
  validationErrors: Array<{row: number; field?: string; error: string}>;
  errors?: string[];
  multiEntitySummary?: {
    companiesCreated: number;
    contactsCreated: number;
    leadsCreated: number;
    dealsCreated: number;
  };
}

interface EntityData {
  [key: string]: any;
}

const REQUIRED_FIELDS: Record<AllowedEntity, string[]> = {
  lead: ["firstName", "lastName", "email"],
  contact: ["firstName", "lastName", "email"],
  client: ["firstName", "lastName", "email"],
  deal: ["title"],
  company: ["name"],
  appointment: ["startTime", "clientEmail"],
  multi: [],
};

const PHONE_REGEX = /^[+]?[\d\s\-().]+$/;
const MIN_PHONE_DIGITS = 7;

const normalizePhone = (phone?: string): string | null => {
  if (!phone) return null;
  return phone.replace(/\D/g, "");
};

const parseCurrency = (value: string): number | null => {
  const cleaned = value.replace(/[^0-9.-]+/g, "");
  if (!cleaned || cleaned === "-" || cleaned === "." || cleaned === "-.") {
    return null;
  }
  const num = Number(cleaned);
  if (Number.isNaN(num)) return null;
  return Math.round(num * 100);
};

const parseMonetaryValue = (value: string, header: string): number | null => {
  const normalizedHeader = header.toLowerCase().replace(/[\s_-]+/g, "");
  if (normalizedHeader.includes("cents")) {
    const cleaned = value.replace(/[^0-9.-]+/g, "");
    if (!cleaned || cleaned === "-" || cleaned === "." || cleaned === "-.") {
      return null;
    }
    const num = Number(cleaned);
    if (Number.isNaN(num)) return null;
    return Math.round(num);
  }

  return parseCurrency(value);
};

const parseDate = (value: string): Date | null => {
  if (!value) return null;
  const normalized = value.trim();
  const isoDate = new Date(normalized);
  if (!Number.isNaN(isoDate.getTime())) {
    return isoDate;
  }
  const mmddyyyy = normalized.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (mmddyyyy) {
    const [, month, day, year] = mmddyyyy;
    return new Date(Number(year), Number(month) - 1, Number(day));
  }
  const ddmmyyyy = normalized.match(/^(\d{1,2})-(\d{1,2})-(\d{4})$/);
  if (ddmmyyyy) {
    const [, day, month, year] = ddmmyyyy;
    return new Date(Number(year), Number(month) - 1, Number(day));
  }
  return null;
};

const splitFullName = (fullName: string): {firstName: string; lastName: string} => {
  const parts = fullName.trim().split(/\s+/);
  if (parts.length === 1) {
    return {firstName: parts[0], lastName: ""};
  }
  const lastName = parts.pop() || "";
  const firstName = parts.join(" ");
  return {firstName, lastName};
};

function getCollectionName(entityType: AllowedEntity): string {
  switch (entityType) {
    case "lead":
      return "leads";
    case "contact":
      // CRM contacts live in the shared Scheduler-owned clients collection.
      return "clients";
    case "deal":
      return "deals";
    case "company":
      return "companies";
    case "client":
      return "clients";
    case "appointment":
      return "appointments";
    case "multi":
      return "imports";
    default:
      return "records";
  }
}

function transformRowData(
  row: string[],
  headers: string[],
  entityType: AllowedEntity,
  fieldMapping: Record<string, string>,
  businessId: string
): EntityData {
  const data: EntityData = {
    businessId,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };

  headers.forEach((header, index) => {
    const field = fieldMapping[header];
    const rawValue = row[index]?.trim() || "";
    if (!field || rawValue === "") {
      return;
    }

    switch (field) {
      case "email":
      case "clientEmail":
        data[field] = rawValue.toLowerCase();
        break;
      case "phone":
        data[field] = normalizePhone(rawValue);
        break;
      case "valueCents": {
        const value = parseMonetaryValue(rawValue, header);
        data[field] = value ?? 0;
        break;
      }
      case "expectedCloseDate":
      case "startTime":
      case "endTime": {
        const date = parseDate(rawValue);
        data[field] = date || undefined;
        break;
      }
      case "status":
        data[field] = rawValue.toLowerCase();
        break;
      case "fullName": {
        const {firstName, lastName} = splitFullName(rawValue);
        data.firstName = firstName;
        data.lastName = lastName;
        break;
      }
      default:
        data[field] = rawValue;
    }
  });

  if (entityType === "lead") {
    data.status = data.status || "new";
    data.source = data.source || "other";
    data.tags = data.tags || [];
  } else if (entityType === "deal") {
    data.valueCents = typeof data.valueCents === "number" ? data.valueCents : 0;
    data.tags = data.tags || [];
    data.status = "open";
  } else if (entityType === "contact" || entityType === "company" || entityType === "client") {
    data.tags = data.tags || [];
  } else if (entityType === "appointment") {
    data.status = data.status || "scheduled";
  }

  return data;
}

function validateRow(
  row: string[],
  headers: string[],
  entityType: AllowedEntity,
  fieldMapping: Record<string, string>
): Array<{row: number; field: string; error: string}> {
  const errors: Array<{row: number; field: string; error: string}> = [];
  const rowData: EntityData = {};
  let valueCentsHeader = "";

  headers.forEach((header, index) => {
    const field = fieldMapping[header];
    const value = row[index]?.trim() || "";
    if (field === "fullName") {
      const {firstName, lastName} = splitFullName(value);
      rowData.firstName = firstName;
      rowData.lastName = lastName;
    } else if (field) {
      rowData[field] = value;
      if (field === "valueCents") {
        valueCentsHeader = header;
      }
    }
  });

  const requiredFields = REQUIRED_FIELDS[entityType] || [];
  requiredFields.forEach((field) => {
    if (!rowData[field] || rowData[field] === "") {
      errors.push({
        row: 0,
        field,
        error: `Required field '${field}' is missing or empty`,
      });
    }
  });

  if (rowData.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(rowData.email)) {
    errors.push({row: 0, field: "email", error: "Invalid email format"});
  }

  if (rowData.phone && !PHONE_REGEX.test(rowData.phone)) {
    errors.push({row: 0, field: "phone", error: "Invalid phone format"});
  } else if (rowData.phone) {
    const normalized = normalizePhone(rowData.phone);
    if (!normalized || normalized.length < MIN_PHONE_DIGITS) {
      errors.push({
        row: 0,
        field: "phone",
        error: `Phone number must include at least ${MIN_PHONE_DIGITS} digits`,
      });
    }
  }

  if (entityType === "deal") {
    if (rowData.valueCents) {
      const value = parseMonetaryValue(rowData.valueCents, valueCentsHeader);
      if (value === null) {
        errors.push({
          row: 0,
          field: "valueCents",
          error: "Invalid currency value",
        });
      }
    }
    if (rowData.expectedCloseDate) {
      const date = parseDate(rowData.expectedCloseDate);
      if (date === null) {
        errors.push({
          row: 0,
          field: "expectedCloseDate",
          error: "Invalid date format",
        });
      }
    }

    const hasContactOrCompany =
      !!rowData.clientEmail ||
      !!rowData.clientName ||
      !!rowData.companyName ||
      !!rowData.companyDomain;

    if (!hasContactOrCompany) {
      errors.push({
        row: 0,
        field: "clientEmail",
        error: "Provide a contact (email/name) or company to link this opportunity",
      });
    }
  }

  if (entityType === "appointment") {
    if (rowData.startTime) {
      const date = parseDate(rowData.startTime);
      if (date === null) {
        errors.push({
          row: 0,
          field: "startTime",
          error: "Invalid start time format",
        });
      }
    }
    if (rowData.endTime) {
      const date = parseDate(rowData.endTime);
      if (date === null) {
        errors.push({
          row: 0,
          field: "endTime",
          error: "Invalid end time format",
        });
      }
    }
  }

  return errors;
}

export function validateAllRows(
  rows: string[][],
  headers: string[],
  entityType: AllowedEntity,
  fieldMapping: Record<string, string>,
  existingIdentifiers?: ExistingIdentifiers
): Array<{row: number; field: string; error: string}> {
  const allErrors: Array<{row: number; field: string; error: string}> = [];
  const seenEmails = new Map<string, number>();
  const seenPhones = new Map<string, number>();
  const existingEmailSet = new Set(
    (existingIdentifiers?.emails || [])
      .map((email) => email.toLowerCase().trim())
      .filter(Boolean),
  );
  const existingPhoneSet = new Set(
    (existingIdentifiers?.phones || []).map((phone) => normalizePhone(phone)).filter(Boolean),
  );

  const getFieldValue = (row: string[], field: string): string => {
    const headerIndex = headers.findIndex((h) => fieldMapping[h] === field);
    if (headerIndex === -1) return "";
    return row[headerIndex]?.trim() || "";
  };

  rows.forEach((row, index) => {
    if (row.every((cell) => !cell || cell.trim() === "")) {
      return;
    }

    const errors = validateRow(row, headers, entityType, fieldMapping);
    errors.forEach((error) => {
      allErrors.push({
        ...error,
        row: index + 1,
      });
    });

    const email = getFieldValue(row, "email").toLowerCase();
    if (email) {
      if (existingEmailSet.has(email)) {
        allErrors.push({
          row: index + 1,
          field: "email",
          error:
            "Email already exists for this business. Update the existing record instead of importing a duplicate.",
        });
      }
      const firstSeen = seenEmails.get(email);
      if (firstSeen) {
        allErrors.push({
          row: index + 1,
          field: "email",
          error: `Duplicate email detected in import (first seen on row ${firstSeen})`,
        });
      } else {
        seenEmails.set(email, index + 1);
      }
    }

    const phone = normalizePhone(getFieldValue(row, "phone"));
    if (phone) {
      if (existingPhoneSet.has(phone)) {
        allErrors.push({
          row: index + 1,
          field: "phone",
          error:
            "Phone already exists for this business. Update the existing record instead of importing a duplicate.",
        });
      }
      const firstSeen = seenPhones.get(phone);
      if (firstSeen) {
        allErrors.push({
          row: index + 1,
          field: "phone",
          error: `Duplicate phone detected in import (first seen on row ${firstSeen})`,
        });
      } else {
        seenPhones.set(phone, index + 1);
      }
    }
  });

  return allErrors;
}

function buildExistingIdentifierSet(existingRecords: Array<{email?: string; phone?: string}>): ExistingIdentifiers {
  const emails = new Set<string>();
  const phones = new Set<string>();
  existingRecords.forEach((record) => {
    if (record.email) emails.add(String(record.email).toLowerCase());
    if (record.phone) {
      const normalized = normalizePhone(String(record.phone));
      if (normalized) phones.add(normalized);
    }
  });
  return {emails: Array.from(emails), phones: Array.from(phones)};
}

async function fetchExistingRecords(
  db: FirestoreDB,
  collectionName: string,
  businessId: string
): Promise<Array<{id: string; email?: string; phone?: string}>> {
  const snapshot = await db
    .collection("businesses")
    .doc(businessId)
    .collection(collectionName)
    .limit(500)
    .get();

  return snapshot.docs.map((doc: { id: string; data: () => Record<string, unknown> }) => ({id: doc.id, ...(doc.data() as Record<string, unknown>)}));
}

function findDuplicate(
  rowData: EntityData,
  existingRecords: Array<{id: string; email?: string; phone?: string}>
): {id: string} | null {
  const email = rowData.email?.toLowerCase();
  const phone = rowData.phone ? normalizePhone(rowData.phone) : null;
  for (const record of existingRecords) {
    if (email && record.email && String(record.email).toLowerCase() === email) {
      return {id: record.id};
    }
    if (phone && record.phone && normalizePhone(String(record.phone)) === phone) {
      return {id: record.id};
    }
  }
  return null;
}

export async function runImport(
  db: FirestoreDB,
  payload: ImportJobPayload
): Promise<ImportExecutionResult> {
  // ============================================
  // SECURITY VALIDATION (Agent M4)
  // ============================================

  // Extract user context (required for security checks)
  const userId = payload.userId || "unknown";
  const userRole = payload.userRole || "";
  const userBusinessId = payload.userBusinessId || payload.businessId;

  // 1. Validate role-based access control
  try {
    validateImportAuthorization(userRole, payload.businessId, userId);
  } catch (error) {
    console.error("Import authorization failed", {
      userId,
      userRole,
      businessId: payload.businessId,
      error: error instanceof Error ? error.message : String(error),
    });
    return {
      imported: 0,
      skipped: payload.rows.length,
      validationErrors: [],
      errors: [error instanceof Error ? error.message : "Access denied"],
    };
  }

  // 2. Validate multi-tenant isolation (prevent cross-tenant imports)
  try {
    validateBusinessIdIsolation(payload.businessId, userBusinessId);
  } catch (error) {
    console.error("Business ID isolation check failed", {
      userId,
      userBusinessId,
      importBusinessId: payload.businessId,
      error: error instanceof Error ? error.message : String(error),
    });
    return {
      imported: 0,
      skipped: payload.rows.length,
      validationErrors: [],
      errors: [error instanceof Error ? error.message : "Security violation: cross-tenant import attempt"],
    };
  }

  // Security checks passed - proceed with import
  console.log("Import security validation passed", {
    userId,
    userRole,
    businessId: payload.businessId,
    entityType: payload.entityType,
    rowCount: payload.rows.length,
  });

  const collectionName = getCollectionName(payload.entityType);
  const rows = payload.skipFirstRow ? payload.rows.slice(1) : payload.rows;

  const existingRecords = await fetchExistingRecords(db, collectionName, payload.businessId);
  const existingIdentifierSet = buildExistingIdentifierSet(existingRecords);
  const mergedIdentifiers: ExistingIdentifiers =
    payload.duplicateHandling === "skip"
      ? {
          emails: Array.from(
            new Set([
              ...(payload.existingIdentifiers?.emails || []),
              ...(existingIdentifierSet.emails || []),
            ]),
          ),
          phones: Array.from(
            new Set([
              ...(payload.existingIdentifiers?.phones || []),
              ...(existingIdentifierSet.phones || []),
            ]),
          ),
        }
      : {
          emails: payload.existingIdentifiers?.emails || [],
          phones: payload.existingIdentifiers?.phones || [],
        };

  const validationErrors = validateAllRows(
    rows,
    payload.headers,
    payload.entityType,
    payload.fieldMapping,
    mergedIdentifiers,
  );

  // ============================================
  // METRICS & OBSERVABILITY (Agent M5)
  // ============================================
  const startTime = Date.now();
  let duplicatesEncountered = 0;

  if (validationErrors.length > 0) {
    // NO PHI: Log only aggregate metrics
    console.log("[IMPORT_METRICS]", {
      entityType: payload.entityType,
      totalRows: rows.length,
      imported: 0,
      skipped: rows.length,
      validationErrorCount: validationErrors.length,
      duplicatesFound: 0,
      durationMs: Date.now() - startTime,
    });

    return {
      imported: 0,
      skipped: rows.length,
      validationErrors,
      errors: ["Validation required before import"],
    };
  }

  if (payload.dryRun) {
    // NO PHI: Log dry run metrics
    console.log("[IMPORT_METRICS]", {
      entityType: payload.entityType,
      totalRows: rows.length,
      imported: 0,
      skipped: rows.length,
      validationErrorCount: 0,
      duplicatesFound: 0,
      dryRun: true,
      durationMs: Date.now() - startTime,
    });

    return {
      imported: 0,
      skipped: rows.length,
      validationErrors: [],
    };
  }

  let imported = 0;
  let skipped = 0;
  const colRef = db.collection("businesses").doc(payload.businessId).collection(collectionName);

  for (const row of rows) {
    try {
      if (row.every((cell) => !cell || cell.trim() === "")) {
        skipped++;
        continue;
      }

      const rowData = transformRowData(
        row,
        payload.headers,
        payload.entityType,
        payload.fieldMapping,
        payload.businessId,
      );

      const duplicate = findDuplicate(rowData, existingRecords);
      if (duplicate) {
        duplicatesEncountered++;
        if (payload.duplicateHandling === "skip") {
          skipped++;
          continue;
        }

        if (payload.duplicateHandling === "update") {
          const {createdAt: _omitCreatedAt, ...updateData} = rowData;
          await colRef.doc(duplicate.id).set(
            {
              ...updateData,
              updatedAt: FieldValue.serverTimestamp(),
            },
            {merge: true},
          );
          imported++;
          continue;
        }
      }

      const docRef = colRef.doc();
      await docRef.set(rowData);
      existingRecords.push({id: docRef.id, email: rowData.email, phone: rowData.phone});
      imported++;
    } catch (error) {
      skipped++;
    }
  }

  // ============================================
  // AUDIT LOGGING (Agent M4 - HIPAA Compliance)
  // ============================================

  // Log import activity for audit trail (NO PHI in logs)
  try {
    await db
      .collection("businesses")
      .doc(payload.businessId)
      .collection("auditLogs")
      .add({
        businessId: payload.businessId,
        userId,
        userName: "Import User", // In production, pass userName from payload
        action: "import",
        entityType: payload.entityType,
        entityId: null, // Batch operation - no single entity ID
        timestamp: FieldValue.serverTimestamp(),
        metadata: {
          totalRows: rows.length,
          imported,
          skipped,
          duplicateHandling: payload.duplicateHandling,
          dryRun: payload.dryRun || false,
          // CRITICAL: Never include PHI (names, emails, phones, etc.)
        },
      });

    console.log("Import audit log created", {
      businessId: payload.businessId,
      userId,
      entityType: payload.entityType,
      imported,
      skipped,
    });
  } catch (auditError) {
    // Log audit failure but don't fail the import
    console.error("Failed to create import audit log", {
      businessId: payload.businessId,
      userId,
      error: auditError instanceof Error ? auditError.message : String(auditError),
    });
  }

  // ============================================
  // FINAL METRICS (Agent M5)
  // ============================================

  // NO PHI: Log final import metrics
  const durationMs = Date.now() - startTime;
  console.log("[IMPORT_METRICS]", {
    entityType: payload.entityType,
    totalRows: rows.length,
    imported,
    skipped,
    validationErrorCount: 0,
    duplicatesFound: duplicatesEncountered,
    duplicateHandling: payload.duplicateHandling,
    durationMs,
  });

  return {
    imported,
    skipped,
    validationErrors: [],
  };
}
