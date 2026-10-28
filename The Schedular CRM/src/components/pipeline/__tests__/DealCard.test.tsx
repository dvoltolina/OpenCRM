/**
 * DealCard Tests
 *
 * Agent CRM-16 Implementation
 *
 * Test Scenarios:
 * 1. Displays deal title
 * 2. Displays formatted value
 * 3. Shows client name
 * 4. Shows expected close date
 * 5. Compact variant renders
 * 6. Drag visual feedback
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { DealCard } from '../DealCard';
import type { Deal } from '../../../types/models';

// ============================================
// Mock dnd-kit sortable
// ============================================

vi.mock('@dnd-kit/sortable', () => ({
  useSortable: vi.fn(() => ({
    attributes: { 'aria-roledescription': 'sortable' },
    listeners: {},
    setNodeRef: vi.fn(),
    transform: null,
    transition: undefined,
    isDragging: false,
  })),
}));

vi.mock('@dnd-kit/utilities', () => ({
  CSS: {
    Transform: {
      toString: vi.fn(() => undefined),
    },
  },
}));

// Import mock for manipulation
import { useSortable } from '@dnd-kit/sortable';
const mockedUseSortable = vi.mocked(useSortable);

// ============================================
// Test Data
// ============================================

const baseDeal: Deal = {
  id: 'deal-1',
  pipelineId: 'pipeline-1',
  stageId: 'stage-1',
  title: 'Enterprise Software Deal',
  valueCents: 2500000, // $25,000
  currency: 'USD',
  probability: 45,
  status: 'open',
  tags: [],
  createdAt: new Date('2025-01-15'),
};

// ============================================
// Tests
// ============================================

describe('DealCard', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockedUseSortable.mockReturnValue({
      attributes: {
        role: 'button',
        tabIndex: 0,
        'aria-disabled': false,
        'aria-pressed': undefined,
        'aria-roledescription': 'sortable',
        'aria-describedby': 'DndDescribedBy-0',
      },
      listeners: {},
      setNodeRef: vi.fn(),
      transform: null,
      transition: undefined,
      isDragging: false,
      active: null,
      activeIndex: -1,
      data: {
        sortable: {
          containerId: 'stage-1',
          items: ['deal-1'],
          index: 0,
        },
      },
      index: 0,
      newIndex: 0,
      isOver: false,
      isSorting: false,
      items: [],
      node: { current: null },
      over: null,
      overIndex: -1,
      rect: { current: null },
      setActivatorNodeRef: vi.fn(),
      setDraggableNodeRef: vi.fn(),
      setDroppableNodeRef: vi.fn(),
    });
  });

  // ============================================
  // Test 1: Displays deal title
  // ============================================
  it('displays deal title', () => {
    render(<DealCard deal={baseDeal} stageId="stage-1" />);

    expect(screen.getByText('Enterprise Software Deal')).toBeInTheDocument();
  });

  // ============================================
  // Test 2: Displays formatted value
  // ============================================
  it('displays formatted value', () => {
    render(<DealCard deal={baseDeal} stageId="stage-1" />);

    // $25,000 (2500000 cents)
    expect(screen.getByText('$25,000')).toBeInTheDocument();
  });

  // ============================================
  // Test 3: Shows client name
  // ============================================
  it('shows client name', () => {
    const dealWithClient: Deal = {
      ...baseDeal,
      clientName: 'Jane Smith',
    };

    render(<DealCard deal={dealWithClient} stageId="stage-1" />);

    expect(screen.getByText('Jane Smith')).toBeInTheDocument();
    // Check initials avatar
    expect(screen.getByText('JS')).toBeInTheDocument();
  });

  // ============================================
  // Test 4: Shows expected close date
  // ============================================
  it('shows expected close date', () => {
    const dealWithDate: Deal = {
      ...baseDeal,
      expectedCloseDate: new Date('2025-12-15'),
    };

    render(<DealCard deal={dealWithDate} stageId="stage-1" />);

    // Should show "Dec 14" or "Dec 15" format (depending on timezone)
    expect(screen.getByText(/Dec 1[45]/)).toBeInTheDocument();
  });

  // ============================================
  // Test 5: Compact variant renders
  // ============================================
  it('compact variant renders', () => {
    render(<DealCard deal={baseDeal} stageId="stage-1" compact />);

    const card = screen.getByTestId('deal-card-deal-1');
    expect(card).toHaveClass('deal-card--compact');

    // Should still show title and value
    expect(screen.getByText('Enterprise Software Deal')).toBeInTheDocument();
    expect(screen.getByText('$25,000')).toBeInTheDocument();
  });

  // ============================================
  // Test 6: Drag visual feedback
  // ============================================
  it('drag visual feedback', () => {
    // Mock useSortable to return isDragging: true
    mockedUseSortable.mockReturnValue({
      attributes: {
        role: 'button',
        tabIndex: 0,
        'aria-disabled': false,
        'aria-pressed': undefined,
        'aria-roledescription': 'sortable',
        'aria-describedby': 'DndDescribedBy-0',
      },
      listeners: {},
      setNodeRef: vi.fn(),
      transform: null,
      transition: undefined,
      isDragging: true,
      active: null,
      activeIndex: -1,
      data: {
        sortable: {
          containerId: 'stage-1',
          items: ['deal-1'],
          index: 0,
        },
      },
      index: 0,
      newIndex: 0,
      isOver: false,
      isSorting: false,
      items: [],
      node: { current: null },
      over: null,
      overIndex: -1,
      rect: { current: null },
      setActivatorNodeRef: vi.fn(),
      setDraggableNodeRef: vi.fn(),
      setDroppableNodeRef: vi.fn(),
    });

    render(<DealCard deal={baseDeal} stageId="stage-1" />);

    const card = screen.getByTestId('deal-card-deal-1');
    expect(card).toHaveClass('deal-card--dragging');
  });

  // ============================================
  // Additional Tests
  // ============================================

  it('calls onClick when card is clicked', () => {
    const onClick = vi.fn();

    render(<DealCard deal={baseDeal} stageId="stage-1" onClick={onClick} />);

    fireEvent.click(screen.getByTestId('deal-card-deal-1'));

    expect(onClick).toHaveBeenCalledTimes(1);
    expect(onClick).toHaveBeenCalledWith(baseDeal);
  });

  it('shows probability badge', () => {
    render(<DealCard deal={baseDeal} stageId="stage-1" />);

    expect(screen.getByText('45%')).toBeInTheDocument();
  });

  it('shows company name when no client name', () => {
    const dealWithCompany: Deal = {
      ...baseDeal,
      clientName: undefined,
      companyName: 'Acme Corporation',
    };

    render(<DealCard deal={dealWithCompany} stageId="stage-1" />);

    expect(screen.getByText('Acme Corporation')).toBeInTheDocument();
  });

  it('renders without client info', () => {
    const dealNoClient: Deal = {
      ...baseDeal,
      clientName: undefined,
      companyName: undefined,
    };

    render(<DealCard deal={dealNoClient} stageId="stage-1" />);

    // Should render without error
    expect(screen.getByText('Enterprise Software Deal')).toBeInTheDocument();
  });

  it('formats different currency values', () => {
    const euroDeal: Deal = {
      ...baseDeal,
      valueCents: 150000, // $1,500
      currency: 'EUR',
    };

    render(<DealCard deal={euroDeal} stageId="stage-1" />);

    // Should format with EUR
    expect(screen.getByText(/1,500/)).toBeInTheDocument();
  });

  it('fires quick note action when the button is clicked', () => {
    const onQuickNote = vi.fn();
    render(<DealCard deal={baseDeal} stageId="stage-1" onQuickNote={onQuickNote} />);

    fireEvent.click(screen.getByLabelText('Add note'));

    expect(onQuickNote).toHaveBeenCalledWith(baseDeal, 'stage-1');
  });

  it('fires quick note action on keyboard shortcut', () => {
    const onQuickNote = vi.fn();
    render(<DealCard deal={baseDeal} stageId="stage-1" onQuickNote={onQuickNote} />);

    fireEvent.keyDown(screen.getByTestId('deal-card-deal-1'), { key: 'n' });

    expect(onQuickNote).toHaveBeenCalledWith(baseDeal, 'stage-1');
  });
});
