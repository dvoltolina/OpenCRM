/**
 * KanbanBoard Tests
 *
 * Agent CRM-16 Implementation
 *
 * Test Scenarios:
 * 1. Renders all stage columns
 * 2. Displays deals in correct columns
 * 3. Shows stage value totals
 * 4. Calls onDealClick when card clicked
 * 5. Shows loading state
 * 6. Empty stages show placeholder
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { KanbanBoard } from '../KanbanBoard';
import type { Pipeline, Stage, Deal } from '../../../types/models';
import type { DealsByStage } from '../../../hooks/useDealsByStage';

// ============================================
// Mocks
// ============================================

// Mock useDealsByStage hook
const mockRefresh = vi.fn();
vi.mock('../../../hooks/useDealsByStage', () => ({
  useDealsByStage: vi.fn(),
}));

// Mock useKanbanDragDrop hook
vi.mock('../../../hooks/useKanbanDragDrop', () => ({
  useKanbanDragDrop: vi.fn(() => ({
    dragState: {
      activeDeal: null,
      overStageId: null,
      originalStageId: null,
    },
    handleDragStart: vi.fn(),
    handleDragOver: vi.fn(),
    handleDragEnd: vi.fn(),
    handleDragCancel: vi.fn(),
    isMoving: false,
    moveError: null,
    lastMoveAttempt: null,
    clearMoveError: vi.fn(),
  })),
}));

// Import mocked module for manipulation
import { useDealsByStage } from '../../../hooks/useDealsByStage';
const mockedUseDealsByStage = vi.mocked(useDealsByStage);

// ============================================
// Test Data
// ============================================

const mockPipeline: Pipeline = {
  id: 'pipeline-1',
  name: 'Sales Pipeline',
  isDefault: true,
  isActive: true,
  ownerId: 'owner-1',
  ownerName: 'Owner',
  teamIds: [],
  createdAt: new Date(),
};

const mockStages: Stage[] = [
  {
    id: 'stage-1',
    pipelineId: 'pipeline-1',
    name: 'Lead',
    order: 0,
    colorHex: '#6366f1',
    probability: 10,
    isActive: true,
    createdAt: new Date(),
  },
  {
    id: 'stage-2',
    pipelineId: 'pipeline-1',
    name: 'Qualified',
    order: 1,
    colorHex: '#3b82f6',
    probability: 30,
    isActive: true,
    createdAt: new Date(),
  },
  {
    id: 'stage-3',
    pipelineId: 'pipeline-1',
    name: 'Proposal',
    order: 2,
    colorHex: '#10b981',
    probability: 60,
    isActive: true,
    createdAt: new Date(),
  },
];

const mockDeals: Deal[] = [
  {
    id: 'deal-1',
    pipelineId: 'pipeline-1',
    stageId: 'stage-1',
    title: 'Acme Corp Deal',
    valueCents: 500000, // $5,000
    currency: 'USD',
    probability: 10,
    status: 'open',
    clientName: 'John Doe',
    tags: [],
    createdAt: new Date(),
  },
  {
    id: 'deal-2',
    pipelineId: 'pipeline-1',
    stageId: 'stage-1',
    title: 'Beta Inc Deal',
    valueCents: 250000, // $2,500
    currency: 'USD',
    probability: 10,
    status: 'open',
    tags: [],
    createdAt: new Date(),
  },
  {
    id: 'deal-3',
    pipelineId: 'pipeline-1',
    stageId: 'stage-2',
    title: 'Gamma LLC Deal',
    valueCents: 1000000, // $10,000
    currency: 'USD',
    probability: 30,
    status: 'open',
    clientName: 'Jane Smith',
    expectedCloseDate: new Date('2025-12-15'),
    tags: [],
    createdAt: new Date(),
  },
];

function createDealsByStage(stages: Stage[], deals: Deal[]): DealsByStage {
  const result: DealsByStage = {};
  for (const stage of stages) {
    const stageDeals = deals.filter((d) => d.stageId === stage.id);
    result[stage.id] = {
      stage,
      deals: stageDeals,
      totalValue: stageDeals.reduce((sum, d) => sum + d.valueCents, 0),
      count: stageDeals.length,
    };
  }
  return result;
}

// ============================================
// Tests
// ============================================

describe('KanbanBoard', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockRefresh.mockClear();
  });

  // ============================================
  // Test 1: Renders all stage columns
  // ============================================
  it('renders all stage columns', () => {
    const dealsByStage = createDealsByStage(mockStages, mockDeals);

    mockedUseDealsByStage.mockReturnValue({
      dealsByStage,
      stages: mockStages,
      isLoading: false,
      error: null,
      pipelineValue: 1750000,
      pipelineCount: 3,
      refresh: mockRefresh,
    });

    render(<KanbanBoard pipeline={mockPipeline} />);

    // Check all stage columns are rendered
    expect(screen.getByTestId('kanban-column-stage-1')).toBeInTheDocument();
    expect(screen.getByTestId('kanban-column-stage-2')).toBeInTheDocument();
    expect(screen.getByTestId('kanban-column-stage-3')).toBeInTheDocument();

    // Check stage names
    expect(screen.getByText('Lead')).toBeInTheDocument();
    expect(screen.getByText('Qualified')).toBeInTheDocument();
    expect(screen.getByText('Proposal')).toBeInTheDocument();
  });

  // ============================================
  // Test 2: Displays deals in correct columns
  // ============================================
  it('displays deals in correct columns', () => {
    const dealsByStage = createDealsByStage(mockStages, mockDeals);

    mockedUseDealsByStage.mockReturnValue({
      dealsByStage,
      stages: mockStages,
      isLoading: false,
      error: null,
      pipelineValue: 1750000,
      pipelineCount: 3,
      refresh: mockRefresh,
    });

    render(<KanbanBoard pipeline={mockPipeline} />);

    // Deal 1 and 2 should be in stage-1
    expect(screen.getByText('Acme Corp Deal')).toBeInTheDocument();
    expect(screen.getByText('Beta Inc Deal')).toBeInTheDocument();

    // Deal 3 should be in stage-2
    expect(screen.getByText('Gamma LLC Deal')).toBeInTheDocument();

    // Check deal cards are in the DOM
    expect(screen.getByTestId('deal-card-deal-1')).toBeInTheDocument();
    expect(screen.getByTestId('deal-card-deal-2')).toBeInTheDocument();
    expect(screen.getByTestId('deal-card-deal-3')).toBeInTheDocument();
  });

  // ============================================
  // Test 3: Shows stage value totals
  // ============================================
  it('shows stage value totals', () => {
    const dealsByStage = createDealsByStage(mockStages, mockDeals);

    mockedUseDealsByStage.mockReturnValue({
      dealsByStage,
      stages: mockStages,
      isLoading: false,
      error: null,
      pipelineValue: 1750000,
      pipelineCount: 3,
      refresh: mockRefresh,
    });

    render(<KanbanBoard pipeline={mockPipeline} />);

    // Check pipeline total value in header
    expect(screen.getByTestId('pipeline-value')).toHaveTextContent('$17,500');
    expect(screen.getByTestId('pipeline-count')).toHaveTextContent('3');

    // Check stage headers exist with their values
    const stage1Header = screen.getByTestId('stage-header-stage-1');
    expect(stage1Header).toHaveTextContent('$7,500');

    const stage2Header = screen.getByTestId('stage-header-stage-2');
    expect(stage2Header).toHaveTextContent('$10,000');

    const stage3Header = screen.getByTestId('stage-header-stage-3');
    expect(stage3Header).toHaveTextContent('$0');
  });

  // ============================================
  // Test 4: Calls onDealClick when card clicked
  // ============================================
  it('calls onDealClick when card clicked', () => {
    const dealsByStage = createDealsByStage(mockStages, mockDeals);
    const onDealClick = vi.fn();

    mockedUseDealsByStage.mockReturnValue({
      dealsByStage,
      stages: mockStages,
      isLoading: false,
      error: null,
      pipelineValue: 1750000,
      pipelineCount: 3,
      refresh: mockRefresh,
    });

    render(<KanbanBoard pipeline={mockPipeline} onDealClick={onDealClick} />);

    // Click on a deal card
    const dealCard = screen.getByTestId('deal-card-deal-1');
    fireEvent.click(dealCard);

    // Verify callback was called with the deal
    expect(onDealClick).toHaveBeenCalledTimes(1);
    expect(onDealClick).toHaveBeenCalledWith(
      expect.objectContaining({ id: 'deal-1', title: 'Acme Corp Deal' })
    );
  });

  // ============================================
  // Test 5: Shows loading state
  // ============================================
  it('shows loading state', () => {
    mockedUseDealsByStage.mockReturnValue({
      dealsByStage: {},
      stages: [],
      isLoading: true,
      error: null,
      pipelineValue: 0,
      pipelineCount: 0,
      refresh: mockRefresh,
    });

    render(<KanbanBoard pipeline={mockPipeline} />);

    expect(screen.getByTestId('kanban-loading')).toBeInTheDocument();
    expect(screen.queryByTestId('kanban-board')).not.toBeInTheDocument();
  });

  // ============================================
  // Test 6: Empty stages show placeholder
  // ============================================
  it('empty stages show placeholder', () => {
    // Only include deals in stage-1, leaving stage-2 and stage-3 empty
    const limitedDeals = mockDeals.filter((d) => d.stageId === 'stage-1');
    const dealsByStage = createDealsByStage(mockStages, limitedDeals);

    mockedUseDealsByStage.mockReturnValue({
      dealsByStage,
      stages: mockStages,
      isLoading: false,
      error: null,
      pipelineValue: 750000,
      pipelineCount: 2,
      refresh: mockRefresh,
    });

    render(<KanbanBoard pipeline={mockPipeline} />);

    // Empty stages should show the empty placeholder
    const emptyStages = screen.getAllByTestId('empty-stage');
    expect(emptyStages.length).toBe(2); // stage-2 and stage-3 are empty
  });

  // ============================================
  // Additional Tests
  // ============================================

  it('shows error state with retry button', () => {
    const mockError = new Error('Failed to load pipeline');

    mockedUseDealsByStage.mockReturnValue({
      dealsByStage: {},
      stages: [],
      isLoading: false,
      error: mockError,
      pipelineValue: 0,
      pipelineCount: 0,
      refresh: mockRefresh,
    });

    render(<KanbanBoard pipeline={mockPipeline} />);

    const errorContainer = screen.getByTestId('kanban-error');
    expect(errorContainer).toBeInTheDocument();
    expect(errorContainer).toHaveTextContent('Failed to load pipeline');

    // Click retry
    fireEvent.click(screen.getByText('Try Again'));
    expect(mockRefresh).toHaveBeenCalled();
  });

  it('calls onAddDeal when add button clicked', () => {
    const dealsByStage = createDealsByStage(mockStages, mockDeals);
    const onAddDeal = vi.fn();

    mockedUseDealsByStage.mockReturnValue({
      dealsByStage,
      stages: mockStages,
      isLoading: false,
      error: null,
      pipelineValue: 1750000,
      pipelineCount: 3,
      refresh: mockRefresh,
    });

    render(<KanbanBoard pipeline={mockPipeline} onAddDeal={onAddDeal} />);

    // Find and click an add button
    const addButtons = screen.getAllByText(/Add Opportunity/i);
    fireEvent.click(addButtons[0]);

    expect(onAddDeal).toHaveBeenCalled();
  });
});
