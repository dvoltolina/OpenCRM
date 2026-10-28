/**
 * ConfirmDialog Component Tests
 *
 * Agent CRM-15 Implementation
 *
 * Test Scenarios:
 * 1. Shows title and message
 * 2. Calls onConfirm when confirmed
 * 3. Calls onCancel when cancelled
 * 4. Shows loading state
 * 5. Danger variant styling
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { ConfirmDialog } from '../ConfirmDialog';

// ============================================
// Setup
// ============================================

// Mock createPortal to render in the same container
vi.mock('react-dom', async () => {
  const actual = await vi.importActual('react-dom');
  return {
    ...actual,
    createPortal: (node: React.ReactNode) => node,
  };
});

describe('ConfirmDialog', () => {
  const mockOnConfirm = vi.fn();
  const mockOnCancel = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: Shows title and message
  // ============================================
  it('shows title and message', () => {
    render(
      <ConfirmDialog
        isOpen={true}
        onConfirm={mockOnConfirm}
        onCancel={mockOnCancel}
        title="Delete Item"
        message="Are you sure you want to delete this item?"
      />
    );

    expect(screen.getByText('Delete Item')).toBeInTheDocument();
    expect(screen.getByText('Are you sure you want to delete this item?')).toBeInTheDocument();
  });

  // ============================================
  // Test 2: Calls onConfirm when confirmed
  // ============================================
  it('calls onConfirm when confirmed', () => {
    render(
      <ConfirmDialog
        isOpen={true}
        onConfirm={mockOnConfirm}
        onCancel={mockOnCancel}
        title="Confirm Action"
        message="Are you sure?"
        confirmText="Yes, do it"
      />
    );

    const confirmButton = screen.getByText('Yes, do it');
    fireEvent.click(confirmButton);

    expect(mockOnConfirm).toHaveBeenCalledTimes(1);
  });

  // ============================================
  // Test 3: Calls onCancel when cancelled
  // ============================================
  it('calls onCancel when cancelled', () => {
    render(
      <ConfirmDialog
        isOpen={true}
        onConfirm={mockOnConfirm}
        onCancel={mockOnCancel}
        title="Confirm Action"
        message="Are you sure?"
        cancelText="No, cancel"
      />
    );

    const cancelButton = screen.getByText('No, cancel');
    fireEvent.click(cancelButton);

    expect(mockOnCancel).toHaveBeenCalledTimes(1);
  });

  // ============================================
  // Test 4: Shows loading state
  // ============================================
  it('shows loading state', () => {
    render(
      <ConfirmDialog
        isOpen={true}
        onConfirm={mockOnConfirm}
        onCancel={mockOnCancel}
        title="Deleting..."
        message="Please wait while we delete the item."
        isLoading={true}
      />
    );

    // Cancel button should be disabled
    const cancelButton = screen.getByRole('button', { name: /cancel/i });
    expect(cancelButton).toBeDisabled();

    // Confirm button should be disabled (shows loading state)
    const confirmButton = screen.getByRole('button', { name: /confirm/i });
    expect(confirmButton).toBeDisabled();
  });

  // ============================================
  // Test 5: Danger variant styling
  // ============================================
  it('applies danger variant styling', () => {
    render(
      <ConfirmDialog
        isOpen={true}
        onConfirm={mockOnConfirm}
        onCancel={mockOnCancel}
        title="Delete"
        message="This action cannot be undone."
        variant="danger"
      />
    );

    // Check that the icon has danger class
    const icon = document.querySelector('.confirm-dialog__icon--danger');
    expect(icon).toBeInTheDocument();

    // Check that confirm button has danger variant
    const confirmButton = screen.getByText('Confirm');
    expect(confirmButton).toHaveClass('form-button--danger');
  });

  // ============================================
  // Additional Tests
  // ============================================
  it('applies warning variant styling', () => {
    render(
      <ConfirmDialog
        isOpen={true}
        onConfirm={mockOnConfirm}
        onCancel={mockOnCancel}
        title="Warning"
        message="This will affect other items."
        variant="warning"
      />
    );

    const icon = document.querySelector('.confirm-dialog__icon--warning');
    expect(icon).toBeInTheDocument();
  });

  it('uses default button text when not specified', () => {
    render(
      <ConfirmDialog
        isOpen={true}
        onConfirm={mockOnConfirm}
        onCancel={mockOnCancel}
        title="Action Required"
        message="Are you sure?"
      />
    );

    // Check that default "Confirm" and "Cancel" buttons exist (using regex for partial match with aria-label)
    expect(screen.getByRole('button', { name: /confirm/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /cancel/i })).toBeInTheDocument();
  });

  it('is hidden when isOpen is false', () => {
    render(
      <ConfirmDialog
        isOpen={false}
        onConfirm={mockOnConfirm}
        onCancel={mockOnCancel}
        title="Confirm"
        message="Are you sure?"
      />
    );

    expect(screen.queryByText('Confirm')).not.toBeInTheDocument();
    expect(screen.queryByText('Are you sure?')).not.toBeInTheDocument();
  });

  it('applies info variant styling by default', () => {
    render(
      <ConfirmDialog
        isOpen={true}
        onConfirm={mockOnConfirm}
        onCancel={mockOnCancel}
        title="Info"
        message="Just so you know..."
      />
    );

    const icon = document.querySelector('.confirm-dialog__icon--info');
    expect(icon).toBeInTheDocument();

    const confirmButton = screen.getByText('Confirm');
    expect(confirmButton).toHaveClass('form-button--primary');
  });
});
