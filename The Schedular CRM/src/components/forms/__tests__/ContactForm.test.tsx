/**
 * ContactForm Tests
 *
 * Agent CRM-14 Implementation
 *
 * Test Scenarios:
 * 1. Renders all fields
 * 2. Company selector with search
 * 3. Address fields toggle
 * 4. Lifecycle dropdown works
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ContactForm } from '../ContactForm';

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

describe('ContactForm', () => {
  const mockOnSubmit = vi.fn();
  const mockOnCancel = vi.fn();

  const mockCompanies = [
    { id: 'company-1', name: 'Acme Corp' },
    { id: 'company-2', name: 'Tech Industries' },
    { id: 'company-3', name: 'Global Solutions' },
  ];

  const defaultProps = {
    onSubmit: mockOnSubmit,
    onCancel: mockOnCancel,
    companies: mockCompanies,
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: Renders all fields
  // ============================================
  it('renders all fields', () => {
    render(<ContactForm {...defaultProps} />);

    // Contact Information
    expect(screen.getByLabelText(/first name/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/last name/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/phone/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/job title/i)).toBeInTheDocument();

    // Lifecycle stage
    expect(screen.getByLabelText(/lifecycle stage/i)).toBeInTheDocument();

    // Buttons
    expect(screen.getByRole('button', { name: /create contact/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /cancel/i })).toBeInTheDocument();
  });

  // ============================================
  // Test 2: Company selector with search
  // ============================================
  it('company selector with search', async () => {
    const user = userEvent.setup();
    render(<ContactForm {...defaultProps} />);

    // Find company searchable select by the placeholder text
    const companyTrigger = screen.getByText(/search companies/i);
    expect(companyTrigger).toBeInTheDocument();

    // Click to open dropdown
    await user.click(companyTrigger);

    // Wait for dropdown options to appear
    await waitFor(() => {
      expect(screen.getByText('Acme Corp')).toBeInTheDocument();
    });

    // Select a company
    await user.click(screen.getByText('Tech Industries'));

    // Verify selection is shown
    await waitFor(() => {
      expect(screen.getByText('Tech Industries')).toBeInTheDocument();
    });
  });

  // ============================================
  // Test 3: Address fields toggle
  // ============================================
  it('address fields toggle', async () => {
    const user = userEvent.setup();
    render(<ContactForm {...defaultProps} />);

    // Address fields should not be visible initially
    expect(screen.queryByLabelText(/street address/i)).not.toBeInTheDocument();
    expect(screen.queryByLabelText(/city/i)).not.toBeInTheDocument();

    // Find and click the toggle button
    const toggleButton = screen.getByRole('button', { name: /add address/i });
    await user.click(toggleButton);

    // Address fields should now be visible
    expect(screen.getByLabelText(/street address/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/city/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/state/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/zip code/i)).toBeInTheDocument();

    // Click toggle again to hide
    const hideButton = screen.getByRole('button', { name: /hide address/i });
    await user.click(hideButton);

    // Address fields should be hidden again
    expect(screen.queryByLabelText(/street address/i)).not.toBeInTheDocument();
  });

  // ============================================
  // Test 4: Lifecycle dropdown works
  // ============================================
  it('lifecycle dropdown works', async () => {
    const user = userEvent.setup();
    render(<ContactForm {...defaultProps} />);

    // Find lifecycle select
    const lifecycleSelect = screen.getByLabelText(/lifecycle stage/i);
    expect(lifecycleSelect).toBeInTheDocument();

    // Check options exist (actual options: lead, prospect, active, inactive, churned)
    expect(screen.getByRole('option', { name: 'Lead' })).toBeInTheDocument();
    expect(screen.getByRole('option', { name: 'Prospect' })).toBeInTheDocument();
    expect(screen.getByRole('option', { name: 'Active' })).toBeInTheDocument();
    expect(screen.getByRole('option', { name: 'Inactive' })).toBeInTheDocument();

    // Select a lifecycle stage
    await user.selectOptions(lifecycleSelect, 'active');

    // Verify selection
    expect(lifecycleSelect).toHaveValue('active');
  });

  // ============================================
  // Additional Tests
  // ============================================

  it('validates required fields', async () => {
    render(<ContactForm {...defaultProps} />);

    // Submit empty form
    const submitButton = screen.getByRole('button', { name: /create contact/i });
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

  it('pre-fills data in edit mode', () => {
    const initialData = {
      id: 'contact-123',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      phone: '555-1234',
      companyId: 'company-1',
      lifecycleStage: 'customer' as const,
    };

    render(<ContactForm {...defaultProps} initialData={initialData} />);

    expect(screen.getByLabelText(/first name/i)).toHaveValue('John');
    expect(screen.getByLabelText(/last name/i)).toHaveValue('Doe');
    expect(screen.getByLabelText(/email/i)).toHaveValue('john@example.com');
    expect(screen.getByRole('button', { name: /save changes/i })).toBeInTheDocument();
  });

  it('calls onCancel when cancel button clicked', async () => {
    const user = userEvent.setup();
    render(<ContactForm {...defaultProps} />);

    const cancelButton = screen.getByRole('button', { name: /cancel/i });
    await user.click(cancelButton);

    expect(mockOnCancel).toHaveBeenCalledTimes(1);
  });
});
