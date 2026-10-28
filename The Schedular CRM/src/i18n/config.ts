/**
 * i18n Configuration
 * Agent CRM-35: Internationalization scaffold
 *
 * Simple i18n system with namespaced translations.
 * This provides a lightweight solution without requiring a full i18n framework.
 */

import { translations as enTranslations } from './en';

// ============================================
// Types
// ============================================

export type Locale = 'en'; // Add more locales here: 'es', 'fr', 'de', etc.

export interface Translations {
  common: Record<string, string>;
  leads: Record<string, string>;
  deals: Record<string, string>;
  contacts: Record<string, string>;
  companies: Record<string, string>;
  settings: Record<string, string>;
  pipeline: Record<string, string>;
  dashboard: Record<string, string>;
  forms: Record<string, string>;
  errors: Record<string, string>;
  actions: Record<string, string>;
}

export type TranslationKey = keyof Translations;
export type TranslationNamespace<T extends TranslationKey> = keyof Translations[T];

// ============================================
// Translation Store
// ============================================

/**
 * Available translations by locale
 */
const translationStore: Record<Locale, Translations> = {
  en: enTranslations,
  // Add more locales here:
  // es: esTranslations,
  // fr: frTranslations,
};

// ============================================
// Current Locale Management
// ============================================

let currentLocale: Locale = 'en';

/**
 * Set the current locale
 * @param locale - Locale to use
 */
export function setLocale(locale: Locale): void {
  if (!translationStore[locale]) {
    console.warn(`Locale "${locale}" not found, falling back to "en"`);
    currentLocale = 'en';
    return;
  }
  currentLocale = locale;
}

/**
 * Get the current locale
 * @returns Current locale
 */
export function getLocale(): Locale {
  return currentLocale;
}

/**
 * Get available locales
 * @returns Array of available locale codes
 */
export function getAvailableLocales(): Locale[] {
  return Object.keys(translationStore) as Locale[];
}

// ============================================
// Translation Functions
// ============================================

/**
 * Get a translated string by key
 *
 * @param namespace - Translation namespace (e.g., 'common', 'leads')
 * @param key - Translation key within namespace
 * @param fallback - Optional fallback text if key not found
 * @returns Translated string
 *
 * @example
 * ```ts
 * t('common', 'save'); // "Save"
 * t('leads', 'new_lead'); // "New Lead"
 * t('unknown', 'key', 'Default Text'); // "Default Text"
 * ```
 */
export function t(
  namespace: TranslationKey,
  key: string,
  fallback?: string
): string {
  const translations = translationStore[currentLocale];
  const namespaceTranslations = translations[namespace];

  if (!namespaceTranslations) {
    console.warn(`Translation namespace "${namespace}" not found`);
    return fallback || key;
  }

  const translation = namespaceTranslations[key];
  if (!translation) {
    console.warn(`Translation key "${namespace}.${key}" not found`);
    return fallback || key;
  }

  return translation;
}

/**
 * Get a translated string with variable interpolation
 *
 * @param namespace - Translation namespace
 * @param key - Translation key
 * @param variables - Object with variables to interpolate
 * @returns Translated and interpolated string
 *
 * @example
 * ```ts
 * // With translation: "Hello, {{name}}!"
 * tVar('common', 'greeting', { name: 'John' }); // "Hello, John!"
 * ```
 */
export function tVar(
  namespace: TranslationKey,
  key: string,
  variables: Record<string, string | number>
): string {
  let translation = t(namespace, key);

  // Replace {{variable}} patterns
  Object.entries(variables).forEach(([varKey, value]) => {
    translation = translation.replace(
      new RegExp(`{{\\s*${varKey}\\s*}}`, 'g'),
      String(value)
    );
  });

  return translation;
}

/**
 * Get plural form of a translation
 *
 * @param namespace - Translation namespace
 * @param key - Translation key (should have _one and _other suffixes)
 * @param count - Count to determine plural form
 * @param variables - Optional variables to interpolate
 * @returns Translated plural string
 *
 * @example
 * ```ts
 * // With translations: "deal_count_one": "{{count}} deal", "deal_count_other": "{{count}} deals"
 * tPlural('deals', 'deal_count', 1); // "1 deal"
 * tPlural('deals', 'deal_count', 5); // "5 deals"
 * ```
 */
export function tPlural(
  namespace: TranslationKey,
  key: string,
  count: number,
  variables?: Record<string, string | number>
): string {
  const pluralKey = count === 1 ? `${key}_one` : `${key}_other`;
  const vars = { count, ...variables };
  return tVar(namespace, pluralKey, vars);
}

// ============================================
// Namespaced Translation Helpers
// ============================================

/**
 * Create a namespaced translator function
 * Useful for components that use many translations from one namespace
 *
 * @param namespace - Translation namespace to bind
 * @returns Translation function bound to namespace
 *
 * @example
 * ```ts
 * const tLeads = createNamespacedTranslator('leads');
 * tLeads('new_lead'); // "New Lead"
 * tLeads('status_new'); // "New"
 * ```
 */
export function createNamespacedTranslator(namespace: TranslationKey) {
  return (key: string, fallback?: string) => t(namespace, key, fallback);
}

// ============================================
// Validation
// ============================================

/**
 * Check if a translation key exists
 *
 * @param namespace - Translation namespace
 * @param key - Translation key
 * @returns True if key exists
 */
export function hasTranslation(namespace: TranslationKey, key: string): boolean {
  const translations = translationStore[currentLocale];
  const namespaceTranslations = translations[namespace];
  return Boolean(namespaceTranslations && namespaceTranslations[key]);
}

/**
 * Get all keys in a namespace
 * Useful for debugging and documentation
 *
 * @param namespace - Translation namespace
 * @returns Array of translation keys
 */
export function getNamespaceKeys(namespace: TranslationKey): string[] {
  const translations = translationStore[currentLocale];
  const namespaceTranslations = translations[namespace];
  return Object.keys(namespaceTranslations || {});
}
