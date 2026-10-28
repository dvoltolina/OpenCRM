import Papa from 'papaparse';
import type { LeadStatus, LeadSource, ContactLeadStatus } from '../types/models';

export interface ImportConfig {
  entityType: 'lead' | 'contact' | 'deal' | 'company' | 'client' | 'appointment';
  fieldMapping: Record<string, string>;  // csvColumn -> entityField
  skipFirstRow: boolean;
  duplicateHandling: 'skip' | 'update' | 'create';
  /** When true, performs validation without writing any data */
  dryRun?: boolean;
  /** When true, stops the import if any validation errors are found */
  stopOnError?: boolean;
  /** Optional existing identifier sets to block imports that collide with current data */
  existingIdentifiers?: ExistingIdentifiers;
}

export interface ImportResult {
  totalRows: number;
  imported: number;
  skipped: number;
  errors: { row: number; error: string }[];
  dryRun?: boolean;
}

export interface ParsedCSV {
  headers: string[];
  rows: string[][];
}

export interface ValidationError {
  row: number;
  field: string;
  error: string;
}

export interface ExistingIdentifiers {
  emails?: string[];
  phones?: string[];
}

interface EntityData {
  [key: string]: any;
}

// Required fields for each entity type
// Note: deal now requires title (valueCents optional, clientEmail recommended for linking)
const REQUIRED_FIELDS: Record<string, string[]> = {
  lead: ['firstName'],
  contact: ['firstName', 'lastName', 'email'],
  client: ['firstName', 'lastName', 'email'],
  deal: ['title'], // valueCents optional, clientEmail recommended for contact linking
  company: ['name'],
  appointment: ['startTime', 'clientEmail'],
};

// Available fields for mapping
export const AVAILABLE_FIELDS: Record<string, { label: string; required: boolean }[]> = {
  lead: [
    { label: 'firstName', required: true },
    { label: 'lastName', required: false },
    { label: 'email', required: false },
    { label: 'phone', required: false },
    { label: 'companyName', required: false },
    { label: 'title', required: false },
    { label: 'industry', required: false },
    { label: 'address', required: false },
    { label: 'street', required: false },
    { label: 'city', required: false },
    { label: 'state', required: false },
    { label: 'zipCode', required: false },
    { label: 'website', required: false },
    { label: 'size', required: false },
    { label: 'source', required: false },
    { label: 'status', required: false },
    { label: 'score', required: false },
    { label: 'notes', required: false },
    { label: 'tags', required: false },
    { label: 'lat', required: false },
    { label: 'lng', required: false },
  ],
  contact: [
    { label: 'firstName', required: true },
    { label: 'lastName', required: true },
    { label: 'email', required: true },
    { label: 'phone', required: false },
    { label: 'companyName', required: false },
    { label: 'title', required: false },
    { label: 'address', required: false },
    { label: 'street', required: false },
    { label: 'city', required: false },
    { label: 'state', required: false },
    { label: 'zipCode', required: false },
    { label: 'country', required: false },
    { label: 'leadStatus', required: false }, // New, Working, Qualified, Unqualified, Nurturing
    { label: 'assignedRepEmail', required: false }, // For assigning contacts to reps
    // Optional deal fields (multi-entity import)
    { label: 'dealTitle', required: false },
    { label: 'dealValueCents', required: false },
    { label: 'dealExpectedCloseDate', required: false },
    { label: 'dealNotes', required: false },
    { label: 'pipelineName', required: false },
    { label: 'stageName', required: false },
    { label: 'tags', required: false },
  ],
  deal: [
    { label: 'title', required: true },
    { label: 'valueCents', required: false },
    { label: 'clientEmail', required: false }, // Used to auto-link to existing Contact or create new
    { label: 'clientName', required: false },
    { label: 'companyName', required: false },
    { label: 'companyDomain', required: false },
    { label: 'pipelineName', required: false },
    { label: 'stageName', required: false },
    { label: 'expectedCloseDate', required: false },
    { label: 'notes', required: false },
    { label: 'assignedRepEmail', required: false }, // For assigning opportunities to reps
    { label: 'tags', required: false },
  ],
  company: [
    { label: 'name', required: true },
    { label: 'industry', required: false },
    { label: 'size', required: false },
    { label: 'website', required: false },
    { label: 'companyDomain', required: false },
    { label: 'phone', required: false },
    { label: 'email', required: false },
    { label: 'address', required: false },
    { label: 'notes', required: false },
    { label: 'tags', required: false }
  ],
  client: [
    { label: 'firstName', required: true },
    { label: 'lastName', required: true },
    { label: 'email', required: true },
    { label: 'phone', required: false },
    { label: 'lifecycle', required: false },
    { label: 'tags', required: false },
    { label: 'leadSource', required: false },
    { label: 'crmNotes', required: false },
  ],
  appointment: [
    { label: 'clientEmail', required: true },
    { label: 'clientName', required: false },
    { label: 'providerName', required: false },
    { label: 'serviceName', required: false },
    { label: 'startTime', required: true },
    { label: 'endTime', required: false },
    { label: 'status', required: false },
    { label: 'location', required: false },
  ],
};

