/**
 * Modal Components Index
 * Barrel export for all modal components
 *
 * Agent CRM-15 Implementation
 */

// Base Modal Components
export { Modal } from './Modal';
export type { ModalProps } from './Modal';

export { ConfirmDialog } from './ConfirmDialog';
export type { ConfirmDialogProps } from './ConfirmDialog';

export { SlideOver } from './SlideOver';
export type { SlideOverProps } from './SlideOver';

// Entity Modals
export { CreateLeadModal } from './CreateLeadModal';
export type { CreateLeadModalProps } from './CreateLeadModal';

export { CreateDealModal } from './CreateDealModal';
export type { CreateDealModalProps } from './CreateDealModal';

export { CreateContactModal } from './CreateContactModal';
export type { CreateContactModalProps } from './CreateContactModal';

export { CreateCompanyModal } from './CreateCompanyModal';
export type { CreateCompanyModalProps } from './CreateCompanyModal';

export { LogActivityModal } from './LogActivityModal';
export type { LogActivityModalProps, EntityType } from './LogActivityModal';

export { ConvertLeadModal } from './ConvertLeadModal';
export type { ConvertLeadModalProps } from './ConvertLeadModal';

export { ContactDetailModal } from './ContactDetailModal';
export type { ContactDetailModalProps } from './ContactDetailModal';

export { CompanyDetailModal } from './CompanyDetailModal';
export type { CompanyDetailModalProps } from './CompanyDetailModal';

export { AssignRepModal } from './AssignRepModal';
export type { AssignRepModalProps } from './AssignRepModal';
