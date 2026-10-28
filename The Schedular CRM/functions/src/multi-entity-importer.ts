/**
 * Multi-Entity CSV Import Processor
 * Agent M2: Backend Multi-Entity Import
 *
 * Extends single-entity importer to create/update Companies, Contacts, optional Leads, and optional Deals per row.
 *
 * Match Rules:
 * - Company: domain→name
 * - Contact: email→phone→(company+name)
 * - Deal: title+company (or contact)+pipeline when update mode
 * - Lead: email/phone (or name+company) in update mode
 *
 * Row Flow:
 * 1. Upsert company
 * 2. Upsert contact linked to company
 * 3. Create/update lead ONLY if lead-status is present
 * 4. Create/update deal ONLY if deal fields are present
 * 5. Attach tags/industry
 * 6. Set owner if provided, else use current user
 *
 * HIPAA Compliance:
 * - All operations scoped by businessId
 * - No PHI in logs/errors
 * - Audit PHI reads/writes
 * - Duplicate handling respects privacy
 */

import {FieldValue} from "./firebaseAdmin";
import type {MultiEntityPrimaryType} from "./importer";

type DuplicateHandling = "skip" | "update" | "create";

export interface MultiEntityRow {
  // Company fields
  companyName?: string;
  companyWebsite?: string;
  companyDomain?: string;
  companyIndustry?: string;
  companySize?: string;
  companyPhone?: string;
  companyEmail?: string;

  // Contact fields (required)
  firstName?: string;
  lastName?: string;
  fullName?: string;
  email?: string;
  phone?: string;
  contactTitle?: string;
  contactLeadStatus?: string;
  street?: string;
  city?: string;
  state?: string;
  zipCode?: string;
  country?: string;

  // Lead fields (optional - only if leadStatus present)
  leadStatus?: string; // new|contacted|qualified|unqualified
  leadSource?: string;
  leadNotes?: string;

  // Deal fields (optional - only if title present)
  dealTitle?: string;
  dealValueCents?: number;
  dealStageName?: string;
  dealPipelineName?: string;
  dealExpectedCloseDate?: Date;
  dealNotes?: string;

  // Shared fields
  tags?: string[];
  ownerId?: string;
  ownerName?: string;
}

export interface MultiEntityImportResult {
  companyId?: string;
  companyCreated: boolean;
  contactId?: string;
  contactCreated: boolean;
  leadId?: string;
  leadCreated: boolean;
  dealId?: string;
  dealCreated: boolean;
  skipped: boolean;
  error?: string;
}

interface EntityData {
  [key: string]: any;
}

const CONTACT_COLLECTION = "clients";

// ============================================
// Utility Functions
// ============================================

const normalizePhone = (phone?: string): string | null => {
  if (!phone) return null;
  return phone.replace(/\D/g, "");
};

