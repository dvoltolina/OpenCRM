/**
 * ConfirmDialog Component
 * Confirmation dialog for destructive or important actions
 *
 * Agent CRM-15 Implementation
 * Agent CRM-35: Enhanced with improved accessibility
 */

import type { ReactNode } from 'react';
import { Modal } from './Modal';
import { FormButton } from '../forms/FormField';
import './modals.css';

// ============================================
// Types
// ============================================

export interface ConfirmDialogProps {
  /** Whether the dialog is open */
  isOpen: boolean;
  /** Called when user confirms */
  onConfirm: () => void;
  /** Called when user cancels */
  onCancel: () => void;
  /** Dialog title */
  title: string;
  /** Dialog message */
  message: ReactNode;
  /** Text for confirm button */
  confirmText?: string;
  /** Text for cancel button */
  cancelText?: string;
  /** Dialog variant for styling */
  variant?: 'danger' | 'warning' | 'info';
  /** Whether the confirm action is in progress */
  isLoading?: boolean;
}

// ============================================
// Icons
// ============================================

function DangerIcon() {
  return (
    <svg
      width="48"
      height="48"
      viewBox="0 0 48 48"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <circle cx="24" cy="24" r="20" stroke="currentColor" strokeWidth="2" />
      <path
        d="M24 16V26M24 32H24.02"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function WarningIcon() {
  return (
    <svg
      width="48"
      height="48"
      viewBox="0 0 48 48"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M24 8L4 40H44L24 8Z"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinejoin="round"
      />
      <path
        d="M24 20V28M24 34H24.02"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function InfoIcon() {
  return (
    <svg
      width="48"
      height="48"
      viewBox="0 0 48 48"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <circle cx="24" cy="24" r="20" stroke="currentColor" strokeWidth="2" />
      <path
        d="M24 22V32M24 16H24.02"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

// ============================================
// Component
// ============================================

/**
 * ConfirmDialog - Confirmation dialog for actions
 *
 * @example
 * ```tsx
 * <ConfirmDialog
 *   isOpen={showDeleteConfirm}
 *   onConfirm={handleDelete}
 *   onCancel={() => setShowDeleteConfirm(false)}
 *   title="Delete Lead"
 *   message="Are you sure you want to delete this lead? This action cannot be undone."
 *   variant="danger"
 *   confirmText="Delete"
 *   isLoading={isDeleting}
 * />
 * ```
 */
export function ConfirmDialog({
  isOpen,
  onConfirm,
  onCancel,
  title,
  message,
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  variant = 'info',
  isLoading = false,
}: ConfirmDialogProps) {
  const Icon = variant === 'danger' ? DangerIcon : variant === 'warning' ? WarningIcon : InfoIcon;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onCancel}
      title={title}
      size="sm"
      closeOnOverlayClick={!isLoading}
      closeOnEscape={!isLoading}
    >
      <div className="confirm-dialog">
        <div
          className={`confirm-dialog__icon confirm-dialog__icon--${variant}`}
          role="img"
          aria-label={
            variant === 'danger'
              ? 'Danger icon'
              : variant === 'warning'
              ? 'Warning icon'
              : 'Information icon'
          }
        >
          <Icon />
        </div>
        <p className="confirm-dialog__message" id="confirm-dialog-description">
          {message}
        </p>
        <div className="confirm-dialog__actions">
          <FormButton
            type="button"
            variant="secondary"
            onClick={onCancel}
            disabled={isLoading}
            aria-label={`${cancelText} ${title.toLowerCase()}`}
          >
            {cancelText}
          </FormButton>
          <FormButton
            type="button"
            variant={variant === 'danger' ? 'danger' : 'primary'}
            onClick={onConfirm}
            isLoading={isLoading}
            aria-label={`${confirmText} ${title.toLowerCase()}`}
            aria-describedby="confirm-dialog-description"
          >
            {confirmText}
          </FormButton>
        </div>
      </div>
    </Modal>
  );
}

export default ConfirmDialog;
