/**
 * LeadForm Tests
 *
 * Agent CRM-14 Implementation
 *
 * Test Scenarios:
 * 1. Renders all fields
 * 2. Validates required fields
 * 3. Validates email format
 * 4. Calls onSubmit with form data
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { LeadForm } from '../LeadForm';

vi.mock('../../../hooks/useDuplicateDetection', () => ({
  useDuplicateDetection: () => ({
    checkEntity: vi.fn().mockResolvedValue([]),
    scanAll: vi.fn(),
    mergeEntities: vi.fn(),
    duplicates: [],
    duplicateGroups: [],
    isChecking: false,
    isScanning: false,
    isMerging: false,
    error: null,
    clearError: vi.fn(),
    clearDuplicates: vi.fn(),
  }),
}));

vi.mock('../../../context/AuthContext', () => ({
  useAuth: () => ({
    crmUser: {
      id: 'user-1',
      role: 'admin',
      displayName: 'Admin User',
      email: 'admin@example.com',
      teamIds: [],
      managedTeamIds: [],
    },
    businessId: 'biz-1',
  }),
}));

describe('LeadForm', () => {
  const mockOnSubmit = vi.fn();
  const mockOnCancel = vi.fn();

  const defaultProps = {
    onSubmit: mockOnSubmit,
    onCancel: mockOnCancel,
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: Renders all fields
  // ============================================
  it('renders all fields', () => {
    render(<LeadForm {...defaultProps} />);

    // Contact Information
    expect(screen.getByLabelText(/first name/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/last name/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/phone/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/company/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/title/i)).toBeInTheDocument();

    // Lead Details
    expect(screen.getByLabelText(/status/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/source/i)).toBeInTheDocument();

    // Additional
    expect(screen.getByLabelText(/notes/i)).toBeInTheDocument();

    // Buttons
    expect(screen.getByRole('button', { name: /create lead/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /cancel/i })).toBeInTheDocument();
  });

  // ============================================
  // Test 2: Validates required fields
  // ============================================
  it('validates required fields', async () => {
    render(<LeadForm {...defaultProps} />);

    // Submit empty form
    const submitButton = screen.getByRole('button', { name: /create lead/i });
    fireEvent.click(submitButton);

    // Wait for validation errors
    await waitFor(() => {
      expect(screen.getByText(/first name is required/i)).toBeInTheDocument();
      expect(screen.getByText(/last name is required/i)).toBeInTheDocument();
      expect(screen.getByText(/email is required/i)).toBeInTheDocument();
    });

    // onSubmit should NOT be called
    expect(mockOnSubmit).not.toHaveBeenCalled();
  });

  // ============================================
  // Test 3: Validates email format
  // ============================================
  it('validates email format', async () => {
    const user = userEvent.setup();
    render(<LeadForm {...defaultProps} />);

    // Fill in fields with invalid email
    await user.type(screen.getByLabelText(/first name/i), 'John');
    await user.type(screen.getByLabelText(/last name/i), 'Doe');
    await user.type(screen.getByLabelText(/email/i), 'invalid-email');

    // Submit form
    const submitButton = screen.getByRole('button', { name: /create lead/i });
    await user.click(submitButton);

    // Wait for form processing
    await new Promise((resolve) => setTimeout(resolve, 100));

    // With invalid email, onSubmit should NOT have been called
    expect(mockOnSubmit).not.toHaveBeenCalled();
  });

  // ============================================
  // Test 4: Calls onSubmit with form data
  // ============================================
  it('calls onSubmit with form data', async () => {
    mockOnSubmit.mockResolvedValue(undefined);
    const user = userEvent.setup();

    render(<LeadForm {...defaultProps} />);

    // Fill in required fields
    await user.type(screen.getByLabelText(/first name/i), 'John');
    await user.type(screen.getByLabelText(/last name/i), 'Doe');
    await user.type(screen.getByLabelText(/email/i), 'john@example.com');
    await user.type(screen.getByLabelText(/phone/i), '555-1234');
    await user.type(screen.getByLabelText(/company/i), 'Acme Corp');

    // Submit form
    const submitButton = screen.getByRole('button', { name: /create lead/i });
    fireEvent.click(submitButton);

    // Wait for onSubmit to be called
    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalledTimes(1);
    });

    // Verify form data
    const submittedData = mockOnSubmit.mock.calls[0][0];
    expect(submittedData.firstName).toBe('John');
    expect(submittedData.lastName).toBe('Doe');
    expect(submittedData.email).toBe('john@example.com');
    expect(submittedData.phone).toBe('555-1234');
    expect(submittedData.companyName).toBe('Acme Corp');
  });

  // ============================================
  // Additional Tests
  // ============================================

  it('pre-fills data in edit mode', () => {
    const initialData = {
      id: 'lead-123',
      firstName: 'Jane',
      lastName: 'Smith',
      email: 'jane@example.com',
      status: 'qualified' as const,
      source: 'referral' as const,
    };

    render(<LeadForm {...defaultProps} initialData={initialData} />);

    expect(screen.getByLabelText(/first name/i)).toHaveValue('Jane');
    expect(screen.getByLabelText(/last name/i)).toHaveValue('Smith');
    expect(screen.getByLabelText(/email/i)).toHaveValue('jane@example.com');
    expect(screen.getByRole('button', { name: /save changes/i })).toBeInTheDocument();
  });

  it('calls onCancel when cancel button clicked', async () => {
    const user = userEvent.setup();
    render(<LeadForm {...defaultProps} />);

    const cancelButton = screen.getByRole('button', { name: /cancel/i });
    await user.click(cancelButton);

    expect(mockOnCancel).toHaveBeenCalledTimes(1);
  });

  it('disables form when isLoading is true', () => {
    render(<LeadForm {...defaultProps} isLoading={true} />);

    expect(screen.getByLabelText(/first name/i)).toBeDisabled();
    expect(screen.getByLabelText(/email/i)).toBeDisabled();
    expect(screen.getByRole('button', { name: /saving/i })).toBeDisabled();
  });
});