const normalizeDomain = (websiteOrEmail: string): string | null => {
  if (!websiteOrEmail) return null;
  const cleaned = websiteOrEmail.toLowerCase().trim();

  // Extract domain from email
  if (cleaned.includes("@")) {
    const parts = cleaned.split("@");
    if (parts.length === 2) return parts[1];
  }

  // Extract domain from URL
  try {
    const url = cleaned.startsWith("http") ? cleaned : `https://${cleaned}`;
    const parsed = new URL(url);
    return parsed.hostname.replace(/^www\./, "");
  } catch {
    // If not a valid URL, treat as domain
    return cleaned.replace(/^www\./, "");
  }
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

const normalizeContactLeadStatus = (value?: string): string | undefined => {
  if (!value) return undefined;

  const normalized = value.trim().toLowerCase();
  const statusMap: Record<string, string> = {
    new: "New",
    working: "Working",
    qualified: "Qualified",
    unqualified: "Unqualified",
    nurturing: "Nurturing",
    hot: "Qualified",
    cold: "Nurturing",
    warm: "Working",
    "in progress": "Working",
    in_progress: "Working",
    inprogress: "Working",
  };

  return statusMap[normalized];
};

const deriveNameFromEmail = (email: string): {firstName: string; lastName: string} => {
  const emailPrefix = email.split("@")[0] || "";
  const cleaned = emailPrefix.replace(/[._-]/g, " ").replace(/\d+/g, "").trim();
  return {
    firstName: cleaned || "Contact",
    lastName: "(from import)",
  };
};

const hasCompanySeed = (row: MultiEntityRow): boolean =>
  !!(row.companyName || row.companyWebsite || row.companyDomain || row.companyEmail);

const hasContactSeed = (row: MultiEntityRow): boolean =>
  !!(row.email || row.fullName || row.firstName || row.lastName || row.phone);

const resolveContactIdentity = (
  row: MultiEntityRow,
  allowEmailFallback = false
): {firstName: string; lastName: string; email: string} | null => {
  if (!row.email) {
    return null;
  }

  let firstName = row.firstName || "";
  let lastName = row.lastName || "";

  if ((!firstName || !lastName) && row.fullName) {
    const parsed = splitFullName(row.fullName);
    firstName = firstName || parsed.firstName;
    lastName = lastName || parsed.lastName;
  }

  if (allowEmailFallback) {
    const fallbackName = deriveNameFromEmail(row.email);
    firstName = firstName || fallbackName.firstName;
    lastName = lastName || fallbackName.lastName;
  }

  if (!firstName || !lastName) {
    return null;
  }

  return {
    firstName: firstName.trim(),
    lastName: lastName.trim(),
    email: row.email.toLowerCase().trim(),
  };
};

const formatContactName = (row: MultiEntityRow): string | undefined => {
  if (row.fullName?.trim()) {
    return row.fullName.trim();
  }

  const fullName = `${row.firstName || ""} ${row.lastName || ""}`.trim();
  return fullName || undefined;
};

// ============================================
// Company Matching & Upsert
// ============================================

/**
 * Find existing company by domain (preferred) or name
 * Match Rules: domain→name
 */
async function findCompany(
  db: FirebaseFirestore.Firestore,
  businessId: string,
  row: MultiEntityRow
): Promise<{id: string; data: EntityData} | null> {
  if (!row.companyName && !row.companyWebsite && !row.companyDomain) {
    return null;
  }

  const companyRef = db.collection("businesses").doc(businessId).collection("companies");

  // Try domain match first (most reliable)
  const domain = row.companyDomain || normalizeDomain(row.companyWebsite || row.companyEmail || "");

  if (domain) {
    const domainQuery = await companyRef.where("website", "==", domain).limit(1).get();
    if (!domainQuery.empty) {
      const doc = domainQuery.docs[0];
      return {id: doc.id, data: doc.data()};
    }

    // Try normalized domain patterns
    const websiteVariants = [
      domain,
      `www.${domain}`,
      `https://${domain}`,
      `http://${domain}`,
    ];

    for (const variant of websiteVariants) {
      const variantQuery = await companyRef.where("website", "==", variant).limit(1).get();
      if (!variantQuery.empty) {
        const doc = variantQuery.docs[0];
        return {id: doc.id, data: doc.data()};
      }
    }
  }

  // Fallback to name match (case-insensitive)
  if (row.companyName) {
    const normalizedName = row.companyName.toLowerCase().trim();
    const allCompanies = await companyRef.limit(100).get();

    for (const doc of allCompanies.docs) {
      const data = doc.data();
      if (data.name && String(data.name).toLowerCase().trim() === normalizedName) {
        return {id: doc.id, data};
      }
    }
  }

  return null;
}

/**
 * Upsert company based on match rules and duplicate handling
 */
async function upsertCompany(
  db: FirebaseFirestore.Firestore,
  businessId: string,
  row: MultiEntityRow,
  duplicateHandling: DuplicateHandling,
  currentUserId: string,
  currentUserName: string
): Promise<{id: string; created: boolean} | null> {
  const companyName =
    row.companyName?.trim() ||
    row.companyDomain ||
    normalizeDomain(row.companyWebsite || row.companyEmail || "") ||
    "";

  if (!companyName) {
    return null;
  }

  const companyRow = row.companyName ? row : {...row, companyName};
  const existing = await findCompany(db, businessId, companyRow);

  if (existing && duplicateHandling === "skip") {
    return {id: existing.id, created: false};
  }

  const companyData: EntityData = {
    name: companyName,
    businessId,
    tags: row.tags || [],
    ownerId: row.ownerId || currentUserId,
    ownerName: row.ownerName || currentUserName,
    teamIds: [],
    visibility: "team",
  };

  if (row.companyWebsite || row.companyDomain) {
    const domain = row.companyDomain || normalizeDomain(row.companyWebsite || "");
    if (domain) {
      companyData.website = domain;
    }
  }

  if (row.companyIndustry) {
    companyData.industry = row.companyIndustry;
  }

  if (row.companySize) {
    companyData.size = row.companySize;
  }

  if (row.companyPhone) {
    companyData.phone = normalizePhone(row.companyPhone);
  }

  if (row.companyEmail) {
    companyData.email = row.companyEmail.toLowerCase().trim();
  }

  const companyRef = db.collection("businesses").doc(businessId).collection("companies");

  if (existing && duplicateHandling === "update") {
    const updateData = {
      ...companyData,
      updatedAt: FieldValue.serverTimestamp(),
    };
    await companyRef.doc(existing.id).set(updateData, {merge: true});
    return {id: existing.id, created: false};
  }

  // Create new company
  const newCompanyRef = companyRef.doc();
  await newCompanyRef.set({
    ...companyData,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return {id: newCompanyRef.id, created: true};
}

// ============================================
// Contact Matching & Upsert
// ============================================

/**
 * Find existing contact by email→phone→(company+name)
 * Match Rules: email→phone→(company+name)
 */
async function findContact(
  db: FirebaseFirestore.Firestore,
  businessId: string,
  row: MultiEntityRow,
  companyId?: string
): Promise<{id: string; data: EntityData} | null> {
  const contactRef = db.collection("businesses").doc(businessId).collection(CONTACT_COLLECTION);

  // Try email match first (most reliable)
  if (row.email) {
    const normalizedEmail = row.email.toLowerCase().trim();
    const emailQuery = await contactRef.where("email", "==", normalizedEmail).limit(1).get();
    if (!emailQuery.empty) {
      const doc = emailQuery.docs[0];
      return {id: doc.id, data: doc.data()};
    }
  }

  // Try phone match
  if (row.phone) {
    const normalizedPhone = normalizePhone(row.phone);
    if (normalizedPhone) {
      const phoneQuery = await contactRef.where("phone", "==", normalizedPhone).limit(1).get();
      if (!phoneQuery.empty) {
        const doc = phoneQuery.docs[0];
        return {id: doc.id, data: doc.data()};
      }
    }
  }

  // Try company+name match
  if (companyId && row.firstName && row.lastName) {
    const allContacts = await contactRef.where("companyId", "==", companyId).limit(50).get();
    const normalizedFirst = row.firstName.toLowerCase().trim();
    const normalizedLast = row.lastName.toLowerCase().trim();

    for (const doc of allContacts.docs) {
      const data = doc.data();
      const docFirst = String(data.firstName || "").toLowerCase().trim();
      const docLast = String(data.lastName || "").toLowerCase().trim();

      if (docFirst === normalizedFirst && docLast === normalizedLast) {
        return {id: doc.id, data};
      }
    }
  }

  return null;
}

/**
 * Upsert contact based on match rules and duplicate handling
 */
async function upsertContact(
  db: FirebaseFirestore.Firestore,
  businessId: string,
  row: MultiEntityRow,
  companyId: string | undefined,
  companyName: string | undefined,
  duplicateHandling: DuplicateHandling,
  currentUserId: string,
  currentUserName: string,
  options: {allowEmailFallback?: boolean} = {}
): Promise<{id: string; created: boolean} | null> {
  const identity = resolveContactIdentity(row, options.allowEmailFallback);
  if (!identity) {
    return null;
  }

  const existing = await findContact(db, businessId, row, companyId);

  if (existing && duplicateHandling === "skip") {
    return {id: existing.id, created: false};
  }

  const contactData: EntityData = {
    firstName: identity.firstName,
    lastName: identity.lastName,
    email: identity.email,
    businessId,
    tags: row.tags || [],
    lifecycle: "active",
    ownerId: row.ownerId || currentUserId,
    ownerName: row.ownerName || currentUserName,
    teamIds: [],
    visibility: "team",
  };

  if (row.phone) {
    contactData.phone = normalizePhone(row.phone);
  }

  if (companyId) {
    contactData.companyId = companyId;
  }

  if (companyName) {
    contactData.companyName = companyName;
  }

  if (row.contactTitle) {
    contactData.title = row.contactTitle;
  }

  const normalizedLeadStatus = normalizeContactLeadStatus(row.contactLeadStatus);
  if (normalizedLeadStatus) {
    contactData.leadStatus = normalizedLeadStatus;
  }

  const hasAddress =
    row.street ||
    row.city ||
    row.state ||
    row.zipCode ||
    row.country;

  if (hasAddress) {
    contactData.address = {};
    if (row.street) contactData.address.street = row.street;
    if (row.city) contactData.address.city = row.city;
    if (row.state) contactData.address.state = row.state;
    if (row.zipCode) contactData.address.zipCode = row.zipCode;
    if (row.country) contactData.address.country = row.country;
  }

  const contactRef = db.collection("businesses").doc(businessId).collection(CONTACT_COLLECTION);

  if (existing && duplicateHandling === "update") {
    const updateData = {
      ...contactData,
      updatedAt: FieldValue.serverTimestamp(),
    };
    await contactRef.doc(existing.id).set(updateData, {merge: true});
    return {id: existing.id, created: false};
  }

  // Create new contact
  const newContactRef = contactRef.doc();
  await newContactRef.set({
    ...contactData,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return {id: newContactRef.id, created: true};
}

// ============================================
// Lead Creation/Update (only if leadStatus present)
// ============================================

/**
 * Find existing lead by email/phone (or name+company) in update mode
 */
async function findLead(
  db: FirebaseFirestore.Firestore,
  businessId: string,
  row: MultiEntityRow,
  companyId?: string
): Promise<{id: string; data: EntityData} | null> {
  const leadRef = db.collection("businesses").doc(businessId).collection("leads");

  // Try email match
  if (row.email) {
    const normalizedEmail = row.email.toLowerCase().trim();
    const emailQuery = await leadRef.where("email", "==", normalizedEmail).limit(1).get();
    if (!emailQuery.empty) {
      const doc = emailQuery.docs[0];
      return {id: doc.id, data: doc.data()};
    }
  }

  // Try phone match
  if (row.phone) {
    const normalizedPhone = normalizePhone(row.phone);
    if (normalizedPhone) {
      const phoneQuery = await leadRef.where("phone", "==", normalizedPhone).limit(1).get();
      if (!phoneQuery.empty) {
        const doc = phoneQuery.docs[0];
        return {id: doc.id, data: doc.data()};
      }
    }
  }

  // Try name+company match
  if (companyId && row.firstName && row.lastName) {
    const allLeads = await leadRef.limit(100).get();
    const normalizedFirst = row.firstName.toLowerCase().trim();
    const normalizedLast = row.lastName.toLowerCase().trim();

    for (const doc of allLeads.docs) {
      const data = doc.data();
      const docFirst = String(data.firstName || "").toLowerCase().trim();
      const docLast = String(data.lastName || "").toLowerCase().trim();
      const docCompany = String(data.companyName || "").toLowerCase().trim();
      const rowCompany = String(row.companyName || "").toLowerCase().trim();

      if (docFirst === normalizedFirst && docLast === normalizedLast && docCompany === rowCompany) {
        return {id: doc.id, data};
      }
    }
  }

  return null;
}

/**
 * Create or update lead ONLY if leadStatus is present
 */
async function upsertLead(
  db: FirebaseFirestore.Firestore,
  businessId: string,
  row: MultiEntityRow,
  companyId: string | undefined,
  companyName: string | undefined,
  duplicateHandling: DuplicateHandling,
  currentUserId: string,
  currentUserName: string,
  forceCreate = false
): Promise<{id: string; created: boolean} | null> {
  if (!forceCreate && !row.leadStatus) {
    return null;
  }

  // Parse name
  let firstName = row.firstName || "";
  let lastName = row.lastName || "";

  if (!firstName && !lastName && row.fullName) {
    const parsed = splitFullName(row.fullName);
    firstName = parsed.firstName;
    lastName = parsed.lastName;
  }

  if (!firstName || !lastName || !row.email) {
    return null; // Lead requires firstName, lastName, email
  }

  const existing = await findLead(db, businessId, row, companyId);

  if (existing && duplicateHandling === "skip") {
    return {id: existing.id, created: false};
  }

  const leadData: EntityData = {
    firstName: firstName.trim(),
    lastName: lastName.trim(),
    email: row.email.toLowerCase().trim(),
    status: row.leadStatus?.toLowerCase() || "new",
    source: row.leadSource || "other",
    businessId,
    tags: row.tags || [],
    ownerId: row.ownerId || currentUserId,
    ownerName: row.ownerName || currentUserName,
    teamIds: [],
    visibility: "team",
  };

  if (row.phone) {
    leadData.phone = normalizePhone(row.phone);
  }

  if (companyName) {
    leadData.companyName = companyName;
  }

  if (row.contactTitle) {
    leadData.title = row.contactTitle;
  }

  if (row.leadNotes) {
    leadData.notes = row.leadNotes;
  }

  const leadRef = db.collection("businesses").doc(businessId).collection("leads");

  if (existing && duplicateHandling === "update") {
    const updateData = {
      ...leadData,
      updatedAt: FieldValue.serverTimestamp(),
    };
    await leadRef.doc(existing.id).set(updateData, {merge: true});
    return {id: existing.id, created: false};
  }

  // Create new lead
  const newLeadRef = leadRef.doc();
  await newLeadRef.set({
    ...leadData,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return {id: newLeadRef.id, created: true};
}

// ============================================
// Deal Creation/Update (only if deal fields present)
// ============================================

/**
 * Find existing deal by title+company (or contact)+pipeline when update mode
 */
async function findDeal(
  db: FirebaseFirestore.Firestore,
  businessId: string,
  row: MultiEntityRow,
  companyId?: string,
  contactId?: string
): Promise<{id: string; data: EntityData} | null> {
  if (!row.dealTitle) {
    return null;
  }

  const dealRef = db.collection("businesses").doc(businessId).collection("deals");
  const normalizedTitle = row.dealTitle.toLowerCase().trim();

  // Try company+title match
  if (companyId) {
    const companyQuery = await dealRef.where("companyId", "==", companyId).limit(50).get();
    for (const doc of companyQuery.docs) {
      const data = doc.data();
      const docTitle = String(data.title || "").toLowerCase().trim();
      if (docTitle === normalizedTitle) {
        return {id: doc.id, data};
      }
    }
  }

  // Try contact+title match
  if (contactId) {
    const contactQuery = await dealRef.where("clientId", "==", contactId).limit(50).get();
    for (const doc of contactQuery.docs) {
      const data = doc.data();
      const docTitle = String(data.title || "").toLowerCase().trim();
      if (docTitle === normalizedTitle) {
        return {id: doc.id, data};
      }
    }
  }

  return null;
}

async function getDefaultPipeline(
  db: FirebaseFirestore.Firestore,
  businessId: string
): Promise<FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | null> {
  const pipelineRef = db.collection("businesses").doc(businessId).collection("pipelines");
  const defaultPipelineQuery = await pipelineRef.where("isDefault", "==", true).limit(1).get();

  if (!defaultPipelineQuery.empty) {
    return defaultPipelineQuery.docs[0];
  }

  const fallbackQuery = await pipelineRef.limit(1).get();
  return fallbackQuery.empty ? null : fallbackQuery.docs[0];
}

async function findPipelineByName(
  db: FirebaseFirestore.Firestore,
  businessId: string,
  pipelineName: string
): Promise<FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | null> {
  if (!pipelineName) return null;

  const pipelineRef = db.collection("businesses").doc(businessId).collection("pipelines");
  const snapshot = await pipelineRef.limit(50).get();
  const target = pipelineName.toLowerCase().trim();

  for (const doc of snapshot.docs) {
    const name = String(doc.data().name || "").toLowerCase().trim();
    if (name === target) {
      return doc;
    }
  }

  return null;
}

async function pickStageForPipeline(
  db: FirebaseFirestore.Firestore,
  businessId: string,
  pipelineId: string,
  stageName?: string
): Promise<{stageId: string; probability: number} | null> {
  const stageRef = db.collection("businesses").doc(businessId).collection("stages");
  const stageQuery = await stageRef
    .where("pipelineId", "==", pipelineId)
    .orderBy("order", "asc")
    .limit(50)
    .get();

  if (stageQuery.empty) {
    return null;
  }

  const target = stageName ? stageName.toLowerCase().trim() : null;
  if (target) {
    const matched = stageQuery.docs.find((doc) => String(doc.data().name || "").toLowerCase().trim() === target);
    if (matched) {
      const probability = matched.data().probability || 0;
      return {stageId: matched.id, probability};
    }
  }

  const firstStage = stageQuery.docs[0];
  const probability = firstStage.data().probability || 0;
  return {stageId: firstStage.id, probability};
}

/**
 * Create or update deal ONLY if deal fields are present
 */
async function upsertDeal(
  db: FirebaseFirestore.Firestore,
  businessId: string,
  row: MultiEntityRow,
  companyId: string | undefined,
  companyName: string | undefined,
  contactId: string | undefined,
  contactName: string | undefined,
  duplicateHandling: DuplicateHandling,
  currentUserId: string,
  currentUserName: string
): Promise<{id: string; created: boolean} | null> {
  // Only create/update deal if title is present
  if (!row.dealTitle) {
    return null;
  }

  // Resolve pipeline/stage (use provided names when present, otherwise fall back to defaults)
  const pipelineDoc =
    (row.dealPipelineName && (await findPipelineByName(db, businessId, row.dealPipelineName))) ||
    (await getDefaultPipeline(db, businessId));

  if (!pipelineDoc) {
    return null;
  }

  const stageInfo = await pickStageForPipeline(db, businessId, pipelineDoc.id, row.dealStageName);
  if (!stageInfo) {
    return null;
  }

  const existing = await findDeal(db, businessId, row, companyId, contactId);

  if (existing && duplicateHandling === "skip") {
    return {id: existing.id, created: false};
  }

  const dealData: EntityData = {
    pipelineId: pipelineDoc.id,
    stageId: stageInfo.stageId,
    title: row.dealTitle.trim(),
    valueCents: row.dealValueCents || 0,
    currency: "USD",
    probability: stageInfo.probability,
    status: "open",
    businessId,
    tags: row.tags || [],
    ownerId: row.ownerId || currentUserId,
    ownerName: row.ownerName || currentUserName,
    teamIds: [],
    visibility: "team",
  };

  if (companyId) {
    dealData.companyId = companyId;
  }

  if (companyName) {
    dealData.companyName = companyName;
  }

  if (contactId) {
    dealData.clientId = contactId;
  }

  if (contactName) {
    dealData.clientName = contactName;
  }

  if (row.email) {
    dealData.clientEmail = row.email.toLowerCase().trim();
  }

  if (row.dealExpectedCloseDate) {
    dealData.expectedCloseDate = row.dealExpectedCloseDate;
  }

  if (row.dealNotes) {
    dealData.notes = row.dealNotes;
  }

  const dealRef = db.collection("businesses").doc(businessId).collection("deals");

  if (existing && duplicateHandling === "update") {
    const updateData = {
      ...dealData,
      updatedAt: FieldValue.serverTimestamp(),
    };
    await dealRef.doc(existing.id).set(updateData, {merge: true});
    return {id: existing.id, created: false};
  }

  // Create new deal
  const newDealRef = dealRef.doc();
  await newDealRef.set({
    ...dealData,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return {id: newDealRef.id, created: true};
}

// ============================================
// Main Multi-Entity Import Function
// ============================================

/**
 * Process a single row of multi-entity import
 * Creates/updates Company, Contact, optional Lead, and optional Deal
 */
export async function processMultiEntityRow(
  db: FirebaseFirestore.Firestore,
  businessId: string,
  row: MultiEntityRow,
  duplicateHandling: DuplicateHandling,
  currentUserId: string,
  currentUserName: string,
  primaryEntityType: MultiEntityPrimaryType = "contact"
): Promise<MultiEntityImportResult> {
  const result: MultiEntityImportResult = {
    companyCreated: false,
    contactCreated: false,
    leadCreated: false,
    dealCreated: false,
    skipped: false,
  };

  try {
    const resolvedCompanyName =
      row.companyName ||
      row.companyDomain ||
      normalizeDomain(row.companyWebsite || row.companyEmail || "") ||
      undefined;
    const shouldCreateCompany = hasCompanySeed(row);
    const shouldCreateContact =
      primaryEntityType === "contact" ||
      (primaryEntityType === "deal" && hasContactSeed(row));
    const shouldCreateLead = primaryEntityType === "lead";
    const shouldCreateDeal = primaryEntityType === "deal" || row.dealTitle !== undefined;

    // Step 1: Upsert company (if company fields present)
    const companyResult = shouldCreateCompany
      ? await upsertCompany(
          db,
          businessId,
          row,
          duplicateHandling,
          currentUserId,
          currentUserName
        )
      : null;

    if (companyResult) {
      result.companyId = companyResult.id;
      result.companyCreated = companyResult.created;
    }

    if (primaryEntityType === "company" && !companyResult) {
      result.skipped = true;
      result.error = "Company requires a name or domain";
      return result;
    }

    // Step 2: Upsert contact when the primary import needs it or when deal linking can use it.
    const contactResult = shouldCreateContact
      ? await upsertContact(
          db,
          businessId,
          row,
          companyResult?.id,
          resolvedCompanyName,
          duplicateHandling,
          currentUserId,
          currentUserName,
          {allowEmailFallback: primaryEntityType === "deal"}
        )
      : null;

    if (primaryEntityType === "contact" && !contactResult) {
      result.skipped = true;
      result.error = "Contact requires firstName, lastName, and email";
      return result;
    }

    if (contactResult) {
      result.contactId = contactResult.id;
      result.contactCreated = contactResult.created;
    }

    const contactIdentity =
      contactResult && (primaryEntityType === "deal" || primaryEntityType === "contact")
        ? resolveContactIdentity(row, primaryEntityType === "deal")
        : null;
    const contactFullName =
      contactIdentity
        ? `${contactIdentity.firstName} ${contactIdentity.lastName}`.trim()
        : formatContactName(row);

    // Step 3: Create/update lead when lead import is the primary path.
    const leadResult = shouldCreateLead
      ? await upsertLead(
          db,
          businessId,
          row,
          companyResult?.id,
          resolvedCompanyName,
          duplicateHandling,
          currentUserId,
          currentUserName,
          true
        )
      : null;

    if (leadResult) {
      result.leadId = leadResult.id;
      result.leadCreated = leadResult.created;
    }

    if (primaryEntityType === "lead" && !leadResult) {
      result.skipped = true;
      result.error = "Lead requires firstName, lastName, and email";
      return result;
    }

    if (primaryEntityType === "deal" && !contactResult && !companyResult) {
      result.skipped = true;
      result.error = "Provide a contact (email/name) or company to link this opportunity";
      return result;
    }

    // Step 4: Create/update deal when the primary import is a deal or contact rows include deal fields.
    const dealResult = shouldCreateDeal
      ? await upsertDeal(
          db,
          businessId,
          row,
          companyResult?.id,
          resolvedCompanyName,
          contactResult?.id,
          contactFullName,
          duplicateHandling,
          currentUserId,
          currentUserName
        )
      : null;

    if (dealResult) {
      result.dealId = dealResult.id;
      result.dealCreated = dealResult.created;
    }

    if (primaryEntityType === "deal" && !dealResult) {
      result.skipped = true;
      result.error = "Deal requires title and a valid pipeline or stage configuration";
      return result;
    }

    return result;
  } catch (error) {
    result.skipped = true;
    result.error = error instanceof Error ? error.message : "Unknown error";
    return result;
  }
}