/**
 * Parse a CSV file and extract headers and rows
 */
export async function parseCSV(file: File): Promise<ParsedCSV> {
  return new Promise((resolve, reject) => {
    Papa.parse(file, {
      complete: (results) => {
        if (results.errors.length > 0) {
          reject(new Error(`CSV parsing failed: ${results.errors[0].message}`));
          return;
        }

        const data = results.data as string[][];
        if (data.length === 0) {
          reject(new Error('CSV file is empty'));
          return;
        }

        const headers = data[0];
        const rows = data.slice(1).filter(row => row.some(cell => cell.trim() !== ''));

        resolve({ headers, rows });
      },
      error: (error) => {
        reject(new Error(`CSV parsing error: ${error.message}`));
      }
    });
  });
}

/**
 * Calculate similarity between two strings (Levenshtein-based)
 */
function stringSimilarity(a: string, b: string): number {
  const aLower = a.toLowerCase().trim();
  const bLower = b.toLowerCase().trim();
  const aCompact = aLower.replace(/[\s_-]+/g, '');
  const bCompact = bLower.replace(/[\s_-]+/g, '');

  if (aLower === bLower || aCompact === bCompact) return 1;
  if (
    aLower.includes(bLower) ||
    bLower.includes(aLower) ||
    aCompact.includes(bCompact) ||
    bCompact.includes(aCompact)
  ) {
    return 0.8;
  }

  // Simple word overlap check
  const aWords = aLower.split(/[\s_-]+/);
  const bWords = bLower.split(/[\s_-]+/);
  const commonWords = aWords.filter(w => bWords.includes(w));
  if (commonWords.length > 0) {
    return 0.6 + (0.3 * commonWords.length / Math.max(aWords.length, bWords.length));
  }

  return 0;
}

/**
 * Extended field aliases with more variations
 */
const FIELD_ALIASES: Record<string, string[]> = {
  firstName: [
    'first name', 'firstname', 'first', 'given name', 'givenname',
    'fname', 'f_name', 'first_name', 'forename', 'nombre'
  ],
  lastName: [
    'last name', 'lastname', 'last', 'surname', 'family name', 'familyname',
    'lname', 'l_name', 'last_name', 'apellido'
  ],
  fullName: [ // Virtual field - will be split into firstName + lastName
    'full name', 'fullname', 'name', 'contact name', 'contact', 'client name',
    'customer name', 'person', 'full_name', 'nombre completo'
  ],
  email: [
    'email', 'e-mail', 'email address', 'emailaddress', 'e_mail', 'mail',
    'email_address', 'correo', 'contact email', 'primary email', 'work email'
  ],
  phone: [
    'phone', 'telephone', 'mobile', 'phone number', 'phonenumber', 'tel',
    'cell', 'cellphone', 'mobile phone', 'work phone', 'primary phone',
    'phone_number', 'contact phone', 'telefono', 'number'
  ],
  companyName: [
    'company', 'company name', 'organization', 'org', 'business',
    'business name', 'employer', 'workplace', 'company_name', 'organisation',
    'firm', 'enterprise', 'empresa'
  ],
  name: ['name', 'company name', 'organization name', 'business name', 'title'],
  title: [
    'title', 'job title', 'position', 'role', 'job', 'designation',
    'job_title', 'occupation', 'job role', 'puesto', 'cargo'
  ],
  address: [
    'address', 'street', 'location', 'street address', 'full address',
    'mailing address', 'postal address', 'direccion', 'address1', 'address_1'
  ],
  street: [
    'street', 'street address', 'address line 1', 'addr1', 'address1', 'line1', 'address line1'
  ],
  city: ['city', 'town', 'municipality', 'ciudad'],
  state: ['state', 'province', 'region', 'estado'],
  zipCode: ['zip', 'zipcode', 'postal code', 'zip code', 'postcode', 'postal'],
  country: ['country', 'nation'],
  source: [
    'source', 'lead source', 'origin', 'how did you hear', 'referral source',
    'lead_source', 'acquisition', 'channel', 'marketing source', 'fuente'
  ],
  status: ['status', 'lead status', 'state', 'stage', 'estado'],
  notes: [
    'notes', 'note', 'comments', 'description', 'remarks', 'memo',
    'additional info', 'details', 'notas', 'comentarios'
  ],
  clientName: ['client', 'client name', 'customer', 'customer name', 'account'],
  stageName: ['stage', 'deal stage', 'pipeline stage', 'sales stage', 'opportunity stage'],
  valueCents: [
    'value', 'amount', 'deal value', 'price', 'revenue', 'worth',
    'deal amount', 'opportunity value', 'total', 'sum', 'valor', 'monto'
  ],
  expectedCloseDate: [
    'close date', 'expected close', 'closing date', 'exp close', 'due date',
    'target date', 'expected close date', 'close_date', 'fecha cierre'
  ],
  industry: ['industry', 'sector', 'business type', 'vertical', 'industria'],
  size: ['size', 'company size', 'org size', 'employees', 'employee count', 'headcount'],
  website: ['website', 'url', 'web', 'site', 'homepage', 'web address', 'sitio web'],
  companyDomain: ['domain', 'company domain', 'web domain', 'website domain', 'business domain'],
  lifecycle: ['lifecycle', 'customer status', 'client status', 'stage'],
  leadSource: ['source', 'lead source', 'origin', 'referral', 'how found'],
  tags: ['tags', 'labels', 'categories', 'keywords', 'etiquetas', 'segments', 'group'],
  clientEmail: ['client email', 'customer email', 'contact email', 'account email', 'client_email', 'contact_email'],
  providerName: ['provider', 'staff', 'assignee', 'owner', 'assigned to', 'rep', 'sales rep'],
  leadStatus: ['lead status', 'leadstatus', 'lead_status', 'status', 'lead stage', 'funnel status'],
  assignedRepEmail: ['assigned rep', 'rep email', 'sales rep email', 'assignee email', 'owner email', 'assigned_to_email', 'rep_email'],
  serviceName: ['service', 'appointment type', 'session type', 'service type', 'product'],
  startTime: ['start', 'start time', 'begin', 'start date', 'begins', 'from', 'inicio'],
  endTime: ['end', 'end time', 'finish', 'end date', 'ends', 'to', 'fin'],
  location: ['location', 'address', 'room', 'venue', 'place', 'ubicacion'],
  pipelineName: ['pipeline', 'pipeline name', 'sales pipeline', 'funnel'],
  dealTitle: ['deal title', 'opportunity title', 'opportunity', 'deal', 'opportunity name'],
  dealNotes: ['deal notes', 'opportunity notes', 'deal description', 'opportunity description'],
  dealExpectedCloseDate: [
    'expected close date', 'close date', 'deal close date', 'opportunity close date', 'expected close'
  ],
  dealValueCents: [
    'deal value', 'opportunity value', 'deal amount', 'opportunity amount', 'deal total', 'opportunity total'
  ],
  lat: ['lat', 'latitude', 'geo lat'],
  lng: ['lng', 'lon', 'longitude', 'geo lng', 'geo lon'],
};

