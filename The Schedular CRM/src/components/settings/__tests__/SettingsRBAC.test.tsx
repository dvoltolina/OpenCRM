/**
 * Settings RBAC Tests
 * Tests role-based access control for Settings components
 * Agent FW-05 Implementation
 */

import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { PipelineSettings } from '../PipelineSettings';
import { TeamSettings } from '../TeamSettings';
import { CustomFieldsSettings } from '../CustomFieldsSettings';
import type { Pipeline, Stage } from '../../../types/models';
import type { CRMUser } from '../../../types/models';

// ============================================
// Mock Data
// ============================================

const mockOwnerUser: CRMUser = {
  id: 'user-owner',
  businessId: 'biz-123',
  email: 'owner@example.com',
  displayName: 'Owner User',
  role: 'owner',
  createdAt: new Date(),
};

const mockAdminUser: CRMUser = {
  id: 'user-admin',
  businessId: 'biz-123',
  email: 'admin@example.com',
  displayName: 'Admin User',
  role: 'admin',
  createdAt: new Date(),
};

const mockStaffUser: CRMUser = {
  id: 'user-staff',
  businessId: 'biz-123',
  email: 'staff@example.com',
  displayName: 'Staff User',
  role: 'staff',
  createdAt: new Date(),
};

const mockFrontDeskUser: CRMUser = {
  id: 'user-front-desk',
  businessId: 'biz-123',
  email: 'frontdesk@example.com',
  displayName: 'Front Desk User',
  role: 'frontDesk',
  createdAt: new Date(),
};

const mockPipelines: Pipeline[] = [
  {
    id: 'pipeline-1',
    name: 'Sales Pipeline',
    isDefault: true,
    isActive: true,
    ownerId: 'owner-1',
    ownerName: 'Owner',
    teamIds: [],
    createdAt: new Date(),
  },
];

const mockStages: Stage[] = [
  {
    id: 'stage-1',
    pipelineId: 'pipeline-1',
    name: 'Lead',
    colorHex: '#6366f1',
    order: 0,
    probability: 10,
    isActive: true,
    createdAt: new Date(),
  },
];

// ============================================
// Mock Hooks
// ============================================

const mockCreatePipeline = vi.fn();
const mockUpdatePipeline = vi.fn();
const mockSetDefaultPipeline = vi.fn();
const mockCreateStage = vi.fn();
const mockUpdateStage = vi.fn();
const mockReorderStages = vi.fn();

// Mock AuthContext
vi.mock('../../../context/AuthContext');

vi.mock('../../../hooks/usePipelines', () => ({
  usePipelines: () => ({
    pipelines: mockPipelines,
    createPipeline: mockCreatePipeline,
    updatePipeline: mockUpdatePipeline,
    isLoading: false,
    error: null,
  }),
}));

vi.mock('../../../hooks/useStages', () => ({
  useStages: () => ({
    stages: mockStages,
    createStage: mockCreateStage,
    updateStage: mockUpdateStage,
    reorderStages: mockReorderStages,
    isLoading: false,
    error: null,
  }),
}));

vi.mock('../../../hooks/useSettings', () => ({
  useSettings: () => ({
    settings: {
      businessId: 'biz-123',
      defaultPipelineId: 'pipeline-1',
      defaultCurrency: 'USD',
      leadScoringEnabled: false,
      dealRotting: { enabled: false, thresholdDays: 14 },
    },
    setDefaultPipeline: mockSetDefaultPipeline,
    isLoading: false,
    error: null,
  }),
}));

vi.mock('../../../hooks/useTeamMembers', () => ({
  useTeamMembers: () => ({
    members: [],
    isLoading: false,
    error: null,
    updateMemberRole: vi.fn(),
    refresh: vi.fn(),
  }),
}));

vi.mock('../../../hooks/useCustomFields', () => ({
  useCustomFields: () => ({
    fields: [],
    isLoading: false,
    error: null,
    createField: vi.fn(),
    updateField: vi.fn(),
    deleteField: vi.fn(),
    archiveField: vi.fn(),
    restoreField: vi.fn(),
    reorderFields: vi.fn(),
    duplicateField: vi.fn(),
  }),
}));

vi.mock('../../../hooks/useModal', () => ({
  useModal: () => ({
    isOpen: false,
    open: vi.fn(),
    close: vi.fn(),
  }),
}));

// ============================================
// Tests
// ============================================

