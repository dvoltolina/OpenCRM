/**
 * Integration Registry and Factory
 * Central registry for all native integrations with factory pattern
 *
 * Task 8: Native Integrations Framework
 *
 * Usage:
 * ```typescript
 * // Get an integration by provider
 * const slack = IntegrationRegistry.get('slack');
 * await slack.connect(context, authData);
 *
 * // Get all registered integrations
 * const all = IntegrationRegistry.getAll();
 *
 * // Check if provider is supported
 * const supported = IntegrationRegistry.isSupported('google_calendar');
 * ```
 */

import { BaseIntegration } from './base-integration';
import { SlackIntegration } from './slack-integration';
import { GoogleCalendarIntegration } from './google-calendar-integration';

// ============================================
// Integration Registry
// ============================================

/**
 * Central registry for all native integrations
 *
 * This registry uses a singleton pattern to maintain a single
 * instance of each integration class.
 */
export class IntegrationRegistry {
  private static integrations: Map<string, BaseIntegration> = new Map();
  private static initialized = false;

  /**
   * Initialize the registry with all available integrations
   */
  private static initialize(): void {
    if (this.initialized) return;

    // Register Slack integration
    const slack = new SlackIntegration();
    this.integrations.set(slack.provider, slack);

    // Register Google Calendar integration
    const googleCalendar = new GoogleCalendarIntegration();
    this.integrations.set(googleCalendar.provider, googleCalendar);

    // Future integrations can be added here:
    // const outlook = new OutlookIntegration();
    // this.integrations.set(outlook.provider, outlook);
    //
    // const salesforce = new SalesforceIntegration();
    // this.integrations.set(salesforce.provider, salesforce);

    this.initialized = true;
  }

  /**
   * Get an integration by provider name
   *
   * @param provider Provider identifier (e.g., 'slack', 'google_calendar')
   * @returns Integration instance or undefined if not found
   */
  static get(provider: string): BaseIntegration | undefined {
    this.initialize();
    return this.integrations.get(provider);
  }

  /**
   * Get all registered integrations
   *
   * @returns Array of all integration instances
   */
  static getAll(): BaseIntegration[] {
    this.initialize();
    return Array.from(this.integrations.values());
  }

  /**
   * Get all provider names
   *
   * @returns Array of provider identifiers
   */
  static getProviders(): string[] {
    this.initialize();
    return Array.from(this.integrations.keys());
  }

  /**
   * Check if a provider is supported
   *
   * @param provider Provider identifier
   * @returns True if provider is registered
   */
  static isSupported(provider: string): boolean {
    this.initialize();
    return this.integrations.has(provider);
  }

  /**
   * Get integration metadata
   *
   * @returns Array of integration metadata
   */
  static getMetadata(): Array<{
    provider: string;
    name: string;
    type: string;
  }> {
    this.initialize();
    return Array.from(this.integrations.values()).map((integration) => ({
      provider: integration.provider,
      name: integration.name,
      type: integration.type,
    }));
  }

  /**
   * Clear the registry (for testing)
   */
  static clear(): void {
    this.integrations.clear();
    this.initialized = false;
  }
}

// ============================================
// Integration Factory
// ============================================

/**
 * Factory for creating integration instances
 *
 * Alternative to using the registry directly, provides
 * more explicit error handling.
 */
export class IntegrationFactory {
  /**
   * Create an integration instance by provider
   *
   * @param provider Provider identifier
   * @returns Integration instance
   * @throws Error if provider is not supported
   */
  static create(provider: string): BaseIntegration {
    const integration = IntegrationRegistry.get(provider);

    if (!integration) {
      const supported = IntegrationRegistry.getProviders().join(', ');
      throw new Error(
        `Unsupported integration provider: ${provider}. Supported providers: ${supported}`
      );
    }

    return integration;
  }

  /**
   * Check if a provider is supported
   *
   * @param provider Provider identifier
   * @returns True if provider is supported
   */
  static isSupported(provider: string): boolean {
    return IntegrationRegistry.isSupported(provider);
  }

  /**
   * Get all supported providers
   *
   * @returns Array of provider identifiers
   */
  static getSupportedProviders(): string[] {
    return IntegrationRegistry.getProviders();
  }
}

// ============================================
// Exports
// ============================================

// Export base class for extending
export { BaseIntegration } from './base-integration';
export type {
  OAuthAuthData,
  IntegrationSyncResult,
  WebhookHandlerResult,
} from './base-integration';

// Export concrete integrations
export { SlackIntegration } from './slack-integration';
export { GoogleCalendarIntegration } from './google-calendar-integration';
export type {
  CalendarEventInput,
  CalendarEventUpdateInput,
} from './google-calendar-integration';

// Default export is the registry
export default IntegrationRegistry;
