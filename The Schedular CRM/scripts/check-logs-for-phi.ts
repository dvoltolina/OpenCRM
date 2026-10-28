#!/usr/bin/env tsx

/**
 * PHI Log Scanner
 *
 * Agent CRM-33: Security & HIPAA Verification Suite
 *
 * This script scans source code and test files for patterns that log PHI,
 * which would violate HIPAA compliance requirements.
 *
 * WHAT IT CHECKS:
 * 1. console.log statements containing PHI fields (email, phone, name, notes)
 * 2. Error messages that might log PHI
 * 3. Debug/trace statements with PHI
 * 4. Test fixtures with real PHI data
 *
 * USAGE:
 *   npm run check:phi           # Check all files
 *   tsx scripts/check-logs-for-phi.ts --dir src
 *   tsx scripts/check-logs-for-phi.ts --dir tests
 *
 * EXIT CODES:
 *   0 - No PHI logging violations found
 *   1 - PHI logging violations detected (fails CI)
 *
 * HIPAA COMPLIANCE:
 * - PHI must NOT be logged to console, files, or external systems
 * - Only log metadata, IDs, and non-PHI fields
 * - Use audit logging system for PHI access tracking
 */

import { readFileSync, readdirSync, statSync } from 'fs';
import { join, relative } from 'path';

// ============================================
// Configuration
// ============================================

interface ScannerConfig {
  /** Directories to scan */
  directories: string[];
  /** File patterns to include */
  includePatterns: string[];
  /** File patterns to exclude */
  excludePatterns: string[];
  /** PHI field patterns to detect */
  phiPatterns: PHIPattern[];
}

interface PHIPattern {
  /** Pattern name for reporting */
  name: string;
  /** Regular expression to match */
  pattern: RegExp;
  /** Severity level */
  severity: 'error' | 'warning';
  /** Description for violation report */
  description: string;
}

interface Violation {
  file: string;
  line: number;
  pattern: string;
  code: string;
  severity: 'error' | 'warning';
  description: string;
}

// ============================================
// PHI Detection Patterns
// ============================================

const PHI_PATTERNS: PHIPattern[] = [
  // Email logging
  {
    name: 'EMAIL_IN_LOG',
    pattern: /console\.(log|info|debug|warn|error)\([^)]*\b(email|emailAddress|userEmail)\b/gi,
    severity: 'error',
    description: 'Email address logged to console',
  },
  {
    name: 'EMAIL_IN_ERROR',
    pattern: /throw\s+new\s+\w*Error\([^)]*\b(email|emailAddress)\b/gi,
    severity: 'error',
    description: 'Email address in error message',
  },

  // Phone number logging
  {
    name: 'PHONE_IN_LOG',
    pattern: /console\.(log|info|debug|warn|error)\([^)]*\b(phone|phoneNumber|mobile)\b/gi,
    severity: 'error',
    description: 'Phone number logged to console',
  },
  {
    name: 'PHONE_IN_ERROR',
    pattern: /throw\s+new\s+\w*Error\([^)]*\b(phone|phoneNumber)\b/gi,
    severity: 'error',
    description: 'Phone number in error message',
  },

  // Name logging
  {
    name: 'NAME_IN_LOG',
    pattern: /console\.(log|info|debug|warn|error)\([^)]*\b(firstName|lastName|fullName|patientName|clientName)\b/gi,
    severity: 'error',
    description: 'Personal name logged to console',
  },

  // Notes/free-text logging (high risk for PHI)
  {
    name: 'NOTES_IN_LOG',
    pattern: /console\.(log|info|debug|warn|error)\([^)]*\b(notes|description|comments|details|memo)\b/gi,
    severity: 'warning',
    description: 'Free-text field logged (may contain PHI)',
  },

  // Address logging
  {
    name: 'ADDRESS_IN_LOG',
    pattern: /console\.(log|info|debug|warn|error)\([^)]*\b(address|street|city|zipCode|postalCode)\b/gi,
    severity: 'error',
    description: 'Address logged to console',
  },

  // SSN or other identifiers
  {
    name: 'SSN_IN_LOG',
    pattern: /console\.(log|info|debug|warn|error)\([^)]*\b(ssn|socialSecurity|taxId)\b/gi,
    severity: 'error',
    description: 'SSN or tax ID logged to console',
  },

  // Medical information
  {
    name: 'MEDICAL_IN_LOG',
    pattern: /console\.(log|info|debug|warn|error)\([^)]*\b(diagnosis|prescription|medication|treatment|healthCondition)\b/gi,
    severity: 'error',
    description: 'Medical information logged to console',
  },

  // Entire object logging (risky if contains PHI)
  {
    name: 'OBJECT_LOG',
    pattern: /console\.(log|info|debug|warn|error)\([^)]*\b(lead|client|contact|patient|user)\s*\)/gi,
    severity: 'warning',
    description: 'Entire entity object logged (may contain PHI)',
  },

  // JSON.stringify on PHI objects
  {
    name: 'JSON_STRINGIFY_PHI',
    pattern: /JSON\.stringify\([^)]*\b(lead|client|contact|patient|user)\b/gi,
    severity: 'warning',
    description: 'JSON.stringify on entity (may contain PHI)',
  },
];