export interface MappingConfidence {
  field: string;
  confidence: number; // 0-1
  needsTransform?: 'splitName' | 'normalizePhone' | 'parseDate' | 'parseCurrency';
}

/**
 * Auto-detect field mappings based on column names with confidence scores
 */
export function autoDetectMapping(headers: string[], entityType: string): Record<string, string> {
  const result = autoDetectMappingWithConfidence(headers, entityType);
  const mapping: Record<string, string> = {};

  for (const [header, conf] of Object.entries(result.mappings)) {
    if (conf.field) {
      mapping[header] = conf.field;
    }
  }

  return mapping;
}

/**
 * Auto-detect field mappings with confidence scores
 */
export function autoDetectMappingWithConfidence(
  headers: string[],
  entityType: string
): {
  mappings: Record<string, MappingConfidence>;
  overallConfidence: number;
  hasFullName: boolean;
  fullNameColumn?: string;
} {
  const mappings: Record<string, MappingConfidence> = {};
  const availableFields = AVAILABLE_FIELDS[entityType]?.map(f => f.label) || [];
  const usedFields = new Set<string>();
  let hasFullName = false;
  let fullNameColumn: string | undefined;

  // First pass: find exact and high-confidence matches
  for (const header of headers) {
    const normalized = header.toLowerCase().trim().replace(/[_-]/g, ' ');
    let bestMatch: MappingConfidence = { field: '', confidence: 0 };

    // Check against all field aliases
    for (const [field, aliases] of Object.entries(FIELD_ALIASES)) {
      // Handle fullName specially
      let targetField = field;
      if (field === 'fullName') {
        // For entities without first/last (e.g., deals, appointments), map to clientName instead of splitting
        if (availableFields.includes('firstName') || availableFields.includes('lastName')) {
          targetField = 'firstName';
        } else if (availableFields.includes('clientName')) {
          targetField = 'clientName';
        } else {
          continue; // no suitable target
        }
      } else if (!availableFields.includes(field)) {
        continue;
      }

      // Full-name aliases can target firstName/clientName, so guard the eventual target too.
      if (usedFields.has(field) || usedFields.has(targetField)) continue;

      for (const alias of aliases) {
        const similarity = stringSimilarity(normalized, alias);
        if (similarity > bestMatch.confidence) {
          if (field === 'fullName') {
            if (targetField === 'firstName') {
              bestMatch = { field: 'firstName', confidence: similarity, needsTransform: 'splitName' };
              hasFullName = true;
              fullNameColumn = header;
            } else {
              bestMatch = { field: targetField, confidence: similarity };
            }
          } else {
            bestMatch = { field, confidence: similarity };

            // Add transform hints
            if (field === 'phone') bestMatch.needsTransform = 'normalizePhone';
            if (field.includes('Date') || field.includes('Time')) bestMatch.needsTransform = 'parseDate';
            if (field === 'valueCents') bestMatch.needsTransform = 'parseCurrency';
          }
        }
      }
    }

    // Guard: if a "name" column was leaning toward lastName or empty, coerce to fullName split
    if ((bestMatch.field === '' || bestMatch.field === 'lastName') && availableFields.includes('firstName')) {
      const fullNameAliases = FIELD_ALIASES.fullName || [];
      const matchesFullName = fullNameAliases.some((alias) => stringSimilarity(normalized, alias) >= 0.9);
      if (matchesFullName) {
        bestMatch = { field: 'firstName', confidence: 1, needsTransform: 'splitName' };
        hasFullName = true;
        fullNameColumn = header;
      }
    }

    // Only accept matches with reasonable confidence
    if (bestMatch.confidence >= 0.5) {
      mappings[header] = bestMatch;
      usedFields.add(bestMatch.field);
    } else {
      mappings[header] = { field: '', confidence: 0 };
    }
  }

  // If we have fullName, mark lastName as fulfilled too (will be split from fullName)
  if (hasFullName) {
    usedFields.add('lastName');
  }

  // Calculate overall confidence
  const requiredFields = REQUIRED_FIELDS[entityType] || [];
  const mappedRequired = requiredFields.filter(f => usedFields.has(f));
  const overallConfidence = requiredFields.length > 0
    ? mappedRequired.length / requiredFields.length
    : 1;

  return { mappings, overallConfidence, hasFullName, fullNameColumn };
}

