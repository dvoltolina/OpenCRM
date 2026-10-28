/**
 * Environment Validation Script
 *
 * Validates that all required environment variables and configurations
 * are properly set before deployment or running the application.
 *
 * Usage:
 *   npx tsx scripts/validate-env.ts
 *   npx tsx scripts/validate-env.ts --strict    # Exit with error on warnings
 *   npx tsx scripts/validate-env.ts --env production
 *
 * Can be used in CI/CD pipelines to ensure proper configuration.
 */

import * as fs from 'fs';
import * as path from 'path';

interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

interface EnvVar {
  name: string;
  required: boolean;
  description: string;
  validate?: (value: string) => boolean;
  validationMessage?: string;
}

// Required environment variables
const REQUIRED_ENV_VARS: EnvVar[] = [
  {
    name: 'VITE_FIREBASE_API_KEY',
    required: true,
    description: 'Firebase API Key',
    validate: (val) => val.length > 20,
    validationMessage: 'API key should be at least 20 characters',
  },
  {
    name: 'VITE_FIREBASE_AUTH_DOMAIN',
    required: true,
    description: 'Firebase Auth Domain',
    validate: (val) => val.includes('.firebaseapp.com') || val.includes('.web.app'),
    validationMessage: 'Auth domain should be a valid Firebase domain',
  },
  {
    name: 'VITE_FIREBASE_PROJECT_ID',
    required: true,
    description: 'Firebase Project ID',
    validate: (val) => val.length > 0 && /^[a-z0-9-]+$/.test(val),
    validationMessage: 'Project ID should contain only lowercase letters, numbers, and hyphens',
  },
  {
    name: 'VITE_FIREBASE_STORAGE_BUCKET',
    required: true,
    description: 'Firebase Storage Bucket',
    validate: (val) => val.includes('.appspot.com') || val.includes('.firebasestorage.app'),
    validationMessage: 'Storage bucket should be a valid Firebase storage domain',
  },
  {
    name: 'VITE_FIREBASE_MESSAGING_SENDER_ID',
    required: true,
    description: 'Firebase Messaging Sender ID',
    validate: (val) => /^\d+$/.test(val),
    validationMessage: 'Sender ID should be numeric',
  },
  {
    name: 'VITE_FIREBASE_APP_ID',
    required: true,
    description: 'Firebase App ID',
    validate: (val) => val.startsWith('1:') && val.includes(':web:'),
    validationMessage: 'App ID should be a valid Firebase app identifier',
  },
];

// Optional but recommended environment variables
const OPTIONAL_ENV_VARS: EnvVar[] = [
  {
    name: 'VITE_FIREBASE_MEASUREMENT_ID',
    required: false,
    description: 'Firebase Analytics Measurement ID (for Google Analytics)',
  },
  {
    name: 'NODE_ENV',
    required: false,
    description: 'Node environment (development, production, test)',
  },
];

// Sensitive patterns that should NOT be in environment variables
const SENSITIVE_PATTERNS = [
  { pattern: /-----BEGIN.*PRIVATE KEY-----/, message: 'Private key detected' },
  { pattern: /password/i, message: 'Password field detected' },
  { pattern: /secret.*key/i, message: 'Secret key pattern detected' },
];

const ROOT_DIR = path.join(process.cwd());
const ENV_FILE = path.join(ROOT_DIR, '.env');
const ENV_EXAMPLE_FILE = path.join(ROOT_DIR, '.env.example');

let STRICT_MODE = false;
let TARGET_ENV = 'staging';

function loadEnvFile(filePath: string): Map<string, string> {
  const envVars = new Map<string, string>();

  if (!fs.existsSync(filePath)) {
    return envVars;
  }

  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split('\n');

  for (const line of lines) {
    const trimmed = line.trim();

    // Skip comments and empty lines
    if (trimmed.startsWith('#') || trimmed === '') {
      continue;
    }

    // Parse key=value
    const match = trimmed.match(/^([^=]+)=(.*)$/);
    if (match) {
      const key = match[1].trim();
      const value = match[2].trim();
      envVars.set(key, value);
    }
  }

  return envVars;
}

