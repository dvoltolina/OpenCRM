/**
 * Multi-Entity Import Handler
 * Agent M2: Backend Multi-Entity Import Integration
 *
 * Integrates multi-entity import processor with existing import infrastructure.
 * Handles:
 * - Security validation (RBAC, tenant isolation)
 * - Field mapping to multi-entity row format
 * - Batch processing with audit logging
 * - Error aggregation and reporting
 *
 * HIPAA Compliance:
 * - All operations scoped by businessId
 * - No PHI in logs/errors
 * - Audit logging for all entity operations
 */

import {
  processMultiEntityRow,
  type MultiEntityRow,
  type MultiEntityImportResult,
} from "./multi-entity-importer";
import type {ImportJobPayload, ImportExecutionResult, MultiEntityPrimaryType} from "./importer";
import {validateImportAuthorization, validateBusinessIdIsolation} from "./importer";
import {FieldValue} from "./firebaseAdmin";

const parseDateValue = (value: string): Date | null => {
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
};

/**
 * Map CSV row to MultiEntityRow format
 */
function mapRowToMultiEntity(
  row: string[],
  headers: string[],
  fieldMapping: Record<string, string>,
  primaryEntityType: MultiEntityPrimaryType = "contact"
): MultiEntityRow {
  const result: MultiEntityRow = {};

  headers.forEach((header, index) => {
    const field = fieldMapping[header];
    const value = row[index]?.trim() || "";

    if (!field || value === "") {
      return;
    }

    // Map to multi-entity fields
    switch (field) {
      // Company fields
      case "name":
        result.companyName = value;
        break;
      case "companyName":
      case "company":
        result.companyName = value;
        break;
      case "companyWebsite":
      case "website":
        result.companyWebsite = value;
        break;
      case "companyDomain":
      case "domain":
        result.companyDomain = value;
        break;
      case "companyIndustry":
      case "industry":
        result.companyIndustry = value;
        break;
      case "companySize":
      case "size":
        result.companySize = value;
        break;
      case "companyPhone":
        result.companyPhone = value;
        break;
      case "companyEmail":
        result.companyEmail = value;
        break;

      // Contact fields
      case "firstName":
        result.firstName = value;
        break;
      case "lastName":
        result.lastName = value;
        break;
      case "fullName":
        result.fullName = value;
        break;
      case "email":
        if (primaryEntityType === "company") {
          result.companyEmail = value;
        } else {
          result.email = value;
        }
        break;
      case "phone":
        if (primaryEntityType === "company") {
          result.companyPhone = value;
        } else {
          result.phone = value;
        }
        break;
      case "street":
      case "address":
        result.street = value;
        break;
      case "city":
        result.city = value;
        break;
      case "state":
        result.state = value;
        break;
      case "zipCode":
        result.zipCode = value;
        break;
      case "country":
        result.country = value;
        break;
      case "contactTitle":
        result.contactTitle = value;
        break;
      case "title":
        if (primaryEntityType === "deal") {
          result.dealTitle = value;
        } else {
          result.contactTitle = value;
        }
        break;
      case "clientEmail":
        result.email = value.toLowerCase();
        break;
      case "clientName":
        result.fullName = value;
        break;

      // Lead fields
      case "leadStatus":
        if (primaryEntityType === "contact") {
          result.contactLeadStatus = value;
        } else {
          result.leadStatus = value;
        }
        break;
      case "status":
        if (primaryEntityType === "lead") {
          result.leadStatus = value;
        } else if (primaryEntityType === "contact") {
          result.contactLeadStatus = value;
        }
        break;
      case "leadSource":
      case "source":
        result.leadSource = value;
        break;
      case "leadNotes":
        result.leadNotes = value;
        break;

      // Deal fields
      case "dealTitle":
        result.dealTitle = value;
        break;
      case "dealValueCents":
      case "dealValue": {
        // Parse currency
        const cleaned = value.replace(/[^0-9.-]+/g, "");
        const num = Number(cleaned);
        if (!Number.isNaN(num)) {
          result.dealValueCents = Math.round(num * 100);
        }
        break;
      }
      case "valueCents": {
        const num = Number(value);
        if (!Number.isNaN(num)) {
          result.dealValueCents = Math.round(num);
        }
        break;
      }
      case "dealStageName":
      case "stageName":
        result.dealStageName = value;
        break;
      case "pipelineName":
      case "dealPipelineName":
        result.dealPipelineName = value;
        break;
      case "expectedCloseDate":
      case "dealExpectedCloseDate": {
        const date = parseDateValue(value);
        if (date) {
          result.dealExpectedCloseDate = date;
        }
        break;
      }
      case "notes":
        if (primaryEntityType === "deal") {
          result.dealNotes = value;
        }
        break;
      case "dealNotes":
        result.dealNotes = value;
        break;

      // Shared fields
      case "tags": {
        // Parse comma-separated tags
        const tags = value.split(",").map((t) => t.trim()).filter(Boolean);
        result.tags = tags;
        break;
      }
      case "ownerId":
        result.ownerId = value;
        break;
      case "ownerName":
        result.ownerName = value;
        break;
    }
  });

  return result;
}

