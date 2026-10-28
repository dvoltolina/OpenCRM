/**
 * Firestore Configuration Validator
 *
 * Validates the Firestore indexes and rules documentation files
 * to ensure they contain valid configurations before deployment.
 *
 * Usage: npx tsx scripts/validate-firestore-config.ts
 */

import * as fs from 'fs';
import * as path from 'path';

interface IndexField {
  fieldPath: string;
  order?: 'ASCENDING' | 'DESCENDING';
  arrayConfig?: 'CONTAINS';
}

interface FirestoreIndex {
  collectionGroup: string;
  queryScope: 'COLLECTION' | 'COLLECTION_GROUP';
  fields: IndexField[];
}

interface FirestoreIndexConfig {
  indexes: FirestoreIndex[];
  fieldOverrides: unknown[];
}

interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

const DOCS_DIR = path.join(process.cwd(), 'docs', 'operations');
const INDEXES_FILE = path.join(DOCS_DIR, 'firestore_indexes.md');
const RULES_FILE = path.join(DOCS_DIR, 'firestore_rules.md');

// Expected CRM collections
const EXPECTED_COLLECTIONS = [
  'pipelines',
  'stages',
  'leads',
  'deals',
  'clients',
  'companies',
  'sales_activities',
  'crm_custom_fields',
];

function extractJsonBlocks(markdown: string): string[] {
  const jsonBlockRegex = /```json\n([\s\S]*?)\n```/g;
  const blocks: string[] = [];
  let match;

  while ((match = jsonBlockRegex.exec(markdown)) !== null) {
    blocks.push(match[1].trim());
  }

  return blocks;
}

function extractJsBlocks(markdown: string): string[] {
  const jsBlockRegex = /```javascript\n([\s\S]*?)\n```/g;
  const blocks: string[] = [];
  let match;

  while ((match = jsBlockRegex.exec(markdown)) !== null) {
    blocks.push(match[1].trim());
  }

  return blocks;
}

function validateIndexField(field: IndexField, index: number): string[] {
  const errors: string[] = [];

  if (!field.fieldPath || typeof field.fieldPath !== 'string') {
    errors.push(`Field ${index}: Missing or invalid fieldPath`);
  }

  if (field.order && !['ASCENDING', 'DESCENDING'].includes(field.order)) {
    errors.push(`Field ${index}: Invalid order "${field.order}"`);
  }

  if (field.arrayConfig && field.arrayConfig !== 'CONTAINS') {
    errors.push(`Field ${index}: Invalid arrayConfig "${field.arrayConfig}"`);
  }

  return errors;
}

function validateIndex(index: FirestoreIndex, idx: number): string[] {
  const errors: string[] = [];

  if (!index.collectionGroup || typeof index.collectionGroup !== 'string') {
    errors.push(`Index ${idx}: Missing or invalid collectionGroup`);
  }

  if (!['COLLECTION', 'COLLECTION_GROUP'].includes(index.queryScope)) {
    errors.push(`Index ${idx}: Invalid queryScope "${index.queryScope}"`);
  }

  if (!Array.isArray(index.fields) || index.fields.length < 2) {
    errors.push(`Index ${idx}: Composite indexes require at least 2 fields`);
  } else {
    index.fields.forEach((field, fieldIdx) => {
      errors.push(...validateIndexField(field, fieldIdx));
    });
  }

  return errors;
}

function validateIndexConfig(config: FirestoreIndexConfig): ValidationResult {
  const result: ValidationResult = {
    valid: true,
    errors: [],
    warnings: [],
  };

  if (!config.indexes || !Array.isArray(config.indexes)) {
    result.errors.push('Missing or invalid "indexes" array');
    result.valid = false;
    return result;
  }

  // Validate each index
  config.indexes.forEach((index, idx) => {
    const indexErrors = validateIndex(index, idx);
    result.errors.push(...indexErrors);
  });

  // Check for expected collections
  const indexedCollections = new Set(config.indexes.map((i) => i.collectionGroup));
  const missingCollections = EXPECTED_COLLECTIONS.filter(
    (c) => !indexedCollections.has(c) && c !== 'pipelines' && c !== 'crm_custom_fields' // These don't need composite indexes
  );

  if (missingCollections.length > 0) {
    result.warnings.push(
      `Missing indexes for collections: ${missingCollections.join(', ')}`
    );
  }

  // Check for duplicate indexes
  const indexSignatures = new Set<string>();
  config.indexes.forEach((index, idx) => {
    const sig = `${index.collectionGroup}:${index.fields.map((f) => `${f.fieldPath}:${f.order || f.arrayConfig}`).join(',')}`;
    if (indexSignatures.has(sig)) {
      result.warnings.push(`Index ${idx}: Duplicate index detected`);
    }
    indexSignatures.add(sig);
  });

  result.valid = result.errors.length === 0;
  return result;
}

