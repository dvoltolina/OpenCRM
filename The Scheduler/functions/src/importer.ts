import {FieldValue} from "./firebaseAdmin";

type AllowedEntity = "lead" | "contact" | "deal" | "company" | "client" | "appointment";
type DuplicateHandling = "skip" | "update" | "create";
type Visibility = "private" | "team" | "org";

export interface ExistingIdentifiers {
  emails?: string[];
  phones?: string[];
}

export interface ImportJobPayload {
  entityType: AllowedEntity;
  headers: string[];
  rows: string[][];
  fieldMapping: Record<string, string>;
  businessId: string;
  duplicateHandling: DuplicateHandling;
  skipFirstRow?: boolean;
  dryRun?: boolean;
  existingIdentifiers?: ExistingIdentifiers;
  ownerId?: string;
  ownerName?: string;
  teamIds?: string[];
  visibility?: Visibility;
}

export interface ImportExecutionResult {
  imported: number;
  skipped: number;
  validationErrors: Array<{row: number; field?: string; error: string}>;
  errors?: string[];
}

interface EntityData {
  [key: string]: any;
}

const REQUIRED_FIELDS: Record<AllowedEntity, string[]> = {
  lead: ["firstName"],
  contact: ["firstName", "lastName", "email"],
  client: ["firstName", "lastName", "email"],
  deal: ["title", "valueCents"],
  company: ["name"],
  appointment: ["startTime", "clientEmail"],
};

const PHONE_REGEX = /^[+]?[\d\s\-().]+$/;
const MIN_PHONE_DIGITS = 7;

const normalizePhone = (phone?: string): string | null => {
  if (!phone) return null;
  return phone.replace(/\D/g, "");
};

const FULL_NAME_ALIASES = new Set([
  "name",
  "full name",
  "fullname",
  "contact name",
  "contact",
  "client name",
  "customer name",
  "person",
]);

const sanitizeTeamIds = (teamIds?: string[]): string[] =>
  Array.from(
    new Set(
      (teamIds || [])
        .filter((teamId): teamId is string => typeof teamId === "string")
        .map((teamId) => teamId.trim())
        .filter(Boolean),
    ),
  );

const normalizeVisibility = (value?: string): Visibility =>
  value === "private" || value === "org" ? value : "team";

const normalizeHeader = (header: string): string =>
  header.toLowerCase().trim().replace(/[_-]+/g, " ");

const parseCurrency = (value: string): number | null => {
  const cleaned = value.replace(/[^0-9.-]+/g, "");
  if (!cleaned || cleaned === "-" || cleaned === "." || cleaned === "-.") {
    return null;
  }
  const num = Number(cleaned);
  if (Number.isNaN(num)) return null;
  return Math.round(num * 100);
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
      return "clients";
    case "deal":
      return "deals";
    case "company":
      return "companies";
    case "client":
      return "clients";
    case "appointment":
      return "appointments";
    default:
      return "records";
  }
}

function getSplitNameHeader(
  headers: string[],
  entityType: AllowedEntity,
  fieldMapping: Record<string, string>
): string | undefined {
  if (entityType !== "lead" && entityType !== "contact" && entityType !== "client") {
    return undefined;
  }

  const hasLastNameColumn = headers.some((header) => fieldMapping[header] === "lastName");
  if (hasLastNameColumn) {
    return undefined;
  }

  return headers.find((header) => (
    fieldMapping[header] === "firstName" &&
    FULL_NAME_ALIASES.has(normalizeHeader(header))
  ));
}

function applyOwnershipDefaults(
  data: EntityData,
  entityType: AllowedEntity,
  payload: ImportJobPayload
): EntityData {
  if (
    entityType !== "lead" &&
    entityType !== "contact" &&
    entityType !== "deal" &&
    entityType !== "company" &&
    entityType !== "client"
  ) {
    return data;
  }

  const importedTeams = Array.isArray(data.teamIds) ? sanitizeTeamIds(data.teamIds) : [];
  return {
    ...data,
    ownerId: data.ownerId || payload.ownerId,
    ownerName: data.ownerName || payload.ownerName,
    teamIds: importedTeams.length > 0 ? importedTeams : sanitizeTeamIds(payload.teamIds),
    visibility: normalizeVisibility(typeof data.visibility === "string" ? data.visibility : payload.visibility),
  };
}

