/**
 * Shared sanitization helpers for calendar providers.
 * Removes obvious PHI/PII before storing or sending to providers.
 */

export const DEFAULT_CALENDAR_TITLE = 'CRM Calendar Event';

const emailPattern = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi;
const phonePattern = /\+?\d[\d\s().-]{6,}\d/g;
const ssnPattern = /\b\d{3}-\d{2}-\d{4}\b/g;
const tokenPattern = /[A-Za-z0-9_\-]{24,}/g;
const likelyNamePattern = /\b[A-Z][a-z]+\s+[A-Z][A-Za-z]*\b/;

export function stripSensitive(text?: string): string | undefined {
  if (!text) return undefined;
  const sanitized = text
    .replace(emailPattern, '[redacted]')
    .replace(phonePattern, '[redacted]')
    .replace(ssnPattern, '[redacted]')
    .replace(tokenPattern, '[redacted]')
    .trim()
    .replace(/\s{2,}/g, ' ');
  return sanitized || undefined;
}

export function sanitizeTitle(title?: string, fallback = DEFAULT_CALENDAR_TITLE): string {
  const clean = stripSensitive(title) || fallback;
  return likelyNamePattern.test(clean) ? fallback : clean;
}

export function sanitizeDescription(description?: string): string | undefined {
  const clean = stripSensitive(description);
  if (!clean) return undefined;
  return likelyNamePattern.test(clean) ? undefined : clean;
}

export function sanitizeErrorMessage(message: string, fallback = 'Calendar request failed'): string {
  const clean = stripSensitive(message) || fallback;
  return clean.length > 200 ? `${clean.slice(0, 197)}...` : clean;
}

export function isoDateOnly(date: Date): string {
  return date.toISOString().split('T')[0] || '';
}