/**
 * Check if import can proceed automatically (high confidence mapping)
 */
export function canAutoImport(headers: string[], entityType: string): boolean {
  const { overallConfidence } = autoDetectMappingWithConfidence(headers, entityType);
  return overallConfidence >= 1.0; // All required fields must be mapped
}

/**
 * Split a full name into first and last name
 */
export function splitFullName(fullName: string): { firstName: string; lastName: string } {
  if (!fullName || typeof fullName !== 'string') {
    return { firstName: '', lastName: '' };
  }

  const trimmed = fullName.trim();
  const parts = trimmed.split(/\s+/);

  if (parts.length === 0) {
    return { firstName: '', lastName: '' };
  }

  if (parts.length === 1) {
    return { firstName: parts[0], lastName: '' };
  }

  // Handle common patterns
  // "John Smith" -> John, Smith
  // "John van der Berg" -> John, van der Berg
  // "Dr. John Smith" -> John, Smith (skip titles)
  const titles = ['mr', 'mrs', 'ms', 'miss', 'dr', 'prof', 'sir', 'madam'];
  let startIdx = 0;

  if (titles.includes(parts[0].toLowerCase().replace('.', ''))) {
    startIdx = 1;
  }

  if (startIdx >= parts.length) {
    return { firstName: trimmed, lastName: '' };
  }

  const firstName = parts[startIdx];
  const lastName = parts.slice(startIdx + 1).join(' ');

  return { firstName, lastName };
}

/**
 * Smart transform row data based on detected patterns
 */
export function smartTransformRow(
  row: string[],
  headers: string[],
  entityType: string,
  mappingResult: ReturnType<typeof autoDetectMappingWithConfidence>
): Record<string, any> {
  const data: Record<string, any> = {};

  headers.forEach((header, index) => {
    const mapping = mappingResult.mappings[header];
    if (!mapping || !mapping.field) return;

    let value = row[index]?.trim() || '';
    if (!value) return;

    // Apply transforms
    if (mapping.needsTransform === 'splitName' && header === mappingResult.fullNameColumn) {
      const { firstName, lastName } = splitFullName(value);
      data.firstName = firstName;
      data.lastName = lastName;
      return;
    }

    if (mapping.needsTransform === 'normalizePhone') {
      value = normalizePhone(value);
    }

    if (mapping.needsTransform === 'parseCurrency') {
      const cents = parseMonetaryValue(value, header);
      data[mapping.field] = cents ?? 0;
      return;
    }

    if (mapping.needsTransform === 'parseDate') {
      const date = parseDate(value);
      data[mapping.field] = date ?? undefined;
      return;
    }

    // Standard field assignment
    if (mapping.field === 'email') {
      data[mapping.field] = value.toLowerCase();
    } else {
      data[mapping.field] = value;
    }
  });

  // Set defaults
  if (entityType === 'lead') {
    data.status = data.status || 'new';
    data.source = data.source || 'other';
    data.tags = data.tags || [];
  } else if (entityType === 'deal') {
    data.valueCents = data.valueCents || 0;
    data.tags = data.tags || [];
    data.status = 'open';
  } else if (entityType === 'contact' || entityType === 'client') {
    data.tags = data.tags || [];
  }

  return data;
}

/**
 * Validate email format
 */
function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

const PHONE_REGEX = /^[+]?[\d\s\-().]+$/;
const MIN_PHONE_DIGITS = 7;

/**
 * Normalize phone number for comparison and storage (digits only).
 * Removing formatting characters and leading '+' keeps duplicate checks consistent
 * with repository normalization.
 */
function normalizePhone(phone?: string): string {
  if (!phone) return '';
  return phone.replace(/\D/g, '');
}