function transformRowData(
  row: string[],
  headers: string[],
  entityType: AllowedEntity,
  fieldMapping: Record<string, string>,
  businessId: string
): EntityData {
  const splitNameHeader = getSplitNameHeader(headers, entityType, fieldMapping);
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

    if (header === splitNameHeader) {
      const {firstName, lastName} = splitFullName(rawValue);
      data.firstName = firstName;
      if (lastName) {
        data.lastName = lastName;
      }
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
        const value = parseCurrency(rawValue);
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
    if (entityType === "contact") {
      data.lifecycle = data.lifecycle || "prospect";
    }
    if (entityType === "client") {
      data.lifecycle = data.lifecycle || "active";
    }
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
  const splitNameHeader = getSplitNameHeader(headers, entityType, fieldMapping);

  headers.forEach((header, index) => {
    const field = fieldMapping[header];
    const value = row[index]?.trim() || "";
    if (header === splitNameHeader || field === "fullName") {
      const {firstName, lastName} = splitFullName(value);
      rowData.firstName = firstName;
      rowData.lastName = lastName;
    } else if (field) {
      rowData[field] = value;
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
      const value = parseCurrency(rowData.valueCents);
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
  existingIdentifiers?: ExistingIdentifiers,
  duplicateHandling: DuplicateHandling = "skip"
): Array<{row: number; field: string; error: string}> {
  const allErrors: Array<{row: number; field: string; error: string}> = [];
  const seenEmails = new Map<string, number>();
  const seenPhones = new Map<string, number>();
  const checkExistingDuplicates = duplicateHandling === "skip";
  const existingEmailSet = new Set(
    (checkExistingDuplicates ? existingIdentifiers?.emails || [] : [])
      .map((email) => email.toLowerCase().trim())
      .filter(Boolean),
  );
  const existingPhoneSet = new Set(
    (checkExistingDuplicates ? existingIdentifiers?.phones || [] : [])
      .map((phone) => normalizePhone(phone)).filter(Boolean),
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
    if (record.email) {
      emails.add(String(record.email).toLowerCase());
    }
    if (record.phone) {
      const normalized = normalizePhone(String(record.phone));
      if (normalized) {
        phones.add(normalized);
      }
    }
  });

  return {
    emails: Array.from(emails),
    phones: Array.from(phones),
  };
}

async function fetchExistingRecords(
  db: FirebaseFirestore.Firestore,
  collectionName: string,
  businessId: string
): Promise<Array<{id: string; email?: string; phone?: string}>> {
  const snapshot = await db
    .collection("businesses")
    .doc(businessId)
    .collection(collectionName)
    .limit(500)
    .get();

  return snapshot.docs.map((doc) => ({id: doc.id, ...(doc.data() as any)}));
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

function upsertTrackedRecord(
  existingRecords: Array<{id: string; email?: string; phone?: string}>,
  record: {id: string; email?: string; phone?: string}
): void {
  const index = existingRecords.findIndex((existing) => existing.id === record.id);
  if (index >= 0) {
    existingRecords[index] = {
      ...existingRecords[index],
      ...record,
    };
    return;
  }
  existingRecords.push(record);
}

function mapLeadStatusToContactLeadStatus(status?: unknown): string | undefined {
  if (typeof status !== "string") {
    return undefined;
  }

  switch (status.trim().toLowerCase()) {
    case "new":
      return "New";
    case "contacted":
      return "Working";
    case "qualified":
      return "Qualified";
    case "unqualified":
      return "Unqualified";
    case "converted":
      return "Qualified";
    default:
      return undefined;
  }
}

function buildLeadMirrorClientData(rowData: EntityData, payload: ImportJobPayload): EntityData {
  const mirrored: EntityData = {
    businessId: payload.businessId,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    firstName: rowData.firstName,
    lastName: rowData.lastName,
    email: rowData.email,
    phone: rowData.phone,
    companyName: rowData.companyName,
    title: rowData.title,
    tags: Array.isArray(rowData.tags) ? rowData.tags : [],
    lifecycle: "lead",
    leadStatus: mapLeadStatusToContactLeadStatus(rowData.status),
    leadSource: rowData.source,
    crmNotes: typeof rowData.notes === "string" ? rowData.notes : undefined,
    assignedRepUid: rowData.assigneeId,
    assignedRepName: rowData.assigneeName,
  };

  return applyOwnershipDefaults(mirrored, "contact", payload);
}

async function syncLeadIntoClients(
  db: FirebaseFirestore.Firestore,
  payload: ImportJobPayload,
  rowData: EntityData,
  existingClientRecords: Array<{id: string; email?: string; phone?: string}>
): Promise<void> {
  const clientData = buildLeadMirrorClientData(rowData, payload);
  const clientColRef = db.collection("businesses").doc(payload.businessId).collection("clients");
  const duplicateClient = findDuplicate(clientData, existingClientRecords);

  if (duplicateClient) {
    if (payload.duplicateHandling === "skip") {
      return;
    }

    if (payload.duplicateHandling === "update") {
      const {createdAt: _omitCreatedAt, ...updateData} = clientData;
      await clientColRef.doc(duplicateClient.id).set(
        {
          ...updateData,
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true}
      );
      upsertTrackedRecord(existingClientRecords, {
        id: duplicateClient.id,
        email: clientData.email,
        phone: clientData.phone,
      });
      return;
    }
  }

  const docRef = clientColRef.doc();
  await docRef.set(clientData);
  upsertTrackedRecord(existingClientRecords, {
    id: docRef.id,
    email: clientData.email,
    phone: clientData.phone,
  });
}

export async function runImport(
  db: FirebaseFirestore.Firestore,
  payload: ImportJobPayload
): Promise<ImportExecutionResult> {
  const collectionName = getCollectionName(payload.entityType);
  const rows = payload.skipFirstRow ? payload.rows.slice(1) : payload.rows;

  const existingRecords = await fetchExistingRecords(db, collectionName, payload.businessId);
  const existingClientRecords =
    payload.entityType === "lead"
      ? await fetchExistingRecords(db, "clients", payload.businessId)
      : existingRecords;
  const existingIdentifierSet = buildExistingIdentifierSet(existingRecords);
  const mergedIdentifiers: ExistingIdentifiers =
    payload.duplicateHandling === "skip"
      ? {
          emails: Array.from(
            new Set([
              ...(payload.existingIdentifiers?.emails || []),
              ...(existingIdentifierSet.emails || []),
            ])
          ),
          phones: Array.from(
            new Set([
              ...(payload.existingIdentifiers?.phones || []),
              ...(existingIdentifierSet.phones || []),
            ])
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
    payload.duplicateHandling,
  );
  const invalidRows = new Set(validationErrors.map((error) => error.row));

  if (payload.dryRun) {
    return {
      imported: 0,
      skipped: rows.length,
      validationErrors,
      errors: validationErrors.length > 0 ? ["Validation required before import"] : undefined,
    };
  }

  let imported = 0;
  let skipped = 0;

  const colRef = db.collection("businesses").doc(payload.businessId).collection(collectionName);

  for (const [index, row] of rows.entries()) {
    try {
      if (row.every((cell) => !cell || cell.trim() === "")) {
        skipped++;
        continue;
      }

      if (invalidRows.has(index + 1)) {
        skipped++;
        continue;
      }

      const rowData = transformRowData(
        row,
        payload.headers,
        payload.entityType,
        payload.fieldMapping,
        payload.businessId
      );

      const duplicate = findDuplicate(rowData, existingRecords);
      if (duplicate) {
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
            {merge: true}
          );
          upsertTrackedRecord(existingRecords, {
            id: duplicate.id,
            email: updateData.email,
            phone: updateData.phone,
          });
          if (payload.entityType === "lead") {
            await syncLeadIntoClients(db, payload, updateData, existingClientRecords);
          }
          imported++;
          continue;
        }
      }

      const createData = applyOwnershipDefaults(rowData, payload.entityType, payload);
      const docRef = colRef.doc();
      await docRef.set(createData);

      upsertTrackedRecord(existingRecords, {id: docRef.id, email: createData.email, phone: createData.phone});
      if (payload.entityType === "lead") {
        await syncLeadIntoClients(db, payload, createData, existingClientRecords);
      }
      imported++;
    } catch {
      skipped++;
    }
  }

  return {
    imported,
    skipped,
    validationErrors,
    errors: imported === 0 && validationErrors.length > 0 ? ["Validation required before import"] : undefined,
  };
}
