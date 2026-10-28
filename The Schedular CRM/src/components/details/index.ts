/**
 * Detail View Components Index
 * Barrel export for all detail view components
 *
 * Agent CRM-17 Implementation
 */

// Shared Components
export { DetailHeader } from './DetailHeader';
export type { DetailHeaderProps, Badge, DetailHeaderAction } from './DetailHeader';

export { DetailSection } from './DetailSection';
export type { DetailSectionProps } from './DetailSection';

export { DetailTabs } from './DetailTabs';
export type { DetailTabConfig } from './DetailTabs';

export { RelatedList } from './RelatedList';
export type { RelatedListProps, RelatedItem } from './RelatedList';

export { ActivityTimeline } from './ActivityTimeline';
export type { ActivityTimelineProps } from './ActivityTimeline';

// Entity Detail Views
export { LeadDetail } from './LeadDetail';
export type { LeadDetailProps } from './LeadDetail';

export { DealDetail } from './DealDetail';
export type { DealDetailProps } from './DealDetail';
export { DealDocumentsTab } from './DealDocumentsTab';

export { ContactDetail } from './ContactDetail';
export type { ContactDetailProps } from './ContactDetail';

export { CompanyDetail } from './CompanyDetail';
export type { CompanyDetailProps } from './CompanyDetail';