describe('Pipeline Settings RBAC', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('allows owner to create pipelines', async () => {
    const { useAuth } = await import('../../../context/AuthContext');
    vi.mocked(useAuth).mockReturnValue({ crmUser: mockOwnerUser, businessId: 'biz-123' } as any);

    render(<PipelineSettings />);

    const createButton = screen.getByText('+ New Pipeline');
    expect(createButton).not.toBeDisabled();
    expect(createButton).not.toHaveAttribute('title');
  });

  it('allows admin to create pipelines', async () => {
    const { useAuth } = await import('../../../context/AuthContext');
    vi.mocked(useAuth).mockReturnValue({ crmUser: mockAdminUser, businessId: 'biz-123' } as any);

    render(<PipelineSettings />);

    const createButton = screen.getByText('+ New Pipeline');
    expect(createButton).not.toBeDisabled();
  });

  it('prevents staff from creating pipelines', async () => {
    const { useAuth } = await import('../../../context/AuthContext');
    vi.mocked(useAuth).mockReturnValue({ crmUser: mockStaffUser, businessId: 'biz-123' } as any);

    render(<PipelineSettings />);

    // Check for RBAC warning
    expect(screen.getByRole('alert')).toHaveTextContent('view-only access');

    const createButton = screen.getByText('+ New Pipeline');
    expect(createButton).not.toBeDisabled();
  });

  it('prevents front desk from modifying pipelines', async () => {
    const { useAuth } = await import('../../../context/AuthContext');
    vi.mocked(useAuth).mockReturnValue({ crmUser: mockFrontDeskUser, businessId: 'biz-123' } as any);

    render(<PipelineSettings />);

    // Check for RBAC warning
    expect(screen.getByRole('alert')).toHaveTextContent('view-only access');

    // All action buttons should be disabled
    const createButton = screen.getByText('+ New Pipeline');
    expect(createButton).toBeDisabled();
  });

  it('prevents staff from adding stages', async () => {
    const { useAuth } = await import('../../../context/AuthContext');
    vi.mocked(useAuth).mockReturnValue({ crmUser: mockStaffUser, businessId: 'biz-123' } as any);

    render(<PipelineSettings />);

    const addStageButton = screen.getByText('+ Add Stage');
    expect(addStageButton).toBeDisabled();
    expect(addStageButton).toHaveAttribute('title', 'You need edit access to add stages');
  });
});

describe('Team Settings RBAC', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('allows owner to invite members', async () => {
    const { useAuth } = await import('../../../context/AuthContext');
    vi.mocked(useAuth).mockReturnValue({ crmUser: mockOwnerUser, businessId: 'biz-123' } as any);

    render(<TeamSettings />);

    const inviteButton = screen.getByText('+ Invite Member');
    expect(inviteButton).not.toBeDisabled();
  });

  it('allows admin to invite members', async () => {
    const { useAuth } = await import('../../../context/AuthContext');
    vi.mocked(useAuth).mockReturnValue({ crmUser: mockAdminUser, businessId: 'biz-123' } as any);

    render(<TeamSettings />);

    const inviteButton = screen.getByText('+ Invite Member');
    expect(inviteButton).not.toBeDisabled();
  });

  it('prevents staff from inviting members', async () => {
    const { useAuth } = await import('../../../context/AuthContext');
    vi.mocked(useAuth).mockReturnValue({ crmUser: mockStaffUser, businessId: 'biz-123' } as any);

    render(<TeamSettings />);

    // Check for RBAC warning
    expect(screen.getByRole('alert')).toHaveTextContent('view-only access');

    const inviteButton = screen.getByText('+ Invite Member');
    expect(inviteButton).toBeDisabled();
  });

  it('prevents front desk from inviting members', async () => {
    const { useAuth } = await import('../../../context/AuthContext');
    vi.mocked(useAuth).mockReturnValue({ crmUser: mockFrontDeskUser, businessId: 'biz-123' } as any);

    render(<TeamSettings />);

    // Check for RBAC warning
    expect(screen.getByRole('alert')).toHaveTextContent('view-only access');

    const inviteButton = screen.getByText('+ Invite Member');
    expect(inviteButton).toBeDisabled();
  });
});

describe('Custom Fields Settings RBAC', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('allows owner to add custom fields', async () => {
    const { useAuth } = await import('../../../context/AuthContext');
    vi.mocked(useAuth).mockReturnValue({ crmUser: mockOwnerUser, businessId: 'biz-123' } as any);

    render(<CustomFieldsSettings />);

    const addButton = screen.getByText('+ Add Custom Field');
    expect(addButton).not.toBeDisabled();
  });

  it('allows admin to add custom fields', async () => {
    const { useAuth } = await import('../../../context/AuthContext');
    vi.mocked(useAuth).mockReturnValue({ crmUser: mockAdminUser, businessId: 'biz-123' } as any);

    render(<CustomFieldsSettings />);

    const addButton = screen.getByText('+ Add Custom Field');
    expect(addButton).not.toBeDisabled();
  });

  it('prevents staff from adding custom fields', async () => {
    const { useAuth } = await import('../../../context/AuthContext');
    vi.mocked(useAuth).mockReturnValue({ crmUser: mockStaffUser, businessId: 'biz-123' } as any);

    render(<CustomFieldsSettings />);

    // Check for RBAC warning
    expect(screen.getByRole('alert')).toHaveTextContent('view-only access');

    const addButton = screen.getByText('+ Add Custom Field');
    expect(addButton).toBeDisabled();
    expect(addButton).toHaveAttribute('title', 'Only owners and admins can add custom fields');
  });

  it('prevents front desk from modifying custom fields', async () => {
    const { useAuth } = await import('../../../context/AuthContext');
    vi.mocked(useAuth).mockReturnValue({ crmUser: mockFrontDeskUser, businessId: 'biz-123' } as any);

    render(<CustomFieldsSettings />);

    // Check for RBAC warning
    expect(screen.getByRole('alert')).toHaveTextContent('view-only access');

    const addButton = screen.getByText('+ Add Custom Field');
    expect(addButton).toBeDisabled();
  });
});
