export type SupportedImportEntity =
  | 'lead'
  | 'contact'
  | 'deal'
  | 'company'
  | 'client'
  | 'appointment';

export interface ImportRoutingDecision {
  entityType: SupportedImportEntity | 'multi';
  primaryEntityType?: 'lead' | 'contact' | 'deal' | 'company';
}

const CONTACT_MULTI_FIELDS = new Set([
  'dealTitle',
  'dealValueCents',
  'dealExpectedCloseDate',
  'dealNotes',
  'pipelineName',
  'stageName',
]);

export function getImportRoutingDecision(
  entityType: SupportedImportEntity,
  fieldMapping: Record<string, string>
): ImportRoutingDecision {
  if (entityType === 'deal') {
    return {
      entityType: 'multi',
      primaryEntityType: 'deal',
    };
  }

  if (entityType === 'contact') {
    const mappedFields = new Set(Object.values(fieldMapping).filter(Boolean));
    const usesDealFields = Array.from(CONTACT_MULTI_FIELDS).some((field) => mappedFields.has(field));

    if (usesDealFields) {
      return {
        entityType: 'multi',
        primaryEntityType: 'contact',
      };
    }
  }

  return { entityType };
}