function validateEnvVar(envVar: EnvVar, value: string | undefined): ValidationResult {
  const result: ValidationResult = {
    valid: true,
    errors: [],
    warnings: [],
  };

  // Check if required var is missing
  if (envVar.required && !value) {
    result.errors.push(`Missing required environment variable: ${envVar.name}`);
    result.valid = false;
    return result;
  }

  // Skip validation if optional and not provided
  if (!envVar.required && !value) {
    return result;
  }

  // Check for placeholder values
  if (value) {
    const placeholders = [
      'your-api-key',
      'your-project',
      'your-project-id',
      'your-sender-id',
      'your-app-id',
    ];

    if (placeholders.some((placeholder) => value.includes(placeholder))) {
      result.errors.push(
        `${envVar.name} contains a placeholder value. Please replace with actual value.`
      );
      result.valid = false;
      return result;
    }
  }

  // Run custom validation
  if (value && envVar.validate) {
    if (!envVar.validate(value)) {
      result.errors.push(
        `${envVar.name}: ${envVar.validationMessage || 'Validation failed'}`
      );
      result.valid = false;
    }
  }

  return result;
}

function checkForSensitiveData(envVars: Map<string, string>): ValidationResult {
  const result: ValidationResult = {
    valid: true,
    errors: [],
    warnings: [],
  };

  for (const [key, value] of envVars.entries()) {
    for (const { pattern, message } of SENSITIVE_PATTERNS) {
      if (pattern.test(value) || pattern.test(key)) {
        result.warnings.push(
          `${key}: ${message}. Ensure this is not a sensitive credential that should be server-side only.`
        );
      }
    }
  }

  return result;
}

function validateFirebaseConfig(): ValidationResult {
  const result: ValidationResult = {
    valid: true,
    errors: [],
    warnings: [],
  };

  const firebaseJsonPath = path.join(ROOT_DIR, 'firebase.json');

  if (!fs.existsSync(firebaseJsonPath)) {
    result.warnings.push('firebase.json not found in project root');
    return result;
  }

  try {
    const firebaseConfig = JSON.parse(fs.readFileSync(firebaseJsonPath, 'utf-8'));

    // Check for required Firestore configuration
    if (!firebaseConfig.firestore) {
      result.warnings.push('firebase.json: Missing firestore configuration');
    } else {
      if (!firebaseConfig.firestore.rules) {
        result.errors.push('firebase.json: Missing firestore.rules path');
        result.valid = false;
      }
      if (!firebaseConfig.firestore.indexes) {
        result.warnings.push('firebase.json: Missing firestore.indexes path');
      }
    }

    // Check for emulator configuration
    if (!firebaseConfig.emulators) {
      result.warnings.push('firebase.json: No emulator configuration found');
    }
  } catch (error) {
    result.errors.push(`firebase.json: Invalid JSON - ${error}`);
    result.valid = false;
  }

  return result;
}

function validateProjectStructure(): ValidationResult {
  const result: ValidationResult = {
    valid: true,
    errors: [],
    warnings: [],
  };

  const requiredFiles = [
    { path: 'package.json', critical: true },
    { path: 'tsconfig.json', critical: true },
    { path: 'firestore.rules', critical: true },
    { path: 'src/main.tsx', critical: true },
    { path: 'src/firebase.ts', critical: false },
  ];

  for (const { path: filePath, critical } of requiredFiles) {
    const fullPath = path.join(ROOT_DIR, filePath);
    if (!fs.existsSync(fullPath)) {
      if (critical) {
        result.errors.push(`Missing required file: ${filePath}`);
        result.valid = false;
      } else {
        result.warnings.push(`Missing recommended file: ${filePath}`);
      }
    }
  }

  return result;
}

