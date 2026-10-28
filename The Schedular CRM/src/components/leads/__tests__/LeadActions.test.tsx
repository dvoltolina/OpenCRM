/**
 * LeadActions Component Tests
 *
 * Agent CRM-24 Implementation
 *
 * Test Scenarios:
 * 1. Renders action buttons
 * 2. Convert button enabled for convertible leads
 * 3. Convert button disabled for already converted leads
 * 4. Convert button disabled for leads without email
 * 5. Convert button disabled for unqualified leads
 * 6. Calls onConvert with lead when clicked
 * 7. Calls onEdit when edit clicked
 * 8. Disables all buttons when disabled prop is true
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { LeadActions, LeadStatusBadge } from '../LeadActions';
import type { Lead } from '../../../types/models';

// ============================================
// Mock Data
// ============================================

const baseLead: Lead = {
  id: 'lead-1',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  phone: '555-1234',
  status: 'new',
  source: 'website',
  tags: [],
  createdAt: new Date('2025-01-01'),
  updatedAt: new Date('2025-01-01'),
};

const convertedLead: Lead = {
  ...baseLead,
  id: 'lead-2',
  status: 'converted',
  convertedToClientId: 'client-1',
  convertedAt: new Date('2025-01-15'),
};

const noEmailLead: Lead = {
  ...baseLead,
  id: 'lead-3',
  email: '',
};

const unqualifiedLead: Lead = {
  ...baseLead,
  id: 'lead-4',
  status: 'unqualified',
};

const qualifiedLead: Lead = {
  ...baseLead,
  id: 'lead-5',
  status: 'qualified',
};

// ============================================
// Tests
// ============================================

describe('LeadActions', () => {
  const mockOnEdit = vi.fn();
  const mockOnConvert = vi.fn();
  const mockOnDelete = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: Renders action buttons
  // ============================================
  it('renders action buttons', () => {
    render(
      <LeadActions
        lead={baseLead}
        onEdit={mockOnEdit}
        onConvert={mockOnConvert}
        onDelete={mockOnDelete}
      />
    );

    expect(screen.getByText('Edit')).toBeInTheDocument();
    expect(screen.getByText('Convert')).toBeInTheDocument();
    expect(screen.getByText('Delete')).toBeInTheDocument();
  });

  // ============================================
  // Test 2: Convert button enabled for convertible leads
  // ============================================
  it('enables convert button for new lead with email', () => {
    render(
      <LeadActions
        lead={baseLead}
        onConvert={mockOnConvert}
      />
    );

    const convertButton = screen.getByText('Convert');
    expect(convertButton).not.toBeDisabled();
  });

  it('enables convert button for qualified lead', () => {
    render(
      <LeadActions
        lead={qualifiedLead}
        onConvert={mockOnConvert}
      />
    );

    const convertButton = screen.getByText('Convert');
    expect(convertButton).not.toBeDisabled();
  });

  // ============================================
  // Test 3: Convert button disabled for already converted leads
  // ============================================
  it('disables convert button for already converted lead', () => {
    render(
      <LeadActions
        lead={convertedLead}
        onConvert={mockOnConvert}
      />
    );

    const convertButton = screen.getByText('Converted');
    expect(convertButton).toBeDisabled();
  });

  // ============================================
  // Test 4: Convert button disabled for leads without email
  // ============================================
  it('disables convert button for lead without email', () => {
    render(
      <LeadActions
        lead={noEmailLead}
        onConvert={mockOnConvert}
      />
    );

    const convertButton = screen.getByText('Convert');
    expect(convertButton).toBeDisabled();
    expect(convertButton).toHaveAttribute('title', 'Lead must have an email to convert');
  });

  // ============================================
  // Test 5: Convert button disabled for unqualified leads
  // ============================================
  it('disables convert button for unqualified lead', () => {
    render(
      <LeadActions
        lead={unqualifiedLead}
        onConvert={mockOnConvert}
      />
    );

    const convertButton = screen.getByText('Convert');
    expect(convertButton).toBeDisabled();
    expect(convertButton).toHaveAttribute('title', 'Cannot convert unqualified leads');
  });

  // ============================================
  // Test 6: Calls onConvert with lead when clicked
  // ============================================
  it('calls onConvert with lead when convert clicked', () => {
    render(
      <LeadActions
        lead={baseLead}
        onConvert={mockOnConvert}
      />
    );

    const convertButton = screen.getByText('Convert');
    fireEvent.click(convertButton);

    expect(mockOnConvert).toHaveBeenCalledTimes(1);
    expect(mockOnConvert).toHaveBeenCalledWith(baseLead);
  });

  it('does not call onConvert for disabled convert button', () => {
    render(
      <LeadActions
        lead={convertedLead}
        onConvert={mockOnConvert}
      />
    );

    const convertButton = screen.getByText('Converted');
    fireEvent.click(convertButton);

    expect(mockOnConvert).not.toHaveBeenCalled();
  });

  // ============================================
  // Test 7: Calls onEdit when edit clicked
  // ============================================
  it('calls onEdit with lead when edit clicked', () => {
    render(
      <LeadActions
        lead={baseLead}
        onEdit={mockOnEdit}
      />
    );

    const editButton = screen.getByText('Edit');
    fireEvent.click(editButton);

    expect(mockOnEdit).toHaveBeenCalledTimes(1);
    expect(mockOnEdit).toHaveBeenCalledWith(baseLead);
  });

  // ============================================
  // Test 8: Disables all buttons when disabled prop is true
  // ============================================
  it('disables all buttons when disabled prop is true', () => {
    render(
      <LeadActions
        lead={baseLead}
        onEdit={mockOnEdit}
        onConvert={mockOnConvert}
        onDelete={mockOnDelete}
        disabled={true}
      />
    );

    expect(screen.getByText('Edit')).toBeDisabled();
    expect(screen.getByText('Convert')).toBeDisabled();
    expect(screen.getByText('Delete')).toBeDisabled();
  });

  it('shows read-only titles when permissions are denied', () => {
    render(
      <LeadActions
        lead={baseLead}
        onEdit={mockOnEdit}
        onConvert={mockOnConvert}
        onDelete={mockOnDelete}
        canEdit={false}
        canConvertOverride={false}
        canDelete={false}
        readOnlyReason="Read-only: not shared"
      />
    );

    expect(screen.getByText('Edit')).toHaveAttribute('title', 'Read-only: not shared');
    expect(screen.getByText('Convert')).toHaveAttribute('title', 'Read-only: not shared');
    expect(screen.getByText('Delete')).toHaveAttribute('title', 'Read-only: not shared');
  });

  // ============================================
  // Test: Only renders provided action buttons
  // ============================================
  it('only renders edit button when only onEdit provided', () => {
    render(
      <LeadActions
        lead={baseLead}
        onEdit={mockOnEdit}
      />
    );

    expect(screen.getByText('Edit')).toBeInTheDocument();
    expect(screen.queryByText('Convert')).not.toBeInTheDocument();
    expect(screen.queryByText('Delete')).not.toBeInTheDocument();
  });

  it('calls onDelete with lead when delete clicked', () => {
    render(
      <LeadActions
        lead={baseLead}
        onDelete={mockOnDelete}
      />
    );

    const deleteButton = screen.getByText('Delete');
    fireEvent.click(deleteButton);

    expect(mockOnDelete).toHaveBeenCalledTimes(1);
    expect(mockOnDelete).toHaveBeenCalledWith(baseLead);
  });
});

// ============================================
// LeadStatusBadge Tests
// ============================================

describe('LeadStatusBadge', () => {
  it('renders new status correctly', () => {
    render(<LeadStatusBadge status="new" />);
    expect(screen.getByText('New')).toBeInTheDocument();
    expect(screen.getByText('New')).toHaveClass('lead-status-badge--new');
  });

  it('renders contacted status correctly', () => {
    render(<LeadStatusBadge status="contacted" />);
    expect(screen.getByText('Contacted')).toBeInTheDocument();
    expect(screen.getByText('Contacted')).toHaveClass('lead-status-badge--contacted');
  });

  it('renders qualified status correctly', () => {
    render(<LeadStatusBadge status="qualified" />);
    expect(screen.getByText('Qualified')).toBeInTheDocument();
    expect(screen.getByText('Qualified')).toHaveClass('lead-status-badge--qualified');
  });

  it('renders unqualified status correctly', () => {
    render(<LeadStatusBadge status="unqualified" />);
    expect(screen.getByText('Unqualified')).toBeInTheDocument();
    expect(screen.getByText('Unqualified')).toHaveClass('lead-status-badge--unqualified');
  });

  it('renders converted status correctly', () => {
    render(<LeadStatusBadge status="converted" />);
    expect(screen.getByText('Converted')).toBeInTheDocument();
    expect(screen.getByText('Converted')).toHaveClass('lead-status-badge--converted');
  });
});
