/**
 * Formatting Utilities
 * Agent CRM-35: Enhanced with locale support and i18n readiness
 *
 * Provides consistent formatting for currency, dates, and other display values.
 * Currency values are stored in cents (integers) to avoid floating-point errors.
 * All formatters support locale parameter for internationalization.
 */

// ============================================
// Locale Configuration
// ============================================

/**
 * Get current locale from settings or browser
 * This can be extended to read from user settings/preferences
 */
export function getCurrentLocale(): string {
  // TODO: Integrate with user settings when available
  // For now, use browser locale or fallback to en-US
  if (typeof navigator !== 'undefined' && navigator.language) {
    return navigator.language;
  }
  return 'en-US';
}

/**
 * Get default currency from business settings
 * This can be extended to read from business settings
 */
export function getDefaultCurrency(): string {
  // TODO: Integrate with business settings when available
  return 'USD';
}

// ============================================
// Currency Formatting
// ============================================

/**
 * Format cents to currency display string
 *
 * @param valueCents - Value in cents (integer)
 * @param currency - Currency code (default: USD)
 * @param locale - Locale for formatting (default: auto-detect)
 * @returns Formatted currency string (e.g., "$1,234.56")
 *
 * @example
 * ```ts
 * formatCurrency(123456, 'USD'); // "$1,234.56"
 * formatCurrency(100, 'EUR', 'de-DE');    // "1,00 €"
 * formatCurrency(0);             // "$0.00"
 * ```
 */