// ============================================
// Allowlist Patterns (Safe Logging)
// ============================================

const ALLOWLIST_PATTERNS = [
  // Logging IDs is safe
  /console\.(log|info|debug|warn|error)\([^)]*\b(id|userId|leadId|clientId|contactId)\b/i,

  // Logging status/lifecycle is safe
  /console\.(log|info|debug|warn|error)\([^)]*\b(status|lifecycle|stage)\b/i,

  // Logging counts/metrics is safe
  /console\.(log|info|debug|warn|error)\([^)]*\b(count|total|length)\b/i,

  // Comments mentioning fields (not actual logging)
  /\/\/.*\b(email|phone|name)\b/i,
  /\/\*.*\b(email|phone|name)\b.*\*\//i,
];

// ============================================
// File Scanner
// ============================================

class PHILogScanner {
  private violations: Violation[] = [];
  private filesScanned = 0;

  constructor(private config: ScannerConfig) {}

  /**
   * Scan all configured directories
   */
  scan(): Violation[] {
    this.violations = [];
    this.filesScanned = 0;

    for (const dir of this.config.directories) {
      this.scanDirectory(dir);
    }

    return this.violations;
  }

  /**
   * Recursively scan a directory
   */
  private scanDirectory(dir: string): void {
    try {
      const entries = readdirSync(dir);

      for (const entry of entries) {
        const fullPath = join(dir, entry);
        const stat = statSync(fullPath);

        if (stat.isDirectory()) {
          // Skip excluded directories
          if (this.shouldExclude(fullPath)) {
            continue;
          }
          this.scanDirectory(fullPath);
        } else if (stat.isFile()) {
          // Scan files that match include patterns
          if (this.shouldInclude(fullPath)) {
            this.scanFile(fullPath);
          }
        }
      }
    } catch (error) {
      console.error(`Error scanning directory ${dir}:`, error);
    }
  }

  /**
   * Scan a single file for PHI logging violations
   */
  private scanFile(filePath: string): void {
    try {
      const content = readFileSync(filePath, 'utf-8');
      const lines = content.split('\n');

      this.filesScanned++;

      lines.forEach((line, index) => {
        // Skip comments and empty lines
        if (this.isComment(line) || line.trim() === '') {
          return;
        }

        // Check against allowlist first
        if (this.isAllowlisted(line)) {
          return;
        }

        // Check for PHI patterns
        for (const phiPattern of this.config.phiPatterns) {
          if (phiPattern.pattern.test(line)) {
            this.violations.push({
              file: relative(process.cwd(), filePath),
              line: index + 1,
              pattern: phiPattern.name,
              code: line.trim(),
              severity: phiPattern.severity,
              description: phiPattern.description,
            });
          }
        }
      });
    } catch (error) {
      console.error(`Error scanning file ${filePath}:`, error);
    }
  }

  /**
   * Check if file should be included in scan
   */
  private shouldInclude(filePath: string): boolean {
    return this.config.includePatterns.some((pattern) => filePath.endsWith(pattern));
  }

  /**
   * Check if path should be excluded from scan
   */
  private shouldExclude(path: string): boolean {
    return this.config.excludePatterns.some((pattern) => path.includes(pattern));
  }

  /**
   * Check if line is a comment
   */
  private isComment(line: string): boolean {
    const trimmed = line.trim();
    return trimmed.startsWith('//') || trimmed.startsWith('/*') || trimmed.startsWith('*');
  }

