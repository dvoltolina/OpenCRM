/**
 * Formatting Utilities
 * Agent CRM-21 Implementation
 *
 * Provides consistent formatting for currency, dates, and other display values.
 * Currency values are stored in cents (integers) to avoid floating-point errors.
 */

// ============================================
// Currency Formatting
// ============================================

/**
 * Format cents to currency display string
 *
 * @param valueCents - Value in cents (integer)
 * @param currency - Currency code (default: 'USD')
 * @param locale - Locale for formatting (default: 'en-US')
 * @returns Formatted currency string (e.g., "$1,234.56")
 *
 * @example
 * ```ts
 * formatCurrency(123456, 'USD'); // "$1,234.56"
 * formatCurrency(100, 'EUR');    // "€1.00"
 * formatCurrency(0);             // "$0.00"
 * ```
 */
export function formatCurrency(
  valueCents: number,
  currency: string = 'USD',
  locale: string = 'en-US'
): string {
  const valueInDollars = valueCents / 100;
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(valueInDollars);
}

/**
 * Format cents to compact currency (e.g., "$1.2K", "$5M")
 *
 * @param valueCents - Value in cents (integer)
 * @param currency - Currency code (default: 'USD')
 * @param locale - Locale for formatting (default: 'en-US')
 * @returns Compact formatted string
 *
 * @example
 * ```ts
 * formatCurrencyCompact(1234567, 'USD'); // "$12.3K"
 * formatCurrencyCompact(123456789);      // "$1.2M"
 * ```
 */
export function formatCurrencyCompact(
  valueCents: number,
  currency: string = 'USD',
  locale: string = 'en-US'
): string {
  const valueInDollars = valueCents / 100;
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
    notation: 'compact',
    maximumFractionDigits: 1,
  }).format(valueInDollars);
}

/**
 * Parse a currency string or number to cents
 *
 * @param value - Value in dollars (number or string)
 * @returns Value in cents (integer)
 *
 * @example
 * ```ts
 * parseToCents(12.34);   // 1234
 * parseToCents('12.34'); // 1234
 * parseToCents(100);     // 10000
 * ```
 */
export function parseToCents(value: number | string): number {
  const numValue = typeof value === 'string' ? parseFloat(value) : value;
  if (isNaN(numValue)) return 0;
  return Math.round(numValue * 100);
}

/**
 * Convert cents to dollars (for calculations)
 *
 * @param valueCents - Value in cents
 * @returns Value in dollars
 */
export function centsToDollars(valueCents: number): number {
  return valueCents / 100;
}

// ============================================
// Number Formatting
// ============================================

/**
 * Format a number with locale-specific separators
 *
 * @param value - Number to format
 * @param locale - Locale for formatting (default: 'en-US')
 * @returns Formatted number string
 *
 * @example
 * ```ts
 * formatNumber(1234567); // "1,234,567"
 * ```
 */
export function formatNumber(value: number, locale: string = 'en-US'): string {
  return new Intl.NumberFormat(locale).format(value);
}

/**
 * Format a percentage value
 *
 * @param value - Decimal or whole number (0-100 or 0-1)
 * @param decimals - Number of decimal places (default: 0)
 * @returns Formatted percentage string
 *
 * @example
 * ```ts
 * formatPercent(75);    // "75%"
 * formatPercent(0.75);  // "75%"
 * formatPercent(33.33, 1); // "33.3%"
 * ```
 */
export function formatPercent(value: number, decimals: number = 0): string {
  // If value is between 0 and 1, treat as decimal
  const percentValue = value <= 1 && value >= 0 ? value * 100 : value;
  return `${percentValue.toFixed(decimals)}%`;
}

// ============================================
// Date Formatting
// ============================================

/**
 * Format a date for display
 *
 * @param date - Date to format
 * @param options - Intl.DateTimeFormat options
 * @param locale - Locale for formatting (default: 'en-US')
 * @returns Formatted date string
 *
 * @example
 * ```ts
 * formatDate(new Date()); // "Jan 15, 2025"
 * ```
 */