function hasSufficientDigits(phone: string): boolean {
  const digitsOnly = phone.replace(/\D/g, '');
  return digitsOnly.length >= MIN_PHONE_DIGITS;
}

/**
 * Parse date from various formats
 */
function parseDate(dateStr: string): Date | null {
  if (!dateStr) return null;

  const date = new Date(dateStr);
  if (!isNaN(date.getTime())) {
    return date;
  }

  // Try common formats
  const formats = [
    /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/,  // MM/DD/YYYY
    /^(\d{4})-(\d{2})-(\d{2})$/,         // YYYY-MM-DD
    /^(\d{1,2})-(\d{1,2})-(\d{4})$/      // DD-MM-YYYY
  ];

  for (const format of formats) {
    const match = dateStr.match(format);
    if (match) {
      const parsed = new Date(dateStr);
      if (!isNaN(parsed.getTime())) {
        return parsed;
      }
    }
  }

  return null;
}

/**
 * Parse currency value to cents
 */
function parseCurrency(value: string): number | null {
  if (!value) return null;

  // Remove currency symbols and commas
  const cleaned = value.replace(/[$,£€]/g, '').trim();
  const num = parseFloat(cleaned);

  if (isNaN(num)) return null;

  // Convert to cents
  return Math.round(num * 100);
}

function parseMonetaryValue(value: string, header: string): number | null {
  if (!value) return null;

  const normalizedHeader = header.toLowerCase().replace(/[\s_-]+/g, '');
  if (normalizedHeader.includes('cents')) {
    const cleaned = value.replace(/[^0-9.-]+/g, '').trim();
    if (!cleaned || cleaned === '-' || cleaned === '.' || cleaned === '-.') {
      return null;
    }

    const amount = Number(cleaned);
    return Number.isNaN(amount) ? null : Math.round(amount);
  }

  return parseCurrency(value);
}

/**
 * Validate a single row of data
 */