  /**
   * Check if line matches allowlist patterns
   */
  private isAllowlisted(line: string): boolean {
    return ALLOWLIST_PATTERNS.some((pattern) => pattern.test(line));
  }

  /**
   * Get scan statistics
   */
  getStats() {
    return {
      filesScanned: this.filesScanned,
      totalViolations: this.violations.length,
      errorCount: this.violations.filter((v) => v.severity === 'error').length,
      warningCount: this.violations.filter((v) => v.severity === 'warning').length,
    };
  }
}

// ============================================
// Report Generator
// ============================================

function generateReport(
  violations: Violation[],
  stats: { filesScanned: number; totalViolations: number; errorCount: number; warningCount: number }
): void {
  console.log('\n========================================');
  console.log('PHI LOG SCANNER - HIPAA COMPLIANCE CHECK');
  console.log('========================================\n');

  console.log(`Files scanned: ${stats.filesScanned}`);
  console.log(`Total violations: ${stats.totalViolations}`);
  console.log(`Errors: ${stats.errorCount}`);
  console.log(`Warnings: ${stats.warningCount}\n`);

  if (violations.length === 0) {
    console.log('✅ No PHI logging violations detected!\n');
    return;
  }

  console.log('❌ PHI LOGGING VIOLATIONS DETECTED:\n');

  // Group by file
  const byFile = violations.reduce((acc, v) => {
    if (!acc[v.file]) acc[v.file] = [];
    acc[v.file].push(v);
    return acc;
  }, {} as Record<string, Violation[]>);

  for (const [file, fileViolations] of Object.entries(byFile)) {
    console.log(`📄 ${file}`);
    for (const violation of fileViolations) {
      const icon = violation.severity === 'error' ? '  ❌' : '  ⚠️ ';
      console.log(`${icon} Line ${violation.line}: ${violation.description}`);
      console.log(`     Pattern: ${violation.pattern}`);
      console.log(`     Code: ${violation.code}`);
      console.log('');
    }
  }

  console.log('========================================');
  console.log('REMEDIATION GUIDANCE');
  console.log('========================================\n');
  console.log('PHI must NOT be logged to console or external systems.');
  console.log('Instead:');
  console.log('  1. Log only IDs, not PHI data');
  console.log('  2. Use audit logging system for PHI access tracking');
  console.log('  3. Redact PHI in error messages');
  console.log('  4. Log metadata only (status, counts, timestamps)\n');
  console.log('Examples of SAFE logging:');
  console.log('  ✅ console.log("Lead created:", leadId)');
  console.log('  ✅ console.log("Status updated:", status)');
  console.log('  ✅ console.log("User count:", count)\n');
  console.log('Examples of UNSAFE logging:');
  console.log('  ❌ console.log("Lead created:", lead.email)');
  console.log('  ❌ console.log("User data:", user)');
  console.log('  ❌ throw new Error(`Invalid email: ${email}`)\n');
}

// ============================================
// Main Execution
// ============================================

function main() {
  // Parse command-line arguments
  const args = process.argv.slice(2);
  const dirArg = args.indexOf('--dir');
  const directories = dirArg >= 0 ? [args[dirArg + 1]] : ['src', 'tests', 'test'];

  const config: ScannerConfig = {
    directories: directories.filter((dir) => {
      try {
        statSync(dir);
        return true;
      } catch {
        return false;
      }
    }),
    includePatterns: ['.ts', '.tsx', '.js', '.jsx'],
    excludePatterns: ['node_modules', 'dist', 'build', '.git', 'coverage'],
    phiPatterns: PHI_PATTERNS,
  };

  console.log('🔍 Scanning for PHI logging violations...\n');
  console.log(`Directories: ${config.directories.join(', ')}\n`);

  const scanner = new PHILogScanner(config);
  const violations = scanner.scan();
  const stats = scanner.getStats();

  generateReport(violations, stats);

  // Exit with error code if violations found
  const errorCount = violations.filter((v) => v.severity === 'error').length;
  process.exit(errorCount > 0 ? 1 : 0);
}

// Run if executed directly (ES module compatible with tsx)
// When run with tsx, always execute main() since this is a standalone script
main();

export { PHILogScanner, PHI_PATTERNS, type Violation, type ScannerConfig };
