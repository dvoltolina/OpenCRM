/**
 * DuplicateList Component
 * Displays a list of entities with potential duplicates
 *
 * Agent CRM-27 Implementation
 */

import type { DuplicateMatch, EntityType } from '../../services/DuplicateDetectionService';
import type { Lead, Client, Company } from '../../types/models';
import './duplicates.css';

// ============================================
// Types
// ============================================

export interface DuplicateListProps<T = Lead | Client | Company> {
  /** Entity type being displayed */
  entityType: EntityType;
  /** The original entity */
  entity: T;
  /** List of potential duplicates */
  matches: DuplicateMatch<T>[];
  /** Called when user clicks merge on a duplicate */
  onMerge?: (entity: T, duplicate: T) => void;
  /** Called when user clicks view on a duplicate */
  onView?: (duplicate: T) => void;
  /** Whether actions are disabled (e.g., during merge) */
  isDisabled?: boolean;
}

// ============================================
// Helper Functions
// ============================================

/**
 * Get confidence level label
 */
function getConfidenceLevel(confidence: number): 'high' | 'medium' | 'low' {
  if (confidence >= 90) return 'high';
  if (confidence >= 70) return 'medium';
  return 'low';
}

/**
 * Get entity display name
 */
function getEntityName(entity: Lead | Client | Company, entityType: EntityType): string {
  if (entityType === 'company') {
    const companyName = (entity as Company).name;
    return typeof companyName === 'string' && companyName ? companyName : 'Unknown Company';
  }

  if ('firstName' in entity && 'lastName' in entity) {
    return `${entity.firstName} ${entity.lastName}`;
  }

  return 'Unknown';
}

/**
 * Get entity contact info
 */
function getContactInfo(entity: Lead | Client | Company): string {
  const parts: string[] = [];

  if ('email' in entity && entity.email) {
    parts.push(entity.email);
  }

  if ('phone' in entity && entity.phone) {
    parts.push(entity.phone);
  }

  return parts.join(' • ');
}

/**
 * Get company info
 */
function getCompanyInfo(entity: Lead | Client | Company): string | undefined {
  if ('companyName' in entity) {
    const name = (entity as Lead | Client).companyName;
    if (typeof name === 'string' && name) {
      return name;
    }
  }

  return undefined;
}

/**
 * Format match details
 */
function formatMatchDetails(match: DuplicateMatch): string {
  const details: string[] = [];

  if (match.matchDetails.email) details.push('Email');
  if (match.matchDetails.phone) details.push('Phone');
  if (match.matchDetails.name) details.push('Name');
  if (match.matchDetails.company) details.push('Company');

  return details.join(', ');
}

// ============================================
// Component
// ============================================

/**
 * DuplicateList - Display potential duplicate entities
 *
 * @example
 * ```tsx
 * <DuplicateList
 *   entityType="client"
 *   entity={client}
 *   matches={duplicateMatches}
 *   onMerge={(primary, secondary) => {
 *     setMergeData({ primary, secondary });
 *     setShowMergeModal(true);
 *   }}
 *   onView={(duplicate) => {
 *     navigate(`/clients/${duplicate.id}`);
 *   }}
 * />
 * ```
 */
export function DuplicateList<T extends Lead | Client | Company>({
  entityType,
  entity,
  matches,
  onMerge,
  onView,
  isDisabled = false,
}: DuplicateListProps<T>) {
  if (matches.length === 0) {
    return (
      <div className="duplicate-list duplicate-list--empty">
        <p className="duplicate-list__empty-message">
          No potential duplicates found for this {entityType}.
        </p>
      </div>
    );
  }

  return (
    <div className="duplicate-list">
      <div className="duplicate-list__header">
        <h3 className="duplicate-list__title">
          Potential Duplicates ({matches.length})
        </h3>
        <p className="duplicate-list__subtitle">
          Review these potential matches and merge if appropriate
        </p>
      </div>

      {/* Original Entity Card */}
      <div className="duplicate-card duplicate-card--original">
        <div className="duplicate-card__header">
          <span className="duplicate-card__badge">Original</span>
        </div>
        <div className="duplicate-card__body">
          <h4 className="duplicate-card__name">{getEntityName(entity, entityType)}</h4>
          <p className="duplicate-card__contact">{getContactInfo(entity)}</p>
          {getCompanyInfo(entity) && (
            <p className="duplicate-card__company">{getCompanyInfo(entity)}</p>
          )}
        </div>
      </div>

      {/* Duplicate Matches */}
      <div className="duplicate-list__matches">
        {matches.map((match) => {
          const level = getConfidenceLevel(match.confidence);

          return (
            <div key={match.entity.id} className="duplicate-card">
              <div className="duplicate-card__header">
                <span className={`duplicate-card__badge duplicate-card__badge--${level}`}>
                  {match.confidence}% Match
                </span>
                <span className="duplicate-card__confidence-label">
                  {level === 'high' ? 'High Confidence' : level === 'medium' ? 'Medium Confidence' : 'Low Confidence'}
                </span>
              </div>

              <div className="duplicate-card__body">
                <h4 className="duplicate-card__name">
                  {getEntityName(match.entity, entityType)}
                </h4>
                <p className="duplicate-card__contact">{getContactInfo(match.entity)}</p>
                {getCompanyInfo(match.entity) && (
                  <p className="duplicate-card__company">{getCompanyInfo(match.entity)}</p>
                )}

                <div className="duplicate-card__details">
                  <span className="duplicate-card__details-label">Matched on:</span>
                  <span className="duplicate-card__details-value">
                    {formatMatchDetails(match)}
                  </span>
                </div>
              </div>

              <div className="duplicate-card__actions">
                {onView && (
                  <button
                    type="button"
                    className="duplicate-card__action duplicate-card__action--view"
                    onClick={() => onView(match.entity)}
                    disabled={isDisabled}
                  >
                    View Details
                  </button>
                )}
                {onMerge && (
                  <button
                    type="button"
                    className="duplicate-card__action duplicate-card__action--merge"
                    onClick={() => onMerge(entity, match.entity)}
                    disabled={isDisabled}
                  >
                    Merge Records
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

export default DuplicateList;