export function validateRow(
  row: string[],
  headers: string[],
  entityType: string,
  fieldMapping: Record<string, string>
): ValidationError[] {
  const errors: ValidationError[] = [];
  const rowData: EntityData = {};

  // Check if we have fullName that will be split
  const detection = autoDetectMappingWithConfidence(headers, entityType);
  const hasFullNameSplit = detection.hasFullName;
  let fullNameValue = '';
  let valueCentsHeader = '';

  // Map CSV columns to entity fields
  headers.forEach((header, index) => {
    const field = fieldMapping[header];
    const value = row[index]?.trim() || '';

    // Check if this is the fullName column
    if (header === detection.fullNameColumn && detection.hasFullName) {
      fullNameValue = value;
      const { firstName, lastName } = splitFullName(value);
      rowData['firstName'] = firstName;
      rowData['lastName'] = lastName;
    } else if (field) {
      rowData[field] = value;
      if (field === 'valueCents') {
        valueCentsHeader = header;
      }
    }
  });

  // Check required fields
  const requiredFields = REQUIRED_FIELDS[entityType] || [];
  requiredFields.forEach((field) => {
    // Skip lastName check if we're splitting from fullName and have a value
    if (field === 'lastName' && hasFullNameSplit && fullNameValue) {
      const { lastName } = splitFullName(fullNameValue);
      if (lastName) return; // Valid, skip error
    }

    if (!rowData[field] || rowData[field] === '') {
      errors.push({
        row: 0, // Will be set by caller
        field,
        error: `Required field '${field}' is missing or empty`
      });
    }
  });

  // Validate email format
  if (rowData.email && !isValidEmail(rowData.email)) {
    errors.push({
      row: 0,
      field: 'email',
      error: 'Invalid email format'
    });
  }

  if (rowData.phone && !PHONE_REGEX.test(rowData.phone)) {
    errors.push({
      row: 0,
      field: 'phone',
      error: 'Invalid phone format'
    });
  } else if (rowData.phone) {
    const normalized = normalizePhone(rowData.phone);
    if (!hasSufficientDigits(normalized)) {
      errors.push({
        row: 0,
        field: 'phone',
        error: `Phone number must include at least ${MIN_PHONE_DIGITS} digits`,
      });
    }
  }

  // Validate specific fields based on entity type
  if (entityType === 'deal') {
    if (rowData.valueCents) {
      const value = parseMonetaryValue(rowData.valueCents, valueCentsHeader);
      if (value === null) {
        errors.push({
          row: 0,
          field: 'valueCents',
          error: 'Invalid currency value'
        });
      }
    }

    if (rowData.expectedCloseDate) {
      const date = parseDate(rowData.expectedCloseDate);
      if (date === null) {
        errors.push({
          row: 0,
          field: 'expectedCloseDate',
          error: 'Invalid date format'
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
        field: 'clientEmail',
        error: 'Provide a contact (email/name) or company to link this opportunity',
      });
    }
  }

  if (entityType === 'appointment') {
    if (rowData.startTime) {
      const date = parseDate(rowData.startTime);
      if (date === null) {
        errors.push({
          row: 0,
          field: 'startTime',
          error: 'Invalid start time format',
        });
      }
    }
    if (rowData.endTime) {
      const date = parseDate(rowData.endTime);
      if (date === null) {
        errors.push({
          row: 0,
          field: 'endTime',
          error: 'Invalid end time format',
        });
      }
    }
  }

  return errors;
}

/**
 * Transform CSV row data into entity data
 */
function transformRowData(
  row: string[],
  headers: string[],
  entityType: string,
  fieldMapping: Record<string, string>,
  businessId: string
): EntityData {
  const data: EntityData = {
    businessId,
    createdAt: new Date(),
    updatedAt: new Date()
  };

  const ensureAddress = () => {
    if (!data.address) {
      data.address = {};
    }
  };

  headers.forEach((header, index) => {
    const field = fieldMapping[header];
    const value = row[index]?.trim() || '';

    if (!field || !value) return;

    // Transform based on field type
    switch (field) {
      case 'email':
        data[field] = value.toLowerCase();
        break;
      case 'phone':
        data[field] = normalizePhone(value);
        break;
      case 'valueCents':
        data[field] = parseMonetaryValue(value, header) || 0;
        break;
      case 'expectedCloseDate': {
        const date = parseDate(value);
        data[field] = date || undefined;
        break;
      }
      case 'status':
        // Validate status value for leads
        if (entityType === 'lead') {
          const validStatuses: LeadStatus[] = ['new', 'contacted', 'qualified', 'unqualified', 'converted'];
          data[field] = validStatuses.includes(value.toLowerCase() as LeadStatus)
            ? value.toLowerCase()
            : 'new';
        } else {
          data[field] = value;
        }
        break;
      case 'stageName':
        // For deals, we'll just store the stage name and let the import handler resolve it
        data[field] = value;
        break;
      case 'dealTitle':
        data[field] = value;
        break;
      case 'dealExpectedCloseDate': {
        const date = parseDate(value);
        data[field] = date || undefined;
        break;
      }
      case 'dealNotes':
        data[field] = value;
        break;
      case 'source':
        // Validate source value for leads
        if (entityType === 'lead') {
          const validSources: LeadSource[] = ['website', 'referral', 'coldCall', 'social', 'event', 'scheduler', 'other'];
          data[field] = validSources.includes(value as LeadSource) ? value : 'other';
        } else {
          data[field] = value;
        }
        break;
      case 'startTime':
      case 'endTime':
        data[field] = parseDate(value) || undefined;
        break;
      case 'clientEmail':
        data[field] = value.toLowerCase();
        break;
      case 'companyDomain':
        data[field] = value.toLowerCase();
        break;
      case 'address':
      case 'street':
        ensureAddress();
        data.address.street = value;
        break;
      case 'city':
        ensureAddress();
        data.address.city = value;
        break;
      case 'state':
        ensureAddress();
        data.address.state = value;
        break;
      case 'zipCode':
        ensureAddress();
        data.address.zipCode = value;
        break;
      case 'country':
        ensureAddress();
        data.address.country = value;
        break;
      case 'tags': {
        const tags = value
          .split(/[,;]+/)
          .map((tag) => tag.trim())
          .filter(Boolean);
        data[field] = tags;
        break;
      }
      default:
        data[field] = value;
    }
  });

  // Set defaults for required fields
  if (entityType === 'lead') {
    data.status = data.status || 'new';
    data.source = data.source || 'other';
    data.tags = data.tags || [];
  } else if (entityType === 'deal') {
    data.valueCents = data.valueCents || 0;
    data.tags = data.tags || [];
    data.status = 'open';
    // Note: clientEmail linking is handled by the import handler, not here
    // The handler will lookup/create contacts before creating the opportunity
  } else if (entityType === 'contact' || entityType === 'client') {
    data.tags = data.tags || [];
    data.lifecycle = data.lifecycle || 'active';
    // Validate and normalize leadStatus if provided
    if (data.leadStatus) {
      const normalizedStatus = normalizeLeadStatus(data.leadStatus);
      data.leadStatus = normalizedStatus;
    }
  } else if (entityType === 'company') {
    data.tags = data.tags || [];
  } else if (entityType === 'appointment') {
    data.status = data.status || 'scheduled';
  }

  return data;
}

/**
 * Normalize lead status value to match ContactLeadStatus type
 * Accepts various case formats and returns properly cased value
 */
function normalizeLeadStatus(value: string): ContactLeadStatus | null {
  if (!value) return null;
  const normalized = value.trim().toLowerCase();

  const statusMap: Record<string, ContactLeadStatus> = {
    'new': 'New',
    'working': 'Working',
    'qualified': 'Qualified',
    'unqualified': 'Unqualified',
    'nurturing': 'Nurturing',
    // Common aliases
    'hot': 'Qualified',
    'cold': 'Nurturing',
    'warm': 'Working',
    'in progress': 'Working',
    'in_progress': 'Working',
    'inprogress': 'Working',
  };

  return statusMap[normalized] || null;
}

/**
 * Detect duplicates based on email or phone
 */
export async function detectDuplicates(
  rowData: EntityData,
  _entityType: string,
  existingRecords: any[]
): Promise<any | null> {
  const email = rowData.email?.toLowerCase();
  const phone = rowData.phone ? normalizePhone(rowData.phone) : null;

  for (const record of existingRecords) {
    if (email && record.email?.toLowerCase() === email) {
      return record;
    }
    if (phone && record.phone && normalizePhone(record.phone) === phone) {
      return record;
    }
  }

  return null;
}

/**
 * Import rows into the database
 */
export async function importRows(
  rows: string[][],
  headers: string[],
  config: ImportConfig,
  businessId: string,
  existingRecords: any[],
  onProgress?: (current: number, total: number) => void,
  createEntity?: (data: EntityData) => Promise<any>,
  updateEntity?: (id: string, data: EntityData) => Promise<any>
): Promise<ImportResult> {
  const result: ImportResult = {
    totalRows: rows.length,
    imported: 0,
    skipped: 0,
    errors: [],
    dryRun: config.dryRun ?? false,
  };

  const preflightErrors = validateAllRows(
    rows,
    headers,
    config.entityType,
    config.fieldMapping,
    config.existingIdentifiers
  );

  if (preflightErrors.length > 0 && config.stopOnError !== false) {
    return {
      ...result,
      imported: 0,
      skipped: rows.length,
      errors: preflightErrors.map((err) => ({
        row: err.row,
        error: err.error,
      })),
    };
  }

  if (preflightErrors.length > 0) {
    preflightErrors.forEach((err) =>
      result.errors.push({
        row: err.row,
        error: err.error,
      })
    );
  }

  if (config.dryRun) {
    result.skipped = rows.length;
    return result;
  }

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];

    try {
      // Skip empty rows
      if (row.every(cell => !cell || cell.trim() === '')) {
        result.skipped++;
        continue;
      }

      // Validate row
      const validationErrors = validateRow(row, headers, config.entityType, config.fieldMapping);
      if (validationErrors.length > 0) {
        result.errors.push({
          row: i + 1,
          error: validationErrors.map(e => `${e.field}: ${e.error}`).join(', ')
        });
        result.skipped++;
        continue;
      }

      // Transform row data
      const rowData = transformRowData(row, headers, config.entityType, config.fieldMapping, businessId);

      // Check for duplicates
      const duplicate = await detectDuplicates(rowData, config.entityType, existingRecords);

      if (duplicate) {
        if (config.duplicateHandling === 'skip') {
          result.skipped++;
          continue;
        } else if (config.duplicateHandling === 'update' && updateEntity) {
          await updateEntity(duplicate.id, rowData);
          result.imported++;
        } else if (config.duplicateHandling === 'create' && createEntity) {
          await createEntity(rowData);
          result.imported++;
        }
      } else {
        // Create new record
        if (createEntity) {
          await createEntity(rowData);
          result.imported++;
        }
      }

      // Report progress
      if (onProgress) {
        onProgress(i + 1, rows.length);
      }
    } catch (error) {
      result.errors.push({
        row: i + 1,
        error: error instanceof Error ? error.message : 'Unknown error'
      });
      result.skipped++;
    }
  }

  return result;
}