export function formatDate(
  date: Date | undefined | null,
  options: Intl.DateTimeFormatOptions = {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  },
  locale: string = 'en-US'
): string {
  if (!date) return '-';
  return new Intl.DateTimeFormat(locale, options).format(date);
}

/**
 * Format a date with time
 *
 * @param date - Date to format
 * @param locale - Locale for formatting (default: 'en-US')
 * @returns Formatted date/time string
 *
 * @example
 * ```ts
 * formatDateTime(new Date()); // "Jan 15, 2025, 3:30 PM"
 * ```
 */
export function formatDateTime(
  date: Date | undefined | null,
  locale: string = 'en-US'
): string {
  if (!date) return '-';
  return new Intl.DateTimeFormat(locale, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(date);
}

/**
 * Format relative time (e.g., "2 hours ago", "in 3 days")
 *
 * @param date - Date to compare
 * @param locale - Locale for formatting (default: 'en-US')
 * @returns Relative time string
 *
 * @example
 * ```ts
 * formatRelativeTime(new Date(Date.now() - 3600000)); // "1 hour ago"
 * ```
 */
export function formatRelativeTime(
  date: Date | undefined | null,
  locale: string = 'en-US'
): string {
  if (!date) return '-';

  const now = new Date();
  const diffMs = date.getTime() - now.getTime();
  const diffSecs = Math.round(diffMs / 1000);
  const diffMins = Math.round(diffSecs / 60);
  const diffHours = Math.round(diffMins / 60);
  const diffDays = Math.round(diffHours / 24);

  const rtf = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' });

  if (Math.abs(diffSecs) < 60) {
    return rtf.format(diffSecs, 'second');
  } else if (Math.abs(diffMins) < 60) {
    return rtf.format(diffMins, 'minute');
  } else if (Math.abs(diffHours) < 24) {
    return rtf.format(diffHours, 'hour');
  } else if (Math.abs(diffDays) < 30) {
    return rtf.format(diffDays, 'day');
  } else {
    return formatDate(date);
  }
}

// ============================================
// String Formatting
// ============================================

/**
 * Format a phone number for display
 *
 * @param phone - Phone number string
 * @returns Formatted phone string
 *
 * @example
 * ```ts
 * formatPhone('5551234567');   // "(555) 123-4567"
 * formatPhone('+15551234567'); // "+1 (555) 123-4567"
 * ```
 */
export function formatPhone(phone: string | undefined | null): string {
  if (!phone) return '-';

  // Remove all non-digits except leading +
  const hasPlus = phone.startsWith('+');
  const digits = phone.replace(/\D/g, '');

  if (digits.length === 10) {
    return `(${digits.slice(0, 3)}) ${digits.slice(3, 6)}-${digits.slice(6)}`;
  } else if (digits.length === 11 && digits.startsWith('1')) {
    return `+1 (${digits.slice(1, 4)}) ${digits.slice(4, 7)}-${digits.slice(7)}`;
  } else if (hasPlus) {
    return `+${digits}`;
  }

  return phone;
}

/**
 * Truncate a string with ellipsis
 *
 * @param str - String to truncate
 * @param maxLength - Maximum length (default: 50)
 * @returns Truncated string
 */
export function truncate(str: string | undefined | null, maxLength: number = 50): string {
  if (!str) return '';
  if (str.length <= maxLength) return str;
  return `${str.slice(0, maxLength - 3)}...`;
}

/**
 * Format a full name from parts
 *
 * @param firstName - First name
 * @param lastName - Last name
 * @returns Full name string
 */
export function formatFullName(
  firstName: string | undefined | null,
  lastName: string | undefined | null
): string {
  const parts = [firstName, lastName].filter(Boolean);
  return parts.join(' ') || 'Unknown';
}
