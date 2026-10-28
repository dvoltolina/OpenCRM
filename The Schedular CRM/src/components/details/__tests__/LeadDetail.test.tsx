/**
 * LeadDetail Component Tests
 *
 * Agent CRM-17 Implementation
 *
 * Test Scenarios:
 * 1. Displays lead information
 * 2. Shows status and source badges
 * 3. Convert action available
 * 4. Activity timeline loads
 */

import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import { LeadDetail } from '../LeadDetail';
import type { Lead, SalesActivity } from '../../../types/models';

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

// Mock hooks
vi.mock('../../../hooks', () => ({
  useLead: vi.fn(),
  useTimeline: vi.fn(),
  useCalendarSync: vi.fn(() => ({
    enabled: false,
    configured: false,
    contextReady: false,
    connections: [],
    conflicts: [],
    activityStatuses: {},
    loading: false,
    error: null,
    refresh: vi.fn(),
    startOAuth: vi.fn(),
    connectWithCode: vi.fn(),
    disconnect: vi.fn(),
    refreshTokens: vi.fn(),
    syncConnection: vi.fn(),
    syncActivity: vi.fn(),
    resolveConflict: vi.fn(),
    updateSettings: vi.fn(),
  })),
  useDocuments: vi.fn(() => ({
    documents: [],
    folders: [],
    isLoading: false,
    isUploading: false,
    error: null,
    refreshDocuments: vi.fn(),
    refreshFolders: vi.fn(),
    uploadDocument: vi.fn(),
    createFolder: vi.fn(),
    moveToFolder: vi.fn(),
    generatePublicLink: vi.fn(),
    revokePublicLink: vi.fn(),
  })),
}));

vi.mock('../../../context/AuthContext', () => ({
  useAuth: () => ({
    businessId: 'biz-1',
    crmUser: {
      id: 'user-1',
      role: 'admin',
      displayName: 'Test User',
      email: 'test@example.com',
      teamIds: [],
      managedTeamIds: [],
      managerId: undefined,
    },
    user: null,
    loading: false,
    isAuthenticated: true,
    signOut: vi.fn(),
  }),
  AuthProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

// Import hooks after mocking
import { useLead, useTimeline } from '../../../hooks';

const mockLead: Lead = {
  id: 'lead-1',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  phone: '555-0123',
  companyName: 'Acme Corp',
  title: 'CEO',
  status: 'new',
  source: 'website',
  score: 85,
  tags: ['vip', 'enterprise'],
  notes: 'Interested in our enterprise plan',
  assigneeName: 'Jane Smith',
  createdAt: new Date('2024-01-15'),
  updatedAt: new Date('2024-01-16'),
};

const mockActivities: SalesActivity[] = [
  {
    id: 'activity-1',
    type: 'call',
    title: 'Initial call',
    description: 'Discussed requirements',
    leadId: 'lead-1',
    isCompleted: false,
    createdById: 'user-1',
    createdByName: 'Jane Smith',
    createdAt: new Date('2024-01-16'),
  },
];

describe('LeadDetail', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: Displays lead information
  // ============================================
  it('displays lead information', () => {
    vi.mocked(useLead).mockReturnValue({
      lead: mockLead,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
      activities: [],
      isLoadingActivities: false,
      refreshActivities: vi.fn(),
    });

    vi.mocked(useTimeline).mockReturnValue({
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<LeadDetail leadId="lead-1" />);

    // Check name
    expect(screen.getByText('John Doe')).toBeInTheDocument();

    // Check email (appears in both header and content)
    expect(screen.getAllByText('john@example.com').length).toBeGreaterThan(0);

    // Check phone
    expect(screen.getByText('555-0123')).toBeInTheDocument();

    // Check company
    expect(screen.getByText('Acme Corp')).toBeInTheDocument();

    // Check title
    expect(screen.getByText('CEO')).toBeInTheDocument();

    // Check notes
    expect(screen.getByText('Interested in our enterprise plan')).toBeInTheDocument();
  });

  // ============================================
  // Test 2: Shows status and source badges
  // ============================================
  it('shows status and source badges', () => {
    vi.mocked(useLead).mockReturnValue({
      lead: mockLead,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
      activities: [],
      isLoadingActivities: false,
      refreshActivities: vi.fn(),
    });

    vi.mocked(useTimeline).mockReturnValue({
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<LeadDetail leadId="lead-1" />);

    // Check status badge
    const statusBadge = screen.getByText('new');
    expect(statusBadge).toBeInTheDocument();
    expect(statusBadge).toHaveClass('detail-badge--primary');

    // Check source badge
    const sourceBadge = screen.getByText('Website');
    expect(sourceBadge).toBeInTheDocument();
    expect(sourceBadge).toHaveClass('detail-badge--default');
  });

  // ============================================
  // Test 3: Convert action available
  // ============================================
  it('shows convert action when provided', () => {
    const mockOnConvert = vi.fn();

    vi.mocked(useLead).mockReturnValue({
      lead: mockLead,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
      activities: [],
      isLoadingActivities: false,
      refreshActivities: vi.fn(),
    });

    vi.mocked(useTimeline).mockReturnValue({
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<LeadDetail leadId="lead-1" onConvert={mockOnConvert} />);

    // Check convert button exists
    const convertButton = screen.getByText('Convert');
    expect(convertButton).toBeInTheDocument();
  });

  it('hides convert action when lead is converted', () => {
    const mockOnConvert = vi.fn();
    const convertedLead = { ...mockLead, status: 'converted' as const };

    vi.mocked(useLead).mockReturnValue({
      lead: convertedLead,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
      activities: [],
      isLoadingActivities: false,
      refreshActivities: vi.fn(),
    });

    vi.mocked(useTimeline).mockReturnValue({
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<LeadDetail leadId="lead-1" onConvert={mockOnConvert} />);

    // Convert button should not exist
    expect(screen.queryByText('Convert')).not.toBeInTheDocument();
  });

  // ============================================
  // Test 4: Activity timeline loads
  // ============================================
  it('displays activity timeline', () => {
    vi.mocked(useLead).mockReturnValue({
      lead: mockLead,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
      activities: mockActivities,
      isLoadingActivities: false,
      refreshActivities: vi.fn(),
    });

    vi.mocked(useTimeline).mockReturnValue({
      activities: mockActivities,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<LeadDetail leadId="lead-1" />);

    // Check activity timeline section
    expect(screen.getByText('Activity Timeline')).toBeInTheDocument();

    // Check activity is displayed
    expect(screen.getByText('Initial call')).toBeInTheDocument();
    expect(screen.getByText('Discussed requirements')).toBeInTheDocument();
  });

  it('shows loading state for activities', () => {
    vi.mocked(useLead).mockReturnValue({
      lead: mockLead,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
      activities: [],
      isLoadingActivities: true,
      refreshActivities: vi.fn(),
    });

    vi.mocked(useTimeline).mockReturnValue({
      activities: [],
      isLoading: true,
      error: null,
      refresh: vi.fn(),
    });

    render(<LeadDetail leadId="lead-1" />);

    expect(screen.getByText('Loading activities...')).toBeInTheDocument();
  });
});