/**
 * Validate all rows and return errors
 */
export function validateAllRows(
  rows: string[][],
  headers: string[],
  entityType: string,
  fieldMapping: Record<string, string>,
  existingIdentifiers?: ExistingIdentifiers,
  duplicateHandling: 'skip' | 'update' | 'create' = 'skip'
): ValidationError[] {
  const allErrors: ValidationError[] = [];
  const seenEmails = new Map<string, number>();
  const seenPhones = new Map<string, number>();
  const checkExistingDuplicates = duplicateHandling === 'skip';
  const existingEmailSet = new Set(
    checkExistingDuplicates
      ? (existingIdentifiers?.emails || []).map((email) => email.toLowerCase().trim()).filter(Boolean)
      : []
  );
  const existingPhoneSet = new Set(
    checkExistingDuplicates
      ? (existingIdentifiers?.phones || []).map((phone) => normalizePhone(phone)).filter(Boolean)
      : []
  );

  const getFieldValue = (row: string[], field: string): string => {
    const headerIndex = headers.findIndex((h) => fieldMapping[h] === field);
    if (headerIndex === -1) return '';
    return row[headerIndex]?.trim() || '';
  };

  rows.forEach((row, index) => {
    // Skip empty rows
    if (row.every(cell => !cell || cell.trim() === '')) {
      return;
    }

    const errors = validateRow(row, headers, entityType, fieldMapping);
    errors.forEach(error => {
      allErrors.push({
        ...error,
        row: index + 1 // 1-based row numbering
      });
    });

    const email = getFieldValue(row, 'email').toLowerCase();
    if (email) {
      if (existingEmailSet.has(email)) {
        allErrors.push({
          row: index + 1,
          field: 'email',
          error: 'Email already exists for this business. Update the existing record instead of importing a duplicate.',
        });
      }

      const firstSeen = seenEmails.get(email);
      if (firstSeen) {
        allErrors.push({
          row: index + 1,
          field: 'email',
          error: `Duplicate email detected in import (first seen on row ${firstSeen})`,
        });
      } else {
        seenEmails.set(email, index + 1);
      }
    }

    const phone = normalizePhone(getFieldValue(row, 'phone'));
    if (phone) {
      if (existingPhoneSet.has(phone)) {
        allErrors.push({
          row: index + 1,
          field: 'phone',
          error: 'Phone already exists for this business. Update the existing record instead of importing a duplicate.',
        });
      }

      const firstSeen = seenPhones.get(phone);
      if (firstSeen) {
        allErrors.push({
          row: index + 1,
          field: 'phone',
          error: `Duplicate phone detected in import (first seen on row ${firstSeen})`,
        });
      } else {
        seenPhones.set(phone, index + 1);
      }
    }
  });

  return allErrors;
}