/**
 * Process multi-entity import with security validation and audit logging
 */
export async function runMultiEntityImport(
  db: FirebaseFirestore.Firestore,
  payload: ImportJobPayload
): Promise<ImportExecutionResult> {
  const userId = payload.userId || "unknown";
  const userName = "User"; // Could be passed in payload if needed
  const userRole = payload.userRole || "";
  const userBusinessId = payload.userBusinessId || payload.businessId;
  const primaryEntityType = payload.primaryEntityType || "contact";
  const rows = payload.skipFirstRow ? payload.rows.slice(1) : payload.rows;

  // RBAC & tenant isolation (HIPAA)
  validateImportAuthorization(userRole, payload.businessId, userId);
  validateBusinessIdIsolation(payload.businessId, userBusinessId);

  let imported = 0;
  let skipped = 0;
  const validationErrors: Array<{row: number; field?: string; error: string}> = [];
  const errors: string[] = [];

  // Summary counters for multi-entity
  let companiesCreated = 0;
  let contactsCreated = 0;
  let leadsCreated = 0;
  let dealsCreated = 0;

  // Dry run - just validate
  if (payload.dryRun) {
    return {
      imported: 0,
      skipped: rows.length,
      validationErrors: [],
    };
  }

  // Process each row
  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];

    // Skip empty rows
    if (row.every((cell) => !cell || cell.trim() === "")) {
      skipped++;
      continue;
    }

    try {
      const multiEntityRow = mapRowToMultiEntity(
        row,
        payload.headers,
        payload.fieldMapping,
        primaryEntityType
      );

      const result: MultiEntityImportResult = await processMultiEntityRow(
        db,
        payload.businessId,
        multiEntityRow,
        payload.duplicateHandling || "skip",
        userId,
        userName,
        primaryEntityType
      );

      if (result.skipped) {
        skipped++;
        if (result.error) {
          validationErrors.push({
            row: i + 1,
            error: result.error,
          });
        }
        continue;
      }

      // Track what was created
      if (result.companyCreated) companiesCreated++;
      if (result.contactCreated) contactsCreated++;
      if (result.leadCreated) leadsCreated++;
      if (result.dealCreated) dealsCreated++;

      imported++;

      // Audit log for multi-entity import (no PHI)
      if (result.contactId || result.companyId || result.leadId || result.dealId) {
        // Log to audit collection (without PHI)
        const auditRef = db
          .collection("businesses")
          .doc(payload.businessId)
          .collection("audit_logs")
          .doc();

        await auditRef.set({
          action: "multi_entity_import",
          userId,
          userRole,
          entityTypes: [
            result.companyId ? "company" : null,
            result.contactId ? "contact" : null,
            result.leadId ? "lead" : null,
            result.dealId ? "deal" : null,
          ].filter(Boolean),
          entityIds: [
            result.companyId,
            result.contactId,
            result.leadId,
            result.dealId,
          ].filter(Boolean),
          created: [
            result.companyCreated,
            result.contactCreated,
            result.leadCreated,
            result.dealCreated,
          ].some(Boolean),
          timestamp: FieldValue.serverTimestamp(),
          businessId: payload.businessId,
          dryRun: payload.dryRun || false,
          duplicateHandling: payload.duplicateHandling || "skip",
        });
      }
    } catch (error) {
      skipped++;
      errors.push(`Row ${i + 1}: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
  }

  return {
    imported,
    skipped,
    validationErrors,
    errors: errors.length > 0 ? errors : undefined,
    multiEntitySummary: {
      companiesCreated,
      contactsCreated,
      leadsCreated,
      dealsCreated,
    },
  };
}