export function formatCurrency(
  valueCents: number,
  currency?: string,
  locale?: string
): string {
  const valueInDollars = valueCents / 100;
  const useCurrency = currency || getDefaultCurrency();
  const useLocale = locale || getCurrentLocale();

  return new Intl.NumberFormat(useLocale, {
    style: 'currency',
    currency: useCurrency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(valueInDollars);
}

/**
 * Format cents to compact currency (e.g., "$1.2K", "$5M")
 *
 * @param valueCents - Value in cents (integer)
 * @param currency - Currency code (default: USD)
 * @param locale - Locale for formatting (default: auto-detect)
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
  currency?: string,
  locale?: string
): string {
  const valueInDollars = valueCents / 100;
  const useCurrency = currency || getDefaultCurrency();
  const useLocale = locale || getCurrentLocale();

  return new Intl.NumberFormat(useLocale, {
    style: 'currency',
    currency: useCurrency,
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
 * @param locale - Locale for formatting (default: auto-detect)
 * @param options - Additional formatting options
 * @returns Formatted number string
 *
 * @example
 * ```ts
 * formatNumber(1234567); // "1,234,567"
 * formatNumber(1234.56, 'de-DE'); // "1.234,56"
 * ```
 */
export function formatNumber(
  value: number,
  locale?: string,
  options?: Intl.NumberFormatOptions
): string {
  const useLocale = locale || getCurrentLocale();
  return new Intl.NumberFormat(useLocale, options).format(value);
}

/**
 * Format a percentage value
 *
 * @param value - Decimal or whole number (0-100 or 0-1)
 * @param decimals - Number of decimal places (default: 0)
 * @param locale - Locale for formatting (default: auto-detect)
 * @returns Formatted percentage string
 *
 * @example
 * ```ts
 * formatPercent(75);    // "75%"
 * formatPercent(0.75);  // "75%"
 * formatPercent(33.33, 1); // "33.3%"
 * ```
 */
export function formatPercent(
  value: number,
  decimals: number = 0,
  locale?: string
): string {
  // If value is between 0 and 1, treat as decimal
  const percentValue = value <= 1 && value >= 0 ? value * 100 : value;
  const useLocale = locale || getCurrentLocale();

  return new Intl.NumberFormat(useLocale, {
    style: 'percent',
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(percentValue / 100);
}

// ============================================
// Date Formatting
// ============================================

/**
 * Format a date for display
 *
 * @param date - Date to format
 * @param format - Format style or custom options
 * @param locale - Locale for formatting (default: auto-detect)
 * @returns Formatted date string
 *
 * @example
 * ```ts
 * formatDate(new Date()); // "Jan 15, 2025"
 * formatDate(new Date(), 'short'); // "1/15/25"
 * formatDate(new Date(), 'long', 'de-DE'); // "15. Januar 2025"
 * ```
 */
export function formatDate(
  date: Date | undefined | null,
  format?: 'short' | 'medium' | 'long' | 'full' | Intl.DateTimeFormatOptions,
  locale?: string
): string {
  if (!date) return '-';

  const useLocale = locale || getCurrentLocale();
  let options: Intl.DateTimeFormatOptions;

  if (!format || typeof format === 'string') {
    const style = format || 'medium';
    options = {
      dateStyle: style as 'short' | 'medium' | 'long' | 'full',
    };
  } else {
    options = format;
  }

  return new Intl.DateTimeFormat(useLocale, options).format(date);
}

/**
 * Format a date with time
 *
 * @param date - Date to format
 * @param locale - Locale for formatting (default: auto-detect)
 * @returns Formatted date/time string
 *
 * @example
 * ```ts
 * formatDateTime(new Date()); // "Jan 15, 2025, 3:30 PM"
 * formatDateTime(new Date(), 'de-DE'); // "15. Jan. 2025, 15:30"
 * ```
 */
export function formatDateTime(
  date: Date | undefined | null,
  locale?: string
): string {
  if (!date) return '-';

  const useLocale = locale || getCurrentLocale();
  return new Intl.DateTimeFormat(useLocale, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date);
}

/**
 * Format time only
 *
 * @param date - Date to format
 * @param locale - Locale for formatting (default: auto-detect)
 * @returns Formatted time string
 *
 * @example
 * ```ts
 * formatTime(new Date()); // "3:30 PM"
 * formatTime(new Date(), 'de-DE'); // "15:30"
 * ```
 */
export function formatTime(
  date: Date | undefined | null,
  locale?: string
): string {
  if (!date) return '-';

  const useLocale = locale || getCurrentLocale();
  return new Intl.DateTimeFormat(useLocale, {
    timeStyle: 'short',
  }).format(date);
}

/**
 * Format relative time (e.g., "2 hours ago", "in 3 days")
 *
 * @param date - Date to compare
 * @param locale - Locale for formatting (default: auto-detect)
 * @returns Relative time string
 *
 * @example
 * ```ts
 * formatRelativeTime(new Date(Date.now() - 3600000)); // "1 hour ago"
 * formatRelativeTime(new Date(Date.now() + 86400000)); // "in 1 day"
 * ```
 */
export function formatRelativeTime(
  date: Date | undefined | null,
  locale?: string
): string {
  if (!date) return '-';

  const useLocale = locale || getCurrentLocale();
  const now = new Date();
  const diffMs = date.getTime() - now.getTime();
  const diffSecs = Math.round(diffMs / 1000);
  const diffMins = Math.round(diffSecs / 60);
  const diffHours = Math.round(diffMins / 60);
  const diffDays = Math.round(diffHours / 24);
  const diffWeeks = Math.round(diffDays / 7);
  const diffMonths = Math.round(diffDays / 30);

  const rtf = new Intl.RelativeTimeFormat(useLocale, { numeric: 'auto' });

  if (Math.abs(diffSecs) < 60) {
    return rtf.format(diffSecs, 'second');
  } else if (Math.abs(diffMins) < 60) {
    return rtf.format(diffMins, 'minute');
  } else if (Math.abs(diffHours) < 24) {
    return rtf.format(diffHours, 'hour');
  } else if (Math.abs(diffDays) < 7) {
    return rtf.format(diffDays, 'day');
  } else if (Math.abs(diffWeeks) < 4) {
    return rtf.format(diffWeeks, 'week');
  } else if (Math.abs(diffMonths) < 12) {
    return rtf.format(diffMonths, 'month');
  } else {
    return formatDate(date, 'medium', useLocale);
  }
}

// ============================================
// String Formatting
// ============================================

/**
 * Format a phone number for display
 *
 * @param phone - Phone number string
 * @param locale - Locale for formatting (default: auto-detect)
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

  // US/Canada format
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

/**
 * Get initials from a name
 *
 * @param name - Full name or parts
 * @param firstName - Optional first name (if name is full name)
 * @param lastName - Optional last name
 * @returns Initials (max 2 characters)
 *
 * @example
 * ```ts
 * getInitials('John Doe'); // "JD"
 * getInitials('', 'Jane', 'Smith'); // "JS"
 * ```
 */
export function getInitials(
  name: string,
  firstName?: string,
  lastName?: string
): string {
  if (firstName && lastName) {
    return `${firstName[0]}${lastName[0]}`.toUpperCase();
  }

  return name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}

// ============================================
// List Formatting
// ============================================

/**
 * Format a list of items with locale-aware conjunctions
 *
 * @param items - Array of items to format
 * @param locale - Locale for formatting (default: auto-detect)
 * @param type - List type (default: 'conjunction')
 * @returns Formatted list string
 *
 * @example
 * ```ts
 * formatList(['apples', 'oranges', 'bananas']); // "apples, oranges, and bananas"
 * formatList(['John', 'Jane'], 'en-US', 'disjunction'); // "John or Jane"
 * ```
 */
export function formatList(
  items: string[],
  locale?: string,
  type: 'conjunction' | 'disjunction' = 'conjunction'
): string {
  if (items.length === 0) return '';
  if (items.length === 1) return items[0];

  const useLocale = locale || getCurrentLocale();
  const formatter = new Intl.ListFormat(useLocale, {
    style: 'long',
    type
  });

  return formatter.format(items);
}