// ============================================
// Opportunity Import with Contact Linking
// ============================================

/**
 * Interface for opportunity import row with client linking support
 */
export interface OpportunityImportRow {
  title: string;
  valueCents?: number;
  clientEmail?: string; // Used to lookup/create contact
  clientName?: string;
  stageName?: string;
  expectedCloseDate?: Date;
  notes?: string;
  assignedRepEmail?: string;
}

/**
 * Result of processing an opportunity row with contact linking
 */
export interface OpportunityLinkResult {
  opportunityData: OpportunityImportRow;
  contactId?: string;
  contactCreated: boolean;
  assignedRepUid?: string;
  error?: string;
}

/**
 * Process opportunity import row and resolve contact linking
 *
 * WORKFLOW:
 * 1. If clientEmail is provided:
 *    a. Look up existing contact by email
 *    b. If found → link opportunity to existing contact
 *    c. If not found → auto-create a new contact, then link
 * 2. Inherit assignedRepUid from contact if not specified
 *
 * @param rowData - The parsed opportunity row data
 * @param existingContacts - Array of existing contacts for lookup
 * @param teamMembers - Array of team members for rep assignment lookup
 * @returns OpportunityLinkResult with contact info and any created contact flag
 */
export function processOpportunityWithContactLinking(
  rowData: OpportunityImportRow,
  existingContacts: Array<{ id: string; email: string; assignedRepUid?: string; firstName?: string; lastName?: string }>,
  teamMembers?: Array<{ id: string; email: string; displayName: string }>
): OpportunityLinkResult {
  const result: OpportunityLinkResult = {
    opportunityData: rowData,
    contactCreated: false,
  };

  // Step 1: Try to link to existing contact via clientEmail
  if (rowData.clientEmail) {
    const normalizedEmail = rowData.clientEmail.toLowerCase().trim();
    const existingContact = existingContacts.find(
      (c) => c.email.toLowerCase() === normalizedEmail
    );

    if (existingContact) {
      // Found existing contact - link to it
      result.contactId = existingContact.id;
      // Inherit assignedRepUid from contact if opportunity doesn't specify one
      if (!rowData.assignedRepEmail && existingContact.assignedRepUid) {
        result.assignedRepUid = existingContact.assignedRepUid;
      }
    } else {
      // Contact not found - mark for creation
      // The actual creation happens in the import handler
      result.contactCreated = true;
    }
  }

  // Step 2: Resolve assignedRepEmail to assignedRepUid if team members provided
  if (rowData.assignedRepEmail && teamMembers) {
    const normalizedRepEmail = rowData.assignedRepEmail.toLowerCase().trim();
    const rep = teamMembers.find(
      (m) => m.email.toLowerCase() === normalizedRepEmail
    );
    if (rep) {
      result.assignedRepUid = rep.id;
    }
  }

  return result;
}

/**
 * Generate contact data from opportunity row for auto-creation
 * Used when clientEmail doesn't match an existing contact
 *
 * @param rowData - The opportunity import row
 * @returns Partial contact data suitable for creation
 */
export function generateContactFromOpportunityRow(
  rowData: OpportunityImportRow
): { email: string; firstName: string; lastName: string; leadStatus: ContactLeadStatus } | null {
  if (!rowData.clientEmail) {
    return null;
  }

  // Parse client name if provided, otherwise use email prefix
  let firstName = '';
  let lastName = '';

  if (rowData.clientName) {
    const nameParts = splitFullName(rowData.clientName);
    firstName = nameParts.firstName;
    lastName = nameParts.lastName;
  }

  // Fallback: use email username as firstName if no name provided
  if (!firstName) {
    const emailPrefix = rowData.clientEmail.split('@')[0] || '';
    // Basic cleaning of email prefix
    firstName = emailPrefix.replace(/[._-]/g, ' ').replace(/\d+/g, '').trim();
    if (!firstName) {
      firstName = 'Contact';
    }
  }

  return {
    email: rowData.clientEmail.toLowerCase().trim(),
    firstName,
    lastName: lastName || '(from import)',
    leadStatus: 'New' as ContactLeadStatus, // Default lead status for auto-created contacts
  };
}