function validateRulesContent(rulesContent: string): ValidationResult {
  const result: ValidationResult = {
    valid: true,
    errors: [],
    warnings: [],
  };

  // Check for required helper functions
  const requiredFunctions = [
    'isAuthenticated',
    'belongsToBusiness',
    'isAdminOrOwner',
    'isOwner',
  ];

  requiredFunctions.forEach((fn) => {
    if (!rulesContent.includes(`function ${fn}(`)) {
      result.errors.push(`Missing required helper function: ${fn}`);
    }
  });

  // Check for expected collection rules
  EXPECTED_COLLECTIONS.forEach((collection) => {
    // pipelines, stages, leads, etc.
    const matchPattern = new RegExp(
      `match\\s+/businesses/\\{businessId\\}/${collection}/`,
      'g'
    );
    if (!matchPattern.test(rulesContent)) {
      // Settings is a special case
      if (collection === 'crm_custom_fields') {
        // Check alternate path
        if (!rulesContent.includes('crm_custom_fields')) {
          result.warnings.push(`Missing rules for collection: ${collection}`);
        }
      } else {
        result.warnings.push(`Missing rules for collection: ${collection}`);
      }
    }
  });

  // Check for security best practices
  if (!rulesContent.includes('request.auth != null')) {
    result.warnings.push('Rules should check for authentication');
  }

  if (!rulesContent.includes('rules_version')) {
    result.errors.push('Missing rules_version declaration');
  }

  result.valid = result.errors.length === 0;
  return result;
}

function validateIndexesFile(): ValidationResult {
  const result: ValidationResult = {
    valid: true,
    errors: [],
    warnings: [],
  };

  if (!fs.existsSync(INDEXES_FILE)) {
    result.errors.push(`Indexes file not found: ${INDEXES_FILE}`);
    result.valid = false;
    return result;
  }

  const content = fs.readFileSync(INDEXES_FILE, 'utf-8');
  const jsonBlocks = extractJsonBlocks(content);

  if (jsonBlocks.length === 0) {
    result.errors.push('No JSON blocks found in indexes file');
    result.valid = false;
    return result;
  }

  // Find the full config block (has "indexes" array)
  let fullConfigFound = false;
  for (const block of jsonBlocks) {
    try {
      const parsed = JSON.parse(block);
      if (parsed.indexes && Array.isArray(parsed.indexes)) {
        fullConfigFound = true;
        const configResult = validateIndexConfig(parsed);
        result.errors.push(...configResult.errors);
        result.warnings.push(...configResult.warnings);
      }
    } catch {
      // Individual index blocks are expected, not errors
    }
  }

  if (!fullConfigFound) {
    result.errors.push('No complete firestore.indexes.json config found');
  }

  result.valid = result.errors.length === 0;
  return result;
}

function validateRulesFile(): ValidationResult {
  const result: ValidationResult = {
    valid: true,
    errors: [],
    warnings: [],
  };

  if (!fs.existsSync(RULES_FILE)) {
    result.errors.push(`Rules file not found: ${RULES_FILE}`);
    result.valid = false;
    return result;
  }

  const content = fs.readFileSync(RULES_FILE, 'utf-8');
  const jsBlocks = extractJsBlocks(content);

  if (jsBlocks.length === 0) {
    result.errors.push('No JavaScript blocks found in rules file');
    result.valid = false;
    return result;
  }

  // Combine all JS blocks for validation
  const allRulesContent = jsBlocks.join('\n');
  const rulesResult = validateRulesContent(allRulesContent);
  result.errors.push(...rulesResult.errors);
  result.warnings.push(...rulesResult.warnings);

  result.valid = result.errors.length === 0;
  return result;
}

function printResult(name: string, result: ValidationResult): void {
  console.log(`\n${'='.repeat(50)}`);
  console.log(`${name}`);
  console.log('='.repeat(50));

  if (result.valid) {
    console.log('✅ Valid');
  } else {
    console.log('❌ Invalid');
  }

  if (result.errors.length > 0) {
    console.log('\nErrors:');
    result.errors.forEach((e) => console.log(`  ❌ ${e}`));
  }

  if (result.warnings.length > 0) {
    console.log('\nWarnings:');
    result.warnings.forEach((w) => console.log(`  ⚠️  ${w}`));
  }
}

function main(): void {
  console.log('🔥 Firestore Configuration Validator');
  console.log(`Working directory: ${process.cwd()}`);

  const indexesResult = validateIndexesFile();
  const rulesResult = validateRulesFile();

  printResult('Firestore Indexes', indexesResult);
  printResult('Firestore Rules', rulesResult);

  console.log('\n' + '='.repeat(50));
  console.log('Summary');
  console.log('='.repeat(50));

  const allValid = indexesResult.valid && rulesResult.valid;
  const totalErrors = indexesResult.errors.length + rulesResult.errors.length;
  const totalWarnings = indexesResult.warnings.length + rulesResult.warnings.length;

  console.log(`Total Errors: ${totalErrors}`);
  console.log(`Total Warnings: ${totalWarnings}`);

  if (allValid) {
    console.log('\n✅ All configurations are valid!');
    console.log('\nNext steps:');
    console.log('1. Copy firestore.indexes.json to Admin Dashboard repo');
    console.log('2. Merge firestore.rules into Admin Dashboard rules');
    console.log('3. Deploy: firebase deploy --only firestore:indexes,firestore:rules');
    process.exit(0);
  } else {
    console.log('\n❌ Validation failed. Please fix the errors above.');
    process.exit(1);
  }
}

main();
