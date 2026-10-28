/**
 * Settings Repository
 * Handles CRM settings persistence
 *
 * Agent CRM-20 Implementation
 * Dependencies: Agent CRM-01 (base repository patterns)
 *
 * Settings are stored as a single document at:
 * businesses/{businessId}/settings/crm
 */

import {
  doc,
  getDoc,
  setDoc,
  onSnapshot,
} from 'firebase/firestore';
import type { Firestore, DocumentSnapshot, Unsubscribe } from 'firebase/firestore';

import { getFirebaseDb } from '../../lib/firebase';
import { crmSettingsDoc } from '../../lib/collections';
import type { CRMSettings } from '../../types/models';
import type { SecurityContext, RepositoryResult } from './repository-types';
import { successResult, failedResult, toRepositoryError } from '../errors/repository-errors';

// ============================================
// Types
// ============================================

export interface SettingsUpdateData {
  defaultPipelineId?: string;
  defaultCurrency?: string;
  leadScoringEnabled?: boolean;
  dealRotting?: {
    enabled: boolean;
    thresholdDays: number;
  };
}

// Default settings for new businesses
const DEFAULT_SETTINGS: CRMSettings = {
  defaultCurrency: 'USD',
  leadScoringEnabled: false,
  dealRotting: {
    enabled: false,
    thresholdDays: 30,
  },
};

// ============================================
// Repository Implementation
// ============================================

class SettingsRepositoryImpl {
  private db: Firestore | null = null;

  private getDb(): Firestore {
    if (!this.db) {
      this.db = getFirebaseDb();
      if (!this.db) {
        throw new Error('Firestore not initialized');
      }
    }
    return this.db;
  }

  /**
   * Get CRM settings for a business
   * Returns default settings if none exist
   */
  async getSettings(context: SecurityContext): Promise<RepositoryResult<CRMSettings>> {
    try {
      const db = this.getDb();
      const docPath = crmSettingsDoc(context.businessId);
      const docRef = doc(db, docPath);
      const snapshot = await getDoc(docRef);

      if (!snapshot.exists()) {
        // Return default settings if not yet created
        return successResult(DEFAULT_SETTINGS);
      }

      const data = snapshot.data();
      const settings: CRMSettings = {
        defaultPipelineId: data.defaultPipelineId,
        defaultCurrency: data.defaultCurrency || 'USD',
        leadScoringEnabled: data.leadScoringEnabled ?? false,
        leadScoringRules: data.leadScoringRules,
        dealRotting: data.dealRotting ?? { enabled: false, thresholdDays: 30 },
      };

      return successResult(settings);
    } catch (error) {
      return failedResult(toRepositoryError(error, 'getSettings'));
    }
  }

  /**
   * Update CRM settings
   * Creates the document if it doesn't exist
   */
  async updateSettings(
    context: SecurityContext,
    updates: SettingsUpdateData
  ): Promise<RepositoryResult<CRMSettings>> {
    try {
      const db = this.getDb();
      const docPath = crmSettingsDoc(context.businessId);
      const docRef = doc(db, docPath);

      // Get current settings
      const snapshot = await getDoc(docRef);
      const currentData = snapshot.exists() ? snapshot.data() : DEFAULT_SETTINGS;

      // Merge updates
      const updatedSettings: CRMSettings = {
        ...currentData,
        ...updates,
        updatedAt: new Date(),
        updatedById: context.userId,
        updatedByName: context.userName,
      } as CRMSettings;

      // Write to Firestore
      await setDoc(docRef, updatedSettings, { merge: true });

      return successResult(updatedSettings);
    } catch (error) {
      return failedResult(toRepositoryError(error, 'updateSettings'));
    }
  }

  /**
   * Set default pipeline
   */
  async setDefaultPipeline(
    context: SecurityContext,
    pipelineId: string
  ): Promise<RepositoryResult<CRMSettings>> {
    return this.updateSettings(context, { defaultPipelineId: pipelineId });
  }

  /**
   * Update deal rotting settings
   */
  async updateDealRotting(
    context: SecurityContext,
    enabled: boolean,
    thresholdDays: number
  ): Promise<RepositoryResult<CRMSettings>> {
    return this.updateSettings(context, {
      dealRotting: { enabled, thresholdDays },
    });
  }

  /**
   * Toggle lead scoring
   */
  async toggleLeadScoring(
    context: SecurityContext,
    enabled: boolean
  ): Promise<RepositoryResult<CRMSettings>> {
    return this.updateSettings(context, { leadScoringEnabled: enabled });
  }

  /**
   * Subscribe to settings changes
   */
  subscribeToSettings(
    context: SecurityContext,
    callback: (settings: CRMSettings) => void,
    onError?: (error: Error) => void
  ): Unsubscribe {
    const db = this.getDb();
    const docPath = crmSettingsDoc(context.businessId);
    const docRef = doc(db, docPath);

    return onSnapshot(
      docRef,
      (snapshot: DocumentSnapshot) => {
        if (!snapshot.exists()) {
          callback(DEFAULT_SETTINGS);
          return;
        }

        const data = snapshot.data();
        const settings: CRMSettings = {
          defaultPipelineId: data.defaultPipelineId,
          defaultCurrency: data.defaultCurrency || 'USD',
          leadScoringEnabled: data.leadScoringEnabled ?? false,
          leadScoringRules: data.leadScoringRules,
          dealRotting: data.dealRotting ?? { enabled: false, thresholdDays: 30 },
        };
        callback(settings);
      },
      (error) => {
        onError?.(error);
      }
    );
  }

  /**
   * Initialize default settings for a new business
   */
  async initializeSettings(context: SecurityContext): Promise<RepositoryResult<CRMSettings>> {
    try {
      const db = this.getDb();
      const docPath = crmSettingsDoc(context.businessId);
      const docRef = doc(db, docPath);

      // Check if already exists
      const snapshot = await getDoc(docRef);
      if (snapshot.exists()) {
        return successResult(snapshot.data() as CRMSettings);
      }

      // Create with defaults
      const initialSettings: CRMSettings = {
        ...DEFAULT_SETTINGS,
        createdAt: new Date(),
        createdById: context.userId,
        createdByName: context.userName,
      } as unknown as CRMSettings;

      await setDoc(docRef, initialSettings);
      return successResult(initialSettings);
    } catch (error) {
      return failedResult(toRepositoryError(error, 'initializeSettings'));
    }
  }
}

// ============================================
// Singleton Export
// ============================================

let settingsRepositoryInstance: SettingsRepositoryImpl | null = null;

export function getSettingsRepository(): SettingsRepositoryImpl {
  if (!settingsRepositoryInstance) {
    settingsRepositoryInstance = new SettingsRepositoryImpl();
  }
  return settingsRepositoryInstance;
}

// For testing - reset instance
export function resetSettingsRepository(): void {
  settingsRepositoryInstance = null;
}

export type SettingsRepository = SettingsRepositoryImpl;