function checkPackageJsonScripts(): ValidationResult {
  const result: ValidationResult = {
    valid: true,
    errors: [],
    warnings: [],
  };

  const packageJsonPath = path.join(ROOT_DIR, 'package.json');

  if (!fs.existsSync(packageJsonPath)) {
    return result;
  }

  try {
    const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf-8'));
    const scripts = packageJson.scripts || {};

    const recommendedScripts = [
      'build',
      'test',
      'test:security',
      'validate:firestore',
    ];

    for (const script of recommendedScripts) {
      if (!scripts[script]) {
        result.warnings.push(`package.json: Missing recommended script: ${script}`);
      }
    }
  } catch (error) {
    result.warnings.push(`package.json: Could not parse - ${error}`);
  }

  return result;
}

function validateEnvironment(): void {
  console.log('='.repeat(60));
  console.log('Environment Validation');
  console.log('='.repeat(60));
  console.log(`Working Directory: ${ROOT_DIR}`);
  console.log(`Target Environment: ${TARGET_ENV}`);
  console.log(`Strict Mode: ${STRICT_MODE}`);
  console.log('='.repeat(60));
  console.log('');

  const allResults: ValidationResult[] = [];

  // Check if .env file exists
  console.log('Checking for .env file...');
  if (!fs.existsSync(ENV_FILE)) {
    console.log('❌ .env file not found');
    console.log(`   Expected location: ${ENV_FILE}`);

    if (fs.existsSync(ENV_EXAMPLE_FILE)) {
      console.log(`   Found .env.example - copy it to .env and fill in values`);
    }

    allResults.push({
      valid: false,
      errors: ['.env file not found'],
      warnings: [],
    });
  } else {
    console.log('✅ .env file found');
  }
  console.log('');

  // Load environment variables
  const envVars = loadEnvFile(ENV_FILE);
  const processEnvVars = new Map(Object.entries(process.env));

  // Merge with process.env (process.env takes precedence)
  for (const [key, value] of processEnvVars.entries()) {
    if (key.startsWith('VITE_')) {
      envVars.set(key, value);
    }
  }

  // Validate required environment variables
  console.log('Validating required environment variables...');
  for (const envVar of REQUIRED_ENV_VARS) {
    const value = envVars.get(envVar.name);
    const result = validateEnvVar(envVar, value);

    if (result.valid) {
      console.log(`✅ ${envVar.name}`);
    } else {
      console.log(`❌ ${envVar.name}`);
      result.errors.forEach((e) => console.log(`   - ${e}`));
    }

    allResults.push(result);
  }
  console.log('');

  // Check optional variables
  console.log('Checking optional environment variables...');
  for (const envVar of OPTIONAL_ENV_VARS) {
    const value = envVars.get(envVar.name);
    if (value) {
      console.log(`✅ ${envVar.name} (optional)`);
    } else {
      console.log(`⚠️  ${envVar.name} (optional, not set)`);
    }
  }
  console.log('');

  // Check for sensitive data
  console.log('Checking for sensitive data...');
  const sensitiveResult = checkForSensitiveData(envVars);
  if (sensitiveResult.warnings.length > 0) {
    console.log('⚠️  Potential sensitive data detected:');
    sensitiveResult.warnings.forEach((w) => console.log(`   - ${w}`));
  } else {
    console.log('✅ No obvious sensitive data patterns detected');
  }
  allResults.push(sensitiveResult);
  console.log('');

  // Validate Firebase config
  console.log('Validating firebase.json...');
  const firebaseResult = validateFirebaseConfig();
  if (firebaseResult.valid && firebaseResult.warnings.length === 0) {
    console.log('✅ Firebase configuration valid');
  } else {
    if (!firebaseResult.valid) {
      console.log('❌ Firebase configuration invalid');
      firebaseResult.errors.forEach((e) => console.log(`   - ${e}`));
    }
    if (firebaseResult.warnings.length > 0) {
      console.log('⚠️  Firebase configuration warnings:');
      firebaseResult.warnings.forEach((w) => console.log(`   - ${w}`));
    }
  }
  allResults.push(firebaseResult);
  console.log('');

  // Validate project structure
  console.log('Validating project structure...');
  const structureResult = validateProjectStructure();
  if (structureResult.valid && structureResult.warnings.length === 0) {
    console.log('✅ Project structure valid');
  } else {
    if (!structureResult.valid) {
      console.log('❌ Project structure invalid');
      structureResult.errors.forEach((e) => console.log(`   - ${e}`));
    }
    if (structureResult.warnings.length > 0) {
      structureResult.warnings.forEach((w) => console.log(`   ⚠️  ${w}`));
    }
  }
  allResults.push(structureResult);
  console.log('');

  // Check package.json scripts
  console.log('Checking package.json scripts...');
  const scriptsResult = checkPackageJsonScripts();
  if (scriptsResult.warnings.length === 0) {
    console.log('✅ All recommended scripts present');
  } else {
    scriptsResult.warnings.forEach((w) => console.log(`   ⚠️  ${w}`));
  }
  allResults.push(scriptsResult);
  console.log('');

  // Summary
  console.log('='.repeat(60));
  console.log('Summary');
  console.log('='.repeat(60));

  const totalErrors = allResults.reduce((sum, r) => sum + r.errors.length, 0);
  const totalWarnings = allResults.reduce((sum, r) => sum + r.warnings.length, 0);
  const allValid = allResults.every((r) => r.valid);

  console.log(`Total Errors: ${totalErrors}`);
  console.log(`Total Warnings: ${totalWarnings}`);
  console.log('');

  if (allValid && totalWarnings === 0) {
    console.log('✅ Environment validation passed!');
    console.log('');
    console.log('You can now:');
    console.log('  - Run the development server: npm run dev');
    console.log('  - Build for production: npm run build');
    console.log('  - Deploy: ./scripts/deploy-crm.sh');
    process.exit(0);
  } else if (allValid && totalWarnings > 0) {
    console.log('⚠️  Environment validation passed with warnings');
    console.log('');
    console.log('Please review the warnings above.');

    if (STRICT_MODE) {
      console.log('');
      console.log('❌ Strict mode enabled: treating warnings as errors');
      process.exit(1);
    } else {
      process.exit(0);
    }
  } else {
    console.log('❌ Environment validation failed');
    console.log('');
    console.log('Please fix the errors above before proceeding.');
    console.log('');
    console.log('Common fixes:');
    console.log('  1. Copy .env.example to .env');
    console.log('  2. Fill in all required Firebase configuration values');
    console.log('  3. Ensure firebase.json is properly configured');
    process.exit(1);
  }
}

// Parse command line arguments
function parseArgs(): void {
  const args = process.argv.slice(2);

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    switch (arg) {
      case '--strict':
        STRICT_MODE = true;
        break;
      case '--env':
        if (i + 1 < args.length) {
          TARGET_ENV = args[i + 1];
          i++;
        }
        break;
      case '--help':
      case '-h':
        console.log('Environment Validation Script');
        console.log('');
        console.log('Usage: npx tsx scripts/validate-env.ts [options]');
        console.log('');
        console.log('Options:');
        console.log('  --strict          Treat warnings as errors');
        console.log('  --env ENV         Target environment (staging, production)');
        console.log('  --help, -h        Show this help message');
        console.log('');
        process.exit(0);
        break;
      default:
        // Fail fast on unsupported flags; avoid fallthrough
        console.error(`Unknown option: ${arg}`);
        console.error('Use --help for usage information');
        process.exit(1);
    }
  }
}

// Main execution
parseArgs();
validateEnvironment();
